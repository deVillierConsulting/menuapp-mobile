# Data Model Changes — IA v2

Based on the six flow docs and the current SQLAlchemy models. Organized by what's new, what's modified, and what's fine as-is.

---

## Summary of gaps

| Gap | Root cause | Fix |
|---|---|---|
| No invite token system | Invite flow was manual/out-of-band | New `group_invite` table |
| No push token storage | APNs not wired | New `device_token` table |
| No subscription/paywall state | Free app in V1 | New `group_subscription` table |
| `VoteValue` has three values but design is binary | Holdover from earlier design | Collapse `yes`/`no`/`veto` → `approve`/`veto` |
| No group-level meal default | Default only lived on Menu | Add `meals_per_week` to `Group` |
| Notification types don't cover v2 events | Enum predates invite + push flows | Add four new notification types |
| `Vote` has no timestamp | Omission | Add `voted_at` column |

---

## New tables

### `group_invite`

Backs the invite link/QR flow in flow-06. A token is generated when the owner taps any share surface; the deep link carries it; the recipient's app calls a join endpoint with the token.

```
group_invite_id   INTEGER PK
group_id          FK → group.group_id CASCADE
created_by        FK → user.user_id SET NULL
token             VARCHAR(64) UNIQUE NOT NULL   ← random URL-safe string
expires_at        TIMESTAMP NOT NULL            ← created_at + 7 days
used_at           TIMESTAMP nullable
used_by_user_id   FK → user.user_id SET NULL nullable
```

Rules:
- A group can have multiple active invite links (owner refreshes mid-flow).
- Joining invalidates that token (`used_at` = now, `used_by_user_id` = joiner).
- Expired or used tokens → 410 Gone.
- GET `/groups/{id}/invite` returns or creates an active token.
- POST `/invites/{token}/join` creates a Member row and marks the token used.

---

### `device_token`

Stores APNs device tokens for push notifications. One user can have multiple tokens (multiple devices, token rotation after reinstall).

```
device_token_id   INTEGER PK
user_id           FK → user.user_id CASCADE
token             VARCHAR(255) UNIQUE NOT NULL   ← APNs device token
platform          VARCHAR(10) NOT NULL           ← 'ios' for now; 'android' later
device_id         VARCHAR(255) nullable          ← identifierForVendor (helps dedup on reinstall)
created_at        TIMESTAMP NOT NULL
last_seen_at      TIMESTAMP NOT NULL             ← updated on each app launch
```

Rules:
- On each app launch (or foreground), the mobile client calls POST `/users/me/device-token` with the current APNs token. Upsert on `token`; update `last_seen_at`.
- Tokens older than 90 days with no `last_seen_at` update are pruned by a background job (APNs returns a 410 when a token is stale — catch that in the send path too).
- The push-send service always fans out to all of a user's active tokens; device dedup is Apple's problem.

---

### `group_subscription`

Tracks billing state for the paywall. One row per group. Kept separate from `Group` to avoid cluttering the core model with billing fields.

```
subscription_id        INTEGER PK
group_id               FK → group.group_id CASCADE UNIQUE
stripe_subscription_id VARCHAR(255) nullable    ← null during trial before Stripe sync
status                 ENUM('trialing','active','past_due','canceled')
trial_ends_at          TIMESTAMP nullable
current_period_end     TIMESTAMP nullable
canceled_at            TIMESTAMP nullable
created_at             TIMESTAMP NOT NULL
updated_at             TIMESTAMP NOT NULL
```

Rules:
- Created automatically when a group is created (status = `trialing`, trial_ends_at = +7 days).
- A Stripe webhook handler updates this row when billing events arrive.
- When `status` is `canceled`, the group becomes read-only: no new menus, no voting. Existing history and the recipe library remain accessible.
- Services check subscription status via a lightweight helper — no billing logic in routers.

---

## Modified tables

### `Group` — add `meals_per_week`

The creation form (flow-06, screen 02) captures a weekly meal goal at the group level. This becomes the default when a new menu is created; individual menus can still override via `planned_meal_count`.

```diff
+ meals_per_week  INTEGER NOT NULL DEFAULT 4
```

Migration: `ALTER TABLE "group" ADD COLUMN meals_per_week INTEGER NOT NULL DEFAULT 4;`

---

### `Vote` — add `voted_at`, fix enum

**Add timestamp:**
```diff
+ voted_at  TIMESTAMP NOT NULL DEFAULT now()
```
Needed for "last voted" display (home screen waiting state, flow-01 state 4) and analytics.

**Collapse `VoteValue` enum:**

Current: `yes | no | veto`  
New: `approve | veto`

The design settled on binary swipe-to-vote — right = approve, left = veto. "Skip" is gone. `no` and `veto` were doing the same job; collapse them.

Migration path (requires two steps to avoid locking issues with an in-use enum):
1. Add `approve` value to the enum.
2. `UPDATE vote SET vote_value = 'approve' WHERE vote_value = 'yes';`
3. `UPDATE vote SET vote_value = 'veto' WHERE vote_value = 'no';`
4. Drop `yes` and `no` from the enum (Postgres: requires recreating the type).

Since dev data is disposable, we'll drop and recreate.

---

### `NotificationType` enum — four new values

Current: `vote_requested | menu_finalized | recipe_added | new_member`

Add:

| New value | Trigger | Recipient | Push? |
|---|---|---|---|
| `invite_received` | Owner generates an invite and shares it | The person who taps the link (shown in-app on join confirmation) | No — they're already in the app |
| `partner_voted` | A group member finishes voting on all current menu recipes | All other members who haven't finished | Yes — "Your turn to vote" |
| `menu_ready_to_finalize` | All members have voted and threshold can be met | Group owner | Yes — "Your menu is ready" |
| `pool_exhausted` | A member has voted on every available recipe but meal target isn't met | That member | In-app only (they're staring at the screen) |

The existing `vote_requested` covers the initial nudge when a menu moves from `draft` to `active`. `partner_voted` is a follow-up reminder; they're different events.

---

## Things that are fine as-is

- **`Member`** — no role field needed; owner identity stays on `Group.owner_id`. Adding a role would require promoting/demoting members, which isn't in scope.
- **`Menu`** — `status` enum (`draft | active | final`), `planned_meal_count`, `start_date`/`end_date` all survive unchanged. Auto-naming ("Week of Jul 14") is service logic, not a schema change.
- **`MenuRecipe`** — `added_by_user_id` already tracks who added each recipe to the picker. No changes.
- **`User`** — `supabase_uid` already handles Apple Sign In identity. No changes beyond push token (handled by the new `device_token` table).
- **`Notification`** — the generic `reference_id` + `reference_type` pattern is flexible enough to point at any entity (menu, invite, etc.). No structural changes.

---

## Migration order

Because of foreign key constraints, create in this order:

1. Modify `VoteValue` enum (no FK dependencies)
2. Modify `NotificationType` enum (no FK dependencies)  
3. Add `meals_per_week` to `Group`
4. Add `voted_at` to `Vote`
5. Create `group_subscription` (depends on `group`)
6. Create `group_invite` (depends on `group`, `user`)
7. Create `device_token` (depends on `user`)

---

## Open questions

**Veto threshold display:** `Group.threshold` currently stores an integer count. The UI shows "votes needed to confirm." Does threshold mean "approvals needed" or "minimum approvals to override a veto"? These are different semantics. Clarify before the finalization algorithm is written.

**Subscription before invite:** If the owner invites someone before Stripe is integrated, do we gate on `group_subscription.status` or skip the check in dev? Recommend a feature flag or a `SKIP_SUBSCRIPTION_CHECK` env var for dev, so the invite flow can be tested without Stripe.

**Multi-group future:** Nothing here prevents a user from owning multiple groups (each with its own subscription). The model already supports it. Whether the UI exposes it is a product decision, not a schema decision.
