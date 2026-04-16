import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/l10n.dart';
import 'language_selection_screen.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Track with Ease',
      'description': 'Manage your daily financial records and ledgers with a professional, streamlined interface.',
      'icon': '📊'
    },
    {
      'title': 'Cloud Sync',
      'description': 'Your data is secured in the cloud and accessible across all your devices instantly.',
      'icon': '☁️'
    },
    {
      'title': 'Smart Insights',
      'description': 'Analyze your net balance, principal, and interest with high-tech visualization.',
      'icon': '⚡'
    }
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryBlack : AppTheme.lightBg,
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (value) => setState(() => _currentPage = value),
              itemCount: _onboardingData.length,
              itemBuilder: (context, index) => _buildPage(index, isDark),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => _buildDot(index: index),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        if (_currentPage == _onboardingData.length - 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
                          );
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Graphs.easeInExpo,
                          );
                        }
                      },
                      child: Text(
                        _currentPage == _onboardingData.length - 1 
                            ? L10n.getString(context, 'get_started') 
                            : L10n.getString(context, 'next'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
                    ),
                    child: Text(L10n.getString(context, 'skip'), style: TextStyle(color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _onboardingData[index]['icon']!,
          style: const TextStyle(fontSize: 100),
        ),
        const SizedBox(height: 40),
        Text(
          _onboardingData[index]['title']!.toUpperCase(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppTheme.primaryNavy,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _onboardingData[index]['description']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white38 : AppTheme.primaryNavy.withOpacity(0.4),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot({required int index}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppTheme.primaryEmerald : (isDark ? Colors.white12 : AppTheme.primaryNavy.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class Graphs {
  static const Curve easeInExpo = Curves.easeInExpo;
}
