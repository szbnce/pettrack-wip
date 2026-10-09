# Screenshot list

Seven phone shots (1080 × 2400) tell the whole story on a store page: what
it is, what it catches, what it proves. Everything is capturable in
**demo mode** — no camera, no server.

| # | File | Screen | State |
|---|---|---|---|
| 1 | `01-dashboard.png` | Dashboard | Live view up, green "Live" pill, pet name card |
| 2 | `02-feed.png` | Activity feed | A day of events (motion / sound / zone), search + chips visible |
| 3 | `03-insights.png` | Weekly insights | The shareable chart — zone time, rest vs active |
| 4 | `04-zones.png` | Zones | Camera canvas + the saved zones, named in plain words |
| 5 | `05-replay.png` | Replays | Day strip + the clip grid |
| 6 | `06-medical.png` | Medical | A medication card and a vaccine card |
| 7 | `07-arming.png` | Settings → arming | "Only watch when I'm away" schedule set up |

Rules:

- Light theme, English locale (the default listing language).
- Realistic pet name and events — demo mode already provides this.
- No notification permission dialogs or onboarding half-states in frame.
- Status bar visible (a store shot that hides it looks cropped).

## How to capture

1. Install `PetTrack.apk` on a device or emulator (1080 × 2400 or bigger).
2. First launch → language **English** → wizard → **Demo mode** → yes.
3. Navigate to each screen above, settle the scroll position so the
   interesting content is at the top third.
4. `adb exec-out screencap -p > docs/store/screenshots/NN-name.png`
   (or the device's own screenshot, resized to 1080 × 2400).
5. Keep the aspect ratio exact — Play rejects odd sizes.

Feature graphic (1024 × 500) and icon (512 × 512) come from the existing
brand assets in `pictures/` (`banner.png`, `BerciPortrait.png`).
