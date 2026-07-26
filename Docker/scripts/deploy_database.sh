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
    # Write .env.local with real Render env vars so Prisma/dotenvx picks them up
    # (.env.local takes precedence over .env and won't be overridden)
    rm -f .env .env.local 2>/dev/null || true
    cat > .env.local <<EOF
DATABASE_PROVIDER=$DATABASE_PROVIDER
DATABASE_CONNECTION_URI=$DATABASE_CONNECTION_URI
DATABASE_URL=$DATABASE_URL
EOF
    npm run db:deploy
    deploy_status=$?
    rm -f .env.local 2>/dev/null || true
    if [ $deploy_status -ne 0 ]; then
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
