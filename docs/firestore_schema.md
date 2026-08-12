# Bite Size — Firestore Database Schema

## Design principles

1. **The date IS the session ID.** A session document lives at `sessions/{yyyy-MM-dd}`
   (e.g. `sessions/2026-07-17`). This gives us the "daily reset" for free — no cron
   job, no cleanup. The app simply reads the doc whose ID is today's date; if it
   doesn't exist yet, today's lunch hasn't started.
2. **The user ID IS the entry ID.** Each roster entry lives at
   `sessions/{date}/entries/{uid}`. One entry per person per day is enforced by the
   document model itself — re-submitting is an upsert, never a duplicate.
3. **Denormalized aggregates on the session doc.** `headcount`, `totalPortions` and
   `totalRotis` are stored on the session document and updated in the *same Firestore
   transaction* that writes an entry. The dashboard renders from a single document
   listener instead of summing a collection on every frame.
4. **Money is an audit trail + a running balance.** Every debt is an immutable
   `transactions` document; each user's `balance` field is the running net, updated
   in the same batch. You can always rebuild a balance from the transaction log.

---

## Collections

### `users/{uid}`

One doc per coworker, keyed by Firebase Auth UID.

| Field       | Type      | Notes                                              |
|-------------|-----------|----------------------------------------------------|
| `name`      | string    | Display name shown on the roster                   |
| `email`     | string    |                                                    |
| `photoUrl`  | string?   |                                                    |
| `fcmToken`  | string?   | For "we're short on salan" push notifications      |
| `balance`   | number    | Running net in Rs. **positive = group owes them**, negative = they owe the group |
| `isActive`  | bool      | Soft-delete for people who leave the office        |
| `createdAt` | timestamp |                                                    |

### `sessions/{yyyy-MM-dd}`

One doc per working day. Created lazily by the first person who adds an entry.

| Field              | Type      | Notes                                                  |
|--------------------|-----------|--------------------------------------------------------|
| `date`             | timestamp | Midnight local time of the day                         |
| `cutoffAt`         | timestamp | Default 12:30 PM; entries lock after this              |
| `status`           | string    | `open` → `locked` (post-cutoff) → `settled` (ledger done) |
| `tandoorRunnerId`  | string?   | UID of whoever claimed the run (null = unclaimed)      |
| `tandoorRunnerName`| string?   | Denormalized for display                               |
| `headcount`        | number    | Aggregate: count of entries                            |
| `totalPortions`    | number    | Aggregate: sum of `entries.portions`                   |
| `totalRotis`       | number    | Aggregate: sum of `entries.rotisNeeded` — **the Bite Size** |
| `totalRotiCost`    | number?   | Entered by the runner after the tandoor run            |
| `createdAt`        | timestamp |                                                        |
| `updatedAt`        | timestamp |                                                        |

**Deficit Detector** is computed client-side, never stored:
`deficit = headcount - totalPortions`. Positive → we're short on salan.

#### Subcollection `sessions/{date}/entries/{uid}`

| Field         | Type      | Notes                                    |
|---------------|-----------|------------------------------------------|
| `userId`      | string    | Same as doc ID (kept for collectionGroup queries) |
| `userName`    | string    | Denormalized for display                 |
| `dishName`    | string    | "Aloo gosht", "Daal", …                  |
| `portions`    | number    | How many people their salan can feed     |
| `rotisNeeded` | number    | Rotis this person will eat               |
| `createdAt`   | timestamp |                                          |
| `updatedAt`   | timestamp |                                          |

#### Subcollection `sessions/{date}/extraOrders/{autoId}`

Created when the deficit poll ends in "order extra food".

| Field         | Type      | Notes                                        |
|---------------|-----------|----------------------------------------------|
| `description` | string    | "2x chicken karahi from Al-Madina"           |
| `cost`        | number    | Rs.                                          |
| `paidById`    | string    | Who fronted the money                        |
| `paidByName`  | string    |                                              |
| `sharedByIds` | string[]  | Who's splitting it (poll opt-ins). Split evenly. |
| `createdAt`   | timestamp |                                              |

### `transactions/{autoId}` (top-level)

Immutable ledger entries. Top-level (not under a session) so a user's history
is one indexed query across all days.

| Field       | Type      | Notes                                                   |
|-------------|-----------|---------------------------------------------------------|
| `sessionId` | string    | `yyyy-MM-dd` it came from (empty for settlements)       |
| `type`      | string    | `roti` \| `extraFood` \| `settlement`                   |
| `fromId`    | string    | Debtor UID                                              |
| `fromName`  | string    |                                                         |
| `toId`      | string    | Creditor UID (runner / payer / person being paid back)  |
| `toName`    | string    |                                                         |
| `amount`    | number    | Rs., always positive; direction is from → to            |
| `note`      | string    | "4 rotis @ Rs. 30"                                      |
| `createdAt` | timestamp |                                                         |

---

## The money math (settlement)

Run once per session when the runner enters costs (a batched write):

1. **Rotis — individual split.** Each participant owes
   `rotisNeeded / totalRotis * totalRotiCost` to the runner.
   One `roti` transaction per participant (skip the runner themselves),
   plus `balance` increments: debtor `-share`, runner `+share`.
2. **Extra food — even split among opt-ins.** For each extra order:
   `cost / sharedByIds.length` per head, owed to `paidById`.
3. **Settlement.** When two people square up in cash, write a `settlement`
   transaction in the opposite direction and adjust both balances back
   toward zero. Balances mean nobody handles change daily — clear weekly.

## Security rules sketch

```
users/{uid}          read: signed-in;  write: only own doc (never `balance` directly — settlement via trusted client batch or Cloud Function)
sessions/{date}      read: signed-in;  create/update: signed-in (aggregates via transaction)
  entries/{uid}      read: signed-in;  write: request.auth.uid == uid && session.status == 'open'
  extraOrders/{id}   read: signed-in;  create: signed-in
transactions/{id}    read: signed-in;  create: signed-in; update/delete: never (immutable)
```

## Indexes

Default single-field indexes cover everything at this scale. Add one composite
index only if you query transaction history filtered + ordered
(`fromId == X orderBy createdAt desc` — Firestore will prompt with a link).
