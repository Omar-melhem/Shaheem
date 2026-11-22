# 03 — متطلبات بيانات النظام (مدخل لتصميم قاعدة البيانات)

## 0. النطاق ومفتاح الأدلة

- **التشغيل:** `20261122T110746Z-cefad0a` — UTC ‏2026-11-22 11:07:46، عمّان 14:07:46 (+03).
- **المصدر المفحوص:** `mobile_frontend/` على HEAD `cefad0a`، بشجرة نظيفة.
- **حالة الواجهة الخلفية:** لا توجد واجهة خلفية ولا OpenAPI (`backend/` فارغ). كل أسماء نقاط النهاية وأسماء الأسلاك (wire names) هنا **مقترحة** ما لم يُذكر رمز Dart موجود.
- **المرجعية:**
  - القرارات المعتمدة D-A53 إلى D-A79 في `docs/decisions/ARCHITECTURAL_DECISIONS.md` (§1.1 و§1.2).
  - `docs/project/PRODUCT_OVERVIEW.md` §3.
  - القرارات المفتوحة D-P25 وD-P35 إلى D-P41 مذكورة كأسئلة، ولم يُقرَّر فيها هنا.
- **هذا مدخل للنقاش لا مخطط نهائي:** نماذج الواجهة ليست جداول، وقابلية القيمة للفراغ في Dart (nullable) لا تعني عموداً اختيارياً معتمداً.

**مفتاح حالة العقد:**
- `domain-only`: حقل موجود في كيان Dart ومستودع، ومحوّله الإنتاجي placeholder.
- `approved-unimplemented`: مطلوب بقرار معتمد، ولا يوجد رمز له.
- `proposed`: اقتراح هذا التقرير.
- `unresolved`: ينتظر قرار المالك.

لا يوجد حقل بحالة `implemented-live`.

**مفتاح التخزين:**
- `P`: حقيقة مخزنة موثوقة.
- `C`: إعداد.
- `S`: لقطة غير قابلة للتغيير.
- `A`: تجميع أو عرض محسوب.
- `E`: بيانات نقل أو حدث.
- `L`: حالة واجهة محلية مؤقتة.
- `K`: سر أو جلسة.

## 1. خريطة الميزات والعمليات

| الميزة | القراءات | الأوامر | الترشيح/الترتيب/الترقيم | الأحداث/الإبطال |
|---|---|---|---|---|
| المصادقة والجلسة (D-A53، D-A65) | فحص الجلسة (`validateSession`)، المستخدم الحالي (`getCurrentUser`) | تسجيل الدخول، تجديد الرمز (معتمد)، تسجيل الخروج وإلغاء الجلسة (معتمد) | — | الحظر يلغي الجلسة فوراً؛ جلسة جهاز واحد |
| الملف والتقييم (D-A77) | `getRating` | — | — | إعادة القراءة عند فتح التبويب |
| التوفر والأذونات والموقع (D-A57) | `getAvailability` | `setAvailability`، رفع الموقع كل 30 ث (معتمد، غير منفذ) | — | انتهاء صلاحية الموقع بعد 90 ث يستبعد الكابتن من العروض |
| العروض (D-A45، D-A46، D-A60) | `getEligibleOffers` (العروض القابلة للتنفيذ لهذا الكابتن فقط) | `acceptOffer`، `declineOffer` | ترتيب حسب الخادم | دفع FCM/APNs وSignalR تلميحٌ لإعادة القراءة فقط (D-A72) |
| الطلب النشط والاستعادة (D-A68، D-A73) | `getActiveOrder` (واحد أو لا شيء) | التحقق من PIN، بدء التوصيل، الإكمال (معتمد D-A67، غير منفذ) | — | عند القبول وبدء التشغيل والعودة للمقدمة |
| السجل (D-A70) | `getDeclinedOffers` (موجود)، التوصيلات المكتملة (غير محدد) | — | ترقيم (مقترح) | بعد رفض مؤكد |
| المحفظة (D-A74، D-A75، D-A76) | الرصيد والخصومات ضمن نافذة 7 أيام (`getWallet`)، الإحصائيات مدى الحياة (`getDeliveryStatistics`) | لا أوامر في تطبيق الكابتن (الشحن عبر الأدمن خارج التطبيق) | `historySinceUtc` | بعد التسليم المؤكد |
| القانوني والإعداد (D-A39، D-A77) | رابط الشروط (`LegalLinks`، ثابت محلي فارغ)، سياسة الخصوصية (مفقودة) | — | — | — |
| حذف الحساب (D-A78) | — | `requestAccountDeletion` | — | المكتمل ينهي الجلسة |
| الالتزامات المجدولة (D-A47، D-A61) | قراءة مستقبلية (غير محددة، D-P25) | تعيين الأدمن (خارج التطبيق) | حسب الموعد | تحذير الأدمن قبل ساعة؛ إيقاف العروض قبل ~30 د |

## 2. قاموس الحقول الذرية

### 2.1 الجدول (أ): الهوية والنوع والاتجاه

| ID | المجموعة | المعنى (عربي) | الرمز في الكود / الاسم المقترح | الاتجاه | النوع والوحدة | قابلية الفراغ: العميل / العمل |
|---|---|---|---|---|---|---|
| DATA-AUTH-01 | Auth | اسم المستخدم المُدخَل | `SignIn(username:)` | صادر | String، 4–30 من `[A-Za-z0-9_.]` أو هاتف من 10 أرقام | غير فارغ / مطلوب |
| DATA-AUTH-02 | Auth | كلمة المرور | `SignIn(password:)` | صادر | String 8–128 (وحدة العد مفتوحة: runes مقابل UTF-16) | غير فارغ / مطلوب |
| DATA-AUTH-03 | Auth | رمز الوصول JWT | مقترح `accessToken` | وارد | String، صلاحية 15 د | — / مطلوب للجلسة |
| DATA-AUTH-04 | Auth | رمز التجديد | مقترح `refreshToken` | وارد | String مدوّر، 90 يوماً من عدم النشاط | — / مطلوب |
| DATA-AUTH-05 | Auth | معرّف جلسة الجهاز | مقترح `deviceSessionId` | وارد | UUID | — / مطلوب (جلسة واحدة) |
| DATA-AUTH-06 | Auth | نتيجة الدخول المصنفة | `SignInResult` (نجاح، بيانات خاطئة، محظور، لا إنترنت، خدمة غير متاحة، فشل الملف، غير مُعدّ، فشل) | وارد | enum / أكواد Problem Details | — / مطلوب |
| DATA-USER-01 | User | معرّف المستخدم | `AppUser.id` | وارد | String غير فارغ | مطلوب / مطلوب |
| DATA-USER-02 | User | الاسم الظاهر | `AppUser.displayName` | وارد | String | nullable / unresolved |
| DATA-USER-03 | User | الهاتف (10 أرقام محلية) | `AppUser.phone` | وارد | String مطبّع | nullable / unresolved |
| DATA-USER-04 | User | الدور | `AppUser.role` | وارد | String ('captain') | nullable / مطلوب (Identity) |
| DATA-USER-05 | User | اكتمال الملف / الأهلية | مقترح `profileComplete` | وارد | bool | — / مطلوب (D-A65، D-P17) |
| DATA-USER-06 | User | حالة الحساب (نشط/محظور) | مقترح `accountStatus` | وارد | enum | — / مطلوب (D-A53) |
| DATA-USER-07 | User | اسم المستخدم المخزن | مقترح `username` | داخلي | String فريد غير حساس لحالة الأحرف | — / مطلوب |
| DATA-RATE-01 | Rating | عدد التقييمات | `CaptainRating.ratingsCount` | وارد | int ≥ 0 | مطلوب / unresolved |
| DATA-RATE-02 | Rating | متوسط التقييم | `CaptainRating.average` | وارد | double | nullable / unresolved (D-P37) |
| DATA-RATE-03 | Rating | أعلى المقياس | `CaptainRating.scaleMax` | وارد | double | nullable / unresolved (D-P37) |
| DATA-RATE-04 | Rating | تقييم مفرد (المصدر) | مقترح `orderRating.value`، `ratedBy`، `ratedAt` | داخلي | — | unresolved (لم يُعتمد من يقيّم) |
| DATA-AV-01 | Availability | التوفر المؤكد من الخادم | `CaptainAvailability` (available/unavailable) | ثنائي الاتجاه | enum | nullable (غير معروف) / مطلوب |
| DATA-AV-02 | Availability | حالة كل متطلب جهاز | `AvailabilityPrerequisites.statuses` | محلي (OS) | Map<enum, enum> | — / ليس حقل قاعدة بيانات |
| DATA-LOC-01 | Location | خط العرض | `GeoPoint.latitude` (+ مقترح للتقرير) | صادر | double ±90 | — / مطلوب للتقرير |
| DATA-LOC-02 | Location | خط الطول | `GeoPoint.longitude` | صادر | double ±180 | — / مطلوب |
| DATA-LOC-03 | Location | الدقة بالمتر | مقترح `accuracyM` | صادر | double ≤ 100 مقبول | — / مطلوب (D-A57) |
| DATA-LOC-04 | Location | وقت الالتقاط على الجهاز | مقترح `capturedAt` | صادر | UTC timestamp | — / مطلوب |
| DATA-LOC-05 | Location | وقت الاستلام في الخادم | مقترح `receivedAt` | داخلي | UTC (الحداثة 90 ث من ساعة الخادم) | — / مطلوب |
| DATA-OFF-01 | Offer | معرّف العرض | `CaptainOrderOffer.id` | وارد | String | مطلوب / مطلوب |
| DATA-OFF-02 | Offer | معرّف الطلب | `CaptainOrderOffer.orderId` | وارد | String | nullable / مطلوب للملاحة (D-A73) |
| DATA-OFF-03 | Offer | نوع العرض | `CaptainOrderOffer.kind` (instant/scheduled) | وارد | enum | افتراضي instant / مطلوب |
| DATA-OFF-04 | Offer | اسم التاجر | `merchantName` | وارد | String غير فارغ | مطلوب / مطلوب |
| DATA-OFF-05 | Offer | وصف موقع الاستلام | `pickupLabel` | وارد | String (منطقة أو عنوان التاجر) | nullable / unresolved |
| DATA-OFF-06 | Offer | منطقة التسليم | `deliveryAreaName` | وارد | String (منطقة، ليست نقطة) | مطلوب / مطلوب |
| DATA-OFF-07 | Offer | أجرة التوصيل الكاملة | `deliveryFeeFils` | وارد | int فلس ≥ 0، بزيادات 500 | مطلوب / مطلوب |
| DATA-OFF-08 | Offer | موعد الاستلام المجدول | `scheduledPickupAt` | وارد | timestamp (منطقة زمنية unresolved، يُعرض محلياً) | nullable / مطلوب للمجدول |
| DATA-OFF-09 | Offer | لقطة مبلغ العمولة | `OfferCommissionSnapshot.amountFils` | وارد | int فلس | nullable / مطلوب (يحجب القبول عند غيابه) |
| DATA-OFF-10 | Offer | لقطة نسبة العمولة | `OfferCommissionSnapshot.rateBasisPoints` | وارد | int نقطة أساس 0–10000 | nullable / مطلوب |
| DATA-OFF-11 | Offer | انتهاء صلاحية العرض | مقترح `expiresAt` | وارد | timestamp (60 ث للجولة أو دقيقتان للخاص) | — / مطلوب (D-A60) |
| DATA-OFF-12 | Offer | جولة الإرسال / خاص | مقترح `dispatchRound`، `isPrivate` | داخلي | int / bool | — / مطلوب للخادم |
| DATA-OFF-13 | Offer | صافي الكابتن (مشتق) | `CaptainOrderOffer.netEarningsFils` | مشتق | الأجرة − العمولة | — / لا يُعرض (Task 38)؛ ليس عموداً |
| DATA-CMD-01 | OfferDecision | أمر القبول | `acceptOffer(offerId)` | صادر | String | — / مطلوب |
| DATA-CMD-02 | OfferDecision | أمر الرفض | `declineOffer(offerId)` | صادر | String | — / مطلوب |
| DATA-CMD-03 | OfferDecision | مفتاح عدم التكرار | مقترح `Idempotency-Key` | صادر | UUID لكل محاولة | — / مطلوب (D-A56) |
| DATA-CMD-04 | OfferDecision | نتيجة الأمر | `OfferCommandResult` (مؤكد، لم يعد متاحاً، مرفوض، غير مُعدّ، غير مؤكد) | وارد | enum / أكواد | — / مطلوب |
| DATA-DEC-01 | Declined | معرّف العرض المرفوض | `DeclinedOfferRecord.offerId` | وارد | String | مطلوب / مطلوب |
| DATA-DEC-02 | Declined | وقت الرفض | `declinedAt` | وارد | timestamp | nullable / مطلوب |
| DATA-DEC-03 | Declined | اسم التاجر | `merchantName` | وارد | String | nullable / unresolved |
| DATA-DEC-04 | Declined | نوع العرض | `kind` | وارد | enum | nullable / unresolved |
| DATA-DEC-05 | Declined | الطلب والمنطقة | مقترح `orderId`، `deliveryAreaName` | وارد | String | — / proposed |
| DATA-ORD-01 | ActiveOrder | معرّف الطلب | `ActiveOrder.orderId` | وارد | String | مطلوب / مطلوب |
| DATA-ORD-02 | ActiveOrder | اسم المطعم/التاجر | `restaurantName` | وارد | String | مطلوب / مطلوب |
| DATA-ORD-03 | ActiveOrder | إحداثيات الاستلام | `pickupLocation.latitude/longitude` | وارد | double؛ (0,0) غير صالح، ضمن سياج الخدمة | nullable (الخريطة تتعطل) / مطلوب لإنشاء الطلب |
| DATA-ORD-04 | ActiveOrder | تعليمات الاستلام | `pickupInstructions` | وارد | String | nullable / اختياري |
| DATA-ORD-05 | ActiveOrder | حالة الطلب | مقترح `status` ∈ {accepted, heading_to_pickup, picked_up, on_the_way} | وارد | enum | — / مطلوب (D-A68) |
| DATA-ORD-06 | ActiveOrder | منطقة التسليم | مقترح `deliveryAreaName` | وارد | String | — / مطلوب |
| DATA-ORD-07 | ActiveOrder | هاتف العميل | مقترح `customerPhone` | وارد | String 10 أرقام | — / approved-unimplemented (§3.1: الكابتن يتصل قبل بدء التوصيل)؛ حساس |
| DATA-ORD-08 | ActiveOrder | الأجرة ولقطة العمولة | مقترح | وارد | فلس | — / مطلوب للخصم عند الإكمال |
| DATA-ORD-09 | Order | PIN الاستلام | مقترح `pickupPin` (خادم فقط، للتاجر) | داخلي/صادر للتحقق | 4 أرقام، استخدام واحد، 3 محاولات | — / مطلوب (D-A67)؛ لا يُعاد للكابتن |
| DATA-ORD-10 | Order | محاولات PIN | مقترح `pinFailedAttempts` | داخلي | int ≤ 3 | — / مطلوب |
| DATA-ORD-11 | Order | الحالة الكاملة | `pending_dispatch … dispatch_expired` (10 قيم، §3.1) | داخلي | enum | — / مطلوب |
| DATA-WAL-01 | Wallet | الرصيد الواحد | `WalletSummary.balanceFils` | وارد | int فلس، قد يكون سالباً أو > 5000 قديماً | مطلوب / مطلوب |
| DATA-WAL-02 | Debit | معرّف قيد الخصم | `WalletCommissionDebit.id` | وارد | String | مطلوب / مطلوب |
| DATA-WAL-03 | Debit | وقت الخصم | `debitedAt` | وارد | UTC timestamp | مطلوب / مطلوب |
| DATA-WAL-04 | Debit | مبلغ العمولة المخصوم | `commissionFils` | وارد | int فلس > 0 | مطلوب / مطلوب |
| DATA-WAL-05 | Debit | اسم التاجر | `merchantName` | وارد | String | nullable / unresolved |
| DATA-WAL-06 | Debit | منطقة التسليم | `deliveryAreaName` | وارد | String | nullable / unresolved |
| DATA-WAL-07 | Debit | الطلب المرتبط | `orderId` | وارد | String | nullable / مطلوب في الدفتر |
| DATA-WAL-08 | Query | بداية نافذة السجل | `getWallet(historySinceUtc:)` | صادر | UTC (الآن − 7 أيام، البداية شاملة) | مطلوب / عرض فقط |
| DATA-WAL-09 | Ledger | قيد شحن (رصيد دائن) | مقترح `credit.amountFils`، `creditedAt`، `verifiedBy` | داخلي/أدمن | فلس > 0 | — / مطلوب في الدفتر؛ لا يظهر للكابتن |
| DATA-WAL-10 | Ledger | معرّف الأثر المالي الفريد | مقترح `financialEffectKey` | داخلي | فريد لكل (طلب، نوع أثر) | — / مطلوب (D-A56، D-A74) |
| DATA-WAL-11 | Config | سقف الرصيد بعد الشحن | مقترح `walletBalanceCeilingFils` = 5000 | إعداد | int فلس | — / مطلوب (D-A75) |
| DATA-WAL-12 | Config | نسبة العمولة العامة | مقترح `commissionRateBasisPoints` = 2000 | إعداد | int | — / مطلوب (D-A59) |
| DATA-STAT-01 | Stats | عدد الطلبات المسلّمة مدى الحياة | `CaptainDeliveryStatistics.deliveredCount` | وارد | int ≥ 0 | مطلوب / مطلوب |
| DATA-STAT-02 | Stats | الأرباح مدى الحياة | `earningsFils` | وارد | int فلس | nullable / unresolved (D-P36) |
| DATA-DEL-01 | Deletion | أمر طلب الحذف | `requestAccountDeletion()` | صادر | — (+ مقترح `Idempotency-Key`) | — / مطلوب |
| DATA-DEL-02 | Deletion | حالة الطلب | `AccountDeletionStatus` (pending/completed) | وارد | enum | — / مطلوب |
| DATA-DEL-03 | Deletion | يتطلب إعادة مصادقة | `CaptainAccountReauthenticationRequiredException` | وارد | خطأ مصنف | — / مطلوب |
| DATA-DEL-04 | Deletion | سجل الطلب ومعرّفه وتوقيته | مقترح `deletionRequestId`، `requestedAt`، `completedAt` | داخلي | — | — / unresolved (D-P39) |
| DATA-CFG-01 | Legal | رابط الشروط | `LegalLinks.termsAndConditions` | محلي ثابت | HTTPS URL، فارغ حالياً | — / مطلوب للإصدار (D-P40) |
| DATA-CFG-02 | Legal | رابط سياسة الخصوصية | غير موجود | — | HTTPS URL | — / إلزامي للمتجر (P-01) |
| DATA-PUSH-01 | Push | رمز الجهاز | مقترح `pushToken`، `platform` | صادر | String | — / approved-unimplemented (D-A58/D-A72) |
| DATA-UI-01 | UI | الشاشة المختارة، القائمة المفتوحة، النافذة المنتظرة، متحكمات النص | Router / `NewOfferSheetHost` / `LoginForm` | محلي | — | ليس حقل قاعدة بيانات (L) |

### 2.2 الجدول (ب): القواعد والمصدر والتخزين والوصول

| ID | التحقق/الافتراضي | مصدر الحقيقة | المستهلكون (شاشة/عنصر ← path) | التخزين | حالة العقد | أثر قاعدة البيانات | الوصول | الخصوصية/الدورة |
|---|---|---|---|---|---|---|---|---|
| DATA-AUTH-01 | قص الأطراف، تحويل الأرقام العربية، فحص الطول والحروف | المستخدم ← Identity | S03 ← `login_cubit.dart:56` | — (المخزن هو DATA-USER-07) | domain-only | فهرس فريد غير حساس لحالة الأحرف | الكابتن يُدخل؛ الأدمن ينشئ | تعريفي |
| DATA-AUTH-02 | لا قص، لا تخزين في الحالة | المستخدم | `login_cubit.dart:29` | K (hash فقط) | domain-only | hash في Identity | — | سري؛ لا يُسجَّل |
| DATA-AUTH-03 | — | الخادم | لا مستهلك بعد | K، في الذاكرة فقط | approved-unimplemented | لا يُخزن | النظام | سري |
| DATA-AUTH-04 | تدوير، hash في الخادم | الخادم | — | K (`flutter_secure_storage`) | approved-unimplemented | جدول `refresh_tokens` (hash، انتهاء، جهاز) | النظام | سري؛ يُلغى عند الحظر/الحذف |
| DATA-AUTH-05 | جلسة واحدة | الخادم | — | P | approved-unimplemented | `device_sessions` (captain_id فريد نشط) | النظام | — |
| DATA-AUTH-06 | — | الخادم | `login_failure_message.dart` | E | domain-only | لا | — | — |
| DATA-USER-01 | غير فارغ (`app_user_model.dart:24`) | الخادم | الجلسة ← كل الطلبات | P | domain-only | PK `users.id` | — | معرّف |
| DATA-USER-02 | fallback «مرحباً بك» / «الاسم غير متوفر» | الأدمن | S04 ← `home_greeting.dart:20`، S07 ← `profile_identity_card.dart:22` | P | domain-only | `captains.display_name` | يعدّله الأدمن (D-A65) | شخصي |
| DATA-USER-03 | 10 أرقام، عزل LTR عند العرض | الأدمن | S07 ← `profile_identity_card.dart:30` | P | domain-only | `captains.phone` (فريد؟ unresolved) | الأدمن | شخصي حساس |
| DATA-USER-04 | — | Identity | غير مستخدم للتوجيه | P | domain-only | جداول Identity roles | — | — |
| DATA-USER-05 | الملف غير المكتمل غير مؤهل | الأدمن | لا (غير منفذ) | P | approved-unimplemented | عمود أو تحقق مشتق | الأدمن | — |
| DATA-USER-06 | الحظر يلغي الجلسات | الأدمن | Splash ← `splash_cubit.dart:99` (الخطأ فقط) | P | approved-unimplemented (الخطأ موجود، الحقل لا) | `users.status` + سجل تدقيق | الأدمن | — |
| DATA-USER-07 | 4–30 حرفاً | الأدمن | — | P | approved-unimplemented | فريد مطبّع | الأدمن | تعريفي |
| DATA-RATE-01..03 | لا 5 نجوم افتراضي؛ «لا توجد تقييمات» حالة مستقلة | الخادم (تجميع) | S07 ← `profile_rating_card.dart:37` | A | domain-only / unresolved | عرض محسوب من DATA-RATE-04 أو عمود مُجمَّع | الكابتن يقرأ | — |
| DATA-RATE-04 | — | unresolved | لا | P | unresolved | `order_ratings` بعد تحديد المقيّم | unresolved | — |
| DATA-AV-01 | التغيير يمر بفحص المتطلبات وأمر مؤكد | الخادم | S04 ← `home_availability_bar.dart:43` | P | domain-only | `captain_availability` (الحالة، `changed_at`) | الكابتن يطلب؛ الخادم يقرر | — |
| DATA-AV-02 | — | نظام التشغيل | `home_availability_notice.dart` | L | domain-only | ليس حقلاً | — | — |
| DATA-LOC-01..05 | دقة ≤ 100م، حداثة 90 ث بساعة الخادم | الجهاز ← الخادم | S08 (موقع الكابتن للخريطة فقط حالياً) | P (آخر موقع) + E (التدفق) | approved-unimplemented | `captain_last_location` (واحد لكل كابتن) + سجل اختياري | الكابتن يرسل؛ الأدمن يرى آخر موقع | حساس جداً؛ مدة الاحتفاظ unresolved |
| DATA-OFF-01..10 | الاسم والمنطقة غير فارغين؛ الأجرة ≥ 0 (`app_order_offer_card.dart:70-85`)؛ اللقطة 0–10000 والمبلغ ≤ الأجرة | الخادم | S04 ← `pending_offers_sliver.dart:40`، النافذة ← `new_offer_sheet_host.dart` | العرض = P؛ اللقطة = S على الطلب | domain-only | `offers` (order_id، captain_id، round، status)؛ الأجرة واللقطة على `orders` | الكابتن المستهدف فقط | المنطقة لا العنوان؛ لا هاتف في الدفع |
| DATA-OFF-11/12 | الخادم يفرض الانتهاء عند القبول | الخادم | لا (غير مستخدم) | P | approved-unimplemented | `offers.expires_at`، `round`، فهرس (captain_id، status، expires_at) | الخادم | — |
| DATA-OFF-13 | مشتق | محسوب | `order_offer.dart:107` (حاجب القبول) | ليس عموداً | domain-only | لا يُخزن | — | — |
| DATA-CMD-01..04 | أمر واحد في وقت واحد؛ القبول الذري الأول يفوز | الخادم | `pending_offers_cubit.dart:94-148` | E + أثر على `offers`/`orders` | domain-only (المفتاح approved-unimplemented) | قيد فريد على `idempotency_keys`؛ تعيين ذري للطلب | الكابتن | تدقيق |
| DATA-DEC-01..05 | الترتيب الأحدث أولاً (`get_declined_offers.dart:52-61`) | الخادم | S05 ← `declined_offer_tile.dart` | P | domain-only / proposed | `offer_decisions` (offer_id، captain_id، decision، decided_at) | الكابتن يقرأ قراراته | — |
| DATA-ORD-01..04 | الطلب النشط يبقى مرئياً ولو كانت الإحداثيات غير صالحة | الخادم | S04 ← `home_active_order_card.dart:45`، S08 ← `active_order_pickup_view.dart` | P | domain-only | `orders` + `merchants.pickup_lat/lng` | الكابتن المُسنَد فقط | — |
| DATA-ORD-05/06/08 | — | الخادم | لا | P | approved-unimplemented | `orders.status`، `delivery_area_id`، `fee_fils`، `commission_snapshot_*` | — | — |
| DATA-ORD-07 | لا يُرسل في الدفع | التاجر | لا | P | approved-unimplemented | `orders.customer_phone` | الكابتن المُسنَد فقط، أثناء التنفيذ | حساس؛ الاحتفاظ unresolved |
| DATA-ORD-09/10 | 4 أرقام، 3 محاولات، يتجدد عند إعادة الإسناد | الخادم | لا | K / P | approved-unimplemented | `order_pickup_pins` (hash، attempts، used_at) | التاجر يرى؛ الكابتن يُدخل | سري |
| DATA-ORD-11 | انتقالات يتحقق منها الخادم بأوامر POST | الخادم | — | P | approved-unimplemented | enum + `order_assignments` + `order_events` للتدقيق | الأدمن/النظام | تدقيق |
| DATA-WAL-01 | يُعرض كما هو، بلا قص | الخادم | S06 ← `wallet_balance_card.dart:25`؛ S04 الشريحة (لا مصدر إنتاجي، API-05) | A (من الدفتر) أو P مع قيد اتساق | domain-only | `wallets.balance_fils` يُحدَّث ذرياً مع الدفتر | الكابتن يقرأ | مالي |
| DATA-WAL-02..07 | يُعرض خلال 7 أيام فقط؛ الدفتر كامل | الخادم | S06 ← `wallet_debit_card.dart:20-51` | P (غير قابل للتغيير) | domain-only | `ledger_entries` (type=`commission_debit`، amount، order_id، created_at)، فهرس (wallet_id، created_at) | الكابتن يقرأ قيوده | مالي؛ لا يُحذف (D-A74) |
| DATA-WAL-08 | — | العميل | `get_wallet.dart:63-64` | ليس عموداً | domain-only | استعلام نطاق زمني | — | — |
| DATA-WAL-09 | موجب، تحقق أدمن، فحص السقف ذرياً | الأدمن | لا (غير معروض للكابتن) | P | approved-unimplemented | `ledger_entries` (type=credit، verified_by) | الأدمن يكتب | مالي؛ تدقيق |
| DATA-WAL-10 | — | الخادم | — | P | approved-unimplemented | قيد فريد يمنع خصمين لنفس الطلب | النظام | — |
| DATA-WAL-11/12 | السقف يطبق على الرصيد الناتج بعد الشحن فقط | الأدمن/الإعداد | — | C | approved-unimplemented | جدول `settings` مُصدَّر بإصدارات | الأدمن | — |
| DATA-STAT-01 | التوصيلات المكتملة فقط، مستقل عن نافذة 7 أيام | الخادم | S06 ← `wallet_metric_cards.dart:45` | A | domain-only | عرض أو تجميع من `orders` المسلّمة | الكابتن يقرأ | — |
| DATA-STAT-02 | لا صفر بديل؛ «غير متوفر» | الخادم | `wallet_metric_cards.dart:48` | A | unresolved | صيغة غير محددة | — | — |
| DATA-DEL-01..03 | تأكيد صريح، إرسال مرة واحدة | الخادم | S09 ← `account_deletion_cubit.dart:73-94` | E | domain-only | — | الكابتن نفسه | — |
| DATA-DEL-04 | — | الخادم | — | P | unresolved | `account_deletion_requests` (status، timestamps) | النظام/الأدمن | الاحتفاظ بالدفتر والهوية unresolved (D-P39) |
| DATA-CFG-01/02 | HTTPS فقط، داخل التطبيق (`legal_page_launcher.dart:106-140`) | المالك | S03، S07 | C (ثابت في الكود حالياً) | domain-only / مفقود | لا (أو إعداد عن بعد، proposed) | — | — |
| DATA-PUSH-01 | — | الجهاز | لا | P | approved-unimplemented | `device_push_tokens` (session، token، platform) | النظام | معرّف جهاز؛ يُحذف عند الخروج/الحذف |
| DATA-UI-01 | — | محلي | — | L | — | ليس حقلاً: حالة إطار عمل وتقديم | — | — |

## 3. الأوامر والأحداث والاتساق

| سير العمل | الفاعل | المدخلات | الشروط المسبقة | تحقق الخادم | تغيّر الحالة | الأثر المالي | الاستجابة/الأخطاء | تلميح الحدث | التزامن/عدم التكرار | التدقيق |
|---|---|---|---|---|---|---|---|---|---|---|
| تسجيل الدخول | الكابتن | DATA-AUTH-01/02 | حساب نشط | Identity؛ رسالة عامة للخطأ | جلسة جديدة تلغي القديمة | — | `SignInResult` | — | جهاز واحد | دخول |
| تغيير التوفر | الكابتن | DATA-AV-01 المطلوب | أذونات الموقع والدفع؛ ملف مكتمل | الأهلية وحداثة الموقع | `captain_availability` | — | مؤكد/مرفوض/غير مؤكد | — | مفتاح مقترح | نعم |
| رفع الموقع | الجهاز | DATA-LOC-01..04 | متاح أو في توصيل | دقة ≤ 100م | آخر موقع | — | — | — | آخر قيمة تفوز حسب `capturedAt` | اختياري |
| قبول عرض فوري | الكابتن | DATA-CMD-01/03 | عرض قابل للتنفيذ وغير منتهٍ؛ لا توصيل نشط؛ شرط المحفظة غير محدد (D-P41) | ذري: أول قبول يفوز؛ إبطال الباقي | تعيين الطلب، status=accepted | **لا حجز ولا خصم** (D-A74) | مؤكد / لم يعد متاحاً / مرفوض | تحديث العروض والطلب النشط؛ العميل يعيد قراءة `getActiveOrder` | Idempotency-Key + قيد فريد على التعيين | `order_assignments` |
| رفض عرض | الكابتن | DATA-CMD-02/03 | العرض موجه له | — | قرار في `offer_decisions` | لا | مؤكد/… | إعادة قراءة العروض والسجل | مفتاح | نعم |
| التحقق من PIN | الكابتن | PIN (مقترح) | status ∈ heading_to_pickup | 3 محاولات ثم الأدمن | picked_up | لا | — | — | — | نعم |
| بدء التوصيل | الكابتن | orderId | picked_up | — | on_the_way | لا | — | — | مفتاح | نعم |
| إكمال التسليم | الكابتن المسؤول | orderId (+ مفتاح) | on_the_way | المسؤول الحالي فقط | delivered | **خصم عمولة واحد** بمبلغ اللقطة؛ تحديث الإحصائيات | — | إبطال المحفظة والطلب النشط | معاملة ذرية + `financialEffectKey` فريد | دفتر غير قابل للتغيير |
| إلغاء قبل الإكمال | الأدمن/النظام | orderId | قبل delivered | — | cancelled | لا خصم | — | — | — | نعم |
| إعادة إسناد بعد الاستلام | الأدمن | orderId، الكابتن البديل | حادث | تسوية يدوية | تعيين جديد | يُخصم من البديل المُكمِل فقط | — | — | — | سلسلة التسليم |
| شحن المحفظة | الأدمن | المبلغ > 0 | تحقق تحويل خارجي | الرصيد الناتج ≤ 5000 ذرياً | — | قيد دائن | رفض فوق السقف | إبطال المحفظة | تسلسل الأرصدة الدائنة المتزامنة | تدقيق الأدمن |
| حذف الحساب | الكابتن | تأكيد (+ مفتاح) | قد تتطلب إعادة مصادقة | unresolved: توصيل نشط، رصيد، حوادث (D-P39) | pending أو completed | الدفتر يُحتفظ به (unresolved) | pending/completed/reauth/… | المكتمل يلغي الجلسات | مفتاح | سجل الطلب |
| تسجيل رمز الدفع | الجهاز | DATA-PUSH-01 | جلسة | — | `device_push_tokens` | — | — | — | upsert | — |

ملاحظات الاتساق:
- **التلميح ليس حالة:** الدفع وSignalR لا يحملان حالة موثوقة. العميل يعيد القراءة (D-A72).
- **الاستجابات المتأخرة:** العميل يُسقطها بعدّاد جيل، ويدمج قراءات الاستعادة.
- **ترتيب الأحداث:** يقترح هذا التقرير `version` أو `updatedAt` على الطلب لكشف التقادم. هذا غير معتمد.

## 4. خريطة قاعدة البيانات المقترحة (للنقاش)

```text
users (Identity) 1─1 captains ─1 captain_availability
   │                  │       └─1 captain_last_location
   │                  ├─* device_sessions ─* device_push_tokens
   │                  ├─1 wallets ─* ledger_entries (credit | commission_debit | adjustment)
   │                  ├─* offer_decisions
   │                  └─* account_deletion_requests
merchants ─* orders ─* offers (round, captain_id, expires_at, status)
   │          ├─* order_assignments (captain_id, from, to, reason)
   │          ├─1 order_pickup_pins
   │          ├─* order_events (status transitions, actor)
   │          └─0..1 order_ratings (unresolved)
service_areas (governorate→city→area, fee_fils) ─* orders (delivery_area_id)
settings (commission_rate_bp, wallet_ceiling_fils, … versioned)
idempotency_keys (key, actor, operation, payload_hash, result)
```

| الكيان المرشح | الحقول المرتبطة | السبب المعتمد |
|---|---|---|
| `captains` | DATA-USER-02/03/05/06/07 | D-A53، D-A65 |
| `captain_availability`، `captain_last_location` | DATA-AV-01، DATA-LOC-* | D-A57 |
| `offers`، `offer_decisions` | DATA-OFF-*، DATA-CMD-*، DATA-DEC-* | D-A46، D-A60 |
| `orders`، `order_assignments`، `order_events`، `order_pickup_pins` | DATA-ORD-* | D-A44، D-A67، D-A68 |
| `wallets`، `ledger_entries` | DATA-WAL-* | D-A74، D-A75؛ دفتر غير قابل للتغيير |
| `settings` | DATA-WAL-11/12، DATA-CFG-* | D-A59 |
| `device_sessions`، `refresh_tokens`، `device_push_tokens` | DATA-AUTH-04/05، DATA-PUSH-01 | D-A53، D-A58 |
| `idempotency_keys` | DATA-CMD-03، DATA-WAL-10 | D-A56 |
| `account_deletion_requests` | DATA-DEL-04 | D-A78 (التفاصيل unresolved) |
| عروض محسوبة (ليست جداول) | DATA-RATE-01..03، DATA-STAT-01/02، الرصيد إن حُسب من الدفتر | قراءات مريحة للواجهة |

**ليست جداول:** بطاقات الواجهة، وحالات الـ Cubit، وحالات أذونات الجهاز، ونافذة 7 أيام، والصافي المشتق.

**فهارس وقيود ذات أساس:**
- فريد على `(order_id, effect_type)` في الدفتر (خصم واحد).
- فريد على التعيين النشط لكل طلب، وعلى التوصيل النشط لكل كابتن (D-A44).
- `(captain_id, status, expires_at)` على العروض (قراءة العروض القابلة للتنفيذ).
- `(wallet_id, created_at)` على الدفتر (نافذة السجل).
- فريد غير حساس لحالة الأحرف على `username`.

## 5. الأسئلة المفتوحة والفجوات (حسب الأثر)

| الأثر | البند | المرجع |
|---|---|---|
| عالٍ | صيغة الأرباح: إجمالي الأجور أم صافي بعد العمولة | D-P36 |
| عالٍ | عقد الحذف: محو أم إخفاء هوية، الاحتفاظ بالدفتر والهوية، التوقيت، إلغاء الجلسة، التوصيل النشط والرصيد | D-P39 |
| عالٍ | موضع حد −1000 فلس بعد إلغاء الحجز | D-P41 |
| عالٍ | نموذج قراءة الالتزامات المجدولة وتفعيلها | D-P25 |
| متوسط | مقياس التقييم ومن يقيّم | D-P37 |
| متوسط | الأرصدة القائمة فوق 5000 | D-P38 |
| متوسط | قبول المجدول داخل التطبيق | D-P35 |
| متوسط | روابط الشروط والخصوصية ونصوصها القانونية | D-P40، P-01 |
| متوسط | وحدة طول كلمة المرور (runes مقابل UTF-16) | `PROJECT_STATUS` §4 |
| متوسط | كل عقود OpenAPI وأكواد Problem Details وأحداث SignalR | D-A54 |
| منخفض | مدة الاحتفاظ بسجل المواقع وهاتف العميل | الخصوصية / P-02 |
| منخفض | ترقيم السجل والتوصيلات المكتملة | — |

**الإنفاذ الخادمي الإلزامي:**
- القبول الذري.
- خصم واحد عند الإكمال.
- سقف 5000 فلس على الرصيد بعد الشحن.
- حداثة الموقع 90 ثانية.
- صلاحية العرض.
- PIN بثلاث محاولات.
- جلسة جهاز واحد.
- إلغاء الجلسة عند الحظر.

لم يُخترَع هنا أي endpoint أو SQL أو مدة احتفاظ قانونية أو مفتاح API أو صيغة عمولة.

## 6. مطابقة الاكتمال

| العنصر الديناميكي (تقرير 01 §9) | حقل البيانات / الفجوة |
|---|---|
| التحية، الاسم، الهاتف | DATA-USER-02/03 |
| شريحة الرصيد / رصيد المحفظة | DATA-WAL-01 (+ فجوة المصدر API-05) |
| مفتاح التوفر والمتطلبات | DATA-AV-01 / DATA-AV-02 |
| حقول بطاقة العرض والنافذة | DATA-OFF-01..10 (+ DATA-OFF-11/12 مفقودة) |
| أوامر القبول والرفض | DATA-CMD-01..04 |
| بطاقة الطلب النشط وصفحته | DATA-ORD-01..04 (+ 05..10 مفقودة) |
| موقع الكابتن والخريطة | DATA-LOC-01/02 (+ مزوّد الخرائط، ليس حقلاً) |
| العروض المرفوضة | DATA-DEC-01..05 |
| التوصيلات المكتملة | فجوة عقد: قائمة `orders` المسلّمة لكابتن مع ترقيم (proposed) |
| سجل الخصم | DATA-WAL-02..08 |
| العدّ والأرباح | DATA-STAT-01/02 |
| التقييم | DATA-RATE-01..04 |
| نتيجة الحذف | DATA-DEL-01..04 |
| الإصدار في «حول» | ليس حقل قاعدة بيانات: مصدر منصة (حزمة غير معتمدة بعد) |
| الشروط والخصوصية | DATA-CFG-01/02 |
| حالة الاتصال | ليس حقلاً (منصة) |
| نصوص ARB، اختيار التبويب، متحكمات الحقول، أعلام الفتح | DATA-UI-01: غير مخزنة عمداً |

| العملية المعتمدة | المدخلات والنتائج |
|---|---|
| الدخول، التجديد، الخروج | DATA-AUTH-01..06 |
| التوفر ورفع الموقع | DATA-AV-01، DATA-LOC-* |
| العروض والقبول والرفض | DATA-OFF-*، DATA-CMD-* |
| PIN، بدء التوصيل، الإكمال | DATA-ORD-05..11 (approved-unimplemented) |
| الخصم والشحن والسقف | DATA-WAL-01..12 |
| الإحصائيات والتقييم | DATA-STAT-*، DATA-RATE-* |
| الحذف | DATA-DEL-* |
| الدفع | DATA-PUSH-01 |
| الالتزامات المجدولة | فجوة: نموذج قراءة غير محدد (D-P25) |
