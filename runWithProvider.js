const dotenv = require('dotenv');
const { execSync } = require('child_process');
const { existsSync } = require('fs');

const { DATABASE_PROVIDER, DATABASE_CONNECTION_URI, DATABASE_URL } = process.env;

// If DATABASE_CONNECTION_URI is not set, derive it from DATABASE_URL
if (!DATABASE_CONNECTION_URI && DATABASE_URL) {
  process.env.DATABASE_CONNECTION_URI = DATABASE_URL;
}

// Load .env AFTER checking Render env vars so Render vars take precedence
dotenv.config();

// Ensure DATABASE_CONNECTION_URI set by Render overrides any .env dummy value
if (DATABASE_CONNECTION_URI) {
  process.env.DATABASE_CONNECTION_URI = DATABASE_CONNECTION_URI;
}
if (DATABASE_URL) {
  process.env.DATABASE_URL = DATABASE_URL;
}

const databaseProviderDefault = process.env.DATABASE_PROVIDER ?? 'postgresql';

if (!DATABASE_PROVIDER) {
  console.warn(`DATABASE_PROVIDER is not set in the .env file, using default: ${databaseProviderDefault}`);
}

// Função para determinar qual pasta de migrations usar
// Função para determinar qual pasta de migrations usar
function getMigrationsFolder(provider) {
  switch (provider) {
    case 'psql_bouncer':
      return 'postgresql-migrations'; // psql_bouncer usa as migrations do postgresql
    default:
      return `${provider}-migrations`;
  }
}

const migrationsFolder = getMigrationsFolder(databaseProviderDefault);

let command = process.argv
  .slice(2)
  .join(' ')
  .replace(/DATABASE_PROVIDER/g, databaseProviderDefault);

// Substituir referências à pasta de migrations pela pasta correta
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