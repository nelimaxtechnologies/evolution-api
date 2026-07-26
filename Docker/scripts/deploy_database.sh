#!/bin/bash

source ./Docker/scripts/env_functions.sh

if [ "$DOCKER_ENV" != "true" ]; then
    export_env_vars
fi

if [[ "$DATABASE_PROVIDER" == "postgresql" || "$DATABASE_PROVIDER" == "mysql" || "$DATABASE_PROVIDER" == "psql_bouncer" ]]; then
    export DATABASE_URL
    export DATABASE_CONNECTION_URI
    echo "=== Deploying database for $DATABASE_PROVIDER ==="

    # If DATABASE_URL is empty, derive it from DATABASE_CONNECTION_URI
    if [ -z "$DATABASE_URL" ] && [ -n "$DATABASE_CONNECTION_URI" ]; then
        export DATABASE_URL="$DATABASE_CONNECTION_URI"
        echo "DATABASE_URL was empty, set from DATABASE_CONNECTION_URI"
    fi

    echo "DATABASE_CONNECTION_URI is set: $([ -n "$DATABASE_CONNECTION_URI" ] && echo 'YES' || echo 'NO')"
    echo "DATABASE_URL is set: $([ -n "$DATABASE_URL" ] && echo 'YES' || echo 'NO')"

    # Update only DATABASE vars in .env using awk (safe with special chars in URLs)
    awk -v dp="$DATABASE_PROVIDER" -v dc="$DATABASE_CONNECTION_URI" -v du="$DATABASE_URL" '
      /^DATABASE_PROVIDER=/ { print "DATABASE_PROVIDER=" dp; next }
      /^DATABASE_CONNECTION_URI=/ { print "DATABASE_CONNECTION_URI=" dc; next }
      /^DATABASE_URL=/ { print "DATABASE_URL=" du; next }
      { print }
    ' .env > .env.tmp && mv .env.tmp .env
    echo "Updated DATABASE vars in .env"

    # Copy provider-specific migrations into the generic migrations folder
    rm -rf ./prisma/migrations
    if [ "$DATABASE_PROVIDER" == "psql_bouncer" ]; then
        cp -r ./prisma/postgresql-migrations ./prisma/migrations
    else
        cp -r ./prisma/${DATABASE_PROVIDER}-migrations ./prisma/migrations
    fi
    echo "Copied ${DATABASE_PROVIDER} migrations"

    # Method 1: migrate reset (drops all + re-applies)
    echo "Attempting prisma migrate reset --force ..."
    npx prisma migrate reset --force 2>&1
    RESET_EXIT=$?
    if [ $RESET_EXIT -eq 0 ]; then
        echo "migrate reset succeeded"
    else
        echo "migrate reset failed (exit $RESET_EXIT), trying migrate deploy..."
        npx prisma migrate deploy 2>&1
        DEPLOY_EXIT=$?
        if [ $DEPLOY_EXIT -ne 0 ]; then
            echo "migrate deploy failed (exit $DEPLOY_EXIT), trying db push..."
            npx prisma db push --accept-data-loss 2>&1
            PUSH_EXIT=$?
            if [ $PUSH_EXIT -ne 0 ]; then
                echo "db push failed (exit $PUSH_EXIT). All methods failed."
                exit 1
            fi
            echo "db push succeeded"
        else
            echo "migrate deploy succeeded"
        fi
    fi

    npm run db:generate
    if [ $? -ne 0 ]; then
        echo "Prisma generate failed"
        exit 1
    else
        echo "Prisma generate succeeded"
    fi
    echo "=== Database deployment complete ==="
else
    echo "Error: Database provider $DATABASE_PROVIDER invalid."
    exit 1
fi
