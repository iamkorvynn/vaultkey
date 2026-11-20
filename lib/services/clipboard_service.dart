import 'dart:async';

import 'package:flutter/services.dart';

/// Copies secrets to the clipboard and clears them after a delay, so a
/// password does not sit in the clipboard indefinitely.
///
/// The platform clipboard is written through [Clipboard.setData]; the
/// clear step writes an empty plain-text payload after [clearAfter].
/// Injectable [clipboard] and [timerFactory] keep this unit-testable.
class ClipboardService {
  ClipboardService({
    Future<void> Function(ClipboardData data)? setData,
    Timer Function(Duration duration, void Function() callback)? timerFactory,
    this.clearAfter = const Duration(seconds: 30),
  })  : _setData = setData ?? Clipboard.setData,
        _timerFactory =
            timerFactory ?? ((d, cb) => Timer(d, cb));

  final Future<void> Function(ClipboardData data) _setData;
  final Timer Function(Duration duration, void Function() callback)
      _timerFactory;

  /// How long a copied secret stays on the clipboard before auto-clear.
  final Duration clearAfter;

  Timer? _clearTimer;

  /// Copies [text] to the clipboard and schedules an auto-clear.
  Future<void> copySecret(String text) async {
    _clearTimer?.cancel();
    await _setData(ClipboardData(text: text));
    _clearTimer = _timerFactory(clearAfter, () {
      _setData(const ClipboardData(text: ''));
    });
  }

  /// Copies [text] without scheduling an auto-clear (for non-secrets).
  Future<void> copy(String text) async {
    await _setData(ClipboardData(text: text));
  }

  /// Clears the clipboard immediately.
  Future<void> clearNow() async {
    _clearTimer?.cancel();
    await _setData(const ClipboardData(text: ''));
  }

  void dispose() {
    _clearTimer?.cancel();
  }
}
