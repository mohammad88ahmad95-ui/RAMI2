import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/theme.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key, required this.title, required this.fileName, required this.buildPdf});
  final String title;
  final String fileName;
  final Future<Uint8List> Function() buildPdf;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: (format) => buildPdf(),
        pdfFileName: fileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        maxPageWidth: 700,
        scrollViewDecoration: BoxDecoration(color: pal.bg),
        loadingWidget: const CircularProgressIndicator(color: kOrange),
        onError: (context, error) => const Center(
          child: Text('تعذّر عرض ملف PDF. حاول مرة أخرى.'),
        ),
      ),
    );
  }
}
