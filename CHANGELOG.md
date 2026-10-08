# Changelog

All notable changes to PetTrack are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
uses [semantic versioning](https://semver.org/). App, server and WearOS
builds version together — Settings → About, the update check and
`/api/version` always refer to the same release.

## [Unreleased]

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
