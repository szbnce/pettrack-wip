# Store assets

Everything a store listing needs, ready to paste or upload. Used by the
release checklist in `../RELEASE_CHECKLIST.md`.

```
store/
├── listing/
│   ├── en-US/          # English listing (the default locale)
│   ├── hu/             # Hungarian
│   ├── de/             # German
│   ├── it/             # Italian
│   ├── ja/             # Japanese
│   ├── ko/             # Korean
│   └── zh-CN/          # Chinese (Simplified)
│       ├── title.txt             ≤ 30 characters
│       ├── short_description.txt ≤ 80 characters
│       └── full_description.txt  ≤ 4000 characters
└── screenshots/
    ├── SHOT_LIST.md    # which screens, in which state
    └── *.png           # the actual shots (phone, 1080×2400)
```

One folder per Play Store listing locale, matching the seven languages the
app itself ships. Titles and short descriptions are counted in characters
(CJK included) — the `.txt` files here already fit their limits; keep them
that way when editing.

## Play Store limits (Google Play)

| Field | Limit |
|---|---|
| Title | 30 characters |
| Short description | 80 characters |
| Full description | 4000 characters |
| Phone screenshots | 2–8, min 1080 px on one side, max 3200 px |
| Feature graphic | 1024 × 500 px |
| App icon | 512 × 512 px (already generated from `android/app/src/main/res`) |

The `.txt` files here already fit their limits — keep them that way when
editing.

## Notes

- Privacy policy URL for the listing:
  `https://github.com/szbnce/PetTrack/blob/main/PRIVACY_POLICY.md`
- Screenshots are taken in demo mode (no camera, no server needed) —
  `screenshots/SHOT_LIST.md` says how.
