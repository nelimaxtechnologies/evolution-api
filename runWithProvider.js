const dotenv = require('dotenv');
const { execSync } = require('child_process');
const { existsSync, readFileSync, writeFileSync } = require('fs');

// Capture Render env vars before .env can override them
const savedConnUri = process.env.DATABASE_CONNECTION_URI;
const savedDbUrl = process.env.DATABASE_URL;
const savedDbProvider = process.env.DATABASE_PROVIDER;

dotenv.config();

// Restore Render env vars (they must win over .env defaults)
if (savedConnUri) process.env.DATABASE_CONNECTION_URI = savedConnUri;
if (savedDbUrl) process.env.DATABASE_URL = savedDbUrl;

const databaseProviderDefault = (savedConnUri ? process.env.DATABASE_PROVIDER : null) ?? process.env.DATABASE_PROVIDER ?? 'postgresql';

if (!process.env.DATABASE_PROVIDER) {
  console.warn(`DATABASE_PROVIDER is not set, using default: ${databaseProviderDefault}`);
}

// Prisma's internal dotenvx reads .env from disk and overrides process.env.
// We must write real credentials to .env BEFORE spawning Prisma, then restore after.
let originalEnv = null;
if (existsSync('.env')) {
  originalEnv = readFileSync('.env', 'utf8');
}
if (savedConnUri) {
  const envContent = [
    `DATABASE_PROVIDER=${savedDbProvider || 'postgresql'}`,
    `DATABASE_CONNECTION_URI=${savedConnUri}`,
    savedDbUrl ? `DATABASE_URL=${savedDbUrl}` : null,
    `AUTHENTICATION_API_KEY=${process.env.AUTHENTICATION_API_KEY || ''}`,
    `AUTHENTICATION_API_ACCESS=${process.env.AUTHENTICATION_API_ACCESS || 'true'}`,
    `AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=${process.env.AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES || 'true'}`,
    `SERVER_PORT=${process.env.SERVER_PORT || '8080'}`,
    `SERVER_TYPE=${process.env.SERVER_TYPE || 'http'}`,
    `LOG_LEVEL=${process.env.LOG_LEVEL || 'warn'}`,
    `DEL_INSTANCE=${process.env.DEL_INSTANCE || 'false'}`,
    `STORE_CLEANING_INTERVAL=${process.env.STORE_CLEANING_INTERVAL || '7200'}`,
    `STORE_CLEANING_TYPE=${process.env.STORE_CLEANING_TYPE || 'evolution'}`,
    `STORE_CLEANING_UNKNOWN=${process.env.STORE_CLEANING_UNKNOWN || 'false'}`,
    `STORE_CLEANING_UNREAD=${process.env.STORE_CLEANING_UNREAD || 'false'}`,
  ].filter(Boolean).join('\n') + '\n';
  writeFileSync('.env', envContent, 'utf8');
  console.log('Wrote real credentials to .env for Prisma');
}

function getMigrationsFolder(provider) {
  switch (provider) {
    case 'psql_bouncer':
      return 'postgresql-migrations';
    default:
      return `${provider}-migrations`;
  }
}

const migrationsFolder = getMigrationsFolder(databaseProviderDefault);

let command = process.argv
  .slice(2)
  .join(' ')
  .replace(/DATABASE_PROVIDER/g, databaseProviderDefault);

const migrationsPattern = new RegExp(`${databaseProviderDefault}-migrations`, 'g');
command = command.replace(migrationsPattern, migrationsFolder);

if (command.includes('rmdir') && existsSync('prisma\\migrations')) {
  try {
    execSync('rmdir /S /Q prisma\\migrations', { stdio: 'inherit' });
  } catch (error) {
    console.error(`Error removing directory: prisma\\migrations`);
    process.exit(1);
  }
} else if (command.includes('rmdir')) {
  console.warn(`Directory 'prisma\\migrations' does not exist, skipping removal.`);
}

try {
  execSync(command, { stdio: 'inherit' });
} catch (error) {
  console.error(`Error executing command: ${command}`);
  // Restore original .env even on failure
  if (originalEnv !== null) {
    writeFileSync('.env', originalEnv, 'utf8');
  }
  process.exit(1);
}

// Restore original .env
if (originalEnv !== null) {
  writeFileSync('.env', originalEnv, 'utf8');
  console.log('Restored original .env');
}
