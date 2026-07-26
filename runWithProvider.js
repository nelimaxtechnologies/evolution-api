const dotenv = require('dotenv');
const { execSync } = require('child_process');
const { existsSync } = require('fs');

const savedConnUri = process.env.DATABASE_CONNECTION_URI;
const savedDbUrl = process.env.DATABASE_URL;

dotenv.config();

if (savedConnUri) process.env.DATABASE_CONNECTION_URI = savedConnUri;
if (savedDbUrl) process.env.DATABASE_URL = savedDbUrl;

const databaseProviderDefault = (savedConnUri ? process.env.DATABASE_PROVIDER : null) ?? process.env.DATABASE_PROVIDER ?? 'postgresql';

if (!process.env.DATABASE_PROVIDER) {
  console.warn(`DATABASE_PROVIDER is not set, using default: ${databaseProviderDefault}`);
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
  process.exit(1);
}
