import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/features/arena/data/repositories/arena_repository_impl.dart';
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
}
