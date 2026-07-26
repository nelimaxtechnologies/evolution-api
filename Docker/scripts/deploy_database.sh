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
    # .env.local takes precedence over .env in dotenvx — write real creds here
    cat > .env.local <<EOF
DATABASE_PROVIDER=$DATABASE_PROVIDER
DATABASE_CONNECTION_URI=$DATABASE_CONNECTION_URI
DATABASE_URL=$DATABASE_URL
EOF
    echo "Wrote .env.local with DATABASE_CONNECTION_URI set"
    npm run db:deploy
    if [ $? -ne 0 ]; then
        rm -f .env.local
        echo "Migration failed"
        exit 1
    else
        echo "Migration succeeded"
    fi
    npm run db:generate
    if [ $? -ne 0 ]; then
        rm -f .env.local
        echo "Prisma generate failed"
        exit 1
    else
        echo "Prisma generate succeeded"
    fi
    rm -f .env.local
else
    echo "Error: Database provider $DATABASE_PROVIDER invalid."
    exit 1
fi
