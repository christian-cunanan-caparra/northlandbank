import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController _notesController = TextEditingController();
  String _selectedAccount = 'Current';
  bool _isLoading = false;
  OverlayEntry? _notificationOverlay;

  Future<void> _transfer() async {
    setState(() => _isLoading = true);

    final recipient = _recipientController.text.trim();
    final amount = _amountController.text.trim();

    if (recipient.isEmpty || amount.isEmpty) {
      _showNotification('Error', 'Please fill all fields');
      setState(() => _isLoading = false);
      return;
    }

    if (recipient == widget.user.cardNumber) {
      _showNotification('Error', 'Cannot transfer to yourself');
      setState(() => _isLoading = false);
      return;
    }

    if (double.tryParse(amount) == null || double.parse(amount) <= 0) {
      _showNotification('Error', 'Please enter a valid amount');
      setState(() => _isLoading = false);
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
        _showNotification('Success', data['message']);
        _recipientController.clear();
        _amountController.clear();
        _notesController.clear();
      } else {
        _showNotification('Error', data['message']);
      }
    } catch (e) {
      _showNotification('Error', 'Failed to complete transfer');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showNotification(String title, String message) {
    _notificationOverlay?.remove();

    final color = title == 'Success'
        ? CupertinoColors.systemGreen
        : CupertinoColors.destructiveRed;

    _notificationOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16, // Added 16px margin from top
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

  @override
  void dispose() {
    _notificationOverlay?.remove();
    _recipientController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Transfer Funds'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.question_circle, size: 24),
          onPressed: () {
            _showNotification('Help', 'Enter recipient details and amount to transfer');
          },
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.arrow_right_arrow_left_circle_fill,
                      size: 60,
                      color: CupertinoColors.destructiveRed,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Send Money',
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .navLargeTitleTextStyle
                          .copyWith(fontSize: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FROM ACCOUNT',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _selectedAccount == 'Current'
                              ? CupertinoIcons.money_dollar_circle
                              : CupertinoIcons.money_dollar,
                          color: CupertinoColors.destructiveRed,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.user.cardNumber}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${widget.user.cardNumber} • $_selectedAccount Account',
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _selectedAccount,
                  children: const {
                    'Current': Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text('Current'),
                    ),
                    'Savings': Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text('Savings'),
                    ),
                  },
                  onValueChanged: (value) {
                    setState(() => _selectedAccount = value!);
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'TO ACCOUNT',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _recipientController,
                placeholder: 'Enter recipient account number',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Icon(
                    CupertinoIcons.person,
                    size: 20,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 16,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  border: Border.all(color: CupertinoColors.systemGrey5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'AMOUNT',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _amountController,
                placeholder: '0.00',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text('₱', style: TextStyle(fontSize: 18)),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  border: Border.all(color: CupertinoColors.systemGrey5),
                  borderRadius: BorderRadius.circular(12),
                ),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: CupertinoColors.destructiveRed,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: _isLoading ? null : _transfer,
                  child: _isLoading
                      ? const CupertinoActivityIndicator()
                      : const Text(
                    'TRANSFER NOW',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Transfer is processed instantly',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
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