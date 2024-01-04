v#!/usr/bin/env bash
set -Ex

function apply_path {

    echo "Check that we have WEBAPP_URL vars"
    test -n "$WEBAPP_URL"

    find /app/apps/web/.next \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s#NEXT_PUBLIC_WEBAPP_URL#$WEBAPP_URL#g"
}

apply_path
echo "Starting Nextjs"
exec "$@"