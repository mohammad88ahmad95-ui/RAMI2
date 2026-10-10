import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/dates.dart';

class PdfColumn {
  final String title;
  final int flex;
  final bool numeric;
  const PdfColumn(this.title, this.flex, {this.numeric = false});
}

class PdfSummaryItem {
  final String label;
  final String value;
  const PdfSummaryItem(this.label, this.value);
}

/// وصف عام لأي تقرير جدولي؛ جميع التقارير تُبنى من هذا الوصف.
class PdfReportSpec {
  final String title;
  final String businessName;
  final List<String> subtitleLines;
  final List<PdfSummaryItem> summary;
  final List<PdfColumn> columns;
  final List<List<String>> rows;
  final List<String>? openingRow;
  final List<String>? footerRow;
  final String emptyMessage;

  const PdfReportSpec({
    required this.title,
    required this.businessName,
    this.subtitleLines = const [],
    this.summary = const [],
    required this.columns,
    required this.rows,
    this.openingRow,
    this.footerRow,
    this.emptyMessage = 'لا توجد بيانات ضمن هذه الفترة.',
  });
}

const PdfColor _orange = PdfColor.fromInt(0xFFFF7A00);
const PdfColor _dark = PdfColor.fromInt(0xFF1A1A1A);
const PdfColor _muted = PdfColor.fromInt(0xFF707070);
const PdfColor _zebra = PdfColor.fromInt(0xFFF7F7F7);
const PdfColor _line = PdfColor.fromInt(0xFFEAEAEA);
const PdfColor _soft = PdfColor.fromInt(0xFFFFF1E3);

pw.Font? _regular;
pw.Font? _bold;
pw.MemoryImage? _logo;

Future<void> _ensureAssets() async {
  _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));
  _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'));
  if (_logo == null) {
    final data = await rootBundle.load('assets/images/logo.png');
    _logo = pw.MemoryImage(data.buffer.asUint8List());
  }
}

pw.Widget _t(String s, {double size = 10, bool bold = false, PdfColor? color, pw.TextAlign? align}) {
  return pw.Text(
    s,
    textDirection: pw.TextDirection.rtl,
    textAlign: align,
    style: pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color),
  );
}

pw.Widget _row(List<PdfColumn> cols, List<String> cells,
    {PdfColor? bg, bool bold = false, PdfColor? color, double size = 9.5}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: bg,
      border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.6)),
    ),
    padding: pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: pw.Row(
      children: [
        for (var i = 0; i < cols.length; i++)
          pw.Expanded(
            flex: cols[i].flex,
            child: pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: 3),
              child: _t(
                i < cells.length ? cells[i] : '',
                size: size,
                bold: bold,
                color: color,
                align: cols[i].numeric ? pw.TextAlign.left : pw.TextAlign.right,
              ),
            ),
          ),
      ],
    ),
  );
}

Future<Uint8List> buildPdfReport(PdfReportSpec spec) async {
  await _ensureAssets();
  final doc = pw.Document(title: spec.title, author: 'رامي', creator: 'رامي');
  final generated = fmtDateTime(DateTime.now());

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
      ),
      header: (ctx) {
        if (ctx.pageNumber == 1) return pw.SizedBox();
        return pw.Container(
          padding: pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _t(spec.title, size: 10, bold: true, color: _orange),
              _t(spec.businessName.isEmpty ? 'رامي' : spec.businessName, size: 9, color: _muted),
            ],
          ),
        );
      },
      footer: (ctx) => pw.Container(
        padding: pw.EdgeInsets.only(top: 8),
        decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _t('أُنشئ بواسطة رامي · $generated', size: 8, color: _muted),
            _t('صفحة ${ctx.pageNumber} من ${ctx.pagesCount}', size: 8, color: _muted),
          ],
        ),
      ),
      build: (ctx) {
        final widgets = <pw.Widget>[];

        // الترويسة: الشعار + العنوان
        widgets.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.ClipRRect(
                horizontalRadius: 10,
                verticalRadius: 10,
                child: pw.Image(_logo!, width: 52, height: 52),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _t(spec.title, size: 18, bold: true),
                    pw.SizedBox(height: 3),
                    _t(spec.businessName.isEmpty ? 'رامي · إدارة حسابات الموردين' : spec.businessName,
                        size: 10, color: _muted),
                  ],
                ),
              ),
              _t('تاريخ الإنشاء\n$generated', size: 8.5, color: _muted, align: pw.TextAlign.left),
            ],
          ),
        );
        widgets.add(pw.SizedBox(height: 8));
        widgets.add(pw.Container(height: 2.5, color: _orange));
        widgets.add(pw.SizedBox(height: 10));

        for (final l in spec.subtitleLines) {
          widgets.add(pw.Padding(padding: pw.EdgeInsets.only(bottom: 3), child: _t(l, size: 11)));
        }
        widgets.add(pw.SizedBox(height: 8));

        if (spec.summary.isNotEmpty) {
          widgets.add(
            pw.Row(
              children: [
                for (var i = 0; i < spec.summary.length; i++) ...[
                  if (i > 0) pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      padding: pw.EdgeInsets.all(9),
                      decoration: pw.BoxDecoration(
                        color: _soft,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _t(spec.summary[i].label, size: 8.5, color: _muted),
                          pw.SizedBox(height: 3),
                          _t(spec.summary[i].value, size: 11, bold: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
          widgets.add(pw.SizedBox(height: 12));
        }

        // رأس الجدول
        widgets.add(_row(
          spec.columns,
          [for (final c in spec.columns) c.title],
          bg: _dark,
          bold: true,
          color: PdfColors.white,
          size: 9,
        ));
        if (spec.openingRow != null) {
          widgets.add(_row(spec.columns, spec.openingRow!, bg: _soft, bold: true));
        }
        if (spec.rows.isEmpty) {
          widgets.add(pw.Padding(
            padding: pw.EdgeInsets.symmetric(vertical: 24),
            child: pw.Center(child: _t(spec.emptyMessage, size: 11, color: _muted)),
          ));
        }
        for (var i = 0; i < spec.rows.length; i++) {
          widgets.add(_row(spec.columns, spec.rows[i], bg: i.isOdd ? _zebra : null));
        }
        if (spec.footerRow != null) {
          widgets.add(_row(spec.columns, spec.footerRow!, bg: _soft, bold: true, size: 10));
        }
        return widgets;
      },
    ),
  );
  return doc.save();
}
