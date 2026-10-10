import 'package:flutter/material.dart';

import '../models/supplier.dart';

const Color kOrange = Color(0xFFFF7A00);
const Color kOrangeDeep = Color(0xFFE56700);
const Color kOrangeLight = Color(0xFFFF9A3D);
const Color kGreen = Color(0xFF1FA971);
const Color kBlue = Color(0xFF2F80ED);
const Color kRed = Color(0xFFE5484D);

Color alpha(Color c, double opacity) => c.withAlpha((opacity * 255).round().clamp(0, 255));

/// ألوان إضافية تتغير حسب الوضع (فاتح / داكن).
class Palette {
  final Color bg;
  final Color card;
  final Color field;
  final Color border;
  final Color text;
  final Color muted;
  final Color softOrange;
  final bool dark;

  const Palette({
    required this.bg,
    required this.card,
    required this.field,
    required this.border,
    required this.text,
    required this.muted,
    required this.softOrange,
    required this.dark,
  });

  static const light = Palette(
    bg: Color(0xFFF7F7F7),
    card: Color(0xFFFFFFFF),
    field: Color(0xFFF1F1F1),
    border: Color(0xFFEAEAEA),
    text: Color(0xFF111111),
    muted: Color(0xFF707070),
    softOrange: Color(0xFFFFF1E3),
    dark: false,
  );

  static const darkPalette = Palette(
    bg: Color(0xFF0E0E0E),
    card: Color(0xFF1A1A1A),
    field: Color(0xFF242424),
    border: Color(0xFF2A2A2A),
    text: Color(0xFFF2F2F2),
    muted: Color(0xFF9A9A9A),
    softOrange: Color(0xFF2B1B0C),
    dark: true,
  );

  static Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkPalette : light;
}

Color statusColor(AccountStatus s) {
  switch (s) {
    case AccountStatus.due:
      return kOrange;
    case AccountStatus.settled:
      return kGreen;
    case AccountStatus.credit:
      return kBlue;
  }
}

String balanceCaption(AccountStatus s) {
  switch (s) {
    case AccountStatus.due:
      return 'مستحق للمورد';
    case AccountStatus.settled:
      return 'الحساب مسدد';
    case AccountStatus.credit:
      return 'رصيد لصالحك';
  }
}

ThemeData buildTheme(Brightness brightness) {
  final pal = brightness == Brightness.dark ? Palette.darkPalette : Palette.light;
  final scheme = ColorScheme.fromSeed(seedColor: kOrange, brightness: brightness).copyWith(
    primary: kOrange,
    onPrimary: Colors.white,
    secondary: kOrange,
    surface: pal.card,
    onSurface: pal.text,
    error: kRed,
  );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: pal.bg,
    dividerColor: pal.border,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: pal.bg,
      foregroundColor: pal.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: pal.text, fontSize: 19, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: pal.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(kOrange, 1.6),
      errorBorder: border(kRed),
      focusedErrorBorder: border(kRed, 1.6),
      labelStyle: TextStyle(color: pal.muted),
      floatingLabelStyle: const TextStyle(color: kOrange, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: pal.text,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: pal.border, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kOrange),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kOrange,
      foregroundColor: Colors.white,
      extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: pal.card,
      indicatorColor: pal.softOrange,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: pal.border, space: 1, thickness: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: pal.card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
  );
}
