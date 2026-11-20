# VaultKey architecture

## Layers

```
UI (screens + widgets)
  ↓  calls
Services (AuthService, VaultService, VaultRepository, CryptoService,
          PasswordGenerator, LockManager, ClipboardService, SecureStore)
  ↓  persists
SQLite (vaultkey.db, app-private storage) + OS keystore (secure storage)
```

- **UI never touches crypto or SQL directly.** Screens call
  `VaultService` / `VaultRepository` with plain Dart objects.
- **The repository owns encryption.** Callers pass decrypted `VaultEntry`
  objects; only ciphertext reaches SQLite.
- **The key lives in exactly two places:** in memory while unlocked, and
  in the OS-encrypted keystore (for biometric unlock). It is never written
  to SQLite, never logged, never sent anywhere (the app has no network).

## Unlock flow

1. App starts → `_Gate` checks `SecureStore.isSetupDone`.
2. Not set up → `SetupScreen` → `AuthService.setupMasterPassword`:
   fresh salt → derive key → store salt + verifier + keystore key.
3. Set up → `LockScreen` → `verifyMasterPassword` (re-derive + constant
   time compare) or `unlockWithBiometrics` (OS prompt → keystore key).
4. On success → `VaultService.bindRepository()` → `VaultScreen`.

## Lock flow

- `LockManager` countdown (default 2 min, configurable 1/2/5/15).
- App backgrounded (`AppLifecycleState.paused`) → immediate lock.
- Manual lock from the app bar / drawer.
- Locking drops the in-memory key and closes the repository handle.

## Data model

### SQLite — `entries` table

| Column | Content |
| --- | --- |
| `id` | TEXT PK, microsecond timestamp at creation |
| `title` | TEXT, plaintext (searchable) |
| `username_enc` | TEXT, AES ciphertext |
| `password_enc` | TEXT, AES ciphertext |
| `url` | TEXT, plaintext (searchable) |
| `notes_enc` | TEXT, AES ciphertext |
| `category` | TEXT, one of the 8 built-in categories |
| `favorite` | INTEGER 0/1 |
| `created_at` / `updated_at` | INTEGER, epoch millis |

Indexes on `title` and `category`.

### Secure storage (`vk_*` keys)

| Key | Content |
| --- | --- |
| `vk_salt` | Per-device random salt (base64) |
| `vk_master_verifier` | SHA-256 of the derived key (hex) |
| `vk_vault_key` | Derived key (base64), for biometric unlock |
| `vk_setup_done` | `"true"` after first setup |
| `vk_biometric_enabled` | `"true"` when biometric unlock is on |
| `vk_autolock_minutes` | Auto-lock delay (default 2) |
| `vk_failed_attempts` / `vk_lockout_until` | Brute-force protection state |

## Changing the master password

`AuthService.changeMasterPassword` verifies the current password, derives
a new key + salt, then calls `VaultService.reencryptAll`, which reads every
entry under the old key and rewrites it under the new key. Only after all
rows are rewritten are the salt / verifier / keystore key replaced. If the
re-encryption throws, the old credentials stay in place.

## Testing strategy

- **Unit:** crypto round-trips + wrong-key failure, generator rules,
  strength ladder, lock state machine, clipboard auto-clear.
- **Repository:** real SQLite via `sqflite_common_ffi` on an in-memory DB,
  including a check that secrets are ciphertext on disk.
- **Widget:** first-run setup gate (mocked secure-storage channel),
  mismatch error, generator screen rendering.
- Platform plugins (`flutter_secure_storage`, `local_auth`, `sqflite`)
  are exercised through fakes/mocks in tests; on-device behavior is
  verified by the release build + manual smoke test.
