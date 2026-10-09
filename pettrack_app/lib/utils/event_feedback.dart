/// Teaching notes for the classifier: "was this actually my pet?"
///
/// One long-press on a feed row posts one note. Nothing retrains from
/// these yet — collecting them with their moment is the job.
library;

const feedbackKindNotMyPet = 'not_my_pet';
const feedbackKindIsMyPet = 'is_my_pet';

bool isFeedbackKind(String? kind) =>
    kind == feedbackKindNotMyPet || kind == feedbackKindIsMyPet;

/// JSON body for `POST /api/feedback`.
///
/// Empty context fields are left out rather than sent as blanks, so the
/// server's row only holds what the viewer actually said.
Map<String, dynamic> feedbackPayload({
  required num timestampSeconds,
  required String kind,
  String? eventType,
  String? zoneName,
  String? filename,
}) {
  return {
    'timestamp': timestampSeconds,
    'kind': kind,
    if (eventType != null && eventType.isNotEmpty) 'event_type': eventType,
    if (zoneName != null && zoneName.isNotEmpty) 'zone_name': zoneName,
    if (filename != null && filename.isNotEmpty) 'filename': filename,
  };
}
