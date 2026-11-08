# Verified package record

These are observations from one TV. Check live state and review rollback before changing any package.

## Optional apps

- com.amazon.bueller.music
- com.amazon.bueller.photos
- com.amazon.shoptv.client
- com.amazon.gamehub

## Telemetry and logging

- com.amazon.wirelessmetrics.service
- com.amazon.perfc
- com.amazon.perfcollection
- com.amazon.dp.logger
- com.amazon.logan
- com.amazon.neo.minerva.logcat
- com.amazon.ceviche
- com.amazon.tv.developer.dataservice

Minerva logcat still had a running process after reboot. A disabled package state alone does not establish that a persistent process stopped.

## Demos and tutorials

- com.amazon.tv.democontent.provider
- com.amazon.tmm.tutorial
- com.amazon.tv.releasenotes

## Alexa support

- com.amazon.alexadirectivebrokerservice
- amazon.speech.davs.davcservice
- com.amazon.alexamediaplayer.runtime.ftv
- com.amazon.alexa.externalmediaplayer.fireos
- com.amazon.alexa.datastore.app
- com.amazon.tv.alexaalerts
- com.amazon.tv.alexanotifications
- com.amazon.aca
- com.amazon.firetv.androidskillconnectioncapability

## Failed or transient changes

- com.amazon.vizzini: package disable reverted at boot. User-0 uninstall with -k failed with DELETE_FAILED_INTERNAL_ERROR. Component disable of VoiceAssistantActivity was denied. RECORD_AUDIO ignore reverted to allow after reboot.
- com.amazon.device.telemetry.emitter: disabled before reboot and returned to its original state afterward.
- com.amazon.ftvads.deeplinking: Fire OS rejected the disable as a protected package.
- Homestead accessibility alone did not redirect Home from Netflix. The subsequent test with READ_LOGS passed before and after reboot.

Preserve the Amazon launcher, Prime Video (com.amazon.firebat), Netflix, account and DRM services, input and HDMI services, Settings, networking, remote and audio services, and updates.
