import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/supplier_repository.dart';
import '../../models/supplier.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import 'supplier_detail_screen.dart';

/// إضافة مورد جديد أو تعديل بياناته.
class SupplierFormScreen extends StatefulWidget {
  const SupplierFormScreen({
    super.key,
    this.supplierId,
    this.initialName = '',
    this.initialPhone = '',
    this.returnIdOnly = false,
  });

  final int? supplierId;
  final String initialName;
  final String initialPhone;

  /// عند true يُعيد رقم المورد إلى الشاشة السابقة بدل فتح صفحته.
  final bool returnIdOnly;

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  late final TextEditingController _phone = TextEditingController(text: widget.initialPhone);
  final _company = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();

  String _currency = 'SYP';
  Supplier? _existing;
  bool _hasMovements = false;
  bool _loading = false;
  bool _saving = false;

  bool get _isEdit => widget.supplierId != null;

  @override
  void initState() {
    super.initState();
    _currency = Provider.of<AppState>(context, listen: false).defaultCurrency;
    if (_isEdit) {
      _loading = true;
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    try {
      final s = await SupplierRepository.instance.summary(widget.supplierId!);
      if (!mounted) return;
      if (s == null) {
        Navigator.pop(context);
        return;
      }
      setState(() {
        _existing = s.supplier;
        _name.text = s.supplier.name;
        _phone.text = s.supplier.phone;
        _company.text = s.supplier.company;
        _address.text = s.supplier.address;
        _notes.text = s.supplier.notes;
        _currency = s.supplier.currency;
        _hasMovements = s.movementCount > 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      showSnack(context, friendlyError(e, fallback: kLoadError), error: true);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _company.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final base = Supplier(
        id: _existing?.id,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        company: _company.text.trim(),
        address: _address.text.trim(),
        notes: _notes.text.trim(),
        currency: _currency,
        archived: _existing?.archived ?? false,
      );
      if (_isEdit) {
        await SupplierRepository.instance.update(base);
        if (!mounted) return;
        showSnack(context, 'تم حفظ بيانات المورد');
        Navigator.pop(context, _existing!.id);
      } else {
        final id = await SupplierRepository.instance.insert(base);
        if (!mounted) return;
        showSnack(context, 'تمت إضافة المورد');
        if (widget.returnIdOnly) {
          Navigator.pop(context, id);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplierId: id)),
          );
        }
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e, fallback: kSaveError), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل المورد' : 'إضافة مورد')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  ramiTextField(
                    controller: _name,
                    label: 'اسم المورد *',
                    validator: Validators.supplierName,
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 14),
                  ramiTextField(
                    controller: _phone,
                    label: 'رقم الهاتف',
                    validator: Validators.phone,
                    keyboard: TextInputType.phone,
                    ltr: true,
                    icon: Icons.phone_rounded,
                  ),
                  const SizedBox(height: 14),
                  ramiTextField(
                    controller: _company,
                    label: 'اسم الشركة / المحل',
                    icon: Icons.storefront_rounded,
                  ),
                  const SizedBox(height: 14),
                  ramiTextField(
                    controller: _address,
                    label: 'العنوان',
                    icon: Icons.location_on_rounded,
                  ),
                  const SizedBox(height: 14),
                  ramiTextField(
                    controller: _notes,
                    label: 'ملاحظات',
                    maxLines: 3,
                    validator: Validators.notes,
                    icon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: 20),
                  Text('عملة حساب المورد',
                      style: TextStyle(fontWeight: FontWeight.w800, color: pal.text)),
                  const SizedBox(height: 4),
                  Text(
                    _hasMovements
                        ? 'لا يمكن تغيير العملة بعد تسجيل حركات لهذا المورد.'
                        : 'جميع فواتير ودفعات هذا المورد ستُسجَّل بهذه العملة (بدون تحويل تلقائي).',
                    style: TextStyle(color: pal.muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in kCurrencies)
                        RamiChip(
                          label: c.symbol == c.code ? c.code : '${c.symbol} (${c.code})',
                          selected: _currency == c.code,
                          onTap: _hasMovements ? () {} : () => setState(() => _currency = c.code),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('حفظ المورد'),
                  ),
                ],
              ),
            ),
    );
  }
}
