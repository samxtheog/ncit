import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SkillBridgeApp());
    expect(find.byType(SkillBridgeApp), findsOneWidget);
  });
}
