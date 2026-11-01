# Upload Key Backup and Recovery

The owner is responsible for keeping secure **offline** backups of the upload key and its credentials.

## What to back up

All files live in `~/.android-keys/btc-field-app/`:

| File | Secret? | Purpose |
|---|---|---|
| `upload-keystore.jks` | **Yes** | The private upload key |
| `credentials.properties` | **Yes** | Keystore password, key password, alias |
| `upload_certificate.pem` | No | Public certificate (needed for an upload-key reset) |

## How to back up

1. Make **at least two** offline copies, stored in different physical places
   (e.g. two encrypted USB drives: one at the office, one at home / in a safe).
2. Store the keystore and the password **separately** if possible — e.g. keystore on the encrypted
   drive, password in an offline password manager vault or sealed printed copy.
3. Encrypt the drive (LUKS, VeraCrypt, or BitLocker). Example with an encrypted archive:

   ```bash
   cd ~/.android-keys
   tar -czf - btc-field-app | gpg --symmetric --cipher-algo AES256 -o btc-field-app-upload-key.tar.gz.gpg
   ```

   Copy the `.gpg` file to the offline media. Use a different passphrase from the keystore password
   and record it with the password backup.
4. Verify each backup restores and opens:

   ```bash
   keytool -list -keystore upload-keystore.jks -alias upload
   ```

   (enter the password when prompted; check the SHA-256 fingerprint matches.)
5. Re-check backups once a year.

**Do not** back up to GitHub, public/shared cloud folders, email, chat, or AI tools.

## Restoring on a new machine

```bash
install -d -m 700 ~/.android-keys/btc-field-app
# copy the three files from the backup into that directory, then:
chmod 600 ~/.android-keys/btc-field-app/*
install -m 600 ~/.android-keys/btc-field-app/credentials.properties android/key.properties
# fix storeFile= in android/key.properties if the home directory path differs
```

Then build and verify as in [ANDROID_RELEASE_BUILD.md](ANDROID_RELEASE_BUILD.md).

## If the upload key is lost or compromised

Because the app uses **Play App Signing**, the app itself is safe — users keep receiving updates.

1. Generate a new upload key (same procedure as [UPLOAD_KEY_SETUP.md](UPLOAD_KEY_SETUP.md), new file names).
2. Export its certificate:

   ```bash
   keytool -export -rfc -keystore new-upload-keystore.jks -alias upload -file new_upload_certificate.pem
   ```

3. Play Console → Release → Setup → **App integrity** → **Request upload key reset**,
   choose the reason, and attach `new_upload_certificate.pem`.
4. Wait for Google's confirmation (typically a few days) before uploading with the new key.
5. If compromised: also rotate any copies, revoke access for anyone who had it, and record the incident.

## If the Play Console account is lost

The upload key alone cannot publish anything. Recover the Google account first (Play Console
access, 2-step verification backup codes). Keep the account owner email and recovery codes with
the key backup documentation.
