import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/l10n.dart';
import '../main_navigation_screen.dart';
import 'onboarding_screen.dart';
import '../../utils/app_theme.dart';
import 'language_selection_screen.dart';
import 'login_screen.dart';
import 'security_lock_screen.dart';
import '../../services/security_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFallback = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    _checkAuth();

    // Fallback timer: if nothing happens in 6 seconds, show a continue button
    _fallbackTimer = Timer(const Duration(milliseconds: 6000), () {
      if (mounted) setState(() => _showFallback = true);
    });
  }

  void _checkAuth() async {
    try {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;

      final langProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );

      User? user;
      try {
        // Wrap Firebase calls as they can hang on Web if not initialized
        user = FirebaseAuth.instance.currentUser;
      } catch (e) {
        debugPrint('Firebase Auth not available or not initialized: $e');
      }

      if (user != null) {
        final isLocked = await SecurityService().isLockEnabled();
        if (isLocked) {
          _navigateTo(const SecurityLockScreen());
        } else {
          _navigateTo(const MainNavigationScreen());
        }
      } else if (langProvider.isLanguageSet) {
        _navigateTo(const LoginScreen());
      } else {
        _navigateTo(const OnboardingScreen());
      }
    } catch (e) {
      debugPrint('Navigation initialization error: $e');
      if (mounted) setState(() => _showFallback = true);
    }
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    _fallbackTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryBlack : AppTheme.lightBg,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNavy.withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'DAILY LEDGER',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: isDark ? Colors.white : AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Classic Experience v3.0',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: isDark
                      ? Colors.white24
                      : AppTheme.primaryNavy.withOpacity(0.2),
                ),
              ),
              if (_showFallback) ...[
                const SizedBox(height: 60),
                TextButton(
                  onPressed: () => _navigateTo(const LoginScreen()),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryEmerald,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'CONTINUE TO LOGIN',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
