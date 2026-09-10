#!/usr/bin/env bash

set -euo pipefail

METADATA_DIR="metadata"
LOCALE="en-US"

# Optional:
# ./changelogs.sh com.freetime.geoweather
#
# Ohne Argument:
# ./changelogs.sh
# -> verarbeitet alle Apps

TARGET_APP="${1:-}"

echo "==> Checking F-Droid changelogs..."

if [ -n "$TARGET_APP" ]; then
    METADATA_FILES=("$METADATA_DIR/$TARGET_APP.yml")
else
    METADATA_FILES=("$METADATA_DIR"/*.yml)
fi

for METADATA_FILE in "${METADATA_FILES[@]}"; do
    [ -f "$METADATA_FILE" ] || continue

    APP_ID="$(basename "$METADATA_FILE" .yml)"

    VERSION="$(
        sed -n \
            's/^CurrentVersion:[[:space:]]*//p' \
            "$METADATA_FILE" \
            | tail -n1
    )"

    VERSION_CODE="$(
        sed -n \
            's/^CurrentVersionCode:[[:space:]]*//p' \
            "$METADATA_FILE" \
            | tail -n1
    )"

    SOURCE_URL="$(
        sed -n \
            's/^SourceCode:[[:space:]]*//p' \
            "$METADATA_FILE" \
            | tail -n1
    )"

    echo
    echo "==> $APP_ID"
    echo "    Version: $VERSION"
    echo "    VersionCode: $VERSION_CODE"

    if [ -z "$VERSION" ] || [ -z "$VERSION_CODE" ]; then
        echo "    Missing CurrentVersion or CurrentVersionCode."
        echo "    Skipping."
        continue
    fi

    if [ -z "$SOURCE_URL" ]; then
        echo "    Missing SourceCode."
        echo "    Skipping."
        continue
    fi

    if [[ "$SOURCE_URL" =~ github\.com/([^/]+)/([^/]+) ]]; then
        OWNER="${BASH_REMATCH[1]}"
        REPO="${BASH_REMATCH[2]}"
        REPO="${REPO%.git}"
    else
        echo "    SourceCode is not GitHub."
        echo "    Skipping."
        continue
    fi

    GITHUB_REPO="$OWNER/$REPO"

    CHANGELOG_DIR="$METADATA_DIR/$APP_ID/$LOCALE/changelogs"
    CHANGELOG_FILE="$CHANGELOG_DIR/$VERSION_CODE.txt"

    mkdir -p "$CHANGELOG_DIR"

    if [ -s "$CHANGELOG_FILE" ]; then
        echo "    Changelog already exists:"
        echo "    $CHANGELOG_FILE"
        continue
    fi

    echo "    Repository: $GITHUB_REPO"

    #
    # 1. Try Fastlane changelog for this versionCode
    #

    echo "    Searching Fastlane changelog..."

    CHANGELOG=""

    CHANGELOG="$(
        gh api \
            -H "Accept: application/vnd.github.raw+json" \
            "repos/$GITHUB_REPO/contents/fastlane/metadata/android/$LOCALE/changelogs/$VERSION_CODE.txt?ref=v$VERSION" \
            2>/dev/null \
            || true
    )"

    #
    # 2. Try default.txt on version tag
    #

    if [ -z "$CHANGELOG" ]; then
        CHANGELOG="$(
            gh api \
                -H "Accept: application/vnd.github.raw+json" \
                "repos/$GITHUB_REPO/contents/fastlane/metadata/android/$LOCALE/changelogs/default.txt?ref=v$VERSION" \
                2>/dev/null \
                || true
        )"
    fi

    #
    # 3. Try tag without v
    #

    if [ -z "$CHANGELOG" ]; then
        CHANGELOG="$(
            gh api \
                -H "Accept: application/vnd.github.raw+json" \
                "repos/$GITHUB_REPO/contents/fastlane/metadata/android/$LOCALE/changelogs/$VERSION_CODE.txt?ref=$VERSION" \
                2>/dev/null \
                || true
        )"
    fi

    if [ -z "$CHANGELOG" ]; then
        CHANGELOG="$(
            gh api \
                -H "Accept: application/vnd.github.raw+json" \
                "repos/$GITHUB_REPO/contents/fastlane/metadata/android/$LOCALE/changelogs/default.txt?ref=$VERSION" \
                2>/dev/null \
                || true
        )"
    fi

    #
    # 4. Try default branch
    #

    if [ -z "$CHANGELOG" ]; then
        CHANGELOG="$(
            gh api \
                -H "Accept: application/vnd.github.raw+json" \
                "repos/$GITHUB_REPO/contents/fastlane/metadata/android/$LOCALE/changelogs/$VERSION_CODE.txt" \
                2>/dev/null \
                || true
        )"
    fi

    if [ -z "$CHANGELOG" ]; then
        CHANGELOG="$(
            gh api \
                -H "Accept: application/vnd.github.raw+json" \
                "repos/$GITHUB_REPO/contents/fastlane/metadata/android/$LOCALE/changelogs/default.txt" \
                2>/dev/null \
                || true
        )"
    fi

    #
    # 5. Fallback: GitHub Release Notes
    #

    if [ -z "$CHANGELOG" ]; then
        echo "    Fastlane changelog not found."
        echo "    Searching GitHub release v$VERSION..."

        CHANGELOG="$(
            gh api \
                "repos/$GITHUB_REPO/releases/tags/v$VERSION" \
                --jq '.body' \
                2>/dev/null \
                || true
        )"
    fi

    if [ -z "$CHANGELOG" ]; then
        echo "    Searching GitHub release $VERSION..."

        CHANGELOG="$(
            gh api \
                "repos/$GITHUB_REPO/releases/tags/$VERSION" \
                --jq '.body' \
                2>/dev/null \
                || true
        )"
    fi

    #
    # Nothing found
    #

    if [ -z "$CHANGELOG" ] || [ "$CHANGELOG" = "null" ]; then
        echo "    No changelog found."
        continue
    fi

    printf '%s\n' "$CHANGELOG" \
        | tr -d '\r' \
        > "$CHANGELOG_FILE"

    echo "    ✓ Created:"
    echo "      $CHANGELOG_FILE"

done

echo
echo "==> Finished updating changelogs."