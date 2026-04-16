import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/finance_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/security_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/security_lock_screen.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import 'common/glass_box.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final SecurityService _securityService = SecurityService();
  bool _isLockEnabled = false;
  bool _isLoadingLock = true;

  @override
  void initState() {
    super.initState();
    _loadLockStatus();
  }

  Future<void> _loadLockStatus() async {
    final status = await _securityService.isLockEnabled();
    if (mounted) {
      setState(() {
        _isLockEnabled = status;
        _isLoadingLock = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = Provider.of<FinanceProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isDesktop = Responsive.isDesktop(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            Text(
              'APPEARANCE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            _buildSection(
              isDesktop,
              isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                  const SizedBox(height: 20),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 18), label: Text('Light', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 18), label: Text('Dark', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_suggest_rounded, size: 18), label: Text('Auto', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (Set<ThemeMode> selection) {
                      themeProvider.setTheme(selection.first);
                    },
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white.withOpacity(0.02) : AppTheme.primaryNavy.withOpacity(0.02),
                      selectedBackgroundColor: isDark ? AppTheme.primaryEmerald : AppTheme.primaryNavy,
                      selectedForegroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'SECURITY',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            _buildSection(
              isDesktop,
              isDark,
              padding: EdgeInsets.zero,
              child: _isLoadingLock 
                ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                : Column(
                    children: [
                      SwitchListTile(
                        value: _isLockEnabled,
                        onChanged: (val) async {
                          if (val) {
                            final success = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SecurityLockScreen(isSetup: true)),
                            );
                            if (success == true) {
                              _loadLockStatus();
                            }
                          } else {
                            await _securityService.setLockEnabled(false);
                            _loadLockStatus();
                          }
                        },
                        secondary: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.security_rounded, color: AppTheme.primaryEmerald, size: 22),
                        ),
                        title: Text('App Lock', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2, color: isDark ? Colors.white : AppTheme.primaryNavy)),
                        subtitle: Text('Fingerprint or PIN on startup', style: TextStyle(color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      ),
                      if (_isLockEnabled) ...[
                        _buildDivider(context),
                        _buildListTile(
                          context,
                          Icons.pin_rounded,
                          'Change PIN',
                          'Update your 4-digit protection code',
                          AppTheme.accentGold,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityLockScreen(isSetup: true))),
                        ),
                      ],
                    ],
                  ),
            ),
            const SizedBox(height: 48),
            Text(
              'DANGER ZONE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.02),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
              ),
              child: _buildListTile(
                context,
                Icons.delete_forever_rounded,
                'Reset Database',
                'Factory reset app data',
                AppTheme.accentRed,
                () => _confirmReset(context),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.02),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
              ),
              child: _buildListTile(
                context,
                Icons.person_remove_rounded,
                'Delete Account',
                'Permanently wipe everything',
                AppTheme.accentRed,
                () => _confirmDeleteAccount(context),
              ),
            ),
            const SizedBox(height: 80),
            Column(
              children: [
                Text('FINANCE DAILY LEDGER', style: TextStyle(color: isDark ? Colors.white12 : AppTheme.primaryNavy.withOpacity(0.1), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 4)),
                const SizedBox(height: 6),
                Text('Classic Experience v3.0', style: TextStyle(color: isDark ? Colors.white12 : AppTheme.primaryNavy.withOpacity(0.1), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(bool isDesktop, bool isDark, {required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(24)}) {
    if (isDesktop) {
      return GlassBox(
        padding: padding,
        borderRadius: 28,
        child: child,
      );
    }
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.primaryNavy : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, String subtitle, Color iconColor, VoidCallback onTap) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2, color: isDark ? Colors.white : AppTheme.primaryNavy)),
      subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }

  Widget _buildDivider(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(height: 1, indent: 24, endIndent: 24, color: isDark ? Colors.white.withOpacity(0.04) : AppTheme.primaryNavy.withOpacity(0.05));
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('RESET ALL DATA?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        content: const Text('All database records will be permanently wiped.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38))),
          TextButton(
            onPressed: () {
              Provider.of<FinanceProvider>(context, listen: false).resetAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database reset.')),
              );
            },
            child: const Text('RESET', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool showPasswordField = false;
        bool isDeleting = false;
        bool isPasswordVisible = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: const Text('DELETE ACCOUNT?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.redAccent)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('This action is permanent and will wipe all your financial records from the cloud.'),
                  const SizedBox(height: 24),
                  if (!showPasswordField) ...[
                    const Text('Type DELETE to confirm:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white24, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      autofocus: true,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                      decoration: InputDecoration(
                        hintText: 'DELETE',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.02),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ] else ...[
                    const Text('VERIFY PASSWORD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orangeAccent, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    const Text('Firebase requires a recent login for security. Please enter your password to proceed.', style: TextStyle(fontSize: 11, color: Colors.white38)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      autofocus: true,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'PASSWORD',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.02),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38)),
                ),
                TextButton(
                  onPressed: isDeleting ? null : () async {
                    String input = passwordController.text;
                    
                    if (!showPasswordField) {
                      if (input.toUpperCase() == 'DELETE') {
                        setState(() {
                          showPasswordField = true;
                          passwordController.clear();
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please type DELETE to confirm')));
                      }
                      return;
                    }

                    // Proceed to delete
                    setState(() => isDeleting = true);
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId != null) {
                      try {
                        // 1. Re-authenticate AND Delete Firebase Account (The hardest step)
                        await AuthService().reauthenticateAndDelete(input);
                        
                        // 2. Delete MongoDB Data
                        await ApiService().deleteUserData(userId);
                        
                        // 3. Clear Local Data
                        if (context.mounted) {
                          await Provider.of<FinanceProvider>(context, listen: false).resetAll();
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false);
                        }
                      } catch (e) {
                        setState(() => isDeleting = false);
                        if (context.mounted) {
                          String errMsg = 'Error: ${e.toString()}';
                          if (errMsg.contains('wrong-password')) {
                            errMsg = 'Incorrect password. Try again.';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg), backgroundColor: Colors.redAccent));
                        }
                      }
                    }
                  },
                  child: isDeleting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
                    : Text(showPasswordField ? 'VERIFY & DELETE' : 'CONFIRM', 
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
