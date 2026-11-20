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
