import 'package:flutter/material.dart';

import 'screens/viewer_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LottieViewerApp());
}

class LottieViewerApp extends StatelessWidget {
  const LottieViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lottie Viewer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const ViewerScreen(),
    );
  }
}
