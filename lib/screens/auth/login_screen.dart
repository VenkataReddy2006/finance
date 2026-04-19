import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../main_navigation_screen.dart';
import '../../utils/app_theme.dart';
import '../../utils/l10n.dart';
import 'forgot_password_screen.dart';
import '../../utils/responsive.dart';
import '../../widgets/common/glass_box.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _apiService = ApiService();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isEmailMode = true;

  void _login() async {
    String identifier = _identifierController.text.trim();
    String password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showError('Please enter all credentials');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String email = identifier;

      // If logging in via phone, fetch the actual email first
      if (!_isEmailMode) {
        if (identifier.length != 10) {
          throw Exception('Please enter a valid 10-digit mobile number');
        }
        email = await _apiService.getEmailByPhone('+91$identifier');
      }

      await _authService.login(email, password);
      if (mounted) {
        // Clear focus
        FocusManager.instance.primaryFocus?.unfocus();

        // EXPLICIT NAVIGATION: Force move to Home Screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Successful'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryBlack : AppTheme.lightBg,
      body: Stack(
        children: [
          if (!Responsive.isMobile(context)) _buildBackground(isDark),
          Center(
            child: Responsive(
              mobile: _buildContent(isDark),
              tablet: GlassBox(
                width: 500,
                child: _buildContent(isDark),
              ),
              desktop: GlassBox(
                width: 450,
                child: _buildContent(isDark),
              ),
            ),
          ),
        ],
      ),
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
              ? [AppTheme.primaryNavy, AppTheme.primaryBlack, const Color(0xFF001F1F)] 
              : [const Color(0xFFE0F2F1), Colors.white, const Color(0xFFF1F8E9)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: AppTheme.primaryEmerald.withOpacity(0.05),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: AppTheme.accentTeal.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: const Icon(Icons.lock_person_rounded, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    L10n.getString(context, 'welcome'),
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 4, 
                      color: isDark ? Colors.white : AppTheme.primaryNavy
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    L10n.getString(context, 'login_subtitle'),
                    style: TextStyle(
                      fontSize: 12, 
                      color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildField(
                    _identifierController, 
                    _isEmailMode ? L10n.getString(context, 'email') : L10n.getString(context, 'mobile_number'), 
                    _isEmailMode ? Icons.email_rounded : Icons.phone_android_rounded,
                    prefix: _isEmailMode ? null : '+91 ',
                    type: _isEmailMode ? TextInputType.emailAddress : TextInputType.number,
                    formatters: _isEmailMode ? null : [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    suffix: IconButton(
                      icon: Icon(_isEmailMode ? Icons.phone_android_rounded : Icons.email_rounded, size: 18, color: AppTheme.accentTeal),
                      onPressed: () {
                        setState(() {
                          _isEmailMode = !_isEmailMode;
                          _identifierController.clear();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    _passwordController,
                    L10n.getString(context, 'password'),
                    Icons.key_rounded,
                    isPass: true,
                    isVisible: _isPasswordVisible,
                    onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(L10n.getString(context, 'login_button'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    ),
                    child: Text(
                      L10n.getString(context, 'forgot_password'),
                      style: TextStyle(color: isDark ? Colors.white38 : AppTheme.primaryNavy.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        L10n.getString(context, 'signup_link'), 
                        style: TextStyle(
                          color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.bold
                        )
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        ),
                        child: Text(
                          L10n.getString(context, 'signup_button').toUpperCase(), 
                          style: const TextStyle(
                            color: AppTheme.accentTeal, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1
                          )
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPass = false,
    bool isVisible = false,
    String? prefix,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatters,
    Widget? suffix,
    VoidCallback? onToggle,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: isPass && !isVisible,
      keyboardType: type,
      inputFormatters: formatters,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixText: prefix,
        prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryNavy),
        prefixIcon: Icon(icon, size: 18, color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryNavy),
        suffixIcon: suffix ?? (isPass
            ? IconButton(
                icon: Icon(isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.2)),
                onPressed: onToggle,
              )
            : null),
        hintText: hint.toUpperCase(),
        hintStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.02) : AppTheme.primaryNavy.withOpacity(0.02),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }
}
