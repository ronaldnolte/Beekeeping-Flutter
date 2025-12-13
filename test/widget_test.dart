import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_forecast/main.dart';

void main() {
  testWidgets('App loads and shows home screen', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const BeekeepingApp());
    await tester.pumpAndSettle();

    // Verify that the title is present.
    expect(find.text('Beekeeping Manager'), findsOneWidget);

    // Verify that the empty state is shown (since no apiaries in mock prefs).
    expect(find.text('No apiaries yet'), findsOneWidget);
    expect(find.text('Create Apiary'), findsOneWidget);
  });
}
