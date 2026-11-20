# VaultKey — Offline Password Manager

**VaultKey** is a fully offline password manager for Android, built with
Flutter. Everything stays on your device: no account, no cloud, no network
calls, no tracking.

- **Master password lock** — one strong password encrypts the whole vault.
- **AES-256 encryption** — usernames, passwords and notes are encrypted
  before they touch the database.
- **Biometric unlock** — fingerprint / face unlock via the OS prompt.
- **Password generator** — secure random passwords with strength meter.
- **Search, categories & favorites** — find any login in seconds.
- **Copy with auto-clear** — clipboard wipes itself 30 seconds after copying
  a secret.
- **Auto-lock** — vault locks after inactivity and when the app backgrounds.

## Status

- Version: **1.0.0** (versionCode 1)
- Package: `dev.numaan.vaultkey`
- Flutter 3.50.0 · Dart 3.14 · minSdk 21
- Tests: `flutter test` — 54 tests, all passing
- Lint: `flutter analyze` — no issues

## Security design

| Layer | How it works |
| --- | --- |
| Master password | Minimum 8 characters; stretched with 10,000 rounds of iterated SHA-256 over password + per-device random salt. |
| Vault key | 256-bit AES key derived from the master password. Held only in memory while unlocked; also kept in the OS-encrypted keystore (Android Keystore / iOS Keychain) so biometric unlock works across restarts. |
| Entry encryption | AES-256-CBC with a fresh random 16-byte IV per value. Ciphertext stored as `base64(iv):base64(data)`. |
| What is encrypted | Username, password, notes. Title, URL and category stay plaintext so search/filter works without decrypting every row. |
| Brute-force protection | 5 wrong master-password attempts → 1-minute lockout. |
| Clipboard | Copied secrets auto-clear after 30 seconds. |
| Auto-lock | Configurable 1 / 2 / 5 / 15 minutes of inactivity, plus lock on app background. |
| Network | None. The app makes zero network calls. INTERNET permission is declared only for the platform permission check. |

**No recovery:** if you forget the master password, the vault cannot be
opened — by design. There is no backdoor, no reset link, no cloud copy.

## Screens

- **Setup** — first-run master password creation with live strength meter.
- **Lock** — master password unlock, biometric button, attempts-left counter.
- **Vault** — entry list with search, category chips, favorites filter,
  per-entry copy + favorite, add button.
- **Entry detail** — reveal/hide password, copy username/password/URL/notes,
  edit, delete.
- **Entry editor** — title, username, password (with one-tap generator and
  strength meter), URL, category, notes.
- **Generator** — length slider (8–64), uppercase / lowercase / digits /
  symbols toggles, exclude-ambiguous option, regenerate + copy.
- **Settings** — auto-lock timeout, biometric toggle, change master password
  (re-encrypts the whole vault), vault stats, erase vault.

## Build

```bash
# Toolchain
export PATH=~/workspace/flutter-sdk/flutter/bin:$PATH
export ANDROID_HOME=~/workspace/android-sdk
export JAVA_HOME=~/workspace/android-sdk/jdk17
export JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true"
export GRADLE_OPTS="-Djava.net.preferIPv4Stack=true"
export CI=true

flutter pub get
flutter analyze   # expect: No issues found!
flutter test      # expect: All tests passed!

# Release APK (parent builds this sequentially; VM RAM constraint)
# flutter build apk --release
```

Gradle is tuned for a low-RAM VM: 1.5 GB heap, daemon off, 2 workers
(`android/gradle.properties`). Release lint is disabled in
`android/app/build.gradle.kts` (AGP lint crashes on this toolchain).

## Project structure

```
lib/
  main.dart                  App entry + setup/lock/vault gate
  models/
    vault_entry.dart         Entry model + SQLite mapping
    category.dart            Built-in categories
  services/
    crypto_service.dart      AES-256-CBC + key derivation (10k SHA-256 rounds)
    secure_store.dart        OS keystore wrapper (flutter_secure_storage)
    auth_service.dart        Master password, lockout, biometric unlock
    vault_repository.dart    SQLite CRUD, encrypt-on-write
    vault_service.dart       Orchestrates auth + repository + re-encryption
    password_generator.dart  Secure generator + entropy strength estimator
    lock_manager.dart        Pure-Dart lock state machine + auto-lock timer
    clipboard_service.dart   Copy secrets with 30s auto-clear
  screens/
    setup_screen.dart        First-run master password creation
    lock_screen.dart         Unlock + biometric
    vault_screen.dart        List, search, filters, auto-lock
    entry_detail_screen.dart View / reveal / copy / delete
    entry_edit_screen.dart   Add / edit form + inline generator
    generator_screen.dart    Standalone generator
    settings_screen.dart     Auto-lock, biometric, change password, erase
  widgets/
    entry_tile.dart          Vault list row
    password_strength_meter.dart  4-segment strength bar

test/
  crypto_service_test.dart   Key derivation + AES round-trip
  password_generator_test.dart  Generation rules + strength
  vault_repository_test.dart    CRUD + encryption-at-rest (sqflite ffi)
  lock_manager_test.dart     Lock states + auto-lock timer
  vault_entry_test.dart      Model mapping + categories
  widget_test.dart           Setup gate + generator screen
```

## Privacy

VaultKey collects nothing. There is no analytics, no crash reporting, no
account, no server. The only data on the device is your encrypted vault
(`vaultkey.db` in the app's private storage) and a handful of keys in the
OS keystore. Uninstalling the app deletes everything.
