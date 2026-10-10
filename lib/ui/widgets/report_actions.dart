import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/text_utils.dart';
import '../../services/file_service.dart';
import '../screens/pdf_preview_screen.dart';
import 'common.dart';

/// أزرار أسفل أي تقرير: عرض/طباعة PDF + مشاركة الملف.
class ReportActions extends StatefulWidget {
  const ReportActions({
    super.key,
    required this.build,
    required this.fileName,
    required this.title,
    this.shareLabel = 'مشاركة التقرير',
    this.enabled = true,
  });

  final Future<Uint8List> Function() build;
  final String fileName;
  final String title;
  final String shareLabel;
  final bool enabled;

  @override
  State<ReportActions> createState() => _ReportActionsState();
}

class _ReportActionsState extends State<ReportActions> {
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await widget.build();
      final f = await writeTempFile('${safeFileName(widget.fileName)}.pdf', bytes);
      await shareFile(f, mime: 'application/pdf', subject: widget.title);
    } catch (e) {
      if (mounted) {
        showSnack(context, friendlyError(e, fallback: 'تعذّر إنشاء ملف PDF. حاول مرة أخرى.'), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _preview() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PdfPreviewScreen(
        title: widget.title,
        fileName: '${safeFileName(widget.fileName)}.pdf',
        buildPdf: widget.build,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.enabled && !_busy ? _preview : null,
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('عرض / طباعة'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: widget.enabled && !_busy ? _share : null,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(widget.shareLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
