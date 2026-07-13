import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/salary_record.dart';
import '../services/ad_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/calculator.dart';
import '../utils/formatters.dart';
import '../utils/number_input_formatter.dart';
import '../utils/platform_support.dart';
import '../widgets/saved_records_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _storageService = StorageService();
  late final TabController _tabController;

  // Tab 1
  final _annualController = TextEditingController();
  final _mealController = TextEditingController(text: '20');
  final _dependentsController = TextEditingController(text: '1');

  // Tab 2
  final _currentAnnualController = TextEditingController();
  final _raisedAnnualController = TextEditingController();

  // Tab 3
  final _targetNetController = TextEditingController();
  final _reverseMealController = TextEditingController(text: '20');
  final _reverseDependentsController = TextEditingController(text: '1');

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerLoaded = false;
  bool isPrivacyMode = false;

  SalaryResult _netResult = SalaryResult.empty;
  SalaryResult _currentRaiseResult = SalaryResult.empty;
  SalaryResult _raisedResult = SalaryResult.empty;
  double _reversedAnnualManwon = 0;

  List<SalaryRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBannerAd();
    _preloadInterstitialAd();
    _loadRecords();

    for (final c in [
      _annualController,
      _mealController,
      _dependentsController,
    ]) {
      c.addListener(_recalculateNet);
    }
    for (final c in [_currentAnnualController, _raisedAnnualController]) {
      c.addListener(_recalculateRaise);
    }
    for (final c in [
      _targetNetController,
      _reverseMealController,
      _reverseDependentsController,
    ]) {
      c.addListener(_recalculateReverse);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _annualController,
      _mealController,
      _dependentsController,
      _currentAnnualController,
      _raisedAnnualController,
      _targetNetController,
      _reverseMealController,
      _reverseDependentsController,
    ]) {
      c.dispose();
    }
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    if (!isAdMobSupported) return;
    _bannerAd = AdService.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _isBannerLoaded = true);
      },
    );
  }

  void _preloadInterstitialAd() {
    if (!isAdMobSupported) return;
    AdService.loadInterstitialAd(
      onLoaded: (ad) {
        _interstitialAd?.dispose();
        _interstitialAd = ad;
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialAd = null;
            _preloadInterstitialAd();
          },
          onAdFailedToShowFullScreenContent: (ad, _) {
            ad.dispose();
            _interstitialAd = null;
            _preloadInterstitialAd();
          },
        );
      },
    );
  }

  Future<void> _loadRecords() async {
    final records = await _storageService.loadRecords();
    if (mounted) setState(() => _records = records);
  }

  double _parseInput(String value) {
    final cleaned = value.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  int _parseInt(String value) {
    final cleaned = value.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return 1;
    return int.tryParse(cleaned) ?? 1;
  }

  void _recalculateNet() {
    setState(() {
      _netResult = SalaryCalculator.calculate(
        annualManwon: _parseInput(_annualController.text),
        mealAllowanceManwon: _parseInput(_mealController.text),
        dependents: _parseInt(_dependentsController.text),
      );
    });
  }

  void _recalculateRaise() {
    setState(() {
      _currentRaiseResult = SalaryCalculator.calculate(
        annualManwon: _parseInput(_currentAnnualController.text),
      );
      _raisedResult = SalaryCalculator.calculate(
        annualManwon: _parseInput(_raisedAnnualController.text),
      );
    });
  }

  void _recalculateReverse() {
    setState(() {
      _reversedAnnualManwon = SalaryCalculator.reverseAnnualManwon(
        targetMonthlyNetManwon: _parseInput(_targetNetController.text),
        mealAllowanceManwon: _parseInput(_reverseMealController.text),
        dependents: _parseInt(_reverseDependentsController.text),
      );
    });
  }

  String _maskMoney(double amount) =>
      isPrivacyMode ? maskCurrency() : formatCurrency(amount);

  String _maskPercentile(String label) =>
      isPrivacyMode ? maskPercentile() : label;

  void _togglePrivacyMode() {
    setState(() => isPrivacyMode = !isPrivacyMode);
  }

  Future<void> _saveCurrentTab() async {
    final tabIndex = _tabController.index;
    SalaryRecord? record;

    if (tabIndex == 0) {
      if (!_netResult.isValid) {
        _showSnack('현재 연봉을 입력해 주세요.');
        return;
      }
      record = SalaryRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: SalaryRecordType.netPay,
        savedAt: DateTime.now(),
        annualManwon: _netResult.annualManwon,
        mealAllowanceManwon: _parseInput(_mealController.text),
        dependents: _parseInt(_dependentsController.text),
        monthlyNet: _netResult.monthlyNet,
        summary:
            '연봉 ${formatNumber(_netResult.annualManwon)}만 · 실수령 ${formatCurrency(_netResult.monthlyNet)}',
      );
    } else if (tabIndex == 1) {
      if (!_currentRaiseResult.isValid || !_raisedResult.isValid) {
        _showSnack('현재 연봉과 인상 연봉을 입력해 주세요.');
        return;
      }
      final diff = _raisedResult.monthlyNet - _currentRaiseResult.monthlyNet;
      record = SalaryRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: SalaryRecordType.raiseCompare,
        savedAt: DateTime.now(),
        annualManwon: _currentRaiseResult.annualManwon,
        raiseAnnualManwon: _raisedResult.annualManwon,
        monthlyNet: diff,
        summary:
            '${formatNumber(_currentRaiseResult.annualManwon)}만 → ${formatNumber(_raisedResult.annualManwon)}만 · 월 ${diff >= 0 ? '+' : ''}${formatCurrency(diff)}',
      );
    } else {
      final target = _parseInput(_targetNetController.text);
      if (target <= 0 || _reversedAnnualManwon <= 0) {
        _showSnack('원하는 월 실수령액을 입력해 주세요.');
        return;
      }
      record = SalaryRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: SalaryRecordType.reverseCalc,
        savedAt: DateTime.now(),
        targetNetManwon: target,
        annualManwon: _reversedAnnualManwon,
        mealAllowanceManwon: _parseInput(_reverseMealController.text),
        dependents: _parseInt(_reverseDependentsController.text),
        monthlyNet: target * SalaryCalculator.manwonToWon,
        summary:
            '세후 ${formatNumber(target)}만 → 세전 연봉 ${formatNumber(_reversedAnnualManwon.roundToDouble())}만',
      );
    }

    await _storageService.saveRecord(record);
    await _loadRecords();
    if (!mounted) return;

    _showSnack('조건이 저장되었습니다.');

    final saveCount = await _storageService.incrementSaveCount();
    if (saveCount % 4 == 0) {
      _showInterstitialAd();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showInterstitialAd() {
    final ad = _interstitialAd;
    if (ad != null) {
      ad.show();
      _interstitialAd = null;
    } else {
      _preloadInterstitialAd();
    }
  }

  void _applyRecord(SalaryRecord record) {
    switch (record.type) {
      case SalaryRecordType.netPay:
        _tabController.animateTo(0);
        _annualController.text =
            formatInputNumber(record.annualManwon ?? 0);
        _mealController.text =
            formatInputNumber(record.mealAllowanceManwon);
        _dependentsController.text = record.dependents.toString();
        _recalculateNet();
      case SalaryRecordType.raiseCompare:
        _tabController.animateTo(1);
        _currentAnnualController.text =
            formatInputNumber(record.annualManwon ?? 0);
        _raisedAnnualController.text =
            formatInputNumber(record.raiseAnnualManwon ?? 0);
        _recalculateRaise();
      case SalaryRecordType.reverseCalc:
        _tabController.animateTo(2);
        _targetNetController.text =
            formatInputNumber(record.targetNetManwon ?? 0);
        _reverseMealController.text =
            formatInputNumber(record.mealAllowanceManwon);
        _reverseDependentsController.text = record.dependents.toString();
        _recalculateReverse();
    }
    Navigator.pop(context);
  }

  Future<void> _deleteRecord(String id) async {
    await _storageService.deleteRecord(id);
    await _loadRecords();
    if (mounted) _showSnack('저장 조건이 삭제되었습니다.');
  }

  void _openSavedSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SavedRecordsSheet(
          records: _records,
          scrollController: scrollController,
          onSelect: _applyRecord,
          onDelete: _deleteRecord,
          isPrivacyMode: isPrivacyMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '💰 연봉 실수령액 계산기',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '저장 목록',
            onPressed: _openSavedSheet,
            icon: const Icon(Icons.list_alt, color: AppTheme.accent),
          ),
          IconButton(
            tooltip: isPrivacyMode ? '숨김 모드 해제' : '상사 접근! 숨김 모드',
            onPressed: _togglePrivacyMode,
            icon: Icon(
              isPrivacyMode ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.accent,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '실수령액'),
            Tab(text: '인상 비교'),
            Tab(text: '세후 역계산'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNetPayTab(),
                _buildRaiseTab(),
                _buildReverseTab(),
              ],
            ),
          ),
          if (_isBannerLoaded && _bannerAd != null)
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                height: _bannerAd!.size.height.toDouble(),
                color: AppTheme.surface.withValues(alpha: 0.95),
                alignment: Alignment.center,
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetPayTab() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hourly = _netResult.hourlyNet;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _annualController,
            label: '현재 연봉 (세전, 만 원)',
            hint: '예: 5500',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _mealController,
                  label: '비과세 식대 (만 원)',
                  hint: '20',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _dependentsController,
                  label: '부양가족 수',
                  hint: '1',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    MaxValueInputFormatter(20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHeroNetCard(_netResult),
          const SizedBox(height: 16),
          _buildDeductionList(_netResult),
          const SizedBox(height: 16),
          if (_netResult.isValid) _buildValueCard(hourly),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveCurrentTab,
            child: const Text('이 조건 저장하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroNetCard(SalaryResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Text(
            '월 실수령액',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.isValid ? _maskMoney(result.monthlyNet) : '-',
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              result.isValid
                  ? '대한민국 직장인 ${_maskPercentile(result.percentileLabel)} 수준입니다! 🎉'
                  : '연봉을 입력하면 소득 백분위가 표시됩니다',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionList(SalaryResult result) {
    final items = [
      ('국민연금', result.nationalPension),
      ('건강보험', result.healthInsurance),
      ('장기요양', result.longTermCare),
      ('고용보험', result.employmentInsurance),
      ('근로소득세', result.incomeTax),
      ('지방소득세', result.localTax),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '항목별 세금·공제',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.$1,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    result.isValid ? _maskMoney(item.$2) : '-',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppTheme.border, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '공제 합계',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                result.isValid ? _maskMoney(result.totalDeductions) : '-',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(double hourly) {
    final perSecond = hourly / 3600;
    final toilet10min = hourly / 6;
    final starbucksMinutes = hourly > 0 ? (4500 / hourly) * 60 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내 연봉 가치 계산기',
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '세후 시급 ${_maskMoney(hourly)}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          _valueLine(
            '숨만 쉬어도 1초당 ${_maskMoney(perSecond)} 적립 중 ⏱️',
          ),
          const SizedBox(height: 10),
          _valueLine(
            '화장실에서 10분 버티면 ${_maskMoney(toilet10min)} 획득! 🚽',
          ),
          const SizedBox(height: 10),
          _valueLine(
            isPrivacyMode
                ? '스타벅스 커피 한 잔(4,500원)을 마시려면 ***분 동안 일해야 합니다. ☕'
                : '스타벅스 커피 한 잔(4,500원)을 마시려면 ${formatNumber(starbucksMinutes)}분 동안 일해야 합니다. ☕',
          ),
        ],
      ),
    );
  }

  Widget _valueLine(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  Widget _buildRaiseTab() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final diff = _raisedResult.monthlyNet - _currentRaiseResult.monthlyNet;
    final taxDiff =
        _raisedResult.totalDeductions - _currentRaiseResult.totalDeductions;
    final hasBoth = _currentRaiseResult.isValid && _raisedResult.isValid;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _currentAnnualController,
            label: '현재 연봉 (세전, 만 원)',
            hint: '예: 5000',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _raisedAnnualController,
            label: '인상될 연봉 (세전, 만 원)',
            hint: '예: 6000',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                const Text(
                  '월 실수령액 차액',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasBoth
                      ? (isPrivacyMode
                          ? '월 +***,***원 더 받아요!'
                          : '월 ${diff >= 0 ? '+' : ''}${formatCurrency(diff)} 더 받아요!')
                      : '-',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _compareCard(
                  title: '소득 백분위',
                  content: hasBoth
                      ? '${_maskPercentile(_currentRaiseResult.percentileLabel)} ➡ ${_maskPercentile(_raisedResult.percentileLabel)}'
                      : '-',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _compareCard(
                  title: '세금 공제 차액',
                  content: hasBoth
                      ? (isPrivacyMode
                          ? '***,***원'
                          : '${taxDiff >= 0 ? '+' : ''}${formatCurrency(taxDiff)}')
                      : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _compareCard(
                  title: '현재 월 실수령',
                  content: hasBoth
                      ? _maskMoney(_currentRaiseResult.monthlyNet)
                      : '-',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _compareCard(
                  title: '인상 후 월 실수령',
                  content:
                      hasBoth ? _maskMoney(_raisedResult.monthlyNet) : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveCurrentTab,
            child: const Text('이 조건 저장하기'),
          ),
        ],
      ),
    );
  }

  Widget _compareCard({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReverseTab() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final target = _parseInput(_targetNetController.text);
    final hasResult = target > 0 && _reversedAnnualManwon > 0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _targetNetController,
            label: '원하는 월 실수령액 (세후, 만 원)',
            hint: '예: 500',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _reverseMealController,
                  label: '비과세 식대 (만 원)',
                  hint: '20',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _reverseDependentsController,
                  label: '부양가족 수',
                  hint: '1',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    MaxValueInputFormatter(20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
            ),
            child: hasResult
                ? Column(
                    children: [
                      Text(
                        isPrivacyMode
                            ? '매달 세후 ***만 원을 받으려면,'
                            : '매달 세후 ${formatNumber(target)}만 원을 받으려면,',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isPrivacyMode
                            ? '세전 연봉 ***,***만 원\n계약이 필요합니다!'
                            : '세전 연봉 ${formatNumber(_reversedAnnualManwon.roundToDouble())}만 원\n계약이 필요합니다!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    '원하는 세후 금액을 입력하면\n필요한 세전 연봉을 역계산합니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveCurrentTab,
            child: const Text('이 조건 저장하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType =
        const TextInputType.numberWithOptions(decimal: true),
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters ?? [ThousandsSeparatorInputFormatter()],
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
