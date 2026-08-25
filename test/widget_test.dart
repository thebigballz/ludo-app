import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ludo_app/app.dart';

void main() {
  testWidgets('LudoApp mounts inside a Riverpod ProviderScope', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LudoApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(LudoApp), findsOneWidget);
  });
}
