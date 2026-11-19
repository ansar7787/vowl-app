import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/pages/gourmet_order_mastery_screen.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/pages/gourmet_order_screen.dart';

void main() {
  test('GourmetOrderMasteryScreen is an alias of GourmetOrderScreen', () {
    const screen = GourmetOrderMasteryScreen(level: 1);
    expect(screen, isA<GourmetOrderScreen>());
  });
}
