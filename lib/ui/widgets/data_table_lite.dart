import 'package:flutter/material.dart';

import '../../core/theme.dart';

class TableCol {
  final String title;
  final double flex;
  final bool end; // محاذاة للنهاية (للأرقام)
  const TableCol(this.title, this.flex, {this.end = false});
}

/// جدول خفيف وسريع (يبني الصفوف عند الحاجة فقط) مع تمرير أفقي عند ضيق الشاشة.
class DataTableLite extends StatelessWidget {
  const DataTableLite({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.cellBuilder,
    this.footer,
    this.minWidth = 620,
    this.rowHighlight,
    this.leadingCells,
  });

  final List<TableCol> columns;
  final int rowCount;

  /// يُرجع نص أو ودجت لكل خلية
  final Widget Function(BuildContext context, int row, int col) cellBuilder;
  final List<Widget>? footer;
  final double minWidth;
  final Color? Function(int row)? rowHighlight;

  /// خلايا صف إضافي قبل الصفوف (مثل الرصيد الافتتاحي)
  final List<Widget>? leadingCells;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth < minWidth ? minWidth : c.maxWidth;
      final total = columns.fold<double>(0, (a, b) => a + b.flex);

      Widget rowOf(List<Widget> cells, {Color? bg, bool bold = false}) {
        return Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              for (var i = 0; i < columns.length; i++)
                SizedBox(
                  width: (width - 24) * columns[i].flex / total,
                  child: Align(
                    alignment: columns[i].end ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                    child: cells[i],
                  ),
                ),
            ],
          ),
        );
      }

      final headerRow = rowOf(
        [
          for (final col in columns)
            Text(col.title,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: pal.muted)),
        ],
        bg: pal.dark ? const Color(0xFF222222) : const Color(0xFFF1F1F1),
      );

      final table = SizedBox(
        width: width,
        child: Column(
          children: [
            headerRow,
            if (leadingCells != null) rowOf(leadingCells!, bg: pal.softOrange),
            Expanded(
              child: rowCount == 0
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: rowCount,
                      separatorBuilder: (_, __) => Divider(height: 1, color: pal.border),
                      itemBuilder: (ctx, r) => rowOf(
                        [for (var i = 0; i < columns.length; i++) cellBuilder(ctx, r, i)],
                        bg: rowHighlight?.call(r),
                      ),
                    ),
            ),
            if (footer != null)
              Container(
                decoration: BoxDecoration(
                  color: pal.softOrange,
                  border: Border(top: BorderSide(color: kOrange, width: 1.5)),
                ),
                child: rowOf(footer!),
              ),
          ],
        ),
      );

      return Container(
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pal.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: c.maxWidth < minWidth
            ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: table)
            : table,
      );
    });
  }
}

Widget cellText(String s, {bool bold = false, Color? color, double size = 13.5}) => Text(
      s,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: color),
    );
