#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo " Freetime Maker F-Droid Bot"
echo "========================================"

APP_ID="${APP_ID:-}"

echo
echo "==> Selecting Java 17 for reproducible Android builds..."

JAVA17_HOME=""

if [ -n "${JAVA_HOME_17_X64:-}" ] && [ -x "${JAVA_HOME_17_X64}/bin/java" ]; then
    JAVA17_HOME="$JAVA_HOME_17_X64"
else
    for JAVA_BIN in /usr/lib/jvm/*/bin/java /opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/17*/x64/bin/java; do
        [ -x "$JAVA_BIN" ] || continue
        if "$JAVA_BIN" -version 2>&1 | head -n1 | grep -Eq 'version "17([.]|\")'; then
            JAVA17_HOME="$(dirname "$(dirname "$JAVA_BIN")")"
            break
        fi
    done
fi

if [ -z "$JAVA17_HOME" ] || [ ! -x "$JAVA17_HOME/bin/java" ]; then
    echo "::error::Java 17 was not found on the runner."
    exit 1
fi

export JAVA_HOME="$JAVA17_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

echo "Using JAVA_HOME=$JAVA_HOME"
java -version

echo
echo "==> Securing F-Droid config permissions..."
chmod 600 config.yml

echo
echo "==> Building all apps..."
echo "fdroid build --all"

fdroid build --all

force_current_build() {
    local app_id="$1"
    local metadata_file="$2"

    [ -f "$metadata_file" ] || return 0

    local version_code
    version_code="$(sed -n 's/^CurrentVersionCode:[[:space:]]*//p' "$metadata_file" | tail -n1)"

    if [ -z "$version_code" ]; then
        echo "::error::Could not determine CurrentVersionCode for $app_id."
        exit 1
    fi

    local unsigned_apk="unsigned/${app_id}_${version_code}.apk"

    if [ ! -f "$unsigned_apk" ]; then
        echo
        echo "==> Forcing fresh source build for ${app_id}:${version_code}..."
        fdroid build --force "${app_id}:${version_code}"
    fi

    if [ ! -f "$unsigned_apk" ]; then
        echo "::error::Expected source-built APK still not found after forced build: $unsigned_apk"
        exit 1
    fi
}

force_current_build "com.freetime.ssmpc" "metadata/com.freetime.ssmpc.yml"
force_current_build "com.freetime.lumastore" "metadata/com.freetime.lumastore.yml"

sign_with_developer_key() {
    local app_id="$1"
    local metadata_file="$2"
    local keystore="$3"

    if [ ! -f "$metadata_file" ]; then
        echo "Metadata not found for $app_id; skipping developer signing."
        return 0
    fi

    local version_code
    version_code="$(sed -n 's/^CurrentVersionCode:[[:space:]]*//p' "$metadata_file" | tail -n1)"

    if [ -z "$version_code" ]; then
        echo "::error::Could not determine CurrentVersionCode for $app_id."
        exit 1
    fi

    local unsigned_apk="unsigned/${app_id}_${version_code}.apk"
    local signed_apk="repo/${app_id}_${version_code}.apk"

    if [ ! -f "$unsigned_apk" ]; then
        echo "::error::Expected source-built APK not found: $unsigned_apk"
        exit 1
    fi

    if [ ! -f "$keystore" ]; then
        echo "::error::Developer keystore not found: $keystore"
        exit 1
    fi

    if [ -z "${KEYSTORE_PASSWORD:-}" ]; then
        echo "::error::KEYSTORE_PASSWORD is not set. Add this secret to FreetimeMaker/fdroid."
        exit 1
    fi

    mkdir -p repo
    rm -f "$signed_apk" "$signed_apk.idsig"

    echo
    echo "==> Signing $app_id with its developer key..."
    apksigner sign \
        --ks "$keystore" \
        --ks-key-alias alle \
        --ks-pass "pass:${KEYSTORE_PASSWORD}" \
        --key-pass "pass:${KEYSTORE_PASSWORD}" \
        --out "$signed_apk" \
        "$unsigned_apk"

    echo "==> Verifying developer signature for $app_id..."
    apksigner verify --verbose --print-certs "$signed_apk"

    rm -f "$unsigned_apk" "$unsigned_apk.idsig"
}

sign_with_developer_key \
    "com.freetime.ssmpc" \
    "metadata/com.freetime.ssmpc.yml" \
    "SuperSMP-Companion-KeyStore.jks"

sign_with_developer_key \
    "com.freetime.lumastore" \
    "metadata/com.freetime.lumastore.yml" \
    "Luma-Store.jks"

echo
echo "==> Publishing remaining apps..."
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
