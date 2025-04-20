import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  OverlayEntry? _notificationOverlay;

  Future<void> _payBill() async {
    setState(() {
      _isLoading = true;
    });

    final amount = _amountController.text.trim();

    if (amount.isEmpty) {
      _showNotification('Error', 'Please enter amount');
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
        _showNotification('Success', data['message']);
        _amountController.clear();
      } else {
        _showNotification('Error', data['message']);
      }
    } catch (e) {
      _showNotification('Error', 'Failed to complete payment');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showNotification(String title, String message) {
    _notificationOverlay?.remove();

    final color = title == 'Success'
        ? CupertinoColors.systemGreen
        : CupertinoColors.destructiveRed;

    _notificationOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: Key(DateTime.now().toString()),
            direction: DismissDirection.up,
            onDismissed: (_) {
              _notificationOverlay?.remove();
              _notificationOverlay = null;
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.systemGrey4,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    title == 'Success'
                        ? CupertinoIcons.checkmark_alt_circle_fill
                        : CupertinoIcons.exclamationmark_circle_fill,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          message,
                          style: const TextStyle(
                            color: CupertinoColors.black,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, size: 18),
                    onPressed: () {
                      _notificationOverlay?.remove();
                      _notificationOverlay = null;
                    },
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_notificationOverlay!);
    Future.delayed(const Duration(seconds: 3), () {
      if (_notificationOverlay?.mounted ?? false) {
        _notificationOverlay?.remove();
        _notificationOverlay = null;
      }
    });
  }

  void _showHelp() {
    _showNotification('Help', 'Select bill type, enter amount and account to pay from');
  }

  @override
  void dispose() {
    _notificationOverlay?.remove();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Pay Bills'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showHelp,
          child: const Icon(CupertinoIcons.question_circle, size: 24),
        ),
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