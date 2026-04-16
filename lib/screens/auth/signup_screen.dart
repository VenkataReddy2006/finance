import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../main_navigation_screen.dart';
import '../../utils/app_theme.dart';
import '../../utils/l10n.dart';
import '../../utils/responsive.dart';
import '../../widgets/common/glass_box.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _apiService = ApiService();
  
  // Email Verification State
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isOtpSent = false;
  bool _isEmailVerified = false;
  bool _isOtpLoading = false;

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  String? _imageBase64;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryEmerald),
              title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async => Navigator.pop(context, await picker.pickImage(source: ImageSource.camera, maxWidth: 512, maxHeight: 512, imageQuality: 75)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.accentTeal),
              title: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async => Navigator.pop(context, await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 75)),
            ),
          ],
        ),
      ),
    );

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() => _imageBase64 = base64Encode(bytes));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _otpControllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _sendOtp() async {
    String email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() => _isOtpLoading = true);
    try {
      await _apiService.sendSignupOtp(email);
      if (mounted) {
        setState(() {
          _isOtpSent = true;
          _isOtpLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent!'), 
            backgroundColor: Color(0xFF004D40), // Dark Teal
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String error = e.toString().replaceAll('Exception: ', '');
        if (error.contains('TimeoutException') || error.contains('Future not completed')) {
          _showError('Connection timed out. Please ensure the backend server is running and your internet is stable.');
        } else {
          _showError(error);
        }
        setState(() => _isOtpLoading = false);
      }
    }
  }

  void _verifyOtp() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) return;

    setState(() => _isOtpLoading = true);
    try {
      await _apiService.verifySignupOtp(_emailController.text.trim(), otp);
      if (mounted) {
        setState(() {
          _isEmailVerified = true;
          _isOtpLoading = false;
        });
        FocusManager.instance.primaryFocus?.unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
        setState(() => _isOtpLoading = false);
        for (var c in _otpControllers) { c.clear(); }
        _focusNodes[0].requestFocus();
      }
    }
  }

  void _signup() async {
    if (_nameController.text.isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (_phoneController.text.length != 10) {
      _showError('Please enter a valid 10-digit mobile number');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
        '+91${_phoneController.text}',
        profileImage: _imageBase64,
      );
      if (mounted) {
        // EXPLICIT NAVIGATION: Force move to Home Screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup Successful!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) _showError('Signup Failed: ${e.toString()}');
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          if (!Responsive.isMobile(context)) _buildBackground(isDark),
          Center(
            child: Responsive(
              mobile: _buildContent(isDark),
              tablet: GlassBox(
                width: 550,
                child: _buildContent(isDark),
              ),
              desktop: GlassBox(
                width: 500,
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
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: isDark 
              ? [AppTheme.primaryBlack, AppTheme.primaryNavy, const Color(0xFF001F1F)] 
              : [const Color(0xFFE0F2F1), Colors.white, const Color(0xFFF1F8E9)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 200,
            left: -100,
            child: CircleAvatar(
              radius: 180,
              backgroundColor: AppTheme.primaryEmerald.withOpacity(0.05),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: AppTheme.accentTeal.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                image: _imageBase64 != null
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(_imageBase64!)),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryNavy.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _imageBase64 == null
                  ? const Icon(Icons.person_add_rounded, size: 50, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            L10n.getString(context, 'signup_button').toUpperCase(),
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 4, 
              color: isDark ? Colors.white : AppTheme.primaryNavy
            ),
          ),
          const SizedBox(height: 8),
          Text(
            L10n.getString(context, 'signup_subtitle'),
            style: TextStyle(
              fontSize: 12, 
              color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), 
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 40),
          _buildField(_nameController, L10n.getString(context, 'full_name'), Icons.badge_rounded),
          const SizedBox(height: 16),
          _buildField(
            _emailController, 
            L10n.getString(context, 'email'), 
            Icons.email_rounded,
            readOnly: _isEmailVerified,
            suffix: _isEmailVerified
              ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
              : TextButton(
                  onPressed: _isOtpLoading ? null : _sendOtp,
                  child: _isOtpLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isOtpSent ? L10n.getString(context, 'resend') : L10n.getString(context, 'send_otp'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentTeal)),
                ),
          ),
          if (_isOtpSent && !_isEmailVerified) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => _buildOtpField(index, isDark)),
            ),
          ],
          const SizedBox(height: 16),
          _buildField(_phoneController, L10n.getString(context, 'mobile_number'), Icons.phone_android_rounded, 
            prefix: '+91 ', 
            type: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          ),
          const SizedBox(height: 16),
          _buildField(
            _passwordController,
            L10n.getString(context, 'password'),
            Icons.key_rounded,
            isPass: true,
            isVisible: _isPasswordVisible,
            onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          const SizedBox(height: 16),
          _buildField(
            _confirmPasswordController,
            L10n.getString(context, 'confirm_password'),
            Icons.done_all_rounded,
            isPass: true,
            isVisible: _isConfirmVisible,
            onToggle: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEmailVerified ? AppTheme.primaryEmerald : Colors.white10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: (_isLoading || !_isEmailVerified) ? null : _signup,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isEmailVerified ? L10n.getString(context, 'signup_button') : L10n.getString(context, 'verify_email'), 
                      style: TextStyle(
                        color: _isEmailVerified ? Colors.white : Colors.white24, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 2
                      )
                    ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account?", style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(L10n.getString(context, 'login_button'), style: TextStyle(color: AppTheme.accentTeal, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField(int index, bool isDark) {
    return Container(
      width: 40,
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
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
          fontSize: 20, 
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
              _verifyOtp(); // Auto-verify on last digit
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

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPass = false,
    bool isVisible = false,
    bool readOnly = false,
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
      readOnly: readOnly,
      keyboardType: type,
      inputFormatters: formatters,
      style: TextStyle(fontWeight: FontWeight.bold, color: readOnly ? Colors.white38 : null),
      decoration: InputDecoration(
        prefixText: prefix,
        prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryNavy),
        prefixIcon: Icon(icon, size: 18, color: isDark ? AppTheme.primaryEmerald : AppTheme.primaryNavy),
        suffixIcon: suffix ?? (isPass
            ? IconButton(
                icon: Icon(isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: Colors.white24),
                onPressed: onToggle,
              )
            : null),
        hintText: hint.toUpperCase(),
        hintStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }
}
