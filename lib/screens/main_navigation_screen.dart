import 'package:flutter/material.dart';
import '../widgets/dashboard_tab.dart';
import '../widgets/payments_tab.dart';
import '../widgets/profile_tab.dart';
import '../widgets/settings_tab.dart';
import '../screens/auth/language_selection_screen.dart';
import '../screens/settings/change_password_screen.dart';
import '../utils/l10n.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const PaymentsTab(),
    const ProfileTab(),
  ];

  final List<String> _titles = [
    'Daily Ledger',
    'Payment History',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isMobile = Responsive.isMobile(context);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: (isMobile) ? null : Colors.transparent,
        elevation: 0,
        title: Text(
          _titles[_selectedIndex].toUpperCase(),
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          if (_selectedIndex == 2)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.tune_rounded, color: Colors.white30),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (!isMobile) _buildBackground(isDark),
          Row(
            children: [
              if (!isMobile) _buildNavigationRail(context, isDark),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile
                        ? 0
                        : (MediaQuery.of(context).size.width > 1400 ? 100 : 40),
                    vertical: isMobile ? 0 : 20,
                  ),
                  decoration: BoxDecoration(
                    color: isMobile
                        ? (isDark
                              ? AppTheme.primaryBlack
                              : AppTheme.lightSurface)
                        : Colors.transparent,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _tabs[_selectedIndex],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? _buildBottomNavBar(context, isDark)
          : null,
      endDrawer: _selectedIndex == 2
          ? _buildProfileDrawer(context, isDark)
          : null,
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.primaryNavy,
                  AppTheme.primaryBlack,
                  const Color(0xFF001F1F),
                ]
              : [
                  const Color(0xFFE0F2F1),
                  Colors.white,
                  const Color(0xFFF1F8E9),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: AppTheme.primaryEmerald.withOpacity(0.03),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: AppTheme.accentTeal.withOpacity(0.03),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDrawer(BuildContext context, bool isDark) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: 280,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.primaryNavy.withOpacity(0.98)
              : AppTheme.lightBg.withOpacity(0.98),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            bottomLeft: Radius.circular(32),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.getString(context, 'settings').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 2,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildDrawerItem(
                context,
                Icons.translate_rounded,
                L10n.getString(context, 'language_selection'),
                AppTheme.accentTeal,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageSelectionScreen(),
                    ),
                  );
                },
              ),
              _buildDrawerItem(
                context,
                Icons.settings_suggest_rounded,
                L10n.getString(context, 'app_settings'),
                AppTheme.primaryEmerald,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          title: Text(L10n.getString(context, 'settings')),
                        ),
                        body: const SettingsTab(),
                      ),
                    ),
                  );
                },
              ),
              _buildDrawerItem(
                context,
                Icons.vpn_key_rounded,
                L10n.getString(context, 'change_password'),
                AppTheme.accentGold,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'FINANCE LEDGER v3.0',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 12,
        color: Colors.white10,
      ),
      onTap: onTap,
    );
  }

  Widget _buildNavigationRail(BuildContext context, bool isDark) {
    bool isMobile = Responsive.isMobile(context);
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      backgroundColor: isMobile
          ? (isDark ? AppTheme.primaryNavy : AppTheme.lightBg)
          : Colors.transparent,
      indicatorColor: AppTheme.primaryEmerald.withOpacity(0.1),
      labelType: NavigationRailLabelType.all,
      selectedLabelTextStyle: TextStyle(
        color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryNavy,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4),
        fontSize: 11,
      ),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.grid_view_rounded),
          selectedIcon: Icon(
            Icons.grid_view_rounded,
            color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryNavy,
          ),
          label: const Text('Summary'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.account_balance_wallet_rounded),
          selectedIcon: Icon(
            Icons.account_balance_wallet_rounded,
            color: AppTheme.accentTeal,
          ),
          label: const Text('Payments'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.person_rounded),
          selectedIcon: const Icon(
            Icons.person_rounded,
            color: AppTheme.accentGold,
          ),
          label: const Text('Profile'),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.grid_view_rounded),
                activeIcon: Icon(
                  Icons.grid_view_rounded,
                  color: isDark
                      ? AppTheme.primaryEmerald
                      : AppTheme.primaryNavy,
                ),
                label: 'Summary',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.account_balance_wallet_rounded),
                activeIcon: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppTheme.accentTeal,
                ),
                label: 'Payments',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_rounded),
                activeIcon: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.accentGold,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
