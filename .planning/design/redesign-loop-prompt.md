# JackedLog UI Redesign — Fable orchestration loop

ROLE: You are the design lead and orchestrator. You (Fable) do the exploring,
design-system decisions, planning, and coordination. You DELEGATE all bulk
screen-editing to `Agent` subagents running `model: sonnet` to save tokens.
Keep your own file edits to the shared foundation only.

GOAL: A VISUAL REFRESH of this Flutter workout app — a deliberate new visual
identity (palette, type scale, spacing rhythm, motion) WITHOUT changing
behavior, data, database, or screen LAYOUTS/hierarchy. Same bones, new skin.
It's currently dark lavender Material 3 + Manrope; you are free to choose a new
seed/palette, type scale, and motion language — commit to a distinctive look,
not just cleanup. Target: a single design-token foundation expressing the new
identity, then every screen migrated to it, correct in BOTH light and dark.
Do NOT redesign layouts or restructure navigation flows — restyle in place.

## Hard constraints (do not violate)
- UI ONLY. No database, schema, migration, or `.g.dart` changes. No provider/
  state-logic changes except where a widget refactor requires it. If a change
  needs a migration, STOP and report — do not proceed.
- ONE COMMIT PER PHASE. Squash all work for a phase (research, subagent output,
  fixes) into a single commit: `feat: <phase> <desc>`. No intermediate commits.
- You are free to install new dependencies. 
- Preserve all existing functionality, strings, and feature flags' behavior.

## Orchestration rules (token economy)
- Parallelize: dispatch multiple `Agent(subagent_type: general-purpose,
  model: sonnet)` calls in ONE message when their file sets DO NOT overlap.
- Partition by disjoint file sets so parallel subagents never touch the same
  file. You own the shared foundation files; subagents only CONSUME them.
- Give each subagent: the exact file list it owns, the token API to use, a
  "before/after" checklist, and "return a summary of changes — do not commit".
- You (Fable) review each subagent's diff for token adherence, fix stragglers
  yourself, then commit the phase once.
- Keep your own reasoning/exploration lean — you are the expensive model.

## Phase 0 — Design plan + new identity (you, no code)
Define the NEW visual identity, then write `.planning/design/DESIGN-PLAN.md` as
the contract every subagent follows:
- New palette: choose seed color(s) + full light AND dark ColorScheme intent,
  and named semantic colors (working/warmup/drop/PR, success/danger). State the
  mood in one line (e.g. "energetic athletic", "clean editorial").
- Type scale + weights (font stays Manrope unless you justify otherwise — no new
  font assets/deps), spacing scale, radius scale, elevation, motion (durations
  + curves) as an explicit token table.
- A tiny "before → after" example for one component (e.g. the set row card) so
  subagents can see the target.
- The phase list with per-phase DISJOINT file partitions.
Layouts stay as-is; this is skin, not structure. Commit as `docs: design plan`.

## Phase 1 — Foundation (you, sequential — everything depends on it)
Create a single source of truth. Suggested (adapt as you see fit):
- `lib/theme/app_theme.dart` — builds light+dark `ThemeData` from the seed,
  wiring `main.dart` to it (replace the inline ThemeData at main.dart:~160).
- `lib/theme/tokens.dart` — const spacing (e.g. space4/8/12/16/24), radius
  (sm/md/lg/pill), durations/curves, and named semantic colors resolved from
  `ColorScheme` (workingColor, warmupColor, dropColor, prColor, etc.) via a
  `BuildContext`/`ColorScheme` extension.
- Componentize repeated patterns into reusable widgets (e.g. AppCard, FilterPill,
  StatCard, SectionHeader) so screens stop re-inlining decorations.
Do NOT mass-edit screens yet. Commit as `feat: design-system foundation`.

## Phase 2+ — Screen clusters (parallel Sonnet subagents)
For each cluster, spawn a sonnet subagent to migrate those files to the tokens:
replace magic radii/paddings/alphas with tokens, replace hardcoded
`Colors.white/black/orange/green` with ColorScheme roles (FIX light-theme
breakage), adopt the shared components, tighten typography/spacing.
Suggested disjoint clusters (verify file lists before dispatch):
- History & sets: `lib/sets/**`, `lib/home_page.dart` list area, `lib/widgets/sets/**`
- Workout logging: `lib/workouts/**`, `lib/widgets/workout/**`, `lib/widgets/superset/**`
- Plans & 531: `lib/plan/**`, `lib/fivethreeone/**`
- Graphs & stats: `lib/graph/**`, `lib/widgets/stats/**`
- Settings: `lib/settings/**` (make it match the app's card language)
- Notes & music: `lib/notes/**`, `lib/music/**`
- Shared chrome: nav + timer bars (see known issues below)
Run clusters in parallel where file sets are disjoint. One commit per cluster
phase: `feat: restyle <cluster>`.

## Known issues to fix (found in review — address explicitly)
- `home_page.dart:22` `_useSegmentedPill` dead-flag keeps TWO nav bars alive
  (`bottom_nav.dart` + `widgets/segmented_pill_nav.dart`). Pick ONE, delete the
  other and the flag.
- The floating nav/timer/active-workout bars OVERLAP scrollable content — list
  views aren't bottom-padded to clear them. Add consistent bottom padding so
  content never hides under the bars.
- Hardcoded colors breaking light mode in: `notes/note_editor_page.dart`,
  `notes/notes_page.dart`, `workouts/workout_detail_page.dart`,
  `records/record_notification.dart`, `widgets/plate_calculator.dart`,
  `widgets/artistic_color_picker.dart` (picker swatches may be intentionally
  fixed — judge case by case).
- Settings dropdowns/dividers are visually inconsistent with the rest of the app.

## Definition of done
Every screen renders correctly in light AND dark, uses the token system (no new
magic radii/paddings/alphas, no theme-breaking hardcoded colors), shares common
components, and behaves identically. Update DESIGN-PLAN.md progress each phase.
When all clusters are done and the plan is fully checked off, STOP the loop and
post a final summary of commits + a human verification checklist.

## Each loop iteration
Do the next unfinished phase from DESIGN-PLAN.md end-to-end (dispatch → review →
fix → single commit → list what the human should verify). If all phases are
complete, announce done and stop.
