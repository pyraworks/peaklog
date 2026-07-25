# Flutter Flavors (dev/prod) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `dev` and `prod` Flutter flavors (Android product flavors, iOS schemes/configurations) with distinct applicationId/bundle ID and app name, without touching business logic or Firebase configuration.

**Architecture:** Extract `main.dart`'s startup logic into a shared `lib/bootstrap.dart` function called by both `lib/main.dart` (prod entrypoint, unchanged behavior) and a new `lib/main_dev.dart`. On Android, add a `productFlavors` block (`dev`, `prod`) to `android/app/build.gradle.kts` with per-flavor `applicationId` and `resValue("string","app_name", ...)`, referenced from the manifest via `@string/app_name`. On iOS, purely additively duplicate the existing Debug/Release/Profile build configurations into `Debug-dev/Release-dev/Profile-dev` and `Debug-prod/Release-prod/Profile-prod` (backed by new per-flavor `.xcconfig` files under `ios/Flutter/Flavors/`), and add two new Xcode schemes named `dev` and `prod` (Flutter's `--flavor` matches scheme name). Existing `Debug`/`Release`/`Profile` configs and the `Runner` scheme are left untouched byte-for-byte, so `flutter run`/`flutter build` without `--flavor` keeps working exactly as before.

**Tech Stack:** Flutter 3.44.1, Kotlin DSL Gradle (AGP 9.0.1), Xcode 26.6 project (pbxproj + xcscheme XML), Firebase (google-services 4.5.0 / Crashlytics 3.0.7 Gradle plugins).

## Global Constraints

- Keep `lib/main.dart` as the production entrypoint; behavior must be identical to today.
- Do not modify business logic anywhere in `lib/`.
- Android prod applicationId: `com.pyraworks.peaklog`. Android dev applicationId: `com.pyraworks.peaklog.dev`.
- iOS prod bundle id: `com.pyraworks.peaklog`. iOS dev bundle id: `com.pyraworks.peaklog.dev`.
- App name prod: `PeakLog`. App name dev: `PeakLog Dev`.
- Do NOT configure a new/separate Firebase project. Do NOT modify `lib/firebase_options.dart`. Do NOT modify `android/app/google-services.json` or `ios/Runner/GoogleService-Info.plist` — both only register `com.pyraworks.peaklog`, so the `dev` applicationId/bundle id will not match. This is a known, accepted gap (no Firebase for dev flavor yet); the existing `try/catch` around `Firebase.initializeApp()` in current `main.dart` already tolerates init failure and must be preserved as-is in the shared bootstrap.
- Do not change app icons.
- Existing production build/run/archive flow must be unaffected by this change (verified by leaving all pre-existing pbxproj objects, the `Runner` scheme, and Android's un-flavored defaults untouched).

## Known risk (discovered during investigation, resolve empirically in Task 2)

`android/app/google-services.json` registers only `com.idaeun.peaklog` and `com.pyraworks.peaklog` as clients — **not** `com.pyraworks.peaklog.dev`. The `com.google.gms.google-services` Gradle plugin hard-fails the build ("No matching client found for package name...") when it can't find a client for the applicationId being built. Since we're forbidden from touching `google-services.json`, Task 2 must disable Google-Services (and verify Crashlytics) Gradle task processing specifically for the `dev` flavor's variants, confirmed by actually running `flutter build apk --flavor dev` and reading the real Gradle task names/errors (do not guess task names — AGP/plugin versions change them).

---

### Task 1: Extract shared Flutter bootstrap; add `main_dev.dart`

**Files:**
- Create: `lib/bootstrap.dart`
- Modify: `lib/main.dart`
- Create: `lib/main_dev.dart`

**Interfaces:**
- Produces: `Future<void> bootstrap()` in `lib/bootstrap.dart` — contains exactly the current body of `main()` (unchanged logic, only lifted into a named function), imports unchanged.

- [ ] **Step 1:** Create `lib/bootstrap.dart` by moving the full current body of `lib/main.dart`'s `main()` function (WidgetsFlutterBinding init, SharedPreferences/launchScreen read, Firebase try/catch init incl. Crashlytics wiring, analytics log, `runApp(...)`) into `Future<void> bootstrap() async { ... }`, keeping every line identical. Keep all existing imports (`dart:async`, `flutter/foundation.dart`, `flutter/material.dart`, `flutter_riverpod`, `firebase_core`, `firebase_analytics`, `firebase_crashlytics`, `shared_preferences`, `app.dart`, `core/services/analytics_service.dart`, `firebase_options.dart`, `providers/analytics_provider.dart`, `providers/launch_screen_provider.dart`).
- [ ] **Step 2:** Replace `lib/main.dart` contents with:
  ```dart
  import 'bootstrap.dart';

  void main() => bootstrap();
  ```
- [ ] **Step 3:** Create `lib/main_dev.dart`:
  ```dart
  import 'bootstrap.dart';

  void main() => bootstrap();
  ```
- [ ] **Step 4:** Run `flutter analyze` — expect no issues (imports must resolve, no unused-import warnings in the now-slim `main.dart`).
- [ ] **Step 5:** Run `flutter test` — expect same pass count as before (134 tests), confirming no behavior change.
- [ ] **Step 6:** Commit: `git add lib/bootstrap.dart lib/main.dart lib/main_dev.dart && git commit -m "Extract shared app bootstrap for flavor entrypoints"`

---

### Task 2: Android product flavors

**Files:**
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1:** In `android/app/build.gradle.kts`, inside the `android { ... }` block, immediately after the closing brace of `defaultConfig { ... }`, add:
  ```kotlin
      flavorDimensions += "environment"
      productFlavors {
          create("dev") {
              dimension = "environment"
              applicationId = "com.pyraworks.peaklog.dev"
              resValue("string", "app_name", "PeakLog Dev")
          }
          create("prod") {
              dimension = "environment"
              applicationId = "com.pyraworks.peaklog"
              resValue("string", "app_name", "PeakLog")
          }
      }
  ```
- [ ] **Step 2:** In `android/app/src/main/AndroidManifest.xml`, change `android:label="PeakLog"` to `android:label="@string/app_name"` on the `<application>` element.
- [ ] **Step 3:** Attempt a real build to discover the actual failure mode: run `flutter build apk --flavor dev --debug -t lib/main_dev.dart` from the project root. Read the Gradle error output carefully — expect a `com.google.gms.google-services` failure of the form "No matching client found for package_name 'com.pyraworks.peaklog.dev'" (per the Known Risk section above). Confirm the exact failing task name printed by Gradle (e.g. `processDevDebugGoogleServices` — do not assume, read it from the actual output).
- [ ] **Step 4:** At the bottom of `android/app/build.gradle.kts` (after the closing brace of the `android { ... }` block, alongside the existing `flutter { source = "../.." }` block), add a task-disabling guard using the *exact* task-name substring confirmed in Step 3, e.g.:
  ```kotlin
  // google-services.json only registers the "prod" applicationId (com.pyraworks.peaklog).
  // Skip Google Services processing for the "dev" flavor so the build doesn't hard-fail
  // with "No matching client found" until a dev Firebase app is registered. Firebase
  // init already tolerates failure at the Dart layer (see lib/bootstrap.dart).
  tasks.whenTaskAdded {
      if (name.contains("Dev") && name.endsWith("GoogleServices")) {
          enabled = false
      }
  }
  ```
  Adjust the `if` condition to match the real task name pattern observed in Step 3 if it differs.
- [ ] **Step 5:** Re-run `flutter build apk --flavor dev --debug -t lib/main_dev.dart`. If it still fails, check whether `com.google.firebase.crashlytics` also has a per-variant task that fails on the mismatched package (read the new error), and extend the same `tasks.whenTaskAdded` guard to also disable that task name for `dev` variants. Iterate until the build succeeds.
- [ ] **Step 6:** Run `flutter build apk --flavor prod --debug -t lib/main.dart` — must succeed with no changes in behavior (this flavor's applicationId matches the existing `google-services.json` client, so no guard should apply to it).
- [ ] **Step 7:** Run `flutter build apk --debug` (no `--flavor`, current default entrypoint `lib/main.dart`) to confirm the pre-existing unflavored build still works — this is the safety check that production packaging (if anything still invokes a flavor-less build) is unaffected. Note: since `flavorDimensions` is now declared, Gradle requires a flavor to be selected for `assemble`/`bundle` tasks going forward — if this step errors asking to specify a flavor, that is expected/acceptable (document it in the final summary) since `--flavor prod`/`--flavor dev` are the new required invocations; just confirm `--flavor prod` behaves identically to the pre-flavor build (applicationId, app name, versionCode/versionName all match commit `c4c94dd`'s behavor).
- [ ] **Step 8:** Verify installed app identity end-to-end: `flutter install --flavor dev -t lib/main_dev.dart` (or run on the `Pixel_10_Pro` emulator, launched via `flutter emulators --launch Pixel_10_Pro`) then `adb shell pm list packages | grep pyraworks` to confirm both `com.pyraworks.peaklog` (if prod also installed) and `com.pyraworks.peaklog.dev` are present as distinct packages, and check the launcher label reads "PeakLog Dev".
- [ ] **Step 9:** Commit: `git add android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml && git commit -m "Add Android dev/prod product flavors"`

---

### Task 3: iOS schemes/configurations

**Files:**
- Create: `ios/Flutter/Flavors/Dev.xcconfig`
- Create: `ios/Flutter/Flavors/Prod.xcconfig`
- Create: `ios/Flutter/Flavors/Debug-dev.xcconfig`
- Create: `ios/Flutter/Flavors/Release-dev.xcconfig`
- Create: `ios/Flutter/Flavors/Profile-dev.xcconfig`
- Create: `ios/Flutter/Flavors/Debug-prod.xcconfig`
- Create: `ios/Flutter/Flavors/Release-prod.xcconfig`
- Create: `ios/Flutter/Flavors/Profile-prod.xcconfig`
- Modify: `ios/Runner.xcodeproj/project.pbxproj` (purely additive: 8 new `PBXFileReference`s, 1 new `PBXGroup` ("Flavors"), 12 new `XCBuildConfiguration`s — 6 at project level, 6 at the `Runner` target level — and the corresponding 2 `XCConfigurationList`s extended to reference the 6 new names each. Nothing existing is deleted or renamed.)
- Modify: `ios/Runner/Info.plist` (`CFBundleDisplayName` → `$(APP_DISPLAY_NAME)`)
- Create: `ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme`
- Create: `ios/Runner.xcodeproj/xcshareddata/xcschemes/prod.xcscheme`

**Design (fixed UUIDs to use — generated via `uuidgen`, do not regenerate):**

| Object | UUID |
|---|---|
| Dev.xcconfig (file ref) | `E997A55A1F92496E98BE1DB7` |
| Prod.xcconfig (file ref) | `634BCE9BD02D41FFBF5BCCEE` |
| Debug-dev.xcconfig (file ref) | `9408A0DFD4524E01BC30457B` |
| Release-dev.xcconfig (file ref) | `B419059A77764FECA0CF92A3` |
| Profile-dev.xcconfig (file ref) | `5CE93B7AA8D3417D9E40FDFC` |
| Debug-prod.xcconfig (file ref) | `D477890996AB48E29EB30A97` |
| Release-prod.xcconfig (file ref) | `47D859008CEC4B47968B704E` |
| Profile-prod.xcconfig (file ref) | `1EEC122B66FC4D6FAA250026` |
| "Flavors" PBXGroup | `4E90F659DAE24A28A926FAD8` |
| Debug-dev (PBXProject-level config) | `B608DC1D899B45F697F43E5F` |
| Release-dev (PBXProject-level config) | `0AAF6CDB928547D9B4EAA1CF` |
| Profile-dev (PBXProject-level config) | `38B2E99D10524267AE6CE347` |
| Debug-prod (PBXProject-level config) | `A1559CE323BC4C7E9F7306FE` |
| Release-prod (PBXProject-level config) | `C3E2C69240AE450C901CEE2E` |
| Profile-prod (PBXProject-level config) | `CE22B3577A094FA1BA021523` |
| Debug-dev (Runner target config) | `A8C2F6675CB54D1895C950DA` |
| Release-dev (Runner target config) | `DBFA849EFC424524AD9C71AE` |
| Profile-dev (Runner target config) | `9D679060FA854B28B9C8A218` |
| Debug-prod (Runner target config) | `C06158D03E524D22A60CBC70` |
| Release-prod (Runner target config) | `ED1ACC54427140E0821F6616` |
| Profile-prod (Runner target config) | `97E7CFF54E684075AF1E7228` |

Rule for the 6 new **PBXProject-level** `XCBuildConfiguration`s: byte-identical `buildSettings` to the existing project-level `Debug`/`Release`/`Profile` (`97C147031CF9000F007C117D`/`97C147041CF9000F007C117D`/`249021D3217E4FDB00AE95B9`) respectively — only `name` differs (`Debug-dev`, `Release-dev`, `Profile-dev`, `Debug-prod`, `Release-prod`, `Profile-prod`), no `baseConfigurationReference`.

Rule for the 6 new **Runner target** `XCBuildConfiguration`s: same `buildSettings` as the existing target-level `Debug`/`Release`/`Profile` (`97C147061CF9000F007C117D`/`97C147071CF9000F007C117D`/`249021D4217E4FDB00AE95B9`) respectively, **except**: remove the `PRODUCT_BUNDLE_IDENTIFIER` line and the `INFOPLIST_KEY_CFBundleDisplayName` line (both now come from the flavor xcconfig / Info.plist variable instead), and set `baseConfigurationReference` to the matching new xcconfig file ref instead of `Debug.xcconfig`/`Release.xcconfig`.

- [ ] **Step 1:** Create `ios/Flutter/Flavors/Dev.xcconfig`:
  ```
  PRODUCT_BUNDLE_IDENTIFIER = com.pyraworks.peaklog.dev
  APP_DISPLAY_NAME = PeakLog Dev
  ```
- [ ] **Step 2:** Create `ios/Flutter/Flavors/Prod.xcconfig`:
  ```
  PRODUCT_BUNDLE_IDENTIFIER = com.pyraworks.peaklog
  APP_DISPLAY_NAME = PeakLog
  ```
- [ ] **Step 3:** Create `ios/Flutter/Flavors/Debug-dev.xcconfig`:
  ```
  #include "../Debug.xcconfig"
  #include "Dev.xcconfig"
  ```
- [ ] **Step 4:** Create `ios/Flutter/Flavors/Release-dev.xcconfig`:
  ```
  #include "../Release.xcconfig"
  #include "Dev.xcconfig"
  ```
- [ ] **Step 5:** Create `ios/Flutter/Flavors/Profile-dev.xcconfig` (Profile reuses Release.xcconfig as its base, matching the existing Profile config's `baseConfigurationReference`):
  ```
  #include "../Release.xcconfig"
  #include "Dev.xcconfig"
  ```
- [ ] **Step 6:** Create `ios/Flutter/Flavors/Debug-prod.xcconfig`:
  ```
  #include "../Debug.xcconfig"
  #include "Prod.xcconfig"
  ```
- [ ] **Step 7:** Create `ios/Flutter/Flavors/Release-prod.xcconfig`:
  ```
  #include "../Release.xcconfig"
  #include "Prod.xcconfig"
  ```
- [ ] **Step 8:** Create `ios/Flutter/Flavors/Profile-prod.xcconfig`:
  ```
  #include "../Release.xcconfig"
  #include "Prod.xcconfig"
  ```
- [ ] **Step 9:** In `ios/Runner.xcodeproj/project.pbxproj`, `/* Begin PBXFileReference section */`: append the 8 new file references (using the UUIDs table above), e.g.:
  ```
  		E997A55A1F92496E98BE1DB7 /* Dev.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = Dev.xcconfig; path = Flutter/Flavors/Dev.xcconfig; sourceTree = "<group>"; };
  ```
  ...and one line per remaining file (`Prod.xcconfig`, `Debug-dev.xcconfig`, `Release-dev.xcconfig`, `Profile-dev.xcconfig`, `Debug-prod.xcconfig`, `Release-prod.xcconfig`, `Profile-prod.xcconfig`), each following the same pattern with `path = "Flutter/Flavors/<name>.xcconfig"` and quoting `name`/`path` for any name containing a hyphen.
- [ ] **Step 10:** In `/* Begin PBXGroup section */`, add the new group (place it right before `/* End PBXGroup section */`):
  ```
  		4E90F659DAE24A28A926FAD8 /* Flavors */ = {
  			isa = PBXGroup;
  			children = (
  				E997A55A1F92496E98BE1DB7 /* Dev.xcconfig */,
  				634BCE9BD02D41FFBF5BCCEE /* Prod.xcconfig */,
  				9408A0DFD4524E01BC30457B /* Debug-dev.xcconfig */,
  				B419059A77764FECA0CF92A3 /* Release-dev.xcconfig */,
  				5CE93B7AA8D3417D9E40FDFC /* Profile-dev.xcconfig */,
  				D477890996AB48E29EB30A97 /* Debug-prod.xcconfig */,
  				47D859008CEC4B47968B704E /* Release-prod.xcconfig */,
  				1EEC122B66FC4D6FAA250026 /* Profile-prod.xcconfig */,
  			);
  			name = Flavors;
  			sourceTree = "<group>";
  		};
  ```
  Then add `4E90F659DAE24A28A926FAD8 /* Flavors */,` to the `children` array of the existing `9740EEB11CF90186004384FC /* Flutter */` group (right after the `Generated.xcconfig` line).
- [ ] **Step 11:** In `/* Begin XCBuildConfiguration section */`, add 6 new project-level blocks (copy `buildSettings` verbatim from `97C147031CF9000F007C117D`/`97C147041CF9000F007C117D`/`249021D3217E4FDB00AE95B9` respectively, only changing the object UUID and `name`), then 6 new Runner-target blocks (copy `buildSettings` from `97C147061CF9000F007C117D`/`97C147071CF9000F007C117D`/`249021D4217E4FDB00AE95B9` respectively, drop the `PRODUCT_BUNDLE_IDENTIFIER` and `INFOPLIST_KEY_CFBundleDisplayName` lines, point `baseConfigurationReference` at the matching new xcconfig file ref from the table). Use the UUIDs from the table above for each.
- [ ] **Step 12:** In `/* Begin XCConfigurationList section */`, extend `97C146E91CF9000F007C117D` (`Build configuration list for PBXProject "Runner"`)'s `buildConfigurations` array with the 6 new project-level config UUIDs, and extend `97C147051CF9000F007C117D` (`Build configuration list for PBXNativeTarget "Runner"`)'s `buildConfigurations` array with the 6 new Runner-target config UUIDs. Do not touch `331C8087294A63A400263BE5` (RunnerTests) — it stays on plain Debug/Release/Profile.
- [ ] **Step 13:** Validate the pbxproj is well-formed: run `plutil -lint ios/Runner.xcodeproj/project.pbxproj` — must report `OK`.
- [ ] **Step 14:** In `ios/Runner/Info.plist`, change:
  ```xml
  	<key>CFBundleDisplayName</key>
  	<string>PeakLog</string>
  ```
  to:
  ```xml
  	<key>CFBundleDisplayName</key>
  	<string>$(APP_DISPLAY_NAME)</string>
  ```
- [ ] **Step 15:** Create `ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme` as a copy of the existing `Runner.xcscheme`, with `LaunchAction buildConfiguration` changed from `"Debug"` to `"Debug-dev"`, `ProfileAction buildConfiguration` changed from `"Profile"` to `"Profile-dev"`, and `ArchiveAction buildConfiguration` changed from `"Release"` to `"Release-dev"`. Leave `TestAction`/`AnalyzeAction` `buildConfiguration="Debug"` unchanged (RunnerTests isn't flavored). Leave all `BuildableReference`/`BlueprintIdentifier` values identical to `Runner.xcscheme` (same underlying `Runner`/`RunnerTests` targets).
- [ ] **Step 16:** Create `ios/Runner.xcodeproj/xcshareddata/xcschemes/prod.xcscheme` the same way, with `Debug-prod`/`Profile-prod`/`Release-prod` in place of `Debug-dev`/`Profile-dev`/`Release-dev`.
- [ ] **Step 17:** Run `cd ios && pod install && cd ..` if needed (only if CocoaPods complains; the Podfile's per-configuration includes for `Pods-Runner.debug/release/profile.xcconfig` are keyed by the *Debug/Release/Profile* Xcode configuration group set in the Podfile's `project 'Runner', {...}` mapping — confirm `Debug-dev`/`Debug-prod`/etc. resolve correctly; if `pod install` or the build below complains about unmapped configurations, add them to the `Podfile`'s configuration map, e.g. `'Debug-dev' => :debug, 'Release-dev' => :release, 'Profile-dev' => :release, 'Debug-prod' => :debug, 'Release-prod' => :release, 'Profile-prod' => :release` alongside the existing `Debug`/`Profile`/`Release` entries, then re-run `pod install`).
- [ ] **Step 18:** Verify: `flutter build ios --flavor dev --no-codesign -t lib/main_dev.dart` — must succeed. If it fails, read the actual Xcode/xcodebuild error (systematic debugging: don't guess, read the error) and fix the specific misconfigured setting.
- [ ] **Step 19:** Verify: `flutter build ios --flavor prod --no-codesign -t lib/main.dart` — must succeed.
- [ ] **Step 20:** Verify existing behavior is unaffected: `flutter build ios --no-codesign` (no `--flavor`, default `lib/main.dart` entrypoint, uses the untouched `Runner` scheme + `Debug`/`Release`/`Profile` configs) — must succeed identically to before this change.
- [ ] **Step 21:** If a physical/simulator device is available, run `flutter run --flavor dev -t lib/main_dev.dart -d <device-id>` and confirm the installed app's home-screen label reads "PeakLog Dev" and its bundle id is `com.pyraworks.peaklog.dev` (`ideviceinstaller -l` or Xcode's Devices window, or on Simulator: `xcrun simctl listapps booted | grep -A3 peaklog`).
- [ ] **Step 22:** Commit: `git add ios/ && git commit -m "Add iOS dev/prod schemes and build configurations"`

---

### Task 4: Final verification and documentation

- [ ] **Step 1:** Run `flutter analyze` from the project root — must report "No issues found!".
- [ ] **Step 2:** Run `flutter test` — must report the same pass count as the pre-change baseline (134 tests), confirming zero business-logic regressions.
- [ ] **Step 3:** Write a summary (in the final chat response, not a new file) explaining every changed/created file, and exact run commands for each flavor:
  - `flutter run --flavor dev -t lib/main_dev.dart`
  - `flutter run --flavor prod -t lib/main.dart` (or plain `flutter run` for the default/prod entrypoint)

## Self-Review Notes

- Spec coverage: Flutter entrypoints (Task 1), Android flavors/applicationId/app name (Task 2), iOS schemes/configurations/bundle id/app name (Task 3), Firebase left untouched (enforced as a constraint + the Known Risk workaround only *disables processing*, never edits Firebase config files), icons untouched (no icon-related file touched anywhere in this plan), final analyze/test + explanation (Task 4).
- Placeholder scan: all file contents given in full; the only intentionally-deferred value is the exact Gradle task name for the Google Services guard, which cannot be known without running the real build — Task 2 Step 3 makes discovering it via a real build the explicit first action, not a guess.
- Type/name consistency: `bootstrap()` name matches between its definition (Task 1 Step 1) and both call sites (Task 1 Steps 2–3). UUIDs in Task 3's table are referenced consistently across Steps 9–16.
