# 02 — File-by-File Inventory (revised, post-remediation)

**Provenance.** Generated 2026-11-22 (R11) from the final remediation working tree on `cefad0a` (`git ls-files` + untracked non-ignored files, minus files deleted in the working tree; plus this report and the revised report 01). Baseline: [`../../../02_FILE_BY_FILE_INVENTORY.md`](../../../02_FILE_BY_FILE_INVENTORY.md) (340 paths, kept unchanged). Counting rules: [`../../AUDIT_METHOD.md`](../../AUDIT_METHOD.md).

**Reading coverage (honest wording).** Membership: every path below exists. Content: the remediation read in full every file it changed or created (listed below) and the canonical docs it updated; unchanged files were not re-read line by line in this run, so their baseline review stands with its own limits (the baseline did **not** read long comments or demo JSON fixtures in full, contrary to its "full" wording).

## 1. Totals

- Paths now: **344** (baseline 340): 12 added, 8 removed, 58 modified.

| Category | Paths |
|---|---|
| runtime | 154 |
| platform | 95 |
| test | 32 |
| doc | 22 |
| demo/tool | 20 |
| config/root | 9 |
| asset-font | 6 |
| preview | 3 |
| generated | 2 |
| asset | 1 |


## 2. Changes against the baseline

| Change | Path | Reason (tracker ID) |
|---|---|---|
| removed | `lib/util/tools/android_loading.dart` | ARCH-02 dead code |
| removed | `lib/util/tools/ios_loading.dart` | ARCH-02 dead code |
| removed | `lib/util/tools/tools.dart` | ARCH-02 dead code |
| removed | `lib/view/screens/splash_screen/bloc/splash_bloc.dart` | ARCH-03 dead Bloc |
| removed | `lib/view/screens/splash_screen/bloc/splash_event.dart` | ARCH-03 |
| removed | `lib/view/screens/splash_screen/bloc/splash_state.dart` | ARCH-03 |
| removed | `lib/view/widget/padding/padding.dart` | SW-04 dead code |
| added | `docs/01_APPLICATION_AUDIT_REPORT.md` | baseline report placed by the owner (kept, sha-pinned) |
| added | `docs/02_FILE_BY_FILE_INVENTORY.md` | baseline (kept) |
| added | `docs/03_SYSTEM_DATA_REQUIREMENTS.md` | baseline (kept) |
| added | `docs/quality/AUDIT_METHOD.md` | R00/R10/R11 quality documentation |
| added | `docs/quality/ENGINEERING_LESSONS.md` | R00/R10/R11 quality documentation |
| added | `docs/quality/REMEDIATION_STATUS.md` | R00/R10/R11 quality documentation |
| added | `docs/quality/reports/2026-11-22-post-fix/01_APPLICATION_AUDIT_REPORT.md` | R00/R10/R11 quality documentation |
| added | `docs/quality/reports/2026-11-22-post-fix/02_FILE_BY_FILE_INVENTORY.md` | R00/R10/R11 quality documentation |
| added | `docs/quality/reports/2026-11-22-post-fix/03_SYSTEM_DATA_REQUIREMENTS.md` | R00/R10/R11 quality documentation |
| added | `lib/view/navigation/current_order_navigation.dart` | ARCH-04 |
| added | `lib/view/screens/route_error_screen/view/route_error_screen.dart` | ARCH-08/LOC-01 |
| added | `test/timeout_policy_test.dart` | ARCH-06 |
| modified | `android/app/src/main/AndroidManifest.xml` | see `../../REMEDIATION_STATUS.md` |
| modified | `docs/architecture/ARCHITECTURE.md` | see `../../REMEDIATION_STATUS.md` |
| modified | `docs/architecture/GLOBAL_SERVICES.md` | see `../../REMEDIATION_STATUS.md` |
| modified | `docs/architecture/ROUTING_AND_STARTUP.md` | see `../../REMEDIATION_STATUS.md` |
| modified | `docs/architecture/STATE_MANAGEMENT.md` | see `../../REMEDIATION_STATUS.md` |
| modified | `docs/decisions/ARCHITECTURAL_DECISIONS.md` | see `../../REMEDIATION_STATUS.md` |
| modified | `docs/release/STORE_SUBMISSION_COMPLIANCE.md` | see `../../REMEDIATION_STATUS.md` |
| modified | `docs/ui/CUSTOM_WIDGET_CONTRACT_STANDARD.md` | see `../../REMEDIATION_STATUS.md` |
| modified | `docs/ui/DESIGN_SYSTEM.md` | see `../../REMEDIATION_STATUS.md` |
| modified | `docs/ui/SHARED_UI_COMPONENTS_REFERENCE.md` | see `../../REMEDIATION_STATUS.md` |
| modified | `ios/Runner/Info.plist` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/domain/use_cases/captain_account.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/domain/use_cases/get_declined_offers.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/domain/use_cases/get_wallet.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/domain/use_cases/order_offers.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/helper/translation/app_ar.arb` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/helper/translation/generated/app_localizations.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/helper/translation/generated/app_localizations_ar.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/main.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/util/routes/go_router.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/navigation/new_offer_sheet_host.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/navigation/new_order_offer_sheet.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/authentication/view/login_screen.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/home_screen/widget/home_active_order_card.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/home_screen/widget/wallet_balance_chip.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/no_internet_screen/view/no_internet_screen.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/order_history_screen/widget/declined_offer_tile.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/profile_screen/cubit/profile_rating_cubit.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/profile_screen/view/profile_screen.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/profile_screen/widget/profile_identity_card.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/profile_screen/widget/profile_rating_card.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/settings_screen/cubit/account_deletion_cubit.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/settings_screen/view/settings_screen.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/settings_screen/widget/account_deletion_confirmation.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/splash_screen/widget/splash_startup_status.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/wallet_screen/cubit/wallet_cubit.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/wallet_screen/cubit/wallet_state.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/wallet_screen/view/wallet_screen.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/wallet_screen/widget/wallet_balance_card.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/wallet_screen/widget/wallet_debit_card.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/screens/wallet_screen/widget/wallet_metric_cards.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/widget/order/app_order_offer_card.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `lib/view/widget/pop_up_screen/app_popup.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `macos/Flutter/GeneratedPluginRegistrant.swift` | see `../../REMEDIATION_STATUS.md` |
| modified | `pubspec.lock` | see `../../REMEDIATION_STATUS.md` |
| modified | `pubspec.yaml` | see `../../REMEDIATION_STATUS.md` |
| modified | `test/custom_widgets_test.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `test/main_navigation_test.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `test/new_offer_sheet_test.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `test/order_card_icons_test.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `test/profile_settings_test.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `test/shared_widgets_test.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `test/startup_flow_test.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `test/wallet_test.dart` | see `../../REMEDIATION_STATUS.md` |
| modified | `tool/demo/README.md` | see `../../REMEDIATION_STATUS.md` |
| modified | `tool/demo/install_manifest.json` | see `../../REMEDIATION_STATUS.md` |
| modified | `tool/demo/remove_demo.dart` | see `../../REMEDIATION_STATUS.md` |

## 3. Runtime Dart files now (153)

<details><summary>Full list</summary>

- `lib/data/models/app_user_model.dart`
- `lib/data/repositories/active_order_repository_placeholder.dart`
- `lib/data/repositories/auth_repository_placeholder.dart`
- `lib/data/repositories/availability_permission_gateway_placeholder.dart`
- `lib/data/repositories/captain_account_repository_placeholder.dart`
- `lib/data/repositories/captain_availability_repository_placeholder.dart`
- `lib/data/repositories/captain_location_repository_placeholder.dart`
- `lib/data/repositories/order_history_repository_placeholder.dart`
- `lib/data/repositories/order_offer_repository_placeholder.dart`
- `lib/data/repositories/wallet_repository_placeholder.dart`
- `lib/domain/entities/active_order.dart`
- `lib/domain/entities/app_user.dart`
- `lib/domain/entities/captain_account.dart`
- `lib/domain/entities/captain_availability.dart`
- `lib/domain/entities/declined_offer.dart`
- `lib/domain/entities/order_offer.dart`
- `lib/domain/entities/wallet.dart`
- `lib/domain/errors/auth_exceptions.dart`
- `lib/domain/errors/availability_exceptions.dart`
- `lib/domain/errors/captain_account_exceptions.dart`
- `lib/domain/errors/order_exceptions.dart`
- `lib/domain/errors/order_history_exceptions.dart`
- `lib/domain/errors/order_offer_exceptions.dart`
- `lib/domain/errors/wallet_exceptions.dart`
- `lib/domain/repositories/active_order_repository.dart`
- `lib/domain/repositories/auth_repository.dart`
- `lib/domain/repositories/availability_permission_gateway.dart`
- `lib/domain/repositories/captain_account_repository.dart`
- `lib/domain/repositories/captain_availability_repository.dart`
- `lib/domain/repositories/captain_location_repository.dart`
- `lib/domain/repositories/order_history_repository.dart`
- `lib/domain/repositories/order_offer_repository.dart`
- `lib/domain/repositories/wallet_repository.dart`
- `lib/domain/use_cases/captain_account.dart`
- `lib/domain/use_cases/captain_availability.dart`
- `lib/domain/use_cases/check_auth_status.dart`
- `lib/domain/use_cases/clear_rejected_session.dart`
- `lib/domain/use_cases/get_active_order.dart`
- `lib/domain/use_cases/get_captain_location.dart`
- `lib/domain/use_cases/get_current_user.dart`
- `lib/domain/use_cases/get_declined_offers.dart`
- `lib/domain/use_cases/get_wallet.dart`
- `lib/domain/use_cases/order_offers.dart`
- `lib/domain/use_cases/sign_in.dart`
- `lib/domain/use_cases/sign_out.dart`
- `lib/helper/date/date_time_format.dart`
- `lib/helper/legal/legal_links.dart`
- `lib/helper/legal/legal_page_launcher.dart`
- `lib/helper/money/jod_format.dart`
- `lib/helper/network/internet_connection_service.dart`
- `lib/helper/translation/l10n_extension.dart`
- `lib/main.dart`
- `lib/theme/app_color.dart`
- `lib/theme/app_theme.dart`
- `lib/theme/text_themes.dart`
- `lib/util/fonts.dart`
- `lib/util/images.dart`
- `lib/util/responsive/app_breakpoints.dart`
- `lib/util/routes/debug_shell_preview.dart`
- `lib/util/routes/go_router.dart`
- `lib/util/routes/route_guard.dart`
- `lib/util/routes/routes_string.dart`
- `lib/util/routes/stream_refresh_listenable.dart`
- `lib/util/validators/validation_error.dart`
- `lib/util/validators/validation_messages.dart`
- `lib/util/validators/validators.dart`
- `lib/view/app_state/connectivity/app_connectivity_cubit.dart`
- `lib/view/app_state/connectivity/app_connectivity_state.dart`
- `lib/view/app_state/connectivity/global_connectivity_banner.dart`
- `lib/view/app_state/session/app_session_cubit.dart`
- `lib/view/app_state/session/app_session_state.dart`
- `lib/view/navigation/app_nav_bar.dart`
- `lib/view/navigation/current_order_navigation.dart`
- `lib/view/navigation/new_offer_sheet_host.dart`
- `lib/view/navigation/new_order_offer_sheet.dart`
- `lib/view/screens/about_screen/view/about_screen.dart`
- `lib/view/screens/authentication/cubit/login_cubit.dart`
- `lib/view/screens/authentication/cubit/login_state.dart`
- `lib/view/screens/authentication/view/login_screen.dart`
- `lib/view/screens/authentication/widget/create_account_popup.dart`
- `lib/view/screens/authentication/widget/debug_preview_button.dart`
- `lib/view/screens/authentication/widget/forgot_password_popup.dart`
- `lib/view/screens/authentication/widget/login_failure_message.dart`
- `lib/view/screens/authentication/widget/login_form.dart`
- `lib/view/screens/authentication/widget/login_terms_action.dart`
- `lib/view/screens/current_order_screen/cubit/current_order_cubit.dart`
- `lib/view/screens/current_order_screen/cubit/current_order_state.dart`
- `lib/view/screens/current_order_screen/view/current_order_screen.dart`
- `lib/view/screens/current_order_screen/widget/active_order_pickup_view.dart`
- `lib/view/screens/current_order_screen/widget/pickup_map.dart`
- `lib/view/screens/home_screen/cubit/home_availability_cubit.dart`
- `lib/view/screens/home_screen/cubit/home_availability_state.dart`
- `lib/view/screens/home_screen/cubit/pending_offers_cubit.dart`
- `lib/view/screens/home_screen/cubit/pending_offers_state.dart`
- `lib/view/screens/home_screen/view/home_screen.dart`
- `lib/view/screens/home_screen/widget/home_active_order_card.dart`
- `lib/view/screens/home_screen/widget/home_app_bar.dart`
- `lib/view/screens/home_screen/widget/home_availability_bar.dart`
- `lib/view/screens/home_screen/widget/home_availability_notice.dart`
- `lib/view/screens/home_screen/widget/home_availability_rationale_listener.dart`
- `lib/view/screens/home_screen/widget/home_greeting.dart`
- `lib/view/screens/home_screen/widget/home_lifecycle_bridge.dart`
- `lib/view/screens/home_screen/widget/pending_offers_header.dart`
- `lib/view/screens/home_screen/widget/pending_offers_sliver.dart`
- `lib/view/screens/home_screen/widget/wallet_balance_chip.dart`
- `lib/view/screens/no_internet_screen/view/no_internet_screen.dart`
- `lib/view/screens/order_history_screen/cubit/declined_offers_cubit.dart`
- `lib/view/screens/order_history_screen/cubit/declined_offers_state.dart`
- `lib/view/screens/order_history_screen/view/order_history_screen.dart`
- `lib/view/screens/order_history_screen/widget/declined_offer_tile.dart`
- `lib/view/screens/profile_screen/cubit/profile_rating_cubit.dart`
- `lib/view/screens/profile_screen/view/profile_screen.dart`
- `lib/view/screens/profile_screen/widget/profile_identity_card.dart`
- `lib/view/screens/profile_screen/widget/profile_rating_card.dart`
- `lib/view/screens/route_error_screen/view/route_error_screen.dart`
- `lib/view/screens/settings_screen/cubit/account_deletion_cubit.dart`
- `lib/view/screens/settings_screen/view/settings_screen.dart`
- `lib/view/screens/settings_screen/widget/account_deletion_confirmation.dart`
- `lib/view/screens/splash_screen/cubit/splash_cubit.dart`
- `lib/view/screens/splash_screen/cubit/splash_state.dart`
- `lib/view/screens/splash_screen/view/splash_screen.dart`
- `lib/view/screens/splash_screen/widget/splash_startup_status.dart`
- `lib/view/screens/wallet_screen/cubit/wallet_cubit.dart`
- `lib/view/screens/wallet_screen/cubit/wallet_state.dart`
- `lib/view/screens/wallet_screen/view/wallet_screen.dart`
- `lib/view/screens/wallet_screen/widget/wallet_balance_card.dart`
- `lib/view/screens/wallet_screen/widget/wallet_debit_card.dart`
- `lib/view/screens/wallet_screen/widget/wallet_metric_cards.dart`
- `lib/view/widget/buttons/app_button.dart`
- `lib/view/widget/buttons/app_icon_position.dart`
- `lib/view/widget/buttons/app_text_button.dart`
- `lib/view/widget/legal/terms_page_opener.dart`
- `lib/view/widget/navigation/main_nav_destination.dart`
- `lib/view/widget/navigation/main_navigation_bar.dart`
- `lib/view/widget/order/app_order_offer_card.dart`
- `lib/view/widget/pop_up_screen/app_popup.dart`
- `lib/view/widget/status/app_status_message.dart`
- `lib/view/widget/text/app_text_widget.dart`
- `lib/view/widget/text/body_text1.dart`
- `lib/view/widget/text/body_text2.dart`
- `lib/view/widget/text/caption.dart`
- `lib/view/widget/text/headline1.dart`
- `lib/view/widget/text/headline2.dart`
- `lib/view/widget/text/headline3.dart`
- `lib/view/widget/text/headline4.dart`
- `lib/view/widget/text/headline5.dart`
- `lib/view/widget/text/headline6.dart`
- `lib/view/widget/text/subtitle1.dart`
- `lib/view/widget/text/subtitle2.dart`
- `lib/view/widget/text_field/app_text_field_style.dart`
- `lib/view/widget/text_field/app_text_form_field.dart`
- `lib/view/widget/toast/app_toast.dart`
- `lib/view/widget/toggle/app_availability_toggle.dart`

</details>

## 4. All paths

<details><summary>Full list with category</summary>

| Path | Category |
|---|---|
| `.gitignore` | config/root |
| `.metadata` | config/root |
| `CLAUDE.md` | config/root |
| `README.md` | config/root |
| `analysis_options.yaml` | config/root |
| `android/.gitignore` | platform |
| `android/app/build.gradle.kts` | platform |
| `android/app/src/debug/AndroidManifest.xml` | platform |
| `android/app/src/main/AndroidManifest.xml` | platform |
| `android/app/src/main/kotlin/com/example/mobile_frontend/MainActivity.kt` | platform |
| `android/app/src/main/res/drawable-v21/launch_background.xml` | platform |
| `android/app/src/main/res/drawable/launch_background.xml` | platform |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | platform |
| `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | platform |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | platform |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | platform |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | platform |
| `android/app/src/main/res/values-night/styles.xml` | platform |
| `android/app/src/main/res/values/styles.xml` | platform |
| `android/app/src/profile/AndroidManifest.xml` | platform |
| `android/build.gradle.kts` | platform |
| `android/gradle.properties` | platform |
| `android/gradle/wrapper/gradle-wrapper.properties` | platform |
| `android/settings.gradle.kts` | platform |
| *the removable debug demo: its code folder and its 7 fixture files* | demo/tool — listed by path in `tool/demo/install_manifest.json`, not here, so this report stays scannable by the demo-removal tool (AUDIT_METHOD §6) |
| `assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Bold.ttf` | asset-font |
| `assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Light.ttf` | asset-font |
| `assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Medium.ttf` | asset-font |
| `assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Regular.ttf` | asset-font |
| `assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-SemiBold.ttf` | asset-font |
| `assets/fonts/ibm_plex_sans_arabic/OFL.txt` | asset-font |
| `assets/images/png/shahm_logo.png` | asset |
| `devtools_options.yaml` | config/root |
| `docs/01_APPLICATION_AUDIT_REPORT.md` | doc |
| `docs/02_FILE_BY_FILE_INVENTORY.md` | doc |
| `docs/03_SYSTEM_DATA_REQUIREMENTS.md` | doc |
| `docs/CLAUDE_PROJECT_INSTRUCTIONS.md` | doc |
| `docs/README.md` | doc |
| `docs/architecture/ARCHITECTURE.md` | doc |
| `docs/architecture/GLOBAL_SERVICES.md` | doc |
| `docs/architecture/ROUTING_AND_STARTUP.md` | doc |
| `docs/architecture/STATE_MANAGEMENT.md` | doc |
| `docs/decisions/ARCHITECTURAL_DECISIONS.md` | doc |
| `docs/project/PRODUCT_OVERVIEW.md` | doc |
| `docs/project/PROJECT_STATUS.md` | doc |
| `docs/quality/AUDIT_METHOD.md` | doc |
| `docs/quality/ENGINEERING_LESSONS.md` | doc |
| `docs/quality/REMEDIATION_STATUS.md` | doc |
| `docs/quality/reports/2026-11-22-post-fix/01_APPLICATION_AUDIT_REPORT.md` | doc |
| `docs/quality/reports/2026-11-22-post-fix/02_FILE_BY_FILE_INVENTORY.md` | doc |
| `docs/quality/reports/2026-11-22-post-fix/03_SYSTEM_DATA_REQUIREMENTS.md` | doc |
| `docs/release/STORE_SUBMISSION_COMPLIANCE.md` | doc |
| `docs/ui/CUSTOM_WIDGET_CONTRACT_STANDARD.md` | doc |
| `docs/ui/DESIGN_SYSTEM.md` | doc |
| `docs/ui/SHARED_UI_COMPONENTS_REFERENCE.md` | doc |
| `ios/.gitignore` | platform |
| `ios/Flutter/AppFrameworkInfo.plist` | platform |
| `ios/Flutter/Debug.xcconfig` | platform |
| `ios/Flutter/Release.xcconfig` | platform |
| `ios/Podfile` | platform |
| `ios/Runner.xcodeproj/project.pbxproj` | platform |
| `ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | platform |
| `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | platform |
| `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | platform |
| `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | platform |
| `ios/Runner.xcworkspace/contents.xcworkspacedata` | platform |
| `ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | platform |
| `ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | platform |
| `ios/Runner/AppDelegate.swift` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png` | platform |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png` | platform |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json` | platform |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` | platform |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` | platform |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` | platform |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` | platform |
| `ios/Runner/Base.lproj/LaunchScreen.storyboard` | platform |
| `ios/Runner/Base.lproj/Main.storyboard` | platform |
| `ios/Runner/Info.plist` | platform |
| `ios/Runner/Runner-Bridging-Header.h` | platform |
| `ios/Runner/SceneDelegate.swift` | platform |
| `ios/RunnerTests/RunnerTests.swift` | platform |
| `l10n.yaml` | config/root |
| `lib/data/models/app_user_model.dart` | runtime |
| `lib/data/repositories/active_order_repository_placeholder.dart` | runtime |
| `lib/data/repositories/auth_repository_placeholder.dart` | runtime |
| `lib/data/repositories/availability_permission_gateway_placeholder.dart` | runtime |
| `lib/data/repositories/captain_account_repository_placeholder.dart` | runtime |
| `lib/data/repositories/captain_availability_repository_placeholder.dart` | runtime |
| `lib/data/repositories/captain_location_repository_placeholder.dart` | runtime |
| `lib/data/repositories/order_history_repository_placeholder.dart` | runtime |
| `lib/data/repositories/order_offer_repository_placeholder.dart` | runtime |
| `lib/data/repositories/wallet_repository_placeholder.dart` | runtime |
| `lib/domain/entities/active_order.dart` | runtime |
| `lib/domain/entities/app_user.dart` | runtime |
| `lib/domain/entities/captain_account.dart` | runtime |
| `lib/domain/entities/captain_availability.dart` | runtime |
| `lib/domain/entities/declined_offer.dart` | runtime |
| `lib/domain/entities/order_offer.dart` | runtime |
| `lib/domain/entities/wallet.dart` | runtime |
| `lib/domain/errors/auth_exceptions.dart` | runtime |
| `lib/domain/errors/availability_exceptions.dart` | runtime |
| `lib/domain/errors/captain_account_exceptions.dart` | runtime |
| `lib/domain/errors/order_exceptions.dart` | runtime |
| `lib/domain/errors/order_history_exceptions.dart` | runtime |
| `lib/domain/errors/order_offer_exceptions.dart` | runtime |
| `lib/domain/errors/wallet_exceptions.dart` | runtime |
| `lib/domain/repositories/active_order_repository.dart` | runtime |
| `lib/domain/repositories/auth_repository.dart` | runtime |
| `lib/domain/repositories/availability_permission_gateway.dart` | runtime |
| `lib/domain/repositories/captain_account_repository.dart` | runtime |
| `lib/domain/repositories/captain_availability_repository.dart` | runtime |
| `lib/domain/repositories/captain_location_repository.dart` | runtime |
| `lib/domain/repositories/order_history_repository.dart` | runtime |
| `lib/domain/repositories/order_offer_repository.dart` | runtime |
| `lib/domain/repositories/wallet_repository.dart` | runtime |
| `lib/domain/use_cases/captain_account.dart` | runtime |
| `lib/domain/use_cases/captain_availability.dart` | runtime |
| `lib/domain/use_cases/check_auth_status.dart` | runtime |
| `lib/domain/use_cases/clear_rejected_session.dart` | runtime |
| `lib/domain/use_cases/get_active_order.dart` | runtime |
| `lib/domain/use_cases/get_captain_location.dart` | runtime |
| `lib/domain/use_cases/get_current_user.dart` | runtime |
| `lib/domain/use_cases/get_declined_offers.dart` | runtime |
| `lib/domain/use_cases/get_wallet.dart` | runtime |
| `lib/domain/use_cases/order_offers.dart` | runtime |
| `lib/domain/use_cases/sign_in.dart` | runtime |
| `lib/domain/use_cases/sign_out.dart` | runtime |
| `lib/helper/date/date_time_format.dart` | runtime |
| `lib/helper/legal/legal_links.dart` | runtime |
| `lib/helper/legal/legal_page_launcher.dart` | runtime |
| `lib/helper/money/jod_format.dart` | runtime |
| `lib/helper/network/internet_connection_service.dart` | runtime |
| `lib/helper/translation/app_ar.arb` | runtime |
| `lib/helper/translation/generated/app_localizations.dart` | generated |
| `lib/helper/translation/generated/app_localizations_ar.dart` | generated |
| `lib/helper/translation/l10n_extension.dart` | runtime |
| `lib/main.dart` | runtime |
| `lib/preview/home_offers_preview.dart` | preview |
| `lib/preview/new_offer_sheet_preview.dart` | preview |
| `lib/preview/wallet_preview.dart` | preview |
| `lib/theme/app_color.dart` | runtime |
| `lib/theme/app_theme.dart` | runtime |
| `lib/theme/text_themes.dart` | runtime |
| `lib/util/fonts.dart` | runtime |
| `lib/util/images.dart` | runtime |
| `lib/util/responsive/app_breakpoints.dart` | runtime |
| `lib/util/routes/debug_shell_preview.dart` | runtime |
| `lib/util/routes/go_router.dart` | runtime |
| `lib/util/routes/route_guard.dart` | runtime |
| `lib/util/routes/routes_string.dart` | runtime |
| `lib/util/routes/stream_refresh_listenable.dart` | runtime |
| `lib/util/validators/validation_error.dart` | runtime |
| `lib/util/validators/validation_messages.dart` | runtime |
| `lib/util/validators/validators.dart` | runtime |
| `lib/view/app_state/connectivity/app_connectivity_cubit.dart` | runtime |
| `lib/view/app_state/connectivity/app_connectivity_state.dart` | runtime |
| `lib/view/app_state/connectivity/global_connectivity_banner.dart` | runtime |
| `lib/view/app_state/session/app_session_cubit.dart` | runtime |
| `lib/view/app_state/session/app_session_state.dart` | runtime |
| `lib/view/navigation/app_nav_bar.dart` | runtime |
| `lib/view/navigation/current_order_navigation.dart` | runtime |
| `lib/view/navigation/new_offer_sheet_host.dart` | runtime |
| `lib/view/navigation/new_order_offer_sheet.dart` | runtime |
| `lib/view/screens/about_screen/view/about_screen.dart` | runtime |
| `lib/view/screens/authentication/cubit/login_cubit.dart` | runtime |
| `lib/view/screens/authentication/cubit/login_state.dart` | runtime |
| `lib/view/screens/authentication/view/login_screen.dart` | runtime |
| `lib/view/screens/authentication/widget/create_account_popup.dart` | runtime |
| `lib/view/screens/authentication/widget/debug_preview_button.dart` | runtime |
| `lib/view/screens/authentication/widget/forgot_password_popup.dart` | runtime |
| `lib/view/screens/authentication/widget/login_failure_message.dart` | runtime |
| `lib/view/screens/authentication/widget/login_form.dart` | runtime |
| `lib/view/screens/authentication/widget/login_terms_action.dart` | runtime |
| `lib/view/screens/current_order_screen/cubit/current_order_cubit.dart` | runtime |
| `lib/view/screens/current_order_screen/cubit/current_order_state.dart` | runtime |
| `lib/view/screens/current_order_screen/view/current_order_screen.dart` | runtime |
| `lib/view/screens/current_order_screen/widget/active_order_pickup_view.dart` | runtime |
| `lib/view/screens/current_order_screen/widget/pickup_map.dart` | runtime |
| `lib/view/screens/home_screen/cubit/home_availability_cubit.dart` | runtime |
| `lib/view/screens/home_screen/cubit/home_availability_state.dart` | runtime |
| `lib/view/screens/home_screen/cubit/pending_offers_cubit.dart` | runtime |
| `lib/view/screens/home_screen/cubit/pending_offers_state.dart` | runtime |
| `lib/view/screens/home_screen/view/home_screen.dart` | runtime |
| `lib/view/screens/home_screen/widget/home_active_order_card.dart` | runtime |
| `lib/view/screens/home_screen/widget/home_app_bar.dart` | runtime |
| `lib/view/screens/home_screen/widget/home_availability_bar.dart` | runtime |
| `lib/view/screens/home_screen/widget/home_availability_notice.dart` | runtime |
| `lib/view/screens/home_screen/widget/home_availability_rationale_listener.dart` | runtime |
| `lib/view/screens/home_screen/widget/home_greeting.dart` | runtime |
| `lib/view/screens/home_screen/widget/home_lifecycle_bridge.dart` | runtime |
| `lib/view/screens/home_screen/widget/pending_offers_header.dart` | runtime |
| `lib/view/screens/home_screen/widget/pending_offers_sliver.dart` | runtime |
| `lib/view/screens/home_screen/widget/wallet_balance_chip.dart` | runtime |
| `lib/view/screens/no_internet_screen/view/no_internet_screen.dart` | runtime |
| `lib/view/screens/order_history_screen/cubit/declined_offers_cubit.dart` | runtime |
| `lib/view/screens/order_history_screen/cubit/declined_offers_state.dart` | runtime |
| `lib/view/screens/order_history_screen/view/order_history_screen.dart` | runtime |
| `lib/view/screens/order_history_screen/widget/declined_offer_tile.dart` | runtime |
| `lib/view/screens/profile_screen/cubit/profile_rating_cubit.dart` | runtime |
| `lib/view/screens/profile_screen/view/profile_screen.dart` | runtime |
| `lib/view/screens/profile_screen/widget/profile_identity_card.dart` | runtime |
| `lib/view/screens/profile_screen/widget/profile_rating_card.dart` | runtime |
| `lib/view/screens/route_error_screen/view/route_error_screen.dart` | runtime |
| `lib/view/screens/settings_screen/cubit/account_deletion_cubit.dart` | runtime |
| `lib/view/screens/settings_screen/view/settings_screen.dart` | runtime |
| `lib/view/screens/settings_screen/widget/account_deletion_confirmation.dart` | runtime |
| `lib/view/screens/splash_screen/cubit/splash_cubit.dart` | runtime |
| `lib/view/screens/splash_screen/cubit/splash_state.dart` | runtime |
| `lib/view/screens/splash_screen/view/splash_screen.dart` | runtime |
| `lib/view/screens/splash_screen/widget/splash_startup_status.dart` | runtime |
| `lib/view/screens/wallet_screen/cubit/wallet_cubit.dart` | runtime |
| `lib/view/screens/wallet_screen/cubit/wallet_state.dart` | runtime |
| `lib/view/screens/wallet_screen/view/wallet_screen.dart` | runtime |
| `lib/view/screens/wallet_screen/widget/wallet_balance_card.dart` | runtime |
| `lib/view/screens/wallet_screen/widget/wallet_debit_card.dart` | runtime |
| `lib/view/screens/wallet_screen/widget/wallet_metric_cards.dart` | runtime |
| `lib/view/widget/buttons/app_button.dart` | runtime |
| `lib/view/widget/buttons/app_icon_position.dart` | runtime |
| `lib/view/widget/buttons/app_text_button.dart` | runtime |
| `lib/view/widget/legal/terms_page_opener.dart` | runtime |
| `lib/view/widget/navigation/main_nav_destination.dart` | runtime |
| `lib/view/widget/navigation/main_navigation_bar.dart` | runtime |
| `lib/view/widget/order/app_order_offer_card.dart` | runtime |
| `lib/view/widget/pop_up_screen/app_popup.dart` | runtime |
| `lib/view/widget/status/app_status_message.dart` | runtime |
| `lib/view/widget/text/app_text_widget.dart` | runtime |
| `lib/view/widget/text/body_text1.dart` | runtime |
| `lib/view/widget/text/body_text2.dart` | runtime |
| `lib/view/widget/text/caption.dart` | runtime |
| `lib/view/widget/text/headline1.dart` | runtime |
| `lib/view/widget/text/headline2.dart` | runtime |
| `lib/view/widget/text/headline3.dart` | runtime |
| `lib/view/widget/text/headline4.dart` | runtime |
| `lib/view/widget/text/headline5.dart` | runtime |
| `lib/view/widget/text/headline6.dart` | runtime |
| `lib/view/widget/text/subtitle1.dart` | runtime |
| `lib/view/widget/text/subtitle2.dart` | runtime |
| `lib/view/widget/text_field/app_text_field_style.dart` | runtime |
| `lib/view/widget/text_field/app_text_form_field.dart` | runtime |
| `lib/view/widget/toast/app_toast.dart` | runtime |
| `lib/view/widget/toggle/app_availability_toggle.dart` | runtime |
| `macos/.gitignore` | platform |
| `macos/Flutter/Flutter-Debug.xcconfig` | platform |
| `macos/Flutter/Flutter-Release.xcconfig` | platform |
| `macos/Flutter/GeneratedPluginRegistrant.swift` | platform |
| `macos/Runner.xcodeproj/project.pbxproj` | platform |
| `macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | platform |
| `macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | platform |
| `macos/Runner.xcworkspace/contents.xcworkspacedata` | platform |
| `macos/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | platform |
| `macos/Runner/AppDelegate.swift` | platform |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` | platform |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png` | platform |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png` | platform |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png` | platform |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png` | platform |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png` | platform |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png` | platform |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png` | platform |
| `macos/Runner/Base.lproj/MainMenu.xib` | platform |
| `macos/Runner/Configs/AppInfo.xcconfig` | platform |
| `macos/Runner/Configs/Debug.xcconfig` | platform |
| `macos/Runner/Configs/Release.xcconfig` | platform |
| `macos/Runner/Configs/Warnings.xcconfig` | platform |
| `macos/Runner/DebugProfile.entitlements` | platform |
| `macos/Runner/Info.plist` | platform |
| `macos/Runner/MainFlutterWindow.swift` | platform |
| `macos/Runner/Release.entitlements` | platform |
| `macos/RunnerTests/RunnerTests.swift` | platform |
| `pubspec.lock` | config/root |
| `pubspec.yaml` | config/root |
| `test/active_order_recovery_test.dart` | test |
| `test/app_availability_toggle_test.dart` | test |
| `test/auth_use_cases_test.dart` | test |
| `test/availability_fakes.dart` | test |
| `test/brand_theme_test.dart` | test |
| `test/connectivity_test.dart` | test |
| `test/current_order_test.dart` | test |
| `test/custom_widgets_test.dart` | test |
| `test/demo_mode_test.dart` | demo/tool |
| `test/fakes.dart` | test |
| `test/home_architecture_test.dart` | test |
| `test/home_availability_test.dart` | test |
| `test/home_offers_test.dart` | test |
| `test/home_screen_test.dart` | test |
| `test/home_tab_reentry_test.dart` | test |
| `test/legal_page_launcher_test.dart` | test |
| `test/localization_responsive_test.dart` | test |
| `test/login_cubit_test.dart` | test |
| `test/login_screen_test.dart` | test |
| `test/main_navigation_bar_test.dart` | test |
| `test/main_navigation_test.dart` | test |
| `test/new_offer_sheet_test.dart` | test |
| `test/order_card_icons_test.dart` | test |
| `test/profile_settings_test.dart` | test |
| `test/route_guard_test.dart` | test |
| `test/shared_widgets_test.dart` | test |
| `test/splash_cubit_test.dart` | test |
| `test/startup_flow_test.dart` | test |
| `test/test_app.dart` | test |
| `test/text_widgets_test.dart` | test |
| `test/timeout_policy_test.dart` | test |
| `test/validators_test.dart` | test |
| `test/wallet_test.dart` | test |
| `tool/demo/README.md` | demo/tool |
| `tool/demo/install_manifest.json` | demo/tool |
| `tool/demo/remove_demo.dart` | demo/tool |
| `tool/demo/remove_demo.sh` | demo/tool |
| `web/favicon.png` | platform |
| `web/icons/Icon-192.png` | platform |
| `web/icons/Icon-512.png` | platform |
| `web/icons/Icon-maskable-192.png` | platform |
| `web/icons/Icon-maskable-512.png` | platform |
| `web/index.html` | platform |
| `web/manifest.json` | platform |

</details>

