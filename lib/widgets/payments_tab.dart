import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/l10n.dart';
import '../screens/group_payments_screen.dart';

class PaymentsTab extends StatelessWidget {
  const PaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final groups = provider.groups;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isDesktop = Responsive.isDesktop(context);

    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.primaryNavy.withOpacity(0.05)),
            const SizedBox(height: 16),
            Text(L10n.getString(context, 'no_payments'), style: TextStyle(color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final totals = provider.getTotalCollectionsForGroup(group.id);
            final double totalAmt = totals['total'] ?? 0;
            final int pCount = (totals['count'] ?? 0).toInt();

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [AppTheme.primaryNavy, AppTheme.primaryBlack]
                    : [Colors.white, AppTheme.lightSurface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.3) : AppTheme.primaryNavy.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupPaymentsScreen(groupId: group.id, groupName: group.name),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(32),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    L10n.getString(context, 'ledger_group').toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryNavy.withOpacity(0.6), letterSpacing: 1.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    group.name.toUpperCase(),
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryEmerald.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryEmerald),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            _statItem('₹${totalAmt.toStringAsFixed(0)}', 'TOTAL COLLECTED', AppTheme.primaryEmerald, isDark),
                            const Spacer(),
                            _statItem(pCount.toString(), 'ENTRIES', isDark ? Colors.white38 : AppTheme.primaryNavy.withOpacity(0.4), isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, Color valueColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: valueColor, letterSpacing: -1),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), letterSpacing: 1.5),
        ),
      ],
    );
  }
}
