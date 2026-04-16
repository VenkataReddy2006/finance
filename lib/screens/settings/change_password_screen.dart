import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../auth/forgot_password_screen.dart';
import '../main_navigation_screen.dart';
import '../../utils/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isOldVisible = false;
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;

  void _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_oldPasswordController.text.isEmpty) {
      _showError('Please enter your current password');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showError('New password must be at least 6 characters');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.changePassword(
        user.uid,
        _oldPasswordController.text,
        _newPasswordController.text,
      );
      if (mounted) {
        _showSuccess('Password changed successfully!');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          (route) => false,
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

  void _forgotPasswordInSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() => _isLoading = true);
    try {
      // Trigger OTP immediately for current user
      await _apiService.sendForgotPasswordOtp(user.email!);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPasswordScreen(
              initialEmail: user.email,
              initialStep: 2, // Skip Step 1
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryBlack : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('CHANGE PASSWORD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildField(
              _oldPasswordController,
              'Current Password',
              Icons.lock_person_rounded,
              isPass: true,
              isVisible: _isOldVisible,
              onToggle: () => setState(() => _isOldVisible = !_isOldVisible),
            ),
            const SizedBox(height: 20),
            _buildField(
              _newPasswordController,
              'New Password',
              Icons.key_rounded,
              isPass: true,
              isVisible: _isNewVisible,
              onToggle: () => setState(() => _isNewVisible = !_isNewVisible),
            ),
            const SizedBox(height: 20),
            _buildField(
              _confirmPasswordController,
              'Confirm New Password',
              Icons.lock_open_rounded,
              isPass: true,
              isVisible: _isConfirmVisible,
              onToggle: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
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
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('UPDATE PASSWORD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'OR',
              style: TextStyle(color: Colors.white10, fontWeight: FontWeight.w900, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _forgotPasswordInSettings,
              child: const Text(
                'I forgot my current password',
                style: TextStyle(color: AppTheme.accentTeal, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPass = false,
    bool isVisible = false,
    VoidCallback? onToggle,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: isPass && !isVisible,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: AppTheme.primaryEmerald),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: Colors.white24),
                onPressed: onToggle,
              )
            : null,
        hintText: hint.toUpperCase(),
        hintStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }
}
