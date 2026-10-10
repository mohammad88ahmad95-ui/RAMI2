import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../services/lock_service.dart';
import '../../state/app_state.dart';

const int kPinLength = 4;

/// لوحة أرقام مع مؤشر النقاط.
class PinPad extends StatelessWidget {
  const PinPad({super.key, required this.value, required this.onChanged, this.onBiometric, this.error});
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onBiometric;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    Widget key(String label, {VoidCallback? onTap, IconData? icon}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Material(
              color: icon == null && label.isEmpty ? Colors.transparent : pal.card,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox(
                  height: 68,
                  child: Center(
                    child: icon != null
                        ? Icon(icon, color: pal.text)
                        : Text(label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ),
        );
    Widget digit(String d) => key(d, onTap: () {
          if (value.length < kPinLength) onChanged(value + d);
        });
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < kPinLength; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 9),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < value.length ? kOrange : Colors.transparent,
                  border: Border.all(color: i < value.length ? kOrange : pal.muted, width: 2),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 34,
          child: Center(
            child: Text(error ?? '', style: const TextStyle(color: kRed, fontWeight: FontWeight.w700)),
          ),
        ),
        for (final row in const [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
          Row(children: [for (final d in row) digit(d)]),
        Row(children: [
          onBiometric != null ? key('', icon: Icons.fingerprint_rounded, onTap: onBiometric) : key(''),
          digit('0'),
          key('', icon: Icons.backspace_outlined, onTap: () {
            if (value.isNotEmpty) onChanged(value.substring(0, value.length - 1));
          }),
        ]),
      ],
    );
  }
}

/// شاشة القفل (تظهر فوق التطبيق عند تفعيل الحماية).
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String? _error;
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      if (app.biometricEnabled) _biometric();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _biometric() async {
    final ok = await LockService.authenticateBiometric('أكّد هويتك لفتح التطبيق');
    if (ok && mounted) context.read<AppState>().unlock();
  }

  void _startCountdown() {
    final app = context.read<AppState>();
    _timer?.cancel();
    setState(() => _remaining = app.lockoutRemaining);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final r = app.lockoutRemaining;
      if (!mounted) return;
      setState(() => _remaining = r);
      if (r == 0) {
        t.cancel();
        setState(() => _error = null);
      }
    });
  }

  void _onChanged(String v) {
    if (_remaining > 0) return;
    setState(() {
      _pin = v;
      _error = null;
    });
    if (v.length == kPinLength) {
      final app = context.read<AppState>();
      if (app.verifyPin(v)) {
        app.unlock();
      } else {
        setState(() {
          _pin = '';
          _error = 'الرمز غير صحيح';
        });
        if (app.lockoutRemaining > 0) _startCountdown();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pal = Palette.of(context);
    return Scaffold(
      backgroundColor: pal.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset('assets/images/logo.png', width: 84, height: 84),
                  ),
                  const SizedBox(height: 18),
                  const Text('أدخل رمز الحماية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 22),
                  PinPad(
                    value: _pin,
                    onChanged: _onChanged,
                    onBiometric: app.biometricEnabled ? _biometric : null,
                    error: _remaining > 0 ? 'محاولات كثيرة. انتظر $_remaining ثانية' : _error,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum PinFlowMode { create, verify }

/// إنشاء رمز جديد (مع تأكيده) أو التحقق من الرمز الحالي. تُعيد true عند النجاح.
class PinFlowScreen extends StatefulWidget {
  const PinFlowScreen({super.key, required this.mode, this.title});
  final PinFlowMode mode;
  final String? title;
  @override
  State<PinFlowScreen> createState() => _PinFlowScreenState();
}

class _PinFlowScreenState extends State<PinFlowScreen> {
  String _pin = '';
  String? _first;
  String? _error;

  String get _prompt {
    if (widget.mode == PinFlowMode.verify) return 'أدخل الرمز الحالي';
    return _first == null ? 'اختر رمزاً من $kPinLength أرقام' : 'أعد إدخال الرمز للتأكيد';
  }

  Future<void> _onChanged(String v) async {
    setState(() {
      _pin = v;
      _error = null;
    });
    if (v.length != kPinLength) return;
    final app = context.read<AppState>();
    if (widget.mode == PinFlowMode.verify) {
      if (app.verifyPin(v)) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _pin = '';
          _error = app.lockoutRemaining > 0 ? 'محاولات كثيرة. حاول بعد قليل' : 'الرمز غير صحيح';
        });
      }
      return;
    }
    if (_first == null) {
      setState(() {
        _first = v;
        _pin = '';
      });
    } else if (_first == v) {
      try {
        await app.enableLock(v);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          setState(() {
            _pin = '';
            _first = null;
            _error = friendlyError(e, fallback: kSaveError);
          });
        }
      }
    } else {
      setState(() {
        _pin = '';
        _first = null;
        _error = 'الرمزان غير متطابقين، حاول من جديد';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'حماية التطبيق')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 46, color: kOrange),
                  const SizedBox(height: 14),
                  Text(_prompt, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 22),
                  PinPad(value: _pin, onChanged: _onChanged, error: _error),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
