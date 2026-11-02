# iOS Sideload Build (unsigned IPA)

For testing on your own iPhone or iPad. This build does not go through the App Store or TestFlight.

**Status:** the workflow has not been run yet, and the app has not been run on an iOS device. The first `v*` tag will show whether the build succeeds.

## How the file is built

Pushing a `v*` tag runs the `build-ios` job in `.github/workflows/release.yml`. It attaches `btk-ios-unsigned.ipa` to the GitHub release.

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
| Account, Cloud and Expedition modes | **Not available** | `lib/firebase_options.dart` has no iOS configuration, so the app starts in local mode only |
| Analytics | Off | Same reason |
| GPS track recording with the screen off | **Not available** | The app has no iOS background location mode, so iOS can suspend recording |
| Update notice | On | The Android-only block doesn't apply, so the app checks GitHub releases |

To enable accounts and sync, add an iOS app in the Firebase console, then run `flutterfire configure --project=gca-btk-field-app`.

## Keep your data

Records stay on the device, and there is no cloud copy on iOS.

- Deleting the app deletes its records and photos.
- Sign again with the same Apple ID and the same bundle ID. A tool that changes the bundle ID installs a separate app with no records.
- Before reinstalling, export a `.btkz` backup from the Records screen.

## Permissions

`ios/Runner/Info.plist` explains each permission to the user. iOS closes an app that asks for one of these without an explanation.

| Key | Used for |
|---|---|
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
| Sign-in doesn't work | Expected. See "What works on iOS" |
