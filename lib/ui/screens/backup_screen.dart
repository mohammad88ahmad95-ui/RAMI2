import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/dates.dart';
import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../services/backup_service.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await BackupService.exportAndShare();
      if (mounted) {
        await context.read<AppState>().reloadSettings();
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
      if (res == null || res.files.isEmpty) return;
      final f = res.files.single;
      List<int>? bytes = f.bytes;
      if (bytes == null && f.path != null) bytes = await File(f.path!).readAsBytes();
      if (bytes == null) throw const AppException('تعذّرت قراءة الملف.');
      String text;
      try {
        text = utf8.decode(bytes);
      } catch (_) {
        throw const AppException('ملف النسخة الاحتياطية غير صالح أو تالف.');
      }
      final info = BackupService.inspect(text);
      final created = DateTime.tryParse(info.createdAt);
      if (!mounted) return;
      final ok = await confirmDialog(
        context,
        title: 'استعادة النسخة الاحتياطية',
        message:
            'ستُستبدل جميع بياناتك الحالية بمحتوى النسخة:\n• ${info.suppliers} مورد\n• ${info.invoices} فاتورة شراء\n• ${info.payments} دفعة'
            '${created == null ? '' : '\nتاريخ النسخة: ${fmtDateTime(created)}'}\n\nلا يمكن التراجع عن هذه العملية.',
        confirmLabel: 'استعادة',
        destructive: true,
      );
      if (!ok) return;
      await BackupService.restore(text);
      if (!mounted) return;
      await context.read<AppState>().reloadSettings();
      if (mounted) showSnack(context, 'تمت استعادة البيانات بنجاح');
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final last = context.watch<AppState>().lastBackupAt;
    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RamiCard(
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: pal.softOrange, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.cloud_done_rounded, color: kOrange),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('آخر نسخة احتياطية', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(last == null ? 'لم يتم إنشاء نسخة بعد' : fmtDateTime(last), style: TextStyle(color: pal.muted)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Text(
            'النسخة الاحتياطية ملف واحد يحتوي على الموردين والفواتير والدفعات والإعدادات. احتفظ به في مكان آمن (واتساب، بريد، Google Drive...) ويمكنك استيراده على جهاز آخر.',
            style: TextStyle(color: pal.muted, height: 1.6),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.upload_rounded),
            label: const Text('تصدير نسخة احتياطية'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _import,
            icon: const Icon(Icons.download_rounded),
            label: const Text('استيراد نسخة احتياطية'),
          ),
          if (_busy) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: kOrange))),
          const SizedBox(height: 18),
          Text('ملاحظة: الاستيراد يستبدل كل البيانات الحالية، ويُحفظ نسخة أمان تلقائية قبل الاستبدال. رمز الحماية لا يُنقل مع النسخة.',
              style: TextStyle(color: pal.muted, fontSize: 12.5, height: 1.6)),
        ],
      ),
    );
  }
}
