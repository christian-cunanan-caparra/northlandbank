import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  bool _isLoading = false;

  Future<void> _changePin() async {
    setState(() {
      _isLoading = true;
    });

    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
      _showAlert('Error', 'Please fill all fields');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (currentPin != widget.user.pin) {
      _showAlert('Error', 'Current PIN is incorrect');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (newPin != confirmPin) {
      _showAlert('Error', 'New PINs do not match');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (newPin.length != 6) {
      _showAlert('Error', 'PIN must be 6 digits');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.25/api/update_pin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'card_number': widget.user.cardNumber,
          'new_pin': newPin,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        _showAlert('Success', data['message']);
        _currentPinController.clear();
        _newPinController.clear();
        _confirmPinController.clear();
      } else {
        _showAlert('Error', data['message']);
      }
    } catch (e) {
      _showAlert('Error', 'Failed to update PIN');
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
        middle: Text('Change PIN'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _currentPinController,
                placeholder: 'Current PIN',
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
              CupertinoTextField(
                controller: _newPinController,
                placeholder: 'New PIN',
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
              CupertinoTextField(
                controller: _confirmPinController,
                placeholder: 'Confirm New PIN',
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
                    : const Text('Change PIN'),
                onPressed: _isLoading ? null : _changePin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}