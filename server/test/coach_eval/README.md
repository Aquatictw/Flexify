# JackedLog AI Coach golden-set eval

This harness sends frozen training snapshots and user utterances through the
Coach chat endpoint, then asserts on decoded tool calls. It deliberately does
not grade assistant prose. Cases 06 and 10 contain prose-shaped behavior that
must be reviewed by a human when it matters.

## Run it

From `server/`:

```sh
COACH_EVAL_BASE_URL=https://example.invalid \
COACH_EVAL_API_KEY=redacted \
COACH_EVAL_MODEL=openai/gpt-5.6-luna \
dart run test/coach_eval/run.dart
```

Configuration precedence is environment first, then `scripts/prod.env`:

- Base URL: `COACH_EVAL_BASE_URL`, then `JACKED_URL`.
- API key: `COACH_EVAL_API_KEY`, then `JACKED_API_KEY`.
- Result label/request model: `COACH_EVAL_MODEL`, then `CHAT_MODEL`, then
  `(server default)`.

The API key is used only in the authorization header and is never included in
output. Other useful flags are `--list`, `--filter <substring>`,
`--json <path>`, and `--help`. `--filter` takes a comma-separated list, so
re-running a handful of failures is one invocation: `--filter 01,06,13`.
Write `--json` output outside the repo (this repo is public and the results
files are not tracked).

The results file records the full `tool_calls` the model emitted (name plus
parsed arguments), its prose, and the case's `expect` block. Failing rows also
print the emitted arguments inline in the table. Diagnose from the results
file rather than paying for another run.

## Sweeping models

Known limitation: the server currently overwrites `payload['model']` with its
own `CHAT_MODEL` in `server/lib/api/chat_api.dart`. A real sweep therefore
requires changing `CHAT_MODEL` on the server, restarting that server, and
rerunning this harness. The runner still sends `model`;
`COACH_EVAL_MODEL` is currently only a label for the results.

The one-line server-side fix for a true client-driven sweep is to honor a
client-supplied value when present—for example, replace the unconditional
assignment with:

```dart
payload['model'] ??= chatModel;
```

After that server fix, a bash sweep is:

```bash
for model in openai/gpt-5.6-luna openai/gpt-5.6-terra; do
  COACH_EVAL_MODEL="$model" dart run test/coach_eval/run.dart \
    --json "/tmp/coach-eval-${model//\//-}.json"
done
```

The fish equivalent is:

```fish
for model in openai/gpt-5.6-luna openai/gpt-5.6-terra
  set label (string replace -a / - $model)
  env COACH_EVAL_MODEL=$model dart run test/coach_eval/run.dart \
    --json /tmp/coach-eval-$label.json
end
```

## Pass bar

The target is 25/25. Cases 04 and 05 are the silent block-corruption pair; if
either fails, reject the model outright. Reject any model below 23/25.
Failures involving the prose-shaped cases 06 and 10 require human review of
the transcript rather than an automatic prose verdict.

## Case format

Each file in `cases/` contains a name, one-line description, utterance,
expectations, and exactly one of `snapshot_ref` or inline `snapshot`.
`session_writes` and `block_writes` default from the presence of
`snapshot.workout` and `snapshot.block`. `forbid` disallows calls.
`absent_tools` requires a tool to be both unoffered and uncalled.
`expect_no_tool_calls` strictly requires zero calls. With
`allow_no_tool_calls`, zero calls waive positive expectations but still obey
the negative rules. With `allow_read_only_calls`, a turn whose only calls are
read-only (`get_exercise_history`, `get_records`, `get_block_history`) is
treated the same as a turn with no calls — looking something up before
answering is legitimate coaching, not a contract violation.

Each expectation has `tool` and `args_match`. Calls are matched at most once.
Extra calls are allowed unless forbidden. Function `arguments` may be a JSON
string or an already-decoded object; malformed argument JSON fails with
`bad-json`.

Partial matching works as follows:

- Expected maps require every expected key recursively; extra actual keys are
  ignored.
- Expected lists match by index and may be shorter than actual lists.
- Numbers compare by value within `1e-9`; other scalar values use equality.

| Directive | Meaning |
| --------- | ------- |
| `{"$absent": true}` | Require the parent-map key to be missing. |
| `{"$oneOf": [m1, m2]}` | Match at least one matcher. |
| `{"$len": 3}` | Require a list of exactly that length. |
| `{"$all": m}` | Require a non-empty list whose every item matches. |
| `{"$contains": [m1, m2]}` | Require a list containing a match for every matcher. |
| `{"$anyOfValues": [v1, v2]}` | Match one of the listed literal values. |
| `{"$lt": n}` | Require a numeric value less than `n`. |
| `{"$lte": n}` | Require a numeric value less than or equal to `n`. |
| `{"$gt": n}` | Require a numeric value greater than `n`. |
| `{"$gte": n}` | Require a numeric value greater than or equal to `n`. |
| `{"$not": m}` | Require the value not to match `m`. |

Directives can be combined in one map, such as
`{"$len": 3, "$all": {"reps": 5}}`. Unknown directives are rejected while
loading cases.

## Offline self-test

The files in `stubs/` are canned ideal responses that test the harness itself;
they are not model evaluation results. This command performs no network calls:

```sh
dart run test/coach_eval/run.dart --stub-dir test/coach_eval/stubs
```

## Results

| Model | Date | Passed | 04/05 | Notes |
| ----- | ---- | ------ | ----- | ----- |
| `anthropic/claude-sonnet-5` | 2026-07-29 | 20/25 | PASS | Before the fraction/prescription prompt rules landed. 4 of the 5 failures were contract gaps, not model errors. |
| `anthropic/claude-sonnet-5` | 2026-07-29 | 11/11 partial | PASS | Cases 01, 02, 04, 05, 06, 11, 13, 16, 17, 18, 19 after the fixes. |
| `anthropic/claude-sonnet-5` | 2026-07-29 | **25/25** | PASS | Full run after the fraction/prescription prompt rules. 236.8s. |
| `openai/gpt-5.6-terra` | 2026-07-30 | 20/25 | PASS | Before the named-percentage and question-vs-instruction rules. Scored 24/25 on the sweep, but repeat runs put cases 02 and 19 at 2/4 each, so the sweep number was partly luck. |
| `openai/gpt-5.6-luna` | 2026-07-30 | 21/25 | PASS | Same prompt as the terra row. Failures: 02, 10, 19 (all fixed by the prompt rules) and 17 (harness bug). |
| `openai/gpt-5.6-luna` | 2026-07-30 | **25/25** | PASS | After the named-percentage and question-vs-instruction rules. 134.5s. Repeats: 02 4/4, 10 4/4, 17 4/4, 19 2/4. **Selected as the production model.** |
| `openai/gpt-5.6-terra` | — | not swept | — | Not re-swept after the prompt fix: luna already scored 25/25 at 40% of terra's input price, so the comparison could not change the choice. |
| `openai/gpt-5.6-sol` | — | not run | — | Never evaluated. Skipped once luna passed at 1/10 of sol's input price. |

Case 19 (`add one more bench set at 85% TM`) is the one residual flake, at roughly
2/4 on luna. It appends a *fourth* set, past the three the prescription covers, so
`pct_of_prescribed` has no baseline for that position — and both gpt-5.6 variants
sometimes reach for it anyway. This is contained rather than dangerous:
`session_tools` passes `prescribed: null` past the end of the prescription and
`resolveWeightSpec` returns a model-facing error naming the alternatives, so the
turn costs an extra round trip and self-corrects instead of silently loading the
wrong weight. Do not "fix" it by making `pct_of_prescribed` fall back to the last
prescribed set; that would turn a recoverable error into a silent 95%-instead-of-85%
bar.

Do not fill this in with anything other than an actual sweep, and label
partial runs as partial.

Planned models: `openai/gpt-5.6-luna` (in production), `anthropic/claude-sonnet-5` (reference).

### Cost

The 115k-token knowledge prefix dominates every turn, so run cost tracks the
model's input price almost exactly:

| Model | Input $/M | Cached read $/M | Cold turn | Warm turn |
| ----- | --------- | --------------- | --------- | --------- |
| `openai/gpt-5.6-luna` | 0.50 | 0.05 | ~$0.058 | ~$0.006 |
| `openai/gpt-5.6-terra` | 1.25 | 0.125 | ~$0.144 | ~$0.014 |
| `openai/gpt-5.6-sol` | 5.00 | 0.50 | ~$0.58 | ~$0.058 |
| `anthropic/claude-sonnet-5` | — | — | ~$0.29 | ~$0.024 |

A full 25-case sweep was **$3–4** on `claude-sonnet-5` and well under **$1** on
luna. Warm pricing only holds inside the provider's cache TTL, so a slow
interactive session pays closer to the cold column. Prefer `--filter` while
iterating.

## Contract notes for Phase B

- The operation discriminator key is `op`.
- `weight_spec` is a single-key object.
- `pct_of_prescribed` is a signed delta; `0` means exactly prescribed.
- `set_index` / `set_indices` are 0-based and count *all* of that exercise's
  sets in the current workout, performed ones included — not just the
  prescribed tail. An index landing on a performed set is a tool error from
  `apply_session_changes`, not a silent no-op.
- Every session op carries `exercise`, including `edit_set` and `remove_sets`,
  so indices are always scoped to one exercise rather than to the workout.
- `correct_tm` is the one place the model emits a block weight number.
- `set_supplemental` takes `cycle` plus `supplemental`.
- **Every `pct_` value is a fraction, not percentage points**: `0.9` is 90%,
  `-0.05` is 5% lighter. This is stated in both the tool schema descriptions
  (`tools.dart`) and the server system prompt (`_toolUseRules` in
  `server/lib/services/knowledge_service.dart`). Before those sentences existed
  the model emitted `-5` for "5% lighter", which would have resolved as 500%
  lighter. Phase B's resolver should still reject `|pct| > 1` as a tool error
  rather than trusting the prompt.
- When the snapshot's `prescription` covers the lift, `pct_of_prescribed` is
  preferred over `pct_of_tm`; `pct_of_tm` is for supplemental work and
  user-named percentages. Without this rule the model re-derived the scheme
  percentages from memory, which is exactly the recall path PRD decisions 3
  and 8 exist to avoid.
- **A percentage the user names beats that preference.** Stated as an
  unconditional rule, the line above made both gpt-5.6 variants answer
  "a set at 90% TM" with `pct_of_prescribed: 0`, loading whatever was already
  prescribed instead of the weight asked for. `_toolUseRules` now puts the
  user-named case first and explains why `0` is wrong there.
- `weight_spec` sits **inside `sets`** for `add_exercise` and `add_sets`, but at
  the **op level** for `edit_set` (`sets` is not an `edit_set` field at all).
  Case 17's matcher originally only accepted the `sets` shape, so a
  schema-correct `edit_set` answer failed; it now accepts either via `$oneOf`.
  Any new case asserting on a weight should do the same unless it means to pin
  one op shape.
- A question is not an instruction. "Should I run SSL instead of BBB?" once drew
  a `propose_block_changes` switching the template to FSL — an unrequested
  change, and to a template the user had not named. Cases 08/09/10 guard this
  boundary with `forbid`.
