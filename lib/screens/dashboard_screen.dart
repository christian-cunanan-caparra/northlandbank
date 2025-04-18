import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mybanking/screens/paybill_screen.dart';
import '../models/user.dart';
import '../models/transaction.dart';
import 'transfer_screen.dart';
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
  bool _isCardExpanded = false;
  bool _isLoadingCard = false;
  int _currentIndex = 0;
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _fetchData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 5 seconds (adjust as needed)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    try {
      await Future.wait([
        _fetchBalance(),
        _fetchRecentTransactions(),
      ]);
    } catch (e) {
      print('Auto-refresh error: $e');
    }
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
        });
      }
    } catch (e) {
      print('Failed to fetch transactions: $e');
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchData();
  }

  Future<void> _toggleCardExpansion() async {
    setState(() {
      _isLoadingCard = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _isCardExpanded = !_isCardExpanded;
      _isLoadingCard = false;
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
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Icon(CupertinoIcons.home),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Icon(CupertinoIcons.arrow_right_arrow_left),
            ),
            label: 'Transfer',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Icon(CupertinoIcons.creditcard),
            ),
            label: 'Pay Bills',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Icon(CupertinoIcons.settings),
            ),
            label: 'Settings',
          ),
        ],
        activeColor: CupertinoColors.systemRed,
        inactiveColor: CupertinoColors.systemGrey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (context) {
                return CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
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
                            child: Column(
                              children: [
                                // Main Account Card
                                GestureDetector(
                                  onTap: _toggleCardExpansion,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: CupertinoColors.systemGrey.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: _isLoadingCard
                                        ? const Center(child: CupertinoActivityIndicator())
                                        : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Account Summary',
                                              style: TextStyle(
                                                color: CupertinoColors.black,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Icon(
                                              _isCardExpanded
                                                  ? CupertinoIcons.chevron_up
                                                  : CupertinoIcons.chevron_down,
                                              size: 20,
                                              color: CupertinoColors.systemGrey,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _isCardExpanded ? 'Tap to minimize' : 'Tap to view details',
                                          style: TextStyle(
                                            color: CupertinoColors.systemGrey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (_isCardExpanded) ...[
                                          const SizedBox(height: 16),
                                          _buildAccountDetailsCard(),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isCardExpanded) ...[
                                  const SizedBox(height: 16),
                                  // Transactions Card
                                  Container(
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: CupertinoColors.systemGrey.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Recent Transactions',
                                              style: TextStyle(
                                                color: CupertinoColors.black,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (_recentTransactions.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 16),
                                            child: Text(
                                              'No recent transactions',
                                              style: TextStyle(
                                                color: CupertinoColors.systemGrey,
                                                fontSize: 14,
                                              ),
                                            ),
                                          )
                                        else
                                          Column(
                                            children: _recentTransactions
                                                .map((transaction) => _buildTransactionItem(transaction))
                                                .toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          case 1:
            return CupertinoTabView(
              builder: (context) => TransferScreen(user: _user),
            );
          case 2:
            return CupertinoTabView(
              builder: (context) => PayBillScreen(user: _user),
            );
          case 3:
            return CupertinoTabView(
              builder: (context) => ChangePinScreen(user: _user),
            );
          default:
            return CupertinoTabView(
              builder: (context) => Container(),
            );
        }
      },
    );
  }

  Widget _buildAccountDetailsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account Number Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account Number',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getMaskedCardNumber(),
                style: const TextStyle(
                  color: CupertinoColors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Balances Row
        Row(
          children: [
            // Current Balance Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${_user.currentBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: CupertinoColors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Savings Balance Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Savings Balance',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${_user.savingsBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: CupertinoColors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTransactionType(transaction.type),
                    style: const TextStyle(
                      color: CupertinoColors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.accountType}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${transaction.amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: transaction.amount >= 0
                          ? CupertinoColors.black
                          : CupertinoColors.black,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(transaction.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 16, thickness: 1),
        ],
      ),
    );
  }

  String _formatTransactionType(String type) {
    if (type.toLowerCase().contains('bill') ||
        type.toLowerCase().contains('water') ||
        type.toLowerCase().contains('electric')) {
      return 'Bill Payment';
    }
    switch (type.toLowerCase()) {
      case 'deposit':
        return 'Deposit';
      case 'withdraw':
        return 'Withdrawal';
      case 'transfer':
        return 'Fund Transfer';
      case 'payment':
        return 'Payment';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}