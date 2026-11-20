import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vaultkey/main.dart';
import 'package:vaultkey/screens/generator_screen.dart';

/// Mocks the flutter_secure_storage method channel so the app gate can
/// run in tests. Returning null for reads means "setup not done".
void mockSecureStorage() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (MethodCall call) async => null,
  );
}

void main() {
  setUp(mockSecureStorage);

  testWidgets('first run shows the master-password setup screen',
      (tester) async {
    await tester.pumpWidget(const VaultKeyApp());
    await tester.pumpAndSettle();
    expect(find.text('Create your master password'), findsOneWidget);
    expect(find.text('Create vault'), findsOneWidget);
    expect(find.text('Minimum 8 characters.'), findsNothing);
  });

  testWidgets('setup screen warns the vault starts empty', (tester) async {
    await tester.pumpWidget(const VaultKeyApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Your vault starts empty.'), findsOneWidget);
  });

  testWidgets('setup screen shows mismatch error', (tester) async {
    await tester.pumpWidget(const VaultKeyApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Master password'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm master password'),
      'different456',
    );
    await tester.tap(find.text('Create vault'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('generator screen renders with options', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GeneratorScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Password generator'), findsOneWidget);
    expect(find.text('Uppercase letters (A-Z)'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Regenerate'), findsOneWidget);
  });
}
