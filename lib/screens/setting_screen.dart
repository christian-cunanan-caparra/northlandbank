import 'package:flutter/cupertino.dart';
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoButton(
              padding: const EdgeInsets.all(16),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => ChangePinScreen(user: user),
                  ),
                );
              },
              child: const Text('Change PIN'),
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(16),
              onPressed: () => _confirmLogout(context),
              child: const Text('Logout', style: TextStyle(color: CupertinoColors.systemRed)),
            ),
          ],
        ),
      ),
    );
  }
}
