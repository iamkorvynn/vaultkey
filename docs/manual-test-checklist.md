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
