# Ticket 35: Android production release configuration hardening

## Production package identity

- Android `applicationId`: `app.subscriptionkiller`
- Android namespace: `app.subscriptionkiller`

## Release signing setup

Provide release signing values through one of these local-only paths:

1. `android/key.properties`
2. Environment variables:
   - `SUB_KILLER_UPLOAD_STORE_FILE`
   - `SUB_KILLER_UPLOAD_STORE_PASSWORD`
   - `SUB_KILLER_UPLOAD_KEY_ALIAS`
   - `SUB_KILLER_UPLOAD_KEY_PASSWORD`

Use `android/key.properties.example` as the local template. The repository ignores `android/key.properties`, `.jks`, and `.keystore` files.

## Release artifact commands

- Debug verification: `flutter build apk --debug`
- Release APK: `flutter build apk --release`
- Release App Bundle: `flutter build appbundle --release`

If release signing values are missing, release builds now fail immediately with a clear Gradle error instead of silently falling back to debug signing.

## Engineer handoff notes

- Debug builds remain available without signing secrets.
- External distribution requires a real keystore plus local signing values.
- No SMS runtime, classifier, resolver, ledger, or persistence behavior changed in this ticket.
