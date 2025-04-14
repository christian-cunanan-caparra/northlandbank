import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

class TransferScreen extends StatefulWidget {
  final User user;

  const TransferScreen({super.key, required this.user});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedAccount = 'Current';
  bool _isLoading = false;

  Future<void> _transfer() async {
    setState(() {
      _isLoading = true;
    });

    final recipient = _recipientController.text.trim();
    final amount = _amountController.text.trim();

    if (recipient.isEmpty || amount.isEmpty) {
      _showAlert('Error', 'Please fill all fields');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (recipient == widget.user.cardNumber) {
      _showAlert('Error', 'Cannot transfer to yourself');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://warehousemanagementsystem.shop/api/transfer.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'from_card': widget.user.cardNumber,
          'to_card': recipient,
          'amount': double.parse(amount),
          'account_type': _selectedAccount,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        _showAlert('Success', data['message']);
        _recipientController.clear();
        _amountController.clear();
      } else {
        _showAlert('Error', data['message']);
      }
    } catch (e) {
      _showAlert('Error', 'Failed to complete transfer');
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
        middle: Text('Transfer Funds'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _recipientController,
                placeholder: 'Recipient Card Number',
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
                controller: _amountController,
                placeholder: 'Amount',
                keyboardType: TextInputType.number,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoSlidingSegmentedControl<String>(
                groupValue: _selectedAccount,
                children: const {
                  'Current': Text('Current Account'),
                  'Savings': Text('Savings Account'),
                },
                onValueChanged: (value) {
                  setState(() {
                    _selectedAccount = value!;
                  });
                },
              ),
              const SizedBox(height: 32),
              CupertinoButton.filled(
                child: _isLoading
                    ? const CupertinoActivityIndicator()
                    : const Text('Transfer'),
                onPressed: _isLoading ? null : _transfer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}