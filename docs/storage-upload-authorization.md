# Storage upload authorization (RC Sprint 3.3)

## Why text works but media fails

Text uses **Firestore** rules only. Image / voice / video / file use **Cloud Storage**
rules that also call `firestore.get` / `firestore.exists` on
`conversations/{conversationId}` and require a valid **App Check** token when
Storage enforcement is enabled.

## Required Console checks (not bypasses)

1. **App Check → Android app `app.velix.messenger`**
   - Debug: register the debug token printed in logcat (`[VelixAppCheck]`).
   - Release: Play Integrity enabled; release SHA-1/256 registered.
   - Tokens registered only for the old `com.example.velix_messenger` app do **not** apply.
2. **Storage Rules cross-service access**
   - First time rules use `firestore.get`/`exists`, Firebase must grant Storage
     permission to read Firestore. If uploads still 403 after a clean rebuild,
     open Firebase Console → Storage → Rules → Publish once and accept the
     permission prompt (or re-run `firebase deploy --only storage`).
3. Do **not** turn App Check off and do **not** open Storage rules publicly.

## Client invariants (code)

- Paths: `chat_media/{conversationId}/images|videos|video_thumbnails|files/...`
- Metadata: `uploaderId` == signed-in uid
- `contentType` set explicitly for chat media
- App Check activated + token warmed before UI traffic
