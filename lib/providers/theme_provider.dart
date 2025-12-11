import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyPrimaryColor = 'primary_color';
  static const String _keyLanguage = 'language';
  static const String _keyNotifications = 'notifications';

  bool _isDarkMode = true;
  Color _primaryColor = const Color(0xFF6366F1);
  String _language = 'Español';
  bool _notificationsEnabled = true;

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;
  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;

  // Color options for labels
  static const List<Color> colorOptions = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
  ];

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_keyDarkMode) ?? true;
      _language = prefs.getString(_keyLanguage) ?? 'Español';
      _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
      
      final colorIndex = prefs.getInt(_keyPrimaryColor) ?? 0;
      _primaryColor = colorOptions[colorIndex.clamp(0, colorOptions.length - 1)];
      
      notifyListeners();
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> setDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = value;
      await prefs.setBool(_keyDarkMode, value);
      notifyListeners();
    } catch (e) {
      print('Error saving dark mode: $e');
    }
  }

  Future<void> setPrimaryColor(Color color) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _primaryColor = color;
      final colorIndex = colorOptions.indexOf(color);
      await prefs.setInt(_keyPrimaryColor, colorIndex >= 0 ? colorIndex : 0);
      notifyListeners();
    } catch (e) {
      print('Error saving primary color: $e');
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _language = language;
      await prefs.setString(_keyLanguage, language);
      notifyListeners();
    } catch (e) {
      print('Error saving language: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = value;
      await prefs.setBool(_keyNotifications, value);
      notifyListeners();
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  // Get theme data based on current settings
  ThemeData getThemeData() {
    final isDark = _isDarkMode;
    
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: isDark ? const Color(0xFF1A1D29) : const Color(0xFFF8FAFC),
        background: isDark ? const Color(0xFF1A1D29) : const Color(0xFFF8FAFC),
        onSurface: isDark ? Colors.white : const Color(0xFF1A1F36),
        onBackground: isDark ? Colors.white : const Color(0xFF1A1F36),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        primary: _primaryColor,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF252836) : const Color(0xFFE2E8F0),
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1F36),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1A1F36),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? const Color(0xFF2D3142) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        color: isDark ? const Color(0xFF252836) : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1F2332) : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2D3142) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2D3142) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF475569),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF1F2332) : const Color(0xFFF1F5F9),
        selectedColor: _primaryColor,
        disabledColor: isDark ? const Color(0xFF2D3142) : const Color(0xFFE2E8F0),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF475569),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
