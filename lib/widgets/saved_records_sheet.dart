import 'package:flutter/material.dart';

import '../models/salary_record.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class SavedRecordsSheet extends StatelessWidget {
  const SavedRecordsSheet({
    super.key,
    required this.records,
    required this.scrollController,
    required this.onSelect,
    required this.onDelete,
    required this.isPrivacyMode,
  });

  final List<SalaryRecord> records;
  final ScrollController scrollController;
  final void Function(SalaryRecord record) onSelect;
  final void Function(String id) onDelete;
  final bool isPrivacyMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '저장된 조건',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? const Center(
                    child: Text(
                      '저장된 조건이 없습니다.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Material(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onSelect(record),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.typeLabel,
                                        style: const TextStyle(
                                          color: AppTheme.accent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isPrivacyMode
                                            ? (record.summary ?? '')
                                                .replaceAllMapped(
                                                RegExp(r'[\d,]+'),
                                                (_) => '***',
                                              )
                                            : (record.summary ?? '-'),
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatDateTime(record.savedAt),
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => onDelete(record.id),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
