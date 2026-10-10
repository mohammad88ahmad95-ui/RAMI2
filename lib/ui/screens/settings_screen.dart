import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../services/csv_service.dart';
import '../../services/lock_service.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'backup_screen.dart';
import 'data_management_screen.dart';
import 'pin_screens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editText(BuildContext context, String title, String current, Future<void> Function(String) save) async {
    final c = TextEditingController(text: current);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: TextField(controller: c, autofocus: true, maxLength: 60),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    c.dispose();
    if (v == null) return;
    try {
      await save(v);
    } catch (e) {
      if (context.mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  Future<void> _pickCurrency(BuildContext context, AppState app) async {
    final code = await showRamiSheet<String>(
      context,
      (ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('العملة الافتراضية للموردين الجدد. الحسابات الحالية تبقى بعملتها ولا يوجد تحويل تلقائي.',
                style: TextStyle(height: 1.5)),
          ),
          for (final c in kCurrencies)
            ListTile(
              onTap: () => Navigator.pop(ctx, c.code),
              title: Text('${c.name} (${c.symbol})', style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: c.code == app.defaultCurrency ? const Icon(Icons.check_circle_rounded, color: kOrange) : null,
            ),
        ]),
      ),
    );
    if (code != null) {
      try {
        await app.setDefaultCurrency(code);
      } catch (e) {
        if (context.mounted) showSnack(context, friendlyError(e), error: true);
      }
    }
  }

  Future<void> _toggleLock(BuildContext context, AppState app, bool on) async {
    try {
      if (on) {
        final ok = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const PinFlowScreen(mode: PinFlowMode.create)),
        );
        if (ok == true && context.mounted) showSnack(context, 'تم تفعيل حماية التطبيق');
      } else {
        final ok = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const PinFlowScreen(mode: PinFlowMode.verify, title: 'تعطيل الحماية')),
        );
        if (ok == true) {
          await app.disableLock();
          if (context.mounted) showSnack(context, 'تم تعطيل حماية التطبيق');
        }
      }
    } catch (e) {
      if (context.mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  Future<void> _toggleBio(BuildContext context, AppState app, bool on) async {
    try {
      if (on) {
        if (!await LockService.biometricsAvailable()) {
          if (context.mounted) showSnack(context, 'البصمة غير متاحة أو غير مفعّلة على هذا الجهاز', error: true);
          return;
        }
        final ok = await LockService.authenticateBiometric('أكّد بصمتك لتفعيل الفتح بالبصمة');
        if (!ok) return;
      }
      await app.setBiometric(on);
    } catch (e) {
      if (context.mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pal = Palette.of(context);

    Widget group(String title, List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
              child: Text(title, style: TextStyle(color: pal.muted, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            RamiCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1) const Divider(indent: 60),
                ],
              ]),
            ),
          ],
        );

    Widget tile(IconData icon, String title, {String? value, Widget? trailing, VoidCallback? onTap, Color? color}) =>
        ListTile(
          onTap: onTap,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: alpha(color ?? kOrange, 0.13), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color ?? kOrange, size: 21),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          subtitle: value == null || value.isEmpty ? null : Text(value),
          trailing: trailing ?? (onTap == null ? null : Icon(Icons.chevron_left_rounded, color: pal.muted)),
        );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: Text('الإعدادات', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          ),
          group('المنشأة', [
            tile(Icons.business_rounded, 'اسم المنشأة',
                value: app.businessName.isEmpty ? 'غير محدد' : app.businessName,
                onTap: () => _editText(context, 'اسم المنشأة', app.businessName, app.setBusinessName)),
            tile(Icons.person_rounded, 'اسم المستخدم',
                value: app.userName.isEmpty ? 'غير محدد' : app.userName,
                onTap: () => _editText(context, 'اسم المستخدم', app.userName, app.setUserName)),
            tile(Icons.payments_rounded, 'العملة الافتراضية',
                value: '${currencyOf(app.defaultCurrency).name} (${currencyOf(app.defaultCurrency).symbol})',
                onTap: () => _pickCurrency(context, app)),
          ]),
          group('المظهر واللغة', [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.dark_mode_rounded, color: kOrange),
                  SizedBox(width: 12),
                  Text('الوضع الداكن', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('تلقائي')),
                      ButtonSegment(value: ThemeMode.light, label: Text('فاتح')),
                      ButtonSegment(value: ThemeMode.dark, label: Text('داكن')),
                    ],
                    selected: {app.themeMode},
                    onSelectionChanged: (s) => app.setThemeMode(s.first),
                  ),
                ),
              ]),
            ),
            tile(Icons.language_rounded, 'اللغة', value: 'العربية',
                onTap: () => showSnack(context, 'العربية هي اللغة الحالية. دعم الإنجليزية مُجهَّز بنيوياً لإصدار قادم.')),
          ]),
          group('الحماية', [
            tile(Icons.lock_rounded, 'حماية التطبيق',
                value: app.lockEnabled ? 'مفعّلة (رمز PIN)' : 'معطّلة',
                trailing: Switch(
                  value: app.lockEnabled,
                  onChanged: (v) => _toggleLock(context, app, v),
                )),
            if (app.lockEnabled) ...[
              tile(Icons.fingerprint_rounded, 'الفتح بالبصمة',
                  trailing: Switch(
                    value: app.biometricEnabled,
                      onChanged: (v) => _toggleBio(context, app, v),
                  )),
              tile(Icons.password_rounded, 'تغيير الرمز', onTap: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const PinFlowScreen(mode: PinFlowMode.verify, title: 'تغيير الرمز')),
                );
                if (ok == true && context.mounted) {
                  final ok2 = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const PinFlowScreen(mode: PinFlowMode.create, title: 'الرمز الجديد')),
                  );
                  if (ok2 == true && context.mounted) showSnack(context, 'تم تغيير الرمز');
                }
              }),
            ],
          ]),
          group('البيانات', [
            tile(Icons.cloud_upload_rounded, 'النسخ الاحتياطي', value: 'تصدير واستيراد نسخة كاملة', color: kBlue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen()))),
            tile(Icons.table_view_rounded, 'تصدير البيانات (CSV)', color: kGreen, onTap: () async {
              try {
                await CsvService.exportAllAndShare();
              } catch (e) {
                if (context.mounted) showSnack(context, friendlyError(e), error: true);
              }
            }),
            tile(Icons.folder_special_rounded, 'إدارة البيانات', value: 'المؤرشفون · حذف البيانات', color: kBlue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataManagementScreen()))),
          ]),
          const SizedBox(height: 24),
          Center(child: Text('رامي · الإصدار $kAppVersion', style: TextStyle(color: pal.muted))),
        ],
      ),
    );
  }
}
