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
echo "==> Replacing GeoWeather APK with official signed release APK..."

GEOWEATHER_METADATA="metadata/com.freetime.geoweather.yml"
if [ -f "$GEOWEATHER_METADATA" ]; then
    VERSION="$(sed -n 's/^CurrentVersion:[[:space:]]*//p' "$GEOWEATHER_METADATA" | tail -n1)"
    VERSION_CODE="$(sed -n 's/^CurrentVersionCode:[[:space:]]*//p' "$GEOWEATHER_METADATA" | tail -n1)"

    if [ -n "$VERSION" ] && [ -n "$VERSION_CODE" ]; then
        APK="repo/com.freetime.geoweather_${VERSION_CODE}.apk"
        RELEASE_URL="https://github.com/FreetimeMaker/GeoWeather/releases/download/v${VERSION}/GeoWeather-v${VERSION}.apk"

        echo "Downloading official GeoWeather ${VERSION} (${VERSION_CODE}) APK..."
        curl --fail --location --retry 3 --retry-delay 2 \
            "$RELEASE_URL" \
            --output "$APK"

        rm -f "${APK}.idsig"

        echo "Verifying official GeoWeather APK signature..."
        apksigner verify --verbose --print-certs "$APK"
    else
        echo "::error::Could not determine GeoWeather CurrentVersion/CurrentVersionCode."
        exit 1
    fi
else
    echo "GeoWeather metadata not found; skipping official APK replacement."
fi

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