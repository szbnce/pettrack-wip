# Compatibility promise

PetTrack is self-hosted and phones get updated one at a time, so mixed
installations are the normal case, not an accident. This page is the
contract: what keeps working when the two halves are not the same version.

## The matrix

| App \ Server | Older server | Same version | Newer server |
|---|---|---|---|
| **Older app** | — | ✅ | ✅ core features; new knobs simply absent |
| **Same version** | ✅ | ✅ | ✅ |
| **Newer app** | ✅ core features; new knobs quietly unavailable | ✅ | — |

"Core features" means live view, feed, replays, snapshots, alerts,
zones and settings that both sides know.

## New app, older server

The app treats a missing endpoint as "this server doesn't do that", never
as a crash:

- One-tap updates: no `/api/app/update` → no update offer (`Check now`
  still compares the two versions).
- ntfy / arming / maintenance knobs: the save is best-effort; the server
  ignores fields it does not know. Check the version line in **Settings →
  About & updates** when something seems not to stick.
- Health and settings cards show their error + retry state instead of a
  broken layout.

## Older app, new server

- The **raw master secret** is still accepted everywhere (QR provisioning,
  scripts, very old builds). It is equivalent to full access — prefer
  scoped logins.
- Login answers carry both `token` and `secret` (the same value) so
  clients that only know one of the two keys keep working.
- Frame upload (`/ws`, `/api/frame/web`), status pokes and monitor PIN
  logins keep their historical shapes.
- **The port moved to 9500.** A saved server address that spells the port
  out (`http://192.168.1.10:8000`) keeps pointing at 8000 — the app never
  rewrites an address a human typed. After moving the server, edit the
  address in **Settings → Advanced** (or re-pair): bare IPs already come
  out as `:9500`. A QR code carries the port, so a fresh scan is always
  right.

## Upgrading a phone in place

- Same application id (`com.szbnce.pettrack_app`): installing the new APK
  over the old one keeps prefs, pairing and login (the session lives in
  the historical `jwt_token` / `server_token` keys — `AuthService` reads
  those).
- **versionCode always increases** (now 3), so the install is treated as
  an upgrade.
- **Signature must match the installed build.** Builds without
  `key.properties` are debug-signed (and interchangeable with older
  debug-signed builds); builds with your release keystore only upgrade
  earlier release-signed installs. If the signatures clash, Android
  refuses the install — uninstall, reinstall, and use **Settings → Backup**
  (restore) to bring the setup back in one file.

## Old monitor phone, new server

Nothing to do: monitors authenticate with the pairing secret or a scoped
monitor token, both of which the server still speaks, and the WebSocket
frame protocol has not changed.
