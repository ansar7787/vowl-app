import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/controllers/topic_vocab_controller.dart';

class MockHapticService extends Mock implements HapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHaptics;
  late List<TopicClusterGroup> testClusters;

  setUp(() {
    mockHaptics = MockHapticService();
    when(() => mockHaptics.selection()).thenAnswer((_) async {});
    when(() => mockHaptics.light()).thenAnswer((_) async {});
    when(() => mockHaptics.heavy()).thenAnswer((_) async {});
    when(() => mockHaptics.warning()).thenAnswer((_) async {});
    when(() => mockHaptics.error()).thenAnswer((_) async {});
    when(() => mockHaptics.success()).thenAnswer((_) async {});

    testClusters = [
      const TopicClusterGroup(
        categoryName: 'Intense Heat',
        emoji: '🔥',
        words: ['Boiling', 'Scorching', 'Steaming'],
      ),
      const TopicClusterGroup(
        categoryName: 'Extreme Cold',
        emoji: '❄️',
        words: ['Freezing', 'Icy', 'Chilly'],
      ),
    ];
  });

  group('TopicVocabController', () {
    test('initializes with all tiles and empty selection', () {
      final controller = TopicVocabController(
        targetClusters: testClusters,
        targetClusterSize: 3,
        initialTiles: [
          'Boiling',
          'Scorching',
          'Steaming',
          'Freezing',
          'Icy',
          'Chilly',
        ],
        hapticService: mockHaptics,
      );

      expect(controller.remainingTiles.length, 6);
      expect(controller.selectedTiles, isEmpty);
      expect(controller.fusedClusters, isEmpty);
      expect(controller.isComplete, isFalse);
      expect(controller.comboMultiplier, 1);
      expect(controller.failedAttempts, 0);
      expect(controller.isOneAway, isFalse);
      expect(controller.remainingClusterCount, 2);
    });

    test('toggles selection and respects targetClusterSize limit', () {
      final controller = TopicVocabController(
        targetClusters: testClusters,
        targetClusterSize: 3,
        initialTiles: [
          'Boiling',
          'Scorching',
          'Steaming',
          'Freezing',
          'Icy',
          'Chilly',
        ],
        hapticService: mockHaptics,
      );

      controller.toggleTile('Boiling');
      expect(controller.selectedTiles.contains('Boiling'), isTrue);

      controller.toggleTile('Scorching');
      expect(controller.selectedTiles.length, 2);

      // Third selection
      controller.toggleTile('Steaming');
      expect(controller.selectedTiles.length, 3);

      // Fourth selection should be blocked
      controller.toggleTile('Freezing');
      expect(controller.selectedTiles.length, 3);
      verify(() => mockHaptics.warning()).called(1);

      // Toggling an already selected tile removes it
      controller.toggleTile('Boiling');
      expect(controller.selectedTiles.length, 2);
      expect(controller.selectedTiles.contains('Boiling'), isFalse);
    });

    test('deselectAll clears all active selections', () {
      final controller = TopicVocabController(
        targetClusters: testClusters,
        targetClusterSize: 3,
        initialTiles: [
          'Boiling',
          'Scorching',
          'Steaming',
          'Freezing',
          'Icy',
          'Chilly',
        ],
        hapticService: mockHaptics,
      );

      controller.toggleTile('Boiling');
      controller.toggleTile('Scorching');
      expect(controller.selectedTiles.length, 2);

      controller.deselectAll();
      expect(controller.selectedTiles, isEmpty);
    });

    test('detects one-away hint when selection has N-1 matching words', () {
      final controller = TopicVocabController(
        targetClusters: testClusters,
        targetClusterSize: 3,
        initialTiles: [
          'Boiling',
          'Scorching',
          'Steaming',
          'Freezing',
          'Icy',
          'Chilly',
        ],
        hapticService: mockHaptics,
      );

      // Select 2 heat words and 1 cold word
      controller.toggleTile('Boiling');
      controller.toggleTile('Scorching');
      controller.toggleTile('Freezing');

      expect(controller.isOneAway, isTrue);
    });

    test(
      'submitFusion successfully fuses matching cluster and increments combo',
      () {
        final controller = TopicVocabController(
          targetClusters: testClusters,
          targetClusterSize: 3,
          initialTiles: [
            'Boiling',
            'Scorching',
            'Steaming',
            'Freezing',
            'Icy',
            'Chilly',
          ],
          hapticService: mockHaptics,
        );

        controller.toggleTile('Boiling');
        controller.toggleTile('Scorching');
        controller.toggleTile('Steaming');

        final fused = controller.submitFusion();
        expect(fused, isNotNull);
        expect(fused!.categoryName, 'Intense Heat');
        expect(controller.fusedClusters.length, 1);
        expect(controller.remainingTiles.length, 3);
        expect(controller.selectedTiles, isEmpty);
        expect(controller.comboMultiplier, 1);
        verify(() => mockHaptics.heavy()).called(1);

        // Fuse second cluster
        controller.toggleTile('Freezing');
        controller.toggleTile('Icy');
        controller.toggleTile('Chilly');
        final secondFused = controller.submitFusion();
        expect(secondFused, isNotNull);
        expect(controller.fusedClusters.length, 2);
        expect(controller.remainingTiles, isEmpty);
        expect(controller.isComplete, isTrue);
        expect(controller.comboMultiplier, 2);
      },
    );

    test(
      'submitFusion fails on mismatched words and increments failedAttempts',
      () {
        final controller = TopicVocabController(
          targetClusters: testClusters,
          targetClusterSize: 3,
          initialTiles: [
            'Boiling',
            'Scorching',
            'Steaming',
            'Freezing',
            'Icy',
            'Chilly',
          ],
          hapticService: mockHaptics,
        );

        controller.toggleTile('Boiling');
        controller.toggleTile('Scorching');
        controller.toggleTile('Freezing');

        final fused = controller.submitFusion();
        expect(fused, isNull);
        expect(controller.failedAttempts, 1);
        expect(controller.comboMultiplier, 1);
        expect(controller.isShaking, isTrue);
        verify(() => mockHaptics.error()).called(1);
      },
    );

    test('autoSolve immediately completes puzzle', () {
      final controller = TopicVocabController(
        targetClusters: testClusters,
        targetClusterSize: 3,
        initialTiles: [
          'Boiling',
          'Scorching',
          'Steaming',
          'Freezing',
          'Icy',
          'Chilly',
        ],
        hapticService: mockHaptics,
      );

      controller.autoSolve();
      expect(controller.isComplete, isTrue);
      expect(controller.remainingTiles, isEmpty);
      expect(controller.fusedClusters.length, 2);
    });
  });
}
