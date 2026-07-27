# Exact Storage 403 diagnosis (device logcat evidence)

Captured from connected device `V2205` running `app.velix.messenger` on 26 Jul 2026.

## Failed authorization check

**App Check token validation** — not Storage Rules clauses.

## Evidence (logcat)

```
W StorageUtil: Error getting App Check token; using placeholder token instead. Error:
com.google.firebase.FirebaseException: Error returned from API. code: 403 body:
Firebase App Check API has not been used in project 720571740911 before or it is disabled.
Enable it by visiting
https://console.developers.google.com/apis/api/firebaseappcheck.googleapis.com/overview?project=720571740911
then retry.

E StorageException: User does not have permission to access this object.
E StorageException:  Code: -13021 HttpResult: 403
Caused by: { "error": { "code": 403, "message": "Permission denied." } }

D DebugAppCheckProvider: Enter this debug secret into the allow list in the Firebase Console
for your project: ce19974f-eac0-4e05-887f-4222adb23756
```

## Checks ruled out by this evidence

| Check | Result | Why |
|-------|--------|-----|
| App Check token validation | **FAIL (proven)** | API disabled → placeholder token → Storage 403 |
| request.auth == null | Not implicated | Auth/Firestore text works; error is App Check API 403 first |
| uploaderId metadata missing | Not proven | Failure occurs after placeholder App Check token |
| conversation missing | Not proven | Same |
| participants mismatch | Not proven | Same |
| upload path mismatch | Not proven | Same |
| contentType mismatch | Not proven | Same |
| Storage bucket mismatch | Not proven | Same |

Storage Security Rules are **not** the first failing gate here. The client never obtained a real App Check token.

## Minimal fix (no rule weakening)

1. Enable API: `firebaseappcheck.googleapis.com` for project `velix-messenger-90f85`
   - Console: https://console.developers.google.com/apis/api/firebaseappcheck.googleapis.com/overview?project=720571740911
2. Firebase Console → App Check → Android app `app.velix.messenger` → Manage debug tokens → add:
   `ce19974f-eac0-4e05-887f-4222adb23756`
3. Force-stop the app (clears “Too many attempts” backoff) and retry upload.
4. Do **not** change Storage Rules for this failure.
