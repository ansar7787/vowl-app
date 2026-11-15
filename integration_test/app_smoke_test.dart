import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vowl/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Vowl End-to-End Smoke Test Suite', () {
    testWidgets('App boots, initializes dependencies, and renders initial frame without crashing',
        (WidgetTester tester) async {
      // Launch application entry point
      app.main();
      await tester.pumpAndSettle();

      // Verify the application initialized successfully and mounted root
      expect(find.byType(app.MyApp), findsOneWidget);
    });
  });
}
