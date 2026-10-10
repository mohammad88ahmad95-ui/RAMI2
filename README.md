# رامي — Rami

تطبيق موبايل (Android) متخصص **حصراً** في إدارة ومتابعة حسابات الموردين: ما عليك لكل مورد، وما دفعته، مع كشف حساب واضح يُصدَّر PDF ويُشارَك.

- يعمل **بدون إنترنت بالكامل** (SQLite محلية) — لا Firebase ولا Backend ولا اشتراكات.
- واجهة **عربية RTL**، تصميم برتقالي + داكن، وضع داكن احترافي.
- الرصيد **يُحسب دائماً من الحركات** (لا يُخزَّن) فلا يمكن أن يختلف عنها.

الرصيد المستحق = إجمالي فواتير الشراء − إجمالي الدفعات
(موجب = مستحق للمورد 🟠 · صفر = مسدد 🟢 · سالب = رصيد لصالحك 🔵)

---

## 1) متطلبات التشغيل

| الأداة | الإصدار |
|---|---|
| Flutter SDK (stable) | 3.24 أو أحدث |
| Dart | ≥ 3.3 (يأتي مع Flutter) |
| JDK | 17 |
| Android SDK | مع Android Studio أو command-line tools |
| Android | الحد الأدنى API 23 (Android 6.0) |

تحقّق من البيئة: `flutter doctor`

## 2) فتح المشروع
فك الضغط ثم افتح المجلد `rami` في **Android Studio** أو **VS Code** (مع إضافتي Flutter و Dart).

## 3) تثبيت الاعتماديات
```bash
flutter pub get
```

## 4) تشغيل المشروع
وصّل هاتفاً (تصحيح USB مفعّل) أو شغّل محاكياً ثم:
```bash
flutter run
```

## 5) إنشاء APK
```bash
flutter build apk --release
```
الناتج: `build/app/outputs/flutter-apk/app-release.apk`

## 6) إنشاء AAB (لمتجر Google Play)
```bash
flutter build appbundle --release
```
الناتج: `build/app/outputs/bundle/release/app-release.aab`

> **التوقيع:** إن لم يوجد ملف `android/key.properties` يُوقَّع الإصدار بمفتاح debug ليمكن تثبيته مباشرة.
> للنشر في المتجر أنشئ مفتاحاً: `keytool -genkey -v -keystore ~/rami.jks -keyalg RSA -keysize 2048 -validity 10000 -alias rami`
> ثم أنشئ `android/key.properties`:
> ```
> storePassword=...
> keyPassword=...
> keyAlias=rami
> storeFile=/المسار/rami.jks
> ```
> (الملف مُستثنى من Git عبر `.gitignore`.)

## 7) تغيير اسم التطبيق
- الاسم الظاهر تحت الأيقونة: `android/app/src/main/AndroidManifest.xml` ← `android:label="رامي"`.
- اسم الحزمة (applicationId): `android/app/build.gradle` ← `applicationId` و`namespace`، ثم انقل مجلد `android/app/src/main/kotlin/com/rami/suppliers` وعدّل `package` في `MainActivity.kt`.
- الاسم داخل الواجهة: `lib/core/constants.dart` ← `kAppName`.

## 8) تغيير الأيقونة
الأيقونات الحالية مولّدة من الشعار المرفق. للتغيير: استبدل ملفات `ic_launcher.png` في
`android/app/src/main/res/mipmap-*` (الأحجام 48/72/96/144/192 بكسل)،
واستبدل `assets/images/logo.png` (شاشة البداية وتقارير PDF).
المصدر عالي الدقة: `assets/images/app_icon.png`.

## 9) بنية المشروع
```
lib/
  main.dart · app.dart            نقطة الدخول، الثيم، RTL، بوابة القفل
  core/                           الثوابت، الثيم، المال، التواريخ، التحقق، الأخطاء (Utilities)
  models/                         Supplier, PurchaseInvoice, Payment, LedgerEntry, Statement, Period (Models)
  data/                           database.dart + Repositories (suppliers / invoices / payments / ledger / settings)
  services/                       النسخ الاحتياطي، CSV، القفل (PIN/بصمة)، المشاركة (Services)
  reports/                        مولّد PDF العربي + بناة التقارير (Reports)
  state/app_state.dart            حالة التطبيق (Provider): الإعدادات، الثيم، القفل، العملة النشطة
  ui/
    screens/                      الشاشات (الرئيسية، الموردون، الحركات، التقارير، الإعدادات، النماذج...)
    widgets/                      مكوّنات مشتركة (بطاقات، جداول، حقول، حالات فارغة...)
test/logic_test.dart              اختبارات المال والرصيد والبحث والفترات
.github/workflows/build.yml       بناء APK/AAB تلقائياً على GitHub Actions
```

### قاعدة البيانات
`suppliers` · `purchase_invoices` · `payments` · `settings`
(مفاتيح خارجية مع `ON DELETE CASCADE`، المبالغ أعداد صحيحة بأصغر وحدة، فهارس على المورد والتاريخ.)

### قرارات تصميم مهمة
- **كشف الحساب** يتبع صيغة كشف المورد: الفواتير في عمود «مدين»، الدفعات في «دائن»، والرصيد التراكمي بينهما.
- **العملات:** لكل مورد عملة (ل.س / USD / EUR / SAR / AED) تُحدَّد عند إنشائه ولا تتغير بعد وجود حركات. لا يوجد تحويل تلقائي؛ الإجماليات تُعرض لكل عملة على حدة (مع شريط اختيار العملة عند وجود أكثر من عملة).
- **الأرشفة:** المورد المؤرشف يختفي من القوائم وتُستثنى مبالغه من إجماليات الرئيسية والتقارير، ويحتفظ بكل بياناته ويمكن استرجاعه.
- **النسخ الاحتياطي:** ملف JSON مع بصمة SHA-256 للتحقق من السلامة؛ الاستيراد يتحقق من الملف كاملاً قبل أي تغيير، ويحفظ نسخة أمان تلقائية، ويستبدل البيانات داخل Transaction (إما ينجح كاملاً أو لا يتغير شيء). رمز الحماية لا يُنقل مع النسخة.
- **الحماية:** رمز PIN من 4 أرقام (مخزّن كـ SHA-256 مع Salt) + بصمة اختيارية، قفل تلقائي بعد 20 ثانية خارج التطبيق، وتأخير 30 ثانية بعد 5 محاولات خاطئة.

## 10) أوامر البناء (ملخص)
```bash
flutter pub get
flutter test
flutter run
flutter build apk --release
flutter build appbundle --release
```

### البناء على GitHub
ارفع المشروع إلى مستودع؛ الـ workflow في `.github/workflows/build.yml` يشغّل التحليل والاختبارات ويبني APK و AAB ويرفعهما كـ Artifacts.

### إن ظهر خطأ في ملفات Gradle
إذا كان لديك Flutter أحدث بكثير وطلب تحديث ملفات أندرويد، نفّذ مرة واحدة خارج المشروع `flutter create --platforms=android tmp_app` وقارن/انسخ إصدارات `settings.gradle` و`gradle-wrapper.properties` منه (لا تلمس `lib/` ولا `pubspec.yaml`).
