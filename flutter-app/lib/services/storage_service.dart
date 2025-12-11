// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/linked_site_model.dart';

class StorageService {
  static const _keySites = 'linked_sites';

  /// Load all saved sites
  static Future<List<LinkedSiteModel>> loadSites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keySites);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> list = jsonDecode(jsonString);
    return list
        .map((e) => LinkedSiteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Save full list
  static Future<void> _saveSites(List<LinkedSiteModel> sites) async {
    final prefs = await SharedPreferences.getInstance();
    final list = sites.map((e) => e.toJson()).toList();
    await prefs.setString(_keySites, jsonEncode(list));
  }

  /// Add or update a site (by serverUrl+username or displayName)
  static Future<void> addOrUpdateSite(LinkedSiteModel site) async {
    final sites = await loadSites();
    final index = sites.indexWhere((s) =>
        s.serverUrl == site.serverUrl &&
        s.username.toLowerCase() == site.username.toLowerCase());

    if (index >= 0) {
      sites[index] = site;
    } else {
      sites.add(site);
    }

    await _saveSites(sites);
  }

  /// Optional: delete by index
  static Future<void> deleteSite(int index) async {
    final sites = await loadSites();
    if (index < 0 || index >= sites.length) return;
    sites.removeAt(index);
    await _saveSites(sites);
  }
}
