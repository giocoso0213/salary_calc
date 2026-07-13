import 'package:flutter_test/flutter_test.dart';
import 'package:salary_calc/main.dart';

void main() {
  testWidgets('앱 타이틀이 표시된다', (tester) async {
    await tester.pumpWidget(const SalaryCalcApp());
    expect(find.textContaining('연봉 실수령액 계산기'), findsOneWidget);
  });
}
