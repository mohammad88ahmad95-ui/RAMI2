import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/money.dart';
import '../../core/text_utils.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import '../../models/supplier.dart';

/// بطاقة حديثة بزوايا ناعمة وظل خفيف.
class RamiCard extends StatelessWidget {
  const RamiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.gradient,
    this.radius = 20,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final double radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? pal.card) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: pal.border) : null,
        boxShadow: pal.dark
            ? null
            : const [BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class AvatarCircle extends StatelessWidget {
  const AvatarCircle(this.name, {super.key, this.size = 46, this.color});
  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? kOrange;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: alpha(c, 0.14), shape: BoxShape.circle),
      child: Text(
        initialOf(name),
        style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: size * 0.4),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final AccountStatus status;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: alpha(c, 0.13), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status.label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class RamiChip extends StatelessWidget {
  const RamiChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Material(
      color: selected ? kOrange : pal.card,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: selected ? kOrange : pal.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? Colors.white : pal.muted),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : pal.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(color: pal.softOrange, shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: kOrange),
            ),
            const SizedBox(height: 22),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: pal.muted, height: 1.5, fontSize: 14.5)),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(minimumSize: const Size(200, 50)),
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
            if (secondaryLabel != null) ...[
              const SizedBox(height: 10),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// مستطيل رمادي متحرك أثناء التحميل (Skeleton).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.width, this.height = 16, this.radius = 10});
  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(pal.field, pal.border, _c.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6, this.height = 84});
  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SkeletonBox(height: height, radius: 20),
      ),
    );
  }
}

/// مبلغ بحركة عدّاد عند التغيّر.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({super.key, required this.minor, required this.currency, this.style, this.suffixStyle});
  final int minor;
  final String currency;
  final TextStyle? style;
  final TextStyle? suffixStyle;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: minor.toDouble()),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(Money.withCurrency(v.round(), currency), style: style),
    );
  }
}

/// يحمّل بيانات غير متزامنة ويُعيد التحميل تلقائياً عند أي تغيير في قاعدة البيانات.
class DataLoader<T> extends StatefulWidget {
  const DataLoader({
    super.key,
    required this.load,
    required this.builder,
    this.skeleton,
    this.reloadKey,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? skeleton;
  final Object? reloadKey;

  @override
  State<DataLoader<T>> createState() => _DataLoaderState<T>();
}

class _DataLoaderState<T> extends State<DataLoader<T>> {
  T? _data;
  bool _has = false;
  Object? _error;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.changes.addListener(_reload);
    _reload();
  }

  @override
  void didUpdateWidget(covariant DataLoader<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadKey != widget.reloadKey) _reload();
  }

  @override
  void dispose() {
    AppDatabase.instance.changes.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final seq = ++_seq;
    try {
      final d = await widget.load();
      if (!mounted || seq != _seq) return;
      setState(() {
        _data = d;
        _has = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_has) return widget.builder(context, _data as T);
    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'تعذّر تحميل البيانات',
        message: friendlyError(_error!, fallback: kLoadError),
        actionLabel: 'إعادة المحاولة',
        onAction: () {
          setState(() => _error = null);
          _reload();
        },
      );
    }
    return widget.skeleton ?? const Center(child: CircularProgressIndicator(color: kOrange));
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'تأكيد',
  String cancelLabel = 'إلغاء',
  bool destructive = false,
}) async {
  final pal = Palette.of(context);
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: pal.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: Text(message, style: TextStyle(color: pal.muted, height: 1.55)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel, style: TextStyle(color: pal.muted, fontWeight: FontWeight.w700)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(110, 46),
            backgroundColor: destructive ? kRed : kOrange,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r == true;
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
    backgroundColor: error ? kRed : const Color(0xFF222222),
    duration: const Duration(seconds: 3),
  ));
}

Future<T?> showRamiSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: builder(ctx),
    ),
  );
}

/// صف خيار داخل Bottom Sheet.
class SheetOption extends StatelessWidget {
  const SheetOption({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final c = color ?? kOrange;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: alpha(c, 0.13), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: c),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyle(color: pal.muted)),
    );
  }
}
