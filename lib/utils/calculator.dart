/// 연봉/식대 입력은 만 원 단위이며, 내부 계산은 원 단위로 수행합니다.
class SalaryResult {
  const SalaryResult({
    required this.annualManwon,
    required this.monthlyGross,
    required this.taxableMonthly,
    required this.nationalPension,
    required this.healthInsurance,
    required this.longTermCare,
    required this.employmentInsurance,
    required this.incomeTax,
    required this.localTax,
    required this.monthlyNet,
    required this.percentileLabel,
  });

  final double annualManwon;
  final double monthlyGross;
  final double taxableMonthly;
  final double nationalPension;
  final double healthInsurance;
  final double longTermCare;
  final double employmentInsurance;
  final double incomeTax;
  final double localTax;
  final double monthlyNet;
  final String percentileLabel;

  double get totalDeductions =>
      nationalPension +
      healthInsurance +
      longTermCare +
      employmentInsurance +
      incomeTax +
      localTax;

  double get hourlyNet => monthlyNet / 209;

  bool get isValid => annualManwon > 0 && monthlyNet > 0;

  static const empty = SalaryResult(
    annualManwon: 0,
    monthlyGross: 0,
    taxableMonthly: 0,
    nationalPension: 0,
    healthInsurance: 0,
    longTermCare: 0,
    employmentInsurance: 0,
    incomeTax: 0,
    localTax: 0,
    monthlyNet: 0,
    percentileLabel: '상위 90%',
  );
}

class SalaryCalculator {
  static const double nationalPensionCap = 298350;
  static const double manwonToWon = 10000;

  /// [annualManwon] 세전 연봉 (만 원), [mealAllowanceManwon] 비과세 식대 (만 원)
  static SalaryResult calculate({
    required double annualManwon,
    double mealAllowanceManwon = 20,
    int dependents = 1,
  }) {
    if (annualManwon <= 0) return SalaryResult.empty;

    final annualWon = annualManwon * manwonToWon;
    final mealWon = mealAllowanceManwon * manwonToWon;
    final monthlyGross = annualWon / 12;
    final taxableMonthly =
        (monthlyGross - mealWon).clamp(0.0, double.infinity).toDouble();

    var nationalPension = taxableMonthly * 0.045;
    if (nationalPension > nationalPensionCap) {
      nationalPension = nationalPensionCap;
    }

    final healthInsurance = taxableMonthly * 0.03545;
    final longTermCare = healthInsurance * 0.1295;
    final employmentInsurance = taxableMonthly * 0.009;

    final taxableManwon = taxableMonthly / manwonToWon;
    final double incomeTax;
    if (taxableManwon <= 300) {
      incomeTax = taxableMonthly * 0.03;
    } else if (taxableManwon <= 500) {
      incomeTax = taxableMonthly * 0.05;
    } else {
      incomeTax = taxableMonthly * 0.08;
    }

    // 부양가족 수는 UI/저장용으로 유지 (요청 수식에는 미반영)
    // ignore: unused_local_variable
    final _ = dependents;

    final localTax = incomeTax * 0.1;
    final monthlyNet = monthlyGross -
        (nationalPension +
            healthInsurance +
            longTermCare +
            employmentInsurance +
            incomeTax +
            localTax);

    return SalaryResult(
      annualManwon: annualManwon,
      monthlyGross: monthlyGross,
      taxableMonthly: taxableMonthly,
      nationalPension: nationalPension,
      healthInsurance: healthInsurance,
      longTermCare: longTermCare,
      employmentInsurance: employmentInsurance,
      incomeTax: incomeTax,
      localTax: localTax,
      monthlyNet: monthlyNet < 0 ? 0 : monthlyNet,
      percentileLabel: percentileForAnnual(annualManwon),
    );
  }

  static String percentileForAnnual(double annualManwon) {
    if (annualManwon >= 15000) return '상위 1%';
    if (annualManwon >= 10000) return '상위 5%';
    if (annualManwon >= 8000) return '상위 10%';
    if (annualManwon >= 6000) return '상위 20%';
    if (annualManwon >= 5000) return '상위 30%';
    if (annualManwon >= 4300) return '상위 40%';
    if (annualManwon >= 3600) return '상위 50%';
    if (annualManwon >= 2800) return '상위 70%';
    return '상위 90%';
  }

  /// 원하는 월 실수령액(만 원)으로부터 세전 연봉(만 원)을 이진 탐색으로 역계산합니다.
  static double reverseAnnualManwon({
    required double targetMonthlyNetManwon,
    double mealAllowanceManwon = 20,
    int dependents = 1,
    int iterations = 20,
  }) {
    if (targetMonthlyNetManwon <= 0) return 0;

    final targetNetWon = targetMonthlyNetManwon * manwonToWon;
    var low = 1.0;
    var high = 100000.0;

    // 상한이 부족하면 확장
    while (calculate(
          annualManwon: high,
          mealAllowanceManwon: mealAllowanceManwon,
          dependents: dependents,
        ).monthlyNet <
        targetNetWon) {
      high *= 2;
      if (high > 1e7) break;
    }

    for (var i = 0; i < iterations; i++) {
      final mid = (low + high) / 2;
      final net = calculate(
        annualManwon: mid,
        mealAllowanceManwon: mealAllowanceManwon,
        dependents: dependents,
      ).monthlyNet;

      if (net < targetNetWon) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return (low + high) / 2;
  }
}
