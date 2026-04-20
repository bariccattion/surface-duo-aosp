# Infinity X GSI with Surface Duo support
# Inherits Infinity X vendor config first, then Surface Duo specifics

WITH_GAPPS := false

# Infinity X vendor config
$(call inherit-product, vendor/infinity/config/common.mk)
$(call inherit-product, vendor/infinity/config/common_full_phone.mk)
$(call inherit-product, vendor/infinity/config/BoardConfigLineage.mk)
$(call inherit-product, device/lineage/sepolicy/common/sepolicy.mk)
-include vendor/infinity/build/core/config.mk

TARGET_NO_KERNEL_OVERRIDE := true
TARGET_NO_KERNEL_IMAGE := true

PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false
LOCAL_UNINSTALLABLE_MODULE := true

SELINUX_IGNORE_NEVERALLOWS := true

override BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

TARGET_BOOT_ANIMATION_RES := 720
TARGET_SUPPORTS_BLUR := true
TARGET_SHIPS_FULL_GAPPS := false
TARGET_HAS_UDFPS := true
BYPASS_CHARGE_SUPPORTED := true

INFINITY_BUILD := tdgsi_arm64_ab
INFINITY_MAINTAINER := Bariccatti
INFINITY_BUILD_TYPE := UNOFFICIAL

# Surface Duo vendor config (APN, overlays, bootanimation, Duo packages)
$(call inherit-product, vendor/surface/config/common.mk)

# OTA
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.system.ota.json_url=https://raw.githubusercontent.com/bariccattion/surface-duo-aosp/android-16.2/config/ota.json

# VNDK versions for vendor compatibility (Duo 1/2 have Android 11 vendors)
PRODUCT_EXTRA_VNDK_VERSIONS += 28 29 30
