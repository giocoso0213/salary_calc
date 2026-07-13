import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.initialize();
  runApp(const SalaryCalcApp());
}

class SalaryCalcApp extends StatelessWidget {
  const SalaryCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '연봉 실수령액 계산기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
