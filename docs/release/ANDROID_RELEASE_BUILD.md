# Android Release Build (AAB for Google Play)

## Prerequisites

- Flutter 3.41.7 (stable) — same as CI
- JDK 17 (Temurin)
- Android SDK with platform-tools and build-tools
- Upload key configured as in [UPLOAD_KEY_SETUP.md](UPLOAD_KEY_SETUP.md) (`android/key.properties` present)

## 1. Bump the version

Edit `pubspec.yaml`:

```yaml
version: 1.20.1+39   # versionName+versionCode
```

`versionCode` must be **strictly greater** than every code previously uploaded to Play.

## 2. Build

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

If signing is not configured the build stops with
`Release signing is not configured...` — fix `android/key.properties`; do not work around it.

## 3. Verify the signature

```bash
AAB=build/app/outputs/bundle/release/app-release.aab
jarsigner -verify "$AAB"                          # expect: jar verified.
keytool -printcert -jarfile "$AAB" | grep -E "Owner|SHA256:"
```

The SHA-256 must equal the upload certificate fingerprint:

```
F8:20:11:52:8D:5A:D7:62:36:AA:A1:F3:99:3B:95:68:FB:85:AD:EB:05:5D:FB:58:E4:2B:17:34:2D:8C:83:2F
```

Also confirm package and version:

```bash
unzip -p "$AAB" base/manifest/AndroidManifest.xml | strings | grep -E "btk_field_app"
```

## 4. Check debug builds still work

```bash
flutter build apk --debug
```

Debug builds use the standard Android debug key and never read `key.properties`.

## 5. Upload

Upload manually in Play Console (Internal testing track first). Nothing in this repository
uploads to Google Play automatically.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `Release signing is not configured` | `android/key.properties` missing and no `BTC_UPLOAD_*` env vars |
| `Keystore was tampered with, or password was incorrect` | Wrong password in `key.properties` |
| Play: "uploaded with the wrong key" | AAB signed with a key other than the registered upload key (e.g. the CI sideload key) |
| Play: "Version code already used" | Bump the `+N` part of `version:` in `pubspec.yaml` |
