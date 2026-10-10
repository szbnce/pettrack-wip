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

/// The payload the monitor phone's scanner expects: `{"ip","secret"}` with
/// `ip` as host:port and no scheme, matching what the server prints as its
/// QR. Built from an app-side server URL (`http://192.168.1.10:9500`) by
/// dropping the scheme and any trailing slash.
String pairingQrPayload(String serverUrl, String secret) {
  var host = serverUrl.trim();
  final scheme = host.indexOf('://');
  if (scheme >= 0) host = host.substring(scheme + 3);
  while (host.endsWith('/')) {
    host = host.substring(0, host.length - 1);
  }
  return jsonEncode({'ip': host, 'secret': secret});
}
