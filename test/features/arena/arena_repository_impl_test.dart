import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/features/arena/data/repositories/arena_repository_impl.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/domain/entities/arena_match_record.dart';
import 'package:vowl/features/arena/domain/entities/arena_rank.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  Transaction? activeTransaction;

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) {
    return transactionHandler(activeTransaction!);
  }
}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockWriteBatch extends Mock implements WriteBatch {
  final List<String> setDocIds = [];
  final List<String> deletedDocIds = [];

  @override
  void set<T>(
    DocumentReference<T> document,
    T data, [
    SetOptions? options,
  ]) {
    setDocIds.add(document.id);
  }

  @override
  void delete(DocumentReference<Object?> document) {
    deletedDocIds.add(document.id);
  }
}

class MockTransaction extends Mock implements Transaction {
  final List<String> setDocPaths = [];

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    setDocPaths.add(documentReference.path);
    return this;
  }
}

class _SequenceRandom implements Random {
  final List<int> _values;
  int _index = 0;

  _SequenceRandom(this._values);

  @override
  int nextInt(int max) {
    final value = _values[_index % _values.length];
    _index++;
    return value % max;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const hostUser = UserEntity(
    id: 'host_123',
    email: 'host@vowl.app',
    displayName: 'Arena Host',
    coins: 120,
  );

  late MockFirebaseFirestore firestore;
  late MockCollectionReference usersCollection;
  late MockCollectionReference roomsCollection;
  late MockDocumentReference userDocRef;
  late MockDocumentSnapshot userSnapshot;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(Duration.zero);
    registerFallbackValue(MockDocumentReference());
    registerFallbackValue(SetOptions(merge: true));
  });

  setUp(() {
    firestore = MockFirebaseFirestore();
    usersCollection = MockCollectionReference();
    roomsCollection = MockCollectionReference();
    userDocRef = MockDocumentReference();
    userSnapshot = MockDocumentSnapshot();

    when(() => firestore.collection('users')).thenReturn(usersCollection);
    when(() => firestore.collection('arena_rooms')).thenReturn(roomsCollection);
    when(() => usersCollection.doc(hostUser.id)).thenReturn(userDocRef);

    when(() => userSnapshot.exists).thenReturn(true);
    when(
      () => userSnapshot.data(),
    ).thenReturn(<String, dynamic>{'coins': 120, 'coinHistory': <dynamic>[]});
    when(() => userDocRef.get()).thenAnswer((_) async => userSnapshot);
    when(() => userDocRef.update(any())).thenAnswer((_) async {});
  });

  group('ArenaRepositoryImpl.createRoomCode', () {
    test('generates a 6-digit VOWL-DUEL code and creates an unused room', () async {
      final candidateDocRef = MockDocumentReference();
      final candidateSnapshot = MockDocumentSnapshot();
      final tx = MockTransaction();
      firestore.activeTransaction = tx;

      when(() => candidateSnapshot.exists).thenReturn(false);
      when(() => candidateDocRef.path).thenReturn('arena_rooms/VOWL-DUEL-223456');
      when(() => roomsCollection.doc('VOWL-DUEL-223456')).thenReturn(
        candidateDocRef,
      );
      when(() => tx.get(userDocRef)).thenAnswer((_) async => userSnapshot);
      when(
        () => tx.update(userDocRef, any()),
      ).thenReturn(tx);
      when(
        () => tx.get(candidateDocRef),
      ).thenAnswer((_) async => candidateSnapshot);

      final repo = ArenaRepositoryImpl(
        firestore,
        _SequenceRandom([123456]),
      );

      final session = await repo.createRoomCode(currentUser: hostUser);

      expect(session.roomCode, 'VOWL-DUEL-223456');
      expect(RegExp(r'^VOWL-DUEL-\d{6}$').hasMatch(session.roomCode), isTrue);
      expect(session.status, 'waiting');
      expect(tx.setDocPaths, ['arena_rooms/VOWL-DUEL-223456']);
    });

    test('retries when candidate room code already exists and succeeds on free code', () async {
      final collidedDocRef = MockDocumentReference();
      final collidedSnapshot = MockDocumentSnapshot();
      final freeDocRef = MockDocumentReference();
      final freeSnapshot = MockDocumentSnapshot();
      final tx = MockTransaction();
      firestore.activeTransaction = tx;

      when(() => collidedSnapshot.exists).thenReturn(true);
      when(() => freeSnapshot.exists).thenReturn(false);
      when(() => collidedDocRef.path).thenReturn('arena_rooms/VOWL-DUEL-100001');
      when(() => freeDocRef.path).thenReturn('arena_rooms/VOWL-DUEL-100002');
      when(() => roomsCollection.doc('VOWL-DUEL-100001')).thenReturn(
        collidedDocRef,
      );
      when(() => roomsCollection.doc('VOWL-DUEL-100002')).thenReturn(
        freeDocRef,
      );

      when(() => tx.get(userDocRef)).thenAnswer((_) async => userSnapshot);
      when(() => tx.update(userDocRef, any())).thenReturn(tx);
      when(
        () => tx.get(collidedDocRef),
      ).thenAnswer((_) async => collidedSnapshot);
      when(() => tx.get(freeDocRef)).thenAnswer((_) async => freeSnapshot);

      final repo = ArenaRepositoryImpl(
        firestore,
        _SequenceRandom([1, 2]),
      );

      final session = await repo.createRoomCode(currentUser: hostUser);

      expect(session.roomCode, 'VOWL-DUEL-100002');
      expect(tx.setDocPaths, ['arena_rooms/VOWL-DUEL-100002']);
    });

    test('refunds entry stake when all generated room codes collide', () async {
      final collidedDocRef = MockDocumentReference();
      final collidedSnapshot = MockDocumentSnapshot();
      final tx = MockTransaction();
      firestore.activeTransaction = tx;

      when(() => collidedSnapshot.exists).thenReturn(true);
      when(() => collidedDocRef.path).thenReturn('arena_rooms/VOWL-DUEL-100005');
      when(() => roomsCollection.doc(any())).thenReturn(collidedDocRef);

      when(() => tx.get(userDocRef)).thenAnswer((_) async => userSnapshot);
      when(() => tx.update(userDocRef, any())).thenReturn(tx);
      when(
        () => tx.get(collidedDocRef),
      ).thenAnswer((_) async => collidedSnapshot);

      final repo = ArenaRepositoryImpl(
        firestore,
        _SequenceRandom([5]),
      );

      await expectLater(
        repo.createRoomCode(currentUser: hostUser),
        throwsException,
      );

      expect(tx.setDocPaths, isEmpty);
      verify(() => userDocRef.update(any())).called(1);
    });
  });

  group('ArenaRepositoryImpl Hybrid Rematch & Match History', () {
    test('rematchGhostAi deducts stake and preserves guest identity with 7 hybrid challenges', () async {
      final tx = MockTransaction();
      firestore.activeTransaction = tx;
      when(() => tx.get(userDocRef)).thenAnswer((_) async => userSnapshot);
      when(() => tx.update(userDocRef, any())).thenReturn(tx);

      final repo = ArenaRepositoryImpl(
        firestore,
        _SequenceRandom([424242]),
      );

      final session = await repo.rematchGhostAi(
        currentUser: hostUser,
        previousGuestId: 'computer_hard',
        previousGuestName: 'Computer',
        previousAccuracy: 0.90,
        previousOpponentDuelWins: 25,
      );

      expect(session.roomCode, startsWith('VOWL-AI-'));
      expect(session.guestId, 'computer_hard');
      expect(session.guestDuelWins, 25);
      expect(session.ghostAccuracy, 0.90);
      expect(session.isGhostRival, isTrue);
      expect(session.challenges.length, 7);
      verify(() => tx.update(userDocRef, any())).called(1);
    });

    test('sendRematchRequest writes pending doc initially and auto-accepts on simultaneous tap', () async {
      final roomRef = MockDocumentReference();
      final roomSnap = MockDocumentSnapshot();
      final rematchColl = MockCollectionReference();
      final rematchRef = MockDocumentReference();
      final rematchSnap = MockDocumentSnapshot();
      final newRoomRef = MockDocumentReference();
      final tx = MockTransaction();
      firestore.activeTransaction = tx;

      when(() => roomsCollection.doc('VOWL-DUEL-111111')).thenReturn(roomRef);
      when(() => roomRef.collection('rematch')).thenReturn(rematchColl);
      when(() => rematchColl.doc('request')).thenReturn(rematchRef);
      when(() => rematchRef.path).thenReturn('arena_rooms/VOWL-DUEL-111111/rematch/request');
      when(() => tx.get(rematchRef)).thenAnswer((_) async => rematchSnap);

      // 1) Initial request (no existing doc) -> writes pending
      when(() => rematchSnap.exists).thenReturn(false);
      when(() => rematchSnap.data()).thenReturn(null);

      final repo = ArenaRepositoryImpl(
        firestore,
        _SequenceRandom([777777]),
      );

      await repo.sendRematchRequest(
        roomCode: 'VOWL-DUEL-111111',
        requesterId: 'host_123',
        requesterName: 'Arena Host',
      );
      expect(tx.setDocPaths, ['arena_rooms/VOWL-DUEL-111111/rematch/request']);

      // 2) Simultaneous rival tap while host_123 request is pending -> auto-creates room + accepted!
      tx.setDocPaths.clear();
      when(() => tx.update(any(), any())).thenReturn(tx);
      when(() => rematchSnap.exists).thenReturn(true);
      when(() => rematchSnap.data()).thenReturn({
        'status': 'pending',
        'requesterId': 'host_123',
        'requesterName': 'Arena Host',
      });
      when(() => tx.get(roomRef)).thenAnswer((_) async => roomSnap);
      when(() => roomSnap.exists).thenReturn(true);
      when(() => roomSnap.data()).thenReturn({
        'hostId': 'host_123',
        'hostName': 'Arena Host',
        'guestId': 'guest_456',
        'guestName': 'Arena Guest',
        'hostDuelWins': 10,
        'guestDuelWins': 15,
      });
      when(() => roomsCollection.doc('VOWL-DUEL-877777')).thenReturn(newRoomRef);
      when(() => newRoomRef.path).thenReturn('arena_rooms/VOWL-DUEL-877777');

      await repo.sendRematchRequest(
        roomCode: 'VOWL-DUEL-111111',
        requesterId: 'guest_456',
        requesterName: 'Arena Guest',
      );

      expect(tx.setDocPaths, ['arena_rooms/VOWL-DUEL-877777']);
      verify(
        () => tx.update(
          rematchRef,
          {
            'status': 'accepted',
            'newRoomCode': 'VOWL-DUEL-877777',
            'acceptedBy': 'guest_456',
          },
        ),
      ).called(1);
    });

    test('declineRematch merges declined status', () async {
      final roomRef = MockDocumentReference();
      final rematchColl = MockCollectionReference();
      final rematchRef = MockDocumentReference();

      when(() => roomsCollection.doc('VOWL-DUEL-333333')).thenReturn(roomRef);
      when(() => roomRef.collection('rematch')).thenReturn(rematchColl);
      when(() => rematchColl.doc('request')).thenReturn(rematchRef);
      when(() => rematchRef.set(any(), any())).thenAnswer((_) async {});

      final repo = ArenaRepositoryImpl(firestore, _SequenceRandom([1]));
      await repo.declineRematch(roomCode: 'VOWL-DUEL-333333');

      verify(
        () => rematchRef.set({'status': 'declined'}, any()),
      ).called(1);
    });

    test('writeMatchHistory trims oldest records past 50-doc cap and getMatchHistory parses results', () async {
      final historyColl = MockCollectionReference();
      final orderedQuery = MockQuery();
      final limitedQuery = MockQuery();
      final existingQuerySnap = MockQuerySnapshot();
      final newDocRef = MockDocumentReference();
      final batch = MockWriteBatch();

      when(() => userDocRef.collection('arena_match_history')).thenReturn(historyColl);
      when(() => historyColl.doc('REC_NEW')).thenReturn(newDocRef);
      when(() => newDocRef.id).thenReturn('REC_NEW');
      when(() => historyColl.orderBy('timestamp', descending: true))
          .thenReturn(orderedQuery);
      when(() => orderedQuery.get()).thenAnswer((_) async => existingQuerySnap);
      when(() => orderedQuery.limit(50)).thenReturn(limitedQuery);
      when(() => firestore.batch()).thenReturn(batch);
      when(() => batch.commit()).thenAnswer((_) async {});

      // Build 51 existing docs so 2 oldest docs get pruned alongside inserting 1 new doc
      final existingDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.generate(
        51,
        (i) {
          final qDoc = MockQueryDocumentSnapshot();
          final dRef = MockDocumentReference();
          when(() => qDoc.id).thenReturn('OLD_$i');
          when(() => qDoc.reference).thenReturn(dRef);
          when(() => dRef.id).thenReturn('OLD_$i');
          when(() => qDoc.data()).thenReturn({
            'id': 'OLD_$i',
            'roomCode': 'VOWL-AI-$i',
            'opponentName': 'Computer',
            'opponentRank': ArenaRank.recruit.key,
            'isGhostRival': true,
            'result': 'win',
            'myScore': 400,
            'rivalScore': 300,
            'myCorrectCount': 6,
            'rivalCorrectCount': 4,
            'rounds': <dynamic>[],
            'timestamp': Timestamp.fromDate(DateTime(2026, 11, 1)),
          });
          return qDoc;
        },
      );
      when(() => existingQuerySnap.docs).thenReturn(existingDocs);
      when(() => limitedQuery.get()).thenAnswer((_) async => existingQuerySnap);

      final repo = ArenaRepositoryImpl(firestore, _SequenceRandom([1]));
      final record = ArenaMatchRecord(
        id: 'REC_NEW',
        roomCode: 'VOWL-DUEL-999000',
        opponentName: 'LexiconRival',
        opponentRank: ArenaRank.gladiator,
        result: 'win',
        myScore: 540,
        rivalScore: 420,
        myCorrectCount: 7,
        rivalCorrectCount: 5,
        rounds: const [
          ArenaRoundResult(
            mechanic: ArenaMechanicType.wordSnap,
            isCorrect: true,
            myTimeMs: 3200,
            myPoints: 77,
          ),
        ],
        timestamp: DateTime(2026, 11, 28),
      );

      await repo.writeMatchHistory(userId: hostUser.id, record: record);

      expect(batch.setDocIds, ['REC_NEW']);
      expect(batch.deletedDocIds, ['OLD_49', 'OLD_50']);

      final fetched = await repo.getMatchHistory(userId: hostUser.id, limit: 50);
      expect(fetched.length, 51);
      expect(fetched.first.id, 'OLD_0');
    });
  });
}
