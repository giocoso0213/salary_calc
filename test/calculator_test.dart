import 'package:flutter_test/flutter_test.dart';
import 'package:salary_calc/utils/calculator.dart';

void main() {
  group('SalaryCalculator', () {
    test('월 실수령액과 국민연금 상한을 계산한다', () {
      final result = SalaryCalculator.calculate(
        annualManwon: 5500,
        mealAllowanceManwon: 20,
      );

      expect(result.monthlyGross, closeTo(5500 * 10000 / 12, 0.01));
      expect(result.nationalPension, lessThanOrEqualTo(298350));
      expect(result.monthlyNet, greaterThan(0));
      expect(result.percentileLabel, '상위 30%');
    });

    test('소득 백분위 구간을 반환한다', () {
      expect(SalaryCalculator.percentileForAnnual(15000), '상위 1%');
      expect(SalaryCalculator.percentileForAnnual(6000), '상위 20%');
      expect(SalaryCalculator.percentileForAnnual(2000), '상위 90%');
    });

    test('세후 역계산이 목표 실수령액에 근접한다', () {
      const targetManwon = 400.0;
      final annual = SalaryCalculator.reverseAnnualManwon(
        targetMonthlyNetManwon: targetManwon,
      );
      final result = SalaryCalculator.calculate(annualManwon: annual);
      expect(
        result.monthlyNet,
        closeTo(targetManwon * 10000, 5000),
      );
    });
  });
}
