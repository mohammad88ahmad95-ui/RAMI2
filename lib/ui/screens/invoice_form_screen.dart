import 'package:flutter/material.dart';

import '../../core/dates.dart';
import '../../core/errors.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/invoice_repository.dart';
import '../../data/supplier_repository.dart';
import '../../models/purchase_invoice.dart';
import '../../models/supplier.dart';
import '../widgets/balance_preview.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/supplier_picker.dart';

/// إضافة فاتورة شراء أو تعديلها.
class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key, this.supplierId, this.invoiceId});
  final int? supplierId;
  final int? invoiceId;

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = today();
  SupplierSummary? _supplier;
  PurchaseInvoice? _existing;
  bool _loading = true;
  bool _saving = false;
  bool _supplierError = false;

  bool get _isEdit => widget.invoiceId != null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      var sid = widget.supplierId;
      if (_isEdit) {
        final inv = await InvoiceRepository.instance.getById(widget.invoiceId!);
        if (inv == null) {
          if (mounted) Navigator.pop(context);
          return;
        }
        _existing = inv;
        sid = inv.supplierId;
        _number.text = inv.number;
        _amount.text = _fmtInput(inv.amount);
        _notes.text = inv.notes;
        _date = tryParseIso(inv.date) ?? today();
      }
      if (sid != null) _supplier = await SupplierRepository.instance.summary(sid);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, friendlyError(e, fallback: kLoadError), error: true);
      Navigator.pop(context);
    }
  }

  String _fmtInput(int minor) {
    final raw = Money.toInput(minor);
    final parts = raw.split('.');
    final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  @override
  void dispose() {
    _number.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  int? get _enteredAmount => Money.parse(_amount.text);

  int? get _previewBalance {
    final s = _supplier;
    final a = _enteredAmount;
    if (s == null || a == null || a <= 0) return null;
    return s.balance - (_existing?.amount ?? 0) + a;
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
      final inv = PurchaseInvoice(
        id: _existing?.id,
        supplierId: _supplier!.id,
        number: _number.text.trim(),
        date: isoDate(_date),
        amount: _enteredAmount!,
        notes: _notes.text.trim(),
      );
      if (_isEdit) {
        await InvoiceRepository.instance.update(inv);
      } else {
        await InvoiceRepository.instance.insert(inv);
      }
      if (!mounted) return;
      showSnack(context, _isEdit ? 'تم تعديل الفاتورة' : 'تم حفظ الفاتورة');
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
      appBar: AppBar(title: Text(_isEdit ? 'تعديل فاتورة شراء' : 'إضافة فاتورة شراء')),
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
                  ramiTextField(
                    controller: _number,
                    label: 'رقم الفاتورة',
                    validator: Validators.invoiceNumber,
                    ltr: true,
                    icon: Icons.tag_rounded,
                  ),
                  const SizedBox(height: 14),
                  DateField(value: _date, onChanged: (d) => setState(() => _date = d)),
                  const SizedBox(height: 14),
                  MoneyField(
                    controller: _amount,
                    label: 'قيمة الفاتورة *',
                    currencySymbol: currencyShortOf(currency),
                    validator: (v) => Validators.amount(v, what: 'قيمة الفاتورة'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  ramiTextField(
                    controller: _notes,
                    label: 'ملاحظات',
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
                    label: const Text('حفظ الفاتورة'),
                  ),
                ],
              ),
            ),
    );
  }
}

String currencyShortOf(String code) => Money.withCurrency(0, code).split(' ').last;
