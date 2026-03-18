import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const TransferDApp());
}

class TransferDApp extends StatelessWidget {
  const TransferDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TransferD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.background,
        useMaterial3: true,
        colorSchemeSeed: AppTheme.brandGreen,
      ),
      home: const SplashScreen(),
    );
  }
}
