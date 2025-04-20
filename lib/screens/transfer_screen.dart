import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  final ScrollController _scrollController = ScrollController();
  String _selectedAccount = 'Current';
  bool _isLoading = false;
  OverlayEntry? _notificationOverlay;

  List<Map<String, dynamic>> _recentRecipients = [];
  bool _showRecentRecipients = true;

  @override
  void initState() {
    super.initState();
    _loadRecentRecipients();
    _scrollController.addListener(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notificationOverlay?.remove();
    _recipientController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentRecipients() async {
    final prefs = await SharedPreferences.getInstance();
    final recipientsJson = prefs.getStringList('recent_recipients') ?? [];

    setState(() {
      _recentRecipients = recipientsJson.map((json) {
        final data = jsonDecode(json);
        return {
          'account': data['account'],
          'name': data['name'] ?? 'Recipient',
          'date': data['date'],
        };
      }).toList();

      _recentRecipients.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
    });
  }

  Future<void> _saveRecentRecipients() async {
    final prefs = await SharedPreferences.getInstance();
    final recipientsJson = _recentRecipients.map((recipient) {
      return jsonEncode({
        'account': recipient['account'],
        'name': recipient['name'],
        'date': recipient['date'],
      });
    }).toList();

    await prefs.setStringList('recent_recipients', recipientsJson);
  }

  Future<void> _addRecentRecipient(String account) async {
    final existingIndex = _recentRecipients.indexWhere((r) => r['account'] == account);
    final now = DateTime.now().toIso8601String();

    if (existingIndex >= 0) {
      setState(() {
        _recentRecipients[existingIndex] = {
          'account': account,
          'name': _recentRecipients[existingIndex]['name'],
          'date': now,
        };
      });
    } else {
      setState(() {
        _recentRecipients.insert(0, {
          'account': account,
          'name': 'Recipient',
          'date': now,
        });

        if (_recentRecipients.length > 5) {
          _recentRecipients = _recentRecipients.sublist(0, 5);
        }
      });
    }

    await _saveRecentRecipients();
  }

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

    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
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
          'amount': amountValue,
          'account_type': _selectedAccount,
          'notes': _notesController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        _showNotification('Success', data['message']);
        await _addRecentRecipient(recipient);
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

  void _selectRecipient(String account) {
    setState(() {
      _recipientController.text = account;
      FocusScope.of(context).unfocus();
    });
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
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
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
                                widget.user.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '•••• ${widget.user.cardNumber.substring(12)} • $_selectedAccount Account',
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

                if (_recentRecipients.isNotEmpty && _showRecentRecipients) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'RECENT RECIPIENTS',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _showRecentRecipients = !_showRecentRecipients),
                        child: Text(
                          _showRecentRecipients ? 'Hide' : 'Show',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _showRecentRecipients
                        ? ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 140, // Increased height
                        minHeight: 100,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SizedBox(
                            height: constraints.maxHeight, // Use full available height
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _recentRecipients.length,
                              itemBuilder: (context, index) {
                                final recipient = _recentRecipients[index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 120,
                                  child: GestureDetector(
                                    onTap: () => _selectRecipient(recipient['account']!),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8), // Reduced vertical padding
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 14, // Smaller avatar
                                              backgroundColor:
                                              CupertinoColors.systemGrey5,
                                              child: Text(
                                                recipient['name']!.substring(0, 1),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: CupertinoColors.destructiveRed,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6), // Smaller spacing
                                            Text(
                                              recipient['name']!,
                                              style: const TextStyle(
                                                fontSize: 13, // Slightly smaller
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '•••• ${recipient['account']!.substring(12)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: CupertinoColors.systemGrey,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                ],


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
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    });
                  },
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
      ),
    );
  }
}