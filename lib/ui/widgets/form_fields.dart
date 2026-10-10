import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/dates.dart';
import '../../core/text_utils.dart';
import '../../core/theme.dart';

/// تنسيق الأرقام أثناء الكتابة مع فواصل الآلاف (1,500,000.50).
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var t = digitsToAscii(newValue.text).replaceAll(RegExp(r'[,\u066C\s]'), '').replaceAll('\u066B', '.');
    final buf = StringBuffer();
    var dot = false;
    for (final ch in t.split('')) {
      if (ch == '.') {
        if (!dot) {
          dot = true;
          buf.write(ch);
        }
      } else if (RegExp(r'[0-9]').hasMatch(ch)) {
        buf.write(ch);
      }
    }
    t = buf.toString();
    var intPart = t;
    var frac = '';
    final i = t.indexOf('.');
    if (i >= 0) {
      intPart = t.substring(0, i);
      frac = t.substring(i);
      if (frac.length > 3) frac = frac.substring(0, 3);
    }
    intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (intPart.length > 12) intPart = intPart.substring(0, 12);
    intPart = intPart.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    final out = intPart + frac;
    return TextEditingValue(text: out, selection: TextSelection.collapsed(offset: out.length));
  }
}

class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    required this.currencySymbol,
    required this.validator,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String currencySymbol;
  final String? Function(String?) validator;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [ThousandsInputFormatter()],
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        suffixText: currencySymbol,
        suffixStyle: const TextStyle(fontWeight: FontWeight.w700, color: kOrange, fontSize: 15),
      ),
    );
  }
}

class DateField extends StatelessWidget {
  const DateField({super.key, required this.value, required this.onChanged, this.label = 'التاريخ'});
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          locale: const Locale('ar'),
          helpText: 'اختر التاريخ',
          cancelText: 'إلغاء',
          confirmText: 'تأكيد',
        );
        if (d != null) onChanged(DateTime(d.year, d.month, d.day));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month_rounded, color: kOrange),
        ),
        child: Text(fmtLong(value), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// حقل نصي موحّد.
Widget ramiTextField({
  required TextEditingController controller,
  required String label,
  String? Function(String?)? validator,
  TextInputType? keyboard,
  int maxLines = 1,
  TextInputAction? action,
  bool ltr = false,
  IconData? icon,
  List<TextInputFormatter>? formatters,
}) {
  return TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboard,
    maxLines: maxLines,
    textInputAction: action ?? (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
    textDirection: ltr ? TextDirection.ltr : null,
    textAlign: ltr ? TextAlign.right : TextAlign.start,
    inputFormatters: formatters,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, size: 22),
    ),
  );
}
