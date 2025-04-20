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
                    size: 28,
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
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _notificationOverlay?.remove();
                      _notificationOverlay = null;
                    },
                    child: const Icon(CupertinoIcons.xmark, size: 18),
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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Help'),
        message: const Text(
          '1. Select the type of bill you want to pay\n'
              '2. Enter the payment amount\n'
              '3. Choose the account to pay from\n'
              '4. Tap "Pay Bill" to complete the transaction',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Icon(
                    CupertinoIcons.money_dollar_circle_fill,
                    size: 60,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ),

              // Bill type selection
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'SELECT BILL TYPE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _selectedBillType,
                  children: const {
                    'water': Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text('Water Bill'),
                    ),
                    'electric': Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text('Electric Bill'),
                    ),
                  },
                  onValueChanged: (value) {
                    setState(() {
                      _selectedBillType = value!;
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Amount input
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'PAYMENT AMOUNT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
              CupertinoTextField(
                controller: _amountController,
                placeholder: 'Enter amount',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text('\₱'),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.extraLightBackgroundGray,
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 24),

              // Account selection
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'SELECT ACCOUNT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _selectedAccount,
                  children: const {
                    'Current': Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text('Current'),
                    ),
                    'Savings': Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text('Savings'),
                    ),
                  },
                  onValueChanged: (value) {
                    setState(() {
                      _selectedAccount = value!;
                    });
                  },
                ),
              ),

              const Spacer(),

              // Pay button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: CupertinoColors.systemRed, // this works with CupertinoButton, not .filled
                  disabledColor: CupertinoColors.systemRed.withOpacity(0.5),
                  onPressed: _isLoading ? null : _payBill,
                  child: _isLoading
                      ? const CupertinoActivityIndicator()
                      : const Text(
                    'Pay Bill',
                    style: TextStyle(
                      fontSize: 17,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),


              // Footer note
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Center(
                  child: Text(
                    'Payments are processed instantly',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}