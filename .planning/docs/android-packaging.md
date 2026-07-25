# Android packaging

## What to ship

Run `./scripts/build-release`. It produces:

| Artifact | Use |
| --- | --- |
| `build/app/outputs/flutter-apk/app-<abi>-release.apk` | direct download / sideload, one per ABI |
| `build/app/outputs/bundle/release/app-release.aab` | store upload; the store delivers ABI-specific splits |

`arm64-v8a` is what current phones (including the test device) run.
`armeabi-v7a` and `x86_64` remain supported — this is a packaging change, not a
device-support change. Version codes are already offset per ABI in
`android/app/build.gradle` (`ext.abiCodes`) so the same release can carry all
three.

The script fails the build if a split APK contains more than one ABI.

## The universal APK

`./scripts/build-release --universal` also builds `app-release.apk`, which
bundles all three native stacks. It exists only for "install anywhere" cases
where the target ABI is unknown. It is roughly 3x the size of the artifact any
single device needs, so it is not a normal release output.

## Baseline sizes

Measured at v1.4.1+7, same source revision:

| Artifact | Size |
| --- | --- |
| Universal release APK | 66.79 MiB |
| arm64-v8a split | 24.31 MiB (−63.6%) |
| armeabi-v7a split | 22.44 MiB |
| x86_64 split | 25.80 MiB |
| Debug APK | 113.36 MiB |

Compare future releases against these numbers using the size table
`build-release` prints.

## What is *not* application size

- **The debug APK.** It carries the Flutter JIT runtime, hot reload, assertions,
  the service protocol and validation libraries. That overhead is development
  tooling and cannot — and should not — be optimized out. Never quote it as a
  shipped size, and never judge performance from a debug build.
- **`build/`.** Unstripped intermediate `.so` files and stale plugin outputs
  live there. Only the packaged artifact counts.

## Where the bytes actually are

The universal APK is ~64 MiB of native code: ~21.4 MiB arm64, ~19.5 MiB ARMv7,
~22.9 MiB x86_64. Packaged Flutter assets are ~0.56 MiB compressed and every
declared runtime dependency is in use, so asset pruning and dependency removal
are not worth pursuing until a fresh artifact analysis says otherwise.

Note: a plain `--target-platform android-arm64` build without `--split-per-abi`
still ships the other ABIs' SQLite libraries (measured 27.26 MiB). Use the split
build, not the target-platform flag.
