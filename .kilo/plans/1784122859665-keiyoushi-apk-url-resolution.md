# Fix: Keiyoushi extension install fails — "No host specified in URI"

## Symptom
Adding a Keiyoushi repo works, but tapping **Install** on any extension fails with:
```
Install failed: invalid argument(s): No host specified in URI tachiyomi-all.ahottie-v1.4.3.apk
```

## Root cause
Keiyoushi `index.min.json` entries expose `apk` as a **relative path/filename** from the
repo root (e.g. `tachiyomi-all.ahottie-v1.4.3.apk`), not a full URL.

Current flow:
- `ExtensionIndexEntry.fromJson` stores `j['apk']` verbatim as `apkUrl`
  (`lib/core/services/extension_manager.dart:40`).
- `ExtensionManager.install()` passes `entry.apkUrl` straight into `_downloadApk()`
  (`extension_manager.dart:113`).
- `_downloadApk` calls `Uri.parse(url)` (`extension_manager.dart:187`); a bare filename
  has no host, so it throws.

The repo base URL is never joined to the APK path, and `install()` does not even receive
the repo URL — `_install` in the UI only passes the `ExtensionIndexEntry`.

## Fix (3 small, localized changes)

### 1. `lib/core/services/extension_manager.dart`
- Change `install` signature to carry the repo URL:
  `Future<ExtensionSource> install(ExtensionIndexEntry entry, {required String repoUrl}) async`
- Build the full download URL by resolving the relative APK path against the repo index
  directory:
  ```dart
  final fullApkUrl = Uri.parse(repoUrl).resolve(entry.apkUrl).toString();
  ```
  Example: `Uri.parse('https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json')
  .resolve('tachiyomi-all.ahottie-v1.4.3.apk')`
  → `https://raw.githubusercontent.com/keiyoushi/extensions/repo/tachiyomi-all.ahottie-v1.4.3.apk`
- Pass `fullApkUrl` to `_downloadApk` instead of `entry.apkUrl`.
- (Robustness) In `_downloadApk`, guard the input: if `Uri.parse(url).host.isEmpty`, throw a
  descriptive `ArgumentError('APK URL "$url" has no host — must be a full URL')` so this class
  of bug fails loudly in future.

### 2. `lib/features/extensions/extensions_screen.dart`
- Change `_install` to accept the repo URL and forward it:
  `Future<void> _install(ExtensionIndexEntry entry, String repoUrl) async`
  → `await _mgr.install(entry, repoUrl: repoUrl);`
- Change `_AvailableTab.onInstall` field type to
  `final void Function(ExtensionIndexEntry, String) onInstall;`
- In the `_AvailableTab` build loop `for (final repo in repos)`, bind the repo URL into the
  install closure:
  `onInstall: () => onInstall(e, repo.url)` (currently `onInstall: () => onInstall(e)`).
- Update the `_AvailableTab` constructor parameter type accordingly.

### 3. Version bump (per AGENTS.md)
After the change, bump the patch version in **both** files:
- `pubspec.yaml`: `version: 2.5.1+24` → `version: 2.5.2+25`
- `lib/features/settings/settings_screen.dart`: `subtitle: 'Version 2.5.1'` and
  `subtitle: 'Version 2.5.1 · build 2.5.1+24'` → `2.5.2`.

## Verification
1. `flutter analyze lib/` — expect no errors.
2. Run on device: Settings → Plugins → Manage plugins → Available → tap **Fetch** on
   "Keiyoushi (official)".
3. Tap **Install** on any extension (e.g. the `ahottie` one). Before the fix this threw
   "No host specified in URI"; after the fix the APK downloads and the extension appears under
   the **Installed** tab.
4. Confirm re-installing an already-downloaded extension is a no-op (apk present on disk,
   `_downloadApk` skipped) and uninstall removes the row + deletes the APK.

## Known limitation (out of scope, optional follow-up)
`ExtensionSource` does not persist the originating repo URL, so a future "update/re-download"
path would need the repo URL re-supplied. Current `install` only re-downloads when the APK is
absent from disk, so this does not affect the reported bug.
