import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/vowl_buddy_badge.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSubject({
    Widget? child,
    AuthBloc? authBloc,
    Brightness brightness = Brightness.dark,
  }) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      builder: (context, _) => MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: authBloc != null
              ? BlocProvider<AuthBloc>.value(
                  value: authBloc,
                  child: child ?? const VowlBuddyBadge(),
                )
              : (child ?? const VowlBuddyBadge()),
        ),
      ),
    );
  }

  group('VowlBuddyBadge Unit & Widget Tests', () {
    testWidgets('renders fallback owl emoji when standalone without AuthBloc', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('🦉'), findsOneWidget);
    });

    testWidgets('renders specific mascot and slot accessory when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          child: const VowlBuddyBadge(
            mascotId: 'silver_wing',
            accessoryId: 'golden_crown',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🦅'), findsOneWidget);
      expect(find.text('👑'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildSubject(
          child: VowlBuddyBadge(
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(VowlBuddyBadge));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders seamlessly when AuthBloc is present in context', (
      tester,
    ) async {
      final mockAuthBloc = MockAuthBloc();
      const user = UserEntity(
        id: 'u1',
        email: 'test@vowl.app',
        displayName: 'Hero',
        vowlMascot: 'crystal_swan',
        vowlEquippedAccessory: 'red_scarf',
      );
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(user),
      );

      await tester.pumpWidget(
        buildSubject(
          authBloc: mockAuthBloc,
          child: const VowlBuddyBadge(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🦢'), findsOneWidget);
      expect(find.text('🧣'), findsOneWidget);
    });

    testWidgets('renders in light mode with correct subtle styling', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          brightness: Brightness.light,
          child: const VowlBuddyBadge(
            size: 28,
            mascotSize: 20,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VowlBuddyBadge), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
