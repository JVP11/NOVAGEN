// Basic smoke test — ensures the NovaGen home shell renders.
import 'package:flutter_test/flutter_test.dart';

import 'package:safeink_scanner/main.dart';

void main() {
  testWidgets('renders NovaGen home shell', (WidgetTester tester) async {
    kGlobalCameras = [];
    await tester.pumpWidget(const NovaGenSafeInkApp());
    await tester.pumpAndSettle();

    expect(find.text('START SCANNING'), findsOneWidget);
    expect(find.textContaining('Nova'), findsWidgets);
  });
}
