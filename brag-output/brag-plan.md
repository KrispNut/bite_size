# Brag plan: Bite Size

## What it is
Bite Size runs an office's shared lunch: who's eating, how many rotis to buy,
who goes to the tandoor, and who owes whom at the end of the month. In the
README's words, it replaces the group chat where all of that used to get lost.

- **For:** a small office crew that shares lunch every day.
- **Sets it apart:** the roster locks when the runner actually leaves, never on
  the clock. Shared costs are invitations, so nobody is charged until they
  accept. The runner can't leave on an unanswered list. There's a Ping button
  with no cooldown, on purpose.
- **Funniest real claim:** "No cooldown, on purpose. The button exists to be
  annoying."
- **Visual hook:** group-chat chaos, then the calm emerald splash, then the real
  dashboard doing the work.
- **Real UI shown:** the splash lockup, app bar with the Ping button, roster
  status bar, runner card (unassigned → assigned → left), roster tiles, the
  shared-meal invite with "Count me in", toasts, and the "Food arrived" card.
- **Share caption:** see the end of this plan.

## Angle
Serious logistics software for a stack of rotis, played straight. The app's own
flow is the joke and the proof: one card follows the run from "Nobody yet — who
is going?" all the way to "Food arrived".

## Hook (0–3s)
Group-chat bubbles pile up. Over them, four questions slam in one per beat:
**Who's eating? How many rotis? Who's going? Who paid?**

## Highlights
1. The roster fills itself and the runner card counts up to **6 ROTIS TO BUY**.
2. A shared Chicken Karahi invite. Tap **COUNT ME IN**. "Nobody is charged until
   they accept."
3. Assign the runner, then **START THE TANDOOR RUN**. The status bar flips to
   **ROSTER LOCKED · LEFT 12:30 PM**.
4. Comic beat: **PING BILAL** gets tapped four times. "No cooldown, on purpose."

## Punchline / outro
**Food arrived.** Then the splash lockup: **Bite Size** / "It replaces the group
chat." / OFFICE LUNCH LOGISTICS, SORTED BEFORE NOON.

## User flow shown
Log rotis → answer a shared-meal invite → runner starts the tandoor run (list
locks) → food arrived.

## Tone
- Preset: `default`, with a dry yc-parody edge.
- Creative direction: "mission control for the lunch run".
- Interpretation: clean and punchy, 7 beats with snappy cuts. Copy comes
  straight from the app; the humour comes from how seriously it treats rotis.

## Format and duration
Landscape, 1920×1080, 30fps, 22s.

## Visual identity (from the code)
- Colours come from `PackPalette.seeded(#145C44, #B5652B)`, ported 1:1
  (`work/palette.mjs`): primaryDeep `#0F4533`, primary `#156047`, primarySoft
  `#E9F3F0`, accentFill `#D0834A`, onAccent `#3F2614`, accent `#885027`.
- Chassis: background `#F4FAFF`, ink `#1E293B`, surface `#FFFFFF`, border
  `#CBD5E1`, text secondary `#3E4946`, text tertiary `#6E7976`, success
  `#1F7A48`, warning `#B45309`, danger `#BA1A1A`.
- Type: Hanken Grotesk 800 with tight tracking, and JetBrains Mono caps for
  anything countable. These are the faces the design system specifies.
- Rules followed: ink strokes on every container, nothing round except the
  phone hardware, no gradients or glows, read-only surfaces flat.
- Assets reused directly: `assets/svg/*` (roti, runner, plate, party,
  splash_image), both runner-card Lotties (`idle.json` while nobody has the
  run, `runner.json` once Imran does, played the way `LottieLoop` plays them),
  and the splash entrance (fade + 14px rise, 600ms easeOutCubic).

## Privacy stand-ins
- All people are fictional: Ayesha (you, admin), Bilal (ping target), Hamza
  (paid for the karahi), Sana. The runner is "Imran", in place of the pack's
  real `externalRunners`.
- No URLs, keys, emails or real data from `.env` or Supabase appear anywhere.

## Storyboard (22.0s)

| # | Time | Scene | On screen | Sound |
|---|---|---|---|---|
| 1 | 0.0–3.0 | Hook | Chat bubbles pile up (texture). Four questions land on the beats at 0.5/1.0/1.5/2.0 and hold to 3.0 | Pentatonic chat dings that turn into the melody; soft woody hits on each question; noise riser into 3.0 |
| 2 | 3.0–5.5 | Reveal | Emerald panel wipes up. Splash lockup: lunchbox mark in a white bento tile, "Bite Size", OFFICE LUNCH LOGISTICS, SORTED BEFORE NOON | The drop: kick, bass and chord stabs; motif under the wordmark |
| 3 | 5.5–9.0 | Roster | Splash dissolves into the app. Phone at right shows the dashboard: idle robot, "Nobody yet — who is going?". Four roster tiles arrive one by one and the counter ticks 0→2→4→5→6. Caption: "Everyone logs their rotis." | Marimba ticks rising in key, one per tile |
| 4 | 9.0–12.0 | Invite | Invite card slides in. Camera pushes in. Cursor taps COUNT ME IN; toast "You're in on Chicken Karahi ✅". Caption: "Nobody is charged until they accept." | Soft tap, then a two-note confirm chime |
| 5 | 12.0–15.5 | Run | Camera on the runner card. Tap IMRAN: the card turns emerald with "6 ROTIS TO BUY" and "Everything is confirmed — clear to go!". Tap START THE TANDOOR RUN: "Left at 12:30 PM · list locked", and the status bar shows ROSTER LOCKED · LEFT 12:30 PM. Caption: "The roster locks when the runner leaves." | Tap, a whoosh as the card flips, then a low lock thunk on the beat |
| 6 | 15.5–17.5 | Ping | Camera on the app bar. PING BILAL is tapped 4× fast, with toasts "Pinged Bilal 🔔" stacking. Caption: "No cooldown, on purpose." | Four bell pings climbing the chord |
| 7a | 17.5–19.0 | Arrival | The Food arrived card replaces the runner card (party mark, "Announced by Imran at 1:05 PM"). Camera pulls back | Celebratory arpeggio, clap fill into 19.0 |
| 7b | 19.0–22.0 | Outro | Emerald lockup: roti-stack tile, "Bite Size", "It replaces the group chat.", tagline | Final D-major hit rings out, fade |

Every caption meets the reading floor of ~0.3s per word once fully on screen.

## Sound
Music and effects are one piece, written to a single grid: 120 BPM in D major
with an I–V–vi–IV progression, all through one shared reverb. Every effect is
pitched in key: chat dings, marimba ticks, confirm chime and ping bells. The
effects sit under the music. Repeated small sounds (dings, ticks) stay in the
background.

## Share copy (draft)
Our office lunch used to live in a group chat. Now it has a roster, a runner
card that locks the list when the tandoor run starts, and a Ping button with no
cooldown, on purpose. Bite Size: office lunch logistics, sorted before noon.
