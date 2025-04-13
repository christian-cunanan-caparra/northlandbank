import 'package:flutter/cupertino.dart';
//import 'package:flutter/services.dart';
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('ATM Login'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoTextField(
                controller: _cardNumberController,
                placeholder: 'Card Number',
                keyboardType: TextInputType.number,
                maxLength: 16,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _pinController,
                placeholder: 'PIN',
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 32),
              CupertinoButton.filled(
                child: _isLoading
                    ? const CupertinoActivityIndicator()
                    : const Text('Login'),
                onPressed: _isLoading ? null : _login,
              ),
            ],
          ),
        ),
      ),
    );
  }
}