import 'package:flutter/cupertino.dart';
//import 'package:http/http.dart' as http;
//import 'dart:convert';
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('ATM Dashboard'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildMenuButton(
                context,
                'Check Balance',
                CupertinoIcons.money_dollar,
                    () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => BalanceScreen(user: user),
                    ),
                  );
                },
              ),
              _buildMenuButton(
                context,
                'Transfer',
                CupertinoIcons.arrow_right_arrow_left,
                    () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => TransferScreen(user: user),
                    ),
                  );
                },
              ),
              _buildMenuButton(
                context,
                'Deposit',
                CupertinoIcons.plus,
                    () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => DepositScreen(user: user),
                    ),
                  );
                },
              ),
              _buildMenuButton(
                context,
                'Withdraw',
                CupertinoIcons.minus,
                    () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => WithdrawScreen(user: user),
                    ),
                  );
                },
              ),
              _buildMenuButton(
                context,
                'Transactions',
                CupertinoIcons.list_bullet,
                    () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => TransactionsScreen(user: user),
                    ),
                  );
                },
              ),
              _buildMenuButton(
                context,
                'Change PIN',
                CupertinoIcons.lock,
                    () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => ChangePinScreen(user: user),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onPressed,
      ) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }
}