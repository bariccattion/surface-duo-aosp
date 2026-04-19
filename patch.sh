#!/bin/bash

# ================================================================
# Surface Duo Custom Patch Application Script
# Applies Surface Duo specific patches (posture, overlays, etc.)
# ================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

patches="$(readlink -f -- "$1")"
tree="$2"

if [ -z "$patches" ] || [ -z "$tree" ]; then
    echo -e "${RED}Usage: $0 <patches_root> <tree_name>${NC}"
    exit 1
fi

PATCH_DIR="$patches/patches/$tree"

if [ ! -d "$PATCH_DIR" ]; then
    echo -e "  ${YELLOW}[WARN]${NC}  Patch directory $PATCH_DIR not found, skipping."
    exit 0
fi

echo -e "  ${CYAN}[Surface Duo]${NC} Applying ${BOLD}$tree${NC} patches from $PATCH_DIR"

TOTAL=0
APPLIED=0
SKIPPED=0
FAILED=0

PROJECTS=()
for project in $(cd "$PATCH_DIR" && echo *); do
    [ -d "$PATCH_DIR/$project" ] && PROJECTS+=("$project")
done

TOTAL_PROJECTS=${#PROJECTS[@]}
PROJ_NUM=0

for project in "${PROJECTS[@]}"; do
    PROJ_NUM=$((PROJ_NUM + 1))

    local_p="$(echo "$project" | tr '_' '/' | sed -e 's;platform/;;g')"
    [ "$local_p" == "build" ] && local_p="build/make"
    [ "$local_p" == "device/phh/treble" ] && local_p="device/phh/treble"
    [ "$local_p" == "system/sepolicy" ] && local_p="system/sepolicy"
    [ "$local_p" == "treble/app" ] && local_p="treble_app"
    [ "$local_p" == "vendor/hardware/overlay" ] && local_p="vendor/hardware_overlay"

    if [ ! -d "$local_p" ]; then
        echo -e "    ${DIM}[$PROJ_NUM/$TOTAL_PROJECTS]${NC} ${YELLOW}SKIP${NC}  $local_p (not found)"
        continue
    fi

    PATCH_FILES=()
    for pf in "$PATCH_DIR/$project"/*.patch; do
        [ -f "$pf" ] && PATCH_FILES+=("$pf")
    done
    local_total=${#PATCH_FILES[@]}

    if [ "$local_total" -eq 0 ]; then
        continue
    fi

    echo -e "    ${DIM}[$PROJ_NUM/$TOTAL_PROJECTS]${NC} ${BLUE}....${NC}  $local_p ($local_total patches)"

    pushd "$local_p" > /dev/null 2>&1

    local_num=0
    for patch_file in "${PATCH_FILES[@]}"; do
        local_num=$((local_num + 1))
        TOTAL=$((TOTAL + 1))
        patch_name="$(basename "$patch_file")"

        if git am "$patch_file" > /dev/null 2>&1; then
            echo -e "      ${DIM}[$local_num/$local_total]${NC} ${GREEN} OK ${NC}  $patch_name"
            APPLIED=$((APPLIED + 1))
        else
            git am --abort > /dev/null 2>&1 || true
            git checkout . > /dev/null 2>&1 || true

            if git apply --check -R "$patch_file" > /dev/null 2>&1; then
                echo -e "      ${DIM}[$local_num/$local_total]${NC} ${DIM}SKIP${NC}  $patch_name (already applied)"
                SKIPPED=$((SKIPPED + 1))
            else
                echo -e "      ${DIM}[$local_num/$local_total]${NC} ${RED}FAIL${NC}  $patch_name"
                echo -e "        ${DIM}--- git apply --check ---${NC}"
                git apply --check "$patch_file" 2>&1 | sed 's/^/        /'
                echo -e "        ${DIM}--- context (first 3 hunks) ---${NC}"
                grep '^@@' "$patch_file" | head -3 | sed 's/^/        /'
                echo -e "        ${DIM}--- patch targets ---${NC}"
                grep '^--- a/\|^+++ b/' "$patch_file" | sed 's/^/        /'
                FAILED=$((FAILED + 1))
            fi
        fi
    done

    popd > /dev/null 2>&1
done

echo
echo -e "  ${CYAN}Surface Duo summary:${NC}  ${GREEN}$APPLIED applied${NC}, ${DIM}$SKIPPED skipped${NC}, ${RED}$FAILED failed${NC} (of $TOTAL total)"
echo

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
