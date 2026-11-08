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
