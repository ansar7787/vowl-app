import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/entities/arena_match_record.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/pages/arena_duel_screen.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

class _ScreenFakeArenaRepository implements ArenaRepository {
  final StreamController<ArenaDuelSession> roomController =
      StreamController<ArenaDuelSession>.broadcast();
  final StreamController<Map<String, dynamic>> rematchController =
      StreamController<Map<String, dynamic>>.broadcast();
  final List<ArenaMatchRecord> savedRecords = [];
  bool acceptRematchCalled = false;
  bool declineRematchCalled = false;
  bool completeMatchCalled = false;

  @override
  Future<ArenaDuelSession> quickMatch({required UserEntity currentUser}) async =>
      throw UnimplementedError();

  @override
  Future<ArenaDuelSession> challengeRivalDirectly({
    required UserEntity currentUser,
    required UserEntity rival,
    required int rivalRank,
  }) async => throw UnimplementedError();

  @override
  Future<ArenaDuelSession> rematchGhostAi({
    required UserEntity currentUser,
    required String previousGuestId,
    required String previousGuestName,
    String? previousGuestPhotoUrl,
    required double previousAccuracy,
    int previousOpponentDuelWins = 0,
  }) async => throw UnimplementedError();

  @override
  Future<ArenaDuelSession> createRoomCode({
    required UserEntity currentUser,
  }) async => throw UnimplementedError();

  @override
  Future<ArenaDuelSession> joinRoom({
    required String roomCode,
    required UserEntity currentUser,
  }) async => throw UnimplementedError();

  @override
  Stream<ArenaDuelSession> listenToRoom(String roomCode) =>
      roomController.stream;

  @override
  Future<void> submitScore({
    required String roomCode,
    required String userId,
    required int score,
    required bool isHost,
    int correctCount = 0,
    int totalTimeMs = 0,
  }) async {}

  @override
  Future<void> updateTypingProgress({
    required String roomCode,
    required String userId,
    required int charactersTyped,
  }) async {}

  @override
  Stream<int> listenToRivalTypingProgress({
    required String roomCode,
    required String rivalId,
  }) => const Stream.empty();

  @override
  Future<void> sendRematchRequest({
    required String roomCode,
    required String requesterId,
    required String requesterName,
  }) async {}

  @override
  Stream<Map<String, dynamic>> listenToRematchRequest({
    required String roomCode,
  }) => rematchController.stream;

  @override
  Future<ArenaDuelSession> acceptRematch({
    required String originalRoomCode,
    required UserEntity currentUser,
  }) async {
    acceptRematchCalled = true;
    return ArenaDuelSession(
      roomCode: 'VOWL-DUEL-999111',
      hostId: currentUser.id,
      hostName: currentUser.safeDisplayName,
      guestId: 'rival_99',
      guestName: 'LexiconRival',
      status: 'in_progress',
      challenges: _build7Challenges(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<ArenaDuelSession> enterAcceptedRematch({
    required String newRoomCode,
    required UserEntity currentUser,
  }) async => throw UnimplementedError();

  @override
  Future<void> declineRematch({required String roomCode}) async {
    declineRematchCalled = true;
  }

  @override
  Future<void> writeMatchHistory({
    required String userId,
    required ArenaMatchRecord record,
  }) async {
    savedRecords.add(record);
  }

  @override
  Future<List<ArenaMatchRecord>> getMatchHistory({
    required String userId,
    int limit = 50,
  }) async => savedRecords;

  @override
  Future<void> completeMatch({
    required String roomCode,
    required UserEntity currentUser,
    required bool isWinner,
    required bool isDraw,
    bool isPerfect = false,
  }) async {
    completeMatchCalled = true;
  }

  @override
  Future<void> forfeitMatch({
    required String roomCode,
    required String userId,
  }) async {}

  @override
  Future<void> refundStake({required String userId}) async {}

  @override
  Future<void> cancelMatchmaking({required String userId}) async {}
}

List<ArenaChallenge> _build7Challenges() {
  return const [
    ArenaChallenge(
      mechanic: ArenaMechanicType.wordSnap,
      id: 'R1_WS',
      prompt: 'Happy',
      correctAnswer: 'glad',
      scrambledLetters: 'DLGA',
      explanation: 'Glad means happy.',
    ),
    ArenaChallenge(
      mechanic: ArenaMechanicType.typeDuel,
      id: 'R2_TD',
      prompt: 'Feeling of triumph',
      correctAnswer: 'win',
      letterCount: 3,
      explanation: 'Win means triumph.',
    ),
    ArenaChallenge(
      mechanic: ArenaMechanicType.rapidJudge,
      id: 'R3_RJ',
      prompt: 'Judge statements',
      correctAnswer: '',
      explanation: 'Grammar rules.',
      rapidItems: [
        RapidJudgeItem(
          sentence: 'She run fast.',
          isCorrect: false,
          rule: 'Use runs.',
        ),
        RapidJudgeItem(
          sentence: 'Dogs bark.',
          isCorrect: true,
          rule: 'Correct.',
        ),
      ],
    ),
    ArenaChallenge(
      mechanic: ArenaMechanicType.sentenceBuild,
      id: 'R4_SB',
      prompt: 'Arrange sentence',
      correctAnswer: 'Birds fly',
      shuffledWords: ['fly', 'Birds'],
      wordCount: 2,
      explanation: 'Simple sentence.',
    ),
    ArenaChallenge(
      mechanic: ArenaMechanicType.spotError,
      id: 'R5_SE',
      prompt: 'Spot the error',
      correctAnswer: 'less',
      sentenceTokens: ['I', 'have', 'less', 'pens'],
      errorTokenIndex: 2,
      errorToken: 'less',
      correctedToken: 'fewer',
      explanation: 'Fewer for countable nouns.',
    ),
    ArenaChallenge(
      mechanic: ArenaMechanicType.mcq,
      id: 'R6_MCQ',
      prompt: 'Synonym of QUICK?',
      correctAnswer: 'Fast',
      options: ['Slow', 'Fast', 'Cold', 'Hard'],
      correctIndex: 1,
      discipline: 'word_clash',
      explanation: 'Fast means quick.',
    ),
    ArenaChallenge(
      mechanic: ArenaMechanicType.speedSpell,
      id: 'R7_SS',
      prompt: 'Opposite of dark',
      correctAnswer: 'light',
      displayMask: 'l_g_t',
      missingLetters: ['i', 'h'],
      missingPositions: [1, 3],
      explanation: 'Light.',
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUser = UserEntity(
    id: 'host_user_1',
    email: 'host@vowl.app',
    displayName: 'HostPlayer',
    coins: 120,
    duelWins: 18,
  );

  late _MockAuthBloc mockAuthBloc;
  late _MockNetworkInfo mockNetwork;
  late _ScreenFakeArenaRepository fakeRepo;
  late bool prevLowAnim;

  setUp(() async {
    prevLowAnim = VowlMotion.lowAnimationModeOverride.value;
    VowlMotion.lowAnimationModeOverride.value = true;

    await di.sl.reset();
    mockAuthBloc = _MockAuthBloc();
    mockNetwork = _MockNetworkInfo();
    fakeRepo = _ScreenFakeArenaRepository();

    when(() => mockAuthBloc.state)
        .thenReturn(AuthState.authenticated(testUser));
    when(() => mockNetwork.isCurrentlyOffline).thenReturn(false);
    when(() => mockNetwork.onStatusChange)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockNetwork.hasRealConnection).thenAnswer((_) async => true);

    di.sl.registerSingleton<ArenaRepository>(fakeRepo);
    di.sl.registerSingleton<NetworkInfo>(mockNetwork);
  });

  tearDown(() async {
    VowlMotion.lowAnimationModeOverride.value = prevLowAnim;
    await fakeRepo.roomController.close();
    await fakeRepo.rematchController.close();
    await di.sl.reset();
  });

  Widget buildHarness(ArenaDuelSession session) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      builder: (_, _) => BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: ArenaDuelScreen(initialSession: session),
        ),
      ),
    );
  }

  testWidgets('ArenaDuelScreen plays through all 7 mechanics end-to-end and opens ArenaResultDialog', (
    tester,
  ) async {
    final ghostSession = ArenaDuelSession(
      roomCode: 'VOWL-AI-PENT1',
      hostId: testUser.id,
      hostName: testUser.safeDisplayName,
      guestId: 'computer_medium',
      guestName: 'Computer',
      stake: 30,
      pot: 60,
      status: 'in_progress',
      isGhostRival: true,
      ghostAccuracy: 0.78,
      challenges: _build7Challenges(),
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(buildHarness(ghostSession));
    await tester.pump();

    // Round 1: Word Snap
    expect(find.text('ROUND 1 OF 7'), findsOneWidget);
    for (final ch in ['G', 'L', 'A', 'D']) {
      await tester.tap(find.text(ch).last);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 1700));

    // Round 2: Type Duel
    expect(find.text('ROUND 2 OF 7'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'win');
    await tester.pump();
    await tester.tap(find.text('Submit Word'));
    await tester.pump(const Duration(milliseconds: 1700));

    // Round 3: Rapid Fire Judge (2 items)
    expect(find.text('ROUND 3 OF 7'), findsOneWidget);
    await tester.tap(find.text('WRONG'));
    await tester.pump();
    await tester.tap(find.text('CORRECT'));
    await tester.pump(const Duration(milliseconds: 1700));

    // Round 4: Sentence Build
    expect(find.text('ROUND 4 OF 7'), findsOneWidget);
    for (final word in ['Birds', 'fly']) {
      await tester.tap(find.text(word).last);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 1700));

    // Round 5: Spot the Error
    expect(find.text('ROUND 5 OF 7'), findsOneWidget);
    await tester.tap(find.text('less'));
    await tester.pump(const Duration(milliseconds: 1700));

    // Round 6: MCQ Classic
    expect(find.text('ROUND 6 OF 7'), findsOneWidget);
    await tester.tap(find.text('Fast'));
    await tester.pump(const Duration(milliseconds: 1700));

    // Round 7: Speed Spell (2 blanks -> auto-submits)
    expect(find.text('ROUND 7 OF 7'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'i');
    await tester.enterText(find.byType(TextField).at(1), 'h');
    await tester.pump(const Duration(milliseconds: 1700));

    // Advance past finalization suspense delay (1400ms) + allow Ghost timers to settle
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();

    expect(fakeRepo.completeMatchCalled, isTrue);
    expect(fakeRepo.savedRecords.length, 1);
    expect(fakeRepo.savedRecords.first.rounds.length, 7);
    expect(find.text('ROUND BREAKDOWN'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('ArenaDuelScreen displays incoming live PvP rematch overlay and accepts cleanly', (
    tester,
  ) async {
    final liveSession = ArenaDuelSession(
      roomCode: 'VOWL-DUEL-555555',
      hostId: testUser.id,
      hostName: testUser.safeDisplayName,
      guestId: 'rival_99',
      guestName: 'LexiconRival',
      status: 'completed',
      isGhostRival: false,
      hostScore: 500,
      guestScore: 420,
      hostCorrectCount: 7,
      guestCorrectCount: 5,
      challenges: _build7Challenges(),
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(buildHarness(liveSession));
    await tester.pump();

    // Emit incoming rematch request from rival
    fakeRepo.rematchController.add({
      'status': 'pending',
      'requesterId': 'rival_99',
      'requesterName': 'LexiconRival',
    });
    await tester.pump();

    expect(find.text('LexiconRival wants a rematch!'), findsOneWidget);

    await tester.tap(find.text('Accept (30🪙)'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(fakeRepo.acceptRematchCalled, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
