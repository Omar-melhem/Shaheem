# 01 — تقرير تدقيق تطبيق كابتن شهم

## 1. بيانات التشغيل والنطاق والمرجعية

| البند | القيمة |
|---|---|
| معرّف التشغيل | `20261122T110746Z-cefad0a` |
| الوقت | UTC ‏2026-11-22 11:07:46 — عمّان 14:07:46 (+03) |
| جذر Git | `/Users/yousef_hamdan/Documents/GitHub/Shaheem` |
| التطبيق | `mobile_frontend/` |
| الفرع / HEAD | `Yousef-Hamdan` / `cefad0a` («Edit All Theme in the Project») |
| حالة الشجرة | نظيفة في بداية الفحص ونهايته (0 ملفات معدلة أو غير متتبعة) |
| الأدوات | Flutter 3.44.6 (stable)، Dart 3.12.2 |
| التبعيات الفعلية (pubspec) | flutter_bloc ^9.1.1، bloc ^9.2.1، go_router ^18.1.4، internet_connection_checker_plus ^3.1.2، responsive_framework ^1.5.1، phosphor_icons ^3.0.1، url_launcher ^6.3.3، intl ^0.20.2، flutter_localizations (SDK)، إضافة إلى تبعيات غير مستخدمة (PLAT-01) |
| الترجمة | `l10n.yaml` ← `lib/helper/translation/app_ar.arb` (عربية فقط، `nullable-getter: false`) |
| الواجهة الخلفية | `backend/` فارغ، ولا يوجد OpenAPI في المستودع |
| التشغيل السابق | لا يوجد (هذا أول تشغيل تحت `SHAHM_AUDITS`) |
| الوضع | `MODE=audit`: لم يُعدَّل أي ملف من التطبيق |

**المرجعية:** `mobile_frontend/CLAUDE.md`. القواعد المعتمدة الحالية هي D-A69 إلى D-A79 (§1.2 في `docs/decisions/ARCHITECTURAL_DECISIONS.md`) و`docs/project/PRODUCT_OVERVIEW.md`. حالة التنفيذ في `docs/project/PROJECT_STATUS.md` §0، وتحققتُ منها مقابل المصدر. لا يوجد `AGENTS.md`. البنود المحمّلة بعبارة «Superseded» في سجل القرارات تاريخية. القرارات المفتوحة D-P35 إلى D-P41 لم يُقرَّر فيها هنا.

**نقاط الدخول:**
- العادية: `lib/main.dart` ← `main()` ← `MainApp`.
- العرض التجريبي: `DemoApp`، لا يعمل إلا مع `kDebugMode && bool.fromEnvironment('SHAHM_DEMO')` (`lib/demo/demo_mode.dart`).
- المعاينات المستقلة الثلاث: `lib/preview/*.dart` عبر `flutter run -t`.
- معاينة debug للصدفة بلا جلسة: `DebugShellPreview` (D-A40).

جذر التركيب هو `MainApp`، والراوتر في `lib/util/routes/go_router.dart`، وسياسة التوجيه الوحيدة في `route_guard.dart`. الجلسة في `AppSessionCubit`، والطلب النشط في `CurrentOrderCubit` على مستوى التطبيق.

## 2. التغطية والاستثناءات

| الفئة | العدد | نطاق المراجعة |
|---|---|---|
| Dart تشغيلي إنتاجي | 158 | كامل |
| Dart عرض تجريبي | 9 | كامل |
| Dart معاينة | 3 | كامل |
| مولّد (gen_l10n) | 2 | فحص الأصل والتوصيل |
| ARB | 1 | كامل (214 مفتاحاً) |
| اختبارات | 32 | الأجزاء ذات الصلة |
| وثائق | 16 | المحتوى المعياري الحالي |
| منصات / أصول / إعداد / أدوات | 119 | ذات الصلة أو بيانات وصفية فقط |
| **المجموع** | **340** | — |

- **ملفات تشغيلية مؤلَّفة قُرئت كاملة: 170 / 170.** لا ملفات جزئية ولا غير مقروءة.
- **طريقة القراءة:** عُرضت كل أسطر الشيفرة بأرقامها، أما أسطر التعليقات فاستُخرجت آلياً ولم تُعرض كلها.
- **المستثنى:** `.git/`، `build/`، `.dart_tool/`، `ios/Pods`، `ios/.symlinks`، `android/.gradle`، `.DS_Store`، `local.properties`، `GeneratedPluginRegistrant`. هذه مخرجات أدوات وليست مصدراً مؤلَّفاً.
- الجرد التفصيلي في `02_FILE_BY_FILE_INVENTORY.md`.

## 3. ملخص النتائج

| الخطورة | العدد | المعرّفات |
|---|---|---|
| متوسطة | 5 | ARCH-02، ARCH-07، ARCH-08/LOC-01، LOC-05، PLAT-01 |
| منخفضة | 14 | ARCH-01، ARCH-03، ARCH-04، ARCH-05، ARCH-06، SW-01، SW-02، SW-03، SW-04، STATE-01، STATE-02، LOC-02، LOC-03، TEST-01 |
| فجوات عقد (لا عيوب كود) | 7 | API-01 إلى API-07 |

ARCH-08 وLOC-01 نتيجة واحدة مُعدّة مرة واحدة.

**لا توجد نتيجة حرجة.** لا حالة أعمال خارج Bloc/Cubit، ولا بيانات أعمال مثبّتة في المسار الإنتاجي، ولا نص واجهة عربي ثابت في الإنتاج. كل المستودعات الإنتاجية تقول «غير مُعدّ» بصدق.

## 4. المعمارية والمجلدات (ARCH)

### ARCH-01 — منخفضة — `util` يعتمد على `view`
- **المواقع:**
  - `lib/util/routes/go_router.dart:6-50`: يستورد 23 ملفاً من `view` (شاشات وCubits).
  - `lib/util/routes/route_guard.dart:5-7`: يستورد `CurrentOrderState` و`SplashState` و`AppSessionState`.
- **القاعدة:** `CLAUDE.md` §4. اتجاه `view → domain ← data`، و`util` للثوابت والأدوات، بينما ملف الراوتر هو عملياً جزء من التركيب.
- **الأثر:** دورة اعتماد مفاهيمية `util ↔ view`، وصعوبة نقل الأدوات بلا سحب الواجهة.
- **التصحيح المقترح:** نقل `go_router.dart` و`route_guard.dart` إلى `lib/view/navigation/routing/` (أو `lib/app/`) مع إبقاء `routes_string.dart` في `util`.
  - المستدعون: `main.dart` والاختبارات `route_guard_test` و`main_navigation_test` وغيرها. المطلوب تعديل الاستيرادات فقط.
- **التحقق:** `flutter analyze`، ثم `route_guard_test` و`main_navigation_test` و`active_order_recovery_test`.

### ARCH-02 — متوسطة — شيفرة ميتة في `util/tools`
- **المواقع:**
  - `lib/util/tools/tools.dart:42-112`: `createRandom` و`showCustomBottomSheet` و`timeFormatter` و`showLoading` و`hideLoading`.
  - `tools.dart:120-195`: `showAlertDialogTwoFun` و`showAlertDialogOneFun` و`show*Message`.
  - `android_loading.dart` و`ios_loading.dart`.
- **الدليل:** لا مستهلك إنتاجياً إلا `appTools.unFocusKeyboard` (`login_screen.dart:74`). البقية تستهلكها الاختبارات فقط (`shared_widgets_test` و`custom_widgets_test`).
- **القاعدة:** D-A64 (إزالة الشيفرة الميتة بعد التدقيق)، وD-P14 (نقل التحميل إلى `view/widget/loading/`).
- **التصحيح:** حذف الأعضاء غير المستخدمة واختباراتها، ونقل ما يلزم إلى `view/widget/loading/`. يُستبدل `unFocusKeyboard` بـ `FocusScope.of(context).unfocus()` مباشرة.
- **التحقق:** analyze، واختبارات الدخول والمكونات المشتركة.

### ARCH-03 — منخفضة — `splash_screen/bloc/` ميت
- **الموقع:** `lib/view/screens/splash_screen/bloc/splash_bloc.dart:7`.
- **المشكلة:** معالج فارغ، ويعيد تعريف الاسمين `SplashState` و`SplashInitial` الموجودين أيضاً في `splash_screen/cubit/splash_state.dart`. وهو مصدر تحذير المحلل الوحيد (`meta`)، والمستورد الوحيد لحزمة `bloc`.
- **القاعدة:** الحذف معتمد في D-A64 وD-P13.
- **التصحيح:** حذف المجلد، ثم إزالة تبعية `bloc` بعد تدقيق التبعيات.

### ARCH-04 — منخفضة — دالة ملاحة عامة داخل ملف مضيف نافذة
- **الموقع:** `openCurrentOrderPage` في `lib/view/navigation/new_offer_sheet_host.dart`. تستوردها `home_active_order_card.dart:31-49`.
- **الأثر:** ميزة الرئيسية تعتمد على ملف مضيف العروض لمجرد مساعد ملاحة.
- **التصحيح:** نقلها إلى `lib/view/navigation/current_order_navigation.dart`. يتأثر المستدعيان فقط.
- **التحقق:** `active_order_recovery_test` و`new_offer_sheet_test`.

### ARCH-05 — منخفضة — نمط «التحميل عند ظهور التبويب» مكرر
- **المواقع:**
  - `home_lifecycle_bridge.dart:51-79`.
  - `order_history_screen.dart:44-74`.
  - `wallet_screen.dart:47-61`.
- **الأثر:** ثلاث نسخ لمنطق `TickerMode` و`AppLifecycleListener` بفروقات طفيفة: المحفظة لا تعيد التحميل عند الاستئناف.
- **التصحيح:** ودجت مشتركة `BranchVisibilityLoader({onFirstShow, onReshow, onResumeWhileVisible})` في `view/navigation/`. السلوك الحالي يبقى كما هو، ويبقى قرار المحفظة (STATE-02) صريحاً.
- **التحقق:** `home_tab_reentry_test` و`wallet_test` و`new_offer_sheet_test` (تحديث السجل).

### ARCH-06 — منخفضة — تصنيف المهلة غير متسق بين حالات الاستخدام
- **الحالات التي تحوّل `TimeoutException` إلى «خدمة غير متاحة»:** `get_active_order.dart:71` و`check_auth_status.dart:71` و`captain_availability.dart:57`.
- **الحالات التي تحوّلها إلى فشل عام:** `get_wallet.dart:89` و`order_offers.dart:86/107` و`get_declined_offers.dart:67` و`captain_account.dart:55/126`. ونتيجة القبول عند المهلة هي `Unconfirmed`، وهذا مقصود.
- **التصحيح:** اعتماد سياسة واحدة موثقة لكل نوع قراءة.

### ARCH-07 — متوسطة (حاجبة للتكامل) — لا طبقة بيانات حقيقية
- **الموقع:** `lib/data/`: نموذج واحد `AppUserModel` بلا `fromJson`، وثمانية مستودعات placeholder.
- **الناقص:**
  - لا عميل HTTP ولا DTO ولا mappers.
  - لا تخزين آمن للرمز (D-P03).
  - لا `get_it` (D-A64).
- **الأثر:** لا شاشة تصل إلى `END_TO_END_VERIFIED`.
- **التصحيح:** بعد كتابة OpenAPI: عملاء مولّدون، ثم DTO ومحوّلات لكل كيان في §7، ثم تسجيلات `get_it`.

### ARCH-08 / LOC-01 — متوسطة — صفحة خطأ إنجليزية افتراضية للمسارات غير المعروفة
- **الموقع:** `lib/util/routes/go_router.dart:106` (`GoRouter(...)` بلا `errorBuilder`).
- **السيناريو:** مستخدم مسجّل يفتح رابطاً غير معروف، مثل المسار المحذوف `/notifications`. `resolveRedirect` يعيد `null` للمسارات غير العامة، فيعرض go_router صفحته الافتراضية بالإنجليزية.
- **مستوى الدليل:** مؤكد من المصدر، ولم يُعَد إنتاجه تفاعلياً في هذا التشغيل. الاختبار `main_navigation_test` يتحقق فقط من غياب تطابق `/notifications`.
- **التصحيح:** `errorBuilder` يعرض `AppStatusMessage` مع مفتاح ARB جديد (`routeNotFoundTitle`) وزر العودة للرئيسية، أو `redirect` للمسارات غير المعروفة إلى `/home`.
- **التحقق:** اختبار ودجت لـ `/notifications` و`/unknown`.

## 5. خطة الاستخراج المقترحة

| المعرّف | من | إلى | تغيّر البيانات / المنشئات | فحوص الانحدار |
|---|---|---|---|---|
| ARCH-04 | `openCurrentOrderPage` في `new_offer_sheet_host.dart` | `view/navigation/current_order_navigation.dart` | لا تغيير في التوقيع | اختبارات الاستعادة والنافذة |
| ARCH-05 | منطق الظهور في 3 شاشات | `view/navigation/branch_visibility_loader.dart` | callbacks بدل `State` مكرر | `home_tab_reentry_test`، `wallet_test` |
| SW-01 | صناديق `DecoratedBox` المكررة | `view/widget/surface/app_surface_card.dart` (`child`, `padding`) | لا تغيّر في البيانات | اختبارات الشاشات المعنية واختبار ذهبي اختياري |
| SW-02 | التفاف `closesPopup:false + pop(true)` | `AppPopupAction<T>` مع `result` و`showAppPopup<T>` يعيد القيمة | المستدعيان: الملف الشخصي وتأكيد الحذف | `profile_settings_test`، `custom_widgets_test` |
| ARCH-01 | `util/routes/go_router.dart`، `route_guard.dart` | `view/navigation/routing/` | استيرادات فقط | الاختبارات كلها |

## 6. استخدام المكونات المشتركة (SW)

| المكوّن | المستهلكون الإنتاجيون | التقييم |
|---|---|---|
| `AppButton` | الدخول، `AppPopup`، `AppStatusMessage`، معاينة debug، البطاقة، النافذة | مستخدم صحيحاً |
| `AppTextButton` | 14 ملفاً | مستخدم صحيحاً |
| `AppTextFormField` | `login_form.dart` | مستخدم صحيحاً |
| `showAppPopup`/`AppPopup` | 7 ملفات | صحيح؛ فجوة API في إرجاع قيمة (SW-02) |
| `showAppToast` | الدخول، tools | صحيح |
| `AppStatusMessage` | Current Order (6 حالات)، عرض الاستلام | صحيح |
| `AppAvailabilityToggle` | `HomeAvailabilityBar` | صحيح |
| `AppOrderOfferCard` | `PendingOffersSliver`، معاينة الرئيسية | صحيح؛ نسخة واحدة؛ المعاينة تستخدم البطاقة الحقيقية |
| `MainNavigationBar` | `AppNavBar` | عرض فقط؛ بلا مدخلات مؤشرات (D-A70) |
| `openTermsPage` | `LoginTermsAction`، `ProfileScreen` | مشترك صحيحاً |
| عائلة `AppTextWidget` (12 ملفاً) | **لا شيء** | SW-04 |
| `CustomePadding` | `AndroidLoading` (ميت) | SW-04 |

- **SW-01 — منخفضة:** «بطاقة بيضاء بإطار `AppColor.divider` وزوايا 16» مكررة يدوياً في 10 ودجات:
  - `app_order_offer_card.dart:101`، `wallet_balance_card.dart:37`، `wallet_debit_card.dart:71`، `wallet_metric_cards.dart:140`.
  - `profile_identity_card.dart:32`، `profile_rating_card.dart:57`، `declined_offer_tile.dart:39`.
  - `active_order_pickup_view.dart:132`، `wallet_balance_chip.dart:59` (زوايا 20)، `home_active_order_card.dart:67` (حاوية حمراء).
  - **المقترح:** `AppSurfaceCard` مشتركة.
- **SW-02 — منخفضة:** `AppPopupAction` لا يدعم قيمة إرجاع. لذلك `profile_screen.dart:79-83` و`account_deletion_confirmation.dart:26-31` يستخدمان `closesPopup:false` مع `Navigator.pop(true)` من الملاح الجذري، وهذا يعتمد على تفاصيل `showDialog`.
- **SW-03 — منخفضة:** `no_internet_screen.dart:62-76` و`splash_startup_status.dart:66-69` يبنيان `FilledButton` مع مؤشر يدوي بدل `AppButton(isLoading:)`. الشكل متقارب بفضل السمة، لكن الحد الأدنى للحجم وبنية الدلالات والتحميل تختلف.
- **SW-04 — منخفضة:**
  - عائلة النصوص `lib/view/widget/text/*` (12 ملفاً) بلا مستهلك إنتاجي. قرار الإبقاء أو الإزالة مفتوح لدى المالك وفق `PROJECT_STATUS`.
  - `WalletBalanceChip.naturalWidth` و`_singleLineWidth` (`wallet_balance_chip.dart:43-51، 113-122`) بلا مستدعٍ بعد إعادة بناء شريط الرئيسية.
  - `CustomePadding` يكرر `Padding` باتجاه `left/right` فيزيائي.
- **تركيبات مبررة لا تُعد مخالفة:** `_MenuTile` في الملف الشخصي، و`_PickupCard` و`_LocationStatus`، و`_EntryLine`، و`_MetricCard` (مساعدات خاصة صغيرة)، والفاصل اليدوي في الدخول (`login_screen.dart:134`).

## 7. ملّاك الحالة (Bloc/Cubit مقابل غيرها)

**العدّ:** 21 صنف `StatefulWidget` أو `ChangeNotifier` في الشيفرة المؤلَّفة: 13 إنتاجية، و4 تجريبية، و3 معاينة، و`StreamRefreshListenable`.

**مخالفات حالة الأعمال: 0.**

| المالك | المسار | ما يخزنه | التصنيف |
|---|---|---|---|
| `MainApp` | `main.dart` | Cubits التطبيق، الراوتر، `AppLifecycleListener`، اشتراك الجلسة | جذر تركيب ودورة حياة — مبرر |
| `StreamRefreshListenable` | `util/routes/stream_refresh_listenable.dart` | اشتراكات تيارات لإعادة التوجيه | حالة إطار عمل — مبرر |
| `NewOfferSheetHost` | `view/navigation/new_offer_sheet_host.dart` | معرّفات العروض المرئية/المنتظرة، المسار المفتوح، علم المعالجة | تقديم وملاحة؛ بيانات العروض في `PendingOffersCubit` — مبرر |
| `LoginForm` | `authentication/widget/login_form.dart` | متحكمات النص و`FocusNode` | محلي — مبرر |
| `LoginTermsAction` | `authentication/widget/login_terms_action.dart` | علم `_opening` | محلي — مبرر |
| `CurrentOrderScreen` | `current_order_screen/view/` | تحميل أولي فقط | محلي — مبرر |
| `HomeLifecycleBridge` | `home_screen/widget/` | `_wasActive` ومستمع الاستئناف | تأثيرات دورة الحياة — مبرر (ARCH-05) |
| `OrderHistoryScreen` | `order_history_screen/view/` | `_wasActive` ومستمع | كذلك (ARCH-05) |
| `WalletScreen` | `wallet_screen/view/` | `_wasActive` | كذلك (ARCH-05) |
| `ProfileScreen` | `profile_screen/view/` | `_openingTerms` | محلي — مبرر |
| `AppTextFormField` | `widget/text_field/` | `_obscured` (`setState`) | محلي — مبرر |
| `DemoApp`، `DemoShellBridge`، `DemoStrip`، `DemoState` | `lib/demo/` | حالة عرض في الذاكرة و`setState` لإظهار الأدوات | تجريبي فقط، ببوابة debug مع العلم، وقابل للإزالة |
| المعاينات الثلاث | `lib/preview/` | Cubits معاينة ببيانات تخيلية | معاينة فقط، لا يستوردها التطبيق (مختبر) |

**Cubits الإنتاجية (14):**
- `AppConnectivityCubit`، `AppSessionCubit`، `SplashCubit`، `LoginCubit`.
- `CurrentOrderCubit`، `HomeAvailabilityCubit`، `PendingOffersCubit`، `DeclinedOffersCubit`.
- `WalletCubit`، `ProfileRatingCubit`، `AccountDeletionCubit`.

إضافة إلى `SplashBloc` الميت. كلها:
- تميّز حالات التحميل والنجاح والفراغ والفشل و«غير مُعدّ».
- تُسقط الإجابات المتأخرة بعدّاد جيل وفحص `isClosed` والجلسة.
- لا تستدعي API أو تخزيناً مباشرة.

الاستعادة يقودها مالك واحد (`CurrentOrderCubit` بقراءات مدمجة)، والملاحة من مكانين محددين: `MainApp` عند الاستئناف، والمضيف عند القبول. ولا يوجد `NavBarCubit`.

- **STATE-01 — منخفضة:** `ProfileRatingCubit` يُحمَّل مرة واحدة فقط (`profile_screen.dart:52-57`)، بلا إعادة عند ظهور التبويب أو الاستئناف، بخلاف الرئيسية وطلباتي والمحفظة. التقييم قد يبقى قديماً طوال الجلسة. **المقترح:** ربطه بـ `BranchVisibilityLoader` (ARCH-05).
- **STATE-02 — منخفضة/معلومة:** `WalletScreen` لا يعيد التحميل عند الاستئناف، وهذا قرار مفتوح موثق في `ROUTING_AND_STARTUP.md` §7. القيمة قد تتأخر عن الخادم حتى يُبدَّل التبويب.

## 8. جرد الشاشات

### 8.1 الشاشات الإنتاجية الموجودة

| ID | الاسم | الصنف/الملف | المسار | قابلية الوصول | واجهة | حالة/تفاعل | جاهزية العقد | تكامل حي | دليل التحقق | الفئة |
|---|---|---|---|---|---|---|---|---|---|---|
| S01 | الإقلاع | `SplashScreen` | `/` | متاح | مكتمل | مكتمل | عقد Auth موجود | لا (placeholder دائماً غير مسجل) | `splash_cubit_test`، `startup_flow_test` | UI_READY_INTEGRATION_PENDING |
| S02 | لا يوجد إنترنت | `NoInternetScreen` | `/no-internet` | متاح | مكتمل | مكتمل | مزوّد منصة حقيقي (`internet_connection_checker_plus`) | موصول، لم يُتحقق منه وقت التشغيل في هذا التشغيل | `connectivity_test` (خدمة مزيفة) | UI_READY_INTEGRATION_PENDING |
| S03 | تسجيل الدخول | `LoginScreen` | `/login` | متاح | مكتمل | مكتمل | `AuthRepository.signIn` | لا؛ رابط الشروط فارغ | `login_screen_test`، `login_cubit_test` | UI_READY_INTEGRATION_PENDING |
| S04 | الرئيسية | `HomeScreen` | `/home` (تبويب 0) | متاح | مكتمل | مكتمل | توفر وعروض وطلب نشط | لا (3 placeholders) | `home_*_test`، `active_order_recovery_test` | UI_READY_INTEGRATION_PENDING |
| S05 | طلباتي | `OrderHistoryScreen` | `/order-history` (تبويب 1) | متاح | **جزئي**: قسم التوصيلات المكتملة يقول «قيد التطوير» | العروض المرفوضة فقط | `getDeclinedOffers` فقط | لا | `new_offer_sheet_test` | UI_OR_BEHAVIOR_PARTIAL |
| S06 | المحفظة | `WalletScreen` | `/wallet` (تبويب 2) | متاح | مكتمل | مكتمل؛ الأرباح «غير متوفر» دائماً (D-P36) | `getWallet`، `getDeliveryStatistics` | لا | `wallet_test` | UI_READY_INTEGRATION_PENDING |
| S07 | حسابي | `ProfileScreen` | `/profile` (تبويب 3) | متاح | مكتمل | مكتمل (الخروج يعمل محلياً) | `getRating` | لا | `profile_settings_test` | UI_READY_INTEGRATION_PENDING |
| S08 | الطلب الحالي | `CurrentOrderScreen` | `/current-order` (صفحة فوق الصدفة) | متاح بعد القبول أو الاستعادة أو من بطاقة الرئيسية | **جزئي**: لا خريطة ولا PIN ولا «بدء التوصيل» ولا تسليم ولا تنقل خارجي | الحالات مكتملة | `ActiveOrder` بلا status/مراحل (API-01) | لا | `current_order_test`، `active_order_recovery_test` | UI_OR_BEHAVIOR_PARTIAL |
| S09 | الإعدادات | `SettingsScreen` | `/settings` | من حسابي | مكتمل | مكتمل | `requestAccountDeletion` | لا (D-P39) | `profile_settings_test` | UI_READY_INTEGRATION_PENDING |
| S10 | حول التطبيق | `AboutScreen` | `/about` | من حسابي | مكتمل | ثابت | مصدر رقم الإصدار غير موجود | لا | `profile_settings_test` | UI_READY_INTEGRATION_PENDING |

**العدّ:**
- **إجمالي الشاشات الإنتاجية الموجودة: 10.**
- END_TO_END_VERIFIED **0**، UI_READY_INTEGRATION_PENDING **8**، UI_OR_BEHAVIOR_PARTIAL **2**، PLACEHOLDER **0**، NOT_ASSESSED **0**. المجموع 10.
- واجهة أو سلوك غير مكتمل **(2)**: طلباتي (S05)، الطلب الحالي (S08).
- واجهة مكتملة والتكامل معلّق **(8)**: الإقلاع، لا يوجد إنترنت، تسجيل الدخول، الرئيسية، المحفظة، حسابي، الإعدادات، حول التطبيق.

**شاشات خارج العدّ:** المعاينات الثلاث (`HomeOffersPreviewApp`، `NewOfferSheetPreviewApp`، `WalletPreviewApp`) للمعاينة فقط، و`DemoApp` تجريبية.

### 8.2 الشاشات المعتمدة وغير الموجودة

| ID | الاسم | المرجع | ملاحظة |
|---|---|---|---|
| M01 | الالتزامات المجدولة المستقبلية | `PRODUCT_OVERVIEW.md` §3.1 و§3.4، D-A44، D-A47، D-A61 (تُعرض منفصلة عن التوصيل النشط) | لا واجهة ولا عقد؛ نموذج القراءة مطلوب تحديده (D-P25) |

**المعتمد المفقود: 1.** لا يُعد قسم «التوصيلات المكتملة» شاشة منفصلة، فهو داخل S05. كذلك خطوات PIN والتسليم داخل S08. والميزات المحذوفة (الإشعارات، الشحن، الحجز) لا تُحسب.

**إجمالي الشاشات المعلّقة = 10 موجودة غير مكتملة + 1 مفقودة = 11** (اتحاد لا جمع أعمدة متداخلة).

### 8.3 ما تحتاجه كل شاشة

| ID | المطلوب | فحص الإكمال |
|---|---|---|
| S01/S03 | مستودع Auth حقيقي، تخزين آمن، تجديد الرمز، رابط الشروط | دخول حقيقي ← الرئيسية ← إعادة تشغيل التطبيق تستعيد الجلسة |
| S02 | تحقق تشغيلي على جهاز أو محاكٍ فعلي | قطع الشبكة يُظهر الشاشة وإعادة المحاولة تعيد التدفق |
| S04 | محوّلات التوفر والأذونات والعروض والطلب النشط، والدفع | توفر مؤكد من الخادم، ووصول عرض حقيقي، وقبوله |
| S05 | قراءة التوصيلات المكتملة (مقبول ومحدد الترقيم) + `getDeclinedOffers` حقيقي | قائمتان من الخادم مع ترقيم |
| S06 | قراءة الرصيد والخصومات والإحصائيات + D-P36 | رصيد حقيقي ≤/>5000 معروض بلا قص، وعدّ مدى الحياة |
| S07 | قراءة التقييم + D-P37 | قيمة حقيقية بالمقياس المعلَن |
| S08 | `PickupMapBuilder` (Google Maps)، أوامر PIN و`startDelivery` و`complete`، status | دورة طلب كاملة على جهاز |
| S09 | عقد الحذف (D-P39) | حذف معلّق أو مكتمل حقيقي على حساب اختبار |
| S10 | مصدر الإصدار (حزمة معتمدة) | رقم إصدار مطابق للبناء |
| M01 | نموذج القراءة والوجهة | قائمة التزامات منفصلة عن الطلب النشط |

### 8.4 الأسطح الثانوية

| السطح | الملف | الحالة |
|---|---|---|
| نافذة عرض جديد | `new_order_offer_sheet.dart` + المضيف | UI_READY_INTEGRATION_PENDING |
| شرح أذونات التوفر | `home_availability_rationale_listener.dart` | UI جاهز؛ محوّل الأذونات غير موجود |
| «تم القبول لكن تعذّر الفتح» | `new_offer_sheet_host.dart` | جاهز |
| نسيت كلمة المرور / إنشاء حساب | `forgot_password_popup.dart`، `create_account_popup.dart` | محتوى ثابت مكتمل |
| الشروط (صفحة داخلية أو نافذة) | `terms_page_opener.dart` | الرابط فارغ؛ النافذة صادقة |
| تأكيد الخروج | `profile_screen.dart` | يعمل محلياً؛ إلغاء الجلسة على الخادم غير موجود |
| تأكيد الحذف | `account_deletion_confirmation.dart` | UI جاهز |
| توست أخطاء الدخول | `login_screen.dart` | جاهز |
| شريط عدم الاتصال العام | `global_connectivity_banner.dart` | مزوّد منصة حي |
| زر معاينة debug | `debug_preview_button.dart` | debug فقط، مؤقت |
| شريط العرض التجريبي | `lib/demo/widget/demo_strip.dart` | تجريبي فقط |

## 9. جاهزية البيانات لكل عنصر (API)

كل العناصر الديناميكية في الإنتاج تتبع المسار: ودجت ← Cubit ← حالة استخدام ← عقد مستودع ← placeholder يرمي «غير مُعدّ».

| الشاشة/العنصر | المصدر (path:line) | النوع | التصنيف |
|---|---|---|---|
| S04 التحية | `home_greeting.dart:20` ← `AppSessionCubit` ← `AppUser.displayName` | `String?` | CONTRACT_READY_ADAPTER_MISSING |
| S04 الرصيد | `HomeScreen.walletBalanceFils` (`go_router.dart:243` يمرر null إنتاجياً؛ القيمة في العرض التجريبي فقط) | `int?` | PARTIAL_CONTRACT: لا مصدر إنتاجي يغذي الشريحة؛ `WalletCubit` في فرع آخر |
| S04 مفتاح التوفر | `home_availability_bar.dart:43` ← `HomeAvailabilityCubit` ← `CaptainAvailabilityRepository` | enum | CONTRACT_READY_ADAPTER_MISSING |
| S04 متطلبات الأذونات | `AvailabilityPermissionGateway` | Map | CONTRACT_READY_ADAPTER_MISSING (لا `permission_handler` موصول) |
| S04/النافذة: التاجر، الاستلام، المنطقة، الأجرة، النوع، الموعد، لقطة العمولة | `CaptainOrderOffer` ← `OrderOfferRepository.getEligibleOffers` | انظر 03 | CONTRACT_READY_ADAPTER_MISSING؛ لا انتهاء صلاحية (API-02) |
| أوامر القبول والرفض | `PendingOffersCubit.accept/decline` ← `acceptOffer(offerId)` | void | PARTIAL_CONTRACT: لا مفتاح idempotency (API-02) |
| S04 بطاقة الطلب النشط / S08 | `CurrentOrderCubit` ← `ActiveOrderRepository.getActiveOrder` | `ActiveOrder?` | PARTIAL_CONTRACT (API-01) |
| S08 موقع الكابتن | `CaptainLocationRepository` | GeoPoint | CONTRACT_READY_ADAPTER_MISSING |
| S08 الخريطة | `PickupMapBuilder` = null في الإنتاج | ودجت | CONTRACT_READY_ADAPTER_MISSING |
| S05 العروض المرفوضة | `DeclinedOffersCubit` ← `getDeclinedOffers` | List | PARTIAL_CONTRACT (API-07) |
| S05 التوصيلات المكتملة | لا يوجد | — | غير محدد (عقد مفقود) |
| S06 الرصيد والخصومات | `WalletCubit` ← `getWallet` | int / List | CONTRACT_READY_ADAPTER_MISSING |
| S06 العدّ والأرباح | `getDeliveryStatistics` | int / int? | العدّ CONTRACT_READY_ADAPTER_MISSING؛ الأرباح غير محددة (D-P36) |
| S07 الاسم والهاتف | `AppSessionCubit` | `String?` | CONTRACT_READY_ADAPTER_MISSING |
| S07 التقييم | `ProfileRatingCubit` ← `getRating` | `CaptainRating` | PARTIAL: المقياس غير محدد (D-P37) |
| S09 نتيجة الحذف | `AccountDeletionCubit` ← `requestAccountDeletion` | enum | CONTRACT_READY_ADAPTER_MISSING (D-P39) |
| S10 الإصدار | لا مصدر | — | غير محدد |
| حالة الاتصال | `InternetConnectionCheckerPlusService` | enum | LIVE_CONNECTED (مزوّد منصة؛ لم يُتحقق منه وقت التشغيل هنا) |
| تنسيق المال والتاريخ | `formatJodFils`، `formatLocalDateTime` | String | DERIVED_OR_PLATFORM_VALUE |
| بيانات المعاينة والعرض التجريبي | `lib/preview/*`، `assets/demo/*` | — | DEMO_OR_PREVIEW_ONLY؛ لا استيراد إنتاجي (مختبر) |

**PRODUCTION_HARDCODED: 0.**

فجوات العقد:
- **API-01** — `ActiveOrder` (`domain/entities/active_order.dart:35-61`) بلا `status`. D-A68 يتطلب الحالات النشطة الأربع. وبلا PIN وأوامر المراحل (D-A67) ومنطقة التسليم ورقم هاتف العميل الذي يتصل به الكابتن قبل «بدء التوصيل» (`PRODUCT_OVERVIEW` §3.1).
- **API-02** — `CaptainOrderOffer` بلا `expiresAt` ولا جولة الإرسال (D-A60). و`acceptOffer`/`declineOffer` بلا `Idempotency-Key` (D-A56).
- **API-03** — `AppUser` بلا اسم المستخدم ولا حالة اكتمال الملف أو الأهلية (D-A65، D-P17) ولا حالة الحظر.
- **API-04** — لا عقد لرفع الموقع كل 30 ثانية (D-A57) ولا تسجيل رمز الدفع (D-A58/D-A72). هذا هدف معتمد غير منفذ.
- **API-05** — الشريحة في الرئيسية بلا مصدر إنتاجي. لا شيء يربط `WalletCubit` بالرئيسية خارج العرض التجريبي، رغم أن D-A71 يطلب «المصدر نفسه». **الإصلاح:** رفع قراءة الرصيد إلى نطاق الصدفة أو حالة مشتركة.
- **API-06** — صيغة الأرباح ومقياس التقييم مفتوحان (D-P36، D-P37).
- **API-07** — `DeclinedOfferRecord` بلا `orderId` ولا منطقة، ولا ترقيم صفحات.

## 10. الترجمة ومصادر النصوص

| الفحص | النتيجة |
|---|---|
| إعداد gen_l10n | صحيح؛ الملفات المولّدة غير معدّلة يدوياً |
| مفاتيح ARB | 214، كلها مستخدمة في `lib/`، وكلها لها `@` وصف |
| placeholders وجمع | `profileRatingCount` (ICU plural بنوع int)، `offersSectionTitleWithCount`، `homeGreeting`، `homeActiveOrderMessage` وغيرها لها metadata صحيحة |
| نص عربي ثابت في الإنتاج | **0** (الحرفيات العربية في `lib/preview/` فقط) |
| رسائل الاستثناءات الخام للمستخدم | لا توجد (`toString` يظهر في `DemoFixtureException` التجريبي فقط، ورسالته للمستخدم من ARB) |

المخالفات:
- **LOC-01 (= ARCH-08) — متوسطة:** صفحة خطأ go_router الإنجليزية. المفتاح المقترح: `routeNotFoundTitle` و`routeNotFoundMessage`.
- **LOC-02 — منخفضة:** تركيب «تسمية: قيمة» بفاصل `': '` ثابت في الكود بدل نمط ICU:
  - `app_order_offer_card.dart:155، 163`.
  - `new_order_offer_sheet.dart:135، 141، 149-150`.
  - `wallet_debit_card.dart:34، 40، 45، 51`.
  - `wallet_balance_card.dart:35` (دلالي).
  - `profile_identity_card.dart:58، 74` (دلالي).
  - **المقترح:** مفتاح عام `labeledValue` («{label}: {value}») أو مفاتيح لكل حقل مثل `offerPickupLine` («موقع المطعم: {pickup}»).
- **LOC-03 — منخفضة:** فواصل ورموز حرفية في نصوص مرئية أو دلالية:
  - `'• '` في `home_availability_notice.dart:92`.
  - `' · '` في `declined_offer_tile.dart:70`.
  - `.join('. ')` في `wallet_metric_cards.dart:138` و`profile_rating_card.dart:55`.
  - دمج نصّين بمسافة في `active_order_pickup_view.dart:212`.
  - **المقترح:** `bulletItem`، و`declinedOfferOutcomeWithKind`، ومفاتيح دلالية مركّبة.
- **LOC-05 — متوسطة (إصدار):** اسم التطبيق الظاهر للمستخدم ما زال قالباً، والمعتمد «شهم» (D-A66، D-P23):
  - `ios/Runner/Info.plist:9-10`: `CFBundleDisplayName = "Mobile Frontend"`.
  - `android/app/src/main/AndroidManifest.xml:3`: `android:label="mobile_frontend"`.
- **ليست مخالفات:** نص التاريخ `yyyy/MM/dd HH:mm` بأرقام غربية مُشتق عمداً (`date_time_format.dart`). عزل LTR للأرقام والهاتف مقصود. أسماء التجار والمناطق بيانات خادم.

## 11. المنصة والتبعيات

- **PLAT-01 — متوسطة:**
  - تسع تبعيات بلا أي استيراد في `lib/` أو `test/`: `dropdown_search`، `flutter_localization`، `google_api_headers`، `geocoding`، `google_maps_flutter`، `http`، `location`، `permission_handler`، `toasty_box`. وتبعية `bloc` تخدم `SplashBloc` الميت وحده.
  - بعضها معتمد لميزات مستقبلية (الخرائط والموقع والأذونات، D-A57/D-A62). وD-A64 يشترط تدقيقاً قبل الإزالة.
  - لا إذن `INTERNET` في `android/app/src/main/AndroidManifest.xml`.
  - لا نصوص غرض للموقع في `Info.plist` رغم ربط إضافات الموقع.
  - معرّف الحزمة قالب: `com.example.mobile_frontend` (`android/app/build.gradle*:8، 19`).
  - كل هذا مسجل أيضاً في `docs/release/STORE_SUBMISSION_COMPLIANCE.md`.

## 12. الاختبارات والتحقق

| الأمر | الوقت (UTC) | النتيجة |
|---|---|---|
| `flutter analyze --no-pub` | 2026-11-22T11:11:10Z | 1 issue (info) — `splash_bloc.dart:2` `depend_on_referenced_packages`، خط الأساس نفسه (ARCH-03) |
| `flutter test --no-pub` | 2026-11-22T11:11Z | **1001 نجح، 0 فشل** (32 ملفاً) |
| مقارنة الشجرة بعد التشغيل | — | `git status --porcelain` = 0؛ لم يتغير مصدر التطبيق. التقارير مكتوبة خارج المستودع فقط |

- **TEST-01 — منخفضة/معلومة:** كل الاختبارات تستخدم أكواداً مزيفة أو placeholders، لعدم وجود محوّل حقيقي. لا اختبار عقد ولا اختبار تكامل (`integration_test/` غير موجود).
- لم يُشغَّل محاكٍ في هذا التشغيل. أي ادعاء تشغيلي هنا مبني على المصدر والاختبارات فقط.

## 13. قائمة الإصلاح المرتبة (مقترحة، غير منفذة)

1. **ARCH-08/LOC-01:** `errorBuilder` معرَّب أو redirect للمسارات غير المعروفة، مع اختبار.
2. **API-05:** مصدر إنتاجي واحد للرصيد يغذي الرئيسية والمحفظة (رفع القراءة إلى نطاق الصدفة).
3. **ARCH-02 + ARCH-03 + SW-04 + PLAT-01 (جزء الشيفرة):** تنظيف الشيفرة الميتة (`tools`، `SplashBloc`، `naturalWidth`، `CustomePadding`) ثم تدقيق التبعيات وإزالة غير المعتمدة. يُنفذ بعد قرار المالك في عائلة النصوص.
4. **SW-02:** دعم إرجاع قيمة في `AppPopupAction` وتبسيط المستدعيين.
5. **LOC-02/LOC-03:** مفاتيح ICU للنصوص المركبة.
6. **ARCH-05 + STATE-01 (+ قرار STATE-02):** `BranchVisibilityLoader` مشترك وإعادة تحميل التقييم.
7. **SW-01 / SW-03:** `AppSurfaceCard` واستخدام `AppButton` في شاشتي الإقلاع وعدم الاتصال.
8. **ARCH-01 / ARCH-04 / ARCH-06:** نقل ملفات التوجيه، وموضع مساعد الملاحة، وسياسة المهلة.
9. **ARCH-07 + API-01..04/07:** بعد OpenAPI: طبقة بيانات حقيقية، و`get_it`، وحقول الطلب النشط والعروض.
10. **LOC-05 + PLAT-01 (المنصة):** مهمة إصدار وفق قائمة الامتثال.

## 14. مقارنة التشغيلات

لا يوجد تشغيل سابق مكتمل تحت `/Users/yousef_hamdan/Documents/Codex/SHAHM_AUDITS`، فهذا التشغيل هو خط الأساس للمقارنة اللاحقة. البصمة المرجعية: HEAD `cefad0a`، شجرة نظيفة، 340 ملفاً متتبعاً، 170 ملف Dart تشغيلياً.
