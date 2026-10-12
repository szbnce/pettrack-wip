# Release checklist

Everything needed to ship one PetTrack release — sideloaded APK and Google
Play — in the order it actually happens. App, server and WearOS build
version together (see `CHANGELOG.md`).

## 0. One-time setup (before the first release)

### Android release keystore

Generate once, keep forever — losing it means losing the ability to update
the Play listing:

```bash
keytool -genkey -v -keystore ~/pettrack-release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 -alias pettrack
```

Create `pettrack_app/android/key.properties` (**never commit this file** —
it is the whole signing identity):

```properties
storePassword=<the keystore password>
keyPassword=<the key password>
keyAlias=pettrack
storeFile=/Users/<you>/pettrack-release.keystore
```

`android/app/build.gradle.kts` reads it automatically: with
`key.properties` present, release builds sign with the release key;
without it they fall back to debug keys so local work never blocks.

Back the keystore up somewhere that is not this machine (password manager
note + an offline copy). Play App Signing: let Google hold the *app*
signing key and keep the *upload* key (this keystore) yourself.

### Google Play Console (first time only)

- Create the app listing with applicationId `com.szbnce.pettrack_app`.
- Privacy policy URL: `https://github.com/szbnce/PetTrack/blob/main/PRIVACY_POLICY.md`
- Store listing copy + screenshots: `docs/store/` (see its README).
- Data safety form: no data collected by the developer; everything is
  self-hosted on the user's server. The one optional third party is ntfy
  (remote alerts, off by default) — declare it under "data shared".
- Content rating questionnaire: no violence/advertising; camera usage is
  surveillance of one's own pet. Fill it once.

## 1. Green gate

```bash
cd pettrack_app
~/flutter/bin/flutter analyze          # must be clean
~/flutter/bin/flutter test             # must be all green
cd .. && python3 tools/check_i18n.py   # 7 locales in sync
```

## 2. Version and changelog

1. `pettrack_app/pubspec.yaml`: bump `version: X.Y.Z+(N+1)`.
2. Move `CHANGELOG.md` `[Unreleased]` entries into a new `## [X.Y.Z] - date`.
3. Screenshots in `docs/store/screenshots/` still match the UI (re-shoot if
   a screen visibly changed — see `SHOT_LIST.md`).

## 3. Sideloaded APK (GitHub Releases)

```bash
./manager.sh android        # → PetTrack.apk at the repo root
```

- Smoke-test `PetTrack.apk` on a real phone: fresh install → wizard →
  demo mode → live view.
- With `key.properties` present the APK is release-signed; without it,
  debug-signed (fine for testing, not for Play).

### Stage the one-tap update on your server

Self-hosted installs update themselves from the server. On the host, next
to the running server (or wherever `PETTRACK_UPDATE_DIR` points):

```bash
./manager.sh stage-update
   # copies the APK in and writes the version for you
   # (the version comes from pubspec.yaml — nothing to retype)
```

No restart needed — Settings → About → "Check now" now offers "Install
update" on Android phones, which downloads the APK and opens the system
installer. Remove the two files to withdraw the offer.

## 4. Google Play (AAB)

```bash
cd pettrack_app
~/flutter/bin/flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

1. Upload the `.aab` to the **internal testing** track first; promote to
   production after a real device passes the smoke test.
2. Version notes: paste the `CHANGELOG.md` section (Play short text) and
   the listing copy lives in `docs/store/listing/<locale>/`.

## 5. Tag and GitHub release

```bash
git tag -a vX.Y.Z -m "PetTrack X.Y.Z"
git push origin main vX.Y.Z
```

GitHub release `vX.Y.Z` with the `CHANGELOG.md` section as notes and
`PetTrack.apk` attached, for people installing fresh. (Existing installs
get their one-tap update from the server staging step above, not from
GitHub.)

## 6. After the release

- [ ] Update check in the app finds `vX.Y.Z` (server and app agree).
- [ ] `/api/version` reports the new version on a freshly installed server.
- [ ] The demo site (`pettrackdemo.szabence.com`) still works.
- [ ] Play Console → check crash/ANR rate after the staged rollout.
