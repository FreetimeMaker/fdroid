#!/usr/bin/env bash

set -euo pipefail

if [ "${RUN_FDROID_MAIN:-false}" != "true" ]; then
  echo "fdroid.sh skipped: RUN_FDROID_MAIN is not enabled."
  exit 0
fi

if [ "${GITHUB_ACTIONS:-false}" = "true" ] && [ "${GITHUB_REF_NAME:-}" != "main" ]; then
  echo "fdroid.sh skipped: this workflow is not running on main."
  exit 0
fi

echo "========================================"
echo " Freetime Maker F-Droid Repository"
echo "========================================"

echo
echo "==> Building all apps..."
echo "fdroid build --all"

fdroid build --all

echo
echo "==> Publishing apps..."
echo "fdroid publish"

fdroid publish

echo
echo "==> Updating repository..."
echo "fdroid update"

fdroid update

echo
echo "========================================"
echo " Done."
echo "========================================"