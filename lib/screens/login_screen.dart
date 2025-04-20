import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'otp_verification_screen.dart';
import '../models/user.dart';
import 'dart:async';
import 'dashboard_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  final FocusNode _cardNumberFocus = FocusNode();
  final FocusNode _pinFocus = FocusNode();

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final cardNumber = _cardNumberController.text.trim().replaceAll(' ', '');
    final pin = _pinController.text.trim();

    if (cardNumber.isEmpty || pin.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      _showAlert('Error', 'Please enter both card number and PIN');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (cardNumber.length != 16) {
      await Future.delayed(const Duration(milliseconds: 300));
      _showAlert('Error', 'Card number must be 16 digits');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (pin.length != 6) {
      await Future.delayed(const Duration(milliseconds: 300));
      _showAlert('Error', 'PIN must be 6 digits');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Check internet connection first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      await Future.delayed(const Duration(milliseconds: 300));
      _showAlert('Error', 'No internet connection');
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
      _showAlert('Error', 'Failed to connect to server. Please try again.');
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

  // In your login_screen.dart
  void _handleForgotPin() async {
    final cardNumber = _cardNumberController.text.trim().replaceAll(' ', '');

    if (cardNumber.isEmpty || cardNumber.length != 16) {
      _showAlert('Error', 'Please enter a valid 16-digit card number first');
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showAlert('Error', 'No internet connection');
      return;
    }

    final emailController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isSending = false;

          return CupertinoAlertDialog(
            title: const Text('Reset PIN'),
            content: Column(
              children: [
                const Text('Enter your registered email to receive an OTP'),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: emailController,
                  placeholder: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                if (isSending) const SizedBox(height: 16),
               if (isSending) const CupertinoActivityIndicator(),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
               onPressed: isSending ? null : () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                child: const Text('Send OTP'),
                onPressed: isSending ? null : () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty || !email.contains('@')) {
                    _showAlert('Error', 'Please enter a valid email');
                    return;
                  }

                  setState(() => isSending = true);

                  try {
                    final response = await http.post(
                      Uri.parse('https://warehousemanagementsystem.shop/api/send_otp.php'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'card_number': cardNumber,
                        'email': email,
                      }),
                    ).timeout(const Duration(seconds: 30));

                    final data = jsonDecode(response.body);

                    if (!context.mounted) return;

                    Navigator.pop(context);

                    if (data['success']) {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => OtpVerificationScreen(
                            cardNumber: cardNumber,
                            email: email,
                          ),
                        ),
                      );
                    } else {
                      _showAlert('Error', data['message'] ?? 'Failed to send OTP');
                    }
                  } on TimeoutException catch (_) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _showAlert('Error', 'Request timed out. Please try again.');
                  } on http.ClientException catch (e) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _showAlert('Error', 'Network error: ${e.message}');
                  } catch (e) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _showAlert('Error', 'Failed to send OTP: ${e.toString()}');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _formatCardNumber() {
    final text = _cardNumberController.text.replaceAll(' ', '');
    if (text.length > 16) {
      _cardNumberController.text = text.substring(0, 16);
      _cardNumberController.selection = TextSelection.fromPosition(
        TextPosition(offset: _cardNumberController.text.length),
      );
      return;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }
    final formattedText = buffer.toString();

    if (_cardNumberController.text != formattedText) {
      _cardNumberController.text = formattedText;
      _cardNumberController.selection = TextSelection.fromPosition(
        TextPosition(offset: _cardNumberController.text.length),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_formatCardNumber);
  }

  @override
  void dispose() {
    _cardNumberController.removeListener(_formatCardNumber);
    _cardNumberController.dispose();
    _pinController.dispose();
    _cardNumberFocus.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.extraLightBackgroundGray,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Logo
                Image.asset(
                  'images/bpi.png',
                  height: 120,
                ),
                const SizedBox(height: 30),
                // Welcome Text
                const Text(
                  'Welcome to BPI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.systemRed,
                  ),
                ),
                const SizedBox(height: 50),
                // Card Number Field
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CupertinoTextField(
                    controller: _cardNumberController,
                    focusNode: _cardNumberFocus,
                    placeholder: 'Card Number (XXXX XXXX XXXX XXXX)',
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.systemGrey,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _cardNumberFocus.hasFocus
                            ? CupertinoColors.systemRed
                            : CupertinoColors.systemGrey5,
                        width: 1.5,
                      ),
                    ),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(
                        CupertinoIcons.creditcard_fill,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                    ),
                    style: const TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 16,
                    ),
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_pinFocus);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // PIN Field
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CupertinoTextField(
                    controller: _pinController,
                    focusNode: _pinFocus,
                    placeholder: 'PIN (6 digits)',
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.systemGrey,
                    ),
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _pinFocus.hasFocus
                            ? CupertinoColors.systemRed
                            : CupertinoColors.systemGrey5,
                        width: 1.5,
                      ),
                    ),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(
                        CupertinoIcons.lock_fill,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                    ),
                    suffix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        _obscurePin ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePin = !_obscurePin;
                        });
                      },
                    ),
                    style: const TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 16,
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                ),
                const SizedBox(height: 10),
                // Forgot PIN button (centered)
                Center(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Forgot your PIN?',
                      style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: _handleForgotPin,
                  ),
                ),
                const SizedBox(height: 40),
                // Login Button (red)
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: CupertinoColors.systemRed,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    borderRadius: BorderRadius.circular(30),
                    disabledColor: CupertinoColors.systemRed.withOpacity(0.5),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    ),
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