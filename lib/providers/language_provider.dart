import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported languages in the app
enum AppLanguage {
  english('en', 'English', 'English'),
  tamil('ta', 'Tamil', 'தமிழ்');

  const AppLanguage(this.code, this.name, this.nativeName);
  
  final String code;
  final String name;
  final String nativeName;
}

/// Provider for managing app language preference
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  
  AppLanguage _currentLanguage = AppLanguage.english;
  bool _isInitialized = false;

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isEnglish => _currentLanguage == AppLanguage.english;
  bool get isTamil => _currentLanguage == AppLanguage.tamil;
  bool get isInitialized => _isInitialized;
  String get languageCode => _currentLanguage.code;

  LanguageProvider() {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_languageKey);
      if (savedCode != null) {
        _currentLanguage = AppLanguage.values.firstWhere(
          (lang) => lang.code == savedCode,
          orElse: () => AppLanguage.english,
        );
      }
    } catch (e) {
      debugPrint('Error loading language preference: $e');
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    
    _currentLanguage = language;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.code);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  void toggleLanguage() {
    setLanguage(isEnglish ? AppLanguage.tamil : AppLanguage.english);
  }

  /// Get translated text based on current language
  String translate(String englishText, String tamilText) {
    return isEnglish ? englishText : tamilText;
  }
}
