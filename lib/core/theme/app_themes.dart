import 'package:flutter/material.dart';

class AppThemes {
  // ─── الوضع النهاري (مطابق لتصميمك الحالي تماماً) ───
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F4FF), // لون الخلفية العام
    cardColor: Colors.white, // لون البطاقات
    primaryColor: const Color(0xFF3B9EFF), // اللون الأساسي (الأزرق)
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF0F4FF),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1A2E5A)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1A2E5A),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: Color(0xFF1A2E5A)), // النصوص الأساسية
      bodyMedium: TextStyle(color: Colors.grey.shade600), // النصوص الثانوية
    ),
    dividerColor: const Color(0xFFE2E8F0),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF3B9EFF),
      unselectedItemColor: Colors.grey,
    ),
  );

  // ─── الوضع الليلي (Dark Mode) ───
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212), // خلفية داكنة مريحة للعين
    cardColor: const Color(0xFF1E1E1E), // بطاقات بدرجة أفتح قليلاً
    primaryColor: const Color(0xFF3B9EFF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.grey.shade400),
    ),
    dividerColor: const Color(0xFF2C2C2C),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(0xFF3B9EFF),
      unselectedItemColor: Colors.grey,
    ),
  );
}