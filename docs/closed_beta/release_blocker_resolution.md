# SubWatch Release Blocker Resolution

## Current status

- Signing: resolved locally
- Signed release AAB: generated
- Signed release APK: generated
- Release install sanity: completed on Android device `ZA222KQKY5`
- Privacy policy content: ready locally
- Privacy policy live URL: still missing

## Local signing path

- Ignored keystore: `android/subwatch-upload-keystore.jks`
- Ignored secrets file: `android/key.properties`
- Gradle wiring: `android/app/build.gradle.kts`
- Alternate supported path: `SUB_KILLER_UPLOAD_*` environment variables

## Release artifact commands

- Signed AAB:
  - `flutter build appbundle --release`
- Signed APK:
  - `android\\gradlew.bat app:assembleRelease --no-daemon`

## Release artifacts produced

- `build/app/outputs/bundle/release/app-release.aab`
- `build/app/outputs/apk/release/app-release.apk`

## Release identity confirmed

- `applicationId`: `app.subscriptionkiller`
- `versionName`: `0.1.0`
- `versionCode`: `1`
- `minSdk`: `24`
- `targetSdk`: `36`

## Release verification completed

- Verified the AAB is signed by:
  - `CN=SubWatch Upload, OU=Release, O=SubWatch, L=Bengaluru, ST=Karnataka, C=IN`
- Installed the signed release APK on device `ZA222KQKY5`
- Verified installed package identity:
  - `app.subscriptionkiller`
  - `versionName=0.1.0`
  - `versionCode=1`
- Verified release first-run gate appears on fresh install
- Verified `Get started` opens the SMS-permission rationale sheet
- Verified `Browse sample first` reaches Home in the signed release build

## Remaining Play blocker

- A final public privacy policy URL is still required for Play closed testing
- Ready-to-publish content exists locally in `docs/privacy_policy.md`
- Next step: publish that policy to the final public URL and place the live URL into the Play listing metadata
