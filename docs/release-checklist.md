# Release checklist

## Before building
- [ ] `flutter analyze` — no issues.
- [ ] `flutter test` — all tests pass.
- [ ] Version bumped in `pubspec.yaml` (`version: X.Y.Z+N`).
- [ ] `CHANGELOG.md` updated with the new version.
- [ ] No demo/sample entries anywhere in code or tests (tests use
      clearly fake data only).

## Build
- [ ] Toolchain env set (Flutter 3.50.0, JDK 17, proxy flags).
- [ ] `flutter build apk --release` (release APK only; do not commit it).
- [ ] `aapt2 dump badging` on the APK — confirm INTERNET permission
      is declared (`uses-permission: name='android.permission.INTERNET'`).
- [ ] Install on a real device and run `docs/manual-test-checklist.md`.

## Publish
- [ ] Tag the release: `git tag vX.Y.Z && git push origin vX.Y.Z`.
- [ ] Attach the APK to the GitHub release.
- [ ] Update `store-listing.md` "What's new" for the Play Store.
