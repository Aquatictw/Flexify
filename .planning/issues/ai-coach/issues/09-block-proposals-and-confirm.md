# 09 — `propose_block_changes` + confirmation card

Status: done

Parent: [PRD](../PRD.md)
Depends on: 07

## Goal

The confirm tier. Everything that outlives today's session — training maxes,
cycle position, supplemental template, and creating a new exercise — goes
through one tool that **writes nothing** until you tap Apply.

The hazard this issue exists to contain: `_shiftTms()`
(`lib/fivethreeone/fivethreeone_state.dart:245`) moves all four TMs *and*
increments `tm_bumps`; `updateTm()` (:282) changes one TM and deliberately does
not. `needsTmUnbump` (:71-77) depends on that difference to know whether Back
should undo a bump it really applied. Two operations, near-identical outcomes in
the data, and picking the wrong one silently corrupts block navigation weeks
later.

## Where

- New: `lib/coach/block_tools.dart`, `lib/coach/widgets/proposal_card.dart`
- Routes to existing `FiveThreeOneState` methods — **never** raw column writes

## Tasks

- **`propose_block_changes(ops[], rationale)`** returns a proposal for
  rendering; it performs no database work. Ops, each mapped to an existing
  state method:

  | Op | Routes to | Semantics shown to the user |
  | -- | --------- | --------------------------- |
  | `bump_tms` | `bumpTms()` → `_shiftTms(1)` | "+4.5 squat/deadlift, +2.2 bench/press — **counts as a cycle bump**" |
  | `unbump_tms` | `unbumpTms()` → `_shiftTms(-1)` | "undoes the last bump — **decrements the bump counter**" |
  | `correct_tm` | `updateTm(exercise, value)` | "bench TM 100 → 97.5 — **does not count as a cycle bump**" |
  | `advance_week` | `advanceWeek()` | current → next position label |
  | `go_back_week` | `goBackWeek()` | current → previous position label |
  | `set_supplemental` | column write on the block | "Leader supplemental BBB → FSL" |
  | `create_exercise` | new `gym_sets` name | "creates a new exercise 'X' — history starts fresh" |

- **The confirm card must state the bump semantics in words**, not just the
  numbers. `bump_tms` and `correct_tm` can produce visually similar diffs; the
  sentence is what makes the difference reviewable. Show before → after per
  lift, the rationale sentence, and Apply / Dismiss.
- **Never write columns directly.** Route through the `FiveThreeOneState`
  methods so `tm_bumps` stays consistent with `needsTmBump` / `needsTmUnbump`.
  A direct `UPDATE` on the TM columns is the bug this whole issue prevents.
- Validate ops against block state before rendering: `unbump_tms` with
  `tm_bumps == 0`, `go_back_week` at cycle 0 week 1 (`canGoBack` at :80), or
  `advance_week` past the TM test are tool errors, not proposals.
- **Coach stance** (PRD decision 13): the system prompt requires one sentence of
  doctrine before a block-level proposal — e.g. *"the book puts TM resets at the
  7th week protocol; you're in Leader 2 week 2"* — then the proposal. Session
  requests stay frictionless. Render the rationale on the card.
- After Apply, call `FiveThreeOneState.refresh()` and feed a tool result back
  into the thread so the model knows the state changed. On Dismiss, feed back
  that it was declined so it does not re-propose immediately.
- Escalate `create_exercise` here from issue 06 — a new exercise name forks
  history permanently and belongs behind a tap.

## Acceptance

- "My bench TM is wrong, should be 97.5" → card reading *"does not count as a
  cycle bump"*, and on Apply `tm_bumps` is unchanged.
- "I finished the cycle, move my TMs up" → card reading *"counts as a cycle
  bump"*, and on Apply `tm_bumps` increments and all four TMs move.
- After a `bump_tms` applied through the coach, pressing Back in the existing
  block UI correctly offers the un-bump — i.e. `needsTmUnbump` still behaves.
- Nothing is written on Dismiss.
- `unbump_tms` at `tm_bumps == 0` returns a tool error, not a card.
- A mid-cycle TM-drop request produces doctrine + a card, never a silent
  session-level rewrite instead.
- Eval cases 4, 5 and 6 (issue 03) pass.
- Verify on device per CLAUDE.md — screenshot both card variants.

## Notes

- This is the highest-blast-radius code in the feature. The confirm tap is the
  only thing between a plausible-sounding suggestion and a corrupted block, so
  the card's wording is a correctness surface, not copy.
- No undo (PRD decision 14) — which is another reason the wording has to be
  right the first time.
