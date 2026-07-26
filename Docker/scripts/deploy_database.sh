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
    # Overwrite .env with real values so Prisma's internal dotenvx picks them up
    cp .env .env.original 2>/dev/null || true
    sed -i "s|^DATABASE_CONNECTION_URI=.*|DATABASE_CONNECTION_URI=$DATABASE_CONNECTION_URI|" .env 2>/dev/null || \
    echo "DATABASE_CONNECTION_URI=$DATABASE_CONNECTION_URI" >> .env
    sed -i "s|^DATABASE_URL=.*|DATABASE_URL=$DATABASE_URL|" .env 2>/dev/null || \
    echo "DATABASE_URL=$DATABASE_URL" >> .env
    npm run db:deploy
    if [ $? -ne 0 ]; then
        cp .env.original .env 2>/dev/null || true
        rm -f .env.original .env.local
        echo "Migration failed"
        exit 1
    else
        echo "Migration succeeded"
    fi
    npm run db:generate
    if [ $? -ne 0 ]; then
        cp .env.original .env 2>/dev/null || true
        rm -f .env.original .env.local
        echo "Prisma generate failed"
        exit 1
    else
        echo "Prisma generate succeeded"
    fi
    cp .env.original .env 2>/dev/null || true
    rm -f .env.original .env.local
else
    echo "Error: Database provider $DATABASE_PROVIDER invalid."
    exit 1
fi
