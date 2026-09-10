#!/usr/bin/env bash

set -euo pipefail

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