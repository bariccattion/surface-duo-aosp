$(call inherit-product, vendor/surface-duo/config/common.mk)

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.system.ota.json_url=https://raw.githubusercontent.com/bariccattion/surface-duo-aosp/android-16.2/config/ota.json
