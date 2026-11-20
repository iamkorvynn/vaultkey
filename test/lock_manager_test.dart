import 'package:flutter_test/flutter_test.dart';
import 'package:vaultkey/services/lock_manager.dart';

void main() {
  group('LockManager', () {
    test('starts locked', () {
      final manager = LockManager();
      expect(manager.isLocked, isTrue);
      expect(manager.isUnlocked, isFalse);
      manager.dispose();
    });

    test('unlock makes it unlocked; lock makes it locked again', () {
      var lockCalls = 0;
      final manager = LockManager(onLock: () => lockCalls++);
      manager.unlock();
      expect(manager.isUnlocked, isTrue);
      manager.lock();
      expect(manager.isLocked, isTrue);
      expect(lockCalls, 1);
      manager.dispose();
    });

    test('lock when already locked does not call onLock again', () {
      var lockCalls = 0;
      final manager = LockManager(onLock: () => lockCalls++);
      manager.lock();
      expect(lockCalls, 0);
      manager.dispose();
    });

    test('auto-lock fires after the given duration', () async {
      final manager = LockManager();
      manager.unlock(autoLock: const Duration(milliseconds: 50));
      expect(manager.isUnlocked, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(manager.isLocked, isTrue);
      manager.dispose();
    });

    test('poke restarts the auto-lock countdown', () async {
      final manager = LockManager();
      manager.unlock(autoLock: const Duration(milliseconds: 80));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      manager.poke(autoLock: const Duration(milliseconds: 80));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(manager.isUnlocked, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(manager.isLocked, isTrue);
      manager.dispose();
    });

    test('unlock without autoLock stays unlocked until manual lock', () async {
      final manager = LockManager();
      manager.unlock();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(manager.isUnlocked, isTrue);
      manager.lock();
      expect(manager.isLocked, isTrue);
      manager.dispose();
    });
  });
}
