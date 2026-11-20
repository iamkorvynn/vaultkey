# Changelog

## 1.0.0 — 2026-11-20

First public release.

### Added
- Offline encrypted vault (SQLite + AES-256-CBC, fresh IV per value)
- Master password setup and unlock, with 5-attempt lockout
- Biometric unlock (fingerprint / face) via OS prompt
- Vault entries: site/app, username, password, URL, notes, category
- Password generator (length 8–64, charset toggles, exclude ambiguous)
- Entropy-based password strength meter (0–4)
- Search across title / username / URL
- Category filter (8 built-in categories) and favorites
- Copy to clipboard with 30-second auto-clear
- Auto-lock timer (1 / 2 / 5 / 15 min) + lock on app background
- Change master password with full vault re-encryption
- Erase vault (deletes entries + secure-storage keys)
- Dark theme (Material 3, follows system)
- 54 unit + widget tests; `flutter analyze` clean
