# Beta (0.14.0) — plan

**Goal:** the app leaves the emulator. It gets its final app ID, public source on GitHub, checks
on every push, a properly signed release APK, and a way for testers to install and update it,
including F-Droid-style through IzzyOnDroid.

> **Status:** postponed (2026-10-29); moved from 0.10.0 to 0.11.0 on 2026-11-02, after the
> better schedules (0.10.0), to 0.12.0 the same day, after loot & gear (0.11.0), to 0.13.0 after the game data catalog
> (0.12.0), and to 0.14.0 after the testers' fight feedback (0.13.0). The GitHub repository and the Google Play developer
> account are being prepared first.

## Defaults (2026-10-29)
You stated no preference, so these are the recommended options. Each can still change before the
work starts.

| Question | Default |
|---|---|
| App ID | `io.github.<github-user>.homework_and_chores`. **Needs your GitHub username.** |
| GitHub | Public repository from the beta on (GPL-3.0) |
| Distribution | Signed APKs on GitHub Releases, plus the IzzyOnDroid repository. The main F-Droid repository comes at 1.0. |
| Signing key | A key file on your PC (not in Dropbox) with an offline backup, plus encrypted GitHub secrets so CI signs tagged releases |

## Where things stand (0.9.0)
| Area | State | Problem |
|---|---|---|
| App ID | `io.github.changeme.homework_and_chores`, in 9 places (Gradle, the Kotlin package and folder, the receiver action, a test, docs) | Placeholder. Changing it after testers install means a new app: their data stays behind unless they back up first. |
| Release signing | The release build is signed with the **debug key** (Flutter's template TODO) | A debug-signed APK can't be updated by a properly signed one, and F-Droid/IzzyOnDroid need a stable key. |
| GitHub | No remote; `gh` isn't installed | — |
| CI | None; the checks in CONTRIBUTING run by hand | — |
| SQLite | The `sqlite3` package **downloads a precompiled SQLite** at build time (its default build hook) | F-Droid builds offline and doesn't accept prebuilt binaries. The hook can compile from the SQLite source instead (public domain). |
| Google's dependency info | Android Gradle adds an encrypted "dependencies info" block to the APK | F-Droid and IzzyOnDroid ask for it to be turned off (`dependenciesInfo { includeInApk = false }`). |
| Store listing | No `fastlane/metadata` | Needed by F-Droid/IzzyOnDroid: title, short and full description (EN/DE), screenshots, a changelog per version code. |
| Asset licenses | `ASSETS_LICENSES.md` lacks the Press Start 2P font (OFL) and the `assets/art` sprites | Must be complete for a GPL/F-Droid release. |
| Permissions | No `INTERNET`; usage access, notifications, boot completed | Fine; the listing should explain usage access. |

## Work
### 1. Final app ID
- **Rename everywhere:**
  - Gradle `namespace` and `applicationId`
  - move the Kotlin package folder and update its `package` lines
  - the `SCREEN_TIME_CHECK` broadcast action in the code and the manifest
  - the test that names it, and the docs
- **No migration needed:** nobody but us has installed the placeholder ID.
- **Test:** a new test fails if the string `changeme` turns up anywhere in `lib/`, `android/` or `test/`.

### 2. Release signing
- **Your step:** you create the key on your PC with `keytool`. A small script, `tool/new_release_key.ps1`, will prompt for the passwords itself, so they never pass through me.
  - The file lives outside Dropbox (e.g. `%USERPROFILE%\keys\homework-chores.jks`), with a second copy offline.
- **Gradle** reads `android/key.properties` (already in `.gitignore`) for local builds. Without it, a release build **fails** instead of quietly using the debug key.
- **CI** gets the keystore (base64) and its passwords as encrypted repository secrets. Only builds of `v*` tags sign.
- **Check:** after building, `apksigner verify --print-certs` must show the release certificate. The SHA-256 fingerprint goes into README, so testers can verify downloads.

### 3. F-Droid-friendly build
- **SQLite:** `sqlite3` compiles the SQLite source (via `hooks: user_defines` in `pubspec.yaml`) instead of downloading a library. To confirm: the APK still opens databases, and an offline build works (`flutter build apk` with the network blocked).
- **Dependency info:** `dependenciesInfo { includeInApk = false; includeInBundle = false }`.
- **Toolchain:** pin the Flutter version in a `.flutter-version` file (and in CI), so F-Droid and CI build with the same Flutter.
- **Dependency audit:** check every package for network use, Google Play Services and prebuilt binaries. As known today: `audioplayers` uses ExoPlayer (Apache-2.0, fine), and `flutter_local_notifications` needs no Play Services.

### 4. GitHub and CI
- **Your step:** create the repository (public) and authorize the push; I'll run `gh` once it's installed and you've logged in. The first push is the history up to 0.14.0, all tags included.
- **`.github/workflows/check.yml`**, on every push and pull request:
  - `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`
  - `python tool/build_art.py --check`
  - generated code up to date (`build_runner` and `gen-l10n`, then `git diff --exit-code`)
  - `flutter build apk --release` (unsigned), then **no-INTERNET check**: `aapt2 dump permissions` must not list `android.permission.INTERNET`
- **`.github/workflows/integration.yml`**, weekly and by hand: the integration test on an Android emulator (`reactivecircus/android-emulator-runner`). It's slow, so it doesn't run on every push.
- **`.github/workflows/release.yml`**, on `v*` tags:
  - build the signed APK and verify its certificate
  - create a GitHub Release with the APK, its SHA-256, and the changelog section for that version

### 5. Store listing (fastlane)
- **`fastlane/metadata/android/en-US/` and `de-DE/`:**
  - `title.txt`, `short_description.txt` (80 characters at most) and `full_description.txt`
  - `images/icon.png`, plus `images/phoneScreenshots/` from the emulator, in light and dark
  - `changelogs/<versionCode>.txt`
- **Full description:** the quest idea, privacy (no internet, no account), usage access explained, and backups.
- **`tool/bump_version.ps1`** also writes the new `changelogs/<versionCode>.txt` from CHANGELOG.

### 6. Licenses and docs
- **`ASSETS_LICENSES.md`:** add the Press Start 2P font (OFL, `assets/fonts/OFL.txt`) and `assets/art` (see `assets/art/CREDITS.md`).
- **README:**
  - install from GitHub or IzzyOnDroid
  - the certificate fingerprint
  - how to report bugs
  - the beta status
- **Issue templates:** a bug report asking for app version, Android version and steps.

### 7. Testing on real phones
- **Who:** the beta goes to a few people, ideally a household with two or more people.
- **What to check:**
  - first start
  - backup to a real sync folder and restore on a second phone
  - notifications after a reboot, and Doze (in battery saver)
  - screen time with real usage
  - fights on a slow phone, and latency calibration with Bluetooth headphones
- **Known risk areas** from the emulator:
  - notification timing after Doze
  - folder access on vendor file managers (Samsung, Xiaomi)
  - audio latency on cheap devices
- **Fixes** land as 0.14.x patch releases.

### 8. IzzyOnDroid
- After the first signed GitHub release, request inclusion at IzzyOnDroid.
- It picks up new GitHub releases automatically and checks the signing key stays the same.
- The fastlane metadata from step 5 provides the listing.

### 9. Google Play (added 2026-10-29)
You're registering as a Google Play developer, so Play becomes a third channel next to GitHub
Releases and IzzyOnDroid. What that changes:
- **One signing key for all stores.** Android updates an app only from APKs signed with the same
  key. Play App Signing normally creates and keeps its own key. Then someone who installed from
  GitHub or IzzyOnDroid couldn't update from Play, or the other way round, without uninstalling and
  restoring a backup.
  - Play lets you upload your own app signing key instead, using the "use the same key as other
    distribution channels" option. Do that with the key from step 2.
  - Play also wants a separate **upload key**, which can be a second key from the same script.
  - Decide this **before** the first Play upload, because it can't be undone later.
- **App Bundle:** Play takes an `.aab` (`flutter build appbundle`). The release workflow builds the
  AAB next to the APK.
- **Target SDK:** Play requires a recent `targetSdk` for new apps. Flutter's default is current
  today; CI should check it before each release.
- **Testing before production:** new personal developer accounts must run a **closed test with at
  least 12 testers for 14 days** before the app can go to production. The real-phone testing in
  step 7 can be that closed test.
- **Store listing:** the fastlane texts and screenshots from step 5 can be reused. Play also wants
  a 512×512 icon and a 1024×500 feature graphic.
- **Play Console forms:**
  - **Data safety:** no data collected or shared, since nothing leaves the phone. Optional backups are
    files the user saves, and Android's own system backup is the user's setting.
  - **Privacy policy URL:** PRIVACY.md published on GitHub works.
  - **Content rating questionnaire** and **target audience**. If children are a target audience,
    the Families policy applies: no ads and no tracking, which the app meets.
- **Usage access:** `PACKAGE_USAGE_STATS` isn't on Play's list of permissions that need a declaration
  form, but the listing and the app must explain why it's used. Screen time already explains it
  before asking for access. Check Play's policy again when submitting, as it changes.
- **No change to the app's rules:** the app still uses no Google Play Services or network. Play is
  only a store here.

## Who does what
| Step | You | Me |
|---|---|---|
| App ID | Tell me your GitHub username | Rename, test, docs |
| Signing key | Run the key script, keep the passwords and the backup | Script, Gradle config, verification |
| GitHub | Create the repo, install and log in to `gh`, add the secrets | Workflows, first push (with your OK) |
| IzzyOnDroid | Send the inclusion request (it's your project and account) | Prepare the metadata, check the requirements |
| Google Play | Developer account, Play Console forms, app signing choice (your own key), closed-test testers | AAB build, listing texts and graphics, Data safety answers to copy in |
| Real phones | Find testers, install | Release notes, triage, fixes |

## Order
1. App ID, the `changeme` test, and the license and README updates. Nothing outside the repo is needed.
2. F-Droid-friendly build: SQLite from source, the dependency info block, the Flutter pin, the dependency audit.
3. Signing setup, then you create the key, then a signed local build verified on the emulator.
4. Fastlane metadata and screenshots.
5. GitHub: you create the repo, I push and add the workflows, and CI turns green.
6. Tag v0.14.0, with a signed release from CI; you then send the IzzyOnDroid request.
7. Testing on real phones, with patch releases as needed.

## Risks
- **SQLite from source:**
  - the build hook needs the Android NDK's C compiler, which Flutter's Android setup provides
  - to check: CI time and APK size
- **Reproducible builds:** not aimed for in the beta. IzzyOnDroid uses our APKs as they are, and F-Droid main (at 1.0) signs with its own key unless builds are reproducible.
- **Generated files in CI:** CI regenerates Drift code and must produce no diff. Line endings could differ on Windows-made files, so a `.gitattributes` with `eol=lf` keeps checkouts identical.
