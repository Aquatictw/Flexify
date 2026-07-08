# 04 — Cardio PRs (max for all metrics)

Status: ready-for-agent

Parent: [PRD](../PRD.md)
Depends on: 01, 03

## Goal

Cardio bouts earn PR badges. Best = **max** for each of duration, distance,
speed, incline, independently. Records currently exclude cardio entirely.

## Where

- `lib/records/records_service.dart` — `checkForRecords` (94-196) queries bests
  with `hidden=0 AND warmup=0 AND cardio=0` (104-115) and compares weight/1RM/
  volume (160-193). 30s `_prCache`; first-ever-set counts as all records.
- `enum RecordType { best1RM, bestVolume, bestWeight }` (16-25).
- Lightweight `isBest(GymSet)` (`lib/database/gym_sets.dart:454-498`) already
  has a cardio branch (best pace) — align or reuse for the workout-card badge.

## Tasks

- Add cardio record types: `bestDuration, bestDistance, bestSpeed, bestIncline`
  to `RecordType`.
- In `checkForRecords`, branch on the candidate set's `cardio`:
  - Cardio path queries `MAX(duration), MAX(distance),
    MAX(distance/duration) [speed], MAX(incline)` for the exercise, filtering
    `hidden=0 AND warmup=0 AND cardio=1` (mirror the strength query shape).
  - PR if the candidate's value strictly exceeds the previous max on any metric;
    first-ever cardio set = all cardio records (mirror 129-152).
  - Guard divide-by-zero for speed (duration=0 → skip speed).
- Keep the 30s cache + `clearPRCache()` behavior intact.
- Ensure badge rendering handles the new record types (wherever strength badges
  render from `checkForRecords`).

## Acceptance

- Logging a longer/faster/farther/steeper cardio bout than history shows the
  matching PR badge(s).
- No PRs for warmup/hidden rows; weight PRs unaffected.
- Speed PR skipped when duration is 0.
- `flutter analyze` clean; verify a real PR badge on device.
