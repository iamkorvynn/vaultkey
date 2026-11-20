# Manual test checklist (on-device smoke test)

Run through this on a real phone after installing the release APK.

## First run
- [ ] App opens to "Create your master password".
- [ ] Password shorter than 8 chars is rejected with a clear error.
- [ ] Mismatched confirmation shows "Passwords do not match."
- [ ] Strength meter moves from Weak to Strong as the password improves.
- [ ] Creating the vault lands on an empty vault list ("Your vault is empty").

## Lock / unlock
- [ ] Locking (app-bar lock icon) returns to the lock screen.
- [ ] Wrong password shows attempts-left and counts down.
- [ ] 5 wrong attempts trigger the 1-minute lockout message.
- [ ] Correct password unlocks to the vault list.
- [ ] Backgrounding the app (home button) locks the vault on return.
- [ ] Auto-lock fires after the configured timeout.

## Vault entries
- [ ] Add an entry: title, username, password, URL, category, notes.
- [ ] Generator button in the editor fills a strong password.
- [ ] Entry appears in the list with the right title/username.
- [ ] Search finds it by title, username and URL; gibberish finds nothing.
- [ ] Category chip filters the list; Favorites filter shows starred only.
- [ ] Star toggle works from list and detail screens.
- [ ] Detail screen masks the password; eye icon reveals it.
- [ ] Copy password shows the 30-second auto-clear snackbar.
- [ ] Edit changes persist; delete removes the entry after confirmation.

## Generator
- [ ] Length slider changes the password length.
- [ ] Turning off all character sets shows an error, doesn't crash.
- [ ] Exclude-ambiguous produces no 0/O/1/l/I characters.
- [ ] Regenerate produces a different password.

## Settings
- [ ] Auto-lock dropdown changes the timeout (verify it fires).
- [ ] Biometric toggle prompts for a biometric, then unlocks with it.
- [ ] Change master password works; old password stops working; all
      entries still decrypt with the new password.
- [ ] Erase vault deletes everything and returns to first-run setup.
- [ ] Kill and relaunch the app: vault still unlocks with the same
      master password (persistence check).
