# PRD: Android Package Size and Runtime Performance

Status: ready-for-agent

## Problem Statement

JackedLog's Android builds appear disproportionately large for the product:
the measured debug APK is 113.36 MiB and the universal release APK is
66.79 MiB. The release package currently ships complete native stacks for
arm64-v8a, armeabi-v7a, and x86_64 to every device even though a device uses
only one ABI. This increases download, installation, update, and storage costs
without adding functionality for that device.

The app can also feel slow in some situations. Debug mode accounts for some of
that perception because it includes the Flutter JIT runtime, assertions,
service instrumentation, and validation libraries, but the code review found
release-relevant work that can continue while pages are hidden: all six tabs
are built and retained immediately, History calculates records with
per-exercise database queries and full-history scans, small thumbnails can
decode full-resolution images, and the rest timer polls throughout the Home
page lifetime.

Assets and removable dependencies are not the principal cause. Packaged
Flutter assets occupy only about 0.56 MiB compressed, clearly unreferenced
assets total roughly 164 KiB, and every declared runtime Dart dependency has a
known use. Optimization work needs to address the measured causes rather than
remove useful features for negligible savings.

## Solution

Deliver Android artifacts that contain only the native ABI required by the
receiving device: ABI-split APKs for direct distribution and an Android App
Bundle for stores that perform device-targeted delivery. Preserve a universal
APK only when explicitly required as a compatibility artifact. The arm64
artifact used by the connected physical phone should remain near the measured
24.31 MiB baseline rather than the 66.79 MiB universal baseline.

Improve release runtime behavior in descending evidence order:

1. Lazily create each configurable Home tab on first visit, preserve its state
   after creation, and ensure hidden tabs do not start or retain avoidable
   database, media, or Spotify work.
2. Replace History's per-exercise record calculation with a bounded set of
   grouped database operations that preserve current record semantics for
   strength exercises, cardio exercises, ties, hidden sets, and warmups.
3. Decode appropriately sized images for History and workout-detail
   thumbnails while preserving full-resolution viewing where it is useful.
4. Run the rest timer's periodic work only while a timer is active and limit
   rebuild frequency to what the visible label and progress treatment require.

Measure runtime changes in profile or release mode on the physical Android
phone. Debug-mode smoothness is not an acceptance signal.

## User Stories

1. As an Android user, I want to download only the native code my phone can
   execute, so that JackedLog consumes less bandwidth.
2. As an Android user, I want application updates to be smaller, so that
   routine releases install more quickly.
3. As an Android user, I want JackedLog to occupy less application storage, so
   that keeping workout history does not carry unnecessary binary overhead.
4. As a direct-download user, I want an APK clearly matched to my device ABI,
   so that I can install the correct compact artifact.
5. As a store-distribution user, I want the store to deliver a device-targeted
   package, so that I do not receive native runtimes for other devices.
6. As a maintainer, I want universal artifacts to be intentional rather than
   the default release output, so that package-size regressions are visible.
7. As a maintainer, I want reproducible package-size measurements, so that I
   can compare future releases against the current baseline.
8. As a maintainer, I want packaged contents measured separately from the
   local build cache, so that generated intermediates are not mistaken for
   shipped application size.
9. As a developer, I want debug APK size documented as development overhead,
   so that time is not spent trying to optimize JIT and hot-reload machinery
   out of release builds.
10. As a user opening JackedLog, I want only the initially visible Home tab to
    initialize, so that the first usable screen does not wait on hidden pages.
11. As a user switching tabs for the first time, I want that tab to initialize
    when requested, so that startup work is distributed according to actual
    use.
12. As a user returning to a previously visited tab, I want its navigation and
    UI state preserved, so that lazy initialization does not make tabs feel
    disposable.
13. As a user who never opens Music, I want Spotify polling and media work to
    remain inactive, so that unused features do not consume battery or CPU.
14. As a Spotify user, I want polling to occur only while Music is visible and
    the app is active, so that playback information stays current without
    unnecessary background work.
15. As a user with a large workout history, I want History to load without a
    database round trip for every distinct exercise, so that growth in my
    exercise library does not cause disproportionate delays.
16. As a strength-training user, I want best weight, estimated 1RM, and volume
    records to remain identical after query optimization, so that faster
    History results remain trustworthy.
17. As a cardio-training user, I want records for each cardio exercise and bout
    to remain identical after query optimization, so that performance work
    does not change training history.
18. As a user with tied records, I want the existing earliest-set tie-breaking
    behavior preserved, so that record badges do not move unexpectedly.
19. As a user with hidden or warmup sets, I want those sets to retain their
    current record eligibility rules, so that optimized queries do not expose
    incorrect records.
20. As a user with exercise photos, I want small thumbnails to scroll smoothly,
    so that camera-resolution images are not decoded for tiny UI elements.
21. As a user opening an image in a detail context, I want useful image quality
    retained, so that thumbnail optimization does not destroy the original.
22. As a user without an active rest timer, I want JackedLog to avoid timer
    polling, so that an idle Home page performs no timer-related periodic work.
23. As a user with an active rest timer, I want smooth progress and an accurate
    remaining-time label, so that reduced polling does not make the timer feel
    stale.
24. As a user receiving the final countdown alert, I want pulse, sound,
    vibration, and time adjustments to behave as before, so that timer
    optimization does not change workout behavior.
25. As a maintainer, I want each performance claim verified in profile or
    release mode on the physical phone, so that debug-mode jank is not treated
    as a production regression.
26. As a maintainer, I want optimizations ranked by measured impact, so that
    small asset and dependency savings do not displace higher-value work.
27. As a maintainer, I want all existing Android ABIs to remain available as
    separate deliverables, so that reducing per-device size does not silently
    drop supported devices.
28. As a user, I want package and runtime optimization to preserve every
    existing JackedLog feature, so that the smaller, faster app has no product
    downgrade.

## Implementation Decisions

- Package-size work is the first priority because it has a deterministic,
  measured result and does not require removing application features.
- Direct APK releases will produce one artifact per supported ABI. Store
  releases will use an Android App Bundle so the store can deliver ABI-specific
  splits. A universal APK may remain available only for an explicitly named
  compatibility or testing workflow.
- Retain arm64-v8a, armeabi-v7a, and x86_64 support. This work changes
  packaging, not the supported-device policy.
- Keep existing reproducible-build and signing behavior. ABI-specific artifact
  naming must make it difficult to install or publish the wrong package.
- Do not count the generated build directory, unstripped intermediate native
  libraries, or stale plugin intermediates as shipped application size.
- Do not prioritize asset deletion. The broad asset directory can eventually
  be narrowed, but the known saving is roughly 164 KiB and is not material to
  this initiative.
- Do not remove or replace a used dependency solely for package size without a
  separate measured cost-benefit case. In particular, file selection,
  Spotify, notifications, audio, and SQLite remain product requirements.
- Home tabs will use create-on-first-visit semantics. Once created, a tab's
  state will be retained for the session, matching current user-visible state
  preservation.
- Offstage rendering alone does not constitute lazy initialization. Hidden,
  never-visited tabs must not create their page subtree or begin page-owned
  streams, polling, media initialization, or other work.
- Spotify polling will be governed by actual Music visibility and application
  lifecycle, while preserving silent reconnection and playback state behavior.
- History record calculation will move from per-exercise round trips to a
  bounded grouped-query design. It must preserve strength record types, cardio
  record types, earliest-set tie-breaking, and exclusion of hidden and warmup
  sets.
- History optimization must avoid loops of per-row Drift writes. No database
  writes or schema changes are expected for this work.
- Thumbnail rendering will request decode dimensions appropriate to the
  rendered size and device pixel ratio. The original image remains available
  for contexts that require a larger view.
- Rest-timer periodic work will be absent while no timer is active. While
  active, progress animation and textual countdown may use different update
  mechanisms or frequencies as long as the visible result remains smooth and
  accurate.
- Runtime work will be executed in the stated priority order. Each item must
  be measured before and after independently so a later optimization is not
  credited for an earlier change.
- Per repository policy, each future execution phase will be squashed into one
  scoped Conventional Commit and committed only after explicit user approval.
- No database migration, export-format change, server change, or API contract
  change is required.

## Testing Decisions

- The primary package acceptance seam is the final Android artifact. Build the
  universal release baseline and the ABI-split release artifacts from the same
  source revision, inspect their contents, and compare byte sizes.
- On the current baseline, the universal release artifact is 66.79 MiB and the
  arm64 split is 24.31 MiB. Acceptance requires the arm64 artifact to remain at
  least 60% smaller than the universal artifact and contain no native
  libraries for other ABIs.
- Verify that each split artifact contains its intended Flutter engine,
  ahead-of-time compiled application, SQLite library, and required common
  resources. Verify installation and launch of the arm64 artifact on the
  connected arm64-v8a phone.
- Verify the store bundle with an official bundle inspection or local delivery
  tool to confirm that an arm64 device receives only arm64 native libraries.
- The highest runtime acceptance seam is observable behavior in a profile or
  release build on the physical Android phone. Use the existing ADB screenshot
  workflow for visual results and a Flutter performance trace or equivalent
  device-side measurement for timing, frame, CPU, and memory claims.
- Establish a before/after profile for the initially visible Home tab. Confirm
  that never-visited tabs are not initialized, and then visit every configured
  tab to confirm first-use initialization and state preservation.
- Verify Music polling at the page/lifecycle boundary: no polling before first
  visit, polling while visible and connected, stopped while hidden or while
  the application is backgrounded, and restored appropriately on return.
- Exercise History with a representative large dataset containing many
  distinct strength and cardio exercises. Compare record output before and
  after using the same data and confirm that database-query count is bounded
  rather than proportional to the number of exercise names.
- Reuse the project's database and record-service test patterns for semantic
  equivalence where they can exercise the real record-calculation seam.
  External results—not SQL text or internal helper calls—are the assertions.
- The History fixture must cover best weight, estimated 1RM, volume, all cardio
  record metrics, ties, hidden sets, warmups, multiple workouts, and multiple
  bouts.
- Exercise image-heavy History and workout-detail screens with
  camera-resolution source images. Compare decoded-image memory and scrolling
  frame behavior, then visually confirm thumbnail sharpness and full-view
  quality on the phone.
- Verify the rest timer in idle, active, paused/backgrounded, adjusted,
  final-five-seconds, completed, sound, and vibration scenarios. Confirm there
  is no periodic timer work while idle and no regression in countdown accuracy
  or alerts.
- Do not use debug-build animation smoothness or startup time as a pass/fail
  criterion. Debug builds may still be large and janky by design.
- A good test asserts user-observable size, behavior, record results, and
  performance boundaries. It does not lock tests to widget-tree shape, exact
  SQL strings, or a particular timer implementation.

## Out of Scope

- Removing JackedLog features to reduce binary size.
- Dropping arm64-v8a, armeabi-v7a, or x86_64 device support.
- Treating the debug APK as a distributable artifact or trying to remove
  Flutter's debug JIT, hot-reload, validation, and service overhead.
- Cleaning the local build cache as an application-size optimization.
- Replacing SQLite, Drift, file selection, Spotify, notifications, or audio
  subsystems solely for sub-megabyte savings.
- Obfuscation as a size strategy.
- Redesigning the Home navigation or tab transition.
- Changing record definitions or cardio semantics.
- Resizing or recompressing users' original image files destructively.
- Database schema or exported-data changes.
- Server deployment or server-side performance work.

## Further Notes

- Measured artifacts from the investigation:
  - Debug APK: 113.36 MiB.
  - Universal release APK: 66.79 MiB.
  - arm64-v8a split release: 24.31 MiB, a 63.6% reduction.
  - armeabi-v7a split release: 22.44 MiB.
  - x86_64 split release: 25.80 MiB.
- The connected physical Android phone reports arm64-v8a.
- The universal release's dominant contents are three native stacks:
  approximately 21.41 MiB arm64, 19.52 MiB ARMv7, and 22.89 MiB x86_64.
- A nominally arm64-only non-split build was 27.26 MiB because SQLite native
  libraries for the other ABIs were still included. The true split artifact
  removed that residual overhead.
- Packaged Flutter assets are approximately 0.56 MiB compressed. Asset cleanup
  and dependency trimming should be reconsidered only after higher-impact work
  is complete and a new artifact analysis identifies a regression.
- Static review establishes credible runtime candidates but not their
  magnitude. Before/after device profiles are required to turn those
  candidates into performance claims.

