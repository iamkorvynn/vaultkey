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
