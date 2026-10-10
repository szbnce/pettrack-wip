import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pettrack_app/widgets/no_camera_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFF15181E),
      body: SizedBox.expand(child: child),
    ),
  );

  testWidgets('names the next step instead of spinning forever', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const NoCameraCard(
          title: 'No camera connected yet',
          description: 'Open PetTrack Monitor on the old phone.',
          buttonLabel: 'Show pairing code',
          onShowQr: _noop,
        ),
      ),
    );

    expect(find.text('No camera connected yet'), findsOneWidget);
    expect(
      find.text('Open PetTrack Monitor on the old phone.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.videocam_off), findsOneWidget);
    // The card is the answer to "what do I do now" — the spinner must not
    // be what a stranded first-run user sees.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the button opens the pairing code', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        NoCameraCard(
          title: 't',
          description: 'd',
          buttonLabel: 'Show pairing code',
          onShowQr: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Show pairing code'));
    expect(tapped, isTrue);
  });

  testWidgets('a long description does not overflow the card', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        const NoCameraCard(
          title: 'A very long title that keeps going and going and going',
          description:
              'A description long enough to wrap onto several lines in a '
              'narrow phone frame, because a first-run screen is exactly '
              'where a long translation lands.',
          buttonLabel: 'Show pairing code',
          onShowQr: _noop,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
