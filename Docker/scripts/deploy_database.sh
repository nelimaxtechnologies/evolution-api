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

    # Replace only DATABASE vars in .env using sed (preserves all other 250+ config vars)
    sed -i "s|^DATABASE_PROVIDER=.*|DATABASE_PROVIDER=$DATABASE_PROVIDER|" .env
    sed -i "s|^DATABASE_CONNECTION_URI=.*|DATABASE_CONNECTION_URI=$DATABASE_CONNECTION_URI|" .env
    # Append if not already present
    grep -q '^DATABASE_PROVIDER=' .env || echo "DATABASE_PROVIDER=$DATABASE_PROVIDER" >> .env
    grep -q '^DATABASE_CONNECTION_URI=' .env || echo "DATABASE_CONNECTION_URI=$DATABASE_CONNECTION_URI" >> .env
    grep -q '^DATABASE_URL=' .env || echo "DATABASE_URL=$DATABASE_URL" >> .env
    echo "Updated DATABASE vars in .env"

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
