# PetTrack roadmap — from tinkerer tool to something you can show a general audience

Ideas collected while building the vision pipeline. Grouped by how much they
buy for how much work. Nothing here is scheduled — this is the wish list.

## The $1M bar (adopted 2026-10-08 — the active directive)

The project is treated as being worth $0 today. Work continues autonomously,
gate by gate, until the product is at the quality someone would pay a premium
for. Valuation is the market's to set — these gates are the testable proxy:
when every one is green, the product side is done.

1. **Flawless first run.** Download to "I can see my pet" in under 10
   minutes: no IP typing, no dead ends, every failure recoverable in plain
   language. *(mostly done — wizard, mDNS/QR pairing, demo mode; audit the
   edges)*
2. **Never miss a moment.** Alerts always arrive (local + ntfy), the stream
   reconnects by itself, the watchdog surfaces failures before the user
   notices them. *(mostly done — quiet hours, ntfy bridge, watchdog; needs
   self-healing stream reconnection)*
3. **Worth sharing.** One-tap share for replays, the daily highlight and the
   week's insights — the kind of screenshots people post.
4. **Daily-use depth.** Event → evidence tap-through (snapshot + jump to the
   replay moment), feed search/filter, arming schedule ("only watch when
   I'm away").
5. **Craft.** No broken-looking state anywhere (error + retry, empty states,
   skeletons on every data screen), accessibility AA (semantics, scaling,
   contrast), full 7-locale parity, performance targets (cold start < 2 s,
   stream latency < 1 s). *(done — the structure for both numbers is in and
   tested; see docs/PERFORMANCE.md for how to verify them on a device)*
6. **Ships like a product.** Semantic versioning + CHANGELOG + tagged release
   notes, one-tap in-app update on Android, backup/restore of settings,
   documented security posture.
7. **Distribution ready** *(the user ships, we arm)*. Store-ready assets:
   screenshots, listing copy, signing/release checklist.

Work order: the Gate 5 error/empty-state pass first (it is what makes every
later feature look premium), then 3 → 4 → 6 → 2's self-healing stream →
1's edge audit → 7. Each item lands green (analyzer + tests + i10n parity).

## Quick wins (hours each, big first-impression impact)

1. **Plain-language settings + Advanced drawer.** Today the app speaks
   "threshold / coverage / zone polygon". Split everyday settings
   (notifications, sound, dark mode, pet profile) from engineering knobs
   (`PETTRACK_*`, ports, tokens) behind an "Advanced" section — and label
   things the way a pet owner would say them ("Notify me when Berci leaves
   the bed zone").
2. **Connection status that never leaves you guessing.** One persistent,
   human-readable status chip: `Connected to home server` / `Reconnecting…` /
   `Server unreachable — are you on the same Wi-Fi?`, with a one-tap retry.
   Half of "the app is buggy" reports are silent connection drops.
3. **First-run wizard.** Three screens: *who is your pet* (name, photo),
   *where is the camera* (pick monitor device), *what should I watch for*
   (draw your first zone or tap a preset: "bed", "cage", "door"). No IP
   typing if we can help it (see pairing below).
4. **Replay timeline instead of a file list.** A day strip with event dots;
   tap a dot → clip plays. Seconds of work to find "that moment at 14:20"
   vs. scrolling filenames like `replay_1777…`.
5. **Notification wording + quiet hours.** "Berci entered the kitchen zone
   · 14:20 · tap to watch" with a snapshot thumbnail, plus "don't notify
   me between 23:00 and 7:00".
6. **Accessibility pass.** Screen-reader labels on icon buttons, respects OS
   text scaling, color-blind-safe zone overlays (not color-only), minimum
   tap-target sizes. Cheap to do incrementally, mandatory for a real audience.

## Medium (a day or two each)

7. **Zero-config pairing (mDNS / QR).** The server advertises
   `_pettrack._tcp` on the LAN; the app shows "PetTrack server found:
   homelab-pi — Connect?". QR pairing already exists for the token — extend it
   to carry host + port so nobody types an IP ever again.
8. **One-line install + HTTPS by default.** A single install script that also
   brings up Caddy (or mkcert) so phones talk HTTPS on the LAN; bad TLS on a
   local IP is the #1 self-host pain. Document Tailscale as the "access from
   outside" path in one paragraph.
9. **Multi-camera.** Several monitor phones → one dashboard with camera
   picker (and "which camera saw the event" on replays). The server
   fan-out already supports multiple `/ws` monitors; the app UI is the work.
10. **Push notifications that work outside the LAN** *(done)*. ntfy.sh / Gotify /
    WebPush bridge so events reach you at school/work without exposing the
    server — opt-in, with a "test notification" button.
11. **Live talk / treat-cam basics (stretch).** Two-way audio is hard on old
    phones; even a "play a sound" button (whistle, treat dispenser via a
    smart plug webhook) is a delight feature for pet owners.
12. **In-app update story.** For the sideloaded APK: a "new version
    available" screen that installs the release APK with one tap (Android
    package installer). Kills the "which APK do I need?" support burden.

## Larger / longer term

13. **Multi-pet profiles & per-pet events** *(deferred — needs a
    pet-reidentification classifier)*. When the tier-3 classifier (or a
    small custom model) can tell pets apart: "Berci vs. guest cat" event
    streams, per-pet activity stats ("Berci was active 3h 12m today").
14. **Activity insights** *(done)*. A simple daily/weekly chart of zone time,
    rest vs. active — the kind of screenshot people post on social media.
    Great for "show a general audience" marketing.
15. **Health & watchdog** *(done)*. Server-side: "camera offline for 10 minutes" alert,
    disk-space warnings for replays, auto-pruning old replays with a retention
    setting. Self-hosters trust a tool that tells them when *it* is broken.
16. **Public landing page + demo mode** *(done)*. The demo site exists; give
    it a real landing page (problem → photos → 3-step install → screenshots)
    and a "demo mode" with synthetic data so visitors can click around
    without a camera.
17. **Security leftovers** *(done)*. Short-lived JWTs
    with refresh, revocation on logout, scoped monitor tokens, persistent PIN
    lockout, HTTPS everywhere — mostly invisible work that keeps the project
    safe to recommend.

## Suggested order for "audience-ready"

1. First-run wizard + pairing (kills the tinkerer IP-typing experience)
2. Connection status + notification quality (kills "is it working?" anxiety)
3. Replay timeline + quiet hours (daily-use pleasure)
4. HTTPS-by-default + one-line install (removes the scariest setup step)
5. Accessibility + plain-language settings (polish that shows)

Everything above is additive to the current stack (Flutter + FastAPI + the
tiered vision pipeline) — no rewrites needed.

## Execution order (approved 2026-10-06 — "everything goes, properly, in order")

Deliberate sequence: make it *look* premium first (cheapest, most visible),
then the one killer feature, then the ecosystem that makes it a real product,
then the wow features, then platform extras. Each phase lands green
(analyzer + tests + i18n parity) before the next starts.

### Phase 1 — Design language *(done)*
1. Bundle brand fonts as assets (offline-safe; drop runtime font fetch)
2. Full Material 3 colour roles + component theme depth (both modes)
3. Native splash + refined app icon
4. Motion & polish vocabulary: hero transitions, skeletons, empty states,
   pull-to-refresh, haptics
5. Accessibility quick pass (semantics/tooltips, tap targets)

### Phase 2 — Daily highlight (killer feature) *(done)*
6. Server: stitch the day's motion events into one recap clip + thumbnail
7. App: "Berci's day" card on the dashboard, share sheet, retention setting

### Phase 3 — Ecosystem & trust *(done)*
8. Rich notifications + quiet hours + test-notification button
9. Home Assistant via MQTT discovery (camera + motion + battery entities)
10. One-line install script + optional Caddy HTTPS; update-check screen
11. Privacy / about page ("self-hosted — nothing leaves your house") +
    version & changelog in the UI

### Phase 4 — Wow features *(done)*
12. Two-way audio (talk-back) and/or "play a sound" button
13. Timelapse mode for the monitor phone
14. Night / low-light enhancement toggle
15. Audio events (bark / meow) in the activity feed
16. Multi-camera grid + digital zoom/pan

### Phase 5 — Platform extras *(done — WearOS complications deferred)*
17. Home-screen widget (live snapshot + status), WearOS complications
    *(widget done; complications need a standalone watch app — deferred)*
18. Replay timeline UI (day strip with event dots)
19. Landing page + demo mode + GitHub Releases polish
