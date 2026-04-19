import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/person.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/l10n.dart';
import 'person_form_screen.dart';
import 'person_detail_screen.dart';

class DayDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const DayDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName.toUpperCase())),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 900 : double.infinity,
          ),
          child: Consumer<FinanceProvider>(
            builder: (context, provider, child) {
              final people = provider.searchPeople(
                widget.groupId,
                _searchQuery,
              );
              final summary = provider.getGroupSummary(widget.groupId);

              return Column(
                children: [
                  _buildDailyMetrics(context, summary),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: L10n.getString(context, 'search_hint'),
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white24
                              : AppTheme.primaryNavy.withOpacity(0.4),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark
                              ? Colors.white24
                              : AppTheme.primaryNavy.withOpacity(0.4),
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.primaryNavy
                            : AppTheme.lightSurface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),
                  Expanded(
                    child: people.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : AppTheme.primaryNavy.withOpacity(0.05),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  L10n.getString(context, 'no_records'),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white24
                                        : AppTheme.primaryNavy.withOpacity(0.4),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: people.length,
                            padding: const EdgeInsets.only(bottom: 120),
                            itemBuilder: (context, index) {
                              final person = people[index];
                              return _buildPersonCard(context, person);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonFormScreen(groupId: widget.groupId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDailyMetrics(BuildContext context, Map<String, double> summary) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.primaryNavy : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : AppTheme.primaryNavy.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 16,
            spacing: 16,
            children: [
              _metricItem(
                context,
                L10n.getString(context, 'total_potential').toUpperCase(),
                '₹${summary['potential']?.toStringAsFixed(0)}',
                isDark ? Colors.white38 : AppTheme.primaryNavy.withOpacity(0.4),
              ),
              _metricItem(
                context,
                L10n.getString(context, 'collectable').toUpperCase(),
                '₹${summary['balance']?.toStringAsFixed(0)}',
                (summary['balance'] ?? 0) < 0
                    ? AppTheme.accentRed
                    : AppTheme.primaryEmerald,
                isRight: false,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white, height: 1),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _metricItem(
                context,
                L10n.getString(context, 'principal').toUpperCase(),
                '₹${summary['principal']?.toStringAsFixed(0)}',
                isDark ? Colors.white : AppTheme.primaryNavy,
                size: 14,
              ),
              _metricItem(
                context,
                L10n.getString(context, 'interest').toUpperCase(),
                '₹${summary['interest']?.toStringAsFixed(0)}',
                AppTheme.accentTeal,
                isRight: false,
                size: 14,
              ),
              _metricItem(
                context,
                L10n.getString(context, 'given').toUpperCase(),
                '₹${summary['given']?.toStringAsFixed(0)}',
                AppTheme.primaryEmerald,
                isRight: false,
                size: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(
    BuildContext context,
    String label,
    String value,
    Color color, {
    bool isRight = false,
    double size = 20,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: isRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: isDark
                ? Colors.white24
                : AppTheme.primaryNavy.withOpacity(0.4),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonCard(BuildContext context, Person person) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.03)
              : AppTheme.primaryNavy.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryNavy.withOpacity(0.2),
                AppTheme.primaryEmerald.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            person.sNo.toString(),
            style: TextStyle(
              color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryNavy,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          person.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: -0.3,
          ),
        ),
        subtitle: Text(
          person.village.toUpperCase(),
          style: TextStyle(
            color: isDark
                ? Colors.white24
                : AppTheme.primaryNavy.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${person.totalAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Colors.white38
                    : AppTheme.primaryNavy.withOpacity(0.4),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '₹${person.balance.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: person.balance < 0
                    ? AppTheme.accentRed
                    : AppTheme.primaryEmerald,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonDetailScreen(personId: person.id),
            ),
          );
        },
      ),
    );
  }
}
