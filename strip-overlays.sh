#!/bin/bash

# Remove OEM-specific overlay directories (Surface Duo only needs generic + Qualcomm overlays)
cd /aosp/source/vendor/hardware_overlay

rm -rf Alldocube Asus Blackview bq CUBOT Doogee DuoQin Essential Fairphone \
    Hisense Hotwav HTC Huawei Infinix Lenovo LG MBI Meizu Moto Multilaser \
    Nokia Nubia OnePlus ONN OPPO Oukitel Razer Realme Samsung Sharp Sony \
    Teclast Tecno Teracube Umidigi Unihertz Vivo Vsmart Xiaomi

rm -rf HW-IMS MTK-IMS SEC-IMS SPRD-IMS
rm -f azure-pipelines.yml

cat > overlay.mk << 'OVERLAYEOF'
PRODUCT_PACKAGES += \
	HardwareOverlayPicker \
	QtiAudio \
	TrebleApp \
	treble-overlay-NavBar \
	treble-overlay-NightMode \
	treble-overlay-SystemUI-FalseLocks \
	treble-overlay-Telephony-LTE \
	treble-overlay-caf-ims \
	treble-overlay-devinputjack \
	treble-overlay-highpriomisc \
	treble-overlay-misc-aod \
	treble-overlay-misc-aod-systemui \
	treble-overlay-misc-biometrics \
	treble-overlay-misc-dt2w \
	treble-overlay-misc-launcher3 \
	treble-overlay-misc-minimal-brightness \
	treble-overlay-misc-spen-pointer \
	treble-overlay-misc-transparent-pointer \
	treble-overlay-tethering \
	treble-overlay-tethering-nobpf \
	treble-overlay-telephony-caf-ims \
	treble-overlay-wifi \
	treble-overlay-wifi5g
OVERLAYEOF

echo "  Stripped OEM overlays from vendor/hardware_overlay"
