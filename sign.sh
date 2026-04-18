#!/bin/bash

# ================================================================
# DUO-DE ROM Signing Script
# Signs target files with release keys
# ================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

KEYSDIR="$1"
OUTFILE="$2"

if [ -z "$KEYSDIR" ]; then
    KEYSDIR="$HOME/.android-certs"
fi

if [ -z "$OUTFILE" ]; then
    OUTFILE="signed-target_files.zip"
fi

if [ ! -d "$KEYSDIR" ]; then
    echo -e "${RED}[ERROR]${NC}  Keys directory not found: $KEYSDIR"
    echo -e "         Set KEYS_DIR or pass as first argument"
    exit 1
fi

echo -e "  ${CYAN}[SIGN]${NC}    Signing target files"
echo -e "    Keys:    $KEYSDIR"
echo -e "    Output:  $OUTFILE"

TARGET_INPUT=$(ls -1 $OUT/obj/PACKAGING/target_files_intermediates/*-target_files*.zip 2>/dev/null | head -1)

if [ -z "$TARGET_INPUT" ]; then
    echo -e "${RED}[ERROR]${NC}  No target_files zip found in $OUT"
    exit 1
fi

echo -e "    Input:   $TARGET_INPUT"
echo

sign_target_files_apks -o -d "$KEYSDIR" \
    --extra_apks AdServicesApk.apk="$KEYSDIR/releasekey" \
    --extra_apks FederatedCompute.apk="$KEYSDIR/releasekey" \
    --extra_apks HalfSheetUX.apk="$KEYSDIR/releasekey" \
    --extra_apks HealthConnectBackupRestore.apk="$KEYSDIR/releasekey" \
    --extra_apks HealthConnectController.apk="$KEYSDIR/releasekey" \
    --extra_apks OsuLogin.apk="$KEYSDIR/releasekey" \
    --extra_apks SafetyCenterResources.apk="$KEYSDIR/releasekey" \
    --extra_apks ServiceConnectivityResources.apk="$KEYSDIR/releasekey" \
    --extra_apks ServiceUwbResources.apk="$KEYSDIR/releasekey" \
    --extra_apks ServiceWifiResources.apk="$KEYSDIR/releasekey" \
    --extra_apks WifiDialog.apk="$KEYSDIR/releasekey" \
    "$TARGET_INPUT" \
    "$OUTFILE"

echo
echo -e "  ${GREEN}[OK]${NC}      Signed: $OUTFILE"
echo
