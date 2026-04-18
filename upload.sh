#!/bin/bash

# ================================================================
# DUO-DE Upload Script
# Creates GitHub release and uploads build artifacts
# ================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo
echo -e "${BOLD}=========================================${NC}"
echo -e "${BOLD}   DUO-DE Uploadbot"
echo -e "   Based on Infinity X GSI"
echo -e "   by Archfx"
echo -e "${BOLD}=========================================${NC}"
echo

BL="$PWD/duo-de"
BD="$PWD/duo-de/builds"
TAG="$(date +v%Y.%m.%d)"
GUSER="bariccattion"
GREPO="surface-duo-aosp"

SKIPOTA=false
if [ "${1:-}" == "--skip-ota" ]; then
    SKIPOTA=true
fi

log_info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}      $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC}   $1"; }
log_upload()  { echo -e "${CYAN}[UPLOAD]${NC}  $1"; }

START=$(date +%s)

log_info "Creating release $TAG"
gh release create "$TAG" --repo "$GUSER/$GREPO" --title "$TAG"
log_success "Release $TAG created"

BUILD_DATE="$(date +%Y%m%d)"
UPLOADED=0

find "$BD/" -name "aosp-*-16.0-$BUILD_DATE.img.xz" | while read -r file; do
    filename="$(basename "$file")"
    SIZE=$(du -h "$file" | awk '{print $1}')
    log_upload "$filename ($SIZE)"
    if gh release upload "$TAG" "$file" --repo "$GUSER/$GREPO"; then
        log_success "Uploaded $filename"
        UPLOADED=$((UPLOADED + 1))
    else
        log_error "Failed to upload $filename"
    fi
done

if [ "$SKIPOTA" = false ]; then
    log_info "Updating OTA file"
    cd "$BL"
    git add config/ota.json
    git commit -m "build: Bump OTA to $TAG"
    git push --set-upstream origin android-16.2 || git push --set-upstream origin android-16.2
    cd ..
    log_success "OTA updated and pushed"
else
    log_info "Skipping OTA update (--skip-ota)"
fi

END=$(date +%s)
ELAPSED=$((END - START))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo
echo -e "${GREEN}${BOLD}  Upload complete${NC} — ${MINUTES}m ${SECONDS}s"
echo
