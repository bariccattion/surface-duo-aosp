# Surface-duo Dual Experience [duo-de][A16 QPR2]

The Surface Duo, Microsoft's dual-screen Android device, aimed to redefine mobile productivity by offering a unique form factor that combined the versatility of two screens with the familiarity of the Android operating system. Although Microsoft officially ceased updates and support for the Surface Duo line in early 2023, with AOSP GSI and the help of the open-source community, it is time to give a second life to this awesome and unique hardware.

DUO-DE is a GSI variant Android ROM created for Microsoft Surface Duo devices, offering a clean AOSP experience. This build combines gapps/vanila variants of the GSI ROM from [ponces](https://github.com/ponces/treble_aosp) with desktop mode enabled + various tweaks to make it nice and smooth with the help of [thain](https://github.com/thai-ng) tweaks. All credits go to respective developers.

## Posture Engine and Dual Modes

With the posture processor engine, both duo1 and duo2 react to various postures. Specifically, the touch configurations and display settings will toggle between left-screen phone mode, right-screen phone mode, and tablet mode based on the hinge position. The hinge gaps can be enabled/disabled through the treble app.

You can control the active display from quick settings. You can see it in action [here](https://x.com/Archfx/status/1869969450419790257). To add this quick setting tile, use the pencil icon in the notification panel and drag and drop the "Active Screen" tile to your panel.

This ROM switches between tablet mode (first image) and phone mode (second image) when you change the postures or active screen. These modes are optimized (both visually and utility-wise) for each of the situations and the screen's real state. Additionally, it supports peak mode display of device status when the device is unfolded partially.

> [!TIP]
> In case your device does not react to tent or ramp mode (landscaped phone mode) by default, you have to enable it from the `Home settings`. When you are in Phone mode, click and hold on the desktop, click `Home settings` on the popup menu, and enable the `Allow home screen rotation` feature. This will enable the launcher to serve the Tent mode and Ramp modes.

### Floating Windows
Floating windowed mode can be enabled/disabled for tablet mode and phone mode separately. To do that, click and hold the desktop, click `Home settings`, and find the settings `Tablet Mode Floating Windows` and `Phone Mode Floating Windows`. 

## Security

All DUO-DE releases are signed with [release keys](https://source.android.com/docs/core/ota/sign_builds), ensuring protection against malicious OTA updates and unauthorized system application replacements. Additionally, DUO-DE passes [play integrity checks](https://developer.android.com/google/play/integrity/overview), safeguarding against malicious applications. For more details about the security of GSI images like DUO-DE, visit [this post](https://archfx.me/posts/2024/12/androidsecurity/).

## Flashing steps
Following are the steps to flash this image to your surface duo.

1. Download the release. 
```shell
wget https://github.com/Archfx/duo-de/releases/download/[[version]]/aosp-arm64-ab-gapps-15.0-[[version]].img.xz
```
2. Extract the compressed `*.xz` file to obtain the `*.img`. (Windows users can use something like 7-zip, Linux and Mac users can use either of the following commands with respective commandline utilities).
```shell
tar -xf aosp-arm64-ab-gapps-15.0-[[version]].img.xz #tar utility
```
```shell
gunzip aosp-arm64-ab-gapps-15.0-[[version]].img.xz #gunzip utility
```
3. If you are migrating from Android 12L (stock) follow this step. You need to unlock the bootloader before proceeding. Please pay attention to commands, do not copy and execute the commands blindly.
```shell
adb reboot fastboot
fastboot delete-logical-partition system_ext
fastboot delete-logical-partition product

#get the current slot
fastboot getvar current-slot
# if current slot is a, delete the system_b
fastboot delete-logical-partition system_b
# if current slot is b, delete the system_a
fastboot delete-logical-partition system_a

fastboot flash system aosp-arm64-ab-gapps-15.0-[[version]].img
fastboot reboot 
# upon reboot, it will prompt to wipe the user data partition.
```
4. Migrating from 13/14 pixel experience, follow the below steps 
```shell
adb reboot fastboot
fastboot flash system aosp-arm64-ab-gapps-15.0-[[version]].img
fastboot reboot 
```
5. When the device is booted, perform a manual reboot to apply the first-time configurations correctly.
6. Enable the following settings (for enabling the floating windows) from the developer options and perform a manual reboot.  
> - Force activities to be resizable
> - Enable freeform windows
> - Enable non-resizable in multi-window
7. Once you flash a **duo-de** version using the above steps, subsequent updates will be received using OTA. You can check updates using ``settings -> system -> system updates``.
   > If prompted to select the default updater, select `PHH treble updater` for always.
8. Enable the ideal `Treble Settings` as outlined [here](https://github.com/Archfx/duo-de/discussions/81). 
9. If you wish to see future updates and feature improvements, consider _starring_ (★) the project—it motivates the development of new releases!

## Building from source

1. Build the Docker image
```
docker build -f build/Dockerfile -t duo-de/treble .
```

2. Run the build container
```
mkdir builds
docker run --rm --privileged \
    --name treble \
    --volume $(pwd)/builds:/aosp/duo-de/builds \
    --volume /path/to/signing-keys:/aosp/archfx-priv/keys \
    duo-de/treble treblebuild
```

3. Collect output
```
Built images land in builds/ as:
- aosp-arm64-ab-gapps-16.0-YYYYMMDD.img.xz
- aosp-arm64-ab-vanilla-16.0-YYYYMMDD.img.xz
```

## Credits
These people have helped this project in some way or another, so they should be the ones who receive all the credit:

[phhusson](https://github.com/phhusson) [AndyYan](https://github.com/AndyCGYan) [eremitein](https://github.com/eremitein) [kdrag0n](https://github.com/kdrag0n) [Peter Cai](https://github.com/PeterCxy) [haridhayal11](https://github.com/haridhayal11) [sooti](https://github.com/sooti) [Iceows](https://github.com/Iceows) [ChonDoit](https://github.com/ChonDoit) [ponces](https://github.com/ponces) [thai-ng](https://github.com/thai-ng) [farmerbb](https://github.com/farmerbb) [Ethanol10](https://github.com/Ethanol10)






