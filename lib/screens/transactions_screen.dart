import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/transaction.dart';
import '../models/user.dart';

class TransactionsScreen extends StatefulWidget {
  final User user;

  const TransactionsScreen({super.key, required this.user});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.0.25/api/transactions.php?card_number=${widget.user.cardNumber}'),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          _transactions = (data['transactions'] as List)
              .map((item) => Transaction.fromJson(item))
              .toList();
          _isLoading = false;
        });
      } else {
        _showAlert('Error', data['message']);
      }
    } catch (e) {
      _showAlert('Error', 'Failed to fetch transactions');
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
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
        middle: Text('Transaction History'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _transactions.isEmpty
            ? const Center(child: Text('No transactions found'))
            : ListView.builder(
          itemCount: _transactions.length,
          itemBuilder: (context, index) {
            final transaction = _transactions[index];
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          transaction.type,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '\$${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: transaction.type == 'Deposit'
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Account: ${transaction.accountType}'),
                    Text(
                        'Date: ${transaction.date.toLocal().toString().split('.')[0]}'),
                    Text(
                        'Balance: \$${transaction.balance.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}