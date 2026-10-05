import 'package:nsd/nsd.dart';

/// A PetTrack server found on the local network via mDNS.
class DiscoveredServer {
  const DiscoveredServer({
    required this.name,
    required this.host,
    required this.port,
  });

  final String name;
  final String host;
  final int port;

  /// `host:port`, ready for [normalizeServerUrl].
  String get address => '$host:$port';
}

/// Browses for `_pettrack._tcp` services advertised by PetTrack servers.
///
/// Supported on Android / iOS / macOS / Windows; on platforms without NSD
/// (web, Linux desktop) [start] throws and callers should fall back to
/// manual address entry.
class ServerDiscovery {
  static const String serviceType = '_pettrack._tcp';

  Discovery? _discovery;
  final List<DiscoveredServer> servers = [];
  final void Function()? onChanged;

  ServerDiscovery({this.onChanged});

  Future<void> start() async {
    _discovery = await startDiscovery(serviceType, autoResolve: true);
    _discovery!.addListener(_sync);
    _sync();
  }

  void _sync() {
    final d = _discovery;
    if (d == null) return;
    servers
      ..clear()
      ..addAll(
        d.services
            .where((s) => s.host != null && s.port != null)
            .map(
              (s) => DiscoveredServer(
                name: (s.name != null && s.name!.isNotEmpty) ? s.name! : s.host!,
                host: _cleanHost(s.host!),
                port: s.port!,
              ),
            ),
      );
    onChanged?.call();
  }

  Future<void> stop() async {
    final d = _discovery;
    _discovery = null;
    if (d != null) {
      await stopDiscovery(d);
    }
  }
}

String _cleanHost(String host) =>
    host.endsWith('.') ? host.substring(0, host.length - 1) : host;
