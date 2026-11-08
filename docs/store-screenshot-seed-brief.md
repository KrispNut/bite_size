# Brief for Antigravity: seed dummy data for Play Store screenshots, then clean up

You have the Bite Size **production** Supabase project. It's the only database, and real colleagues use it. Claude is driving the Android app on a phone to capture 7 store screenshots, and needs some dummy data in place first. Everything below must be **fully reversible**: back up anything you change, tag everything you add, and the cleanup must leave the database exactly as it was.

Today's date is **2026-10-19** (Asia/Karachi). The lunch session id for today is `'2026-10-19'`. The cricket pack's session id is `'ground_booking:2026-10-19'`.

There are two phases: **SETUP** (run now) and **CLEANUP** (run only when the user says "cleanup").

---

## Before anything: inspect, don't guess

1. Read the live columns of `public.users`, `public.sessions`, `public.entries`, `public.extra_orders`, `public.extra_order_shares` and `public.transactions`, plus the triggers on `sessions` and `entries`. The repo's `docs/migrations/*.sql` describe the intent, but the live schema wins. Adapt the SQL below to the real column names. In particular, confirm these exist:
   - `users`: `auth_uid`, `role`, `is_active`
   - `sessions`: `runner_departed_at`, `arrived_at`, `arrived_by_name`
   - `extra_orders`: `status`, `cost_minor`, `created_by`
   - `extra_order_shares`: `status`, `amount_minor`, `weight`
2. Find **the phone's account**: the `users` row named `Sickmojas F`. Call its id `ME`.
3. List every other real user (id, name, role, is_active). Report the names in your summary.

## SETUP

Run it as one transaction where possible. Use a private schema, so nothing is exposed to the app's API:

```sql
create schema if not exists shot_backup;
```

### 1. Back up everything you are about to change

- `shot_backup.users`: a full copy of every **existing** `users` row (all columns).
- `shot_backup.sessions`: full copies of the rows `'2026-10-19'` and `'ground_booking:2026-10-19'`, if they exist. Also record in a small table whether each existed (`existed boolean`).
- `shot_backup.today_entries`: a copy of all `entries` rows for those two session ids, if any.
- `shot_backup.today_orders`: the `extra_orders` (and their `extra_order_shares`) for those two session ids, if any.

### 2. Make the phone account presentable and an admin, temporarily

```sql
update public.users set name = 'Ali', role = 'admin' where id = ME;
```

The original name and role are in `shot_backup.users`.

### 3. Keep real colleagues' names off a public listing, temporarily

For every **other existing** user, set `name` to a neutral first name (e.g. `Raza`, `Faisal`, `Kamran`…, one each). Don't touch `is_active`: disabling accounts would lock colleagues out. Originals are in the backup.

### 4. Dummy people (all tagged by email)

Insert 11 users with `auth_uid = null`, `role = 'member'`, `is_active = true`, and email `<lowercase name>@shot.bitesize.invalid`:

`Sara, Hina, Bilal, Umar, Shan, Talha, Usman, Waqas, Yasir, Zain, Zubair`

### 5. A finished past month for the ledger shot (August 2026)

First check that **no** sessions exist for `2026-08-%`. If any do, stop and report.

For every weekday of August 2026 (21 days), insert a session:
- id `'2026-08-DD'`, date that day, cutoff that day at 13:00 +05
- `status = 'settled'`
- `total_roti_cost = total_rotis * 25`

Give each session entries for **ME and the 11 dummies**: `rotis_needed` 1–4 (ME mostly 2–3), and `dish_name` from:

`Daal mash, Chicken karahi, Aloo gobi, Keema, Biryani, Chana, Mix sabzi, Haleem, Raita, Nothing`

`portions` is 1, or 0 when the dish is `Nothing`. Make the session `total_rotis`/`headcount` match the entries (the triggers may do this; verify).

Don't insert into `transactions` unless the ledger needs it to show costs. The app's ledger computes cost from `sessions.total_roti_cost / total_rotis`.

### 6. Today's lunch session `'2026-10-19'`

Create it if missing (the `ensure_session` function, or a plain insert).

Leave it in the starting state:
- `status = 'open'`
- no runner (`tandoor_runner_id`/`name` null)
- `runner_departed_at` and `arrived_at` null

Entries (ME has **no** entry; Claude adds it on the phone):

| user | dish_name | portions | rotis_needed |
|---|---|---|---|
| Sara | Chicken karahi | 1 | 2 |
| Hina | Aloo gobi | 1 | 3 |
| Bilal | Nothing | 0 | 4 |
| Umar | Keema | 1 | 3 |

Make session totals match.

### 7. One shared meal that needs ME's answer (today, lunch)

`extra_orders` row:
- `session_id = '2026-10-19'`
- `description = 'Extra salan'`
- `cost = 480`, `cost_minor = 48000`
- `paid_by_id`/`paid_by_name` = Bilal
- `created_by` = Bilal
- `split_mode = 'equal'`
- `status = 'pending'`
- `shared_by_ids` = [Bilal, Sara, ME] if that column still exists

`extra_order_shares`:

| user | status | amount_minor |
|---|---|---|
| Bilal | accepted | 24000 |
| Sara | accepted | 24000 |
| ME | pending | 0 |

Follow the app's rule that accepted shares add up to the cost.

### 8. The cricket pack session `'ground_booking:2026-10-19'`

- Payer = Bilal (`tandoor_runner_id`/`tandoor_runner_name`)
- `total_rotis = 2` (here that means 2 hours)
- `status = 'open'`, not departed

One confirmed shared cost on it:
- `description = 'Pitch, 2 hours'`
- `cost = 6000`, `cost_minor = 600000`
- paid by Bilal
- `status = 'confirmed'`

Shares: all 11 dummies plus ME, each `accepted`, `amount_minor = 50000`.

### 9. Report back

When everything is in, print **`SETUP DONE`** with:
- ME's id
- how many dummy users, August sessions and entries were created
- the backed-up original names of real users (the user may want to know)
- whether today's sessions already existed

## What Claude does next on the phone (no DB action from you)

Claude accepts the salan invite, adds ME's own entry, assigns the runner, locks the list, taps "Food arrived" and opens (but **never confirms**) the "Settle October" sheet. The app writes those changes itself. Cleanup removes them too.

---

## CLEANUP (only when the user says "cleanup")

Restore exactly, then drop the backup.

1. **Today's sessions** (`'2026-10-19'`, `'ground_booking:2026-10-19'`):
   - Delete all `extra_orders` (shares cascade), `entries` and `transactions` on them.
   - If the session **did not exist** before setup, delete the session row.
   - Otherwise, restore the row from `shot_backup.sessions` and re-insert the backed-up entries and orders.
2. **August 2026:** delete the sessions created in step 5 (entries cascade) and any `transactions` on them.
3. **Settle check:** if any `transactions` reference dummy users or the sessions above, delete them. The settle button should never have been pressed; report if it was.
4. **Dummy users:** delete `users` where `email like '%@shot.bitesize.invalid'`. Their entries and shares cascade.
5. **Real users:** restore `name`, `role` and every other column from `shot_backup.users` (ME back to `Sickmojas F` and its original role; colleagues back to their real names).
6. **Verify:**
   - Compare `users` with the backup row-for-row (excluding nothing).
   - Confirm no rows reference the dummy ids.
   - Confirm `2026-08-%` has no sessions.
7. `drop schema shot_backup cascade;` and print **`CLEANUP DONE`** with the verification results.
