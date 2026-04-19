#!/bin/bash

# ================================================================
# Surface Duo AOSP — Full Build Script
# Based on Infinity X GSI
# ================================================================
# Usage:
#   ./build.sh                    # Full build (all steps)
#   ./build.sh --skip-sync        # Skip repo init/sync
#   ./build.sh --skip-patches     # Skip patch application
#   ./build.sh --gapps-only       # Build only gapps variant
#   ./build.sh --vanilla-only     # Build only vanilla variant
#   ./build.sh --skip-sign        # Skip signing step
#   ./build.sh --skip-upload      # Skip upload step
# ================================================================

set -euo pipefail

# ----------------------------------------------------------------
# Colors and formatting
# ----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}      $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}    $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC}   $1"; }
log_step()    { echo -e "\n${CYAN}${BOLD}==> $1${NC}"; }
log_sub()     { echo -e "  ${DIM}->${NC} $1"; }

live_run() {
    local desc="$1"
    shift
    local start=$(date +%s)
    local rc=0
    if [ -t 1 ]; then
        echo -ne "  ${BLUE}[RUN ]${NC}    ${desc}..."
        set +euo pipefail
        "$@" 2>&1 | while IFS= read -r line; do
            local now=$(date +%s)
            local s=$(( (now - start) % 60 ))
            local m=$(( (now - start) / 60 ))
            echo -ne "\r  ${BLUE}[RUN ]${NC}    ${desc} [${m}m${s}s] ${DIM}${line:0:120}${NC}\033[K"
        done
        rc=${PIPESTATUS[0]:-0}
        set -euo pipefail
        local now=$(date +%s)
        local s=$(( (now - start) % 60 ))
        local m=$(( (now - start) / 60 ))
        if [ $rc -eq 0 ]; then
            echo -e "\r  ${GREEN}[OK]${NC}      ${desc} [${m}m${s}s]\033[K"
        else
            echo -e "\r  ${RED}[FAIL]${NC}    ${desc} [${m}m${s}s] (exit $rc)\033[K"
            return $rc
        fi
    else
        echo -e "  ${BLUE}[RUN ]${NC}    ${desc}..."
        set +euo pipefail
        "$@" 2>&1 | while IFS= read -r line; do
            local now=$(date +%s)
            local s=$(( (now - start) % 60 ))
            local m=$(( (now - start) / 60 ))
            echo -e "  ${DIM}[${m}m${s}s]${NC} ${line:0:200}"
        done
        rc=${PIPESTATUS[0]:-0}
        set -euo pipefail
        local now=$(date +%s)
        local s=$(( (now - start) % 60 ))
        local m=$(( (now - start) / 60 ))
        if [ $rc -eq 0 ]; then
            echo -e "  ${GREEN}[OK]${NC}      ${desc} [${m}m${s}s]"
        else
            echo -e "  ${RED}[FAIL]${NC}    ${desc} [${m}m${s}s] (exit $rc)"
            return $rc
        fi
    fi
}

elapsed() {
    local s=$(( $1 % 60 ))
    local m=$(( ($1 / 60) % 60 ))
    local h=$(( $1 / 3600 ))
    if [ $h -gt 0 ]; then
        printf "%dh %dm %ds" $h $m $s
    else
        printf "%dm %ds" $m $s
    fi
}

# ----------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------
BUILD_ROOT="/aosp/surface-duo-aosp"
BUILD_DIR="/aosp/surface-duo-aosp/out"
SOURCE_DIR="/aosp/source"
INFINITY_MANIFEST_URL="https://github.com/ProjectInfinity-X/manifest"
INFINITY_MANIFEST_BRANCH="16"
PATCHES_DIR="$BUILD_ROOT/patches"
KEYS_DIR="${KEYS_DIR:-/aosp/surface-duo-aosp/signing-keys}"

SKIP_PATCHES=false
SKIP_SIGN=false
SKIP_UPLOAD=false
BUILD_GAPPS=true
BUILD_VANILLA=true
BUILD_JOBS="${BUILD_JOBS:-$(nproc --all)}"

for arg in "$@"; do
    case "$arg" in
        --skip-patches) SKIP_PATCHES=true ;;
        --skip-sign)    SKIP_SIGN=true ;;
        --skip-upload)  SKIP_UPLOAD=true ;;
        --gapps-only)   BUILD_VANILLA=false ;;
        --vanilla-only) BUILD_GAPPS=false ;;
        -j*)            BUILD_JOBS="${arg#-j}" ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-patches   Skip patch application"
            echo "  --skip-sign      Skip signing step"
            echo "  --skip-upload    Skip upload/release step"
            echo "  --gapps-only     Build only gapps variant"
            echo "  --vanilla-only   Build only vanilla variant"
            echo "  -j<N>            Set parallel job count"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *) log_error "Unknown option: $arg"; exit 1 ;;
    esac
done

# ----------------------------------------------------------------
# Banner
# ----------------------------------------------------------------
echo
echo -e "${BOLD}=========================================${NC}"
echo -e "${BOLD}   Surface Duo AOSP Build System"
echo -e "${BOLD}=========================================${NC}"
echo
echo -e "  Build date:   $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "  Source dir:   $SOURCE_DIR"
echo -e "  Output dir:   $BUILD_DIR"
echo -e "  Keys dir:     $KEYS_DIR"
echo -e "  Working dir:  $(pwd)"
echo -e "  Variants:     $([ "$BUILD_GAPPS" = true ] && echo -n "gapps ")$([ "$BUILD_VANILLA" = true ] && echo -n "vanilla")"
echo
echo -e "  Skip patches: $SKIP_PATCHES"
echo -e "  Skip sign:    $SKIP_SIGN"
echo -e "  Skip upload:  $SKIP_UPLOAD"
echo

START_TOTAL=$(date +%s)

# ----------------------------------------------------------------
# Step 1: Init and Sync
# ----------------------------------------------------------------
log_step "Step 1/8: Initializing and syncing repos"
STEP_START=$(date +%s)

    log_info "Initializing repo with Infinity X manifest (branch $INFINITY_MANIFEST_BRANCH)"
    cd "$SOURCE_DIR"
    repo init --depth=1 --no-repo-verify --git-lfs \
        -u "$INFINITY_MANIFEST_URL" \
        -b "$INFINITY_MANIFEST_BRANCH" \
        -g default,-mips,-darwin,-notdefault
    log_success "Repo initialized"

    log_info "Installing Surface Duo local manifests"
    rm -rf .repo/local_manifests
    mkdir -p .repo/local_manifests
    cp "$BUILD_ROOT/build/duode.xml" .repo/local_manifests/duode.xml
    [ -f "$BUILD_ROOT/build/remove.xml" ] && cp "$BUILD_ROOT/build/remove.xml" .repo/local_manifests/remove.xml
    log_success "Local manifests installed"

    log_info "Resetting source tree before sync"
    cd "$SOURCE_DIR"
    repo forall -c 'git reset --hard && git clean -fdx' 2>/dev/null || true

    log_info "Syncing source tree (this takes 20-60+ minutes)..."
    MAX_SYNC_RETRIES=5
    SYNC_RETRY=0
    SYNC_JOBS="$BUILD_JOBS"

    while [ $SYNC_RETRY -lt $MAX_SYNC_RETRIES ]; do
        SYNC_RETRY=$((SYNC_RETRY + 1))

        if repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j"$SYNC_JOBS" 2>&1 | tee /tmp/repo-sync.log; then
            if grep -qiE "error:|failed:" /tmp/repo-sync.log; then
                :
            else
                break
            fi
        fi

        if [ $SYNC_RETRY -eq $MAX_SYNC_RETRIES ]; then
            log_error "Repo sync failed after $MAX_SYNC_RETRIES attempts. Errors:"
            grep -iE "error:|failed:" /tmp/repo-sync.log | tail -20
            exit 1
        fi

        WAIT=$((SYNC_RETRY * 30))
        log_warn "Sync attempt $SYNC_RETRY/$MAX_SYNC_RETRIES had failures:"
        grep -iE "error:|failed:" /tmp/repo-sync.log | tail -10
        log_info "Waiting ${WAIT}s before retry with fewer jobs..."
        sleep "$WAIT"
        SYNC_JOBS=4
    done

    log_info "Creating patches symlink"
    ln -sf "$BUILD_ROOT/patches" "$SOURCE_DIR/patches"

    STEP_END=$(date +%s)
    log_success "Step 1 completed in $(elapsed $((STEP_END - STEP_START)))"

# ----------------------------------------------------------------
# Step 2: Apply patches
# ----------------------------------------------------------------
if [ "$SKIP_PATCHES" = false ]; then
    log_step "Step 2/8: Applying patches"
    STEP_START=$(date +%s)

    log_info "Resetting source tree (clean state for patching)"
    repo forall -c 'git reset --hard && git clean -fdx' > /dev/null 2>&1 || true

    log_info "Applying TrebleDroid patches"
    if bash "$PATCHES_DIR/apply-patches.sh" "$(pwd)" trebledroid; then
        log_success "TrebleDroid patches applied"
    else
        log_warn "Some TrebleDroid patches had issues (non-fatal)"
    fi

    log_info "Applying Doze-off personal patches"
    if bash "$PATCHES_DIR/apply-patches.sh" "$(pwd)" doze-off; then
        log_success "Doze-off patches applied"
    else
        log_warn "Some Doze-off patches had issues (non-fatal)"
    fi

    log_info "Applying Surface Duo patches"
    if bash "$BUILD_ROOT/patch.sh" "$BUILD_ROOT" duo; then
        log_success "Surface Duo patches applied"
    else
        log_warn "Some Surface Duo patches had issues (non-fatal)"
    fi

    STEP_END=$(date +%s)
    log_success "Step 2 completed in $(elapsed $((STEP_END - STEP_START)))"
else
    log_warn "Skipping patches (--skip-patches)"
fi

# ----------------------------------------------------------------
# Step 3: Generate makefiles
# ----------------------------------------------------------------
log_step "Step 3/8: Generating treble makefiles"
STEP_START=$(date +%s)

log_info "Copying aosp.mk and running generate.sh"
cd "$SOURCE_DIR/device/phh/treble"
cp "$BUILD_ROOT/build/aosp.mk" .
bash generate.sh aosp
cd "$SOURCE_DIR"
log_success "Makefiles generated"

STEP_END=$(date +%s)
log_success "Step 3 completed in $(elapsed $((STEP_END - STEP_START)))"

# ----------------------------------------------------------------
# Step 4: Build treble app
# ----------------------------------------------------------------
log_step "Step 4/8: Building treble app"
STEP_START=$(date +%s)

log_info "Building treble_app (release mode)"
cd "$SOURCE_DIR/treble_app"
live_run "Treble app build" bash build.sh release
cp TrebleApp.apk ../vendor/hardware_overlay/TrebleApp/app.apk
cd "$SOURCE_DIR"

STEP_END=$(date +%s)
log_success "Step 4 completed in $(elapsed $((STEP_END - STEP_START)))"

# ----------------------------------------------------------------
# Step 5: Setup build environment
# ----------------------------------------------------------------
log_step "Step 5/8: Setting up build environment"
STEP_START=$(date +%s)

mkdir -p "$BUILD_DIR"
log_info "Sourcing envsetup.sh from $SOURCE_DIR"
cd "$SOURCE_DIR"
set +euo pipefail
. build/envsetup.sh
log_success "Build environment ready"

STEP_END=$(date +%s)
log_success "Step 5 completed in $(elapsed $((STEP_END - STEP_START)))"

# ----------------------------------------------------------------
# Step 6: Build variants
# ----------------------------------------------------------------
log_step "Step 6/8: Building system images"
STEP_START=$(date +%s)

build_variant() {
    local variant="$1"
    local variant_start=$(date +%s)
    local log_file="$BUILD_DIR/build-${variant}-$(date +%Y%m%d-%H%M%S).log"

    echo
    log_info "=========================================="
    log_info "  Building variant: ${BOLD}$variant${NC}"
    log_info "=========================================="

    log_sub "Lunching $variant-userdebug"
    lunch "$variant"-userdebug

    log_sub "Running installclean"
    make -j"$BUILD_JOBS" installclean > /dev/null 2>&1
    make -j"$BUILD_JOBS" systemimage 2>&1 | tee "$log_file"

    if [ "$SKIP_SIGN" = false ]; then
        log_sub "Building target-files-package"
        make -j"$BUILD_JOBS" target-files-package otatools 2>&1 | tee -a "$log_file"

        log_sub "Signing target files"
        bash "$BUILD_ROOT/sign.sh" "$KEYS_DIR" "$OUT/signed-target_files.zip"

        log_sub "Extracting signed system.img"
        unzip -jqo "$OUT/signed-target_files.zip" IMAGES/system.img -d "$OUT"
    else
        log_warn "Skipping signing (--skip-sign)"
    fi

    log_sub "Copying image to output directory"
    cp "$OUT/system.img" "$BUILD_DIR/system-$variant.img"

    local variant_end=$(date +%s)
    log_success "Variant $variant completed in $(elapsed $((variant_end - variant_start)))"
    log_info "  Output: $BUILD_DIR/system-$variant.img"
    local img_size=$(duf "$BUILD_DIR/system-$variant.img" 2>/dev/null | tail -1 | awk '{print $2}' || du -h "$BUILD_DIR/system-$variant.img" | awk '{print $1}')
    log_info "  Size: $img_size"
}

if [ "$BUILD_GAPPS" = true ]; then
    build_variant treble_arm64_bgN
fi

if [ "$BUILD_VANILLA" = true ]; then
    build_variant treble_arm64_bvN
fi

STEP_END=$(date +%s)
log_success "Step 6 completed in $(elapsed $((STEP_END - STEP_START)))"

# ----------------------------------------------------------------
# Step 7: Generate packages
# ----------------------------------------------------------------
log_step "Step 7/8: Generating release packages"
STEP_START=$(date +%s)

BUILD_DATE="$(date +%Y%m%d)"
PACKAGE_COUNT=0

find "$BUILD_DIR/" -name "system-treble_*.img" | while read -r file; do
    filename="$(basename "$file")"
    [[ "$filename" == *"_a64"* ]] && arch="arm32_binder64" || arch="arm64"
    [[ "$filename" == *"_bvN"* ]] && variant="vanilla" || variant="gapps"
    name="aosp-${arch}-ab-${variant}-16.0-$BUILD_DATE"

    log_info "Compressing $name.img -> $name.img.xz"
    xz -cv "$file" -T0 > "$BUILD_DIR/$name.img.xz"
    PACKAGE_COUNT=$((PACKAGE_COUNT + 1))
done

rm -rf "$BUILD_DIR"/system-*.img
log_success "Packages generated"

STEP_END=$(date +%s)
log_success "Step 7 completed in $(elapsed $((STEP_END - STEP_START)))"

# ----------------------------------------------------------------
# Step 8: Generate OTA and upload
# ----------------------------------------------------------------
log_step "Step 8/8: Generating OTA metadata"
STEP_START=$(date +%s)

VERSION="$(date +v%Y.%m.%d)"
TIMESTAMP="$START_TOTAL"

log_info "Generating config/ota.json for version $VERSION"

JSON="{\"version\": \"$VERSION\",\"date\": \"$TIMESTAMP\",\"variants\": ["
find "$BUILD_DIR/" -name "aosp-*-16.0-$BUILD_DATE.img.xz" | sort | {
    while read -r file; do
        filename="$(basename "$file")"
        [[ "$filename" == *"-arm32"* ]] && arch="a64" || arch="arm64"
        [[ "$filename" == *"-vanilla"* ]] && variant="v" || variant="g"
        name="treble_${arch}_b${variant}N"
        size=$(wc -c < "$file")
        url="https://github.com/bariccattion/surface-duo-aosp/releases/download/$VERSION/$filename"
        JSON="${JSON} {\"name\": \"$name\",\"size\": \"$size\",\"url\": \"$url\"},"
    done
    JSON="${JSON%?}]}"
    echo "$JSON" | jq . > "$BUILD_ROOT/config/ota.json"
}
log_success "OTA metadata generated"

if [ "$SKIP_UPLOAD" = false ]; then
    log_info "Running upload script..."
    bash "$BUILD_ROOT/upload.sh"
else
    log_warn "Skipping upload (--skip-upload)"
fi

STEP_END=$(date +%s)
log_success "Step 8 completed in $(elapsed $((STEP_END - STEP_START)))"

# ----------------------------------------------------------------
# Summary
# ----------------------------------------------------------------
END_TOTAL=$(date +%s)
TOTAL_ELAPSED=$((END_TOTAL - START_TOTAL))

echo
echo -e "${BOLD}=========================================${NC}"
echo -e "${GREEN}${BOLD}  BUILD COMPLETE${NC}"
echo -e "${BOLD}=========================================${NC}"
echo
echo -e "  Total time:  $(elapsed $TOTAL_ELAPSED)"
echo -e "  Variants:    $([ "$BUILD_GAPPS" = true ] && echo -n "gapps ")$([ "$BUILD_VANILLA" = true ] && echo -n "vanilla")"
echo -e "  Output:      $BUILD_DIR/"
echo
echo -e "  Files:"
find "$BUILD_DIR/" -name "*.xz" -exec ls -lh {} \; | awk '{print "    " $NF "  (" $5 ")"}' | sed "s|$BUILD_DIR/||g"
echo
