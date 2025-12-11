// lib/models/linked_site_model.dart
import 'package:characters/characters.dart';

class LinkedSiteModel {
  final String displayName;
  final String logoUrl;       // may be "", then we'll show initials avatar
  final String username;      // site username / account id
  final String ctWebBase64;   // fallback CT_Web (unencrypted if placeholder)
  final String siteSaltHex;   // optional for future hash tweaks
  final String serverUrl;     // backend base url
  final String deviceId;      // id used during pairing

  // 🔹 NEW — required for secure storage and multi-site
  final String userId;
  final String siteId;

  LinkedSiteModel({
    required this.displayName,
    required this.logoUrl,
    required this.username,
    required this.ctWebBase64,
    required this.siteSaltHex,
    required this.serverUrl,
    required this.deviceId,
    required this.userId,
    required this.siteId,
  });

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'logoUrl': logoUrl,
        'username': username,
        'ctWebBase64': ctWebBase64,
        'siteSaltHex': siteSaltHex,
        'serverUrl': serverUrl,
        'deviceId': deviceId,
        'userId': userId,   // NEW
        'siteId': siteId,   // NEW
      };

  static LinkedSiteModel fromJson(Map<String, dynamic> json) => LinkedSiteModel(
        displayName: json['displayName'] as String,
        logoUrl: json['logoUrl'] as String? ?? '',
        username: json['username'] as String? ?? '',
        ctWebBase64: json['ctWebBase64'] as String,
        siteSaltHex: json['siteSaltHex'] as String? ?? '',
        serverUrl: json['serverUrl'] as String,
        deviceId: json['deviceId'] as String,

        // 🔹 Read new fields — fallback safe
        userId: json['userId'] as String? ?? '',
        siteId: json['siteId'] as String? ?? 'default',
      );

  /// For fallback avatar (initials icon)
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.isEmpty
          ? '?'
          : parts.first.characters.take(2).toString().toUpperCase();
    }
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts[1].isNotEmpty ? parts[1][0] : '';
    final res = (first + second).trim();
    return res.isEmpty ? '?' : res.toUpperCase();
  }
}
