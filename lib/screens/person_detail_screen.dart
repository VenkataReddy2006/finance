import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/person.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/l10n.dart';
import 'person_form_screen.dart';

class PersonDetailScreen extends StatelessWidget {
  final String personId;

  const PersonDetailScreen({super.key, required this.personId});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        final person = provider.people.firstWhere(
          (p) => p.id == personId,
          orElse: () => Person(
            id: '',
            sNo: 0,
            name: '',
            village: '',
            date: DateTime.now(),
            principal: 0,
            interest: 0,
            groupId: '',
          ),
        );
        
        if (person.id.isEmpty) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Person not found')));
        }

        bool isDark = Theme.of(context).brightness == Brightness.dark;
        bool isDesktop = Responsive.isDesktop(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(person.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonFormScreen(
                        groupId: person.groupId,
                        personId: person.id,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, provider, person),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  children: [
                    _buildHeader(context, person),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.history_rounded, size: 16, color: Colors.indigoAccent),
                          ),
                          const SizedBox(width: 12),
                          Text(L10n.getString(context, 'transaction_history').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                    person.payments.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Text(L10n.getString(context, 'no_payments'), style: const TextStyle(color: Colors.white12, fontWeight: FontWeight.bold)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: person.payments.length,
                            itemBuilder: (context, index) {
                              final payment = person.payments[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: CircleAvatar(backgroundColor: AppTheme.primaryEmerald.withOpacity(0.1), radius: 18, child: const Icon(Icons.payment, size: 16, color: AppTheme.primaryEmerald)),
                                  title: Text('₹${payment.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                                  subtitle: Text(DateFormat('dd MMMM yyyy').format(payment.date).toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white24, fontWeight: FontWeight.bold)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.redAccent),
                                    onPressed: () => provider.deletePayment(person.id, payment.id),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddPaymentDialog(context, provider),
            icon: const Icon(Icons.add),
            label: Text(L10n.getString(context, 'add_payment'), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Person person) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.primaryNavy : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.indigo.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.getString(context, 'village').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white24, letterSpacing: 1.5)),
                  Text(person.village.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(L10n.getString(context, 'date').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white24, letterSpacing: 1.5)),
                  Text(DateFormat('dd-MM-yyyy').format(person.date), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metric(context, L10n.getString(context, 'principal'), person.principal.toStringAsFixed(0), AppTheme.primaryEmerald),
              _metric(context, L10n.getString(context, 'interest'), person.interest.toStringAsFixed(0), AppTheme.accentGold),
              _metric(context, L10n.getString(context, 'total'), person.totalAmount.toStringAsFixed(0), isDark ? Colors.white38 : AppTheme.primaryNavy.withOpacity(0.4)),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metric(context, L10n.getString(context, 'given'), person.totalGiven.toStringAsFixed(0), AppTheme.accentTeal),
                _metric(context, L10n.getString(context, 'balance'), person.balance.toStringAsFixed(0), person.balance < 0 ? AppTheme.accentRed : AppTheme.primaryEmerald, isLarge: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value, Color color, {bool isLarge = false}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), letterSpacing: 1)),
        const SizedBox(height: 6),
        Text('₹$value', style: TextStyle(fontSize: isLarge ? 26 : 18, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
      ],
    );
  }

  void _showAddPaymentDialog(BuildContext context, FinanceProvider provider) {
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF14142B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(L10n.getString(context, 'add_payment').toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: '${L10n.getString(context, 'amount')} (₹)', labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.04))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd MMMM yyyy').format(selectedDate).toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60)),
                      const Icon(Icons.calendar_month_rounded, size: 20, color: Colors.cyanAccent),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(L10n.getString(context, 'cancel'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white38))),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountController.text);
                if (amt != null) {
                  provider.addPayment(personId, amt, selectedDate);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FinanceProvider provider, Person person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(L10n.getString(context, 'delete_person'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: Text(L10n.getString(context, 'delete_person_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(L10n.getString(context, 'cancel'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38))),
          TextButton(
            onPressed: () async {
              await provider.deletePerson(person.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: Text(L10n.getString(context, 'logout').split(' ')[0], style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
