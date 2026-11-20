# VaultKey threat model

## What VaultKey protects against

- **Stolen unlocked phone, briefly unattended** — auto-lock + lock on
  background limit the window to minutes.
- **Shoulder surfing / screenshots of the vault list** — passwords are
  masked by default; reveal is per-field and manual.
- **Clipboard snooping** — copied secrets auto-clear after 30 seconds.
- **Someone guessing the master password** — 5 attempts, then a 1-minute
  lockout; the key is stretched with 10,000 SHA-256 rounds.
- **Database file theft (rooted device / backup extraction)** — usernames,
  passwords and notes are AES-256 ciphertext; without the master password
  (or the keystore key) the rows are useless.
- **Accidental exposure via search** — titles/URLs stay plaintext by design
  so search works; they reveal *which* accounts you have, not the secrets.

## What VaultKey does NOT protect against

- **A forgotten master password** — there is no recovery, by design.
- **A compromised device with a keylogger / screen recorder** — no app can
  defend against that; the master password is typed on the device keyboard.
- **Physical extraction of the OS keystore** — biometric unlock stores the
  derived key in the platform keystore; on a fully compromised device that
  key could be extracted. If that worries you, keep biometrics off and use
  the master password only.
- **Weak master passwords** — the strength meter warns, but a short or
  guessable master password undermines everything. Minimum 8 characters
  is enforced; longer is strongly recommended.
