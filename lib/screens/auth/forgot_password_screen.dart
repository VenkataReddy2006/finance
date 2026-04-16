import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../main_navigation_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  final int initialStep;

  const ForgotPasswordScreen({
    super.key, 
    this.initialEmail,
    this.initialStep = 1,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();

  late int _currentStep; // 1: Email, 2: OTP, 3: Reset
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Timer for Resend OTP
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
    if (_currentStep == 2) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _canResend = false;
      _secondsRemaining = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _sendOtp() async {
    String email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.sendForgotPasswordOtp(email);
      if (mounted) {
        setState(() {
          _currentStep = 2;
          _isLoading = false;
        });
        _startTimer();
        _showSuccess('Verification code sent to $email');
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
        setState(() => _isLoading = false);
      }
    }
  }

  void _verifyOtp() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _showError('Please enter the 6-digit code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.verifyForgotPasswordOtp(
        _emailController.text.trim(),
        otp,
      );
      if (mounted) {
        setState(() {
          _currentStep = 3;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetPassword() async {
    if (_newPasswordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String otp = _otpControllers.map((c) => c.text).join();
      await _apiService.resetPassword(
        _emailController.text.trim(),
        otp,
        _newPasswordController.text,
      );
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _showSuccess('Password reset successful!');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (route) => false,
          );
        } else {
          _showSuccess('Password reset successful! Please login.');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.greenAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.primaryBlack
          : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 48),
              if (_currentStep == 1) _buildStep1(isDark),
              if (_currentStep == 2) _buildStep2(isDark),
              if (_currentStep == 3) _buildStep3(isDark),
              const SizedBox(height: 48),
              _buildButton(),
              if (_currentStep == 2) _buildResendButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    IconData icon = Icons.email_outlined;
    String title = "FORGOT PASSWORD";
    String subtitle = "Enter your email to receive a reset code";

    if (_currentStep == 2) {
      icon = Icons.mark_email_read_rounded;
      title = "VERIFY EMAIL";
      subtitle = "Enter the 6-digit code sent to ${_emailController.text}";
    } else if (_currentStep == 3) {
      icon = Icons.lock_open_rounded;
      title = "NEW PASSWORD";
      subtitle = "Set a secure password for your account";
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
          ),
          child: Icon(icon, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 32),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: isDark ? Colors.white : AppTheme.primaryNavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(bool isDark) {
    return _buildField(
      _emailController,
      'Email Address',
      Icons.email_rounded,
      type: TextInputType.emailAddress,
    );
  }

  Widget _buildStep2(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) => _buildOtpField(index, isDark)),
    );
  }

  Widget _buildOtpField(int index, bool isDark) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 24, 
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
      ),
    );
  }

  Widget _buildStep3(bool isDark) {
    return Column(
      children: [
        _buildField(
          _newPasswordController,
          'New Password',
          Icons.key_rounded,
          isPass: true,
          obscureText: _obscureNewPassword,
          onToggleVisibility: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
        ),
        const SizedBox(height: 20),
        _buildField(
          _confirmPasswordController,
          'Confirm Password',
          Icons.key_outlined,
          isPass: true,
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ],
    );
  }

  Widget _buildButton() {
    String label = "SEND CODE";
    VoidCallback action = _sendOtp;

    if (_currentStep == 2) {
      label = "VERIFY CODE";
      action = _verifyOtp;
    } else if (_currentStep == 3) {
      label = "RESET PASSWORD";
      action = _resetPassword;
    }

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryEmerald,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: _isLoading ? null : action,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }

  Widget _buildResendButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextButton(
        onPressed: _canResend ? _sendOtp : null,
        child: Text(
          _canResend ? "RESEND CODE" : "RESEND IN ${_secondsRemaining}S",
          style: TextStyle(
            color: _canResend ? AppTheme.accentTeal : Colors.white24,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPass = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType type = TextInputType.text,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: isPass ? obscureText : false,
      keyboardType: type,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: AppTheme.primaryEmerald),
        suffixIcon: isPass 
          ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18,
                color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.2),
              ),
              onPressed: onToggleVisibility,
            )
          : null,
        hintText: hint.toUpperCase(),
        hintStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
