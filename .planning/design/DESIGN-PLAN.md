# JackedLog Visual Refresh — DESIGN PLAN (contract for all subagents)

Mood: **"Forged iron"** — dark-gym athletic: graphite neutrals, hot ember-orange
energy accent, confident heavy type, pill-shaped controls, quick snappy motion.
Skin only: NO layout/hierarchy/navigation/behavior/data changes.

## Identity

### Palette
- **Default seed: ember orange `Color(0xFFFF5C1F)`** (replaces lavender default).
  The user-configurable `customColorSeed` setting and dynamic-color toggle STAY —
  the seed only changes the shipped default. Both light + dark schemes come from
  `ColorScheme.fromSeed` in `lib/theme/app_theme.dart`.
- Dark scheme uses `dynamicSchemeVariant: DynamicSchemeVariant.vibrant` for punch;
  light uses the same for consistency.
- **Semantic colors** (resolved via `context.jl` extension in `lib/theme/tokens.dart`,
  brightness-aware — NEVER hardcode these hues in screens):
  | token | role | dark | light |
  |---|---|---|---|
  | `working` | normal set | `colorScheme.primary` | same |
  | `warmup` | warmup set | `0xFFFFB74D` | `0xFFB26A00` |
  | `dropSet` | drop set | `0xFFCE93D8` | `0xFF7B1FA2` |
  | `pr` | personal record | `0xFFFFD54F` | `0xFF9A7B00` |
  | `success` | positive/complete | `0xFF81C784` | `0xFF2E7D32` |
  | `danger` | destructive | `colorScheme.error` | same |

### Type scale (Manrope stays; no new font assets)
Set in `app_theme.dart` textTheme:
- displaySmall/headlineMedium: **w800, letterSpacing -0.5** (big numbers, page titles)
- titleLarge: w700 -0.25 · titleMedium/titleSmall: w700
- bodyLarge/bodyMedium: w500 · labelLarge: w700 · labelMedium/Small: w600 +0.3
Screens use `Theme.of(context).textTheme` roles — no inline `fontSize:` for
standard text (data-dense tables may keep explicit sizes but take weights/colors
from the theme).

### Tokens (`lib/theme/tokens.dart`, all const)
| group | values |
|---|---|
| spacing | `space4 space8 space12 space16 space24 space32` |
| radius | `radiusSm=10 radiusMd=16 radiusLg=24 radiusPill=999` (+ matching `BorderRadius` consts `brSm/brMd/brLg/brPill`) |
| motion | `durFast=150ms durMed=250ms durSlow=400ms`; `curveStandard=Curves.easeOutCubic`, `curveEmphasized=Curves.easeInOutCubicEmphasized` |
| chrome | `bottomBarClearance` — bottom padding that clears floating nav+timer bars; ALL scrollables behind the bars use it |
| alpha | use `surfaceContainerHighest / surfaceContainerHigh / …` M3 roles instead of `withOpacity`/`withValues` alpha soup wherever possible |

### Shared components (`lib/theme/components.dart`)
- `AppCard` — surfaceContainer + `brMd`, optional onTap (replaces ad-hoc
  `Card`/`Container(decoration: …circular(12))`).
- `FilterPill` — selectable pill chip (`brPill`), primaryContainer when selected.
- `SectionHeader` — labelLarge, primary color, `space16` top inset.
- `StatCard` already exists at `lib/widgets/stats/stat_card.dart` — restyle it to
  tokens in Phase 1; screens keep using it.

### Before → after (set row example)
Before: `Container(decoration: BoxDecoration(color: colorScheme.surfaceVariant.withOpacity(.5), borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(... Colors.orange for warmup ...))`
After: `AppCard(child: Row(... color: context.jl.warmup ...))` with `space12`
padding, `brMd`, weight/reps in `titleMedium` (w700), unit in `labelSmall`.

## Migration rules (every subagent follows)
1. Replace hardcoded `Colors.*` with ColorScheme roles or `context.jl.*`
   semantics. Exception: `artistic_color_picker.dart` swatches stay literal.
2. Replace magic `BorderRadius.circular(n)` / EdgeInsets with tokens.
3. Replace inline `Duration(milliseconds: n)` animations with `durFast/Med/Slow`
   + token curves.
4. Adopt `AppCard`/`FilterPill`/`SectionHeader` where a screen re-inlines that
   pattern. Do NOT change widget tree structure/layout otherwise.
5. Every scrollable that sits behind floating bars gets
   `padding: EdgeInsets.only(bottom: bottomBarClearance)` (replaces ad-hoc `96`s).
6. Verify both brightnesses: no white-on-white / black-on-black.
7. Do not commit. Return a summary of files changed + anything skipped.

## Phases (disjoint file ownership — one commit each)
- [x] **P0** design plan (this file) — `docs: design plan`
- [x] **P1** Foundation (Fable, sequential): `lib/theme/{app_theme,tokens,components}.dart` (new), wire `lib/main.dart`, restyle `lib/widgets/stats/stat_card.dart`, resolve nav-flag: delete `_useSegmentedPill` + `lib/bottom_nav.dart`, keep `segmented_pill_nav.dart` (edit `lib/home_page.dart` chrome only) — `feat: design-system foundation`
- [x] **P2** History & sets: `lib/sets/**`, `lib/widgets/sets/**`, `lib/filters.dart`, `lib/app_search.dart`, `lib/custom_set_indicator.dart` — `feat: restyle history & sets`
- [x] **P3** Workout logging: `lib/workouts/**` (except `workout_state.dart` logic), `lib/widgets/workout/**`, `lib/widgets/superset/**`, `lib/widgets/plate_calculator.dart`, `lib/animated_fab.dart` — `feat: restyle workout logging`
- [x] **P4** Plans & 5/3/1: `lib/plan/**`, `lib/fivethreeone/**`, `lib/widgets/five_three_one_calculator.dart`, `lib/day_selector.dart` — `feat: restyle plans & 531`
- [x] **P5** Graphs & stats: `lib/graph/**`, `lib/widgets/stats/period_selector.dart`, `lib/graphs_filters.dart`, `lib/widgets/bodyweight_entry_tile.dart`, `lib/widgets/bodyweight_entry_dialog.dart` — `feat: restyle graphs & stats`
- [x] **P6** Settings & server: `lib/settings/**`, `lib/server/**`, `lib/permissions_page.dart`, `lib/delete_records_button.dart` (consistent dropdowns/dividers) — `feat: restyle settings`
- [x] **P7** Notes, music, records: `lib/notes/**`, `lib/music/**`, `lib/records/record_notification.dart`, `lib/widgets/artistic_color_picker.dart` (chrome only), `lib/widgets/bodypart_tag.dart` — `feat: restyle notes & music`
- [ ] **P8** Shared chrome: `lib/widgets/segmented_pill_nav.dart`, `lib/widgets/morphing_nav_icon.dart`, `lib/timer/**` (bars/page, not `timer_state.dart` logic), `lib/widgets/timer_quick_access.dart`, `lib/screens/splash_screen.dart` — `feat: restyle shared chrome`

P2–P7 may run in parallel (disjoint). P8 after P3 (timer/active-bar adjacency).
Known light-mode breakage to fix in-cluster: notes pages (P7),
`workout_detail_page.dart` (P3), `record_notification.dart` (P7),
`plate_calculator.dart` (P3), spotify settings (P6).

## Progress log
- 2026-07-03: P0 complete.
- 2026-07-03: P1 complete. `lib/theme/{tokens,app_theme,components}.dart` created;
  `main.dart` wired to `jlScheme`/`jlTheme` (old purple default remapped to ember
  via `effectiveSeed` — DB default untouched); `bottom_nav.dart` + `_useSegmentedPill`
  deleted (pill nav kept); `stat_card.dart` on tokens. `bottomBarClearance(context)`
  in tokens.dart is the bar-overlap fix — subagents use it for rule 5.
  Note for P6: appearance-settings seed swatch should show `effectiveSeed(...)`.
