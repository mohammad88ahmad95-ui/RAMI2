/// خطأ برسالة عربية جاهزة للعرض للمستخدم.
class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => message;
}

const String kSaveError = 'حدث خطأ أثناء حفظ البيانات. حاول مرة أخرى.';
const String kLoadError = 'حدث خطأ أثناء تحميل البيانات. حاول مرة أخرى.';
const String kGenericError = 'حدث خطأ غير متوقع. حاول مرة أخرى.';

/// يحوّل أي استثناء إلى رسالة عربية بسيطة دون كشف تفاصيل تقنية.
String friendlyError(Object e, {String fallback = kGenericError}) {
  if (e is AppException) return e.message;
  return fallback;
}
