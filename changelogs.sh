#!/usr/bin/env bash

set -euo pipefail

METADATA_DIR="metadata"
LOCALE="en-US"

TARGET_APP="${1:-}"

github_raw_content() {
    local endpoint="$1"
    local result=""

    if result="$(gh api         -H "Accept: application/vnd.github.raw+json"         "$endpoint"         2>/dev/null)"; then
        printf '%s' "$result"
        return 0
    fi

    return 1
}

github_release_body() {
    local repo="$1"
    local tag="$2"
    local result=""

    if result="$(gh api         "repos/$repo/releases/tags/$tag"         --jq '.body // empty'         2>/dev/null)"; then
        printf '%s' "$result"
        return 0
    fi

    return 1
}

is_github_error_payload() {
    local file="$1"

    grep -Eq '"message"[[:space:]]*:[[:space:]]*"Not Found"' "$file" 2>/dev/null         && grep -Eq '"status"[[:space:]]*:[[:space:]]*"?404"?' "$file" 2>/dev/null
}

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
        sed -n             's/^CurrentVersion:[[:space:]]*//p'             "$METADATA_FILE"             | tail -n1
    )"

    VERSION_CODE="$(
        sed -n             's/^CurrentVersionCode:[[:space:]]*//p'             "$METADATA_FILE"             | tail -n1
    )"

    SOURCE_URL="$(
        sed -n             's/^SourceCode:[[:space:]]*//p'             "$METADATA_FILE"             | tail -n1
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
        if is_github_error_payload "$CHANGELOG_FILE"; then
            echo "    Removing invalid GitHub 404 payload:"
            echo "    $CHANGELOG_FILE"
            rm -f "$CHANGELOG_FILE"
        else
            echo "    Changelog already exists:"
            echo "    $CHANGELOG_FILE"
            continue
        fi
    fi

    echo "    Repository: $GITHUB_REPO"
    echo "    Searching Fastlane changelog..."

    CHANGELOG=""

    if [ -z "$CHANGELOG" ]; then
        CHANGELOG="$(github_raw_content             "repos/$GITHUB_REPO/contents/fastlane/metadata/android/$LOCALE/changelogs/$VERSION_CODE.txt?ref=v$VERSION"             || true)"
    fi

    if [ -z "$CHANGELOG" ]; then
        CHANGELOG="$(github_raw_content             "repos/$GITHUB_REPO/contents/fastlane/metadata/android/$LOCALE/changelogs/default.txt?ref=v$VERSION"             || true)"
    fi

    if [ -z "$CHANGELOG" ]; then
        CHANGELOG="$(github_raw_content             "repos/$GITHUB_REPO/contents/fastlane/metadata/android/$LOCALE/changelogs/$VERSION_CODE.txt?ref=$VERSION"             || true)"
    fi

    if [ -z "$CHANGELOG" ]; then
        CHANGELOG="$(github_raw_content             "repos/$GITHUB_REPO/contents/fastlane/metadata/android/$LOCALE/changelogs/default.txt?ref=$VERSION"             || true)"
    fi

    if [ -z "$CHANGELOG" ]; then
        CHANGELOG="$(github_raw_content             "repos/$GITHUB_REPO/contents/fastlane/metadata/android/$LOCALE/changelogs/$VERSION_CODE.txt"             || true)"
    fi

    if [ -z "$CHANGELOG" ]; then
        CHANGELOG="$(github_raw_content             "repos/$GITHUB_REPO/contents/fastlane/metadata/android/$LOCALE/changelogs/default.txt"             || true)"
    fi

    if [ -z "$CHANGELOG" ]; then
        echo "    Fastlane changelog not found."
        echo "    Searching GitHub release v$VERSION..."
        CHANGELOG="$(github_release_body "$GITHUB_REPO" "v$VERSION" || true)"
    fi

    if [ -z "$CHANGELOG" ]; then
        echo "    Searching GitHub release $VERSION..."
        CHANGELOG="$(github_release_body "$GITHUB_REPO" "$VERSION" || true)"
    fi

    if [ -z "$CHANGELOG" ]; then
        echo "    No changelog found."
        continue
    fi

    printf '%s\n' "$CHANGELOG"         | tr -d '\r'         > "$CHANGELOG_FILE"

    echo "    ✓ Created:"
    echo "      $CHANGELOG_FILE"
done

echo
echo "==> Finished updating changelogs."
