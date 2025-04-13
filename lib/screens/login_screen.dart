import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final cardNumber = _cardNumberController.text.trim();
    final pin = _pinController.text.trim();

    if (cardNumber.isEmpty || pin.isEmpty) {
      _showAlert('Error', 'Please enter both card number and PIN');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.25/api/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'card_number': cardNumber,
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        final user = User.fromJson(data['user']);
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => DashboardScreen(user: user),
          ),
        );
      } else {
        _showAlert('Login Failed', data['message']);
      }
    } catch (e) {
      _showAlert('Error', 'Failed to connect to server: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // BPI Logo Placeholder
                Image.asset(
                  'images/bpi.png', // Replace with your actual logo asset
                  height: 120,
                ),

                const SizedBox(height: 60),

                // Card Number (Username) Field
                CupertinoTextField(
                  controller: _cardNumberController,
                  placeholder: 'Card Number',
                  placeholderStyle: const TextStyle(color: CupertinoColors.systemRed),
                  keyboardType: TextInputType.number,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: CupertinoColors.systemRed, width: 2),
                    ),
                  ),
                  style: const TextStyle(color: CupertinoColors.black),
                ),

                const SizedBox(height: 30),

                // PIN Field
                CupertinoTextField(
                  controller: _pinController,
                  placeholder: 'PIN',
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  placeholderStyle: const TextStyle(color: CupertinoColors.systemRed),
                  suffix: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(
                      _obscurePin ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                      color: CupertinoColors.systemGrey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePin = !_obscurePin;
                      });
                    },
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: CupertinoColors.systemRed, width: 2),
                    ),
                  ),
                  style: const TextStyle(color: CupertinoColors.black),
                ),

                const SizedBox(height: 40),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: CupertinoColors.systemRed,
                    borderRadius: BorderRadius.circular(40),
                    child: _isLoading
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text(
                      'Login',
                      style: TextStyle(color: CupertinoColors.white),
                    ),
                    onPressed: _isLoading ? null : _login,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
