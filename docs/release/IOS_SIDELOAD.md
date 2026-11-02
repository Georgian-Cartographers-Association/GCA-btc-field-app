# iOS Sideload Build (unsigned IPA)

For testing on your own iPhone or iPad. This build does not go through the App Store or TestFlight.

**Status:** the app has not been run on an iOS device, so everything below about how it behaves comes from the code.

## How the file is built

- Pushing a `v*` tag runs the `build-ios` job in `.github/workflows/release.yml`, which attaches `btk-ios-unsigned.ipa` to the GitHub release.
- A pull request that touches iOS runs `.github/workflows/ios.yml`, which keeps the IPA for 14 days as a workflow artifact. Use this to test without making a release.

The file has no signature, so iOS will not install it until a sideloading tool signs it with your Apple ID.

## Install

1. Download `btk-ios-unsigned.ipa` from the [latest release](https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app/releases/latest).
2. Open it in [Sideloadly](https://sideloadly.io) or [AltStore](https://altstore.io) on your computer, and sign in with an Apple ID. These are third-party tools, so a separate Apple ID is the safer choice.
3. On iOS 16 or later, turn on Developer Mode: Settings > Privacy & Security > Developer Mode.
4. Trust your Apple ID: Settings > General > VPN & Device Management.

## Limits of a free Apple ID

- The signature lasts 7 days. After that the app won't open until it is signed again.
- Only a few sideloaded apps can be active at once.

## What works on iOS

| Feature | iOS build | Why |
|---|---|---|
| Local records, map, export | Should work | Not yet tested on a device |
| Account, Cloud and Expedition modes | **Not available** | `lib/firebase_options.dart` has no iOS configuration. Settings turns these modes off and says why |
| Analytics | Off | Same reason |
| GPS track recording with the screen off | Should work | Uses the iOS background location mode, and iOS shows a location indicator while recording |
| Sharing on iPad | Should work | The share sheet gets a position to attach to |
| Update notice | On | The Android-only block doesn't apply, so the app checks GitHub releases |

## Turn on accounts and sync

1. Decide the bundle ID first, because Firebase registers the app under it. It is `ge.cartographers.btkFieldApp` today.
2. Add an iOS app with that bundle ID in the Firebase console.
3. Run `flutterfire configure --project=gca-btk-field-app`, or add the new app's values to `lib/firebase_options.dart` by hand.

A sideloading tool that changes the bundle ID can affect this, so test sign-in on a device.

## Keep your data

Records stay on the device, and there is no cloud copy on iOS. The app's folder is visible in the Files app, under On My iPhone.

- Deleting the app deletes its records and photos.
- Sign again with the same Apple ID and the same bundle ID. A tool that changes the bundle ID installs a separate app with no records.
- Before reinstalling, export a `.btkz` backup from the Records screen.

## Permissions

`ios/Runner/Info.plist` explains each permission to the user. iOS closes an app that asks for one of these without an explanation.

| Key | Used for |
|---|---|
| `UIBackgroundModes` (`location`) | Recording a track with the screen off |
| `NSLocationWhenInUseUsageDescription` | Coordinates, tracks and compass |
| `NSCameraUsageDescription` | Taking record photos |
| `NSPhotoLibraryUsageDescription` | Choosing record photos |

Add the matching key when adding a plugin that needs a new permission.

## Troubleshooting

| Symptom | Cause |
|---|---|
| App won't open after a week | The free signature expired. Sign it again |
| "Untrusted Developer" | Trust your Apple ID, step 4 above |
| Records are missing after reinstalling | The app was deleted, or the bundle ID changed |
| Cloud and Expedition are greyed out | Expected. See "What works on iOS" |
| Photos are missing after an update | They should come back: saved paths are moved to the new app folder when read. If not, please report it |
