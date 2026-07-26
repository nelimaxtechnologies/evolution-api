#!/bin/bash

source ./Docker/scripts/env_functions.sh

if [ "$DOCKER_ENV" != "true" ]; then
    export_env_vars
fi

if [[ "$DATABASE_PROVIDER" == "postgresql" || "$DATABASE_PROVIDER" == "mysql" || "$DATABASE_PROVIDER" == "psql_bouncer" ]]; then
    export DATABASE_URL
    export DATABASE_CONNECTION_URI
    echo "Deploying migrations for $DATABASE_PROVIDER"
    echo "Database URL: $DATABASE_CONNECTION_URI"
    # Remove .env so dotenv/dotenvx in prisma.config.ts cannot override Render env vars
    mv .env .env.bak 2>/dev/null || true
    npm run db:deploy
    if [ $? -ne 0 ]; then
        mv .env.bak .env 2>/dev/null || true
        echo "Migration failed"
        exit 1
    else
        echo "Migration succeeded"
    fi
    npm run db:generate
    if [ $? -ne 0 ]; then
        mv .env.bak .env 2>/dev/null || true
        echo "Prisma generate failed"
        exit 1
    else
        echo "Prisma generate succeeded"
    fi
    mv .env.bak .env 2>/dev/null || true
else
    echo "Error: Database provider $DATABASE_PROVIDER invalid."
    exit 1
fi
