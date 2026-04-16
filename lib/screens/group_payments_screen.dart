import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/l10n.dart';

class GroupPaymentsScreen extends StatelessWidget {
  final String groupId;
  final String groupName;

  const GroupPaymentsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final groupedPayments = provider.getPaymentsGroupedByDateForGroup(groupId);
    final dates = groupedPayments.keys.toList()..sort((a, b) => b.compareTo(a));

    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryBlack : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(groupName.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: dates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.primaryNavy.withOpacity(0.05)),
                  const SizedBox(height: 16),
                  Text(L10n.getString(context, 'no_payments'), style: TextStyle(color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final payments = groupedPayments[date]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 24, 0, 12),
                          child: Text(
                            DateFormat('EEEE, MMM d').format(date).toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), letterSpacing: 2),
                          ),
                        ),
                        ...payments.map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.primaryNavy : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : AppTheme.primaryNavy.withOpacity(0.05)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.download_done_rounded, size: 18, color: AppTheme.primaryEmerald),
                            ),
                            title: Text(p['personName'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2)),
                            subtitle: Text(DateFormat('hh:mm a').format(p['date']), style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), fontWeight: FontWeight.bold)),
                            trailing: Text(
                              '₹${p['amount'].toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.primaryEmerald, letterSpacing: -0.5),
                            ),
                          ),
                        )).toList(),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}
