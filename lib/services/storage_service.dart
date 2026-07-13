import 'package:shared_preferences/shared_preferences.dart';

import '../models/salary_record.dart';

class StorageService {
  static const _recordsKey = 'salary_records';
  static const _saveCountKey = 'save_count';

  Future<List<SalaryRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_recordsKey) ?? '';
    final records = SalaryRecord.listFromJsonString(jsonString);
    records.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return records;
  }

  Future<void> saveRecord(SalaryRecord record) async {
    final records = await loadRecords();
    records.removeWhere((item) => item.id == record.id);
    records.insert(0, record);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recordsKey,
      SalaryRecord.listToJsonString(records),
    );
  }

  Future<void> deleteRecord(String id) async {
    final records = await loadRecords();
    records.removeWhere((item) => item.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recordsKey,
      SalaryRecord.listToJsonString(records),
    );
  }

  Future<int> incrementSaveCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_saveCountKey) ?? 0) + 1;
    await prefs.setInt(_saveCountKey, count);
    return count;
  }
}
