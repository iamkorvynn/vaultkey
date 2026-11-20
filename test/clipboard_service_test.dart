import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vaultkey/services/clipboard_service.dart';

void main() {
  group('ClipboardService', () {
    test('copySecret writes the secret to the clipboard', () async {
      final written = <String?>[];
      final service = ClipboardService(
        setData: (data) async {
          written.add(data.text);
        },
        timerFactory: (_, _) => Timer(const Duration(days: 1), () {}),
      );
      await service.copySecret('hunter2');
      expect(written, ['hunter2']);
      service.dispose();
    });

    test('copySecret schedules an auto-clear that wipes the clipboard',
        () async {
      final written = <String?>[];
      void Function()? capturedCallback;
      final service = ClipboardService(
        setData: (data) async {
          written.add(data.text);
        },
        timerFactory: (_, callback) {
          capturedCallback = callback;
          return Timer(const Duration(days: 1), () {});
        },
      );
      await service.copySecret('hunter2');
      expect(capturedCallback, isNotNull);
      capturedCallback!();
      // Give the async clear a chance to run.
      await Future<void>.delayed(Duration.zero);
      expect(written, ['hunter2', '']);
      service.dispose();
    });

    test('copy (non-secret) writes without scheduling a clear', () async {
      final written = <String?>[];
      var timerCalls = 0;
      final service = ClipboardService(
        setData: (data) async {
          written.add(data.text);
        },
        timerFactory: (_, __) {
          timerCalls++;
          return Timer(const Duration(days: 1), () {});
        },
      );
      await service.copy('plain note');
      expect(written, ['plain note']);
      expect(timerCalls, 0);
      service.dispose();
    });

    test('clearNow wipes the clipboard immediately', () async {
      final written = <String?>[];
      final service = ClipboardService(
        setData: (data) async {
          written.add(data.text);
        },
        timerFactory: (_, _) => Timer(const Duration(days: 1), () {}),
      );
      await service.copySecret('hunter2');
      await service.clearNow();
      expect(written.last, '');
      service.dispose();
    });

    test('second copySecret cancels the first auto-clear timer', () async {
      var timersCreated = 0;
      final timers = <Timer>[];
      final service = ClipboardService(
        setData: (_) async {},
        timerFactory: (_, callback) {
          timersCreated++;
          final timer = Timer(const Duration(days: 1), callback);
          timers.add(timer);
          return timer;
        },
      );
      await service.copySecret('first');
      await service.copySecret('second');
      expect(timersCreated, 2);
      expect(timers.first.isActive, isFalse);
      expect(timers.last.isActive, isTrue);
      service.dispose();
    });
  });
}
