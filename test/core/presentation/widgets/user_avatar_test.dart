import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';

void main() {
  group('UserAvatar Widget Tests', () {
    testWidgets('renders fallback icon when photoUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              photoUrl: null,
              size: 60,
              fallbackIcon: Icons.account_circle,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.account_circle), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders default fallback person icon when photoUrl is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              photoUrl: '   ',
              size: 48,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('renders CachedNetworkImage when photoUrl is an HTTPS url', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              photoUrl: 'https://example.com/avatar.jpg',
              size: 80,
            ),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(cachedImage.imageUrl, 'https://example.com/avatar.jpg');
      expect(cachedImage.fit, BoxFit.cover);
    });

    testWidgets('applies border and custom dimensions correctly', (tester) async {
      const border = Border.fromBorderSide(
        BorderSide(color: Colors.amber, width: 3.0),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              photoUrl: null,
              size: 100,
              border: border,
              backgroundColor: Colors.blueGrey,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(UserAvatar),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.maxWidth, 100);
      expect(container.constraints?.maxHeight, 100);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, border);
      expect(decoration?.shape, BoxShape.circle);
    });
  });
}

