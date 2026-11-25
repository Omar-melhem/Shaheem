# SHAHM Flutter — Store Submission Compliance (Apple App Store and Google Play)

**Canonical, permanently maintained checklist** for submitting the SHAHM
**captain-only** Flutter app (`mobile_frontend/`) to the Apple App Store and
Google Play. Created by Task 14 (documentation only).

- **Policy research baseline:** 2026-11-15. Every source below was opened on
  that date unless marked otherwise.
- **Store rules change.** Re-verify every material item against the official
  page (§11) when a release task starts and again immediately before each
  submission, and update the "Last verified" column.
- **This file is not store approval** and is **not legal advice.** It records
  store policy requirements, what the repository currently shows, and what
  must be decided by the owner or reviewed by a lawyer.
- **Research input:** the owner's snapshot
  `16_SHAHM_STORE_SUBMISSION_POLICY_REFERENCE_2026-11-15.md` (reference
  only, not certification) was cross-checked against this file on
  2026-11-15. All 13 of its sources are the same official pages listed in
  §11 and were re-read directly; the snapshot is not itself a source.
- **Evidence rule:** `verified met` only with concrete evidence (code/config
  path, a public URL, build output, or console evidence). Without it:
  `pending verification`. Console settings are never assumed.

---

> **Update 2026-11-22 (D-A81, Current Order workflow) — source changes,
> not store verification:**
> - Google Maps SDK keys: Android `com.google.android.geo.API_KEY` =
>   `${googleMapsApiKey}` (Gradle property `SHAHM_GOOGLE_MAPS_API_KEY`,
>   empty by default); iOS `GMSApiKey` = `$(SHAHM_GOOGLE_MAPS_API_KEY)`,
>   provided by `AppDelegate` only when non-empty. **No key is committed**;
>   restrict real keys by app (package/bundle + signing cert) and to the Maps
>   SDKs. The Dart map is built only with `--dart-define=SHAHM_GOOGLE_MAPS=true`.
> - Routes API: **no access design yet** (backend proxy vs app-restricted
>   key); nothing calls it; no unrestricted server key may ship in the app.
> - External navigation: Android `<queries>` for the `google.navigation`
>   scheme; iOS `LSApplicationQueriesSchemes` = `comgooglemaps`. Only the
>   Google Maps app is opened (non-browser mode); no other map app.
> - Map attribution: the app draws nothing over the Google map, so the logo
>   and attribution remain visible; verify on a real keyed build.
> - Customer phone: shown only on the delivery leg when supplied; never in
>   offers/push; include it in the data-safety declarations (P-02).
> - Verified: `flutter build ios --simulator --debug` succeeded 2026-11-22
>   (compiles the `GoogleMaps` import and plist keys). Gradle
>   `:app:processReleaseMainManifest` (manifest merge only, no APK) shows
>   `INTERNET`, the `google.navigation` query, label «شهم», an empty
>   `com.google.android.geo.API_KEY`, and the plugin-merged
>   `ACCESS_FINE/COARSE_LOCATION`, `FOREGROUND_SERVICE(_LOCATION)` and
>   `ACCESS_NETWORK_STATE` (G-05/G-06 still apply). **`flutter build apk
>   --debug` fails before this change set's code matters:**
>   `permission_handler_android` 14.1.1 (unchanged in the lockfile) requires
>   compileSdk 37, while the project compiles against 36 with Android Gradle
>   Plugin 9.0.1 — a toolchain upgrade task. No keyed build, no tile/route
>   rendering, no device run, no release build.

## 1. How to use this file

1. Before any release-related task (store builds, signing, permissions, GPS,
   push, legal links, metadata, privacy declarations), read this file and
   `../project/PROJECT_STATUS.md`.
2. Work on the items marked **Blocker: yes** first; never mark one met
   without the evidence named in its row.
3. When code or config changes an item, update its row (status, evidence,
   date) in the same task.
4. Store policy changes: replace the requirement text, the source URL and
   the "Last verified" date; do not keep stale constants.

Status values: **verified met** · **verified missing** · **pending
verification** · **conditional** (depends on a future feature or an owner
decision). Applicability: **mandatory** · **conditional** · **not
applicable**.

## 2. Three different things (never mix them)

| Concept | What it is | Store relevance for SHAHM |
|---|---|---|
| **Privacy Policy** | A public document describing what personal data the app and its SDKs collect, why, sharing, retention/deletion, and a privacy contact | **Mandatory on both stores**, in the store console **and** inside the app (§4, P-01) |
| **Terms & Conditions** | The contract between SHAHM and its captains (planned separate public web page, Task 13) | **Not a general store requirement.** Apple's Terms of Use/EULA link is required only in specific contexts (e.g. auto-renewable subscriptions, Guideline 3.1.2), which SHAHM does not have. A Terms button **never** satisfies privacy obligations |
| **User consent** | A clear affirmative action before specific data collection (e.g. prominent disclosure followed by the OS permission prompt) | Required for sensitive data such as location (§4, P-05; §5, G-04) |

A Terms **acceptance checkbox** or mandatory agreement step is a separate
legal/product decision: it is **not** approved (Task 13), is not created by
adding a Terms link, and is not privacy consent or permission consent.

## 3. Repository snapshot (evidence inspected 2026-11-15)

Inspected on branch `Yousef-Hamdan`, HEAD `0c2fc2c`, with uncommitted work.
This is what the **source** shows, not the approved target architecture.

| Area | Current state | Evidence |
|---|---|---|
| App identity | Package `com.example.mobile_frontend` (Android), bundle ID `com.example.mobileFrontend` (iOS); label **«شهم»** and iOS `CFBundleDisplayName`/`CFBundleName` **«شهم»** since R09 (2026-11-22; before: `mobile_frontend` / `Mobile Frontend`); package/bundle identifiers still the template values (owner input, not changed); version `0.1.0+1` | `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj`, `pubspec.yaml` |
| Android SDK levels | `compileSdk`/`targetSdk` = `flutter.*SdkVersion` = **36**, `minSdk` 24 (Flutter 3.44.6 tool defaults) | `build.gradle.kts`; `flutter_tools/gradle/.../FlutterExtension.kt` |
| Android release signing | **Debug keys** (`signingConfig = signingConfigs.getByName("debug")`, with a TODO) | `android/app/build.gradle.kts` |
| Android permissions | Main manifest declares `INTERNET` since R09 (2026-11-22; before it existed only in the debug/profile manifests). The approved `location` plugin is still declared (D-A57), so its merged permissions below still apply until the GPS task configures or justifies them. The declared-but-unused `location` 10.1.0 plugin **merges** `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION` and a service. No other locked plugin adds permissions | Plugin manifests in the pub cache; merged release manifest **not built** (pending) |
| iOS deployment / toolchain | Deployment target **14.0**; local Xcode **26.6** | `project.pbxproj`, `Podfile`; `xcodebuild -version` |
| iOS purpose strings / modes | **None** (`NSLocation*UsageDescription`, `UIBackgroundModes` absent) | `ios/Runner/Info.plist` |
| iOS plugins linked | `flutter_localization`, `geocoding_darwin`, `google_maps_flutter_ios`, `location`, `package_info_plus`, `permission_handler_apple`, `shared_preferences_foundation`, `url_launcher_ios` | `ios/Runner/GeneratedPluginRegistrant.m` |
| Privacy manifests | No app-level `ios/Runner/PrivacyInfo.xcprivacy`. Flutter engine and these plugins ship their own: `url_launcher_ios`, `geocoding_darwin`, `google_maps_flutter_ios`, `location`, `package_info_plus`, `permission_handler_apple`, `shared_preferences_foundation` (not `flutter_localization`) | Pub cache / Flutter engine artifacts; Xcode privacy report **not generated** |
| Backend | **None.** All repositories are placeholders (`auth`, `active_order`, `captain_location`); sign-in reports "backend not configured" | `lib/data/repositories/*_placeholder.dart`, `PROJECT_STATUS.md` |
| GPS / location | Not implemented (placeholder repository; no permission request code). Task 24 added the availability permission **port** and a placeholder adapter that reports "not configured" and shows no prompt; the in-app explanation text (`availabilityRationaleMessage`) exists but is **pending owner/legal review** and is not a Play prominent disclosure yet | `lib/data/repositories/captain_location_repository_placeholder.dart` |
| Push (FCM/APNs) | Not implemented; no Firebase or push package | `pubspec.yaml` |
| Analytics / ads / crash SDKs | None declared | `pubspec.yaml` |
| Secure token storage | Not implemented (`flutter_secure_storage` approved target, not installed) | `pubspec.yaml`, `PRODUCT_OVERVIEW.md` |
| Payments | None in app. Wallet = external manual recharge verified by Admin (product rule) | `PRODUCT_OVERVIEW.md` §3.3 |
| Account creation | No self-registration; Admin creates captain accounts; Login shows "contact administration" | `login_screen.dart`, D-A39 |
| Legal links | Terms action on Login, URL **not yet provided** (shows "not available yet"); **no Privacy Policy entry or link** | `lib/helper/legal/legal_links.dart`, `login_terms_action.dart` |
| Debug shell preview | Compiled only in debug builds (`kDebugMode`) | `lib/util/routes/debug_shell_preview.dart`, `login_screen.dart`, tests "simulated release" |
| Screens | (2026-11-20 target) Login; Home AppBar with greeting, availability and balance chip, offer cards; My Orders (declined offers); Wallet (balance, metrics, debit history); My Account with Settings (account deletion), Terms, About; Current Order page — all against "not configured" placeholders; no Notifications feed. Actual status: `PROJECT_STATUS.md` §0 | `PROJECT_STATUS.md` §1 |
| Device testing | iOS simulator only (Login); no Android device/emulator run; no physical device; no release build | `PROJECT_STATUS.md` |

## 4. Requirements for both stores

Columns: **ID** · **Requirement** · **Platform** · **Applicability** · **Why
it applies to SHAHM** · **Status** · **Source** · **Last verified** ·
**Evidence / console field** · **Action (owner / engineer)** · **Blocker**.

| ID | Requirement | Platform | Applicability | Why SHAHM | Status | Source | Last verified | Evidence / console field | Action (owner / engineer) | Blocker |
|---|---|---|---|---|---|---|---|---|---|---|
| P-01 | Public Privacy Policy: active, public, non-geofenced URL (Google: no PDF), linked in the store console **and** inside the app; names the developer/entity, privacy contact, data types, purposes, sharing, security, retention/deletion, how to request deletion/revoke consent | Both | Mandatory | Every app; SHAHM will process account, location, push and wallet data | **verified missing** (no URL, no in-app link) | [Play user data][g-userdata], [Play app content][g-content], [Apple 5.1.1(i)][a-guidelines], [ASC privacy][a-privacy] | 2026-11-15 | Play: App content › Privacy policy; ASC: App Privacy › Privacy Policy URL; in-app: none yet | Owner: publish a lawyer-reviewed policy on the SHAHM site and supply the URL. Eng.: add a central `LegalLinks` entry and an in-app link (Login and Profile), reuse the in-app opener | **yes** |
| P-02 | Store data declarations match the **release build** incl. third-party SDKs: Play **Data safety**, Apple **privacy nutrition labels** | Both | Mandatory | Release build will include captain login/account, location, push identifiers, wallet balances and ledger (backend integer fils), order data, and SDKs (Maps, etc.). Customers have no account or GPS point (do not invent customer collection), but the captain app may display the **customer phone** and destination area entered by merchants (`PRODUCT_OVERVIEW.md`), which must be assessed | **pending verification** (data flows not implemented; consoles not checked) | [Play user data][g-userdata], [ASC privacy][a-privacy] | 2026-11-15 | Play: App content › Data safety; ASC: App Privacy | Eng.: inventory data per release build (§10 audit) incl. SDKs. Owner: answer both questionnaires; keep them consistent with the Privacy Policy | **yes** |
| P-03 | Complete, functional app with **live backend** and reviewer access (Apple 2.1: "turn on your back-end service"; Google: provide all access details) | Both | Mandatory | Login is required for everything | **verified missing** (no backend; placeholder sign-in) | [Apple 2.1][a-guidelines], [Apple complete review][a-review], [Play app content][g-content] | 2026-11-15 | ASC: App Review Information › Sign-in; Play: App content › App access | Owner: provision a dedicated reviewer captain account on the real backend; keep it valid during review. Eng.: real sign-in; reviewer notes (§9, §10) | **yes** |
| P-04 | No placeholder/temporary content in the submitted build (Apple 2.1: placeholder text, empty websites, temporary content scrubbed; minimum functionality 4.2) | Both (Apple explicit) | Mandatory | Home is empty; three tabs are "under construction"; Terms shows "not available yet" | **verified missing** | [Apple 2.1, 4.2][a-guidelines], [Play policy center][g-policy] | 2026-11-15 | Release build screens | Owner: decide release scope. Eng.: implement or remove placeholder tabs; publish Terms or decide how the action ships (owner) | **yes** |
| P-05 | Location only when relevant, with notice and consent before collection (Apple 5.1.5; Google prominent disclosure + runtime permission) | Both | Mandatory once GPS ships | Approved product: location while Available, every 30 s, background best-effort | **conditional** (GPS not implemented) | [Apple 5.1.5][a-guidelines], [Play user data][g-userdata], [Play background location][g-bgloc] | 2026-11-15 | Disclosure screen before the OS prompt; permission flow | Eng.: in-app disclosure (word "location", background wording, features, use/sharing) immediately before the prompt, shown when enabling Available, never at startup (project rule) | yes, when GPS ships |
| P-06 | Accurate metadata: name, description, screenshots reflect the real app (Apple 2.3; app name ≤ 30 characters; Google store listing policy) | Both | Mandatory | Device-visible name «شهم» set in source (R09, 2026-11-22); store listing assets still missing | **partially done** (source names set; not verified on a device build; listing assets missing) | [Apple 2.3][a-guidelines], [Play policy center][g-policy] | 2026-11-15 | ASC: App Information; Play: Main store listing; `Info.plist`, `AndroidManifest.xml` | Owner: final store name «شهم»/SHAHM, descriptions (Arabic), screenshots from the real build. Eng.: set app label/display name | **yes** |
| P-07 | Age rating questionnaire (Apple's updated system since 2026-01-31) and target audience (Google) | Both | Mandatory | Adult captains only; no children | **pending verification** (consoles not checked) | [Apple upcoming requirements][a-upcoming], [Play app content][g-content] | 2026-11-15 | ASC: Age Rating; Play: Content rating, Target audience | Owner: complete both; target audience adults (18+) per business rule (owner to confirm) | yes |
| P-08 | Correct developer identity and reachable support contact (Apple Support URL, Google contact email/website) | Both | Mandatory | Public listing | **pending verification** (no accounts inspected; no support URL/contact given) | [Apple complete review][a-review], [Play package registration][g-pkgreg] | 2026-11-15 | ASC: Support URL; Play: Store settings › Contact details | Owner: provide real support contact; never invented in this repo | yes |
| P-09 | Permissions requested only when needed, with purpose explained | Both | Mandatory | Location (and push) are requested when enabling Available (project rule) | **conditional** | [Apple 5.1.1(ii)][a-guidelines], [Play user data][g-userdata] | 2026-11-15 | Permission flow code (not written) | Eng.: request in stages on Available; never at startup | yes, when GPS/push ship |
| P-10 | Account deletion. **Store policy:** conditional — Google: "If your app allows users to create an account from within your app…"; Apple 5.1.1(v): apps that support account creation must let people initiate deletion in the app. **Product requirement (owner, D-A78, 2026-11-20): an in-app deletion flow is required regardless of that applicability assessment** | Both | Policy: conditional (Admin-provisioned accounts; applicability still for owner/legal). Product: **required** | No self-registration; Admin creates accounts; owner nevertheless requires in-app deletion | **pending verification** — Flutter flow (Settings → «حذف الحساب» → confirmation → typed outcome) tracked in `PROJECT_STATUS.md` §0; **no deletion backend contract** (D-P39), so production reports "not configured" and nothing is deleted | [Play user data][g-userdata], [Apple 5.1.1(v)][a-guidelines], [Apple account deletion][a-delete] | 2026-11-20 | Settings screen; deletion port/use case | Backend: define erasure/anonymization, retention, timing, session revocation and settlement of active delivery/balance/incidents (D-P39). Owner/legal: retention disclosure in the Privacy Policy (P-01). Deletion must not be deactivation-only, must not force phone/email/chat support, may use confirmation/reauthentication, must state timing and retained data | **yes** (product requirement)
| P-11 | Secure transport and storage | Both | Mandatory (store security policies; project rule) | Credentials, tokens, location, wallet | **pending verification** (no backend; no token storage) | [Play policy center][g-policy], [Apple 5.1][a-guidelines] | 2026-11-15 | HTTPS-only API config; `flutter_secure_storage` | Eng.: HTTPS only (no cleartext), tokens in secure storage, no secrets in logs (project rules) | yes |
| P-12 | Third-party SDK compliance (data practices declared; Apple listed-SDK privacy manifests/signatures) | Both | Mandatory | Flutter, `url_launcher_ios`, `package_info_plus` are on Apple's list; Google Maps SDK planned | **pending verification** (no Xcode privacy report; no archive) | [Apple listed SDKs][a-sdks], [Play user data][g-userdata] | 2026-11-15 | Xcode Organizer privacy report; Play Data safety | Eng.: generate the privacy report from a release archive; remove unused SDKs (§5 G-05, §6 A-05) | yes |
| P-13 | Stable app on real devices | Both | Mandatory | Only simulator runs so far | **verified missing** (no physical-device or release-build test) | [Apple 2.1][a-guidelines], [Play policy center][g-policy] | 2026-11-15 | Test report per release | Eng.: release builds on physical Android and iPhone, incl. low-end Android and text scale | yes |
| P-14 | Payment rules: real-world services consumed outside the app must **not** use Apple IAP (3.1.3(e)); wallet top-up is external/manual | Both | **Not applicable to IAP / billing** as currently designed | Delivery is a physical service; no in-app payment exists | **conditional** (re-check if any digital purchase is added) | [Apple 3.1][a-guidelines], [Play policy center][g-policy] | 2026-11-15 | — | Owner: keep wallet/recharge outside the app; flag any digital goods for review. Google Payments policy text not re-read here (pending) | no |
| P-15 | Debug-only shortcuts absent from release (reviewers must use a real account) | Both | Mandatory (2.1 completeness) | Temporary debug shell preview exists | **verified met** for exclusion from release (code gated by `kDebugMode`; widget tests simulate release). Replacement by real sign-in: missing (P-03) | [Apple 2.1][a-guidelines] | 2026-11-15 | `debug_shell_preview.dart`, `login_screen_test.dart` "simulated release" | Eng.: remove the preview before release as planned (D-A40) | no (P-03 blocks) |
| P-16 | EU Digital Services Act trader status (if distributed in the EU) | Both | Conditional | Default market is Jordan; EU distribution not decided | **conditional** | [Apple upcoming requirements][a-upcoming], [Play announcement 2026-10-29][g-announce] | 2026-11-15 | ASC: Business › trader status; Play Console: trader declaration | Owner: choose storefront countries; complete trader status if the EU is included | conditional |

## 5. Google Play

| ID | Requirement | Platform | Applicability | Why SHAHM | Status | Source | Last verified | Evidence / console field | Action (owner / engineer) | Blocker |
|---|---|---|---|---|---|---|---|---|---|---|
| G-01 | **Target API:** new apps and updates must target **Android 16 (API 36)** since **2026-08-31** (extension available to 2026-11-01) | Android | Mandatory | New app | **verified met in config** (`targetSdk = flutter.targetSdkVersion` = 36); no release AAB built | [Play target API][g-target] | 2026-11-15 | `android/app/build.gradle.kts`; Play: bundle explorer after upload | Eng.: confirm `targetSdkVersion 36` in the built AAB; re-check yearly requirement before each release | no (re-check) |
| G-02 | Release signing with an upload key (Play App Signing) and an Android App Bundle | Android | Mandatory | Release uses debug keys | **verified missing** (debug signing) | [Play policy center][g-policy] (signing/AAB page not re-read: pending) | 2026-11-15 | `build.gradle.kts` `signingConfig` | Owner: create/own the upload key and Play App Signing. Eng.: release `signingConfig` from a secure keystore (never committed); `flutter build appbundle` | **yes** |
| G-03 | Unique package name you own; **Android developer verification + package registration**: "Effective September 30, 2026, all Play packages must be registered"; unregistered apps "will be removed from Play" | Android | Mandatory | Package is the template `com.example.mobile_frontend` | **verified missing** (placeholder package; verification status not checked) | [Play package registration][g-pkgreg] | 2026-11-15 | `applicationId`; Play: Android developer verification page | Owner: decide the final package name (e.g. a domain you own), verify identity, register the package. Eng.: change `applicationId`/`namespace` (owner-approved task; a package name cannot be changed after the first upload) | **yes** |
| G-04 | **Background location** (if shipped): core-functionality test; Permissions Declaration Form (one feature); prominent in-app disclosure before the runtime prompt (must contain "location", background wording, all features, use/sharing; not only in the Privacy Policy); ≤ 30 s video; valid test credentials; renew on material change | Android | **Conditional — high-priority policy track** | Product requires location while Available, background best-effort | **conditional** (not implemented; **not** pre-approved because the product requires it) | [Play background location][g-bgloc], [Play user data][g-userdata] | 2026-11-15 | Play: App content › Sensitive app permissions › Location permissions | Owner: decide whether background location is truly needed or foreground service suffices; approve the disclosure copy. Eng.: implement the disclosure, record the video, prepare the declaration | yes, when shipped |
| G-05 | **Foreground service** declaration for apps targeting Android 14+ that declare FGS types (location FGS must continue a user-initiated action and stop when it ends) | Android | **Mandatory now unless removed** | The unused `location` plugin already merges `FOREGROUND_SERVICE_LOCATION` and a service into the build | **verified missing** (declaration not prepared; merged manifest not built) | [Play FGS requirements][g-fgs], [Play background location][g-bgloc] | 2026-11-15 | Play: App content › Foreground service permissions; merged `AndroidManifest.xml` | Eng.: until GPS ships, remove the unused plugin or strip its permissions/service (approval needed per D-A64); when GPS ships, declare the type with a video | **yes** |
| G-06 | **Location Permission policy** (mandatory **2027-01-27**): narrowest scope; Play Console declaration for precise location (`ACCESS_FINE_LOCATION`) explaining why coarse/location button is insufficient; apps targeting Android 17 (API 37+) must use the location button for one-time/infrequent requests; geofencing removed as an FGS use case (same date) | Android | Mandatory for releases on/after 2027-01-27 (future date) | `ACCESS_FINE_LOCATION` already merged by the `location` plugin; the product needs precise location | **conditional** (future) | [Play announcement 2026-10-29][g-announce], [Play FGS requirements][g-fgs] | 2026-11-15 | Play: App content › location declaration | Eng./Owner: prepare the precise-location justification; check the API 37 rule before targeting Android 17 | yes, from 2027-01-27 |
| G-07 | `INTERNET` permission in the **release** manifest | Android | Mandatory for any network use | The app checks connectivity and will call the backend | **fixed in source (R09, 2026-11-22):** declared in `android/app/src/main/AndroidManifest.xml`; the merged release manifest was **not built** (no release build in the remediation package) | Android platform requirement (Flutter template note in `android/app/src/debug/AndroidManifest.xml`) | 2026-11-15 | `android/app/src/main/AndroidManifest.xml` | Eng.: add `<uses-permission android:name="android.permission.INTERNET"/>` to the main manifest in an approved task; verify in the merged release manifest | **yes** |
| G-08 | Data safety form complete and accurate, incl. SDKs | Android | Mandatory | See P-02 | **pending verification** | [Play user data][g-userdata] | 2026-11-15 | Play: App content › Data safety | See P-02 | **yes** |
| G-09 | App access instructions for restricted parts (sign-in), up to five sets; special login methods explained | Android | Mandatory | Entire app is behind login | **verified missing** (no backend account) | [Play app content][g-content] | 2026-11-15 | Play: App content › App access | Owner: reviewer captain account; note the Amman service geofence so reviewers abroad can still see core flows (demo data or explanation) | **yes** |
| G-10 | Ads declaration | Android | Mandatory (declare "no ads") | No ads SDK | **pending verification** (console) | [Play app content][g-content] | 2026-11-15 | Play: App content › Ads | Owner: declare no ads | yes (console task) |
| G-11 | Content rating questionnaire; target audience and content | Android | Mandatory | See P-07 | **pending verification** | [Play app content][g-content] | 2026-11-15 | Play: App content › Content rating / Target audience | Owner | yes (console task) |
| G-12 | Closed testing before production: **personal** developer accounts created after **2023-11-13** need **≥ 12 testers opted in continuously for 14 days** | Android | **Conditional** (not organization accounts, not older personal accounts) | Account type unknown | **pending verification** | [Play new personal accounts][g-closed] | 2026-11-15 | Play: Dashboard › production access | Owner: confirm account type; if it applies, plan ≥ 14 days with 12 real captains/testers | conditional |
| G-13 | Financial features / other App content declarations (e.g. financial features, government, health) | Android | Conditional | Wallet shows balances/commission ledger; no lending or payments | **pending verification** (page section not readable in this research) | [Play app content][g-content] | 2026-11-15 | Play: App content | Owner: answer truthfully; legal review if any declaration is ambiguous | conditional |
| G-14 | Privacy policy link both in Play Console and in-app, publicly accessible without login | Android | Mandatory | See P-01 | **verified missing** | [Play app content][g-content], [Play user data][g-userdata] | 2026-11-15 | Play: App content › Privacy policy | See P-01 | **yes** |
| G-15 | Push notifications runtime permission on Android 13+ and Data safety for device identifiers (if FCM ships) | Android | Conditional | Product requires push for Available | **conditional** (push not implemented) | [Play user data][g-userdata] | 2026-11-15 | `POST_NOTIFICATIONS` in manifest; Data safety | Eng.: request with Available (staged); declare device/other IDs | yes, when push ships |

## 6. Apple App Store

| ID | Requirement | Platform | Applicability | Why SHAHM | Status | Source | Last verified | Evidence / console field | Action (owner / engineer) | Blocker |
|---|---|---|---|---|---|---|---|---|---|---|
| A-01 | **2.1 App Completeness:** final build, working URLs, demo account and live backend, full access (demo mode only with Apple's prior approval) | iOS | Mandatory | Login-gated app | **verified missing** | [Apple 2.1][a-guidelines], [Apple complete review][a-review] | 2026-11-15 | ASC: App Review Information (sign-in, notes) | See P-03, P-04. Notes must describe the business model (B2B delivery, Admin-provisioned captains, external wallet recharge), devices tested, and external services (maps, push) | **yes** |
| A-02 | **4.2 Minimum Functionality**: more than a repackaged site or a collection of links | iOS | Mandatory | Current build: Login + empty/placeholder tabs | **verified missing** | [Apple 4.2][a-guidelines] | 2026-11-15 | Release build | Eng./Owner: ship real captain features (offers, current order, wallet, history) | **yes** |
| A-03 | **5.1.1(i)** Privacy Policy URL in App Store Connect and inside the app | iOS | Mandatory | See P-01 | **verified missing** | [Apple 5.1.1][a-guidelines], [ASC privacy][a-privacy] | 2026-11-15 | ASC: App Privacy › Privacy Policy URL | See P-01 | **yes** |
| A-04 | **5.1.1(v)** Sign-in: login allowed when the app has significant account-based features; account deletion required for apps that support account creation; no unnecessary personal data | iOS | Mandatory (sign-in); deletion conditional by policy but **required by the owner** (D-A78) | Captain accounts are the core; no self-registration | **pending verification** — see P-10. Apple's account-deletion page (read 2026-11-20): offer deletion of "the entire account record, along with associated personal data"; "only offering to temporarily deactivate or disable an account is insufficient"; a website completion step needs "a link directly to the page"; "let people know what information will and won't be retained" and how long it takes; non-regulated apps "should not require people to make a phone call, send an email, use a chat support flow"; identity-verification steps are allowed; Sign in with Apple token revocation applies only if that sign-in is used (it is not) | [Apple 5.1.1(v)][a-guidelines], [Apple account deletion][a-delete] | 2026-11-20 | Review notes explaining Admin provisioning and the deletion flow | Backend contract D-P39; legal retention text | **yes** (with P-10)
| A-05 | **Purpose strings** for every protected resource the binary can access (e.g. `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`); missing strings can fail upload validation | iOS | **Mandatory now if location code stays linked** | `location`, `geocoding`, `permission_handler_apple`, `google_maps_flutter_ios` are linked although unused | **verified missing** (no purpose strings in `Info.plist`); upload validation not run | [Apple 5.1.1(ii) purpose strings][a-guidelines] | 2026-11-15 | `ios/Runner/Info.plist`; App Store Connect upload result | Eng.: either remove unused location plugins until GPS ships (approval per D-A64) or add accurate Arabic purpose strings in the GPS task; run a TestFlight upload to confirm no missing-purpose-string errors | **yes** |
| A-06 | **2.5.4 Background modes** only for their intended purpose; `UIBackgroundModes` `location` only if background GPS ships; **5.1.5** location relevant + consent | iOS | Conditional | Product background tracking while Available | **conditional** | [Apple 2.5.4, 5.1.5][a-guidelines] | 2026-11-15 | `Info.plist` `UIBackgroundModes` | Eng.: add only with real background GPS; explain in review notes | yes, when shipped |
| A-07 | **SDK minimum:** uploads built with **Xcode 26** and an **iOS 26 SDK** or later (since **2026-04-28**) | iOS | Mandatory | Any upload | **pending verification** (local Xcode 26.6 installed; no archive built) | [Apple upcoming requirements][a-upcoming] | 2026-11-15 | `xcodebuild -version`; archive metadata | Eng.: archive with current Xcode; re-check before each upload | no (re-check) |
| A-08 | **Minimum OS:** apps must target **iOS 13 or later** (since **2026-09-09**) | iOS | Mandatory | — | **verified met in config** (deployment target 14.0) | [Apple upcoming requirements][a-upcoming] | 2026-11-15 | `IPHONEOS_DEPLOYMENT_TARGET = 14.0`, `Podfile` | — | no |
| A-09 | **Privacy manifests and required-reason APIs:** approved reasons for listed APIs used by the app **or its SDKs** (since **2024-05-01**); listed third-party SDKs need privacy manifests (and signatures when binary) | iOS | Mandatory | Flutter, `url_launcher`/`url_launcher_ios`, `package_info_plus` are listed SDKs; plugins use APIs such as UserDefaults | **pending verification** (plugins ship manifests; no app-level manifest; Xcode privacy report not generated) | [Apple upcoming requirements][a-upcoming], [Apple listed SDKs][a-sdks], [Apple required-reason APIs][a-reasons] (page rendered no text on 2026-11-15; requirement confirmed via the upcoming-requirements page) | 2026-11-15 | Xcode Organizer › Generate Privacy Report; upload emails (e.g. ITMS-91053) | Eng.: generate the report from a release archive; add `ios/Runner/PrivacyInfo.xcprivacy` only if app code needs it | yes |
| A-10 | **Privacy nutrition labels** incl. third-party partners' code | iOS | Mandatory | See P-02 | **pending verification** | [ASC privacy][a-privacy] | 2026-11-15 | ASC: App Privacy | See P-02 | **yes** |
| A-11 | **Age rating** (updated questionnaire) | iOS | Mandatory | See P-07 | **pending verification** | [Apple upcoming requirements][a-upcoming] | 2026-11-15 | ASC: Age Rating | Owner | yes (console task) |
| A-12 | **Push notifications** permission and APNs configuration (if push ships); APNs Trust Store SHA-2 root (since 2025) is server-side | iOS | Conditional | Product requires push for Available | **conditional** | [Apple upcoming requirements][a-upcoming] | 2026-11-15 | Push capability/entitlement; server trust store | Eng./backend: when implementing push | yes, when shipped |
| A-13 | **2.3 metadata**: name ≤ 30 characters, accurate screenshots/description, specific review notes for features | iOS | Mandatory | See P-06 | **verified missing** | [Apple 2.3][a-guidelines] | 2026-11-15 | ASC: App Information / version page | See P-06 | **yes** |
| A-14 | Terms of Use / EULA link: required in specific contexts (e.g. auto-renewable subscriptions, 3.1.2); otherwise Apple's standard EULA applies unless a custom one is provided | iOS | **Not applicable** today (no subscriptions) | SHAHM's own Terms page is a project requirement (Task 13), not an Apple requirement | **conditional** | [Apple 3.1][a-guidelines] | 2026-11-15 | ASC: License Agreement | Owner/legal: decide whether SHAHM Terms become the custom EULA | no |
| A-15 | Distribution channel: public App Store vs an organization-only channel | iOS / Android | Owner decision | Captains are Admin-provisioned; Apple's guidelines mention apps "sold directly … to organizations" (3.1.3(c)) and enterprise accounts (4.8); Play exempts "permanently private apps … for internal distribution" from target-API rules | **pending verification** (not researched in depth; private-distribution pages not read) | [Apple guidelines][a-guidelines], [Play target API][g-target] | 2026-11-15 | — | Owner: decide; if private distribution is preferred, research Apple Custom Apps and managed Google Play in a separate task | no |

## 7. Project product requirements (not store policy)

These come from owner decisions, not store rules. They often support store
compliance, but meeting them is not store approval.

| Item | Source | Status |
|---|---|---|
| Location and push requested when the captain enables **Available**, never at startup; staged requests | `PRODUCT_OVERVIEW.md` §3.2/§3.6 | Not implemented |
| Location every 30 s while Available; background best-effort | `PRODUCT_OVERVIEW.md` §3.6, D-A53–D-A56 | Not implemented |
| Session token in `flutter_secure_storage`; one device session per captain | `PRODUCT_OVERVIEW.md` | Not implemented |
| Terms & Conditions action on Login opening the public SHAHM page in-app only | Task 13, D-A39 supplement | Implemented; URL **not yet provided** |
| No self-registration; Admin creates accounts | D-A39 | Implemented (popup) |
| Wallet recharge outside the app, verified by Admin; no in-app recharge action | D-A76, `PRODUCT_OVERVIEW.md` §3.3 | Wallet UI shows balance and debit history only (see `PROJECT_STATUS.md` §0); wallet API not connected |
| In-app account deletion from Settings, with confirmation and truthful outcomes | D-A78 | See P-10; backend contract missing |
| Operational order push alerts (no in-app notification feed) | D-A72 | Push not implemented; feed removed |
| Terms & Conditions also reachable from Profile («حسابي») | D-A77 | See `PROJECT_STATUS.md` §0 |

## 8. Items that need owner or legal review (not legal advice)

- Privacy Policy content, controller entity, privacy contact, retention and
  deletion procedures, and lawful basis for location tracking of captains
  (who may be contractors or employees): **lawyer review**.
- Terms & Conditions content and whether it becomes a custom Apple EULA.
- Whether store account-deletion obligations apply to Admin-provisioned
  accounts (P-10, A-04) — the in-app flow is required by the owner anyway
  (D-A78); the retention/deletion statements in the Privacy Policy and the
  financial-ledger retention term remain lawyer/owner decisions (D-P39).
- Exact prominent-disclosure wording for background location (Arabic).
- Data safety / privacy-label answers (they are legal statements by the
  developer).
- Storefront countries, EU distribution, trader status.
- Jordan-specific requirements (data protection, labour/contractor rules)
  are **outside** this research.

## 9. Unknowns / owner inputs

| Input | Needed for |
|---|---|
| Final app name, store descriptions (Arabic), screenshots | P-06, A-13 |
| Final Android package name and iOS bundle ID (cannot change after the first upload) | G-03 |
| Developer account owner entity (organization vs personal) and account creation date | G-03, G-12, P-08 |
| Public Privacy Policy URL (and Terms URL) on the SHAHM web site | P-01, P-04 |
| Support URL / contact email | P-08 |
| Reviewer captain account on a live backend, plus how reviewers outside Amman can exercise core flows | P-03, G-09, A-01 |
| Decision: background location vs foreground-only (FGS) | G-04, G-05, A-06 |
| Decision: remove the unused `location`/maps/permission plugins until their feature tasks (D-A64) | G-05, G-06, A-05 |
| Storefront countries (EU or not) | P-16 |
| Distribution: public stores vs organization-only | A-15 |
| Upload keystore and Play App Signing ownership | G-02 |

## 10. Pre-submission audit (run for every release)

Record results with date, build number and evidence in `PROJECT_STATUS.md`.

- [ ] Re-open every source in §11; update changed requirements and dates.
- [ ] Build the release artifacts (`flutter build appbundle`, Xcode archive)
      with the current toolchain; record versions (G-01, A-07).
- [ ] Inspect the **merged** Android release manifest: only intended
      permissions/services; `INTERNET` present; no unused location/FGS
      entries (G-05, G-07).
- [ ] Verify `targetSdkVersion` in the AAB (G-01) and the iOS deployment
      target (A-08).
- [ ] Release signing with the upload key; never debug keys (G-02).
- [ ] Generate the Xcode privacy report; resolve missing reasons/manifests
      (A-09); TestFlight upload shows no missing-purpose-string errors (A-05).
- [ ] No placeholder screens, texts, or links in the release build; debug
      preview absent (P-04, P-15).
- [ ] Privacy Policy URL opens publicly without login, from the console and
      from inside the app (P-01).
- [ ] Data safety and privacy labels match the release build's real data
      flows and SDKs (P-02).
- [ ] Reviewer account signs in on the live backend; notes explain Admin
      provisioning, wallet recharge outside the app, service area (P-03).
- [ ] Location/push: disclosure → OS prompt order, triggered by enabling
      Available, declarations and videos ready (P-05, G-04, G-15, A-06).
- [ ] Physical-device runs on Android and iPhone (P-13).
- [ ] App names, icons, screenshots and descriptions match the build
      (P-06, A-13).
- [ ] Console tasks done: content/age rating, target audience, ads, app
      access, financial/other declarations, trader status if needed.

### How to verify without assuming console access

- **Play Console:** App content page (Privacy policy, App access, Ads,
  Content rating, Target audience, Data safety, Sensitive app permissions,
  Foreground service permissions); Android developer verification page;
  Dashboard › production access (closed testing).
- **App Store Connect:** App Information (name, age rating, license), App
  Privacy (policy URL, nutrition labels), version page › App Review
  Information (sign-in, notes), Business (trader status).
- **Local:** `android/app/src/main/AndroidManifest.xml` and the merged
  manifest under `build/` after a release build; `ios/Runner/Info.plist`;
  Xcode Organizer privacy report; `pubspec.lock` for SDK versions.

Never record a console item as met without a screenshot path, an export or
a written confirmation from the account owner.

## 11. Sources (official only)

| Ref | Page | Last verified |
|---|---|---|
| [g-policy] | [Google Play Developer Program Policy](https://support.google.com/googleplay/android-developer/answer/18265346) (states "effective October 29, 2026") | 2026-11-15 (navigation and privacy areas read; full text not exhaustively read) |
| [g-userdata] | [Google Play User Data](https://support.google.com/googleplay/android-developer/answer/10144311) | 2026-11-15 |
| [g-content] | [Google Play: Prepare your app for review (App content)](https://support.google.com/googleplay/android-developer/answer/9859455) | 2026-11-15 (partially readable) |
| [g-bgloc] | [Google Play: Access to location in the background](https://support.google.com/googleplay/android-developer/answer/9799150) | 2026-11-15 |
| [g-fgs] | [Google Play: Foreground service and full-screen intent requirements](https://support.google.com/googleplay/android-developer/answer/13392821) | 2026-11-15 (search summary; re-read before the GPS task) |
| [g-target] | [Google Play: Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878) | 2026-11-15 |
| [g-pkgreg] | [Google Play: Package name registration / developer verification](https://support.google.com/googleplay/android-developer/answer/16984799) | 2026-11-15 |
| [g-closed] | [Google Play: Testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465) | 2026-11-15 |
| [g-announce] | [Google Play policy announcement, October 29, 2026](https://support.google.com/googleplay/android-developer/answer/18100766) | 2026-11-15 |
| [a-guidelines] | [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) (no update date shown) | 2026-11-15 (sections 1–5.2 read) |
| [a-review] | [Apple: Complete review information](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review/) | 2026-11-15 |
| [a-privacy] | [App Store Connect: Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy) | 2026-11-15 |
| [a-upcoming] | [Apple: Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/) | 2026-11-15 |
| [a-sdks] | [Apple: Third-party SDK requirements](https://developer.apple.com/support/third-party-SDK-requirements/) | 2026-11-15 |
| [a-delete] | [Apple: 5.1.1(v) Account deletion](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion) (no update date shown) | 2026-11-20 |
| [a-reasons] | [Apple: Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api) | **Not readable** on 2026-11-15 (JavaScript page); re-check in a browser |

[g-policy]: https://support.google.com/googleplay/android-developer/answer/18265346
[g-userdata]: https://support.google.com/googleplay/android-developer/answer/10144311
[g-content]: https://support.google.com/googleplay/android-developer/answer/9859455
[g-bgloc]: https://support.google.com/googleplay/android-developer/answer/9799150
[g-fgs]: https://support.google.com/googleplay/android-developer/answer/13392821
[g-target]: https://support.google.com/googleplay/android-developer/answer/11926878
[g-pkgreg]: https://support.google.com/googleplay/android-developer/answer/16984799
[g-closed]: https://support.google.com/googleplay/android-developer/answer/14151465
[g-announce]: https://support.google.com/googleplay/android-developer/answer/18100766
[a-guidelines]: https://developer.apple.com/app-store/review/guidelines/
[a-review]: https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review/
[a-privacy]: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
[a-upcoming]: https://developer.apple.com/news/upcoming-requirements/
[a-sdks]: https://developer.apple.com/support/third-party-SDK-requirements/
[a-reasons]: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
[a-delete]: https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion

## 12. Maintenance

- One canonical file: update this one; never start a parallel checklist.
- Each release task updates the affected rows and the verification dates.
- A new store announcement → add or edit the row, cite the official page,
  mark future dates as future.
- Record each release audit result (§10) in `../project/PROJECT_STATUS.md`.
