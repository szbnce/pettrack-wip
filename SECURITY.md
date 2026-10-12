# Security Policy

## Supported versions

App, server and WearOS builds ship together and version together (see
`CHANGELOG.md`). Only the latest release receives security fixes — update
both halves; the About card and `/api/version` tell you when they disagree.

| Version | Supported |
|---|---|
| 2.0.x | ✅ |
| < 2.0 | ❌ |

## The security model in one page

PetTrack is self-hosted: video, events and medical data live on your own
machine and nothing is sent to a third party unless you opt in. The design
follows from that — the LAN is the trust boundary, and everything that can
cross it is deliberate.

**Authentication.** Clients sign in once with either the master secret or
the 4-digit pairing PIN and receive a **session**: a short-lived access
token (1 hour) plus a rotating refresh token (90 days). Refresh tokens are
stored hashed; replaying a rotated refresh token burns the whole session
family. Signing out revokes the family server-side — access tokens carrying
that session die with it. Five failed PIN/secret attempts lock the client
out for 5 minutes (persisted, survives restarts).

**Authorization.** Tokens are scoped. The monitor (camera) phone gets a
token that can only upload frames, report status and report sound. Media
tokens reach only the replay files they were minted for. Setting the PIN
requires a full-scope token. WebSocket endpoints enforce the same allowlist.

**Share links.** Sharing a clip as a link mints a media token scoped to
that one file and valid for 7 days, so the link opens in a browser without
a session. It grants nothing else — no feed, no settings, no other clip —
and it dies with the file. Treat such a link like the clip itself: it is
for people you trust on your network.

**Transport.** Plain HTTP is acceptable only on a trusted LAN. For anything
wider, terminate TLS in front (the bundled Caddy setup) or use the native
TLS options (`PETTRACK_TLS_CERT` / `PETTRACK_TLS_KEY`), and reach the
server over a VPN such as Tailscale rather than port-forwarding :9500.

**Data at rest.** SQLite + clip files on your disk, file mode your OS
enforces. The master secret lives in `.env` next to the server; the Fernet
key for stored credentials likewise. Back them up like credentials.

**Updates.** The app updates itself from your own server and nowhere else:
you stage `PetTrack.apk` + `update.json` in the server's updates/ directory,
the app downloads the file over your LAN with valid credentials (the
download endpoint rejects anonymous callers), and Android's own installer
asks for confirmation before replacing anything. There is no third-party
update service in the path — which also means staging an APK is an
operator-privileged action: anyone who can write that directory can ship
code to every install.

**Opt-in egress.** Two features send data off the box, both off by default:
the Home Assistant MQTT bridge (to *your* broker) and remote alerts via ntfy
(text-only event titles — never video or snapshots). Quiet hours apply.

**What this is not.** PetTrack is not multi-tenant, has no per-user accounts
inside a household, and does not defend against an attacker who owns the
server host. Treat a compromise of the server as a compromise of the
footage.

## Reporting a vulnerability

Please use GitHub's private reporting ("Security → Report a
vulnerability" on this repository) rather than a public issue. Include the
version (`/api/version` and the About card), what you expected, and what
happened. You will get an acknowledgement; fixes for real issues ship in a
patched release and land in `CHANGELOG.md`.
