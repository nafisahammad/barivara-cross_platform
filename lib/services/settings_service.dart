import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LayoutDensity { comfortable, compact }

class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;
  final String notes;

  const EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
    required this.notes,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> data) {
    return EmergencyContact(
      name: (data['name'] ?? '') as String,
      relationship: (data['relationship'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      notes: (data['notes'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'notes': notes,
    };
  }
}

class AppSettings {
  final ThemeMode themeMode;
  final double textScale;
  final LayoutDensity density;
  final bool notifyTickets;
  final bool notifyPayments;
  final bool notifyAnnouncements;
  final bool channelPush;
  final bool channelEmail;
  final bool channelSms;
  final String language;
  final String currency;
  final String timeFormat;
  final List<EmergencyContact> emergencyContacts;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.textScale = 1.0,
    this.density = LayoutDensity.comfortable,
    this.notifyTickets = true,
    this.notifyPayments = true,
    this.notifyAnnouncements = true,
    this.channelPush = true,
    this.channelEmail = false,
    this.channelSms = false,
    this.language = 'English',
    this.currency = 'BDT',
    this.timeFormat = '12h',
    this.emergencyContacts = const [],
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? textScale,
    LayoutDensity? density,
    bool? notifyTickets,
    bool? notifyPayments,
    bool? notifyAnnouncements,
    bool? channelPush,
    bool? channelEmail,
    bool? channelSms,
    String? language,
    String? currency,
    String? timeFormat,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      density: density ?? this.density,
      notifyTickets: notifyTickets ?? this.notifyTickets,
      notifyPayments: notifyPayments ?? this.notifyPayments,
      notifyAnnouncements: notifyAnnouncements ?? this.notifyAnnouncements,
      channelPush: channelPush ?? this.channelPush,
      channelEmail: channelEmail ?? this.channelEmail,
      channelSms: channelSms ?? this.channelSms,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      timeFormat: timeFormat ?? this.timeFormat,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }

  VisualDensity get visualDensity {
    switch (density) {
      case LayoutDensity.compact:
        return const VisualDensity(horizontal: -1, vertical: -1);
      case LayoutDensity.comfortable:
        return VisualDensity.standard;
    }
  }

  factory AppSettings.fromPrefs(SharedPreferences prefs) {
    final themeRaw = prefs.getString('settings.themeMode');
    final densityRaw = prefs.getString('settings.density');
    final contactsRaw = prefs.getString('settings.emergencyContacts');

    return AppSettings(
      themeMode: _parseThemeMode(themeRaw),
      textScale: prefs.getDouble('settings.textScale') ?? 1.0,
      density: _parseDensity(densityRaw),
      notifyTickets: prefs.getBool('settings.notifyTickets') ?? true,
      notifyPayments: prefs.getBool('settings.notifyPayments') ?? true,
      notifyAnnouncements: prefs.getBool('settings.notifyAnnouncements') ?? true,
      channelPush: prefs.getBool('settings.channelPush') ?? true,
      channelEmail: prefs.getBool('settings.channelEmail') ?? false,
      channelSms: prefs.getBool('settings.channelSms') ?? false,
      language: prefs.getString('settings.language') ?? 'English',
      currency: prefs.getString('settings.currency') ?? 'BDT',
      timeFormat: prefs.getString('settings.timeFormat') ?? '12h',
      emergencyContacts: _parseContacts(contactsRaw),
    );
  }

  static ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static LayoutDensity _parseDensity(String? value) {
    switch (value) {
      case 'compact':
        return LayoutDensity.compact;
      case 'comfortable':
      default:
        return LayoutDensity.comfortable;
    }
  }

  static List<EmergencyContact> _parseContacts(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final contacts = <EmergencyContact>[];
      for (final item in decoded) {
        if (item is Map) {
          final map = <String, dynamic>{};
          for (final entry in item.entries) {
            map[entry.key.toString()] = entry.value;
          }
          contacts.add(EmergencyContact.fromMap(map));
        }
      }
      return contacts;
    } catch (_) {
      return const [];
    }
  }
}

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  late SharedPreferences _prefs;
  final ValueNotifier<AppSettings> notifier =
      ValueNotifier<AppSettings>(const AppSettings());

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    notifier.value = AppSettings.fromPrefs(_prefs);
  }

  AppSettings get settings => notifier.value;

  Future<void> update(AppSettings settings) async {
    notifier.value = settings;
    await _save(settings);
  }

  Future<void> _save(AppSettings settings) async {
    await _prefs.setString('settings.themeMode', settings.themeMode.name);
    await _prefs.setDouble('settings.textScale', settings.textScale);
    await _prefs.setString(
      'settings.density',
      settings.density == LayoutDensity.compact ? 'compact' : 'comfortable',
    );
    await _prefs.setBool('settings.notifyTickets', settings.notifyTickets);
    await _prefs.setBool('settings.notifyPayments', settings.notifyPayments);
    await _prefs.setBool(
      'settings.notifyAnnouncements',
      settings.notifyAnnouncements,
    );
    await _prefs.setBool('settings.channelPush', settings.channelPush);
    await _prefs.setBool('settings.channelEmail', settings.channelEmail);
    await _prefs.setBool('settings.channelSms', settings.channelSms);
    await _prefs.setString('settings.language', settings.language);
    await _prefs.setString('settings.currency', settings.currency);
    await _prefs.setString('settings.timeFormat', settings.timeFormat);
    await _prefs.setString(
      'settings.emergencyContacts',
      jsonEncode(
        settings.emergencyContacts.map((contact) => contact.toMap()).toList(),
      ),
    );
  }
}
