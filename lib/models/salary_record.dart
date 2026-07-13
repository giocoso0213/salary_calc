import 'dart:convert';

enum SalaryRecordType {
  netPay,
  raiseCompare,
  reverseCalc,
}

class SalaryRecord {
  const SalaryRecord({
    required this.id,
    required this.type,
    required this.savedAt,
    this.annualManwon,
    this.raiseAnnualManwon,
    this.targetNetManwon,
    this.mealAllowanceManwon = 20,
    this.dependents = 1,
    this.monthlyNet,
    this.summary,
  });

  final String id;
  final SalaryRecordType type;
  final DateTime savedAt;
  final double? annualManwon;
  final double? raiseAnnualManwon;
  final double? targetNetManwon;
  final double mealAllowanceManwon;
  final int dependents;
  final double? monthlyNet;
  final String? summary;

  String get typeLabel {
    switch (type) {
      case SalaryRecordType.netPay:
        return '실수령액 계산';
      case SalaryRecordType.raiseCompare:
        return '인상 비교';
      case SalaryRecordType.reverseCalc:
        return '세후 역계산';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'savedAt': savedAt.toIso8601String(),
        'annualManwon': annualManwon,
        'raiseAnnualManwon': raiseAnnualManwon,
        'targetNetManwon': targetNetManwon,
        'mealAllowanceManwon': mealAllowanceManwon,
        'dependents': dependents,
        'monthlyNet': monthlyNet,
        'summary': summary,
      };

  factory SalaryRecord.fromJson(Map<String, dynamic> json) {
    return SalaryRecord(
      id: json['id'] as String,
      type: SalaryRecordType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SalaryRecordType.netPay,
      ),
      savedAt: DateTime.parse(json['savedAt'] as String),
      annualManwon: (json['annualManwon'] as num?)?.toDouble(),
      raiseAnnualManwon: (json['raiseAnnualManwon'] as num?)?.toDouble(),
      targetNetManwon: (json['targetNetManwon'] as num?)?.toDouble(),
      mealAllowanceManwon:
          (json['mealAllowanceManwon'] as num?)?.toDouble() ?? 20,
      dependents: (json['dependents'] as num?)?.toInt() ?? 1,
      monthlyNet: (json['monthlyNet'] as num?)?.toDouble(),
      summary: json['summary'] as String?,
    );
  }

  static List<SalaryRecord> listFromJsonString(String jsonString) {
    if (jsonString.isEmpty) return [];
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((item) => SalaryRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static String listToJsonString(List<SalaryRecord> records) {
    return jsonEncode(records.map((record) => record.toJson()).toList());
  }
}
