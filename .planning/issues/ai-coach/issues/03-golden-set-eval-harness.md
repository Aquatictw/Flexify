# 03 — Golden-set eval harness

Status: done

Parent: [PRD](../PRD.md)
Depends on: 02

## Goal

A script that replays ~25 fixed cases through `/api/chat` and asserts on the
**tool calls the model emits** — name and arguments — not on prose. This is what
makes "decide the model by eval" real, and the only safe way to try a cheaper
model later.

## Where

- New: `server/test/coach_eval/` — cases as JSON, runner as a Dart script.
- Run manually (`dart run server/test/coach_eval/run.dart`), not in `flutter test`.

## Tasks

- **Case format**: `{name, snapshot, utterance, expect: [{tool, args_match}]}`
  where `snapshot` is a literal session-snapshot JSON blob (issue 05's shape)
  and `args_match` is a partial match — assert the fields that matter, ignore
  the rest.
- **Runner**: for each case, POST `{messages, tools}` to `/api/chat`, read
  `choices[0].message.tool_calls`, compare against `expect`. Print a pass/fail
  table and a summary line. Take the target model from an env var so a model
  sweep is a shell loop.
- **Cases — the three core utterances:**
  1. "today is 5/3/1 bench day, add the prescribed work but 5% lighter" →
     `apply_session_changes` adding Bench Press with three sets, each
     `{pct_of_prescribed: -0.05}`.
  2. "make a new set at 90% TM × 5" (Bench Press already in session) →
     `apply_session_changes` appending one set `{pct_of_tm: 0.90}`, reps 5,
     against the existing exercise — **not** a new exercise.
  3. "add 3×10 lat pulldown at 60kg" → accessory with `{absolute: 60}`, no TM
     reference, no unit field.
- **Cases — the traps:**
  4. "my bench TM is wrong, it should be 100" → `propose_block_changes` with
     `correct_tm`, **not** `bump_tms`.
  5. "I finished the cycle, move my TMs up" → `bump_tms`, **not** `correct_tm`.
  6. "this feels heavy, drop my TM" mid-cycle (snapshot: Leader 2, week 2) →
     doctrine sentence, and either no tool call or `propose_block_changes` —
     **never** `apply_session_changes` silently rewriting the session as a
     substitute.
  7. Unknown exercise name ("add some bench") where the vocabulary has
     "Bench Press" → asserts the model uses the vocabulary spelling.
  8. No active block in snapshot → no write tool call; advisory answer only.
  9. No active workout → `apply_session_changes` absent from the offered tools;
     assert the model does not hallucinate a call to it.
  10. "should I run SSL instead of BBB?" → answers from the book, states plainly
      it is not configurable in the app, offers `fsl`/`bbb`.
- Pad to ~25 with variations: kg vs lb blocks, deload week, TM test week,
  supplemental volume cuts, "same as last week but lighter".
- Document in a README how to sweep models and what the pass bar is.

## Acceptance

- `dart run server/test/coach_eval/run.dart` prints a per-case pass/fail table.
- Swapping the model env var reruns the whole set unchanged.
- Cases 4 and 5 both pass on the chosen model — that pair is the one silent
  corruption path in the design (`_shiftTms` maintains `tm_bumps`, `updateTm`
  deliberately does not, and `needsTmUnbump` depends on the difference).
- At least two models have been run and the results recorded in the README.

## Notes

- Assert structurally. Prose quality is not what decides model choice here —
  correct tool selection is.
- Snapshots are literals in the case files, so the harness does not need a
  device or a database.
- Once the app logs real turns, promote real failures into cases rather than
  inventing more.
