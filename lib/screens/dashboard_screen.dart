import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/transaction.dart';
import 'balance_screen.dart';
import 'transfer_screen.dart';
import 'deposit_screen.dart';
import 'withdraw_screen.dart';
import 'transactions_screen.dart';
import 'change_pin_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late User _user;
  List<Transaction> _recentTransactions = [];
  bool _isLoadingTransactions = true;
  bool _isRefreshing = false;
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchBalance(),
      _fetchRecentTransactions(),
    ]);
  }

  Future<void> _fetchBalance() async {
    try {
      final response = await http.get(Uri.parse(
        'https://warehousemanagementsystem.shop/api/get_balance.php?card_number=${_user.cardNumber}',
      ));
      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          _user = _user.copyWith(
            currentBalance: double.parse(data['balance']['current_balance'].toString()),
            savingsBalance: double.parse(data['balance']['savings_balance'].toString()),
          );
        });
      } else {
        print('API responded but failed: ${data['message']}');
      }
    } catch (e) {
      print('Failed to fetch balance: $e');
    }
  }

  Future<void> _fetchRecentTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('https://warehousemanagementsystem.shop/api/transactions.php?card_number=${_user.cardNumber}&limit=3'),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          _recentTransactions = (data['transactions'] as List)
              .map((item) => Transaction.fromJson(item))
              .toList();
          _isLoadingTransactions = false;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _isLoadingTransactions = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingTransactions = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchData();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  String _getMaskedCardNumber() {
    if (_user.cardNumber.length <= 5) {
      return _user.cardNumber;
    }
    final visiblePart = _user.cardNumber.substring(0, 5);
    final maskedPart = '*' * (_user.cardNumber.length - 5);
    return '$visiblePart$maskedPart';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CupertinoPageScaffold(
          backgroundColor: CupertinoColors.systemGrey6,
          navigationBar: CupertinoNavigationBar(
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.line_horizontal_3),
              onPressed: _toggleSidebar,
            ),
            middle: const Text('BPI Mobile Banking'),
            backgroundColor: CupertinoColors.systemRed,
            brightness: Brightness.dark,
          ),
          child: SafeArea(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: _handleRefresh,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Number',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getMaskedCardNumber(),
                            style: const TextStyle(
                              color: CupertinoColors.extraLightBackgroundGray,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current Balance',
                                    style: TextStyle(
                                      color: CupertinoColors.extraLightBackgroundGray,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '₱${_user.currentBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Savings Balance',
                                    style: TextStyle(
                                      color: CupertinoColors.extraLightBackgroundGray,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '₱${_user.savingsBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildQuickActionButton(context, index),
                      childCount: 4,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        // CupertinoButton(
                        //   padding: EdgeInsets.zero,
                        //   child: const Text(
                        //     'View All',
                        //     style: TextStyle(
                        //       color: CupertinoColors.systemRed,
                        //       fontSize: 14,
                        //     ),
                        //   ),
                        //   onPressed: () => Navigator.push(
                        //     context,
                        //     CupertinoPageRoute(
                        //       builder: (context) => TransactionsScreen(user: _user),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),

                if (_isLoadingTransactions && !_isRefreshing)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                  )
                else if (_recentTransactions.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No recent transactions',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final transaction = _recentTransactions[index];
                        return _buildTransactionItem(transaction);
                      },
                      childCount: _recentTransactions.length,
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (_isSidebarOpen)
          GestureDetector(
            onTap: _toggleSidebar,
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: _isSidebarOpen ? 0 : -MediaQuery.of(context).size.width * 0.7,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.7,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 100,
                      color: CupertinoColors.systemRed,
                      padding: const EdgeInsets.only(left: 16, bottom: 16),
                      alignment: Alignment.bottomLeft,
                      child: const Text(
                        'Services',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildSidebarItem(
                            context,
                            CupertinoIcons.person,
                            'Account Info',
                                () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => BalanceScreen(user: _user),
                                ),
                              );
                              _toggleSidebar();
                            },
                          ),
                          _buildSidebarItem(
                            context,
                            CupertinoIcons.arrow_right_arrow_left,
                            'Transfer',
                                () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => TransferScreen(user: _user),
                                ),
                              );
                              _toggleSidebar();
                            },
                          ),
                          _buildSidebarItem(
                            context,
                            CupertinoIcons.plus,
                            'Deposit',
                                () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => DepositScreen(user: _user),
                                ),
                              );
                              _toggleSidebar();
                            },
                          ),
                          _buildSidebarItem(
                            context,
                            CupertinoIcons.minus,
                            'Withdraw',
                                () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => WithdrawScreen(user: _user),
                                ),
                              );
                              _toggleSidebar();
                            },
                          ),
                          _buildSidebarItem(
                            context,
                            CupertinoIcons.list_bullet,
                            'Transactions',
                                () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => TransactionsScreen(user: _user),
                                ),
                              );
                              _toggleSidebar();
                            },
                          ),
                          _buildSidebarItem(
                            context,
                            CupertinoIcons.lock,
                            'Change PIN',
                                () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => ChangePinScreen(user: _user),
                                ),
                              );
                              _toggleSidebar();
                            },
                          ),
                          _buildSidebarItem(
                            context,
                            CupertinoIcons.settings,
                            'Settings',
                                () {
                              _showComingSoon(context);
                              _toggleSidebar();
                            },
                          ),
                          _buildSidebarItem(
                            context,
                            CupertinoIcons.info,
                            'About',
                                () {
                              _showComingSoon(context);
                              _toggleSidebar();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (_isSidebarOpen)
                Positioned(
                  right: 16,
                  top: 16,
                  child: GestureDetector(
                    onTap: _toggleSidebar,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: const Icon(
                        CupertinoIcons.line_horizontal_3,
                        color: CupertinoColors.white,
                        size: 20,
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

  Widget _buildSidebarItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: CupertinoColors.systemRed,
            size: 24,
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncoming = transaction.type == 'Deposit' ||
        (transaction.type == 'Transfer' && transaction.amount > 0);
    final isOutgoing = transaction.type == 'Withdraw' ||
        (transaction.type == 'Transfer' && transaction.amount < 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(12),
        onPressed: () {},
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getTransactionIcon(transaction.type),
                color: CupertinoColors.systemRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTransactionType(transaction.type),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.accountType} • ${_formatDate(transaction.date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncoming ? '+' : isOutgoing ? '-' : ''}₱${transaction.amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncoming
                    ? CupertinoColors.systemGreen
                    : CupertinoColors.systemRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context, int index) {
    final List<Map<String, dynamic>> quickActions = [
      {
        'icon': CupertinoIcons.arrow_right_arrow_left,
        'label': 'Transfer',
        'action': () async {
          await Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => TransferScreen(user: _user),
            ),
          );
          await _fetchData();
        },
      },
      {
        'icon': CupertinoIcons.plus,
        'label': 'Deposit',
        'action': () async {
          await Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => DepositScreen(user: _user),
            ),
          );
          await _fetchData();
        },
      },
      {
        'icon': CupertinoIcons.minus,
        'label': 'Withdraw',
        'action': () async {
          await Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => WithdrawScreen(user: _user),
            ),
          );
          await _fetchData();
        },
      },
      {
        'icon': CupertinoIcons.creditcard,
        'label': 'Pay Bills',
        'action': () => _showComingSoon(context),
      },
    ];

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: quickActions[index]['action'],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              quickActions[index]['icon'],
              color: CupertinoColors.systemRed,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            quickActions[index]['label'],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTransactionType(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return 'Deposit';
      case 'withdraw':
        return 'Withdrawal';
      case 'transfer':
        return 'Fund Transfer';
      case 'payment':
        return 'Payment';
      case 'bill':
        return 'Bill Payment';
      default:
        return type;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return CupertinoIcons.arrow_down;
      case 'withdraw':
        return CupertinoIcons.arrow_up;
      case 'transfer':
        return CupertinoIcons.arrow_right_arrow_left;
      case 'payment':
        return CupertinoIcons.money_dollar;
      case 'bill':
        return CupertinoIcons.doc_text;
      default:
        return CupertinoIcons.doc_text;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showComingSoon(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('This feature will be available soon.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}