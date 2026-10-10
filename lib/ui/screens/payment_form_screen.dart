import 'package:flutter/material.dart';

import '../../core/dates.dart';
import '../../core/errors.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/payment_repository.dart';
import '../../data/supplier_repository.dart';
import '../../models/ledger_entry.dart';
import '../../models/payment.dart';
import '../../models/supplier.dart';
import '../widgets/balance_preview.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/supplier_picker.dart';
import 'invoice_form_screen.dart' show currencyShortOf;

/// تسجيل دفعة لمورد أو تعديلها.
class PaymentFormScreen extends StatefulWidget {
  const PaymentFormScreen({super.key, this.supplierId, this.paymentId});
  final int? supplierId;
  final int? paymentId;

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = today();
  PaymentMethod _method = PaymentMethod.cash;
  SupplierSummary? _supplier;
  Payment? _existing;
  bool _loading = true;
  bool _saving = false;
  bool _supplierError = false;

  bool get _isEdit => widget.paymentId != null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      var sid = widget.supplierId;
      if (_isEdit) {
        final p = await PaymentRepository.instance.getById(widget.paymentId!);
        if (p == null) {
          if (mounted) Navigator.pop(context);
          return;
        }
        _existing = p;
        sid = p.supplierId;
        final raw = Money.toInput(p.amount).split('.');
        final whole = raw[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
        _amount.text = raw.length > 1 ? '$whole.${raw[1]}' : whole;
        _notes.text = p.notes;
        _date = tryParseIso(p.date) ?? today();
        _method = p.method;
      }
      if (sid != null) _supplier = await SupplierRepository.instance.summary(sid);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, friendlyError(e, fallback: kLoadError), error: true);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  int? get _entered => Money.parse(_amount.text);

  int? get _previewBalance {
    final s = _supplier;
    final a = _entered;
    if (s == null || a == null || a <= 0) return null;
    return s.balance + (_existing?.amount ?? 0) - a;
  }

  Future<void> _pickSupplier() async {
    final s = await pickSupplier(context, selectedId: _supplier?.id);
    if (s != null) {
      setState(() {
        _supplier = s;
        _supplierError = false;
      });
    }
  }

  Future<void> _save() async {
    final ok = _formKey.currentState!.validate();
    if (_supplier == null) {
      setState(() => _supplierError = true);
      return;
    }
    final dErr = Validators.date(_date);
    if (!ok || dErr != null) {
      if (dErr != null) showSnack(context, dErr, error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final pay = Payment(
        id: _existing?.id,
        supplierId: _supplier!.id,
        date: isoDate(_date),
        amount: _entered!,
        method: _method,
        notes: _notes.text.trim(),
      );
      if (_isEdit) {
        await PaymentRepository.instance.update(pay);
      } else {
        await PaymentRepository.instance.insert(pay);
      }
      if (!mounted) return;
      showSnack(context, _isEdit ? 'تم تعديل الدفعة' : 'تم تسجيل الدفعة');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e, fallback: kSaveError), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final currency = _supplier?.currency ?? 'SYP';
    final preview = _previewBalance;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل دفعة' : 'تسجيل دفعة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _isEdit ? null : _pickSupplier,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'المورد *',
                        errorText: _supplierError ? 'يرجى اختيار المورد' : null,
                        suffixIcon: _isEdit ? null : const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      child: _supplier == null
                          ? Text('اختر المورد', style: TextStyle(color: pal.muted, fontSize: 16))
                          : Row(
                              children: [
                                AvatarCircle(_supplier!.supplier.name, size: 30, color: statusColor(_supplier!.status)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(_supplier!.supplier.name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DateField(value: _date, onChanged: (d) => setState(() => _date = d)),
                  const SizedBox(height: 14),
                  MoneyField(
                    controller: _amount,
                    label: 'المبلغ المدفوع *',
                    currencySymbol: currencyShortOf(currency),
                    validator: (v) => Validators.amount(v, what: 'مبلغ الدفعة'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 18),
                  Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.w800, color: pal.text)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in PaymentMethod.values)
                        RamiChip(
                          label: m.label,
                          selected: _method == m,
                          onTap: () => setState(() => _method = m),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ramiTextField(
                    controller: _notes,
                    label: 'ملاحظات (اختياري)',
                    maxLines: 3,
                    validator: Validators.notes,
                    icon: Icons.notes_rounded,
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: 16),
                    BalancePreview(newBalance: preview, currency: currency),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('تسجيل الدفعة'),
                  ),
                ],
              ),
            ),
    );
  }
}
