import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kSettingsKey = 'scamshield_settings';

/// Provides the singleton SettingsService.
final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService());

/// Persistent user settings — mirrors the extension's chrome.storage.local settings.
class AppSettings {
  final String language; // 'lo' | 'en'
  final int sensitivity; // 20–90
  final bool notifications;
  final String backendUrl;

  const AppSettings({
    this.language = 'lo',
    this.sensitivity = 50,
    this.notifications = true,
    this.backendUrl = 'http://172.20.10.11:8000',
  });

  AppSettings copyWith({
    String? language,
    int? sensitivity,
    bool? notifications,
    String? backendUrl,
  }) =>
      AppSettings(
        language: language ?? this.language,
        sensitivity: sensitivity ?? this.sensitivity,
        notifications: notifications ?? this.notifications,
        backendUrl: backendUrl ?? this.backendUrl,
      );

  Map<String, dynamic> toJson() => {
        'language': language,
        'sensitivity': sensitivity,
        'notifications': notifications,
        'backendUrl': backendUrl,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    var url = json['backendUrl'] as String? ?? 'http://172.20.10.11:8000';
    if (url.contains('48096') || url.contains('10.0.2.2') || url.contains('localhost')) {
      url = 'http://172.20.10.11:8000';
    }
    return AppSettings(
      language: json['language'] as String? ?? 'lo',
      sensitivity: json['sensitivity'] as int? ?? 50,
      notifications: json['notifications'] as bool? ?? true,
      backendUrl: url,
    );
  }
}

class SettingsService {
  /// Load settings from SharedPreferences.
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSettingsKey);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  /// Save settings to SharedPreferences.
  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSettingsKey, jsonEncode(settings.toJson()));
  }
}
