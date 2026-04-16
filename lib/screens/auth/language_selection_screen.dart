import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/l10n.dart';
import '../main_navigation_screen.dart';
import 'login_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, String>> languages = [
      {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🇺🇸'},
      {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు', 'flag': '🇮🇳'},
      {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी', 'flag': '🇮🇳'},
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryBlack : AppTheme.lightBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.language_rounded, size: 40, color: AppTheme.primaryEmerald),
              ),
              const SizedBox(height: 24),
              Text(
                L10n.getString(context, 'language_selection').toUpperCase(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: isDark ? Colors.white : AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
                Text(
                  L10n.getString(context, 'select_lang_desc'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4),
                  ),
                ),
              const SizedBox(height: 48),
              Expanded(
                child: ListView.separated(
                  itemCount: languages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    bool isSelected = langProvider.locale.languageCode == lang['code'];

                    return GestureDetector(
                      onTap: () => langProvider.setLanguage(lang['code']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.primaryEmerald.withOpacity(0.1) 
                              : (isDark ? Colors.white.withOpacity(0.04) : AppTheme.primaryNavy.withOpacity(0.02)),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryEmerald : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['native']!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? AppTheme.primaryEmerald : (isDark ? Colors.white : AppTheme.primaryNavy),
                                  ),
                                ),
                                Text(
                                  lang['name']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppTheme.primaryEmerald.withOpacity(0.5) : (isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4)),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryEmerald),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                          (route) => false,
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      }
                    } catch (e) {
                      debugPrint('Auth check error in language selection: $e');
                      // Fallback: Just go to login screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    }
                  },
                  child: Text(
                    L10n.getString(context, 'continue').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
