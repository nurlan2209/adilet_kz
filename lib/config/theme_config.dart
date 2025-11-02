import 'package:flutter/material.dart';

/// Класс с государственными цветами и стилями для приложения Әділет KZ
class AppTheme {
  // Государственные цвета Казахстана
  static const Color primaryBlue = Color(0xFF0066B3);
  static const Color darkBlue = Color(0xFF003D82);
  static const Color lightBlue = Color(0xFFE6F2FF);
  static const Color goldAccent = Color(0xFFFFB81C);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFE0E6ED);

  // Цвета статусов
  static const Color activeGreen = Color(0xFF10B981);
  static const Color activeGreenLight = Color(0xFF059669);
  static const Color inactiveRed = Color(0xFFEF4444);
  static const Color inactiveRedLight = Color(0xFFDC2626);

  /// Основная тема приложения
  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Roboto',

      // AppBar тема
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: darkBlue,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkBlue,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: darkBlue),
      ),

      // Цветовая схема
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: goldAccent,
        surface: Colors.white,
        error: inactiveRed,
      ),

      // Кнопки
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Карточки
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),

      // Поля ввода
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Индикаторы прогресса
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
      ),

      // Иконки
      iconTheme: const IconThemeData(
        color: primaryBlue,
      ),
    );
  }

  /// Виджет для градиентной полосы под AppBar
  static Widget appBarGradient() {
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, goldAccent],
        ),
      ),
    );
  }

  /// Виджет для заголовка секции с боковой полосой
  static Widget sectionHeader(String title, {Color? accentColor}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: accentColor ?? primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: darkBlue,
          ),
        ),
      ],
    );
  }

  /// Бейдж статуса документа
  static Widget statusBadge(String status, {bool isActive = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? activeGreen.withOpacity(0.1)
            : inactiveRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive
              ? activeGreen.withOpacity(0.3)
              : inactiveRed.withOpacity(0.3),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isActive ? activeGreenLight : inactiveRedLight,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  /// Бейдж категории документа
  static Widget categoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: primaryBlue.withOpacity(0.3),
        ),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: primaryBlue,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  /// Иконка с фоном для документов
  static Widget documentIcon(IconData icon, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(size * 0.15),
      ),
      child: Icon(
        icon,
        color: primaryBlue,
        size: size * 0.5,
      ),
    );
  }

  /// Пустое состояние с иконкой
  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              icon,
              size: 40,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Информационный баннер
  static Widget infoBanner({
    required String title,
    required String subtitle,
    IconData icon = Icons.account_balance,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue, darkBlue],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: goldAccent, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}