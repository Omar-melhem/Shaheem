# 02 — جرد الملفات ملفاً بملف
- التشغيل: `20261122T110746Z-cefad0a` — UTC ‏2026-11-22 11:07:46، توقيت عمّان 14:07:46 (+03).
- المستودع: `/Users/yousef_hamdan/Documents/GitHub/Shaheem` — الفرع `Yousef-Hamdan`، HEAD `cefad0a`، شجرة عمل نظيفة (0 ملفات معدلة/غير متتبعة) في بداية الفحص ونهايته.
- نطاق الجرد: جميع الملفات المتتبعة في `mobile_frontend/` ‏(340). لا توجد ملفات غير متتبعة. المستثنى صراحةً: `.git/` و`build/` و`.dart_tool/` و`ios/Pods` و`ios/.symlinks` و`android/.gradle` وملفات `.DS_Store` و`local.properties` و`GeneratedPluginRegistrant` (مخرجات أدوات/بيئة محلية، ليست مصدراً مؤلَّفاً).
- `backend/` في جذر المستودع فارغ؛ لا يوجد عقد OpenAPI.

## طريقة القراءة

ملفات Dart التشغيلية (الإنتاج + العرض التجريبي + المعاينة، 170 ملفاً، ‏15,780 سطراً) قُرئت كاملةً: كل سطر شيفرة مع رقم سطره. أسطر التعليقات (`//` و`///`) فُحصت آلياً بحثاً عن نصوص وتسميات، ولم تُعرض كلها؛ وهذا لا يؤثر في السلوك التشغيلي. ملفات الاختبار قُرئت في الأجزاء ذات الصلة. الوثائق المعيارية قُرئت بمحتواها المعياري الحالي.

## إجماليات حسب الفئة

| الفئة | العدد |
|---|---|
| أصل | 1 |
| بيانات تجريبية JSON | 7 |
| خط | 6 |
| إعداد | 7 |
| عرض تجريبي (Dart) | 9 |
| وثيقة | 16 |
| مولّد | 2 |
| منصة | 94 |
| معاينة (Dart) | 3 |
| مورد ARB | 1 |
| تشغيلي إنتاجي (Dart) | 158 |
| اختبار | 32 |
| أداة | 4 |
| **المجموع** | **340** |

- ملفات تشغيلية مؤلَّفة قُرئت كاملة: **170 / 170**. جزئية أو غير مقروءة: **0**.

## جدول مسؤوليات المجلدات

| المجلد | المسؤولية الفعلية | ملاحظات |
|---|---|---|
| `lib/domain/` | كيانات، أخطاء مصنّفة، عقود مستودعات، حالات استخدام — بلا Flutter | نظيف (لا استيراد Flutter/data/view) |
| `lib/data/` | نموذج AppUserModel و8 مستودعات placeholder | لا DTO ولا مصدر بيانات حقيقي (ARCH-07) |
| `lib/helper/` | اتصال، تنسيق مال/تاريخ، روابط قانونية، ترجمة | سليم |
| `lib/theme/` | AppColor، AppTheme، TextThemeStyle | سليم |
| `lib/util/` | مسارات، تحقق، أدوات، نقاط توقف | go_router.dart يستورد view (ARCH-01)؛ tools ميتة جزئياً (ARCH-02) |
| `lib/view/app_state/` | Cubits الاتصال والجلسة + الشريط العام | سليم |
| `lib/view/navigation/` | الصدفة، مضيف النافذة، محتوى النافذة | دالة ملاحة عامة داخل ملف المضيف (ARCH-04) |
| `lib/view/screens/` | 11 مجلد ميزة | splash_screen/bloc ميت (ARCH-03) |
| `lib/view/widget/` | مكونات مشتركة | عائلة النصوص غير مستخدمة (SW-04) |
| `lib/demo/` | عرض debug تجريبي قابل للإزالة | معزول ببوابة تفعيل |
| `lib/preview/` | 3 معاينات تصميم مستقلة | غير مستوردة من التطبيق (مختبر) |
| `test/` | 32 ملفاً، 1001 اختبار | أكواد مزيفة فقط |
| `tool/demo/` | مزيل العرض التجريبي | — |

## الجرد الكامل

| # | المسار | الفئة | الأسطر | نطاق المراجعة | الدور/الرموز الرئيسية | النتائج | الخلاصة |
|---|---|---|---|---|---|---|---|
| 1 | `.gitignore` | إعداد | 48 | full | إعداد المشروع | — | — |
| 2 | `.metadata` | إعداد | 39 | full | إعداد المشروع | — | — |
| 3 | `CLAUDE.md` | وثيقة | 295 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 4 | `README.md` | وثيقة | 3 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 5 | `analysis_options.yaml` | إعداد | 1 | full | إعداد المشروع | — | — |
| 6 | `android/.gitignore` | منصة | 14 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 7 | `android/app/build.gradle.kts` | منصة | 45 | relevant sections | إعداد منصة | PLAT-01, LOC-05 | اسم القالب/أذونات ناقصة |
| 8 | `android/app/src/debug/AndroidManifest.xml` | منصة | 7 | relevant sections | إعداد منصة | PLAT-01, LOC-05 | اسم القالب/أذونات ناقصة |
| 9 | `android/app/src/main/AndroidManifest.xml` | منصة | 45 | relevant sections | إعداد منصة | PLAT-01, LOC-05 | اسم القالب/أذونات ناقصة |
| 10 | `android/app/src/main/kotlin/com/example/mobile_frontend/MainActivity.kt` | منصة | 5 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 11 | `android/app/src/main/res/drawable-v21/launch_background.xml` | منصة | 12 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 12 | `android/app/src/main/res/drawable/launch_background.xml` | منصة | 12 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 13 | `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 14 | `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 15 | `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 16 | `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 17 | `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 18 | `android/app/src/main/res/values-night/styles.xml` | منصة | 18 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 19 | `android/app/src/main/res/values/styles.xml` | منصة | 18 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 20 | `android/app/src/profile/AndroidManifest.xml` | منصة | 7 | relevant sections | إعداد منصة | PLAT-01, LOC-05 | اسم القالب/أذونات ناقصة |
| 21 | `android/build.gradle.kts` | منصة | 24 | relevant sections | إعداد منصة | PLAT-01, LOC-05 | اسم القالب/أذونات ناقصة |
| 22 | `android/gradle.properties` | منصة | 6 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 23 | `android/gradle/wrapper/gradle-wrapper.properties` | منصة | 5 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 24 | `android/settings.gradle.kts` | منصة | 26 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 25 | `assets/demo/fixtures/auth.json` | بيانات تجريبية JSON | 16 | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 26 | `assets/demo/fixtures/captain.json` | بيانات تجريبية JSON | 18 | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 27 | `assets/demo/fixtures/current_order.json` | بيانات تجريبية JSON | 32 | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 28 | `assets/demo/fixtures/home.json` | بيانات تجريبية JSON | 12 | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 29 | `assets/demo/fixtures/offers.json` | بيانات تجريبية JSON | 73 | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 30 | `assets/demo/fixtures/order_history.json` | بيانات تجريبية JSON | 55 | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 31 | `assets/demo/fixtures/wallet.json` | بيانات تجريبية JSON | 58 | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 32 | `assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Bold.ttf` | خط | - | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 33 | `assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Light.ttf` | خط | - | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 34 | `assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Medium.ttf` | خط | - | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 35 | `assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Regular.ttf` | خط | - | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 36 | `assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-SemiBold.ttf` | خط | - | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 37 | `assets/fonts/ibm_plex_sans_arabic/OFL.txt` | خط | 93 | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 38 | `assets/images/png/shahm_logo.png` | أصل | - | metadata only | أصل ثنائي/بيانات تجريبية | — | مسجل في pubspec |
| 39 | `devtools_options.yaml` | إعداد | 3 | full | إعداد المشروع | — | — |
| 40 | `docs/CLAUDE_PROJECT_INSTRUCTIONS.md` | وثيقة | 213 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 41 | `docs/README.md` | وثيقة | 80 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 42 | `docs/architecture/ARCHITECTURE.md` | وثيقة | 204 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 43 | `docs/architecture/GLOBAL_SERVICES.md` | وثيقة | 211 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 44 | `docs/architecture/ROUTING_AND_STARTUP.md` | وثيقة | 343 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 45 | `docs/architecture/STATE_MANAGEMENT.md` | وثيقة | 287 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 46 | `docs/decisions/ARCHITECTURAL_DECISIONS.md` | وثيقة | 289 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 47 | `docs/project/PRODUCT_OVERVIEW.md` | وثيقة | 396 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 48 | `docs/project/PROJECT_STATUS.md` | وثيقة | 656 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 49 | `docs/release/STORE_SUBMISSION_COMPLIANCE.md` | وثيقة | 288 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 50 | `docs/ui/CUSTOM_WIDGET_CONTRACT_STANDARD.md` | وثيقة | 308 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 51 | `docs/ui/DESIGN_SYSTEM.md` | وثيقة | 343 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 52 | `docs/ui/SHARED_UI_COMPONENTS_REFERENCE.md` | وثيقة | 1366 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 53 | `ios/.gitignore` | منصة | 34 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 54 | `ios/Flutter/AppFrameworkInfo.plist` | منصة | 24 | relevant sections | إعداد منصة | PLAT-01, LOC-05 | اسم القالب/أذونات ناقصة |
| 55 | `ios/Flutter/Debug.xcconfig` | منصة | 2 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 56 | `ios/Flutter/Release.xcconfig` | منصة | 2 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 57 | `ios/Podfile` | منصة | 42 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 58 | `ios/Runner.xcodeproj/project.pbxproj` | منصة | 756 | relevant sections | إعداد منصة | PLAT-01, LOC-05 | اسم القالب/أذونات ناقصة |
| 59 | `ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | منصة | 7 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 60 | `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | منصة | 8 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 61 | `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | منصة | 8 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 62 | `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | منصة | 119 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 63 | `ios/Runner.xcworkspace/contents.xcworkspacedata` | منصة | 10 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 64 | `ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | منصة | 8 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 65 | `ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | منصة | 8 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 66 | `ios/Runner/AppDelegate.swift` | منصة | 16 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 67 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` | منصة | 122 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 68 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 69 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 70 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 71 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 72 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 73 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 74 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 75 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 76 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 77 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 78 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 79 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 80 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 81 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 82 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 83 | `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json` | منصة | 23 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 84 | `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 85 | `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 86 | `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 87 | `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` | وثيقة | 5 | relevant sections | وثيقة | — | مرجع معياري/تاريخي |
| 88 | `ios/Runner/Base.lproj/LaunchScreen.storyboard` | منصة | 37 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 89 | `ios/Runner/Base.lproj/Main.storyboard` | منصة | 26 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 90 | `ios/Runner/Info.plist` | منصة | 70 | relevant sections | إعداد منصة | PLAT-01, LOC-05 | اسم القالب/أذونات ناقصة |
| 91 | `ios/Runner/Runner-Bridging-Header.h` | منصة | 1 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 92 | `ios/Runner/SceneDelegate.swift` | منصة | 6 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 93 | `ios/RunnerTests/RunnerTests.swift` | منصة | 12 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 94 | `l10n.yaml` | إعداد | 11 | full | إعداد المشروع | — | — |
| 95 | `lib/data/models/app_user_model.dart` | تشغيلي إنتاجي (Dart) | 35 | full | نموذج بيانات المستخدم | ARCH-07 | بلا fromJson |
| 96 | `lib/data/repositories/active_order_repository_placeholder.dart` | تشغيلي إنتاجي (Dart) | 21 | full | طبقة البيانات (placeholder) | — | سليم ضمن نطاق الفحص |
| 97 | `lib/data/repositories/auth_repository_placeholder.dart` | تشغيلي إنتاجي (Dart) | 49 | full | طبقة البيانات (placeholder) | — | سليم ضمن نطاق الفحص |
| 98 | `lib/data/repositories/availability_permission_gateway_placeholder.dart` | تشغيلي إنتاجي (Dart) | 36 | full | طبقة البيانات (placeholder) | — | سليم ضمن نطاق الفحص |
| 99 | `lib/data/repositories/captain_account_repository_placeholder.dart` | تشغيلي إنتاجي (Dart) | 25 | full | طبقة البيانات (placeholder) | — | سليم ضمن نطاق الفحص |
| 100 | `lib/data/repositories/captain_availability_repository_placeholder.dart` | تشغيلي إنتاجي (Dart) | 29 | full | طبقة البيانات (placeholder) | — | سليم ضمن نطاق الفحص |
| 101 | `lib/data/repositories/captain_location_repository_placeholder.dart` | تشغيلي إنتاجي (Dart) | 21 | full | طبقة البيانات (placeholder) | — | سليم ضمن نطاق الفحص |
| 102 | `lib/data/repositories/order_history_repository_placeholder.dart` | تشغيلي إنتاجي (Dart) | 18 | full | طبقة البيانات (placeholder) | — | سليم ضمن نطاق الفحص |
| 103 | `lib/data/repositories/order_offer_repository_placeholder.dart` | تشغيلي إنتاجي (Dart) | 30 | full | طبقة البيانات (placeholder) | — | سليم ضمن نطاق الفحص |
| 104 | `lib/data/repositories/wallet_repository_placeholder.dart` | تشغيلي إنتاجي (Dart) | 25 | full | طبقة البيانات (placeholder) | — | سليم ضمن نطاق الفحص |
| 105 | `lib/demo/demo_app.dart` | عرض تجريبي (Dart) | 90 | full | عرض تجريبي debug فقط (Task 37) — مستبعد من الإنتاج ببوابة kDebugMode && SHAHM_DEMO | — | نطاق تجريبي معزول |
| 106 | `lib/demo/demo_mode.dart` | عرض تجريبي (Dart) | 19 | full | عرض تجريبي debug فقط (Task 37) — مستبعد من الإنتاج ببوابة kDebugMode && SHAHM_DEMO | — | نطاق تجريبي معزول |
| 107 | `lib/demo/demo_state.dart` | عرض تجريبي (Dart) | 325 | full | عرض تجريبي debug فقط (Task 37) — مستبعد من الإنتاج ببوابة kDebugMode && SHAHM_DEMO | — | نطاق تجريبي معزول |
| 108 | `lib/demo/model/demo_fixtures.dart` | عرض تجريبي (Dart) | 376 | full | عرض تجريبي debug فقط (Task 37) — مستبعد من الإنتاج ببوابة kDebugMode && SHAHM_DEMO | — | نطاق تجريبي معزول |
| 109 | `lib/demo/repo/demo_auth_repository.dart` | عرض تجريبي (Dart) | 49 | full | عرض تجريبي debug فقط (Task 37) — مستبعد من الإنتاج ببوابة kDebugMode && SHAHM_DEMO | — | نطاق تجريبي معزول |
| 110 | `lib/demo/repo/demo_repositories.dart` | عرض تجريبي (Dart) | 111 | full | عرض تجريبي debug فقط (Task 37) — مستبعد من الإنتاج ببوابة kDebugMode && SHAHM_DEMO | — | نطاق تجريبي معزول |
| 111 | `lib/demo/widget/demo_home_wallet.dart` | عرض تجريبي (Dart) | 34 | full | عرض تجريبي debug فقط (Task 37) — مستبعد من الإنتاج ببوابة kDebugMode && SHAHM_DEMO | — | نطاق تجريبي معزول |
| 112 | `lib/demo/widget/demo_shell_bridge.dart` | عرض تجريبي (Dart) | 67 | full | عرض تجريبي debug فقط (Task 37) — مستبعد من الإنتاج ببوابة kDebugMode && SHAHM_DEMO | — | نطاق تجريبي معزول |
| 113 | `lib/demo/widget/demo_strip.dart` | عرض تجريبي (Dart) | 164 | full | عرض تجريبي debug فقط (Task 37) — مستبعد من الإنتاج ببوابة kDebugMode && SHAHM_DEMO | — | نطاق تجريبي معزول |
| 114 | `lib/domain/entities/active_order.dart` | تشغيلي إنتاجي (Dart) | 62 | full | كيان الطلب النشط | API-01 | بلا status/مراحل |
| 115 | `lib/domain/entities/app_user.dart` | تشغيلي إنتاجي (Dart) | 23 | full | المستخدم | API-03 | بلا اكتمال ملف/أهلية |
| 116 | `lib/domain/entities/captain_account.dart` | تشغيلي إنتاجي (Dart) | 38 | full | التقييم ونتيجة الحذف | API-06 | مقياس التقييم مفتوح D-P37 |
| 117 | `lib/domain/entities/captain_availability.dart` | تشغيلي إنتاجي (Dart) | 112 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 118 | `lib/domain/entities/declined_offer.dart` | تشغيلي إنتاجي (Dart) | 33 | full | سجل الرفض | API-07 | بلا orderId/منطقة/ترقيم |
| 119 | `lib/domain/entities/order_offer.dart` | تشغيلي إنتاجي (Dart) | 122 | full | كيان العرض | API-02 | بلا انتهاء صلاحية |
| 120 | `lib/domain/entities/wallet.dart` | تشغيلي إنتاجي (Dart) | 85 | full | المحفظة والإحصائيات | API-06 | صيغة الأرباح مفتوحة D-P36 |
| 121 | `lib/domain/errors/auth_exceptions.dart` | تشغيلي إنتاجي (Dart) | 60 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 122 | `lib/domain/errors/availability_exceptions.dart` | تشغيلي إنتاجي (Dart) | 32 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 123 | `lib/domain/errors/captain_account_exceptions.dart` | تشغيلي إنتاجي (Dart) | 31 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 124 | `lib/domain/errors/order_exceptions.dart` | تشغيلي إنتاجي (Dart) | 43 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 125 | `lib/domain/errors/order_history_exceptions.dart` | تشغيلي إنتاجي (Dart) | 25 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 126 | `lib/domain/errors/order_offer_exceptions.dart` | تشغيلي إنتاجي (Dart) | 36 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 127 | `lib/domain/errors/wallet_exceptions.dart` | تشغيلي إنتاجي (Dart) | 22 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 128 | `lib/domain/repositories/active_order_repository.dart` | تشغيلي إنتاجي (Dart) | 16 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 129 | `lib/domain/repositories/auth_repository.dart` | تشغيلي إنتاجي (Dart) | 48 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 130 | `lib/domain/repositories/availability_permission_gateway.dart` | تشغيلي إنتاجي (Dart) | 28 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 131 | `lib/domain/repositories/captain_account_repository.dart` | تشغيلي إنتاجي (Dart) | 20 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 132 | `lib/domain/repositories/captain_availability_repository.dart` | تشغيلي إنتاجي (Dart) | 30 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 133 | `lib/domain/repositories/captain_location_repository.dart` | تشغيلي إنتاجي (Dart) | 16 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 134 | `lib/domain/repositories/order_history_repository.dart` | تشغيلي إنتاجي (Dart) | 19 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 135 | `lib/domain/repositories/order_offer_repository.dart` | تشغيلي إنتاجي (Dart) | 37 | full | عقد العروض | API-02 | بلا مفتاح idempotency |
| 136 | `lib/domain/repositories/wallet_repository.dart` | تشغيلي إنتاجي (Dart) | 25 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 137 | `lib/domain/use_cases/captain_account.dart` | تشغيلي إنتاجي (Dart) | 130 | full | حالة استخدام | ARCH-06 | مهلة تُصنّف فشلاً عاماً لا "خدمة غير متاحة" |
| 138 | `lib/domain/use_cases/captain_availability.dart` | تشغيلي إنتاجي (Dart) | 96 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 139 | `lib/domain/use_cases/check_auth_status.dart` | تشغيلي إنتاجي (Dart) | 77 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 140 | `lib/domain/use_cases/clear_rejected_session.dart` | تشغيلي إنتاجي (Dart) | 17 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 141 | `lib/domain/use_cases/get_active_order.dart` | تشغيلي إنتاجي (Dart) | 77 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 142 | `lib/domain/use_cases/get_captain_location.dart` | تشغيلي إنتاجي (Dart) | 68 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 143 | `lib/domain/use_cases/get_current_user.dart` | تشغيلي إنتاجي (Dart) | 88 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 144 | `lib/domain/use_cases/get_declined_offers.dart` | تشغيلي إنتاجي (Dart) | 71 | full | حالة استخدام | ARCH-06 | مهلة تُصنّف فشلاً عاماً لا "خدمة غير متاحة" |
| 145 | `lib/domain/use_cases/get_wallet.dart` | تشغيلي إنتاجي (Dart) | 149 | full | حالة استخدام | ARCH-06 | مهلة تُصنّف فشلاً عاماً لا "خدمة غير متاحة" |
| 146 | `lib/domain/use_cases/order_offers.dart` | تشغيلي إنتاجي (Dart) | 142 | full | حالة استخدام | ARCH-06 | مهلة تُصنّف فشلاً عاماً لا "خدمة غير متاحة" |
| 147 | `lib/domain/use_cases/sign_in.dart` | تشغيلي إنتاجي (Dart) | 114 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 148 | `lib/domain/use_cases/sign_out.dart` | تشغيلي إنتاجي (Dart) | 13 | full | طبقة النطاق | — | سليم ضمن نطاق الفحص |
| 149 | `lib/helper/date/date_time_format.dart` | تشغيلي إنتاجي (Dart) | 14 | full | تكامل/مساعد | — | سليم ضمن نطاق الفحص |
| 150 | `lib/helper/legal/legal_links.dart` | تشغيلي إنتاجي (Dart) | 16 | full | تكامل/مساعد | — | سليم ضمن نطاق الفحص |
| 151 | `lib/helper/legal/legal_page_launcher.dart` | تشغيلي إنتاجي (Dart) | 142 | full | تكامل/مساعد | — | سليم ضمن نطاق الفحص |
| 152 | `lib/helper/money/jod_format.dart` | تشغيلي إنتاجي (Dart) | 28 | full | تكامل/مساعد | — | سليم ضمن نطاق الفحص |
| 153 | `lib/helper/network/internet_connection_service.dart` | تشغيلي إنتاجي (Dart) | 101 | full | تكامل/مساعد | — | سليم ضمن نطاق الفحص |
| 154 | `lib/helper/translation/app_ar.arb` | مورد ARB | 456 | full | مورد ARB العربي (214 مفتاحاً) | — | كل المفاتيح مستخدمة ولها وصف |
| 155 | `lib/helper/translation/generated/app_localizations.dart` | مولّد | 1422 | generated inspection | مخرجات gen_l10n من app_ar.arb | — | مولّد؛ لا يُحرَّر يدوياً |
| 156 | `lib/helper/translation/generated/app_localizations_ar.dart` | مولّد | 752 | generated inspection | مخرجات gen_l10n من app_ar.arb | — | مولّد؛ لا يُحرَّر يدوياً |
| 157 | `lib/helper/translation/l10n_extension.dart` | تشغيلي إنتاجي (Dart) | 12 | full | تكامل/مساعد | — | سليم ضمن نطاق الفحص |
| 158 | `lib/main.dart` | تشغيلي إنتاجي (Dart) | 367 | full | جذر التركيب (composition root): خدمات، Cubits على مستوى التطبيق، الراوتر، دورة الحياة، استعادة الطلب | ARCH-07 | سليم؛ توصيل يدوي بانتظار get_it (D-A64) |
| 159 | `lib/preview/home_offers_preview.dart` | معاينة (Dart) | 205 | full | معاينة تصميم مستقلة ببيانات تخيلية — غير مستوردة من التطبيق | — | نطاق معاينة |
| 160 | `lib/preview/new_offer_sheet_preview.dart` | معاينة (Dart) | 201 | full | معاينة تصميم مستقلة ببيانات تخيلية — غير مستوردة من التطبيق | — | نطاق معاينة |
| 161 | `lib/preview/wallet_preview.dart` | معاينة (Dart) | 165 | full | معاينة تصميم مستقلة ببيانات تخيلية — غير مستوردة من التطبيق | — | نطاق معاينة |
| 162 | `lib/theme/app_color.dart` | تشغيلي إنتاجي (Dart) | 96 | full | السمة | — | سليم ضمن نطاق الفحص |
| 163 | `lib/theme/app_theme.dart` | تشغيلي إنتاجي (Dart) | 134 | full | السمة | — | سليم ضمن نطاق الفحص |
| 164 | `lib/theme/text_themes.dart` | تشغيلي إنتاجي (Dart) | 109 | full | السمة | — | سليم ضمن نطاق الفحص |
| 165 | `lib/util/fonts.dart` | تشغيلي إنتاجي (Dart) | 13 | full | أدوات/مسارات | — | سليم ضمن نطاق الفحص |
| 166 | `lib/util/images.dart` | تشغيلي إنتاجي (Dart) | 4 | full | أدوات/مسارات | — | سليم ضمن نطاق الفحص |
| 167 | `lib/util/responsive/app_breakpoints.dart` | تشغيلي إنتاجي (Dart) | 45 | full | أدوات/مسارات | — | سليم ضمن نطاق الفحص |
| 168 | `lib/util/routes/debug_shell_preview.dart` | تشغيلي إنتاجي (Dart) | 42 | full | مفتاح معاينة debug مؤقت | — | مبرر (D-A40)، مؤقت |
| 169 | `lib/util/routes/go_router.dart` | تشغيلي إنتاجي (Dart) | 304 | full | بناء GoRouter وكل مزوّدي Cubits للمسارات | ARCH-01, ARCH-08, LOC-01 | موقعه في util يعكس اتجاه الاعتماد؛ لا errorBuilder |
| 170 | `lib/util/routes/route_guard.dart` | تشغيلي إنتاجي (Dart) | 115 | full | سياسة التوجيه الوحيدة | ARCH-01 | منطق سليم؛ يستورد حالات Cubit من view |
| 171 | `lib/util/routes/routes_string.dart` | تشغيلي إنتاجي (Dart) | 26 | full | ثوابت المسارات | — | سليم |
| 172 | `lib/util/routes/stream_refresh_listenable.dart` | تشغيلي إنتاجي (Dart) | 27 | full | ChangeNotifier لإعادة تشغيل التوجيه | — | حالة إطار عمل مبررة |
| 173 | `lib/util/tools/android_loading.dart` | تشغيلي إنتاجي (Dart) | 31 | full | مؤشر تحميل Android | ARCH-02, SW-04 | مستخدم فقط من showLoading غير المستخدم |
| 174 | `lib/util/tools/ios_loading.dart` | تشغيلي إنتاجي (Dart) | 31 | full | مؤشر تحميل iOS | ARCH-02 | كذلك |
| 175 | `lib/util/tools/tools.dart` | تشغيلي إنتاجي (Dart) | 196 | full | AppTools: أغلفة حوار/توست/تحميل وأدوات | ARCH-02 | معظم الأعضاء بلا مستهلك إنتاجي |
| 176 | `lib/util/validators/validation_error.dart` | تشغيلي إنتاجي (Dart) | 31 | full | أدوات/مسارات | — | سليم ضمن نطاق الفحص |
| 177 | `lib/util/validators/validation_messages.dart` | تشغيلي إنتاجي (Dart) | 20 | full | أدوات/مسارات | — | سليم ضمن نطاق الفحص |
| 178 | `lib/util/validators/validators.dart` | تشغيلي إنتاجي (Dart) | 162 | full | أدوات/مسارات | — | سليم ضمن نطاق الفحص |
| 179 | `lib/view/app_state/connectivity/app_connectivity_cubit.dart` | تشغيلي إنتاجي (Dart) | 113 | full | العرض | — | سليم ضمن نطاق الفحص |
| 180 | `lib/view/app_state/connectivity/app_connectivity_state.dart` | تشغيلي إنتاجي (Dart) | 28 | full | العرض | — | سليم ضمن نطاق الفحص |
| 181 | `lib/view/app_state/connectivity/global_connectivity_banner.dart` | تشغيلي إنتاجي (Dart) | 109 | full | العرض | — | سليم ضمن نطاق الفحص |
| 182 | `lib/view/app_state/session/app_session_cubit.dart` | تشغيلي إنتاجي (Dart) | 55 | full | العرض | — | سليم ضمن نطاق الفحص |
| 183 | `lib/view/app_state/session/app_session_state.dart` | تشغيلي إنتاجي (Dart) | 27 | full | العرض | — | سليم ضمن نطاق الفحص |
| 184 | `lib/view/navigation/app_nav_bar.dart` | تشغيلي إنتاجي (Dart) | 56 | full | العرض | — | سليم ضمن نطاق الفحص |
| 185 | `lib/view/navigation/new_offer_sheet_host.dart` | تشغيلي إنتاجي (Dart) | 420 | full | مقدّم نافذة العرض الجديد + ملاحة القبول + إغلاق عند وجود طلب نشط | ARCH-04 | يضم دالة ملاحة عامة openCurrentOrderPage |
| 186 | `lib/view/navigation/new_order_offer_sheet.dart` | تشغيلي إنتاجي (Dart) | 384 | full | محتوى نافذة العرض | LOC-02 | تركيب نصوص بفاصل ثابت |
| 187 | `lib/view/screens/about_screen/view/about_screen.dart` | تشغيلي إنتاجي (Dart) | 66 | full | العرض — شاشة | — | سليم ضمن نطاق الفحص |
| 188 | `lib/view/screens/authentication/cubit/login_cubit.dart` | تشغيلي إنتاجي (Dart) | 109 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 189 | `lib/view/screens/authentication/cubit/login_state.dart` | تشغيلي إنتاجي (Dart) | 83 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 190 | `lib/view/screens/authentication/view/login_screen.dart` | تشغيلي إنتاجي (Dart) | 160 | full | العرض — شاشة | — | سليم ضمن نطاق الفحص |
| 191 | `lib/view/screens/authentication/widget/create_account_popup.dart` | تشغيلي إنتاجي (Dart) | 25 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 192 | `lib/view/screens/authentication/widget/debug_preview_button.dart` | تشغيلي إنتاجي (Dart) | 48 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 193 | `lib/view/screens/authentication/widget/forgot_password_popup.dart` | تشغيلي إنتاجي (Dart) | 21 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 194 | `lib/view/screens/authentication/widget/login_failure_message.dart` | تشغيلي إنتاجي (Dart) | 27 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 195 | `lib/view/screens/authentication/widget/login_form.dart` | تشغيلي إنتاجي (Dart) | 122 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 196 | `lib/view/screens/authentication/widget/login_terms_action.dart` | تشغيلي إنتاجي (Dart) | 53 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 197 | `lib/view/screens/current_order_screen/cubit/current_order_cubit.dart` | تشغيلي إنتاجي (Dart) | 179 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 198 | `lib/view/screens/current_order_screen/cubit/current_order_state.dart` | تشغيلي إنتاجي (Dart) | 76 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 199 | `lib/view/screens/current_order_screen/view/current_order_screen.dart` | تشغيلي إنتاجي (Dart) | 130 | full | صفحة الطلب الحالي | API-01, S08 | لا خريطة/PIN/بدء توصيل |
| 200 | `lib/view/screens/current_order_screen/widget/active_order_pickup_view.dart` | تشغيلي إنتاجي (Dart) | 249 | full | عرض الاستلام | LOC-03, SW-01, API-01 | دمج نصّين بمسافة |
| 201 | `lib/view/screens/current_order_screen/widget/pickup_map.dart` | تشغيلي إنتاجي (Dart) | 37 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 202 | `lib/view/screens/home_screen/cubit/home_availability_cubit.dart` | تشغيلي إنتاجي (Dart) | 315 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 203 | `lib/view/screens/home_screen/cubit/home_availability_state.dart` | تشغيلي إنتاجي (Dart) | 126 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 204 | `lib/view/screens/home_screen/cubit/pending_offers_cubit.dart` | تشغيلي إنتاجي (Dart) | 166 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 205 | `lib/view/screens/home_screen/cubit/pending_offers_state.dart` | تشغيلي إنتاجي (Dart) | 100 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 206 | `lib/view/screens/home_screen/view/home_screen.dart` | تشغيلي إنتاجي (Dart) | 104 | full | العرض — شاشة | — | سليم ضمن نطاق الفحص |
| 207 | `lib/view/screens/home_screen/widget/home_active_order_card.dart` | تشغيلي إنتاجي (Dart) | 116 | full | سطر الطلب النشط/فشل التحقق في الرئيسية | ARCH-04, SW-01 | يستورد مساعد ملاحة من ملف مضيف النافذة |
| 208 | `lib/view/screens/home_screen/widget/home_app_bar.dart` | تشغيلي إنتاجي (Dart) | 115 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 209 | `lib/view/screens/home_screen/widget/home_availability_bar.dart` | تشغيلي إنتاجي (Dart) | 57 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 210 | `lib/view/screens/home_screen/widget/home_availability_notice.dart` | تشغيلي إنتاجي (Dart) | 129 | full | إشعار التوفر | LOC-03 | نقطة "•" حرفية |
| 211 | `lib/view/screens/home_screen/widget/home_availability_rationale_listener.dart` | تشغيلي إنتاجي (Dart) | 55 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 212 | `lib/view/screens/home_screen/widget/home_greeting.dart` | تشغيلي إنتاجي (Dart) | 34 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 213 | `lib/view/screens/home_screen/widget/home_lifecycle_bridge.dart` | تشغيلي إنتاجي (Dart) | 89 | full | تحميل الرئيسية عند الظهور/الاستئناف | ARCH-05 | نمط مكرر |
| 214 | `lib/view/screens/home_screen/widget/pending_offers_header.dart` | تشغيلي إنتاجي (Dart) | 76 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 215 | `lib/view/screens/home_screen/widget/pending_offers_sliver.dart` | تشغيلي إنتاجي (Dart) | 93 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 216 | `lib/view/screens/home_screen/widget/wallet_balance_chip.dart` | تشغيلي إنتاجي (Dart) | 123 | full | شريحة الرصيد | SW-04 | naturalWidth و_singleLineWidth بلا مستدعٍ |
| 217 | `lib/view/screens/no_internet_screen/view/no_internet_screen.dart` | تشغيلي إنتاجي (Dart) | 83 | full | شاشة لا إنترنت | SW-03 | FilledButton خام بدل AppButton |
| 218 | `lib/view/screens/order_history_screen/cubit/declined_offers_cubit.dart` | تشغيلي إنتاجي (Dart) | 105 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 219 | `lib/view/screens/order_history_screen/cubit/declined_offers_state.dart` | تشغيلي إنتاجي (Dart) | 43 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 220 | `lib/view/screens/order_history_screen/view/order_history_screen.dart` | تشغيلي إنتاجي (Dart) | 185 | full | شاشة طلباتي | ARCH-05, S05 | قسم التوصيلات المكتملة غير مبني |
| 221 | `lib/view/screens/order_history_screen/widget/declined_offer_tile.dart` | تشغيلي إنتاجي (Dart) | 89 | full | سجل عرض مرفوض | LOC-03, SW-01, API-07 | " · " حرفي |
| 222 | `lib/view/screens/profile_screen/cubit/profile_rating_cubit.dart` | تشغيلي إنتاجي (Dart) | 90 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 223 | `lib/view/screens/profile_screen/view/profile_screen.dart` | تشغيلي إنتاجي (Dart) | 165 | full | شاشة حسابي | SW-02, STATE-01 | تحميل التقييم مرة واحدة فقط |
| 224 | `lib/view/screens/profile_screen/widget/profile_identity_card.dart` | تشغيلي إنتاجي (Dart) | 107 | full | الاسم والهاتف | LOC-02, SW-01 | تركيب ": " |
| 225 | `lib/view/screens/profile_screen/widget/profile_rating_card.dart` | تشغيلي إنتاجي (Dart) | 114 | full | بطاقة التقييم | LOC-03, SW-01 | join(". ") |
| 226 | `lib/view/screens/settings_screen/cubit/account_deletion_cubit.dart` | تشغيلي إنتاجي (Dart) | 100 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 227 | `lib/view/screens/settings_screen/view/settings_screen.dart` | تشغيلي إنتاجي (Dart) | 142 | full | العرض — شاشة | — | سليم ضمن نطاق الفحص |
| 228 | `lib/view/screens/settings_screen/widget/account_deletion_confirmation.dart` | تشغيلي إنتاجي (Dart) | 36 | full | تأكيد الحذف | SW-02 | التفاف على AppPopup لإرجاع قيمة |
| 229 | `lib/view/screens/splash_screen/bloc/splash_bloc.dart` | تشغيلي إنتاجي (Dart) | 13 | full | SplashBloc ميت | ARCH-03 | حذف معتمد (D-A64) |
| 230 | `lib/view/screens/splash_screen/bloc/splash_event.dart` | تشغيلي إنتاجي (Dart) | 4 | full | جزء من SplashBloc | ARCH-03 | ميت |
| 231 | `lib/view/screens/splash_screen/bloc/splash_state.dart` | تشغيلي إنتاجي (Dart) | 6 | full | جزء من SplashBloc (تضارب أسماء) | ARCH-03 | ميت |
| 232 | `lib/view/screens/splash_screen/cubit/splash_cubit.dart` | تشغيلي إنتاجي (Dart) | 137 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 233 | `lib/view/screens/splash_screen/cubit/splash_state.dart` | تشغيلي إنتاجي (Dart) | 56 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 234 | `lib/view/screens/splash_screen/view/splash_screen.dart` | تشغيلي إنتاجي (Dart) | 50 | full | العرض — شاشة | — | سليم ضمن نطاق الفحص |
| 235 | `lib/view/screens/splash_screen/widget/splash_startup_status.dart` | تشغيلي إنتاجي (Dart) | 75 | full | حالة الإقلاع | SW-03 | FilledButton خام |
| 236 | `lib/view/screens/wallet_screen/cubit/wallet_cubit.dart` | تشغيلي إنتاجي (Dart) | 115 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 237 | `lib/view/screens/wallet_screen/cubit/wallet_state.dart` | تشغيلي إنتاجي (Dart) | 69 | full | العرض — Cubit/حالة | — | سليم ضمن نطاق الفحص |
| 238 | `lib/view/screens/wallet_screen/view/wallet_screen.dart` | تشغيلي إنتاجي (Dart) | 181 | full | شاشة المحفظة | ARCH-05, STATE-02 | لا إعادة تحميل عند الاستئناف (قرار مفتوح) |
| 239 | `lib/view/screens/wallet_screen/widget/wallet_balance_card.dart` | تشغيلي إنتاجي (Dart) | 80 | full | بطاقة الرصيد | LOC-02, SW-01 | تسمية دلالية مركبة |
| 240 | `lib/view/screens/wallet_screen/widget/wallet_debit_card.dart` | تشغيلي إنتاجي (Dart) | 127 | full | بطاقة خصم | LOC-02, SW-01 | تركيب "label: value" |
| 241 | `lib/view/screens/wallet_screen/widget/wallet_metric_cards.dart` | تشغيلي إنتاجي (Dart) | 188 | full | بطاقتا المقاييس | LOC-03, SW-01 | join(". ") للدلالات |
| 242 | `lib/view/widget/buttons/app_button.dart` | تشغيلي إنتاجي (Dart) | 238 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 243 | `lib/view/widget/buttons/app_icon_position.dart` | تشغيلي إنتاجي (Dart) | 7 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 244 | `lib/view/widget/buttons/app_text_button.dart` | تشغيلي إنتاجي (Dart) | 102 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 245 | `lib/view/widget/legal/terms_page_opener.dart` | تشغيلي إنتاجي (Dart) | 34 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 246 | `lib/view/widget/navigation/main_nav_destination.dart` | تشغيلي إنتاجي (Dart) | 55 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 247 | `lib/view/widget/navigation/main_navigation_bar.dart` | تشغيلي إنتاجي (Dart) | 307 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 248 | `lib/view/widget/order/app_order_offer_card.dart` | تشغيلي إنتاجي (Dart) | 305 | full | بطاقة العرض المشتركة | LOC-02, SW-01 | فاصل ": " مُركّب يدوياً |
| 249 | `lib/view/widget/padding/padding.dart` | تشغيلي إنتاجي (Dart) | 28 | full | CustomePadding | SW-04 | تكرار لـ Padding مع left/right فيزيائي |
| 250 | `lib/view/widget/pop_up_screen/app_popup.dart` | تشغيلي إنتاجي (Dart) | 402 | full | AppPopup المشترك | SW-02 | لا يدعم إجراء يُرجع قيمة |
| 251 | `lib/view/widget/status/app_status_message.dart` | تشغيلي إنتاجي (Dart) | 138 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 252 | `lib/view/widget/text/app_text_widget.dart` | تشغيلي إنتاجي (Dart) | 96 | full | ودجت نص مشترك (عائلة AppTextWidget) | SW-04 | بلا مستهلك إنتاجي |
| 253 | `lib/view/widget/text/body_text1.dart` | تشغيلي إنتاجي (Dart) | 39 | full | ودجت نص مشترك (عائلة AppTextWidget) | SW-04 | بلا مستهلك إنتاجي |
| 254 | `lib/view/widget/text/body_text2.dart` | تشغيلي إنتاجي (Dart) | 39 | full | ودجت نص مشترك (عائلة AppTextWidget) | SW-04 | بلا مستهلك إنتاجي |
| 255 | `lib/view/widget/text/caption.dart` | تشغيلي إنتاجي (Dart) | 31 | full | ودجت نص مشترك (عائلة AppTextWidget) | SW-04 | بلا مستهلك إنتاجي |
| 256 | `lib/view/widget/text/headline1.dart` | تشغيلي إنتاجي (Dart) | 31 | full | ودجت نص مشترك (عائلة AppTextWidget) | SW-04 | بلا مستهلك إنتاجي |
| 257 | `lib/view/widget/text/headline2.dart` | تشغيلي إنتاجي (Dart) | 31 | full | ودجت نص مشترك (عائلة AppTextWidget) | SW-04 | بلا مستهلك إنتاجي |
| 258 | `lib/view/widget/text/headline3.dart` | تشغيلي إنتاجي (Dart) | 31 | full | ودجت نص مشترك (عائلة AppTextWidget) | SW-04 | بلا مستهلك إنتاجي |
| 259 | `lib/view/widget/text/headline4.dart` | تشغيلي إنتاجي (Dart) | 42 | full | ودجت نص مشترك (عائلة AppTextWidget) | SW-04 | بلا مستهلك إنتاجي |
| 260 | `lib/view/widget/text/headline5.dart` | تشغيلي إنتاجي (Dart) | 42 | full | ودجت نص مشترك (عائلة AppTextWidget) | SW-04 | بلا مستهلك إنتاجي |
| 261 | `lib/view/widget/text/headline6.dart` | تشغيلي إنتاجي (Dart) | 31 | full | ودجت نص مشترك (عائلة AppTextWidget) | SW-04 | بلا مستهلك إنتاجي |
| 262 | `lib/view/widget/text/subtitle1.dart` | تشغيلي إنتاجي (Dart) | 31 | full | ودجت نص مشترك (عائلة AppTextWidget) | SW-04 | بلا مستهلك إنتاجي |
| 263 | `lib/view/widget/text/subtitle2.dart` | تشغيلي إنتاجي (Dart) | 31 | full | ودجت نص مشترك (عائلة AppTextWidget) | SW-04 | بلا مستهلك إنتاجي |
| 264 | `lib/view/widget/text_field/app_text_field_style.dart` | تشغيلي إنتاجي (Dart) | 169 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 265 | `lib/view/widget/text_field/app_text_form_field.dart` | تشغيلي إنتاجي (Dart) | 284 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 266 | `lib/view/widget/toast/app_toast.dart` | تشغيلي إنتاجي (Dart) | 301 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 267 | `lib/view/widget/toggle/app_availability_toggle.dart` | تشغيلي إنتاجي (Dart) | 134 | full | العرض — ودجت | — | سليم ضمن نطاق الفحص |
| 268 | `macos/.gitignore` | منصة | 7 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 269 | `macos/Flutter/Flutter-Debug.xcconfig` | منصة | 1 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 270 | `macos/Flutter/Flutter-Release.xcconfig` | منصة | 1 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 271 | `macos/Flutter/GeneratedPluginRegistrant.swift` | منصة | 22 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 272 | `macos/Runner.xcodeproj/project.pbxproj` | منصة | 729 | relevant sections | إعداد منصة | PLAT-01, LOC-05 | اسم القالب/أذونات ناقصة |
| 273 | `macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | منصة | 8 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 274 | `macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | منصة | 117 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 275 | `macos/Runner.xcworkspace/contents.xcworkspacedata` | منصة | 7 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 276 | `macos/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | منصة | 8 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 277 | `macos/Runner/AppDelegate.swift` | منصة | 13 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 278 | `macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` | منصة | 68 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 279 | `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 280 | `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 281 | `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 282 | `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 283 | `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 284 | `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 285 | `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 286 | `macos/Runner/Base.lproj/MainMenu.xib` | منصة | 343 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 287 | `macos/Runner/Configs/AppInfo.xcconfig` | منصة | 14 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 288 | `macos/Runner/Configs/Debug.xcconfig` | منصة | 2 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 289 | `macos/Runner/Configs/Release.xcconfig` | منصة | 2 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 290 | `macos/Runner/Configs/Warnings.xcconfig` | منصة | 13 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 291 | `macos/Runner/DebugProfile.entitlements` | منصة | 12 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 292 | `macos/Runner/Info.plist` | منصة | 32 | relevant sections | إعداد منصة | PLAT-01, LOC-05 | اسم القالب/أذونات ناقصة |
| 293 | `macos/Runner/MainFlutterWindow.swift` | منصة | 15 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 294 | `macos/Runner/Release.entitlements` | منصة | 8 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 295 | `macos/RunnerTests/RunnerTests.swift` | منصة | 12 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 296 | `pubspec.lock` | إعداد | 839 | full | إعداد المشروع | — | — |
| 297 | `pubspec.yaml` | إعداد | 93 | full | إعداد المشروع | PLAT-01 | — |
| 298 | `test/active_order_recovery_test.dart` | اختبار | 287 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 299 | `test/app_availability_toggle_test.dart` | اختبار | 222 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 300 | `test/auth_use_cases_test.dart` | اختبار | 133 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 301 | `test/availability_fakes.dart` | اختبار | 95 | relevant sections | اختبار/أداة اختبار | — | يغطي المسارات بأكواد مزيفة فقط |
| 302 | `test/brand_theme_test.dart` | اختبار | 302 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 303 | `test/connectivity_test.dart` | اختبار | 223 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 304 | `test/current_order_test.dart` | اختبار | 801 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 305 | `test/custom_widgets_test.dart` | اختبار | 3055 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 306 | `test/demo_mode_test.dart` | اختبار | 705 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 307 | `test/fakes.dart` | اختبار | 234 | relevant sections | اختبار/أداة اختبار | — | يغطي المسارات بأكواد مزيفة فقط |
| 308 | `test/home_architecture_test.dart` | اختبار | 291 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 309 | `test/home_availability_test.dart` | اختبار | 468 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 310 | `test/home_offers_test.dart` | اختبار | 904 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 311 | `test/home_screen_test.dart` | اختبار | 513 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 312 | `test/home_tab_reentry_test.dart` | اختبار | 393 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 313 | `test/legal_page_launcher_test.dart` | اختبار | 194 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 314 | `test/localization_responsive_test.dart` | اختبار | 98 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 315 | `test/login_cubit_test.dart` | اختبار | 297 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 316 | `test/login_screen_test.dart` | اختبار | 849 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 317 | `test/main_navigation_bar_test.dart` | اختبار | 336 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 318 | `test/main_navigation_test.dart` | اختبار | 459 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 319 | `test/new_offer_sheet_test.dart` | اختبار | 1365 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 320 | `test/order_card_icons_test.dart` | اختبار | 396 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 321 | `test/profile_settings_test.dart` | اختبار | 441 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 322 | `test/route_guard_test.dart` | اختبار | 296 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 323 | `test/shared_widgets_test.dart` | اختبار | 151 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 324 | `test/splash_cubit_test.dart` | اختبار | 191 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 325 | `test/startup_flow_test.dart` | اختبار | 250 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 326 | `test/test_app.dart` | اختبار | 36 | relevant sections | اختبار/أداة اختبار | — | يغطي المسارات بأكواد مزيفة فقط |
| 327 | `test/text_widgets_test.dart` | اختبار | 618 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 328 | `test/validators_test.dart` | اختبار | 275 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 329 | `test/wallet_test.dart` | اختبار | 754 | relevant sections | اختبار/أداة اختبار | TEST-01 | يغطي المسارات بأكواد مزيفة فقط |
| 330 | `tool/demo/README.md` | أداة | 109 | relevant sections | أداة إزالة العرض التجريبي | — | مسموح |
| 331 | `tool/demo/install_manifest.json` | أداة | 249 | relevant sections | أداة إزالة العرض التجريبي | — | مسموح |
| 332 | `tool/demo/remove_demo.dart` | أداة | 398 | relevant sections | أداة إزالة العرض التجريبي | — | مسموح |
| 333 | `tool/demo/remove_demo.sh` | أداة | 8 | relevant sections | أداة إزالة العرض التجريبي | — | مسموح |
| 334 | `web/favicon.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 335 | `web/icons/Icon-192.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 336 | `web/icons/Icon-512.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 337 | `web/icons/Icon-maskable-192.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 338 | `web/icons/Icon-maskable-512.png` | منصة | - | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 339 | `web/index.html` | منصة | 46 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
| 340 | `web/manifest.json` | منصة | 35 | metadata only | ملف منصة مولّد/قالب | — | بيانات وصفية فقط |
