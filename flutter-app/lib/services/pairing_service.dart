// lib/services/pairing_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/linked_site_model.dart';
import 'ctweb_secure_store.dart';

final _uuid = const Uuid();

Future<LinkedSiteModel> pairFromQr(String qrText) async {
  // 1) Parse QR JSON from website
  final Map<String, dynamic> qrPayload = jsonDecode(qrText);

  final String serverUrl = qrPayload['s'] as String;           // server_url
  final String qrUserId = qrPayload['u'] as String;            // user_id
  final String pairToken = qrPayload['t'] as String;           // pair_token
  final String siteId = (qrPayload['i'] as String?) ?? 'nextgen_demo';

  // 2) Generate deviceId (random uuid)
  final String deviceId = _uuid.v4();

  // 3) Placeholder public key; Node falls back to plain ctWeb for now
  const String devicePublicKey = 'MOBILE_PUBLIC_KEY_PLACEHOLDER';

  // 4) POST /api/pairing/confirm
  final confirmRes = await http.post(
    Uri.parse('$serverUrl/api/pairing/confirm'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'pairToken': pairToken,
      'deviceId': deviceId,
      'devicePublicKey': devicePublicKey,
    }),
  );

  if (confirmRes.statusCode != 200) {
    throw Exception('Pairing failed: ${confirmRes.body}');
  }

  final confirmData = jsonDecode(confirmRes.body);
  if (confirmData['success'] != true) {
    throw Exception('Pairing failed: ${confirmData['error'] ?? 'Unknown error'}');
  }

  // From backend: see pairing.js → confirm route
  final String ctWebBase64 = confirmData['encrypted_ct_web'] as String;
  final String siteSaltHex = (confirmData['site_salt'] as String?) ?? '';
  final String displayName =
      (confirmData['display_name'] as String?) ?? 'Unknown Site';
  final String logoUrl = (confirmData['logo_url'] as String?) ?? '';
  final String returnedUserId =
      (confirmData['user_id'] as String?) ?? qrUserId;
  final String returnedSiteId =
      (confirmData['site_id'] as String?) ?? siteId;
  final String username =
      (confirmData['username'] as String?) ?? 'user_$returnedUserId';

  // 5) Store CT_Web securely in keystore-backed storage
  await CtWebSecureStore.saveCtWeb(
    userId: returnedUserId,
    siteId: returnedSiteId,
    ctWebBase64: ctWebBase64,
  );

  // 6) POST /api/pairing/complete (tell server pairing is done)
  final completeRes = await http.post(
    Uri.parse('$serverUrl/api/pairing/complete'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'userId': returnedUserId,
      'deviceId': deviceId,
    }),
  );

  if (completeRes.statusCode != 200) {
    throw Exception('Pairing complete failed: ${completeRes.body}');
  }

  final completeData = jsonDecode(completeRes.body);
  if (completeData['success'] != true) {
    throw Exception('Pairing complete failed: ${completeData['error'] ?? 'Unknown error'}');
  }

  // 7) Build model for local storage and dashboard
  return LinkedSiteModel(
    displayName: displayName,
    logoUrl: logoUrl,
    username: username,
    ctWebBase64: ctWebBase64,
    siteSaltHex: siteSaltHex,
    serverUrl: serverUrl,
    deviceId: deviceId,

    // if your model has these fields, include them:
    userId: returnedUserId,
    siteId: returnedSiteId,
  );
}
