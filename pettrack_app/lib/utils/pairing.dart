import 'dart:convert';

/// A pairing QR's payload: `{"ip": "...", "secret": "..."}` with both fields
/// non-empty strings. Anything else is not ours — it must never reach a
/// login form, where a wrong-typed field is a crash and a missing one is a
/// mystery.
Map<String, String>? parsePairingPayload(String raw) {
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return null;
  }
  return pairingFields(decoded);
}

/// The same validation for an already-decoded value.
Map<String, String>? pairingFields(Object? data) {
  if (data is! Map) return null;
  final ip = data['ip'];
  final secret = data['secret'];
  if (ip is! String || ip.isEmpty) return null;
  if (secret is! String || secret.isEmpty) return null;
  return {'ip': ip, 'secret': secret};
}
