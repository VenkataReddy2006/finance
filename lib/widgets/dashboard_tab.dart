import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../screens/day_detail_screen.dart';
import '../models/group.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import 'common/glass_box.dart';
import '../utils/l10n.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.groups.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryEmerald));
        }

        final isDesktop = Responsive.isDesktop(context);
        final isTablet = Responsive.isTablet(context);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 60.0 : 20.0,
            vertical: 8.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResponsiveSummary(context, provider),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    L10n.getString(context, 'ledger_groups'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  IconButton(
                    onPressed: () => _showAddGroupDialog(context, provider),
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryEmerald, size: 28),
                    tooltip: L10n.getString(context, 'add_new'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildGroupGrid(context, provider, isDesktop, isTablet),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponsiveSummary(BuildContext context, FinanceProvider provider) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    
    if (isDesktop || isTablet) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 900 : 700),
          child: _buildSummaryCard(context, provider, isDesktop || isTablet),
        ),
      );
    }
    return _buildSummaryCard(context, provider, false);
  }

  Widget _buildSummaryCard(BuildContext context, FinanceProvider provider, bool useGlass) {
    final balanceColor = provider.weeklyBalance < 0 ? AppTheme.accentRed : AppTheme.primaryEmerald;
    final theme = Theme.of(context);
    bool isDark = theme.brightness == Brightness.dark;
    
    if (useGlass) {
      return GlassBox(
        padding: const EdgeInsets.all(40.0),
        borderRadius: 30,
        child: _buildSummaryContent(context, provider, isDark, balanceColor),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: isDark 
            ? [AppTheme.primaryNavy, AppTheme.primaryBlack]
            : [Colors.white, AppTheme.lightSurface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : AppTheme.primaryNavy.withOpacity(0.05), 
            blurRadius: 30, 
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32.0),
      child: _buildSummaryContent(context, provider, isDark, balanceColor),
    );
  }

  Widget _buildSummaryContent(BuildContext context, FinanceProvider provider, bool isDark, Color balanceColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(L10n.getString(context, 'total_balance').toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), letterSpacing: 1.5)),
            const Icon(Icons.auto_graph_rounded, color: AppTheme.accentGold, size: 24),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '₹${provider.weeklyBalance.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: balanceColor, letterSpacing: -2),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _summaryItem(L10n.getString(context, 'principal'), '₹${provider.weeklyPrincipal.toStringAsFixed(0)}', isDark ? Colors.white : AppTheme.primaryNavy),
            _summaryItem(L10n.getString(context, 'interest'), '₹${provider.weeklyInterest.toStringAsFixed(0)}', AppTheme.accentTeal),
            _summaryItem(L10n.getString(context, 'given'), '₹${provider.weeklyGiven.toStringAsFixed(0)}', AppTheme.primaryEmerald),
            if (Responsive.isDesktop(context))
               _summaryItem(L10n.getString(context, 'ledger_status'), 'Premium Classic Active', AppTheme.accentGold),
          ],
        ),
      ],
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color.withOpacity(0.9))),
      ],
    );
  }

  Widget _buildGroupGrid(BuildContext context, FinanceProvider provider, bool isDesktop, bool isTablet) {
    int crossAxisCount = 2;
    if (isDesktop) {
      crossAxisCount = 6;
    } else if (isTablet) {
      crossAxisCount = 4;
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: (isDesktop || isTablet) ? 1.2 : 1.4,
      ),
      itemCount: provider.groups.length,
      itemBuilder: (context, index) {
        final group = provider.groups[index];
        final groupPeople = provider.getPeopleForGroup(group.id);
        return _buildGroupCard(context, group, groupPeople.length, provider);
      },
    );
  }

  Widget _buildGroupCard(BuildContext context, Group group, int count, FinanceProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DayDetailScreen(groupId: group.id, groupName: group.name)),
        );
      },
      onLongPress: () => _showGroupOptions(context, group, provider),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : AppTheme.primaryNavy.withOpacity(0.05), width: 1.5),
          boxShadow: [
             BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : AppTheme.primaryNavy.withOpacity(0.05),
              offset: const Offset(0, 10),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryNavy),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showGroupOptions(context, group, provider),
                  child: const Icon(Icons.more_vert_rounded, size: 16, color: Colors.white24),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 14, color: AppTheme.primaryEmerald),
                      const SizedBox(width: 8),
                      const Text(
                        'COUNT',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 1),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context, FinanceProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.getString(context, 'create_new_group').toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: L10n.getString(context, 'group_name_hint')),
          textCapitalization: TextCapitalization.sentences,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(L10n.getString(context, 'cancel'))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addGroup(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(L10n.getString(context, 'add_new'), style: const TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showGroupOptions(BuildContext context, Group group, FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131324),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(group.name.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 2)),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
              title: Text(L10n.getString(context, 'rename_group'), style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, group, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: Text(L10n.getString(context, 'delete_group'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(context, group, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Group group, FinanceProvider provider) {
    final controller = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.getString(context, 'rename_group').toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: L10n.getString(context, 'group_name_hint')),
          textCapitalization: TextCapitalization.sentences,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(L10n.getString(context, 'cancel'))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.renameGroup(group.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(L10n.getString(context, 'rename_group').split(' ')[0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Group group, FinanceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${L10n.getString(context, 'delete_group')}?', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.redAccent)),
        content: Text('Are you sure you want to delete "${group.name}"? All records inside this group will be deleted too.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(L10n.getString(context, 'cancel'))),
          TextButton(
            onPressed: () {
              provider.deleteGroup(group.id);
              Navigator.pop(context);
            },
            child: Text(L10n.getString(context, 'delete_group').split(' ')[0], style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
