# Android release signing (Velix Messenger)

## What lives on disk (local only)

| Path | Purpose | Git |
|------|---------|-----|
| `android/app/upload-keystore.jks` | Production upload/release keystore | Ignored |
| `android/key.properties` | Keystore passwords + alias paths | Ignored |

Do **not** commit either file. Do **not** paste passwords into chat, tickets, or docs.

## Build

Release builds read `android/key.properties` and sign with the `upload` alias.
If `key.properties` is missing, the release Gradle configuration fails (no debug fallback).

```bash
flutter build appbundle --release
# or
flutter build apk --release
```

## Fingerprints (release keystore, alias `upload`)

| Algorithm | Value |
|-----------|-------|
| SHA-1 | `23:02:AD:86:7C:9C:54:4E:AC:46:7A:2E:D6:47:FD:EB:22:55:EA:90` |
| SHA-256 | `6F:92:03:2B:3B:2F:13:9D:47:80:A2:99:B6:37:69:D8:0E:DE:D8:01:B9:41:D9:FD:88:7B:09:57:69:9B:13:DE` |

Re-verify anytime (requires your local store password):

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

### Manual registration (required)

1. Firebase Console → Project settings → Your apps → Android app `app.velix.messenger` → **Add fingerprint** → paste SHA-1 and SHA-256.  
2. Google Play Console → App integrity / Play Integrity API → ensure the same upload key is registered when the app is enrolled.  
3. After adding fingerprints, download a fresh `google-services.json` if Firebase adds an Android OAuth client (optional until Google Sign-In is used).

## Backup

Back up `upload-keystore.jks` and the passwords offline. Losing them permanently blocks Play Store updates for this signing key.
