import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:modern_calculator/models/history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  const AppPreferences({
    required this.themeMode,
    required this.scientificMode,
    required this.useDegrees,
    required this.history,
    required this.expression,
    required this.previewResult,
  });

  final ThemeMode themeMode;
  final bool scientificMode;
  final bool useDegrees;
  final List<HistoryEntry> history;
  final String expression;
  final String previewResult;
}

class StorageService {
  static const _themeModeKey = 'themeMode';
  static const _scientificModeKey = 'scientificMode';
  static const _useDegreesKey = 'useDegrees';
  static const _historyKey = 'history';
  static const _expressionKey = 'expression';
  static const _previewResultKey = 'previewResult';

  Future<AppPreferences> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeModeKey) ?? 'dark';
    final historyValues = prefs.getStringList(_historyKey) ?? const <String>[];
    final history = <HistoryEntry>[];

    for (final encoded in historyValues) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is Map) {
          history.add(HistoryEntry.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {
        continue;
      }
    }

    return AppPreferences(
      themeMode: themeName == 'light' ? ThemeMode.light : ThemeMode.dark,
      scientificMode: prefs.getBool(_scientificModeKey) ?? false,
      useDegrees: prefs.getBool(_useDegreesKey) ?? true,
      history: history,
      expression: prefs.getString(_expressionKey) ?? '',
      previewResult: prefs.getString(_previewResultKey) ?? '0',
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> saveScientificMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scientificModeKey, value);
  }

  Future<void> saveAngleMode(bool useDegrees) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDegreesKey, useDegrees);
  }

  Future<void> saveHistory(List<HistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = history.map((entry) => jsonEncode(entry.toJson())).toList();
    await prefs.setStringList(_historyKey, encoded);
  }

  Future<void> saveSession({
    required String expression,
    required String previewResult,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_expressionKey, expression);
    await prefs.setString(_previewResultKey, previewResult);
  }
}
