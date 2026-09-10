#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo " Freetime Maker F-Droid Bot"
echo "========================================"

APP_ID="${APP_ID:-}"

echo
echo "==> Building all apps..."
echo "fdroid build --all"

fdroid build --all

echo
echo "==> Publishing apps..."
echo "fdroid publish"

fdroid publish

echo
echo "==> Preparing changelog script..."
echo "chmod +x ./changelogs.sh"

chmod +x ./changelogs.sh

echo
echo "==> Updating changelogs..."

if [ -n "$APP_ID" ]; then
    echo "Processing only:"
    echo "$APP_ID"

    echo "./changelogs.sh $APP_ID"
    ./changelogs.sh "$APP_ID"
else
    echo "No APP_ID specified."
    echo "Processing all apps."

    echo "./changelogs.sh"
    ./changelogs.sh
fi

echo
echo "==> Updating repository..."
echo "fdroid update"

fdroid update

echo
echo "========================================"
echo " Done."
echo "========================================"