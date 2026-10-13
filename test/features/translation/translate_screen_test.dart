import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/tts_voice_helper.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/translation/presentation/bloc/translation_bloc.dart';
import 'package:vowl/features/translation/presentation/pages/translate_screen.dart';

class MockTranslationBloc extends MockBloc<TranslationEvent, TranslationState>
    implements TranslationBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeTranslationEvent extends Fake implements TranslationEvent {}

class FakeHapticService implements HapticService {
  @override
  bool isHapticsEnabled = true;
  @override
  Future<void> error() async {}
  @override
  Future<void> heavy() async {}
  @override
  Future<void> light() async {}
  @override
  Future<void> rhythmicTick() async {}
  @override
  Future<void> selection() async {}
  @override
  Future<void> success() async {}
  @override
  Future<void> warning() async {}
}

class FakeTtsService implements TtsService {
  @override
  bool isSpeaking = false;

  @override
  Future<void> speak(
    String text, {
    double? rate,
    String? locale,
    List<int>? pauseMarkers,
    TtsVoicePreset? forcedPreset,
    bool isKids = false,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> reloadVoice() async {}

  @override
  Future<void> previewPreset(
    TtsVoicePreset preset, {
    void Function()? onStart,
    void Function()? onDone,
    void Function(dynamic error)? onError,
  }) async {}

  @override
  void setWordCallback(void Function(String word)? callback) {}
}

class FakeSpeechService implements SpeechService {
  @override
  bool isPlaying = false;

  @override
  bool isListening = false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<bool> initializeStt() async => true;

  @override
  Future<void> listen({
    required Function(List<String>, bool) onResult,
    required VoidCallback onDone,
    Function(double)? onSoundLevelChange,
    String? localeId,
    Duration? pauseFor,
    ListenMode listenMode = ListenMode.dictation,
  }) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> speak(String text, {double rate = 0.5, String locale = "en-US"}) async {}

  @override
  void setWordCallback(Function(String)? callback) {}
}

class MockAdService extends Mock implements AdService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeTranslationEvent());
  });

  late MockTranslationBloc mockTranslationBloc;
  late MockAuthBloc mockAuthBloc;
  late FakeTtsService fakeTts;
  late FakeSpeechService fakeSpeech;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockTranslationBloc = MockTranslationBloc();
    mockAuthBloc = MockAuthBloc();
    fakeTts = FakeTtsService();
    fakeSpeech = FakeSpeechService();

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerLazySingleton<HapticService>(() => FakeHapticService());

    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    di.sl.registerLazySingleton<TtsService>(() => fakeTts);

    if (di.sl.isRegistered<SpeechService>()) {
      di.sl.unregister<SpeechService>();
    }
    di.sl.registerLazySingleton<SpeechService>(() => fakeSpeech);

    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
    di.sl.registerLazySingleton<AdService>(() => MockAdService());

    const testUser = UserEntity(
      id: 'test_user',
      email: 'test@vowl.app',
      isPremium: true,
      completedLevels: {},
      totalExp: 100,
    );
    when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(testUser));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => mockTranslationBloc.stream).thenAnswer((_) => const Stream<TranslationState>.empty());
    when(() => mockTranslationBloc.state).thenReturn(
      const TranslationState(
        status: TranslationStatus.loaded,
        currentSourceLanguage: 'English',
        currentTargetLanguage: 'Spanish',
        downloadedLanguages: ['Spanish'],
        freeTranslationsRemaining: 3,
      ),
    );
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TranslationBloc>.value(value: mockTranslationBloc),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => const MaterialApp(
          home: TranslateScreen(),
        ),
      ),
    );
  }

  group('TranslateScreen Widget Tests', () {
    testWidgets('renders all major sections cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 600));

      // Verify Header
      expect(find.text('Translate'), findsOneWidget);
      expect(find.text('50+ languages • Works offline'), findsOneWidget);

      // Verify Language Selector Bar
      expect(find.text('FROM'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('TO'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);

      // Verify Input Area
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);

      // Verify Output Area
      expect(find.text('SPANISH'), findsOneWidget);
      expect(find.text('Translation will appear here'), findsOneWidget);
    });

    testWidgets('typing in TextField shows character count and clear button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 600));

      await tester.enterText(find.byType(TextField), 'Hello world');
      await tester.pump(const Duration(milliseconds: 500));

      // Paste button disappears, clear button and character count appear
      expect(find.text('Paste'), findsNothing);
      expect(find.text('11/600'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets('tapping swap button dispatches TranslationSwapLanguages event', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockTranslationBloc.add(any(that: isA<TranslationSwapLanguages>()))).called(1);
    });

    testWidgets('displays translated text with copy and TTS audio buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockTranslationBloc.state).thenReturn(
        const TranslationState(
          status: TranslationStatus.loaded,
          sourceText: 'Hello',
          translatedText: 'Hola',
          currentSourceLanguage: 'English',
          currentTargetLanguage: 'Spanish',
          downloadedLanguages: ['Spanish'],
          freeTranslationsRemaining: 3,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 600));

      expect(
        find.byWidgetPredicate((w) => w is SelectableText && w.data == 'Hola'),
        findsOneWidget,
      );
      expect(find.text('Copy'), findsOneWidget);
      expect(find.byIcon(Icons.volume_down_rounded), findsOneWidget);
    });

    testWidgets('tapping back button when input is empty pops directly without exit dialog', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 600));

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pump(const Duration(milliseconds: 300));

      // No confirmation dialog was shown because screen was untouched
      expect(find.byType(ModernGameDialog), findsNothing);
    });

    testWidgets('tapping back button when input has text shows exit confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 600));

      // Enter text and hide test keyboard
      await tester.enterText(find.byType(TextField), 'Testing confirmation');
      tester.testTextInput.hide();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      await tester.tap(backButton);
      await tester.pump(const Duration(milliseconds: 400));

      // Exit confirmation dialog appears with KEEP PLAYING and Quit actions
      expect(find.byType(ModernGameDialog), findsOneWidget);
      expect(find.text('KEEP PLAYING'), findsOneWidget);
      expect(find.text('Quit'), findsOneWidget);

      // Dismiss dialog cleanly to cancel repeating animations before test teardown
      await tester.tap(find.text('KEEP PLAYING'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ModernGameDialog), findsNothing);
    });
  });
}
