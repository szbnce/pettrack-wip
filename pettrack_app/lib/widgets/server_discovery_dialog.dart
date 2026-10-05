import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/services/server_discovery.dart';

/// "Find my server" — scans the local network for PetTrack servers and fills
/// in the address field when the user taps one. Returns `null` on cancel.
class ServerDiscoveryButton extends StatelessWidget {
  const ServerDiscoveryButton({super.key, required this.onSelected});

  final void Function(String address) onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      icon: const Icon(Icons.wifi_find),
      label: Text(l10n.discoveryBtn),
      onPressed: () async {
        final address = await showServerDiscoveryDialog(context);
        if (address != null) {
          onSelected(address);
        }
      },
    );
  }
}

/// Opens the discovery dialog; pops with `host:port` of the chosen server.
Future<String?> showServerDiscoveryDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _DiscoveryDialog(),
  );
}

class _DiscoveryDialog extends StatefulWidget {
  const _DiscoveryDialog();

  @override
  State<_DiscoveryDialog> createState() => _DiscoveryDialogState();
}

class _DiscoveryDialogState extends State<_DiscoveryDialog> {
  ServerDiscovery? _discovery;
  Timer? _emptyTimer;
  bool _unsupported = false;
  bool _searchTimedOut = false;

  @override
  void initState() {
    super.initState();
    _startScan();
    // After a while, stop pretending to search forever.
    _emptyTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && (_discovery?.servers.isEmpty ?? true)) {
        setState(() => _searchTimedOut = true);
      }
    });
  }

  Future<void> _startScan() async {
    final discovery = ServerDiscovery(onChanged: () {
      if (mounted) setState(() {});
    });
    try {
      // A hung NSD lookup must not trap the user in a spinner — if the
      // browse does not even start, fall back to manual entry.
      await discovery.start().timeout(const Duration(seconds: 3));
      if (!mounted) {
        await discovery.stop();
        return;
      }
      setState(() => _discovery = discovery);
    } catch (_) {
      // Platform without NSD (web, Linux desktop): fall back to manual entry.
      await discovery.stop();
      if (mounted) setState(() => _unsupported = true);
    }
  }

  @override
  void dispose() {
    _emptyTimer?.cancel();
    _discovery?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final servers = _discovery?.servers ?? const <DiscoveredServer>[];

    return AlertDialog(
      title: Text(l10n.discoveryTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: _unsupported
            ? Text(l10n.discoveryNotSupported)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (servers.isEmpty) ...[
                    if (!_searchTimedOut) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      Text(l10n.discoverySearching),
                    ] else
                      Text(l10n.discoveryEmpty),
                    const SizedBox(height: 8),
                    Text(
                      l10n.discoveryHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: servers.length,
                        itemBuilder: (ctx, i) {
                          final s = servers[i];
                          return ListTile(
                            leading: const Icon(Icons.dns),
                            title: Text(s.name),
                            subtitle: Text(
                              '${s.address}\n${l10n.discoveryTapToUse}',
                            ),
                            isThreeLine: true,
                            onTap: () => Navigator.of(ctx).pop(s.address),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.settingsQrDialogDone),
        ),
      ],
    );
  }
}
