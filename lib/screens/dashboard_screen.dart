import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mybanking/screens/paybill_screen.dart';
import '../models/user.dart';
import '../models/transaction.dart';
import 'transfer_screen.dart';
import 'change_pin_screen.dart';
import 'setting_screen.dart';
import 'login_screen.dart'; // Import the login screen

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
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _hasInternetConnection = true;

  // BPI Color Scheme
  final Color _bpiRed = const Color(0xFFED1C24);
  final Color _bpiDarkRed = const Color(0xFFC41017);
  final Color _bpiGold = const Color(0xFFFFD700);
  final Color _bpiDarkBlue = const Color(0xFF003366);

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _startAutoRefresh();
    _initConnectivityListener();
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        setState(() {
          _hasInternetConnection = false;
        });
        _handleNoInternetConnection();
      } else {
        setState(() {
          _hasInternetConnection = true;
        });
      }
    });
  }

  void _handleNoInternetConnection() {
    // Show alert and logout
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Connection Lost'),
        content: const Text('No internet connection. You will be logged out.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              _logoutDueToNoInternet();
            },
          ),
        ],
      ),
    );
  }

  void _logoutDueToNoInternet() {
    // Navigate back to login screen
    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isCardExpanded) {
        // Check connectivity before attempting refresh
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          _handleNoInternetConnection();
          return;
        }
        _fetchData();
      }
    });
  }

  Future<void> _fetchData() async {
    try {
      await Future.wait([
        _fetchBalance(),
        _fetchRecentTransactions(),
      ]);
    } catch (e) {
      debugPrint('Auto-refresh error: $e');
      // Check if error is due to no internet
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        _handleNoInternetConnection();
      }
    }
  }

  Future<void> _fetchBalance() async {
    try {
      final response = await http.post(
        Uri.parse('https://warehousemanagementsystem.shop/api/get_balances.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'card_number': _user.cardNumber}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          _user = _user.copyWith(
            currentBalance: double.parse(data['balance']['current_balance'].toString()),
            savingsBalance: double.parse(data['balance']['savings_balance'].toString()),
            name: data['balance']['name'] ?? _user.name,
          );
        });
      } else {
        debugPrint('Balance fetch error: ${data['message']}');
      }
    } catch (e) {
      debugPrint('Failed to fetch balance: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        _handleNoInternetConnection();
      }
    }
  }

  Future<void> _fetchRecentTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('https://warehousemanagementsystem.shop/api/transactions.php?card_number=${_user.cardNumber}&limit=3'),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          _recentTransactions = (data['transactions'] as List)
              .map((item) => Transaction.fromJson(item))
              .toList();
        });
      } else {
        debugPrint('Transactions fetch error: ${data['message']}');
      }
    } catch (e) {
      debugPrint('Failed to fetch transactions: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        _handleNoInternetConnection();
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (_isCardExpanded) {
      setState(() {
        _isLoadingCard = true;
      });
      await _fetchData();
      setState(() {
        _isLoadingCard = false;
      });
    }
  }

  Future<void> _toggleCardExpansion() async {
    if (!_isCardExpanded) {
      // Only show loading and fetch data when expanding
      setState(() {
        _isLoadingCard = true;
      });

      await _fetchData();

      setState(() {
        _isLoadingCard = false;
        _isCardExpanded = true;
      });
    } else {
      // Immediate collapse with no loading
      setState(() {
        _isCardExpanded = false;
      });
    }
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
            icon: Icon(CupertinoIcons.home, size: 20),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.arrow_right_arrow_left, size: 20),
            label: 'Transfer',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.creditcard, size: 20),
            label: 'Pay Bills',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings, size: 20),
            label: 'Settings',
          ),
        ],
        activeColor: _bpiRed,
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
                    backgroundColor: _bpiRed,
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
                                // BPI Account Card
                                GestureDetector(
                                  onTap: _toggleCardExpansion,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_bpiRed, _bpiDarkRed],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
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
                                            Text(
                                              'BPI Account',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Icon(
                                              _isCardExpanded
                                                  ? CupertinoIcons.chevron_up
                                                  : CupertinoIcons.chevron_down,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _isCardExpanded ? 'Tap to minimize' : 'Tap to view details',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (_isLoadingCard && !_isCardExpanded)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            child: Center(
                                              child: CupertinoActivityIndicator(radius: 14),
                                            ),
                                          ),
                                        if (_isCardExpanded && !_isLoadingCard) ...[
                                          const SizedBox(height: 16),
                                          _buildBPIAccountDetailsCard(),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isCardExpanded && !_isLoadingCard) ...[
                                  const SizedBox(height: 16),
                                  // Transactions Card
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
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
                                            Text(
                                              'Transactions history',
                                              style: TextStyle(
                                                color: _bpiDarkBlue,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                // Navigate to full transaction history
                                              },
                                              child: Text(
                                                'View All',
                                                style: TextStyle(
                                                  color: _bpiRed,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (_recentTransactions.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                                                .map((transaction) => _buildBPITransactionItem(transaction))
                                                .toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                                // Quick Actions
                                if (!_isCardExpanded) ...[
                                  const SizedBox(height: 16),
                                  _buildQuickActions(),
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
              builder: (context) => SettingsScreen(user: _user),
            );
          default:
            return CupertinoTabView(
              builder: (context) => Container(),
            );
        }
      },
    );
  }

  Widget _buildBPIAccountDetailsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Name
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _user.name.toUpperCase(),
            style: TextStyle(
              color: _bpiGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Account Number
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Number',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getMaskedCardNumber(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),


        // Balance Row
        Row(
          children: [
            // Current Balance
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${_user.currentBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Savings Balance
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Savings Balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${_user.savingsBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
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

  Widget _buildBPITransactionItem(Transaction transaction) {
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
                    style: TextStyle(
                      color: _bpiDarkBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.accountType}',
                    style: TextStyle(
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
                    '${transaction.amount >= 0 ? '' : ''}₱${transaction.amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: transaction.amount >= 0 ? _bpiDarkBlue : _bpiRed,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(transaction.date),
                    style: TextStyle(
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

  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),


    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _bpiRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _bpiRed,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: _bpiDarkBlue,
              fontSize: 12,
            ),
          ),
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