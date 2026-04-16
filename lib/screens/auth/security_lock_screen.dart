import 'package:flutter/material.dart';
import '../../services/security_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/l10n.dart';
import '../main_navigation_screen.dart';
import 'package:flutter/services.dart';

class SecurityLockScreen extends StatefulWidget {
  final bool isSetup; // True if setting up PIN, False if unlocking
  const SecurityLockScreen({super.key, this.isSetup = false});

  @override
  State<SecurityLockScreen> createState() => _SecurityLockScreenState();
}

class _SecurityLockScreenState extends State<SecurityLockScreen> {
  final SecurityService _securityService = SecurityService();
  String _enteredPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _message = widget.isSetup ? 'Set a 4-digit PIN' : 'Enter your PIN';
    if (!widget.isSetup) {
      _checkBiometrics();
    }
  }

  Future<void> _checkBiometrics() async {
    final available = await _securityService.isBiometricAvailable();
    if (available) {
      final authenticated = await _securityService.authenticateWithBiometrics();
      if (authenticated) {
        _onUnlockSuccess();
      }
    }
  }

  void _onNumberTap(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += number;
      });

      if (_enteredPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _handlePinComplete() async {
    if (widget.isSetup) {
      if (!_isConfirming) {
        _confirmPin = _enteredPin;
        setState(() {
          _enteredPin = '';
          _isConfirming = true;
          _message = 'Confirm your PIN';
        });
      } else {
        if (_enteredPin == _confirmPin) {
          await _securityService.savePin(_enteredPin);
          await _securityService.setLockEnabled(true);
          _onUnlockSuccess();
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _enteredPin = '';
            _message = 'PINs do not match. Try again.';
          });
        }
      }
    } else {
      final isValid = await _securityService.verifyPin(_enteredPin);
      if (isValid) {
        _onUnlockSuccess();
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _enteredPin = '';
          _message = 'Incorrect PIN. Try again.';
        });
      }
    }
  }

  void _onUnlockSuccess() {
    if (!mounted) return;
    if (widget.isSetup) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryBlack : AppTheme.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryEmerald.withOpacity(0.1),
              ),
              child: const Icon(Icons.lock_person_rounded, size: 48, color: AppTheme.primaryEmerald),
            ),
            const SizedBox(height: 24),
            Text(
              _message.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 32),
            
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                bool isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppTheme.primaryEmerald : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? AppTheme.primaryEmerald : (isDark ? Colors.white24 : Colors.black12),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const Spacer(),
            
            // Keypad
            _buildKeypad(),
            
            const SizedBox(height: 40),
            if (!widget.isSetup)
              TextButton.icon(
                onPressed: _checkBiometrics,
                icon: const Icon(Icons.fingerprint_rounded, color: AppTheme.primaryEmerald),
                label: const Text('SCAN BIOMETRIC', style: TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_keyBtn('1'), _keyBtn('2'), _keyBtn('3')],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_keyBtn('4'), _keyBtn('5'), _keyBtn('6')],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_keyBtn('7'), _keyBtn('8'), _keyBtn('9')],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80, height: 80),
            _keyBtn('0'),
            _buildBackspaceBtn(),
          ],
        ),
      ],
    );
  }

  Widget _keyBtn(String text) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _onNumberTap(text),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppTheme.primaryNavy : Colors.white,
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildBackspaceBtn() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _onBackspace,
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(12),
        decoration: const BoxDecoration(shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(Icons.backspace_rounded, color: isDark ? Colors.white24 : Colors.black26),
      ),
    );
  }
}
