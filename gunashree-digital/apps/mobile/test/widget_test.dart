import 'package:flutter_test/flutter_test.dart';

import 'package:gunashree_digital/app_state.dart';
import 'package:gunashree_digital/main.dart';
import 'package:gunashree_digital/services.dart';

void main() {
  testWidgets('renders the Gunashree Digital home experience', (tester) async {
    final state = AppState(ApiService());
    await tester.pumpWidget(GunashreeApp(state: state));
    expect(find.text('Good morning, designer'), findsOneWidget);
    expect(find.text('Make something people remember.'), findsOneWidget);
  });
}
