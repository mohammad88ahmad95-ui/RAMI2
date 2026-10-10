#!/usr/bin/env bash
# يعيد توليد مجلد android بقوالب Flutter الحديثة (Gradle / AGP / Kotlin المناسبة لنسختك)
# ثم يعيد تطبيق تخصيصات رامي: الاسم، الأيقونات، الثيم، MainActivity، صلاحية البصمة.
set -euo pipefail
cd "$(dirname "$0")/.."

TMP="$(mktemp -d)"
cp -r android/app/src/main "$TMP/main"

rm -rf android
flutter create . --platforms=android --org com.rami --project-name rami --no-pub

# flutter create يضيف اختبار افتراضي لا يناسب رامي
rm -f test/widget_test.dart

# حذف MainActivity المولّد واستبداله بنسخة رامي (FlutterFragmentActivity للبصمة)
rm -rf android/app/src/main/kotlin android/app/src/main/java
mkdir -p android/app/src/main/kotlin
cp -r "$TMP/main/kotlin/." android/app/src/main/kotlin/
cp "$TMP/main/AndroidManifest.xml" android/app/src/main/AndroidManifest.xml
cp -r "$TMP/main/res/." android/app/src/main/res/

# معرّف الحزمة والحد الأدنى للنظام
for f in android/app/build.gradle android/app/build.gradle.kts; do
  [ -f "$f" ] || continue
  sed -i 's/com\.rami\.rami/com.rami.suppliers/g' "$f"
  sed -i 's/minSdk = flutter\.minSdkVersion/minSdk = 23/; s/minSdkVersion flutter\.minSdkVersion/minSdkVersion 23/' "$f"
done
echo "android/ prepared."
