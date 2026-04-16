import 'dart:convert';
// Removed dart:io as it breaks on Web. Using universal XFile instead.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/finance_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';
import '../utils/app_theme.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/language_selection_screen.dart';
import '../screens/settings/change_password_screen.dart';
import 'settings_tab.dart';
import '../utils/l10n.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ApiService _apiService = ApiService();
  String? _imageBase64;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCachedImage();
  }

  void _loadCachedImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cached = HiveService.settingsBox.get('profile_image_${user.uid}');
    if (cached != null) {
      setState(() => _imageBase64 = cached);
    } else {
      // If not in cache, try fetching from backend
      try {
        final response = await _apiService.getUserProfile(user.uid);
        if (response != null && response['profileImage'] != null) {
          final img = response['profileImage'];
          await HiveService.settingsBox.put('profile_image_${user.uid}', img);
          if (mounted) setState(() => _imageBase64 = img);
        }
      } catch (e) {
        debugPrint('Error fetching profile from backend: $e');
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final base64 = base64Encode(bytes);
        
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _apiService.updateProfileImage(user.uid, base64);
          await HiveService.settingsBox.put('profile_image_${user.uid}', base64);
          setState(() => _imageBase64 = base64);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile image updated!'), backgroundColor: AppTheme.primaryEmerald),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.accentRed),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildSourceOption(
              icon: Icons.camera_alt_rounded,
              title: 'Camera',
              subtitle: 'Take a new photo',
              color: AppTheme.primaryEmerald,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            _buildSourceOption(
              icon: Icons.photo_library_rounded,
              title: 'Gallery',
              subtitle: 'Choose from your library',
              color: AppTheme.accentTeal,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : AppTheme.primaryNavy)),
      subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final financeProvider = Provider.of<FinanceProvider>(context);
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // Profile Header
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _isUploading ? null : () => _showImageSourceActionSheet(context),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                        image: (_imageBase64 != null && _imageBase64!.isNotEmpty)
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
                      child: (_imageBase64 == null || _imageBase64!.isEmpty)
                          ? const Icon(Icons.person_rounded, size: 50, color: Colors.white)
                          : null,
                    ),
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryEmerald, strokeWidth: 2),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryEmerald,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppTheme.primaryBlack : Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.displayName?.toUpperCase() ?? user?.email?.split('@')[0].toUpperCase() ?? 'USER',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              Text(
                user?.email ?? 'Not logged in',
                style: TextStyle(color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        
        Text(
          'ACCOUNT OVERVIEW',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        
        // Stats Row
        Row(
          children: [
            _buildStatCard(L10n.getString(context, 'groups'), financeProvider.groups.length.toString(), AppTheme.primaryEmerald, isDark),
            const SizedBox(width: 12),
            _buildStatCard(L10n.getString(context, 'people'), financeProvider.people.length.toString(), AppTheme.accentGold, isDark),
          ],
        ),
        
        const SizedBox(height: 32),
        Text(
          'SESSION',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), letterSpacing: 2),
        ),
        const SizedBox(height: 16),

        _buildActionTile(
          context,
          Icons.logout_rounded,
          L10n.getString(context, 'logout'),
          'Sign out of your account',
          AppTheme.accentRed,
          () async {
            bool? confirm = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(L10n.getString(context, 'logout')),
                content: Text(L10n.getString(context, 'confirm_logout')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text(L10n.getString(context, 'logout'), style: const TextStyle(color: AppTheme.accentRed))),
                ],
              ),
            );
            if (confirm == true) {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : AppTheme.primaryNavy.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, String subtitle, Color iconColor, VoidCallback onTap) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.primaryNavy : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : AppTheme.primaryNavy.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : AppTheme.primaryNavy)),
        subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white24 : AppTheme.primaryNavy.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold)),
        trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white10 : AppTheme.primaryNavy.withOpacity(0.2)),
        onTap: onTap,
      ),
    );
  }
}
