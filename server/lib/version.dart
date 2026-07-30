/// Single source of truth for the running server version.
///
/// Bump this when cutting a release so the update checker can compare it
/// against the latest tag published on GitHub. Keep it in sync with the
/// repository's release tags (e.g. `v1.3.0`).
const String serverVersion = '1.3.1';

/// GitHub repository (`owner/name`) used by the update checker.
const String githubRepo = 'Aquatictw/JackedLog';
