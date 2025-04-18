import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

class PayBillScreen extends StatefulWidget {
  final User user;

  const PayBillScreen({super.key, required this.user});

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedAccount = 'Current';
  String _selectedBillType = 'water';
  bool _isLoading = false;

  Future<void> _payBill() async {
    setState(() {
      _isLoading = true;
    });

    final amount = _amountController.text.trim();

    if (amount.isEmpty) {
      _showAlert('Error', 'Please enter amount');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://warehousemanagementsystem.shop/api/paybill.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'card_number': widget.user.cardNumber,
          'amount': double.parse(amount),
          'account_type': _selectedAccount,
          'bill_type': _selectedBillType,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        _showAlert('Success', data['message']);
        _amountController.clear();
      } else {
        _showAlert('Error', data['message']);
      }
    } catch (e) {
      _showAlert('Error', 'Failed to complete payment');
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
        middle: Text('Pay Bills'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              CupertinoSlidingSegmentedControl<String>(
                groupValue: _selectedBillType,
                children: const {
                  'water': Text('Water Bill'),
                  'electric': Text('Electric Bill'),
                },
                onValueChanged: (value) {
                  setState(() {
                    _selectedBillType = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
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
                onPressed: _isLoading ? null : _payBill,
                child: _isLoading
                    ? const CupertinoActivityIndicator()
                    : const Text('Pay Bill'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}