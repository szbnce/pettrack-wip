# Changelog

All notable changes to PetTrack are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
uses [semantic versioning](https://semver.org/). App, server and WearOS
builds version together — Settings → About, the update check and
`/api/version` always refer to the same release.

## [Unreleased]

### Added

- "I'm home" alert snooze: one tap on the feed's Snooze chip silences this
  phone's alerts for 30 minutes, an hour or until 23:00 — recording keeps
  running, arming still decides what gets watched
- Feed export: the activity feed — filtered as you see it — leaves the app
  as a spreadsheet-ready CSV through the share sheet
- "Free up space now" on the System health card: the retention sweep runs
  on demand instead of waiting for the background timer, and says exactly
  what it freed
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
