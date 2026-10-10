# Changelog

All notable changes to PetTrack are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
uses [semantic versioning](https://semver.org/). App, server and WearOS
builds version together — Settings → About, the update check and
`/api/version` always refer to the same release.

## [Unreleased]

### Added

- A failed push is not a lost alert: if ntfy is unreachable the alert waits
  and goes out when the topic comes back — an hour at most, because a stale
  "your dog barked" is worse than silence. Quiet hours still mute the pet,
  but a dead camera or a full disk punches through at high priority
- The container says what is wrong instead of tracebacking: on the first
  `docker compose up` a missing bind-mount source becomes a *directory*,
  which used to crash the boot in a loop and mint a new master secret every
  time. The entrypoint now checks every mount and points at the folder to
  move aside; settings fall back to `.env/pettrack.env` on the same mount
  and survive a rebuild
- A shareable week card: Insights' share button now shows the post before
  it leaves — the pet's name, the headline number, the week's shape as a
  bar chart, and where the time went — as an image you can post anywhere,
  or as the plain text it used to be
- Delete a clip now: the false alarm, the knocked-over camera — one tap in
  the player, a confirmation, and the recording is gone for good. The pin
  goes with it, and only a full session can do it (a monitor phone is a
  camera, not a cleaner)
- Plain-language settings: the notification toggles speak the way a pet
  owner would say them ("Tell me when Berci enters or leaves a zone") and
  the wiring — server address, pairing secret, account — sits in a
  collapsed "Advanced" drawer, so everyday settings stay the whole story
- "I'm home" alert snooze: one tap on the feed's Snooze chip silences this
  phone's alerts for 30 minutes, an hour or until 23:00 — recording keeps
  running, arming still decides what gets watched
- Feed export: the activity feed — filtered as you see it — leaves the app
  as a spreadsheet-ready CSV through the share sheet
- "Free up space now" on the System health card: the retention sweep runs
  on demand instead of waiting for the background timer, and says exactly
  what it freed
- "Last night" recap: the first time you open the app in the morning it
  says how many events happened overnight — once a day, then out of the
  way
- Share a replay as a link: a week-long URL scoped to that one clip opens
  in any browser on the network — no app, no login (SECURITY.md covers
  the model)
- Replay day density strip: pick a day and see the whole day hour by
  hour — where the motion actually was — and tap an hour to filter the
  clips to it
- The monitor phone protects its own battery: below 20% it streams at
  half speed, below 10% at quarter speed, and says so on the frame —
  charging always keeps full pace
- Teach PetTrack from the feed: long-press any event to say "not my pet"
  or "that's my pet". The note is stored with its moment and context for
  the classifier's training pass — nothing retrains from them yet
- Pin a replay: one tap in the player keeps that clip forever. Retention
  and disk pressure both look the other way; the pin list lives next to
  the footage in `.pinned.json`, so it moves with the folder
- "All quiet for…" on the feed: once the house has been still for half an
  hour the feed says so, instead of just stopping
- One-tap in-app update on Android: the server stages a new APK
  (`updates/PetTrack.apk` + `update.json`), Settings → About offers it,
  and one tap downloads it and opens the system installer — self-hosted,
  nothing leaves the LAN
- Arming schedule: watch only when you're away — auto-arm and auto-disarm by
  weekday and time, always visible on the camera chip
- One-file settings backup and restore — the whole setup, pairing included,
  moves to a new phone in a single file
- First-run safety net: "Skip for now" when no monitor is wired up yet, and
  a lost session recovers with the pairing secret instead of exiling you to
  the wizard

### Fixed

- The server no longer dies on a settings file it cannot write. A directory
  called `.env` — the classic Docker bind-mount accident — used to raise
  `IsADirectoryError` on every boot *and* in the fallback that reopened the
  same directory, crash-looping uvicorn and rotating the master secret each
  time (every session, PIN and encrypted record with it). Every writer now
  goes through one safe path that takes no for an answer and keeps the
  running server working even on a read-only box
- Backwards compatibility is a promise now (docs/COMPATIBILITY.md): the
  2.1.0+3 APK upgrades older installs in place keeping login and settings,
  new servers keep answering the old clients' token shapes, and an old
  server simply lacks the new knobs instead of breaking the app
- Live stream latency stays structural, not lucky: frames fan out per client
  (one slow phone no longer delays the others) and skip to the newest frame
  instead of replaying a stale backlog; vision analysis rides beside the
  stream and classifier inference runs in a thread
- Cold start has no wasted motion: parallel platform init and no fixed
  splash delay in the boot route — targets and how to measure them live in
  `docs/PERFORMANCE.md`
- Every data screen loads honestly: skeletons while content is in flight
  instead of a false "nothing here" flash — the dashboard feed and the
  Settings health card were the last offenders
- Every socket comes back on its own — streams retry with backoff and the
  screens say so while they do
- Light theme speaks up: white-on-light ghost text replaced by theme ink on
  the dashboard, Zones, the Replays day strip and the desktop headers
- The status badge no longer cries wolf: while the first frame is still in
  traffic it says "Searching...", not "OFFLINE!"; demo mode wears its Live
  face instead of red
- The Zones screen is alive in demo mode: the bundled frame and the demo
  zones instead of a spinner and skeletons that never settle
- Demo mode tells the truth everywhere: Medical carries a sample medication
  and vaccine instead of crying "server unreachable", and Settings knows the
  pet's name instead of showing an empty field
- The status bar clock and icons follow the theme on every screen — white on
  light made them vanish, and the native window now starts with the right ink
  instead of waiting for a frame to correct it
- Settings shows one title, not two
- QR payloads are validated before login, and wrong PIN, stale secret and
  missing fields each get their own honest error
- A refused pet save fails the wizard instead of pretending it saved

### Changed

- Accessibility to WCAG AA: every control speaks, every image says what it
  is, and contrast holds in both themes
- The status badge wears a pale pill with dark ink — readable on any surface
- Release builds sign with the release keystore when `key.properties` is
  present (see docs/RELEASE_CHECKLIST.md); debug keys keep local builds
  working

## [2.0.0] - 2026-10-08

The audience-ready release: a real design language, a real security model,
alerts that leave the house, and the feature set of a product rather than a
tinkerer tool.

### Added

- Material 3 design language: bundled brand fonts, component depth in both
  modes, native splash, refined app icon, skeletons and empty states
- "Today's recap" highlight card and a daily highlight clip; daily timelapse
  of the whole day of pet life
- Activity insights — motion, zone time and rest at a glance
- Replay timeline: a day strip with event dots
- Rich notifications with quiet hours and a test-notification button
- **Remote alerts via ntfy** — zone, sound and watchdog pushes reach you
  outside the LAN (ntfy.sh or self-hosted), in the app's language and with
  the pet's name; opt-in with a one-tap setup check
- Home Assistant integration through MQTT discovery (motion, battery,
  charging, monitor online, last event, camera snapshot)
- Sound events (bark / meow) in the activity feed
- Remote night mode; "play a sound" to call the pet from the viewer
- Multi-camera support: camera picker or grid view
- Home-screen widget with a live snapshot
- System health card and a server watchdog (camera offline, disk pressure)
  with replay auto-pruning and a retention setting
- First-run wizard, mDNS server discovery, QR pairing, a connection-status
  chip that never leaves you guessing, and a demo mode
- Public landing page; one-line server setup script; optional Caddy HTTPS
  for the LAN; in-app update check against the server
- Optional tier-3 pet / not-pet ONNX classifier; tiered vision pipeline
  (thumbnail diff gating) with JPEG frame streaming
- WearOS companion screens and phone → watch credential sync
- Full localization: English, German, Hungarian, Italian, Japanese, Korean
  and Chinese, with CI parity checks
- Vaccine and medication tracking with server sync
- pytest suite for the server API (143 tests) and GitHub Actions CI

### Security

- Short-lived access tokens with rotating refresh sessions; signing out
  revokes the session family and every access token issued with it
- Monitor devices get scoped tokens — frame upload, status and sound only;
  media tokens reach only the replays path
- Persistent PIN/secret lockout: 5 failures → 5 minutes, survives restarts
- Short-lived signed replay URLs — no long-lived tokens in plain API calls
- The master secret is never handed to clients
- Optional native TLS (`PETTRACK_TLS_CERT` / `PETTRACK_TLS_KEY`)

### Changed

- Frames stream as JPEG instead of PNG previews — faster and lighter
- Motion gating by thumbnail difference instead of MOG2
- iOS builds fixed; `manager.sh` is the single build pipeline

## [1.0.0] - 2026-09-06

First public release: live video stream, zone setting and pet tracking,
motion recordings with instant replay and sharing, activity log, vaccine
and medication tracking, instant picture capture, WearOS support, the
static website and a privacy policy.

[Unreleased]: https://github.com/szbnce/pettrack-wip/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/szbnce/pettrack-wip/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/szbnce/pettrack-wip/releases/tag/v1.0.0
