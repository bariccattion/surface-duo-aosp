#!/bin/bash

# ================================================================
# Surface Duo AOSP Patch Application Script
# Applies TrebleDroid, doze-off and/or duo patches to AOSP source tree
# ================================================================
# Usage:
#   apply-patches.sh <source_dir> [trebledroid|doze-off|duo]
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

source_dir="$1"
patch_type="$2"

if [ -z "$source_dir" ]; then
    echo -e "${RED}Usage: $0 <source_dir> [trebledroid|doze-off|duo]${NC}"
    echo "  If patch_type is specified, only that type is applied."
    echo "  If not specified, all patch types are applied."
    exit 1
fi

patches_base="$source_dir/patches"

TOTAL_PATCHES=0
APPLIED=0
SKIPPED=0
FAILED=0

apply_patch_set() {
    local patch_set="$1"
    local patch_dir="$patches_base/$patch_set"

    if [ ! -d "$patch_dir" ]; then
        echo -e "  ${YELLOW}[WARN]${NC}  Patch directory $patch_dir not found, skipping."
        return
    fi

    local projects=()
    for project_dir in "$patch_dir"/*/; do
        [ -d "$project_dir" ] && projects+=("$project_dir")
    done

    local total_projects=${#projects[@]}
    echo -e "  ${CYAN}[PATCH]${NC} Applying ${BOLD}$patch_set${NC} patches (${total_projects} projects)"

    local proj_num=0
    for project_dir in "${projects[@]}"; do
        proj_num=$((proj_num + 1))
        local project_name=$(basename "$project_dir")

        local p="$(echo "$project_name" | tr '_' '/' | sed -e 's;platform/;;g')"
        [ "$p" == "build" ] && p="build/make"
        [ "$p" == "device/phh/treble" ] && p="device/phh/treble"
        [ "$p" == "system/sepolicy" ] && p="system/sepolicy"
        [ "$p" == "treble/app" ] && p="treble_app"
        [ "$p" == "vendor/hardware/overlay" ] && p="vendor/hardware_overlay"
        [ "$p" == "vendor/partner/gms" ] && p="vendor/partner_gms"

        local target_dir="$source_dir/$p"
        if [ ! -d "$target_dir" ]; then
            echo -e "    ${DIM}[$proj_num/$total_projects]${NC} ${YELLOW}SKIP${NC}  $p (directory not found)"
            continue
        fi

        local patch_files=()
        for pf in "$project_dir"*.patch; do
            [ -f "$pf" ] && patch_files+=("$pf")
        done
        local total_patches=${#patch_files[@]}

        if [ "$total_patches" -eq 0 ]; then
            echo -e "    ${DIM}[$proj_num/$total_projects]${NC} ${DIM}----${NC}  $p (no patches)"
            continue
        fi

        echo -e "    ${DIM}[$proj_num/$total_projects]${NC} ${BLUE}....${NC}  $p ($total_patches patches)"

        local patch_num=0
        pushd "$target_dir" > /dev/null

        for patch_file in "${patch_files[@]}"; do
            patch_num=$((patch_num + 1))
            TOTAL_PATCHES=$((TOTAL_PATCHES + 1))
            local patch_name=$(basename "$patch_file")

            if git apply --check -R "$patch_file" > /dev/null 2>&1; then
                echo -e "      ${DIM}[$patch_num/$total_patches]${NC} ${DIM}SKIP${NC}  $patch_name (already applied)"
                SKIPPED=$((SKIPPED + 1))
                continue
            fi

            if git am "$patch_file" > /dev/null 2>&1; then
                echo -e "      ${DIM}[$patch_num/$total_patches]${NC} ${GREEN} OK ${NC}  $patch_name"
                APPLIED=$((APPLIED + 1))
                continue
            fi

            git am --abort > /dev/null 2>&1 || true
            git checkout . > /dev/null 2>&1 || true

            echo -e "      ${DIM}[$patch_num/$total_patches]${NC} ${RED}FAIL${NC}  $patch_name"
            FAILED=$((FAILED + 1))

            echo -e "      ${DIM}[$patch_num/$total_patches]${NC} ${RED}FAIL${NC}  $patch_name"
            FAILED=$((FAILED + 1))
        done

        popd > /dev/null
    done
}

if [ -n "$patch_type" ]; then
    apply_patch_set "$patch_type"
else
    apply_patch_set "trebledroid"
    apply_patch_set "doze-off"
fi

echo
echo -e "  ${CYAN}Patch summary:${NC}  ${GREEN}$APPLIED applied${NC}, ${DIM}$SKIPPED skipped${NC}, ${RED}$FAILED failed${NC} (of $TOTAL_PATCHES total)"
echo

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
