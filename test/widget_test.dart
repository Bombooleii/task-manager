import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/main.dart';

void main() {
  testWidgets('App renders task list screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskManagerApp());
    await tester.pumpAndSettle();

    expect(find.text('Ажлын жагсаалт'), findsOneWidget);
  });
}
