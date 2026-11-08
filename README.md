# Fire TV 4-Series debloat

A supervised Windows ADB case study for Amazon 4K50N402 (AFTNA1322D, shinagawa), Fire OS 8.1.8.5, build RS8185.3898N. Treat other firmware as unverified.

## What worked

- 24 user-0 package disables survived the final reboot.
- Homestead 2.1.0 redirected Home from Netflix and Prime Video after reboot using its accessibility service and READ_LOGS.
- Window, transition and animator duration scales remained at 0.5x.
- The owner confirmed Netflix and Prime Video playback, HDMI switching and that Alexa did not answer. Vizzini remained installed and Fire OS reset its microphone AppOp to allow. The exact reason voice stopped was not isolated. Homestead's on-device ADB and reapply were later enabled by the owner.
- Three cold launches per app in the final same-boot comparison gave medians of 754 to 681 ms (Netflix) and 1184 to 906 ms (Prime Video). Earlier runs were mixed. These are activity launch times, not playback times or proof of a sustained speedup.

## Procedure

1. Install official Android Platform Tools. Enable ADB debugging on the TV, connect on your local network and approve the TV prompt. Use an explicit target with every command.
2. Capture the build fingerprint, package state, current Home handler and settings locally. Keep the raw files private. For each candidate, record the user-0 installed and enabled states with dumpsys package.
3. Review and apply one batch at a time. For a package originally in the default state, use pm disable-user --user 0 PACKAGE and restore with pm default-state --user 0 PACKAGE. For an explicitly enabled package, restore with pm enable --user 0 PACKAGE.
4. Verify each batch, then reboot and confirm it persisted. Test Home, remote, HDMI, Settings, Wi-Fi, picture and sound, and play a title in both Netflix and Prime Video. Roll back a failing batch.
5. Use the official Homestead release and review its computer setup. Capture the original accessibility settings before enabling its service, and preserve any existing services. The stock launcher is the recovery path. Test Home from each streaming app before and after reboot.
6. If shortening transitions, capture each original global animation-scale value first. Restore a missing value by deleting its key and restore an existing value by putting that exact value back.
7. When finished, disconnect Windows ADB. Homestead reapply needs on-device ADB debugging. Check that unknown-app installation permissions are off unless intentionally needed.

See [the package record](PACKAGES.md) for exact package IDs and failed attempts.

## Upstream references

- [Amazon ADB setup](https://developer.amazon.com/docs/fire-tv/connecting-adb-to-device.html)
- [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools)
- [Homestead releases and setup](https://github.com/Sarg338/Homestead)
- [Independent report for the same model and build](https://dumbtv.org/tv/fire-tv#aftna1322d)

## Windows quick start

Download Android Platform Tools and extract it. In PowerShell, open this repository folder. On the TV, go to Settings > Device & Software > About, highlight the device name and press Select seven times if Developer Options is hidden. Enable ADB Debugging, then find the TV's IPv4 address under About > Network.

```powershell
$adb = 'C:\path\to\platform-tools\adb.exe'
$tv = '192.168.1.50:5555' # Replace with your TV address.
& $adb connect $tv
& $adb devices -l
.\FireTvDebloat.ps1 -Adb $adb -Target $tv -Action Audit
```

Accept the authorization prompt on the TV and confirm its status is **device**. Audit is read-only and rejects other models and builds. It reports Android's package state values (0 = default, 1 = explicitly enabled, 3 = disabled for the user). The rollback JSON contains your local TV address. Keep it private.

Apply a single group, starting with Apps. A new state file is required for every batch. If a command or core service check fails, the tool attempts to restore each touched package and reports any rollback failures.

```powershell
New-Item -ItemType Directory -Force .\local-state | Out-Null
.\FireTvDebloat.ps1 -Adb $adb -Target $tv -Action Apply -Group Apps -StateFile .\local-state\apps.json -Approve
```

The other groups are Telemetry, Demos, and Alexa. Run them separately with distinct state filenames. Verify Netflix and Prime Video playback, HDMI, picture, audio, and the remote between groups. Reboot using the TV menu, reconnect, and rerun Audit to verify persistence. If a batch fails your hands-on check, restore it using its saved file.

```powershell
.\FireTvDebloat.ps1 -Adb $adb -Target $tv -Action Restore -StateFile .\local-state\apps.json -Approve
& $adb disconnect $tv
```

### Homestead and animation settings

Launcher setup is manual. Install the official release APK with `& $adb -s $tv install .\homestead.apk` and open Homestead from the apps row. Record both secure settings first.

```powershell
& $adb -s $tv shell settings --user 0 get secure enabled_accessibility_services
& $adb -s $tv shell settings --user 0 get secure accessibility_enabled
```

Use Homestead's documented computer setup. For this TV, the working configuration used HomeRedirectService and READ_LOGS. If you have other accessibility services, append Homestead to the existing colon-separated list. Test Home from both streaming apps. To roll back, restore the exact prior accessibility values (use settings delete for previously missing keys) and uninstall com.homestead.launcher. Use the on-device ADB option only if you want Homestead to reapply selected debloat changes after reboot.

The three global animation keys are window_animation_scale, transition_animation_scale, and animator_duration_scale. Record each with settings get global KEY, then use settings put global KEY 0.5 to shorten transitions. Restore exact original values with settings put, or settings delete for missing keys.
