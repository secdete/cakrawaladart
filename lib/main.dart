import 'package:flutter/material.dart';
import 'core/constants/bimbel_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/landing/screens/bimbel_landing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CakrawalaBimbelApp());
}

class CakrawalaBimbelApp extends StatelessWidget {
  const CakrawalaBimbelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${BimbelConstants.appName} - ${BimbelConstants.appTagline}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const BimbelLandingScreen(),
    );
  }
}
