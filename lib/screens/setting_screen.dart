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

  void _showTermsAndConditions(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('Terms & Conditions'),
            leading: CupertinoNavigationBarBackButton(
              onPressed: () => Navigator.pop(context),
              color: CupertinoColors.black,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About This Project',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This application was developed by BSIT students as part of their final project requirements. '
                        'The purpose of this project is purely educational, demonstrating the skills and knowledge '
                        'acquired during our studies in mobile application development.',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '1. Educational Purpose Only\n\n'
                        'This application is developed for educational purposes only. It is not intended for commercial use or real-world financial transactions.\n\n'
                        '2. No Real Financial Data\n\n'
                        'All financial data shown in this application is simulated. Do not enter real banking information or expect real financial services.\n\n'
                        '3. No Warranty\n\n'
                        'This application is provided "as is" without any warranties of any kind. The developers make no guarantees about the accuracy or reliability of the information presented.\n\n'
                        '4. Data Privacy\n\n'
                        'While we implement basic security measures, this application should not be considered secure for sensitive personal data. Do not store real personal information in this app.\n\n'
                        '5. Limitation of Liability\n\n'
                        'The developers shall not be liable for any damages resulting from the use of this application, as it is purely for educational demonstration.\n\n'
                        '6. Changes to Terms\n\n'
                        'These terms may be modified at any time without notice, as this is a student project under development.\n\n'
                        '7. Acceptance of Terms\n\n'
                        'By using this application, you acknowledge that this is a student project and agree to these terms and conditions.',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Development Team',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Christian Caparra\nMichael Deramos\nJhuniel Galang\nJohn Lloyd Guevarra\nSamuel Miranda',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      '© ${DateTime.now().year} BSIT Student Project',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.destructiveRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: CupertinoColors.white,
            child: Icon(CupertinoIcons.person_fill,
                size: 30, color: CupertinoColors.destructiveRed),
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
        style: const TextStyle(
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
                color: iconColor?.withOpacity(0.2) ??
                    CupertinoColors.systemBlue.withOpacity(0.2),
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
                      style: const TextStyle(
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

            _buildSectionHeader('SUPPORT'),
            _buildSettingItem(
              icon: CupertinoIcons.doc_text_fill,
              title: 'Terms & Conditions',
              iconColor: CupertinoColors.systemGrey2,
              onTap: () => _showTermsAndConditions(context),
            ),

            _buildSectionHeader('APP'),
            _buildSettingItem(
              icon: CupertinoIcons.arrow_2_circlepath,
              title: 'App Version',
              subtitle: '1.0.0',
              iconColor: CupertinoColors.systemPink,
              showChevron: false,
              onTap: () {
                showCupertinoDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return CupertinoAlertDialog(
                      title: const Text('Team Members'),
                      content: const Text('Christian Caparra\nMichael Deramos\nJhuniel Galang\nJohn Lloyd Guevarra\nSamuel Miranda'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    );
                  },
                );
              },
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