import 'dart:async';

/// Pure-Dart lock state machine, kept free of Flutter so it can be unit
/// tested without a widget binding.
///
/// States: locked -> unlocked (starts the auto-lock countdown) -> locked
/// again when the countdown fires, when [lock] is called, or when the app
/// is backgrounded (the UI calls [lock] on AppLifecycleState.paused).
class LockManager {
  LockManager({this.onLock});

  /// Called exactly when the vault transitions to locked.
  final void Function()? onLock;

  bool _unlocked = false;
  Timer? _timer;

  bool get isUnlocked => _unlocked;

  bool get isLocked => !_unlocked;

  /// Unlocks the vault and (re)starts the auto-lock countdown of
  /// [autoLock] duration. A null [autoLock] means "lock only manually".
  void unlock({Duration? autoLock}) {
    _unlocked = true;
    _timer?.cancel();
    if (autoLock != null) {
      _timer = Timer(autoLock, lock);
    }
  }

  /// Locks the vault immediately and cancels any pending auto-lock timer.
  void lock() {
    if (!_unlocked) return;
    _unlocked = false;
    _timer?.cancel();
    _timer = null;
    onLock?.call();
  }

  /// Restarts the auto-lock countdown (call on user activity).
  void poke({Duration? autoLock}) {
    if (!_unlocked) return;
    _timer?.cancel();
    if (autoLock != null) {
      _timer = Timer(autoLock, lock);
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
