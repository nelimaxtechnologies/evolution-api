import 'dotenv/config';

import path from 'node:path';

import { defineConfig, env } from 'prisma/config';

const provider = process.env.DATABASE_PROVIDER ?? 'postgresql';

const schemaFile =
  provider === 'mysql'
    ? 'mysql-schema.prisma'
    : provider === 'psql_bouncer'
      ? 'psql_bouncer-schema.prisma'
      : 'postgresql-schema.prisma';

// Prisma 7 reads the URL from here. Prefer DATABASE_CONNECTION_URI, fall back to DATABASE_URL.
const dbUrl = process.env.DATABASE_CONNECTION_URI || process.env.DATABASE_URL || '';

export default defineConfig({
  schema: path.join('prisma', schemaFile),
  migrations: {
    path: path.join('prisma', 'migrations'),
  },
  datasource: {
    url: dbUrl,
  },
});
