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
      await Future.delayed(const Duration(milliseconds: 300));
      _showAlert('Error', 'Please enter both card number and PIN');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://warehousemanagementsystem.shop/api/login.php'),
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
        await Future.delayed(const Duration(milliseconds: 300));
        _showAlert('Login Failed', data['message']);
      }
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 300));
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
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

                // Logo
                Image.asset(
                  'images/bpi.png',
                  height: 100,
                ),

                const SizedBox(height: 20),

                // Welcome Text
                const Text(
                  'Welcome to BPI',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemRed,
                  ),
                ),

                const SizedBox(height: 50),

                // Card Number Field
                CupertinoTextField(
                  controller: _cardNumberController,
                  placeholder: 'Card Number',
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  style: const TextStyle(color: CupertinoColors.black),
                ),

                const SizedBox(height: 20),

                // PIN Field
                CupertinoTextField(
                  controller: _pinController,
                  placeholder: 'PIN',
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  style: const TextStyle(color: CupertinoColors.black),
                ),

                const SizedBox(height: 40),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    borderRadius: BorderRadius.circular(30),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(color: CupertinoColors.black)
                        : const Text(
                      'Log in',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Optional: Forgot PIN
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text(
                    'Forgot your PIN?',
                    style: TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    // Handle forgot PIN
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
