# Bite Size — 20s intro film

A 1920×1080, 30 fps, 20.000 s motion-graphics intro for Bite Size, built in
[Remotion](https://www.remotion.dev). The score and every sound effect are
synthesised from scratch by a standard-library Python script. There are no samples and no voiceover.

**Output:** `out/bite_size_promo.mp4`

## Structure

| Time | Beat | What happens |
| --- | --- | --- |
| 0–3.0 s | 1 · the problem | A lunch group chat piles up: roti counts drift, payments get lost. |
| 3.0–7.0 s | 1 · the fix | The "?" dot floods the frame emerald. *Bite Size* lands, and the bubbles snap into tidy rows that file into the app. A salan cost arrives as an invite, and the cursor taps **Join**. |
| 7.0–13.6 s | 2 · the split | The camera dives through **Join** into a bento of cards: the shared cost becomes *Joined* (Rs 480 ÷ 3 = Rs 160 each). The tandoor run lists who's in and who's fetching, and **locks when the runner leaves**. Then come your share (Rs 75 + Rs 160 = Rs 235) and the October ledger, whose balances net to Rs 0. **"Adds up."** is stamped. |
| 13.6–17.4 s | 3 · the packs | The switcher flips **Office Lunch → Cricket Ground**: the pitch is booked by the hour (2 hrs × Rs 3,000 = Rs 6,000 ÷ 12 = Rs 500 each). |
| 17.4–20 s | sign-off | Wordmark, "Fair splits. *no arguments.*", and both pack chips. |

All figures reconcile: 3+2+4+3 = 12 rotis × Rs 25 = Rs 300; ledger
+1,840 − 620 − 740 − 480 = 0.

## Colour

Everything comes from `lib/core/theme/app_colors.dart`. The neutral base uses
`bgColor`, `surface`, `border`, `divider` and the `ink` text ramp, plus the zinc
`navy900` for the dark stage. Packs use their seed pairs:

- **Office Lunch** (`biteSize*`): emerald `#145C44` + terracotta copper `#B5652B`
- **Cricket Ground** (`ground*`): royal navy `#1F3F80` + antique gold `#A8792A`

Soft fills use the same `tint()` alpha-blend `AppColors.tint` uses.

## Rebuild

```bash
npm install
```

```bash
npm run audio
```

```bash
npm run render
```

```bash
npm run finalize
```

`finalize` (needs ffmpeg) keeps the rendered video stream as-is and muxes the
original WAV in as a single AAC encode cut at exactly 20.000 s, which drops
the codec padding the raw render carries.

Cue timings live in `src/timeline.json`. Both the scenes and
`audio/generate_audio.py` read them, so retiming a beat moves its sound with it.
`audio/cue_sheet.json` lists every effect and the frame it lands on.

If Remotion's headless Chrome can't download, render with a local Chromium
browser instead, for example Edge:

```bash
npx remotion render src/index.ts BiteSizePromo out/render_raw.mp4 --codec=h264 --crf=16 --audio-codec=aac --audio-bitrate=320k --browser-executable="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --chrome-mode=chrome-for-testing
```

---

# App-accurate cut (`BiteSizeApp`)

**Output:** `out/bite_size_app.mp4`, also 1920×1080, 30 fps and exactly 20.000 s.

It tells the same story, but every phone frame is the Flutter app's own UI. It's
rebuilt in `src/app/` from the widgets that draw it, and driven through the app's
real flow and copy:

| Time | What the phone shows | Built from |
| --- | --- | --- |
| 3.0–4.7 s | The cold-start splash: lunchbox mark, "Bite Size", OFFICE LUNCH LOGISTICS, SORTED BEFORE NOON, and the shuttling progress bar. It then shrinks into the phone and dissolves (350 ms) into the dashboard. | `splash_view.dart`, `neo_progress_bar.dart` |
| 4.7–6.5 s | Ali's dashboard: ROSTER OPEN, a pending invite card, the runner card (Lottie runner, 12 ROTIS TO BUY, `Waiting on Sara, Ali to answer "Extra salan".`), the roster and shared meals. | `dashboard_body.dart`, `runner_card.dart`, `pending_invites_card.dart`, `invite_row.dart`, `roster_tile.dart` |
| 6.5–9.2 s | **COUNT ME IN**, then the toast. The shared meal re-splits across the people who accepted: Rs 240 while Sara is pending, Rs 160 once she accepts. The runner card turns to "Everything is confirmed — clear to go!". | `shared_expense_tile.dart`, `shared_expense.dart` |
| 9.2–11.2 s | **START THE TANDOOR RUN**, then **Heading out?** ("This locks the list at 1 shared meal plus 12 rotis…"), then **LOCK IT & GO**. Result: ROSTER LOCKED · LEFT 1:15 PM, "Roster locked — Ali left at 1:15 PM". | `runner_card.dart`, `dialogs.dart`, `roster_status_bar.dart`, `roster_closed_notice.dart` |
| 11.2–13.8 s | Rotis ledger, then the Settle sheet: price per roti 25 gives TOTAL BILL Rs 3300 (132 rotis × 25), then SETTLE OCTOBER. Tiles update to Rs 825 / Rs 3,300. | `ledger_daily_strip_view.dart`, `settle_month_sheet.dart`, `bill_total_tile.dart`, `bento_tile.dart` |
| 13.8–16.9 s | Drawer, then **Theme**, then the pack picker (each row in its own palette and swatch). Picking **Ground Booking** reloads the app as Ground Booking: PAYER Bilal, 2 HOURS TO BUY, 12 in the group, and "Pitch, 2 hours" at Rs 6,000, Rs 500 each. | `dashboard_drawer.dart`, `pack_picker_sheet.dart`, `activity_packs.dart` |

Accuracy notes:

- **Colours.** `src/app/flutter.ts` ports `PackPalette.seeded` exactly: the Flutter
  `HSLColor` round-trip, the WCAG-luminance bisection, and 8-bit rounding. The
  phone therefore uses the derived roles (Office Lunch primary `#156047`, deep
  `#0F4533`, accent fill `#D0834A`; Ground Booking primary `#2850A4`, deep
  `#1C3A75`, accent fill `#BF8C34`), not the raw seeds.
- **Tokens and type.** Radii, spacing, ink strokes, shadows and the tracking and
  leading curves come from `app_theme.dart` / `text_styles.dart`. Type is Roboto
  (the app sets no font family) with tabular figures for the "mono" styles.
  Icons are Material Icons Round, matching Flutter's `Icons.*_rounded`.
- **Assets.** The app's own SVG marks, Lottie runner and launcher art are
  copied in by `npm run sync-assets`.
- **The one liberty.** Switching packs restarts the app instantly. The video
  covers that restart with a circle reveal from the tapped row.

```bash
npm run sync-assets
```

```bash
npm run audio:app
```

```bash
npm run render:app
```

```bash
npm run finalize:app
```

Its cues live in `src/app/timeline_app.json`, and `audio/cue_sheet_app.json`
lists its effects.

---

# Reference-style cut (`BiteSizeRef`)

**Output:** `out/bite_size_ref.mp4`. It's 1920×1080, 30 fps, and exactly 20.000 s. The beats are the reference's, but they're given more room, and every transition is slower and calmer than the source.

This cut rebuilds the reference film shot for shot in its art style, for Bite Size:

| Time | Reference | Bite Size |
| --- | --- | --- |
| 0–3.2 s | character peeks in, "psst…", *Got something to sell?*, then the "?" dot wipes | the app's mascot peeks in, "psst…", *Who's in for lunch?*, then the "?" dot wipes |
| 3.2–6.2 s | blue field with Courses / Ebooks / Apps cards | brand field with Rotis / Meals / Pitches cards |
| 6.2–9.3 s | field shrinks into a phone: *Pocketsflow turns it into a store in minutes* | field shrinks into the real app: *Bite Size turns it into one list, one runner.* The cursor taps COUNT ME IN |
| 9.3–15.3 s | push through the button, then a bento of checkout cards and *Handled.* | a gentle push onto COUNT ME IN, a dissolve onto the matching button, then a bento (shared meal, runner, month-end price, who's in, the lock, the October bill) and *Sorted.* |
| 15.3–17.9 s | black: *You create. We handle the flow.* | black: *You bite. We handle the size.* |
| 17.9–20 s | wordmark, character peeking behind it | **Bite Size** wordmark, mascot peeking behind it, *Office lunch logistics, sorted before noon.* |

**Art style.** `src/ref/Dither.tsx` is a 1-bit ordered (8×8 Bayer) dither. The
app's 3D beaver mascot (`assets/icon/logo.png`) is rendered at 2 px through a red
"colour filter", as in black-and-white photography, plus an unsharp mask. That
keeps the fur, the ears and their inner patches, the eyes, the teeth and the apple
legible, so the mascot reads like a printed photo. The card illustrations are 3 px:
the app's roti art, plus a drawn salan bowl and cricket ball. The mascot is posed before it's dithered, so the pattern crawls
as it moves, as it does in the reference. The brand colour (`#156047`, the app's
derived primary) takes the reference's blue role. The black beat uses the app's
dark-mode primary.

```bash
npm run audio:ref
```

```bash
npm run render:ref
```

```bash
npm run finalize:ref
```

---

# Notes cut (`BiteSizeNotes`)

**Output:** `out/bite_size_notes.mp4`. It's 1920×1080, 30 fps, and exactly 20.000 s.

It combines two references in one film:

- **0–8 s, after the Slava S. reference (typography plus client notes).** The office group chat revises the lunch order like a client who never stops giving feedback. Each italic note reshapes one word, labelled `v1` → `v8_final_FINAL`:
  - "who's in for lunch?" → **Lunch?**
  - "me! 3 rotis" → a copper disc with **3 ROTIS**
  - "+4 for me. salan too?" → marquee rows
  - "whole floor's in. bigger." → **12 ROTIS** grows until it crops
  - "wait… who's paying?" → a contrast wipe
  - "who paid on friday??" → **W H O  P A I D ?**
  - "can someone just keep track?" → a serif **Lunch.**
  - "ugh. is there an app for this?" → the camera dives into that full stop until it floods the frame green
- **8–20 s, after the QuickDesign reference (product console).** The flood collapses into a cursor, and "What's for *lunch*?" types out:
  - an input with "daal mash · 3 rotis", plus Rotis / Shared meal / Runner / Month-end chips
  - a tilted grid of 12 roster cards counting to 12/12: *One list.* **Twelve lunches.**
  - a toolkit of real app features: SHARED MEALS, RUNNER, LIST LOCKS, CHEF AI, PING
  - *Order. Fetch. Settle.* beside an October bill counting to Rs 3,300 (132 rotis × Rs 25 over 11 days)
  - a tile wipe into a pixel roti mark, then typed **bite size**, and the reference's closing line reworded as *Any other orders?*

Colours are the app's own. Part 1 uses the lunch pack's warm `accentSoft` paper, zinc ink and the copper seed. The console uses the app's dark-mode roles: emerald `primaryDark` `#2DA87F` and copper `accentDark` `#D69262`. The roster cards draw from both packs' derived palettes, plus `AppColors.info` for PING. Card icons are the app's own SVGs.

All transitions are eased: the toolkit uses 6-frame dissolves, not hard cuts.

```bash
npm run audio:notes
```

```bash
npm run render:notes
```

```bash
npm run finalize:notes
```
