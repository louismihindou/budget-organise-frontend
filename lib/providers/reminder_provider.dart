// lib/providers/reminder_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderProvider with ChangeNotifier {
  bool _remindersEnabled = true;

  ReminderProvider() {
    _loadPreference();
  }

  bool get remindersEnabled => _remindersEnabled;

  void toggleReminders(bool enabled) {
    _remindersEnabled = enabled;
    _savePreference(enabled);
    notifyListeners();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _remindersEnabled = prefs.getBool('remindersEnabled') ?? true;
    notifyListeners();
  }

  Future<void> _savePreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remindersEnabled', enabled);
  }
}
