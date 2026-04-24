# Pixel 9a Testing Guide

This project now has a physical-device smoke test at `integration_test/pixel_9a_smoke_test.dart`. It launches the app on the phone and checks that the main tabs render and navigate correctly.

## 1. Finish the Windows Android setup

On this machine, Android tooling is configured as:

- Flutter SDK found at `C:\src\flutter`.
- Android SDK found at `C:\Android\Sdk`.
- Android SDK Platform 36, Build-Tools 36.0.0, Platform-Tools, and Google USB Driver are installed.
- Android SDK licenses are accepted.
- `flutter` was added to the user `PATH`; open a new terminal if the current one still cannot find it.
- No Pixel device is detected by ADB until USB debugging is enabled and authorized on the phone.

If you ever need to recreate the SDK setup, install Android Studio, then open it once and install:

- Android SDK Platform
- Android SDK Platform-Tools
- Android SDK Build-Tools
- Android SDK Command-line Tools
- Android SDK Platform for the API level Android Studio recommends

After installing the SDK, either add Flutter to your user `PATH` or keep using the full path:

```powershell
C:\src\flutter\bin\flutter.bat doctor -v
```

If Android Studio installed the SDK somewhere Flutter does not find, point Flutter at it:

```powershell
C:\src\flutter\bin\flutter.bat config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
```

For this machine, the configured SDK command is:

```powershell
C:\src\flutter\bin\flutter.bat config --android-sdk C:\Android\Sdk
```

Then accept Android licenses:

```powershell
C:\src\flutter\bin\flutter.bat doctor --android-licenses
```

## 2. Enable USB debugging on the Pixel 9a

On the Pixel 9a:

1. Open Settings.
2. Go to About phone.
3. Tap Build number 7 times to enable Developer options.
4. Go back to Settings, then System, then Developer options.
5. Enable USB debugging.
6. Connect the phone over USB.
7. Accept the "Allow USB debugging?" prompt on the phone.

Use a USB data cable, not a charge-only cable.

## 3. Confirm Flutter can see the phone

From the project root:

```powershell
C:\src\flutter\bin\flutter.bat devices
```

You should see an Android device entry. If the phone is listed as unauthorized, unlock the phone and accept the USB debugging prompt. If it does not appear, run:

```powershell
$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe devices
```

Then reconnect the cable and check the phone prompt again.

## 4. Run normal local checks

Run these before testing on the phone:

```powershell
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat test
```

## 5. Run the Pixel 9a smoke test

Once `flutter devices` shows the phone, run:

```powershell
C:\src\flutter\bin\flutter.bat test integration_test\pixel_9a_smoke_test.dart -d <device-id>
```

Use the Android device id shown by `flutter devices`. If the Pixel is the only Android device attached, this usually works too:

```powershell
C:\src\flutter\bin\flutter.bat test integration_test\pixel_9a_smoke_test.dart -d android
```

In VS Code, you can also run the `Flutter: Pixel 9a Smoke Test` task after the device is detected.

## 6. Manual test pass

After the smoke test passes, do one quick manual pass on the Pixel 9a:

- Launch the app with `C:\src\flutter\bin\flutter.bat run -d <device-id>`.
- Check Dashboard renders with "Quick Actions".
- Open Library and confirm the empty state is readable.
- Open Analysis and confirm the history view renders.
- Open Settings and toggle theme, units, and audio cues.
- Rotate the phone and check that text stays readable.
- Close and reopen the app to confirm settings persist.

## Troubleshooting

- `Unable to locate Android SDK`: install Android Studio's SDK tools or run `flutter config --android-sdk`.
- Device not listed: enable USB debugging, use a data cable, unlock the phone, and accept the authorization prompt.
- Windows sees `Pixel 9a` but `adb devices` is empty: the phone is connected as file transfer only. Enable Developer options, enable USB debugging, unplug/replug, and accept the RSA prompt.
- USB debugging is already enabled but no prompt appears: on the phone, open Developer options, tap Revoke USB debugging authorizations, toggle USB debugging off and on, then reconnect the cable.
- `adb` shows `unauthorized`: revoke USB debugging authorizations in Developer options, unplug, replug, and accept the prompt again.
- Test hangs during install: disconnect other Android devices and rerun with the exact Pixel device id.
