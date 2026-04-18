#!/bin/bash

# ================================================================
# DUO-DE Patch Sync Script
# Syncs latest Infinity X patches from Doze-off/patches
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
echo -e "${BOLD}   DUO-DE Patch Syncbot"
echo -e "   Based on Infinity X GSI"
echo -e "   by Archfx"
echo -e "${BOLD}=========================================${NC}"
echo

BL="$PWD/duo-de"
TD="patches-16.2"

START=$(date +%s)

log_info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}      $1"; }

log_info "Cloning Infinity X patches (branch: $TD)"
rm -rf /tmp/infinity_patches
git clone --depth=1 https://github.com/Doze-off/patches -b "$TD" /tmp/infinity_patches
log_success "Patches cloned"

log_info "Updating trebledroid patches"
rm -rf "$BL/patches/trebledroid"
cp -R /tmp/infinity_patches/trebledroid "$BL/patches/trebledroid"
log_success "Trebledroid patches updated"

log_info "Note: doze-off patches are curated manually, not auto-synced"
log_info "Note: ponces patches are kept as reference, not auto-synced"

log_info "Cleaning up temp files"
rm -rf /tmp/infinity_patches
log_success "Cleanup done"

END=$(date +%s)
ELAPSED=$((END - START))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo
echo -e "${GREEN}${BOLD}  Sync complete${NC} — ${MINUTES}m ${SECONDS}s"
echo
