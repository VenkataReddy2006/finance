import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/person.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/l10n.dart';

class PersonFormScreen extends StatefulWidget {
  final String groupId;
  final String? personId;

  const PersonFormScreen({
    super.key,
    required this.groupId,
    this.personId,
  });

  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sNoController = TextEditingController();
  final _nameController = TextEditingController();
  final _villageController = TextEditingController();
  final _principalController = TextEditingController();
  final _interestController = TextEditingController();
  
  double _totalAmount = 0;
  DateTime _selectedDate = DateTime.now();
  bool _isEdit = false;
  Person? _existingPerson;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.personId != null;
    if (_isEdit) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      _existingPerson = provider.people.firstWhere((p) => p.id == widget.personId);
      _sNoController.text = _existingPerson!.sNo.toString();
      _nameController.text = _existingPerson!.name;
      _villageController.text = _existingPerson!.village;
      _principalController.text = _existingPerson!.principal.toString();
      _interestController.text = _existingPerson!.interest.toString();
      _selectedDate = _existingPerson!.date;
      _updateTotal();
    }
  }

  void _updateTotal() {
    double p = double.tryParse(_principalController.text) ?? 0;
    double i = double.tryParse(_interestController.text) ?? 0;
    setState(() {
      _totalAmount = p + i;
    });
  }

  @override
  void dispose() {
    _sNoController.dispose();
    _nameController.dispose();
    _villageController.dispose();
    _principalController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? L10n.getString(context, 'edit_entry') : L10n.getString(context, 'add_new'))),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 700 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('PERSON DETAILS'),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.primaryNavy : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : AppTheme.primaryNavy.withOpacity(0.05)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildTextField(_sNoController, 'Enter S.No', label: 'SERIAL NUMBER', isNumber: true, validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final sNo = int.tryParse(value);
                          if (sNo == null) return 'Invalid';
                          final provider = Provider.of<FinanceProvider>(context, listen: false);
                          if (provider.isDuplicateSNo(widget.groupId, sNo, excludeId: widget.personId)) {
                            return 'Duplicate S.No';
                          }
                          return null;
                        }),
                        const SizedBox(height: 24),
                        _buildTextField(_nameController, L10n.getString(context, 'full_name'), label: L10n.getString(context, 'full_name').toUpperCase()),
                        const SizedBox(height: 24),
                        _buildTextField(_villageController, L10n.getString(context, 'village'), label: L10n.getString(context, 'village').toUpperCase()),
                        const SizedBox(height: 24),
                        _buildDatePicker(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildLabel('FINANCIALS'),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.primaryBlack : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : AppTheme.primaryNavy.withOpacity(0.05)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_principalController, '₹0', label: 'PRINCIPAL', isNumber: true, onChanged: (_) => _updateTotal())),
                            const SizedBox(width: 20),
                            Expanded(child: _buildTextField(_interestController, '₹0', label: 'INTEREST', isNumber: true, onChanged: (_) => _updateTotal())),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryEmerald.withOpacity(0.1), AppTheme.accentGold.withOpacity(0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('PROJECTED TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1.5)),
                              Text('₹${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.cyanAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: _submit,
                      child: Text(_isEdit ? L10n.getString(context, 'edit_entry') : L10n.getString(context, 'save_entry'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), letterSpacing: 2)),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.getString(context, 'date').toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryNavy, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) setState(() => _selectedDate = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.primaryNavy.withOpacity(0.08)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd MMMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Icon(Icons.calendar_today_rounded, size: 18, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.2)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {required String label, bool isNumber = false, Function(String)? onChanged, String? Function(String?)? validator}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryNavy, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          validator: validator ?? (value) => (value == null || value.isEmpty) ? 'Required' : null,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.primaryNavy.withOpacity(0.08))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryNavy, width: 2)),
          ),
        ),
      ],
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      if (_isEdit) {
        final updatedPerson = _existingPerson!.copyWith(
          sNo: int.parse(_sNoController.text),
          name: _nameController.text,
          village: _villageController.text,
          date: _selectedDate,
          principal: double.parse(_principalController.text),
          interest: double.parse(_interestController.text),
        );
        await provider.updatePerson(updatedPerson);
      } else {
        await provider.addPerson(
          sNo: int.parse(_sNoController.text),
          name: _nameController.text,
          village: _villageController.text,
          date: _selectedDate,
          principal: double.parse(_principalController.text),
          interest: double.parse(_interestController.text),
          groupId: widget.groupId,
        );
      }
      if (mounted) Navigator.pop(context);
    }
  }
}
