import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
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

      final data = _parseResponse(response);

      if (data['success'] == true) {
        setState(() => _otpVerified = true);
        _showAlert('Success', 'OTP verified successfully');
      } else {
        throw Exception(data['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      _handleError(e);
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: CupertinoColors.systemRed),
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
          const Text('We will send an OTP to your registered email:'),
          const SizedBox(height: 8),
          Text(
            widget.user.email,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          CupertinoButton.filled(
            onPressed: _isLoading ? null : _sendOtp,
            child: _isLoading ? const CupertinoActivityIndicator() : const Text('Send OTP'),
          ),
        ],
      );
    }

    if (!_otpVerified) {
      return Column(
        children: [
          const SizedBox(height: 20),
          const Text('Enter the 6-digit OTP sent to:'),
          const SizedBox(height: 4),
          Text(
            widget.user.email,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _otpController,
            placeholder: 'Enter OTP',
            keyboardType: TextInputType.number,
            maxLength: 6,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            onPressed: _isLoading ? null : _verifyOtp,
            child: _isLoading ? const CupertinoActivityIndicator() : const Text('Verify OTP'),
          ),
          const SizedBox(height: 16),
          if (_resendTimer > 0)
            Text('Resend OTP in $_resendTimer seconds')
          else
            CupertinoButton(
              onPressed: _sendOtp,
              child: const Text('Resend OTP'),
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
          const Text('Current PIN'),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _currentPinController,
            placeholder: 'Enter current PIN',
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          const Text('New PIN'),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _newPinController,
            placeholder: 'Enter new PIN (6 digits)',
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Confirm New PIN'),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _confirmPinController,
            placeholder: 'Confirm new PIN',
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
            onPressed: _isLoading ? null : _changePin,
            child: _isLoading ? const CupertinoActivityIndicator() : const Text('Change PIN'),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
