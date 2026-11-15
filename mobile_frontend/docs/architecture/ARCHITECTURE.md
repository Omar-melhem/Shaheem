# SHAHM Flutter — Architecture

**Approved target through 2026-11-14; implementation snapshot remains historical.** `ARCHITECTURAL_DECISIONS.md` §1.1 is authoritative when older architectural notes differ.

The layers, folder responsibilities, dependency rules and composition of the
Flutter app. State management, routing and global services each have their
own documents.

Decisions referenced: D-A02, D-A09, D-A17, D-A27, D-A28 (see
`../decisions/ARCHITECTURAL_DECISIONS.md`).

---

## 1. Layers and dependency rule

```text
        view   (screens, widgets, Cubits/Blocs, app-level state)
         │
         ▼
       domain  (entities, repository contracts, use cases, typed errors)
         ▲
         │
        data   (models/DTOs, data sources, repository implementations)
```

- **`view`** depends on `domain` and calls use cases.
- **`data`** implements domain contracts.
- **`domain`** depends on nothing app-specific: no Flutter, no `data`, no
  `view`, no HTTP or storage packages.
- **Composition:** implementations are wired to contracts in the composition
  root (`lib/main.dart`). See §4.
- **Server authority:** a rule that must hold across devices (acceptance,
  wallet, eligibility) is enforced by the server. Client checks are
  convenience only.

## 2. Folder responsibilities (`lib/`)

| Folder | Holds | Must not hold | Current contents |
|---|---|---|---|
| `data/` | API models/DTOs, data sources, repository implementations, DTO → entity mapping | Business rules; widgets | `models/app_user_model.dart`, `repositories/`: five **temporary placeholders** (`auth_repository_placeholder.dart`, `active_order_repository_placeholder.dart`, `captain_location_repository_placeholder.dart`, and since Task 24 `captain_availability_repository_placeholder.dart` (backend not configured) and `availability_permission_gateway_placeholder.dart` (permissions not configured, no prompts)) |
| `domain/` | Entities, repository contracts, use cases, typed domain errors | Flutter imports, DTOs, widgets, Cubits | `entities/`, `errors/`, `repositories/`, `use_cases/`. Task 24: `CaptainAvailability` / `AvailabilityRequirement` / `RequirementStatus` / `AvailabilityPrerequisites`, `CaptainAvailabilityRepository` (API contract TO SPECIFY), `AvailabilityPermissionGateway` (platform permission port), `GetCaptainAvailability` / `ChangeCaptainAvailability` |
| `helper/` | App-level service integrations and localization resources, each with a clear single responsibility | A miscellaneous dumping ground | `network/internet_connection_service.dart`, `translation/` (ARB + generated `AppLocalizations` + `l10n_extension.dart`) |
| `theme/` | Colors, typography, `ThemeData` | Feature logic | `app_color.dart`, `app_theme.dart`, `text_themes.dart` |
| `util/` | Constants, strings, image paths, fonts, routes, pure validators, UI helper tools | Order or wallet business rules | `images.dart`, `fonts.dart`, `responsive/` (`AppBreakpoints`), `routes/` (paths, router, guard, and the temporary `debug_shell_preview.dart`, D-A40), `validators/`, `tools/` |
| `view/` | Screens, widgets, feature Cubits/Blocs, app-level state | API calls, JSON parsing, business calculations | `app_state/`, `navigation/`, `screens/`, `widget/` |

**Inside `view/`:**

```text
view/
├── app_state/            app-wide Cubits and their UI (one instance each)
│   ├── connectivity/
│   └── session/
├── navigation/           main shell (AppNavBar): GoRouter branches ↔ bar
├── screens/<feature>/
│   ├── view/             the screen file (composition only)
│   ├── cubit/ or bloc/   feature state
│   └── widget/           feature-specific widgets
└── widget/<category>/    cross-feature shared widgets: text/, padding/,
                          text_field/, buttons/, pop_up_screen/, toast/,
                          navigation/ (MainNavigationBar), placeholder/,
                          status/ (AppStatusMessage)
```

**Screens** (each in `screens/<name>/view/`): `splash_screen`,
`no_internet_screen`, `authentication` (Login), `home_screen`, and the four
screens added with the main navigation (D-A36): `notifications_screen`,
`order_history_screen` and `profile_screen` (placeholders), and
`current_order_screen` (`view/`, `cubit/`, `widget/`; D-A41).

**Approved target change (D-A50, not implemented in the current source
snapshot):** replace the Profile destination/screen with a Wallet destination
and screen. Update the route, branch order, enum, localized labels and tests
together when that feature is implemented.

**Shell vs bar:** `view/navigation/app_nav_bar.dart` owns routing (which
branch is open, switching, back). `view/widget/navigation/` holds the visual
`MainNavigationBar` and the `MainNavDestination` enum, which know nothing
about routes or feature state (C-19). Details:
`ROUTING_AND_STARTUP.md` §7.

**Known exception:** `util/tools/` imports widgets from `view/widget/`
(D-P14).

## 3. Widget separation (permanent rule, D-A09)

- **Screen files** compose the layout and coordinate state only.
- **Meaningful custom widgets** (a clear responsibility or reuse value) go in
  their own files:
  - Feature-specific: `view/screens/<feature>/widget/`.
  - Cross-feature: `view/widget/<category>/`.
- **No large or reusable widget classes** declared inside screen files.
- **No trivial files:** don't create files for plain `Padding`, `Row` or
  `Container` wrappers.
- **Reuse** shared widgets instead of duplicating them. Search before adding.

**Integration boundaries waiting for a backend or provider** (each is a
domain contract with a placeholder that reports "not configured"; none
returns invented data):

| Contract (`domain/repositories/`) | Use case | Status (approval vs outstanding work) |
|---|---|---|
| `AuthRepository` | `SignIn`, `CheckAuthStatus`, `GetCurrentUser`, `SignOut` | **Approved** architecture D-A53–D-A56 and secure refresh storage (ledger D-P02, D-P03); concrete OpenAPI auth endpoints/DTOs, backend and implementation pending |
| `ActiveOrderRepository` | `GetActiveOrder` | **Approved** active-order behavior D-A68 (ledger D-P25, D-P02); concrete current-order DTO/endpoint, scheduled-activation read model, backend and implementation pending |
| `CaptainLocationRepository` | `GetCaptainLocation` | **Approved** package/permissions D-A57; implementation pending |
| `PickupMapBuilder` (view-level, `current_order_screen/widget/pickup_map.dart`) | — | **Approved** Google Maps/Routes D-A62; implementation pending |

**Example:** `SplashScreen` composes the logo and `SplashStartupStatus`
(`screens/splash_screen/widget/`).

## 4. Composition root and dependency injection (D-A64)

**Approved future integration:** use **`get_it`** as the application-wide
service registration mechanism, initialized at the Flutter composition root.
Each feature may contribute a registration module. Inject services into
repositories, use cases and Cubits through **constructors**, not through
direct `get_it` lookups inside those classes. Tests can override/reset the
container. Do **not** use `injectable` or DI code generation.

```text
main() / composition root
 ├─ registerCoreDependencies(getIt)
 ├─ registerAuthDependencies(getIt)
 ├─ registerOrdersDependencies(getIt)
 ├─ registerWalletDependencies(getIt)
 ├─ registerLocationAndNotifications(getIt)
 └─ MainApp(services supplied through constructor)
     ├─ AppConnectivityCubit / AppSessionCubit / SplashCubit
     └─ feature Cubits receive UseCases via constructors
```

The block above is an **architecture target**, not a claim that those exact
Dart functions or modules already exist. Previously `MainApp` built objects
through plain constructor wiring without `get_it`; that remains the last
verified Flutter implementation until a real source migration is performed.

**Backend integration boundary (D-A53–D-A56):** generated API clients live in
`data/`; map typed API DTOs to domain entities. OpenAPI is generated from
ASP.NET Core `/api/v1` with approved Problem Details errors. Domain logic
remains framework-neutral. SignalR/FCM are delivery hints; repository REST
reads and PostgreSQL transactions are the authoritative state. Use a
PostgreSQL transactional outbox for critical order/financial/admin events,
not GPS telemetry. Idempotency keys, uniqueness constraints and concurrency
checks are backend concerns, never delegated to Cubits.

**Permanent cleanup rule:** when migrating a feature, remove superseded
legacy code and imports once usage and tests verify safety; do not leave
parallel old/new implementations behind.

## 5. Naming and code conventions

- **Naming:** `snake_case.dart` files, lowercase folders, `PascalCase`
  classes, `camelCase` members.
- **Style:**
  - Use `const` where possible.
  - Avoid `dynamic`.
  - Never use `print` for error logging (no logger chosen yet).
- **Errors:**
  - Handle them explicitly; never swallow silently. When ignoring is
    intentional, explain why in a comment.
  - Classify failures with typed domain exceptions or results
    (`domain/errors/auth_exceptions.dart`, sealed result classes).
- **No hard-coded values** for colors, strings or asset paths:
  - Colors: `AppColor`.
  - Strings: ARB localization through `context.l10n` (D-A30).
  - Images: `AppImages`.
  - Breakpoints: `AppBreakpoints`.
- **Comments:** English comments are mandatory (D-A07). The rules are in
  `../../CLAUDE.md` §10.

## 6. Packages (D-A27, D-A64; complete audit before removal)

| Package | Used for | Status |
|---|---|---|
| `flutter_bloc` | State management | Used |
| `go_router` | Navigation | Used |
| `internet_connection_checker_plus` | Reachability monitor | Used |
| `flutter_localizations` (SDK) + `intl` | gen_l10n localization (D-A30) | Used (added 2026-11-11) |
| `responsive_framework` 1.5.1 | Central breakpoints (D-A31) | Used (added 2026-11-11) |
| `phosphor_icons` 3.0.1 | Icons of the main navigation destinations (D-A37) | Used (added 2026-11-11) |
| `toasty_box` | Nothing since 2026-11-11: toasts moved to `ScaffoldMessenger` (D-A32) | Legacy unused in snapshot; remove **only after complete audit** |
| `url_launcher` 6.3.3 (Android 6.3.33, iOS 6.4.2 resolved) | **Used since Task 13:** `lib/helper/legal/legal_page_launcher.dart`, in `LaunchMode.inAppWebView` only (legal pages, never external). Still approved for the planned external Google Maps navigation (D-A57, D-A62) | Used. Re-verify the in-app-only behavior after any upgrade |
| `bloc`, `meta` (transitive) | Only imported by the unused legacy `SplashBloc` | See D-P13 |
| `google_maps_flutter`, `geocoding`, `location`, `permission_handler`, `http`, `dropdown_search`, `flutter_localization` (third-party, unrelated to the SDK `flutter_localizations`), `google_api_headers` | Nothing in `lib/`: declared but not imported (a full audit of `test/` and platform folders hasn't been done) | Audit `lib/`, `test/`, Android/iOS and transitive needs. **Keep approved** `google_maps_flutter`, `location`, `permission_handler`, `url_launcher` for planned features. Remove genuinely unused packages only after proof of non-use |

**Rules:**
- New packages need a justification and approval first.
- Usage of approved packages (Maps, GPS, external navigation, get_it, secure storage) is authorized by D-A53–D-A64; still verify compatibility before adding or using them.
