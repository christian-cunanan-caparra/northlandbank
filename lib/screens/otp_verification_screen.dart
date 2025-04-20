// otp_verification_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OtpVerificationScreen extends StatefulWidget {
  final String cardNumber;
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.cardNumber,
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isLoading = false;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;

  Future<void> _verifyOtpAndResetPin() async {
    final otp = _otpController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (otp.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
      _showAlert('Error', 'Please fill all fields');
      return;
    }

    if (newPin.length != 6 || confirmPin.length != 6) {
      _showAlert('Error', 'PIN must be 6 digits');
      return;
    }

    if (newPin != confirmPin) {
      _showAlert('Error', 'PINs do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://warehousemanagementsystem.shop/api/verify_otp_and_reset_pin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'card_number': widget.cardNumber,
          'email': widget.email,
          'otp': otp,
          'new_pin': newPin,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        _showAlert('Success', 'PIN reset successfully', popAfter: true);
      } else {
        _showAlert('Error', data['message']);
      }
    } catch (e) {
      _showAlert('Error', 'Failed to connect to server. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://warehousemanagementsystem.shop/api/send_otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'card_number': widget.cardNumber,
          'email': widget.email,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        _showAlert('Success', 'New OTP sent to your email');
      } else {
        _showAlert('Error', data['message']);
      }
    } catch (e) {
      _showAlert('Error', 'Failed to resend OTP. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAlert(String title, String message, {bool popAfter = false}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              if (popAfter) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Reset PIN'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Enter OTP sent to your email',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: _otpController,
                placeholder: 'OTP (6 digits)',
                keyboardType: TextInputType.number,
                maxLength: 6,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey5),
                ),
              ),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: _newPinController,
                placeholder: 'New PIN (6 digits)',
                obscureText: _obscureNewPin,
                keyboardType: TextInputType.number,
                maxLength: 6,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey5),
                ),
                suffix: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    _obscureNewPin ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPin = !_obscureNewPin;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              CupertinoTextField(
                controller: _confirmPinController,
                placeholder: 'Confirm New PIN',
                obscureText: _obscureConfirmPin,
                keyboardType: TextInputType.number,
                maxLength: 6,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey5),
                ),
                suffix: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    _obscureConfirmPin ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPin = !_obscureConfirmPin;
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),
              CupertinoButton.filled(
                child: _isLoading
                    ? const CupertinoActivityIndicator()
                    : const Text('Reset PIN'),
                onPressed: _isLoading ? null : _verifyOtpAndResetPin,
              ),
              const SizedBox(height: 20),
              CupertinoButton(
                child: const Text('Resend OTP'),
                onPressed: _isLoading ? null : _resendOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}