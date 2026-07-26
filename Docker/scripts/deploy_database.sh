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

    # Prisma's internal dotenvx reads .env from disk and overrides process.env.
    # Overwrite .env with real Render credentials BEFORE Prisma runs.
    cat > .env <<ENVEOF
DATABASE_PROVIDER=$DATABASE_PROVIDER
DATABASE_CONNECTION_URI=$DATABASE_CONNECTION_URI
DATABASE_URL=$DATABASE_URL
AUTHENTICATION_API_KEY=${AUTHENTICATION_API_KEY:-429683C4C977415CAAFCCE10F7D57E11}
AUTHENTICATION_API_ACCESS=${AUTHENTICATION_API_ACCESS:-true}
AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=${AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES:-true}
SERVER_PORT=${SERVER_PORT:-8080}
SERVER_TYPE=${SERVER_TYPE:-http}
LOG_LEVEL=${LOG_LEVEL:-warn}
DEL_INSTANCE=${DEL_INSTANCE:-false}
ENVEOF
    echo "Wrote real credentials to .env"

    npm run db:deploy
    if [ $? -ne 0 ]; then
        echo "Migration failed"
        exit 1
    else
        echo "Migration succeeded"
    fi
    npm run db:generate
    if [ $? -ne 0 ]; then
        echo "Prisma generate failed"
        exit 1
    else
        echo "Prisma generate succeeded"
    fi
else
    echo "Error: Database provider $DATABASE_PROVIDER invalid."
    exit 1
fi
