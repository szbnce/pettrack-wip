/// Normalizes user-entered server addresses and QR payloads to a full base URL.
///
/// Accepts what people actually type or scan — `192.168.1.10`,
/// `192.168.1.10:8000`, `http://192.168.1.10:8000`, `localhost`,
/// `https://pet.example.com` — and returns a URL the API calls can use
/// directly. Local IPs and localhost get the default port 8000 unless a
/// port is given or the scheme is https.
String normalizeServerUrl(String input) {
  var target = input.trim();
  if (target.isEmpty) return target;
  if (!target.startsWith('http://') && !target.startsWith('https://')) {
    target = 'http://$target';
  }

  final uri = Uri.tryParse(target);
  if (uri == null) return target;
  if (uri.hasPort) return target;

  final host = uri.host;
  final isIpOrLocal =
      RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$').hasMatch(host) ||
      host == 'localhost';
  if (isIpOrLocal && uri.scheme != 'https') {
    return '${uri.scheme}://$host:8000${uri.path}';
  }
  return target;
}
