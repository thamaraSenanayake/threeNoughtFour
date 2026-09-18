import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ThreeNoteFourApp());
}

class ThreeNoteFourApp extends StatelessWidget {
  const ThreeNoteFourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '304 Arena - Sri Lankan 304 Card Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: AppTheme.gold,
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.gold,
          secondary: AppTheme.goldDark,
          surface: AppTheme.modalBg,
        ),
        fontFamily: 'sans-serif',
      ),
      home: const HomeScreen(),
    );
  }
}
