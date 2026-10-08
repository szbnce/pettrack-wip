import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class Medication {
  final String id;
  final String name;
  final String dose;
  final int intervalHours;
  final bool alertEnabled;
  final int colorValue;

  Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.intervalHours,
    this.alertEnabled = false,
    this.colorValue = 0xFF4DB6AC, // Default teal
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dose': dose,
    'intervalHours': intervalHours,
    'alertEnabled': alertEnabled,
    'colorValue': colorValue,
  };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'],
    name: json['name'],
    dose: json['dose'],
    intervalHours: json['intervalHours'] ?? 24,
    alertEnabled: json['alertEnabled'] ?? false,
    colorValue: json['colorValue'] ?? 0xFF4DB6AC,
  );
}

class Vaccine {
  final String id;
  final String name;
  final String dateGiven;
  final String nextDue;
  final int colorValue;

  Vaccine({
    required this.id,
    required this.name,
    required this.dateGiven,
    required this.nextDue,
    this.colorValue = 0xFF4DB6AC, // Default teal
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dateGiven': dateGiven,
    'nextDue': nextDue,
    'colorValue': colorValue,
  };

  factory Vaccine.fromJson(Map<String, dynamic> json) => Vaccine(
    id: json['id'],
    name: json['name'],
    dateGiven: json['dateGiven'],
    nextDue: json['nextDue'],
    colorValue: json['colorValue'] ?? 0xFF4DB6AC,
  );
}

/// A load result that remembers where the items came from.
///
/// Screens use [fromCache] to say "the server is unreachable — this is your
/// saved copy" instead of quietly pretending the fetch worked.
class MedicalLoadResult<T> {
  final List<T> items;
  final bool fromCache;

  const MedicalLoadResult(this.items, {this.fromCache = false});
}

class MedicalDataManager {
  static const String _medKey = 'saved_medications';
  static const String _vacKey = 'saved_vaccines';

  static Future<MedicalLoadResult<Medication>> loadMedications(
    String serverIp,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await http.get(
        Uri.parse('$serverIp/api/medical'),
        headers: AuthService.headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['medications'] != null) {
          final List<dynamic> list = data['medications'];
          final meds = list.map((e) => Medication.fromJson(e)).toList();

          await prefs.setString(
            _medKey,
            jsonEncode(meds.map((e) => e.toJson()).toList()),
          );
          return MedicalLoadResult(meds);
        }
      }
    } catch (e) {
      debugPrint('medical: falling back to the cached copy: $e');
    }

    final jsonStr = prefs.getString(_medKey);
    if (jsonStr == null) return const MedicalLoadResult([], fromCache: true);
    final List<dynamic> list = jsonDecode(jsonStr);
    return MedicalLoadResult(
      list.map((e) => Medication.fromJson(e)).toList(),
      fromCache: true,
    );
  }

  static Future<void> saveMedications(
    List<Medication> meds,
    String serverIp,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(meds.map((e) => e.toJson()).toList());
    await prefs.setString(_medKey, jsonStr);
    await _syncToServer(serverIp);
  }

  static Future<MedicalLoadResult<Vaccine>> loadVaccines(
    String serverIp,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await http.get(
        Uri.parse('$serverIp/api/medical'),
        headers: AuthService.headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['vaccines'] != null) {
          final List<dynamic> list = data['vaccines'];
          final vacs = list.map((e) => Vaccine.fromJson(e)).toList();
          await prefs.setString(
            _vacKey,
            jsonEncode(vacs.map((e) => e.toJson()).toList()),
          );
          return MedicalLoadResult(vacs);
        }
      }
    } catch (e) {
      debugPrint('medical: falling back to the cached copy: $e');
    }

    final jsonStr = prefs.getString(_vacKey);
    if (jsonStr == null) return const MedicalLoadResult([], fromCache: true);
    final List<dynamic> list = jsonDecode(jsonStr);
    return MedicalLoadResult(
      list.map((e) => Vaccine.fromJson(e)).toList(),
      fromCache: true,
    );
  }

  static Future<void> saveVaccines(List<Vaccine> vacs, String serverIp) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(vacs.map((e) => e.toJson()).toList());
    await prefs.setString(_vacKey, jsonStr);
    await _syncToServer(serverIp);
  }

  static Future<void> _syncToServer(String serverIp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medStr = prefs.getString(_medKey) ?? '[]';
      final vacStr = prefs.getString(_vacKey) ?? '[]';

      await http.post(
        Uri.parse('$serverIp/api/medical'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-token': AuthService.token,
        },
        body: jsonEncode({
          'medications': jsonDecode(medStr),
          'vaccines': jsonDecode(vacStr),
        }),
      );
    } catch (e) {
      debugPrint('medical: sync to server failed: $e');
    }
  }
}
