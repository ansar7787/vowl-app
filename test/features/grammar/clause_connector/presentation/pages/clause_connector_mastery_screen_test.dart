import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/clause_connector/presentation/pages/clause_connector_mastery_screen.dart';

void main() {
  group('ClauseConnectorMasteryScreen Type Alias', () {
    test('ClauseConnectorMasteryScreen resolves identically to ClauseConnectorScreen', () {
      expect(ClauseConnectorMasteryScreen, equals(ClauseConnectorScreen));
    });

    test('can instantiate ClauseConnectorMasteryScreen with level and gameType', () {
      const screen = ClauseConnectorMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<ClauseConnectorScreen>());
    });
  });
}
