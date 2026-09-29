# Bite Size 🍛

Bite Size runs the shared money for a small group: who's taking part, what they
put in, how much of the bulk thing to buy, who fetches it, and who owes whom at
the end of it. It replaces the group chat where all of that used to get lost.

It started as an office lunch app and the lunch is still the default. But the
engine underneath — people, a session, costs in integer minor units, invitations
that have to be accepted, an exact split, a ledger — never had anything to do
with food. So the words, the switched-on features and the colours are
**configuration, not code**: see [Activity packs](#-activity-packs).

The day is one Supabase row keyed by the date — and, since 007, by the pack:
`2026-09-14` for lunch, `ground_booking:2026-09-14` for cricket — so it resets
itself at midnight with no cron job and no cleanup, and two packs on the same
day never share a roster, a shared cost, a runner, or a reset.

---

## 📦 Activity packs

A pack is the answer to "what is this install?". It decides which halves of the
app are switched on, what every noun is called, what colour it is, what shape
it is, and what currency the money is in. Nothing under `lib/features/` carries
a domain word or a raw colour as a literal — a screen asks the pack. Icons are
the exception: screens use the app's own marks directly (see [Icons](#icons)).

**Switch one in the app:** drawer → **Theme**. Tapping one restarts the app in
place — it comes back recoloured and reshaped — and the choice is remembered on
the device.

```
lib/core/theme/
├── activity_packs.dart  the whole pack layer in one file — Currency,
│                        ActivityPack (modules · labels), PackPalette,
│                        PackShape, the shipped packs, PackService
├── app_colors.dart      AppColors + the four pack seed colours
├── app_theme.dart       ThemeService · AppRadius · AppSpace · AppDecor ·
│                        AppShadow · AppTheme
├── text_styles.dart     type roles
└── font_weights.dart    weight tokens
```

### The module switches

| Module | What it turns on | Off means |
|---|---|---|
| `roster` | People log what they contributed | No roster section, no sticky add-entry bar |
| `coverage` | The headcount-vs-portions shortfall, shown as a one-line warning only when the roster is short | No shortfall tracking |
| `units` | A countable thing bought in bulk, billed by how many each person took | No unit counter, no per-unit split, no "nothing to buy" gate on the runner |
| `errand` | Somebody goes and buys it, and the list must be final before they leave | No runner card, no departure gate, no arrival |
| `advisor` | The AI read on the session | No AI check |
| `ping` | The one-tap nag to whoever is flagged `is_ping_target` | No Ping button, even though the flag is project-wide |

Turn all six off and the app collapses to *session → costs → invitations →
split → ledger*, which is the whole of the shared-money case. That isn't a
degraded mode; it's the floor everything else is built on.

### The packs that ship

| Pack | `roster` | `coverage` | `units` | `errand` | `advisor` | `ping` | Reads as |
|---|:-:|:-:|:-:|:-:|:-:|:-:|---|
| `office_lunch` | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | dish · rotis · tandoor run · Chef AI · Ping |
| `ground_booking` | — | — | ✅ | ✅ | — | — | hours · ground booking · groundsman |

And how each one looks, which is the other half of the switch:

| Pack | Primary / accent | Radius | Stroke | Depth |
|---|---|---|---|---|
| `office_lunch` | emerald `#145C44` · terracotta copper `#B5652B` | ×1.0 | 1px | soft |
| `ground_booking` | royal navy `#1F3F80` · antique gold `#A8792A` | ×1.0 | 1px | soft |

A seed contributes **hue and saturation only**. Every role of the ramp is then
anchored to a target *relative luminance* — the number WCAG contrast is built
from — rather than an HSL lightness, because at equal lightness a gold is far
brighter than a copper. That is why both packs weigh the same in every role and
why the contrast ratios hold for any seed you might swap in.

Both packs share the same rounded geometry on purpose — the themes are told
apart by colour alone. The palettes are jewel tones: dark and rich, never
neon. An earlier iteration muted both so far that a desaturated forest and a
desaturated navy collapsed into the same grey-dark, so keep a clear hue gap
and some chroma between seeds.

There used to be two more packs (`potluck`, `shared_costs`); they were cut,
and a device that still has one of them saved falls back to `office_lunch`
with a log line rather than crashing.

`ground_booking` is the cricket case: the pitch costs what it costs, someone
pays the groundsman, and it splits by the hours booked. There's no roster to
fill and nothing to be short of, so those modules are off and the screens they
own simply aren't there.

### Choosing one

In the app: **drawer → Theme**. Tapping a row restarts the app in place and it
comes back wearing the new one; the choice is written to `SharedPreferences`,
so it survives a real restart too. Light and dark mode is a separate switch,
also in the drawer.

The restart is not decoration — see
[Why a theme change restarts the app](#why-a-theme-change-restarts-the-app).

The `.env` keys set what a *fresh* install starts as. A person's own choice
wins over them, which is the whole point of the picker:

```dotenv
ACTIVITY_PACK=ground_booking
```

Or hand it a whole pack inline — the same shape the `activities.config` row
will hold once groups land:

```dotenv
ACTIVITY_PACK_JSON={"id":"printer","modules":{"units":true},"labels":{"activityName":"Print Fund","unit":"sheet","unitPlural":"sheets"},"palette":{"primary":"FF4C5D8A","accent":"FFD9822B"},"shape":{"radiusScale":0.5,"strokeWidth":2,"depth":"hard"},"currency":"PKR","recurrence":"adhoc"}
```

Resolution order is: saved choice → `ACTIVITY_PACK_JSON` → `ACTIVITY_PACK` →
`office_lunch`. A bad value is never fatal; it logs and falls through.
`PackService.resetToEnv()` forgets the saved choice.

An inline pack isn't offered in the picker — it has no id anyone could choose
again — but an install pinned to one keeps it.

### Reading a pack

```dart
PackService.labels.unitCount(6)    // "6 rotis" / "6 hours"
PackService.labels.expenseCount(2) // "2 shared meals" / "2 shared costs"
PackService.modules.errand         // is anyone fetching anything?
PackService.currency.format(1250)  // "Rs 12.50" — minor units in, string out
PackService.palette.primaryDeep    // read by AppColors, not by features
PackService.shape.radiusScale      // read by AppRadius, not by features
```

`PackService` is a `ChangeNotifier`, and `AppColors` / `AppRadius` / `AppDecor`
/ `AppShadow` read it on every access rather than caching — but that alone is
not enough to repaint the app. See below.

### Why a theme change restarts the app

Notifying listeners does not reskin a Flutter app. `Element.updateChild`
short-circuits when the incoming widget is *identical* to the one it replaces,
which is exactly what a `const` widget is — and a lot of this app is const:
`const DashboardDrawer()`, `const DashboardBottomBar()`, every
`const SheetHandle()`. Those read `AppColors.primary` and `AppRadius.md` inside
`build`, so they keep the old theme until something unrelated happens to
invalidate them.

So `_BiteSizeAppState` keys the whole tree on a generation counter and bumps it
when the pack changes. The old tree is discarded and a new one built from
scratch — what a restart would achieve, without killing the process or signing
anyone out. A cold start goes through the splash; a theme restart skips it and
lands straight on the dashboard, because `IdentityService` is a singleton that
outlives the tree and already knows who you are.

**`appNavigatorKey` is reissued on every restart, and that is load-bearing.**
Flutter *reparents* a global-keyed element into the new tree instead of
rebuilding it. A stable navigator key would carry the navigator and every route
under it across the teardown untouched, still wearing the old theme — the
restart would appear to do nothing. `newAppNavigatorKey()` exists for this one
reason.

Light/dark is different: it doesn't restart anything. `ThemeService` notifies,
and the widgets that paint with `AppColors` listen to it (the dashboard, the
bottom bar, the drawer). The drawer has to, because the Dark mode switch lives
inside it — otherwise the app behind it would change and the open drawer
wouldn't.

### Colour and shape

A pack's look is two objects, and both only touch *identity*:

**`PackPalette`** — the primary and accent ramps, 16 roles across light and
dark. `PackPalette.seeded(primary:, accent:)` derives all sixteen from two
colours, which is how a new pack gets a palette without hand-picking values and
getting one subtly wrong. Both shipped packs are seeded from the four colours
pinned in `AppColors` (`biteSizePrimary`/`biteSizeAccent`,
`groundPrimary`/`groundAccent`) — change a seed and the whole ramp follows.
Check contrast when you do: a plausible-looking plum seed once produced a
dark-mode primary at 2.84:1 against the background.

**`PackShape`** — `radiusScale` (0 = square, 1 = the original 4/8/12/16/24
ramp), `strokeWidth`, and `ShapeDepth`:

| Depth | What sits under a surface |
|---|---|
| `soft` | A blurred offset shadow. Cards float. The original. |
| `hard` | A solid, fully-opaque ink rectangle at `blurRadius: 0`. Elements look stamped onto the page — the Neo-Brutalist reading. |
| `flat` | Nothing. Structure comes from the outline alone. |

Four presets: `standard`, `rounded`, `brutalist`, `document`.

What is deliberately *not* per pack: ink, the greys, the text colours, the
semantic red/amber/green, the spacing ramp, the type scale and the icons. Those
are the chassis. Moving the colours would make the themes look like different
apps; moving the spacing would reflow every screen and turn a theme switch into
a layout bug hunt.

Under `hard` depth, [design system rule 3](#-design-system) stops being
advisory: a translucent fill over an opaque ink shadow turns the element into a
dark smear, which is why `AppColors.tint()` blends rather than using alpha.

### Recurrence

`recurrence: daily` is what gives the lunch app its free reset — the session id
is the date, so midnight clears the board. `adhoc` is for anything that isn't
daily. There is no cutoff time: the roster only locks when the runner actually
leaves, and Postgres enforces that (migration 011). `sessions.cutoff_at` is
still filled in by `ensure_session()` because the column is `NOT NULL`, but
nothing reads it.

### Money

Amounts are integer minor units — paisa, cents, fils — everywhere, and only
become a decimal at the moment they're drawn. `Currency.minorExponent` is why
that's a type and not just a symbol string: JPY has no minor unit and KWD has
three, so `/ 100` is a Pakistani assumption rather than an arithmetic fact.

### What isn't configurable yet

One install is still one group running one activity, because `sessions.id` is
the date and nothing else. See
[Not yet generic](#️-not-yet-generic-one-group-per-install).

---

## 🚀 What it does

Under the lunch pack, which is what these read as by default:

**Daily roster** — Everyone logs what they brought and how many rotis they
want, or that they're eating only. There's no deadline on the clock: the
roster stays open until the runner leaves. An empty roster shows a dashed
"your slot" row with your own photo in it; tapping it opens Add entry.
`roster`. Coverage — "how many people does it feed" — is off for this pack:
nobody counted portions honestly, so the number only ever produced false
alarms.

**Unit counter** — The live total of the bulk item to buy, aggregated by a
database trigger rather than by counting rows on the client. It sits on the
runner card as "N ROTIS TO BUY". `units`.

**Advisor AI** — Gemini reads the roster and the headcount and says whether
there's enough to go round, and what to do about it if there isn't. The framing
comes from the pack's `advisorBrief`; the numbers are generated from its labels,
so a group that renames its units gets a prompt about the right thing without
anyone editing the file. `advisor`.

**Shared costs** — Two people ordering a karahi between themselves is a
different thing from the whole office splitting the bread. A shared cost charges
only the people on it — and only after they've agreed. See
[Shared costs are invitations](#-shared-costs-are-invitations). Always on: this
is the engine.

**Errand runner** — One card follows the run from start to finish: who is
going, how much to buy, whether they've left, and the button for whatever
happens next. See [The runner card](#-the-runner-card). `errand`.

**Ledger & settle** — The Ledger shows every day of the month per person.
Settling is monthly: the admin enters one price per roti and settles every day
that hasn't been billed yet. See [Settling the month](#-settling-the-month).

**Ping** — One tap in the app bar nags whoever is flagged as the ping target,
even if their app is closed. See [Ping one person](#-ping-one-person). `ping`.

**Notifications** — Local alerts for the things you'd otherwise miss: someone
inviting you onto a cost, someone answering yours, a cost being confirmed, the
runner leaving, the food landing on the table, and an hourly nag at the admin
while no runner has been picked. Pings are the one alert that also goes out as
a push.

---

## 🏃 The runner card

The runner card is the top of the dashboard, and it's there from the moment
the app opens — even before anyone has touched today and Postgres has a row for
it. Assigning a runner, adding an entry or pinging creates the day through
`ensure_session()`. The card changes shape as the run goes:

| Stage | What it shows | Who can act |
|---|---|---|
| Nobody assigned | An idle robot, "Nobody yet — who is going?", the rotis to buy | An admin picks one of the pack's `externalRunners` (the office boy, Rana) |
| Assigned | The runner, the rotis to buy, "Start the tandoor run" | The runner or an admin. Greyed out, with the reason on the line above, while nobody has asked for any rotis or a shared cost is unanswered |
| Left | "Left at 12:30 PM · list locked", "Food arrived" | Anyone, after a confirm, and everyone else is notified |
| Arrived | The card is replaced by the arrival celebration | — |

The status line above it says **ROSTER OPEN**, or **ROSTER LOCKED · LEFT 12:30
PM** once the runner has gone.

Starting the run is the one step that can't be undone for members: it freezes
the roster and every shared cost for the day. So it's gated twice — by the
button in the app, and by `depart_for_tandoor()` in Postgres, which refuses
while any shared cost is unanswered (and, with migration 013, while nobody has
asked for any rotis). The reasons come from `departureBlockReason`, which names
the people everyone is waiting on rather than just greying the button out.

---

## 💰 Settling the month

Settling happens once a month, from the Ledger. An admin taps **Settle
September** at the bottom of the ledger, enters the price per roti, and gets
the month's roti bill before confirming.

What it does, for every day this month that isn't settled yet:

1. Each person's rotis × the price is written to the ledger as owed to the
   admin who's settling (they paid the tandoor).
2. Every confirmed shared cost is written at the split its people already
   agreed to, owed to whoever paid for it.
3. The day is marked `settled` and its roti cost stored in
   `sessions.total_roti_cost`, which is what the Ledger reads to price each day.

Today is left out while its roster is still open, so settling on the last
afternoon of the month can't lock anyone out of lunch. When there's nothing
left to bill the button says **Nothing to settle in September**. Days with rotis
but no price yet are called out at the top of the ledger, because they would
otherwise silently read as zero.

The work is in `SupabaseService.settleSessions()`, one day at a time, so a
dropped connection leaves at most one day half-written. Admins were always
allowed to write a day's cost and status (migration 002), so this needed no
new migration.

---

## 🔔 Ping one person

The dashboard's app bar carries a button that reaches exactly one member —
whoever carries `is_ping_target` in `public.users`. Tap it and that person's
phone rings with *"{you} pinged you"*. The button is never shown **to** that
person; pings flow one way, towards them, and everybody else can send one.

```
  UPDATE public.users SET is_ping_target = TRUE WHERE email = 'rana@…'
        │
        ▼
  Everyone but Rana sees  [ 🔔 PING RANA ]  in the app bar
        │  tap
        ▼
  send_ping() in Postgres — reads the flagged row itself, refuses to ping
  yourself, no cooldown
        │
        ▼
  Rana's phone: in-app buzz if the app is open, a push if it isn't
```

Why it's built that way:

- **The target is a row, not a build.** It started as `PING_TARGET_EMAIL` in
  `.env`, which ships inside the app — so moving the ping meant rebuilding and
  reinstalling on *every* phone, and until the last one was done half the
  roster pinged the old person while the new target still saw a button aimed at
  themselves. It is now one `UPDATE` (009), live for everyone on next launch.
- **At most one target, enforced.** A partial unique index over the true values
  makes "the ONE person" a rule Postgres keeps. Moving it is two statements:
  clear, then set.
- **Only an admin moves it.** `users_update` lets a person write their own row,
  so `guard_user_identity()` refuses a change to `is_ping_target` from anyone
  who isn't an admin — otherwise any member could quietly point the ping at
  themselves.
- **The client never picks the recipient**, and doesn't even send one.
  `send_ping()` is the only door into the table (there is no insert policy) and
  it resolves the target server-side, so a phone running an older build cannot
  ping whoever *used* to be the target.
- **No cooldown, on purpose.** The button exists to be annoying, so it can be
  tapped again immediately. Migration 010 removed the 30-second `ping_too_soon`
  guard that 006 introduced.
- **No target, no button.** If nobody is flagged, the button isn't shown at all.
- **History doesn't ring.** Rows created before the dashboard subscribed are
  what arrived while the app was shut; those are marked seen silently. Only
  rows created afterwards ring, whichever stream event carries them.
- **It reaches a closed phone.** Unlike every other alert, a ping also goes
  out as a push — see [Pings are push](#-pings-are-push-everything-else-is-local).

**Admins work the same way and always did.** `public.users.role` is the only
thing that grants admin, enforced by RLS through `is_admin()`, and there may be
any number of them:

```sql
UPDATE public.users SET role = 'admin'
 WHERE lower(email) IN ('one@example.com', 'two@example.com');
```

`ADMIN_EMAIL` in `.env` was only ever a seed for migration 001 and nothing at
runtime ever read it.

---

## 🤝 Shared costs are invitations

Adding someone to a shared cost used to put money on their tab without asking
them. It doesn't any more.

```
  You add "Chicken Karahi · Rs 900" and name Ali and Sara
        │
        ▼
  Ali and Sara each get a notification and a card on their dashboard
        │
        ├── Ali accepts  ─────────────► he's in the split
        ├── Sara declines ────────────► she's out; cost re-splits across the rest
        │
        ▼
  Every invite answered → the cost is CONFIRMED
        │
        ▼
  Only then can the runner leave
```

The rules, and why each exists:

- **Nobody is charged until they accept.** A share starts `pending` and carries
  zero paisa. The numbers in the share sheet are estimates, labelled as such,
  because the real split isn't knowable until the last person answers.
- **Declining re-splits the cost.** Postgres re-runs the whole allocation over
  whoever is left, so the shares always still add up to the bill exactly. The
  payer gets told, because their own share just went up.
- **The payer can't decline.** They already spent the money. They can delete
  the cost; they can't walk away from it.
- **Declines stay visible.** A person who said no stays on the tile with a
  cross, so "why is this only split two ways" is answerable without opening
  anything.
- **The runner cannot leave on an unanswered list.** `depart_for_tandoor()`
  refuses while any cost is `pending`, and the runner card names who it's
  waiting on. The runner is the one buying these things — leaving without
  knowing what to get is how you come back with the wrong thing and an argument
  about who pays for it.
- **Leaving freezes the day.** After departure nothing can be added, removed or
  answered. Enforced by a trigger, not just by hiding buttons.

### Cost and invite states

In code the cost is a `SharedExpense` with an `ExpenseStatus`; each person on it
is an `ExpenseShare` with an `InviteStatus`. The database still calls them
orders (`extra_orders`, `extra_order_shares`) — see
[Domain vocabulary in code](#domain-vocabulary-in-code).

| `ExpenseStatus` | Meaning |
|---|---|
| `pending` | Someone named on it still owes an answer. **Blocks the errand.** |
| `confirmed` | Everyone answered, at least one person is in. Goes to the ledger. |
| `cancelled` | Everyone declined. Kept as a record of the ask; billed to nobody. |

| `InviteStatus` | Meaning |
|---|---|
| `pending` | Asked, hasn't answered. Carries zero. |
| `accepted` | In the split, carries their allocated slice. |
| `declined` | Out. Carries zero, stays listed. |

---

## 📅 The shape of a day

```
 open ──► roster fills ──► runner assigned
                                  │
         at least one roti, and every shared cost answered?
                     │                         │
                    no                        yes
                     │                         │
           button greyed, the card       runner departs
           says what it's waiting on      (list frozen)
                                               │
                                          food arrives
                                               │
                              end of month: the admin settles
                                               │
                                            ledger
```

Under a pack with `errand` off, the middle of that isn't there: the session
fills with costs and the admin settles.

---

## 🛠️ Architecture

- **Frontend** — Flutter. `Provider` + `ChangeNotifier` view models
  (`DashboardViewModel`, `AuthViewModel`, `LedgerViewModel`), organised
  feature-first under `lib/features/`.
- **Domain config** — `lib/core/theme/activity_packs.dart`. The pack: labels,
  module switches, palette, shape, currency. See [Activity packs](#-activity-packs).
- **Backend** — Supabase Postgres. The dashboard subscribes to realtime streams
  for the session, the roster entries, the shared costs and your pings; there
  is no polling and no manual refresh path beyond pull-to-refresh.
- **Auth** — Supabase Auth + Google Sign-In, gated by a seeded allowlist.
- **AI** — Gemini (`gemini-2.5-flash`) via `google_generative_ai`.
- **Notifications** — `flutter_local_notifications`, fired off realtime stream
  events, plus Firebase Cloud Messaging for pings. See
  [Pings are push](#-pings-are-push-everything-else-is-local).
- **Theming** — two independent axes. `ThemeService` drives light/dark;
  `PackService` drives *which* theme, via `PackPalette` and `PackShape`. Both
  feed the `AppColors` / `AppText` / `AppSpace` / `AppDecor` token set in
  `lib/core/theme/`. No raw hex or magic numbers in feature code. See
  [Colour and shape](#colour-and-shape) and [Design system](#-design-system).

```
lib/
├── core/
│   ├── alerts/     toast.dart (toasts, the loader, whileLoading), dialogs.dart
│   ├── constants/  env-backed config
│   ├── network/    connectivity monitor
│   ├── services/   tap sounds
│   ├── theme/      the pack layer, colours, spacing, decoration, type
│   └── widgets/    anything used by more than one feature
├── features/
│   ├── auth/        Google sign-in + allowlist claim
│   ├── splash/      the brand lockup while identity restores
│   ├── dashboard/   runner card, roster, shared costs, drawer  ← the main screen
│   ├── advisor_ai/  Gemini deficit analysis
│   └── ledger/      the month per person, admin corrections, monthly settle
├── generated/      asset paths (Assets.svg.*, Assets.lottie.*)
└── services/
    ├── supabase_service.dart      every query and RPC in one place
    ├── identity_service.dart      the signed-in person's app profile
    ├── notification_service.dart  local notification channels
    ├── push_service.dart          FCM token + pings that arrive over push
    ├── analytics_service.dart     Clarity session replay
    └── supabase_target.dart       dormant: a separate project per pack
```

**One widget per file.** A screen file holds its screen and nothing else; every
sub-widget lives in the feature's `widgets/` folder, or in `core/widgets/` the
moment a second feature needs it. The only things that share a file are a
`StatefulWidget` and its `State` (Dart requires it), a model and its own enums,
and private render helpers with exactly one caller.

### Domain vocabulary in code

The models are named for what they are, not for lunch. The **JSON keys are
still the original columns**, so the app reads and writes the live schema with
no migration:

| Dart | Column | Means |
|---|---|---|
| `ActivitySession` | `sessions` | One occurrence — a day's lunch, a match |
| `RosterEntry.contribution` | `dish_name` | What a person put in |
| `RosterEntry.covers` | `portions` | How far it stretches |
| `RosterEntry.unitsTaken` | `rotis_needed` | How many of the bulk item they take |
| `ActivitySession.totalUnits` | `total_rotis` | Bulk item to buy |
| `ActivitySession.totalUnitCost` | `total_roti_cost` | What it cost, once the month is settled |
| `ActivitySession.runnerId` | `tandoor_runner_id` | Who's fetching it |
| `SharedExpense` / `ExpenseShare` | `extra_orders` / `extra_order_shares` | A cost and its members |
| `ExpenseStatus` | `extra_orders.status` | pending / confirmed / cancelled |
| `TransactionType.units` | `'roti'` | Ledger row for the per-unit split |
| `TransactionType.sharedExpense` | `'extraFood'` | Ledger row for a shared cost |

In Dart it's always *expense*; only the database and the RPCs still say
*order* (`create_extra_order`, `respond_to_extra_order`, `p_order_id`).

`TransactionType` carries an explicit `wire` value for exactly this reason — the
CHECK constraint on `transactions.type` hasn't moved yet, and the enum names
shouldn't have to wait for it.

Three sets of strings are load-bearing and so are deliberately still
food-flavoured: the DB column and RPC names above, the `TransactionType` wire
values, and the Android notification channel ids (`lunch_arrival_channel`,
`shared_order_channel` and friends). Android binds channel ids at install, so
renaming one orphans the channel on every device that already has the app.

---

## 🎨 Design system

Neo-Brutalist. Everything is a "bento tile": a solid fill inside a hard
boundary, sitting on a hard shadow. Five rules carry the whole look.

**1. Every container has an ink stroke.** `AppColors.ink` is the load-bearing
token. There are no hairlines — a border is either the full stroke or it isn't
there. `AppDecor.stroke` / `AppDecor.card()` apply it, at the weight the
running pack's `PackShape.strokeWidth` asks for.

**2. Depth is one of three readings, never a smudge.** `AppShadow` renders
`ShapeDepth.soft`, `.hard` or `.flat` — see [Colour and shape](#colour-and-shape).
Under `hard` it returns solid, fully opaque ink rectangles at `blurRadius: 0`.
There is no gradient, glow or `BackdropFilter` anywhere in `lib/`; if you need
one, the design is wrong, not the rule.

**3. Tinted fills must be opaque.** This is the one that bites. A translucent
fill sitting on a 100%-opaque ink shadow lets the black show straight through
and turns the element into a dark smear. Always blend instead of alpha:

```dart
color: AppColors.tint(accent, 0.24)   // ✅ flattened onto the surface
color: accent.withValues(alpha: 0.24) // ❌ shadow bleeds through
```

**4. Raised means tappable; press = travel onto the shadow.** Buttons, chips
and tappable tiles move by the shadow offset and drop the shadow entirely at
the same time, so the element appears to physically press into the page and
pop back out on release. Buttons implement it themselves; tappable tiles get it
from `TactileContainer`, whose `builder` hands a `flat` flag to the decoration
(`AppDecor.card(shadow: !flat)`). The other half of the rule is what makes it
mean anything: a read-only surface — the runner card, roster rows, shared-cost
tiles, the ledger headlines — has no shadow at all (`shadow: false`), so a
raised surface is always a promise that it does something. Disabled elements
sit flat for the same reason.

**5. Nothing is a circle.** Avatars, icon chips, switch knobs, status dots and
progress bars are all squared to `AppRadius.rXs` or tighter. Circles read as a
different design language.

### Type

Two roles. Body and headings use the default sans at heavy weights with tight
tracking (`AppText.h1`–`h3`, `getExtraBoldStyle`). Anything countable — prices,
tallies, dates, caps labels on tiles — uses `getMonoStyle` / `AppText.mono`,
which sets tabular figures so columns of numbers don't shuffle as they update.

> **Not yet done:** the system specifies Hanken Grotesk and JetBrains Mono. No
> font files are bundled and `google_fonts` isn't a dependency, so `getMonoStyle`
> currently approximates the ledger role with tabular figures and wide tracking.
> Adding the real faces means dropping the TTFs into `assets/fonts/`, declaring
> them in `pubspec.yaml`, and setting `fontFamily` in `_getTextStyle` and
> `getMonoStyle` — two functions, no call-site changes.

### Component vocabulary

| Widget | Role |
|---|---|
| `BentoTile` | A caps label and a big tabular figure over an `svgAsset` bled off the bottom-right corner. The ledger headlines. |
| `AppDecor.card()` / `.filled()` / `.tinted()` | White / solid-colour / semantic-colour tile. |
| `AppDecor.well()` | Recessed: stroked but *not* shadowed. Inputs and inset lists. |
| `CustomButton` | Chunky, uppercase, ink-stroked, presses onto its shadow. Uppercasing happens here, not at call sites. If `onPress` returns a `Future` it shows its own busy state. |
| `PillButton` / `Pill` | Tappable chip / static badge. Mono caps, 1px stroke — they sit inside stroked containers, and doubling the stroke turns a tile into a cage. |
| `DashedDivider` | Torn-receipt rule between line items, where a solid line would read as another border. |
| `AppIconButton` | Every icon-only tap target. Square chip, ink stroke, presses onto its shadow. |
| `NeoProgressBar` | Indeterminate busy state. Replaces the Material spinners, whose tapering round stroke is the giveaway that a spinner didn't come from this system. |
| `AppIcon` | Renders one of the app's own SVG marks. See [Icons](#icons). |
| `LottieLoop` | Loops a Lottie without keeping the screen redrawing. See [Lottie](#lottie). |
| `CurrencyPrefix` | The currency marker inside every money field, read from the pack. |
| `PackPickerSheet` | The theme switcher. Each row is drawn in that pack's own colours and geometry, so it previews itself before you tap. |
| `UserAvatar` | A person's photo in a rounded bento box, or their initial. The **only** raster-image site in the app, and it renders through `octo_image`: the monogram is the placeholder *and* the error fallback, so a dead photo URL degrades to an initial, never a broken-image glyph. Add a second image site and route it through the same way. |

### Colour roles

`primaryDeep` fills the brand tile (white text; `textOnBrandMuted` for its
captions). `accentFill` is the warm "appetite" tile (`onAccent` on top), and
the one colour a button on the dark runner card is allowed. `surfacePale` is
the third, informational fill. `primarySoft` is a *wash* for "this row is
yours" — deliberately much lighter than `primaryFixed`, the mid-light brand tone
used for small filled elements, because body copy has to stay readable on top
of it.

### Icons

The app ships its own marks in `assets/svg/`, drawn on a 32×32 grid in the
palette with the same 2px ink stroke as everything else — `roti`, `salan`,
`tandoor`, `runner`, `team`, `receipt`, `sparkle`, `party`, `plate`, `sun`,
`moon` (plus the Google logo and the splash art). Render them with `AppIcon`;
`BentoTile`, `DrawerTile`, `EmptyState` and `HintBanner` each take an
`svgAsset`.

Screens reference the marks directly — `Assets.svg.roti.path`, not a lookup
through the pack. Packs change words and colours, not icons.

These replaced emoji characters (`🥘`, `🫓`, `🔔`, `🥤`), which the platform
renders in full colour with its own soft shading — the one thing on screen that
never matched the flat two-tone tiles around it. Emoji still appear in toasts,
notifications and log lines, where they're text rather than chrome.

Anything *not* domain-specific — sign out, delete, chevrons, camera — stays on a
Material rounded icon. There is no house glyph for those, and inventing one
would be worse than borrowing a good one.

Everything in `assets/` is referenced. When the last use of a file goes, the
file goes too — it used to carry 38 files inherited from a food-delivery
template (social-network Lotties, voucher and coupon SVGs, a delivery rider).

### Lottie

**One Lottie on the dashboard at a time, and never on a ticker.** The runner
card's icon box shows `idle.json` (a robot waiting about) while nobody has the
errand and `runner.json` once somebody does. Both play through `LottieLoop`,
not `Lottie.asset(repeat: true)`.

A repeating Lottie runs on a vsync ticker, so the whole screen redraws 60–120
times a second and re-evaluates every keyframe (the runner is ~2,400 pixel
squares) for as long as it's on screen. That's what warmed the phone.
`LottieLoop` steps frames on a timer at the file's own pace (25 a second for
both), records each frame once and replays it, and stops in the background,
under another route, or with reduced motion on. Any new looping Lottie should
go through it too.

A Lottie is JSON, not SVG — never hand one to `AppIcon`, which is `SvgPicture`
underneath and will throw *"Invalid SVG data"* on every rebuild. `BentoTile.art`
exists so a tile can take an animated mark without pretending it's an SVG.

Elsewhere Lottie survives only where something is genuinely in flight and
briefly on screen: the loading overlay and loader, the no-connection dialog,
and the error state. The splash is the static brand lockup — the same mark,
wordmark and tagline the sign-in screen opens with — over the brand colour,
with one progress bar; it stays only as long as restoring identity takes,
with a short minimum so the entrance can land.

### The drawer

Every drawer row is a `DrawerTile` — a row, not a card. The drawer once held
a column of shadowed, stroked cards, each with an accent rail, a stroked icon
chip, a title, a one-line subtitle and a badge, plus a list of today's
transactions underneath. Every row shouted at the same volume and the menu was
longer than the screen. Three signals now do the work, in order of how fast
they read:

1. **One colour per row: the tinted icon box.** The app's own SVG marks draw
   in their own colours and ignore any tint you hand them, so the box around
   the mark carries the hue; nothing else on the row is coloured.
2. **The trailing slot means something.** A chip is current state (the pack in
   use), a switch is a setting you flip in place, a chevron is somewhere to
   go, and nothing at all is an action that fires right here. Subtitles only
   appear where they add a fact the title doesn't carry.
3. **Section rules.** The two screens come first with no label: Today, filled
   and bold because you are on it, and Ledger (where the month is settled).
   `SETTINGS` is Theme and Dark mode, `DANGER ZONE` is the admin-only reset,
   and Sign out is pinned under a rule at the bottom, above the gesture bar.
   The line running off to the right of each label is what makes a group read
   as a group. The AI check is deliberately not here: it sits on the roster
   header next to the roster it reads.

App places and settings use the app's own marks (tandoor, roti, sparkle,
sun/moon); system actions — reset, sign out — use plain glyphs. The profile
header runs up under the status bar and is one tap target that opens
`EditProfileSheet` for both the photo and the name. Every row reports itself to
screen readers as a button (or, for Dark mode, a switch and its state).

Rows highlight on press rather than travelling onto a shadow: a list of
tappable rows is an affordance people already know, and the press-onto-shadow
move is for tiles.

Accents are picked so no two adjacent rows share a hue **in either pack**:
Today takes the pack primary, Ledger takes `secondary`, Theme and Dark mode
take the pack-neutral `info` teal. Reset is the only `tinted: true` row — the
whole row washes red — and sign out is deliberately the quiet one, grey with no
chip, because leaving isn't destructive.

---

### Session replay

Microsoft Clarity records what people actually did, via `ClarityWidget` at the
very root of the tree in `main.dart`. Root placement is not cosmetic: it sits
*above* the generation-keyed subtree, so switching pack restarts the whole app
without ending the recording. Move it inside `BiteSizeApp` and every theme
change starts a new session.

**It only runs in release builds**, and only when `CLARITY_PROJECT_ID` is set.
The SDK has no debug gate of its own, so without that check every `flutter run`
would upload hot restarts, half-finished features and throwaway roti counts
into the same dashboard real people land in. There is deliberately no fallback
project id either: `dotenv.load` only prints when it fails, so a default would
mean an app that thinks it has no configuration still quietly shipping sessions
somewhere.

Nothing outside `lib/services/analytics_service.dart` imports the SDK. Call
sites go through `Analytics`, which is a no-op whenever a session isn't being
recorded, so no screen has to know whether Clarity is on.

Two things are attached to every session:

* **Who.** `Analytics.identify()` runs from `IdentityService.claim()` with the
  *app* user id — the same `public.users.id` every foreign key uses, so a
  replay can be lined up against the rows it wrote. Without it Clarity invents
  an anonymous id per session, which answers what happened but never to whom.
* **Where.** Routes are pushed as bare `MaterialPageRoute`s with no names, so
  Clarity has nothing to label a screen with. `ScreenName` wraps each view and
  announces it through a `RouteObserver`. It has to be a route observer rather
  than a call in `initState`: popping the ledger leaves the dashboard mounted,
  nothing rebuilds, and the session would otherwise still claim to be on the
  ledger. `didPopNext` is what fixes that.

Masking is **not** a code setting in the Flutter SDK — the level comes from the
project config on clarity.microsoft.com, and `ClarityMask` / `ClarityUnmask`
override it per widget. Replays show display names, the sign-in email and every
amount in the ledger, so choose that level deliberately.

One caveat worth knowing: `android/app/src/main/AndroidManifest.xml` declares
`INTERNET` itself. Debug and profile builds get it from Flutter's own
manifests, but release was only ever inheriting it by merge from
`google_sign_in_android` — dropping that plugin would have taken Supabase,
Gemini, avatars and Clarity offline in one go, in release only.

---

### Two ids, on purpose

`IdentityService` is the only thing that should ever hand out a user id. People
are seeded into `public.users` by email *before* they've ever signed in, so the
app-side `users.id` and the Supabase Auth UID are different values. Every
foreign key points at `users.id`; the Auth UID exists only to look that row up.
Anything writing a `user_id` reads `IdentityService.instance.appUserId`.

### Money is integers

Costs are stored in minor units (`cost_minor`, `amount_minor`) and allocated in
Postgres by largest remainder, so per-person shares always sum back to the bill
exactly. The client never derives a share — it reads the one that was stored.
This is why settle-up can't drift, and why a declined invite can be re-split
safely. How many minor units make one major one is
[the pack's currency](#money), not a hardcoded 100.

---

## 🔐 Security model

The app is a closed allowlist, and Postgres — not Flutter — decides what each
role can do.

- **Seeding** — People exist as rows in `public.users` with an email and a role
  before they can log in.
- **Claiming** — `claim_identity()` binds a verified Google account to its
  seeded row on first sign-in. The email comes from the JWT, never from the
  client, so you can't claim someone else's row by lying about who you are.
  Unseeded email → `not_allowlisted`, and no account is created.
- **RLS** — Enabled on every table. Members write their own entry; admins assign
  the runner, settle the month and move ledger rows. Column-level rules that
  RLS can't express (e.g. "anyone may announce arrival, but only an admin may
  change the runner or settle") are enforced by `BEFORE UPDATE` triggers.
- **Privileged writes go through RPCs** — `create_extra_order()`,
  `respond_to_extra_order()`, `depart_for_tandoor()`, `send_ping()` and
  `ensure_session()` are `SECURITY DEFINER` and act strictly on behalf of
  `current_app_user()`. Direct inserts into `extra_order_shares` are blocked,
  because a client could otherwise invent an allocation that doesn't sum to the
  bill.
- **Config** — In `.env`, loaded by `flutter_dotenv`, with nothing hardcoded.
  Note that `.env` is declared as an asset, so it **ships inside the app**:
  nothing in it is truly secret. The Supabase anon key is public by design (RLS
  is the protection); the Gemini key can be pulled out of an APK, so restrict
  it to the app in Google Cloud.

The pack is *not* a security boundary. It decides what the app draws, not what
Postgres will accept — a client running a pack with `errand` switched off could
still call `depart_for_tandoor()`, and RLS is what stops it mattering.

---

## 🗄️ Database

`docs/supabase_schema.sql` is the **original** schema and is no longer the whole
picture. Apply the numbered files in `docs/migrations/` on top of it, in order.
All of them are safe to re-run.

| Migration | What it adds |
|---|---|
| `001_roles_and_rls.sql` | Roles, `auth_uid`, `claim_identity()`, RLS on every table, the allowlist seed |
| `002_session_write_guards.sql` | Trigger restricting runner assignment and settling to admins |
| `003_shared_orders.sql` | `extra_order_shares`, minor-unit amounts, largest-remainder allocation |
| `004_ensure_session.sql` | `ensure_session()` — a shared cost can be the first thing logged today |
| `005_order_invites.sql` | Invite/accept/decline on shares, the cost lifecycle, `depart_for_tandoor()` and the departure lock |
| `006_pings.sql` | The `pings` table, `send_ping()` (resolves the recipient by email server-side, 30-second rate limit), realtime |
| `007_pack_sessions.sql` | `ensure_session()` reads the date off the end of a pack-prefixed id, so each pack gets its own session per day |
| `008_ping_ensures_session.sql` | `send_ping()` calls `ensure_session()` first, so a ping can be the first thing logged today without tripping the `pings → sessions` FK |
| `009_ping_target_in_db.sql` | `users.is_ping_target` (one row only, admin-only to move) replaces `PING_TARGET_EMAIL`, and `send_ping()` resolves the recipient itself |
| `010_ping_no_cooldown.sql` | `send_ping()` drops the 30-second rate limit — pings are meant to be repeated |
| `011_entries_lock_on_departure.sql` | `entries` refuse member writes once the runner has departed (`runner_already_left`), mirroring the `extra_orders` guard from 005 — the roster locks on departure, never on the clock |
| `012_ping_push_webhook.sql` | AFTER INSERT trigger on `pings` that posts the row to the `ping-push` Edge Function, which sends it over FCM — a ping reaches a phone whose app is closed |
| `013_no_run_without_rotis.sql` | `depart_for_tandoor()` refuses while the day's `total_rotis` is 0 (`no_units_to_buy`). Optional: the app already greys the button out; this also stops older builds |

The client creates a day only through `ensure_session()` — adding an entry,
assigning a runner, an admin correcting the ledger, a shared cost or a ping —
never with a direct insert.

No migration was needed for activity packs or for monthly settling: the pack
lives in `.env` and the Dart models map their neutral field names onto the
existing columns, and admins could always write a day's cost and status.

---

## ⚠️ Not yet generic: one group per install

`sessions.id TEXT PRIMARY KEY` is a date — `yyyy-mm-dd`, or since 007
`<pack_id>:yyyy-mm-dd` — and that is the whole tenancy model. It buys the free
midnight reset, and it costs:

- Two groups can't share a database — there is one session per pack per
  calendar day for the entire schema.
- ~~One group can't run two activities on the same day.~~ Closed by 007: each
  pack keys its own session, so a cricket cost can't land on the lunch roster
  and resetting one pack's day leaves the other's alone.
- An ad-hoc pack still keys by date, so a group can't hold two matches in a day.

Closing that is the next migration, and it does not change any call site that
reads a label:

```sql
groups        id, name, currency_code, minor_exponent, timezone
group_members group_id, user_id, role            -- replaces users.role
activities    id, group_id, pack_id, config JSONB -- the pack, per group
sessions      id UUID, group_id, activity_id, occurs_on DATE, ...
              UNIQUE (activity_id, occurs_on)     -- keeps the free daily reset
```

`PackService.loadFromEnv()` becomes a read of `activities.config` — the JSON
shape is already the one `ActivityPack.fromJson` accepts, which is why
`ACTIVITY_PACK_JSON` exists at all. The same migration is the right moment to
rename the food-flavoured columns (`dish_name` → `contribution`, `rotis_needed`
→ `units_taken`, `total_rotis` → `total_units`, `tandoor_runner_id` →
`runner_id`, `extra_orders` → `shared_expenses`) and the `transactions.type`
CHECK values, since both need a coordinated data migration anyway.

---

## 🔔 Pings are push; everything else is local

A ping has to land on a phone whose app is closed, so it is the one alert
that goes out over Firebase Cloud Messaging. Two states, one rule:

| App is… | What happens |
|---|---|
| on screen | The phone buzzes and the app shows it. Nothing in the notification centre. |
| backgrounded or closed | The notification centre, with sound, on the `ping_channel` channel. |

How it flows: `send_ping()` inserts a row → the trigger from migration 012
posts it to the `ping-push` Edge Function (`supabase/functions/ping-push`) →
the function reads the recipient's `users.fcm_token` and sends one
high-priority FCM message. On the phone, `PushService` keeps `fcm_token`
current for whoever is signed in and relays a foreground push to the dashboard,
which presents it exactly as it presents a ping off the realtime stream —
deduped by id, so whichever path arrives first wins.

A checkout with no `android/app/google-services.json` still builds and runs;
push is simply off, and a backgrounded app falls back to a local notification.

**Turning it on** (once per project):

1. Firebase console → create or open a project → add an Android app with
   package `com.bootlegcorp.bitesize` → download `google-services.json` into
   `android/app/`. iOS additionally needs an APNs key uploaded to Firebase and
   `GoogleService-Info.plist` in `ios/Runner/`. Both files are gitignored.
2. Project settings → Service accounts → generate a private key. Store it as
   the `FCM_SERVICE_ACCOUNT_JSON` secret on Supabase, verbatim, and don't leave
   the downloaded file in the repo.
3. Pick a long random string. Store it twice under two names: as the
   `PING_WEBHOOK_SECRET` secret on the Edge Function, and in Vault with
   `SELECT vault.create_secret('<the string>', 'ping_webhook_secret');`.
4. Deploy `ping-push` with JWT verification off (`supabase/config.toml`
   already says so), then run migration 012. After a test ping,
   `net._http_response` holds the function's answer; the tail of the
   migration file says what each status means.

Everything else — invites, answers, arrival, departure — is still a local
notification fired from a realtime stream, so it needs the app running to be
instant. The in-app gate is unaffected either way: the runner is blocked by the
database, not by whether a notification was delivered.

---

## ⚙️ Getting started

### Prerequisites

- Flutter SDK (Dart `^3.11.0`)
- A Supabase project with `docs/supabase_schema.sql` and every migration in
  `docs/migrations/` applied in order (013 is optional)
- Google Cloud OAuth credentials (Web + iOS client IDs)
- A Gemini API key (only if your pack has the `advisor` module on)
- Optional: a Firebase project, for pings that reach a closed phone

### Setup

1. **Dependencies**

   ```bash
   flutter pub get
   ```

2. **Create `.env` in the project root.** It's declared as an asset in
   `pubspec.yaml` and loaded at startup — it is *not* passed via
   `--dart-define` — and it's gitignored.

   ```dotenv
   SUPABASE_URL=https://xxxx.supabase.co
   SUPABASE_ANON_KEY=...
   GEMINI_API_KEY=...
   GOOGLE_WEB_CLIENT_ID=....apps.googleusercontent.com
   GOOGLE_IOS_CLIENT_ID=....apps.googleusercontent.com

   # Optional. Which activity pack a FRESH install starts as; defaults to
   # office_lunch. A person's own choice in drawer → Theme overrides it and
   # is remembered on the device. ACTIVITY_PACK_JSON takes a whole inline pack.
   ACTIVITY_PACK=office_lunch

   # Optional. Microsoft Clarity session replay. Release builds only, and
   # omitting it turns replay off rather than falling back to a default.
   CLARITY_PROJECT_ID=...

   # Seed only, read by migration 001 and by nothing at runtime.
   ADMIN_EMAIL=you@example.com
   ```

   Admin is `public.users.role` and the ping target is
   `public.users.is_ping_target` — both are changed with an `UPDATE` in
   Supabase, never by rebuilding. Read them in code via
   `IdentityService.instance.isAdmin` and `DashboardViewModel.pingTarget`,
   never by comparing emails.

   Both packs share one Supabase project, kept apart by the pack prefix on
   `sessions.id`. `GROUND_SUPABASE_URL` / `GROUND_SUPABASE_ANON_KEY` would give
   `ground_booking` a project of its own (`supabase_target.dart`), but leave
   them out: auth is per project, so switching pack would sign people out.

3. **Seed yourself into the allowlist.** Migration 001 seeds three accounts; add
   your own row to `public.users` (email + `role`) or you will be refused at
   sign-in with `not_allowlisted`.

4. **Optional: push for pings.** Follow
   [Turning it on](#-pings-are-push-everything-else-is-local).

5. **Run**

   ```bash
   flutter run
   ```

   Notification channels bind natively at first launch — if alerts don't appear
   after a hot restart, do a full `flutter run` again.

`flutter analyze` should report no errors or warnings; the handful of infos
left are in `activity_packs.dart`, `app_colors.dart`, `app_theme.dart` and the
generated `assets.dart`.

---

## 🧭 Conventions worth knowing before you edit

- **No domain word as a literal in `lib/features/`.** Ask the pack:
  `PackService.labels.unitPlural`, not `'rotis'`. If the pack has no word for
  what you need, add a field to `PackLabels` with a colourless default — that's
  the point of the class.
- **Icons are direct.** `Assets.svg.roti.path`, not a lookup through the pack.
  When the last use of an asset goes, delete the file.
- **Gate a feature on its module, not on whether the data happens to be empty.**
  `if (PackService.modules.errand)`, not `if (session.runnerName != null)`.
- **Call it an expense.** `SharedExpense`, `expenseId`, `removeSharedExpense` —
  never `order` in Dart. The database names stay as they are.
- **Never format money by hand.** `PackService.currency.format(minorUnits)`.
  `/ 100` is wrong in three currencies and a symbol string is wrong in most.
- Never mint a `users` row from the client. Seeding and `claim_identity()` own
  that; auto-creating one would let anyone who authenticates add themselves to
  the roster, which is exactly what the allowlist prevents.
- Never create a `sessions` row from the client either — call
  `ensure_session()`.
- Never compute a share on the client. Call the RPC and read back what Postgres
  allocated.
- **Nothing locks on the clock.** The roster and the day's costs lock when the
  runner leaves, and only then.
- **A greyed-out button must say why it's greyed out.** See
  `departureBlockReason`.
- **Loader and toast around an action:** `ShowToastDialog.whileLoading(message,
  action, success: ...)`. The action returns an error string or null.
- **Never loop a Lottie with `repeat: true`.** Use `LottieLoop`.
- **Read-only surfaces don't get a shadow.** Pass `shadow: false`; only things
  you can tap are raised.
- New spacings go in `lib/core/theme/`, not inline. New *brand* colours and
  radii go in `PackPalette` / `PackShape` — `lib/core/theme/` holds the chassis
  and reads the rest from the pack, so a hex literal added to `AppColors` is a
  colour that can never be themed.
- Don't attach a long-lived `GlobalKey` to a widget inside the app tree. The
  theme restart works by discarding that tree, and Flutter reparents
  global-keyed elements instead of rebuilding them — anything holding one
  survives the restart still wearing the old theme. `appNavigatorKey` is the
  only one, and it is reissued on purpose.
- RPCs raise bare codes (`not_allowlisted`, `orders_not_finalized:2`,
  `no_units_to_buy`) so they stay greppable in Postgres logs. They're
  translated into sentences in one place per feature —
  `IdentityError.fromMessage` for auth, `DashboardViewModel._errorMessages` /
  `_readableError` for the dashboard, which is a getter rather than a `const`
  map precisely so it can name what *this* pack calls things.
- Never tint with alpha on a surface that carries a shadow — use
  `AppColors.tint()`. See [Design system](#-design-system), rule 3.
