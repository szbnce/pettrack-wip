/// Notification copy the way a pet owner would say it: the zone toggle
/// names the pet ("Tell me when Berci enters or leaves a zone") and falls
/// back to a nameless line before the pet has one.
library;

import 'package:pettrack_app/l10n/app_localizations.dart';

/// The zone-alert label for a pet name; empty or blank names get the
/// generic wording instead of a sentence with a hole in it.
String zoneAlertLabel(AppLocalizations l10n, String petName) {
  final name = petName.trim();
  return name.isEmpty ? l10n.alertsZoneGeneric : l10n.alertsZone(name);
}
