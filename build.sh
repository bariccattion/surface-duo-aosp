#!/bin/bash

# ================================================================
# DUO-DE AOSP 16.0 QPR2 Buildbot
# Based on Infinity X GSI
# by Archfx
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

echo
echo -e "${BOLD}=========================================${NC}"
echo -e "${BOLD}   DUO-DE AOSP 16.0 QPR2 Buildbot"
echo -e "   Based on Infinity X GSI"
echo -e "   by Archfx"
echo -e "${BOLD}=========================================${NC}"
echo

export BUILD_NUMBER="$(date +%y%m%d)"

BUILD_ROOT="$PWD/duo-de"
BUILD_DIR="$PWD/duo-de/builds"
INFINITY_MANIFEST_URL="https://github.com/ProjectInfinity-X/manifest"
INFINITY_MANIFEST_BRANCH="16"
PATCHES_DIR="$BUILD_ROOT/patches"

log_info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}      $1"; }
log_step()    { echo -e "\n${CYAN}${BOLD}==>${NC} $1"; }

initRepos() {
    log_step "Initializing workspace"
    repo init --depth=1 --no-repo-verify --git-lfs \
        -u "$INFINITY_MANIFEST_URL" \
        -b "$INFINITY_MANIFEST_BRANCH" \
        -g default,-mips,-darwin,-notdefault --config-name
    log_success "Repo initialized"

    log_info "Installing DUO-DE local manifests"
    mkdir -p .repo/local_manifests
    cp "$BUILD_ROOT/build/duode.xml" .repo/local_manifests/duode.xml
    [ -f "$BUILD_ROOT/build/remove.xml" ] && cp "$BUILD_ROOT/build/remove.xml" .repo/local_manifests/remove.xml
    log_success "Local manifests installed"
}

syncRepos() {
    log_step "Syncing repos"
    repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j"$(nproc --all)" \
        || repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j"$(nproc --all)"
    log_success "Repo sync complete"
}

applyPatches() {
    log_step "Applying patches"
    ln -sf "$BUILD_ROOT/patches" "$PWD/patches"

    log_info "TrebleDroid patches"
    bash "$PATCHES_DIR/apply-patches.sh" "$(pwd)" trebledroid

    log_info "Ponces personal patches"
    bash "$PATCHES_DIR/apply-patches.sh" "$(pwd)" ponces

    log_info "Doze-off personal patches"
    bash "$PATCHES_DIR/apply-patches.sh" "$(pwd)" doze-off

    log_info "DUO-DE patches"
    bash "$BUILD_ROOT/patch.sh" "$BUILD_ROOT" duo

    log_step "Generating makefiles"
    cd device/phh/treble
    cp "$BUILD_ROOT/build/aosp.mk" .
    bash generate.sh aosp
    cd ../../..
    log_success "Makefiles generated"
}

setupEnv() {
    log_step "Setting up build environment"
    mkdir -p "$BUILD_DIR"
    source build/envsetup.sh > /dev/null 2>&1
    source build/core/build_id.mk
    log_success "Build environment ready"
}

buildTrebleApp() {
    log_step "Building treble_app"
    cd treble_app
    bash build.sh release
    cp TrebleApp.apk ../vendor/hardware_overlay/TrebleApp/app.apk
    cd ..
    log_success "Treble app built"
}

buildVariant() {
    local variant="$1"
    log_step "Building $variant"
    lunch "$variant"-userdebug
    make -j"$(nproc --all)" installclean > /dev/null 2>&1
    make -j"$(nproc --all)" systemimage 2>&1 | tail -1
    make -j"$(nproc --all)" target-files-package otatools 2>&1 | tail -1
    bash "$BUILD_ROOT/sign.sh" "$BUILD_ROOT/signing-keys" "$OUT/signed-target_files.zip"
    unzip -jqo "$OUT/signed-target_files.zip" IMAGES/system.img -d "$OUT"
    mv "$OUT/system.img" "$BUILD_DIR/system-$variant.img"
    log_success "Image: $BUILD_DIR/system-$variant.img"
}

buildVariants() {
    buildVariant treble_arm64_bgN
    buildVariant treble_arm64_bvN
}

generatePackages() {
    log_step "Generating packages"
    local buildDate="$(date +%Y%m%d)"
    find "$BUILD_DIR/" -name "system-treble_*.img" | while read -r file; do
        filename="$(basename "$file")"
        [[ "$filename" == *"_a64"* ]] && arch="arm32_binder64" || arch="arm64"
        [[ "$filename" == *"_bvN"* ]] && variant="vanilla" || variant="gapps"
        name="aosp-${arch}-ab-${variant}-16.0-$buildDate"
        log_info "Compressing $name.img"
        xz -cv "$file" -T0 > "$BUILD_DIR/$name.img.xz"
    done
    rm -rf "$BUILD_DIR"/system-*.img
    log_success "Packages generated"
}

generateOta() {
    log_step "Generating OTA metadata"
    local version="$(date +v%Y.%m.%d)"
    local buildDate="$(date +%Y%m%d)"
    local timestamp="$START"
    local json="{\"version\": \"$version\",\"date\": \"$timestamp\",\"variants\": ["
    find "$BUILD_DIR/" -name "aosp-*-16.0-$buildDate.img.xz" | sort | {
        while read -r file; do
            filename="$(basename "$file")"
            [[ "$filename" == *"-arm32"* ]] && arch="a64" || arch="arm64"
            [[ "$filename" == *"-vanilla"* ]] && variant="v" || variant="g"
            name="treble_${arch}_b${variant}N"
            size=$(wc -c < "$file")
            url="https://github.com/bariccattion/surface-duo-aosp/releases/download/$version/$filename"
            json="${json} {\"name\": \"$name\",\"size\": \"$size\",\"url\": \"$url\"},"
        done
        json="${json%?}]}"
        echo "$json" | jq . > "$BUILD_ROOT/config/ota.json"
    }
    log_success "OTA metadata generated"
}

uploadOTA() {
    bash "$BUILD_ROOT/upload.sh"
}

START=$(date +%s)

initRepos
syncRepos
applyPatches
setupEnv
buildTrebleApp
buildVariants
generatePackages
generateOta
# uploadOTA

END=$(date +%s)
ELAPSED=$((END - START))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo
echo -e "${GREEN}${BOLD}  Buildbot complete${NC} — ${MINUTES}m ${SECONDS}s"
echo
