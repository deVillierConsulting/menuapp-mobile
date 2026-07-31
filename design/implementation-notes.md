# MenuApp Mobile — Implementation Notes

Design decisions that have specific Flutter implementation constraints.
Written alongside the HTML flow docs; referenced when building each screen.

---

## Voting Tutorial — Animated Demo Card

**Applies to:** `lib/ui/home/` (the voting state on the Home screen)
**Related flow:** flow-01-home.html · State 03a

### What it is
Before the first real recipe card is shown, play a ~2.5s animated demo that teaches the swipe mechanic. A placeholder card auto-drags right (approve), flies off, a second auto-drags left (veto), flies off, then the first real card slides in.

### Flutter approach

- **Widget type:** `StatefulWidget` with `TickerProviderStateMixin`
- **Do NOT put this in the cubit.** The tutorial is a purely local UI concern — it has no business logic, makes no API calls, and produces no state that other widgets care about.
- **Gate:** Check `SharedPreferences` for `'hasSeenVoteTutorial'` in `initState`. If `true`, skip straight to the real card stack. If `false`, run the sequence and write `true` when it completes.
- **Animation sequence (approximate):**
  1. Demo card 1 slides in from the right (300ms, `CurvedAnimation(Curves.easeOut)`)
  2. Pause 400ms
  3. Card auto-drags right: `Tween<Offset>` from `Offset.zero` to `Offset(1.5, -0.2)` + green tint overlay fades in (400ms)
  4. Demo card 2 slides in from the right (300ms)
  5. Pause 400ms
  6. Card auto-drags left: `Tween<Offset>` to `Offset(-1.5, -0.2)` + red tint overlay (400ms)
  7. First real recipe card slides in (300ms)
- **Tilt during drag:** Apply `Transform.rotate` derived from the horizontal drag offset — a small rotation (max ~8°) makes the card feel physical. Same transform used on real swipe gestures for consistency.
- **No skip button.** Total duration is under 3s. Adding a skip button implies the tutorial is long enough to be annoying — keep it short enough that it isn't.
- **Progress dot strip** (below the card, not inside it): dots are `6×6` circles by default. The active dot is a pill — `16px wide × 6px tall`, `BorderRadius.circular(3)`. Done = `#16A34A`, vetoed = `#DC2626`, unseen = `#E7E5E4`, active = `#F97316` pill. Gap between dots is `4px`.

### Real swipe gesture (same widget, after tutorial)
The live voting card uses `GestureDetector` with `onHorizontalDragUpdate` and `onHorizontalDragEnd`. On drag end:
- Velocity or offset > threshold → commit the vote (right = approve, left = veto), trigger the same fly-off animation, advance to next card
- Below threshold → snap back with a spring curve (`Curves.elasticOut`, short duration)

The veto/approve overlay labels (the rail text) fade in proportional to drag offset, starting at 25% displacement. They should not be visible at rest.

---

## Veto Power — Group Size Scaling

**Applies to:** `app/services/` on the backend (menu finalization logic)
**Related flow:** flow-01-home.html · Design decisions

- **Groups of 1–3:** A single veto excludes a recipe from the finalized menu.
- **Groups of 4+:** A recipe is excluded only if a strict majority of members vetoed it (e.g., 3 of 4, or 3 of 5).
- This uses the same `member_count` already available on the group record — no additional fields needed.
- The finalization algorithm runs server-side when the last member casts their last vote. It does not need to be re-run on subsequent opens.

---

## Card Flip — Tap Interaction

**Applies to:** The voting card widget
**Related flow:** flow-01-home.html · State 03b

Use `AnimatedSwitcher` or a manual `AnimationController` with a `Matrix4` perspective transform to simulate a card flip on the Y axis. Key details:

- Flip is a Y-axis rotation: `Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle)`
- First half of the animation (0° → 90°): show front. Second half (90° → 180°): show back.
- The back card is a different widget entirely — don't try to animate the content; just swap it at the 90° midpoint.
- Tapping the back flips it back to front. Swiping from either face commits the vote.
- The swipe gesture detector wraps the outer flip container, not the individual faces.

---

## Recipe Pool Exhaustion — Recovery Flow

**Applies to:** `AddRecipeCubit` / `AddRecipeSheet`
**Related flow:** flow-01-home.html · State 03c

When all recipes in the menu have been voted on but the meal target is not met:
- The `HomeCubit` should expose a `poolExhausted` state (or a flag on the existing voting state).
- The Home screen renders the exhaustion UI (State 03c in flow-01).
- "Add more recipes →" opens the `AddRecipeSheet` — the same sheet used in the planning flow. No new component needed.
- "Lower meal target" adjusts `mealTarget` on the menu record via a PATCH to `/menus/{id}`. A simple bottom sheet with a stepper is enough UI.

---

## Onboarding — Curated Recipe Pool

**Applies to:** Backend seed data + onboarding logic
**Related flow:** flow-07-onboarding.html · Part A

The recipes shown during onboarding must be a hand-curated pool of 12–15 top-rated recipes — best food photography, broad cuisine variety, high historical approval rate. This pool should be tagged separately in the database (e.g. a boolean `is_onboarding_featured` on the Recipe model or a dedicated join table). It must never change without deliberate product review. Do not pull from the general recipe pool randomly; a mediocre first impression is unrecoverable.

---

## Onboarding — Guest Session Persistence

**Applies to:** Mobile client + backend join endpoint
**Related flow:** flow-07-onboarding.html · Parts A & B

Votes cast before sign-in (the "Try it first" path) must survive the auth flow without interruption. Implementation:

- On first app launch, generate a device-scoped guest UUID and store it in `SharedPreferences`.
- All votes cast in guest mode are stored locally under this UUID.
- On successful sign-in, POST the guest UUID to a `/sessions/migrate` endpoint (or include it in the sign-in payload).
- The backend migrates any local votes to the newly created user account, associates them with the correct menu, and returns the updated menu state.
- The user must land on the home screen seeing the same menu preview they saw before sign-in — no visible seam.

This is a non-trivial backend requirement. The guest UUID must be included in the vote submission payloads from the start of the guest session so the server can find them at migration time.

---
