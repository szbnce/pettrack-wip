/// App identity and version helpers for the update check.
///
/// The settings "About & updates" card compares this against the server's
/// `/api/version` so mixed installs (new app + old server, or the reverse)
/// say so instead of just failing mysteriously.
library;

/// App version, kept in sync with `pubspec.yaml`'s `version:`.
const String kAppVersion = '2.1.0';

/// Compares two dotted versions ("1.2.0") like [Comparable.compareTo]:
/// negative when [a] is older than [b], 0 when equal, positive when newer.
int compareVersions(String a, String b) {
  final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  for (var i = 0; i < 3; i++) {
    final va = i < pa.length ? pa[i] : 0;
    final vb = i < pb.length ? pb[i] : 0;
    if (va != vb) return va.compareTo(vb);
  }
  return 0;
}
