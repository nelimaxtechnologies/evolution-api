import path from 'node:path';
import { readFileSync } from 'node:fs';
import { defineConfig } from 'prisma/config';

function readEnvFile(key: string): string {
  try {
    const content = readFileSync('/evolution/.env', 'utf8');
    for (const line of content.split('\n')) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const eqIndex = trimmed.indexOf('=');
      if (eqIndex === -1) continue;
      const k = trimmed.slice(0, eqIndex).trim();
      if (k === key) {
        let v = trimmed.slice(eqIndex + 1).trim();
        if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
          v = v.slice(1, -1);
        }
        return v;
      }
    }
  } catch {}
  return '';
}

const provider = process.env.DATABASE_PROVIDER ?? 'postgresql';

const dbUrl =
  process.env.DATABASE_CONNECTION_URI ||
  process.env.DATABASE_URL ||
  readEnvFile('DATABASE_CONNECTION_URI') ||
  readEnvFile('DATABASE_URL');

const schemaFile =
  provider === 'mysql'
    ? 'mysql-schema.prisma'
    : provider === 'psql_bouncer'
      ? 'psql_bouncer-schema.prisma'
      : 'postgresql-schema.prisma';

export default defineConfig({
  schema: path.join('prisma', schemaFile),
  migrations: {
    path: path.join('prisma', 'migrations'),
  },
  datasource: {
    url: dbUrl,
  },
});
