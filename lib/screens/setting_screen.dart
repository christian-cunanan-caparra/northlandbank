import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import 'change_pin_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  final User user;

  const SettingsScreen({super.key, required this.user});

  void _confirmLogout(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Clear session data

                Navigator.of(context).pushAndRemoveUntil(
                  CupertinoPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: CupertinoColors.white,
            child: Icon(CupertinoIcons.person_fill,
                size: 30,
                color: CupertinoColors.systemBlue),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: CupertinoColors.systemGrey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.systemGrey5,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor?.withOpacity(0.2) ?? CupertinoColors.systemBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? CupertinoColors.systemBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Settings'),
        backgroundColor: CupertinoColors.systemBlue,
        brightness: Brightness.dark,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildHeader(),
            ),

            _buildSectionHeader('ACCOUNT SETTINGS'),
            _buildSettingItem(
              icon: CupertinoIcons.lock_fill,
              title: 'Change PIN',
              iconColor: CupertinoColors.systemGreen,
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => ChangePinScreen(user: user),
                  ),
                );
              },
            ),
            _buildSettingItem(
              icon: CupertinoIcons.bell_fill,
              title: 'Notifications',
              subtitle: 'Manage your alerts',
              iconColor: CupertinoColors.systemRed,
              onTap: () {
                // Navigate to notifications settings
              },
            ),
            _buildSettingItem(
              icon: CupertinoIcons.creditcard_fill,
              title: 'Linked Accounts',
              subtitle: '2 accounts linked',
              iconColor: CupertinoColors.systemPurple,
              onTap: () {
                // Navigate to linked accounts
              },
            ),

            _buildSectionHeader('SECURITY'),
            _buildSettingItem(
              icon: CupertinoIcons.shield_fill,
              title: 'Security Center',
              iconColor: CupertinoColors.systemOrange,
              onTap: () {
                // Navigate to security center
              },
            ),
            _buildSettingItem(
              icon: CupertinoIcons.lock,
              title: 'Biometric Login',
              subtitle: 'Enabled',
              iconColor: CupertinoColors.systemIndigo,
              onTap: () {
                // Toggle biometric login
              },
            ),

            _buildSectionHeader('SUPPORT'),
            _buildSettingItem(
              icon: CupertinoIcons.question_circle_fill,
              title: 'Help Center',
              iconColor: CupertinoColors.systemYellow,
              onTap: () {
                // Navigate to help center
              },
            ),
            _buildSettingItem(
              icon: CupertinoIcons.chat_bubble_fill,
              title: 'Contact Us',
              iconColor: CupertinoColors.systemTeal,
              onTap: () {
                // Navigate to contact us
              },
            ),
            _buildSettingItem(
              icon: CupertinoIcons.doc_text_fill,
              title: 'Terms & Conditions',
              iconColor: CupertinoColors.systemGrey2,
              onTap: () {
                // Show terms and conditions
              },
            ),

            _buildSectionHeader('APP'),
            _buildSettingItem(
              icon: CupertinoIcons.moon_fill,
              title: 'Dark Mode',
              subtitle: 'System default',
              iconColor: CupertinoColors.systemGrey2,
              onTap: () {
                // Toggle dark mode
              },
            ),
            _buildSettingItem(
              icon: CupertinoIcons.arrow_2_circlepath,
              title: 'App Version',
              subtitle: '1.2.3 (Latest)',
              iconColor: CupertinoColors.systemPink,
              showChevron: false,
              onTap: () {},
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoButton(
                color: CupertinoColors.systemRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: () => _confirmLogout(context),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: CupertinoColors.systemRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}