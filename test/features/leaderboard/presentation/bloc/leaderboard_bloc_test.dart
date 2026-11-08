import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:vowl/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:vowl/features/leaderboard/presentation/bloc/leaderboard_bloc_event_state.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

void main() {
  late MockLeaderboardRepository mockRepository;
  late LeaderboardBloc bloc;

  final testDate = DateTime.utc(2026, 11, 7, 7, 0, 0);
  final todayKey = DateTime.now().toIso8601String().substring(0, 10);

  final user1 = UserEntity(
    id: 'u1',
    email: 'u1@vowl.app',
    displayName: 'User 1',
    totalExp: 1000,
    dailyXpHistory: {todayKey: 200},
    currentStreak: 5,
    kidsCoins: 10,
    completedLevels: {
      'reading': [1, 2, 3],
    },
  );

  final user2 = UserEntity(
    id: 'u2',
    email: 'u2@vowl.app',
    displayName: 'User 2',
    totalExp: 2000,
    dailyXpHistory: {todayKey: 500},
    currentStreak: 10,
    kidsCoins: 20,
    completedLevels: {
      'reading': [1, 2, 3, 4, 5],
    },
  );

  setUp(() {
    mockRepository = MockLeaderboardRepository();
    bloc = LeaderboardBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be LeaderboardInitial', () {
    expect(bloc.state, const LeaderboardInitial());
  });

  group('LoadLeaderboard (Standard / Weekly)', () {
    final rawResult = LeaderboardResult(
      users: [user1, user2],
      lastUpdated: testDate,
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      'emits [LeaderboardLoading, LeaderboardLoaded] sorted by weekly XP descending on successful fetch',
      build: () {
        when(
          () => mockRepository.getTopUsers(limit: any(named: 'limit')),
        ).thenAnswer((_) async => Right(rawResult));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadLeaderboard(isKids: false)),
      expect: () => [
        const LeaderboardLoading(),
        isA<LeaderboardLoaded>()
            .having(
              (s) => s.users.first.id,
              'first user is user2 (500 weekly)',
              'u2',
            )
            .having(
              (s) => s.users.last.id,
              'last user is user1 (200 weekly)',
              'u1',
            )
            .having((s) => s.isKids, 'isKids', false)
            .having((s) => s.lastUpdated, 'lastUpdated', testDate),
      ],
      verify: (_) {
        verify(() => mockRepository.getTopUsers()).called(1);
      },
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      'completes event.completer even when repository returns failure',
      build: () {
        when(
          () => mockRepository.getTopUsers(limit: any(named: 'limit')),
        ).thenAnswer((_) async => const Left(ServerFailure('Network offline')));
        return bloc;
      },
      act: (bloc) async {
        final completer = Completer<void>();
        bloc.add(LoadLeaderboard(isKids: false, completer: completer));
        await completer.future; // Should complete cleanly without hang
      },
      expect: () => [
        const LeaderboardLoading(),
        const LeaderboardError('Network offline'),
      ],
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      'pull-to-refresh does not emit LeaderboardLoading when state is already LeaderboardLoaded',
      build: () {
        when(
          () => mockRepository.getTopUsers(limit: any(named: 'limit')),
        ).thenAnswer((_) async => Right(rawResult));
        return bloc;
      },
      seed: () => LeaderboardLoaded([user1], testDate, isKids: false),
      act: (bloc) => bloc.add(const LoadLeaderboard(isKids: false)),
      expect: () => [
        isA<LeaderboardLoaded>()
            .having((s) => s.users.length, 'users length', 2)
            .having((s) => s.isKids, 'isKids', false),
      ],
    );
  });

  group('LoadLeaderboard (Kids Zone)', () {
    final kidsUserA = UserEntity(
      id: 'k1',
      email: 'k1@vowl.app',
      kidsCoins: 10,
      currentStreak: 2,
      completedLevels: {
        'kids_animals': [1, 2, 3], // 3 levels
      },
    );

    final kidsUserB = UserEntity(
      id: 'k2',
      email: 'k2@vowl.app',
      kidsCoins: 50,
      currentStreak: 5,
      completedLevels: {
        'kids_animals': [1, 2, 3, 4, 5, 6, 7], // 7 levels
      },
    );

    final rawKidsResult = LeaderboardResult(
      users: [kidsUserA, kidsUserB],
      lastUpdated: testDate,
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      'emits [LeaderboardLoading, LeaderboardLoaded] sorted by kids levels completed on successful fetch',
      build: () {
        when(
          () => mockRepository.getTopKidsUsers(limit: any(named: 'limit')),
        ).thenAnswer((_) async => Right(rawKidsResult));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadLeaderboard(isKids: true)),
      expect: () => [
        const LeaderboardLoading(),
        isA<LeaderboardLoaded>()
            .having(
              (s) => s.users.first.id,
              'first user is k2 (7 levels)',
              'k2',
            )
            .having((s) => s.users.last.id, 'last user is k1 (3 levels)', 'k1')
            .having((s) => s.isKids, 'isKids', true),
      ],
      verify: (_) {
        verify(() => mockRepository.getTopKidsUsers()).called(1);
      },
    );
  });
}
