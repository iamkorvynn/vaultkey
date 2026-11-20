import 'dart:async';

import 'package:flutter/services.dart';
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
        timerFactory: (_, __) => Timer(const Duration(days: 1), () {}),
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
