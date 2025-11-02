import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:adiletkz/screens/navigation_screen.dart';
import 'package:adiletkz/screens/act_detail_screen.dart';
import 'package:adiletkz/screens/profile/login_screen.dart';
import 'package:adiletkz/screens/profile/register_screen.dart';
import 'package:adiletkz/screens/assistant_page.dart';

class AdiletApp extends StatelessWidget {
  const AdiletApp({super.key});

  // Государственные цвета Казахстана
  static const Color primaryBlue = Color(0xFF0066B3);
  static const Color darkBlue = Color(0xFF003D82);
  static const Color lightBlue = Color(0xFFE6F2FF);
  static const Color goldAccent = Color(0xFFFFB81C);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFE0E6ED);

  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Әділет KZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: backgroundColor,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.light(
          primary: primaryBlue,
          secondary: goldAccent,
          surface: Colors.white,
          error: Color(0xFFEF4444),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: darkBlue,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: darkBlue,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: primaryBlue,
          contentTextStyle: TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => NavigationScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/actDetail': (context) => ActDetailScreen(actTitle: '', actId: ''),
        '/assistant': (context) => const AssistantPage(),
      },
    );
  }
}
