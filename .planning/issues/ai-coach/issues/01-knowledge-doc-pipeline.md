# 01 — Knowledge doc build pipeline

Status: ready-for-agent

Parent: [PRD](../PRD.md)
Depends on: none (foundation)

## Goal

Turn `531forever.pdf` into a ~48k-token prose-only knowledge document, plus two
generated companions: a percentage reference derived from `schemes.dart`, and an
app capability manifest. These three are concatenated into the system prompt by
issue 02.

**The numeric set tables must not survive.** The book sets them in a script font
and ClearScan mangles it — `rO"/o x 5` is 70% × 5, `'10"/o x 5+ CPR sef)` is
90% × 5+ (PR set), `J)eodliff` is Deadlift. Feeding those to something that
tells you what to load is a correctness hazard. Body prose OCRs cleanly.

## Where

- New: `tools/knowledge/build_knowledge.dart` (or `.py` — a build script, not
  shipped code).
- Output: written to a path outside the repo tree, referenced by
  `KNOWLEDGE_DIR` in `scripts/prod.env`.
- Reads: `lib/fivethreeone/schemes.dart` constants for the generated reference.

## Tasks

- **Gitignore `531forever.pdf` first.** The repo is public and the file is
  currently untracked in the root. Also gitignore the build output directory.
- Extract text: `pdftotext 531forever.pdf` (plain, not `-layout` — layout mode
  preserves table columns you are about to delete anyway).
- Strip, by page range (283 pages total):
  - pp. 1–13 front matter (cover, foreword, Musashi quote, publisher, contents)
  - pp. 21–26 individual jump/throw movement descriptions — **keep** the rules
    text on pp. 22–23
  - pp. 36–44 exercise how-to entries (DB press, lat pulldown, upright row, SLDL,
    kettlebell, DB squat form cues)
  - Beginner Prep School, Spinal Tap H.S. years, and weight-vest sections
- Strip **every** numeric set table book-wide. Detect on the OCR signature
  rather than page ranges: lines containing `"/o`, `%` adjacent to `x <digit>`,
  or the mangled day headers (`WBBK`, `WBEK`, `WIBK`, `PBIDAY`, `MONDA:`,
  `WBDNISDAY`, `THUlSD`, `MDRDAY`, `PIIDAY`). Prefer over-stripping: a template
  with prose but no table is fine, a table with corrupt numbers is not.
- Repair the common OCR artifacts in retained prose: `l ifter` → `lifter`,
  `a ll ows` → `allows`, `5 / 3 / 1 F O R EV E R` running headers removed.
- Keep and clearly section: Part 1 doctrine pp. 14–35 (principles, TM selection,
  supplemental lift rules, programming, leader/anchor, 7th-week protocols),
  assistance rules pp. 45–46, template *prose* across Part 2, and Part 3
  conditioning + recovery pp. 256–283.
- **Generate `percentages.md` from `schemes.dart`** — do not hand-type it. Emit
  `fivesProScheme`, `prSetsScheme`, `deloadScheme`, `tmTestScheme`, `bbbScheme`,
  `getFslScheme` per week, the cycle order and week counts (`cycleWeeks`), and
  the TM bump steps (`tmBumpLower` 4.5 / `tmBumpUpper` 2.2). This is the
  agent's only trusted source of percentages.
- **Generate `capabilities.md`** — what the app can actually represent: the five
  cycle types in their fixed 11-week order, and exactly two supplementals
  (`bbb`, `fsl`) with `leaderSupplementalOptions` / `anchorSupplementalOptions`.
  State plainly that other templates from the book can be discussed but not
  configured as a block.
- Report the final token estimate. *Resolved 2026-07-29:* landed at ~115k
  measured tokens, well above the ~48k target. Investigated and accepted — see
  PRD decision 8. The ~48k figure assumed the set tables dominated the book;
  they are ~27% of it. No further trimming; Part 2 template prose is retained
  deliberately.

## Acceptance

- Output contains zero occurrences of `"/o`, and zero of the mangled day-header
  tokens listed above.
- Output contains the Part 1 principles, the leader/anchor and 7th-week protocol
  prose, and the conditioning/recovery material.
- `percentages.md` values match `schemes.dart` exactly — spot-check 5's PRO
  week 2 (70/80/90) and PR Sets week 3 (75×5 / 85×3 / 95×1+).
- Re-running the script is deterministic (same input → byte-identical output),
  so the prompt prefix stays cacheable.
- `531forever.pdf` and the output directory are both gitignored; `git status`
  is clean of them.

## Notes

- Determinism matters more than it looks: any byte change in this doc
  invalidates the whole cached prefix on every provider.
- Do not commit the extracted text. Personal copy, public repo.
