import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ChangePinScreen extends StatefulWidget {
  final User user;

  const ChangePinScreen({super.key, required this.user});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  String? _errorMessage;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resendTimer = 60;
    });

    try {
      final response = await http.post(
        Uri.parse('https://warehousemanagementsystem.shop/api/send_otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'card_number': widget.user.cardNumber,
          'email': widget.user.email,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = _parseResponse(response);

      if (data['success'] == true) {
        _startResendTimer();
        _showAlert('Success', 'OTP sent to ${widget.user.email}');
        setState(() => _otpSent = true);
      } else {
        throw Exception(data['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      _handleError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _otpController.text.trim();

    if (enteredOtp.isEmpty || enteredOtp.length != 6) {
      _showAlert('Error', 'Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://warehousemanagementsystem.shop/api/verify_otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'card_number': widget.user.cardNumber,
          'otp': enteredOtp,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          setState(() => _otpVerified = true);
          _showAlert('Success', 'OTP verified successfully');
        } else {
          _showAlert('Error', data['message'] ?? 'OTP verification failed');
        }
      } else if (response.statusCode == 500) {
        _showAlert('Error', data['message'] ?? 'Invalid or expired OTP');
      } else {
        throw Exception('Unexpected response: ${response.statusCode}');
      }
    } on TimeoutException {
      _showAlert('Error', 'Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      _showAlert('Error', 'Network error: ${e.message}');
    } catch (e) {
      _showAlert('Error', 'An unexpected error occurred: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePin() async {
    if (!_otpVerified) {
      _showAlert('Error', 'Please verify OTP first');
      return;
    }

    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
      _showAlert('Error', 'Please fill all fields');
      return;
    }

    if (newPin != confirmPin) {
      _showAlert('Error', 'New PINs do not match');
      return;
    }

    if (newPin.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(newPin)) {
      _showAlert('Error', 'PIN must be 6 digits');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://warehousemanagementsystem.shop/api/update_pin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'card_number': widget.user.cardNumber,
          'current_pin': currentPin,
          'new_pin': newPin,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = _parseResponse(response);

      if (data['success'] == true) {
        _showAlert('Success', 'PIN changed successfully', onDismiss: () {
          _resetScreen();
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to update PIN');
      }
    } catch (e) {
      _handleError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetScreen() {
    _currentPinController.clear();
    _newPinController.clear();
    _confirmPinController.clear();
    _otpController.clear();

    setState(() {
      _otpSent = false;
      _otpVerified = false;
      _errorMessage = null;
      _resendTimer = 60;
    });
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw HttpException('Request failed with status: ${response.statusCode}');
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('Invalid server response format');
    }
  }

  void _handleError(dynamic e) {
    String message;

    if (e is SocketException) {
      message = 'Please check your internet connection';
    } else if (e is TimeoutException) {
      message = 'Server is taking too long to respond';
    } else if (e is HttpException) {
      message = 'Server error: ${e.message}';
    } else if (e is FormatException) {
      message = 'Invalid server response';
    } else {
      message = 'An unexpected error occurred: ${e.toString()}';
    }

    setState(() => _errorMessage = message);
    _showAlert('Error', message);
  }

  void _startResendTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  void _showAlert(String title, String message, {VoidCallback? onDismiss}) {
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
              onDismiss?.call();
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
        middle: Text('Change PIN'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CupertinoColors.systemRed.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_circle_fill,
                          color: CupertinoColors.systemRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildOtpSection(),
              _buildPinChangeSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpSection() {
    if (!_otpSent) {
      return Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.extraLightBackgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(CupertinoIcons.mail_solid, size: 48, color: CupertinoColors.activeBlue),
                const SizedBox(height: 16),
                const Text(
                  'We will send a verification code to your registered email address',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.user.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(8),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading
                      ? const CupertinoActivityIndicator()
                      : const Text(
                    'Send Verification Code',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (!_otpVerified) {
      return Column(
          children: [
          const SizedBox(height: 20),
    Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: CupertinoColors.extraLightBackgroundGray,
    borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
    children: [
    const Icon(CupertinoIcons.lock_fill, size: 48, color: CupertinoColors.activeGreen),
    const SizedBox(height: 16),
    const Text(
    'Enter the 6-digit verification code sent to:',
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 16),
    ),
    const SizedBox(height: 8),
    Text(
    widget.user.email,
    textAlign: TextAlign.center,
    style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: CupertinoColors.activeBlue,
    ),
    ),
    const SizedBox(height: 24),
    CupertinoTextField(
    controller: _otpController,
    placeholder: 'Enter 6-digit code',
    keyboardType: TextInputType.number,
    maxLength: 6,
    padding: const EdgeInsets.all(16),
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 24, letterSpacing: 4),
    decoration: BoxDecoration(
    color: CupertinoColors.white,
    border: Border.all(color: CupertinoColors.systemGrey),
    borderRadius: BorderRadius.circular(8),
    ),
    ),
    const SizedBox(height: 16),
    CupertinoButton.filled(
    borderRadius: BorderRadius.circular(8),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    onPressed: _isLoading ? null : _verifyOtp,
    child: _isLoading
    ? const CupertinoActivityIndicator()
        : const Text(
    'Verify Code',
    style: TextStyle(fontSize: 16),
    ),
    ),
    const SizedBox(height: 16),
    if (_resendTimer > 0)
    Text(
    'You can resend code in $_resendTimer seconds',
    style: const TextStyle(color: CupertinoColors.systemGrey),
    )
    else
    CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: _sendOtp,
    child: const Text(
    'Resend Verification Code',
    style: TextStyle(color: CupertinoColors.activeBlue),
    ),
    )],
    ),
    ),
    ],
    );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPinChangeSection() {
    if (_otpVerified) {
      return Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CupertinoColors.extraLightBackgroundGray,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.lock_rotation,
                  size: 48,
                  color: CupertinoColors.activeBlue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Change Your PIN',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 4),
                        child: Text(
                          'Current PIN',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                      CupertinoTextField(
                        controller: _currentPinController,
                        placeholder: 'Enter current PIN',
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        padding: const EdgeInsets.all(16),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 4),
                        child: Text(
                          'New PIN',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                      CupertinoTextField(
                        controller: _newPinController,
                        placeholder: 'Enter new PIN (6 digits)',
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        padding: const EdgeInsets.all(16),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 4),
                        child: Text(
                          'Confirm New PIN',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                      CupertinoTextField(
                        controller: _confirmPinController,
                        placeholder: 'Confirm new PIN',
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        padding: const EdgeInsets.all(16),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(10),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    onPressed: _isLoading ? null : _changePin,
                    child: _isLoading
                        ? const CupertinoActivityIndicator()
                        : const Text(
                      'Update PIN',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}