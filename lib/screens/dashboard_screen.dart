import 'package:flutter/cupertino.dart';
import '../models/user.dart';
import 'balance_screen.dart';
import 'transfer_screen.dart';
import 'deposit_screen.dart';
import 'withdraw_screen.dart';
import 'transactions_screen.dart';
import 'change_pin_screen.dart';

class DashboardScreen extends StatelessWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('BPI Mobile Banking'),
        backgroundColor: CupertinoColors.systemRed,
        brightness: Brightness.dark,
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Account Summary Card
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
                        'Account Summary',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                '₱${user.currentBalance.toStringAsFixed(2)}',
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
                                '₱${user.savingsBalance.toStringAsFixed(2)}',
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

            // Quick Actions
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

            // Services Section
            const SliverPadding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildServiceButton(context, index),
                  childCount: 4,
                ),
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
    'action': () => Navigator.push(
    context,
    CupertinoPageRoute(
    builder: (context) => TransferScreen(user: user),
    ),
    )},
    {
    'icon': CupertinoIcons.plus,
    'label': 'Deposit',
    'action': () => Navigator.push(
    context,
    CupertinoPageRoute(
    builder: (context) => DepositScreen(user: user),
    ),
    ),
    },
    {
    'icon': CupertinoIcons.minus,
    'label': 'Withdraw',
    'action': () => Navigator.push(
    context,
    CupertinoPageRoute(
    builder: (context) => WithdrawScreen(user: user),
    ),
    ),
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

  Widget _buildServiceButton(BuildContext context, int index) {
    final List<Map<String, dynamic>> services = [
    {
      'icon': CupertinoIcons.money_dollar,
    'label': 'Account Balance',
    'action': () => Navigator.push(
    context,
    CupertinoPageRoute(
    builder: (context) => BalanceScreen(user: user),
    ),
    )},
    {
    'icon': CupertinoIcons.list_bullet,
    'label': 'Transactions',
    'action': () => Navigator.push(
    context,
    CupertinoPageRoute(
    builder: (context) => TransactionsScreen(user: user),
    ),
    ),
    },
    {
    'icon': CupertinoIcons.lock,
    'label': 'Change PIN',
    'action': () => Navigator.push(
    context,
    CupertinoPageRoute(
    builder: (context) => ChangePinScreen(user: user),
    ),
    ),
    },
    {
    'icon': CupertinoIcons.settings,
    'label': 'Settings',
    'action': () => _showComingSoon(context),
    },
    ];

    return Container(
    decoration: BoxDecoration(
    color: CupertinoColors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
    BoxShadow(
    color: CupertinoColors.systemGrey.withOpacity(0.2),
    blurRadius: 4,
    offset: const Offset(0, 2),
    ),
    ],
    ),
    child: CupertinoButton(
    padding: EdgeInsets.zero,
    borderRadius: BorderRadius.circular(12),
    onPressed: services[index]['action'],
    child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
    color: CupertinoColors.systemRed.withOpacity(0.1),
    borderRadius: BorderRadius.circular(24),
    ),
    child: Icon(
    services[index]['icon'],
    color: CupertinoColors.systemRed,
    size: 28,
    ),
    ),
    const SizedBox(height: 12),
    Text(
    services[index]['label'],
    style: const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: CupertinoColors.darkBackgroundGray,
    ),
    textAlign: TextAlign.center,
    ),
    ],
    ),
    ),
    ),
    );
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