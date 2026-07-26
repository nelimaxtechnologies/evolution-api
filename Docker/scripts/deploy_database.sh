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

    # Update only DATABASE vars in .env using awk (safe with special chars in URLs)
    awk -v dp="$DATABASE_PROVIDER" -v dc="$DATABASE_CONNECTION_URI" -v du="$DATABASE_URL" '
      /^DATABASE_PROVIDER=/ { print "DATABASE_PROVIDER=" dp; next }
      /^DATABASE_CONNECTION_URI=/ { print "DATABASE_CONNECTION_URI=" dc; next }
      /^DATABASE_URL=/ { print "DATABASE_URL=" du; next }
      { print }
    ' .env > .env.tmp && mv .env.tmp .env
    echo "Updated DATABASE vars in .env"

    echo "Syncing database schema with prisma db push..."
    npx prisma db push --accept-data-loss
    if [ $? -ne 0 ]; then
        echo "Schema push failed, falling back to migrate deploy..."
        npm run db:deploy
        if [ $? -ne 0 ]; then
            echo "Migration failed"
            exit 1
        else
            echo "Migration succeeded"
        fi
    else
        echo "Schema push succeeded"
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
