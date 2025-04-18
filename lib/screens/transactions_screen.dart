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
  bool _hasError = false;

  Future<void> _fetchTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('https://warehousemanagementsystem.shop/api/transactions.php?card_number=${widget.user.cardNumber}'),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          _transactions = (data['transactions'] as List)
              .map((item) => Transaction.fromJson(item))
              .toList();
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        _showAlert('Error', data['message'] ?? 'Failed to load transactions');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      _showAlert('Error', 'Failed to connect to server');
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
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Transaction History'),
        backgroundColor: CupertinoColors.systemRed,
        brightness: Brightness.dark,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _hasError
            ? _buildErrorView()
            : _transactions.isEmpty
            ? _buildEmptyView()
            : CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: _fetchTransactions,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final transaction = _transactions[index];
                    return _buildTransactionCard(transaction);
                  },
                  childCount: _transactions.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: CupertinoColors.systemRed),
          const SizedBox(height: 16),
          const Text(
            'Failed to load transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            child: const Text('Try Again'),
            onPressed: _fetchTransactions,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.doc_plaintext, size: 48, color: CupertinoColors.systemGrey),
          const SizedBox(height: 16),
          const Text(
            'No transactions found',
            style: TextStyle(fontSize: 18, color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Type + Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTransactionType(transaction.type),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '₱${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: transaction.type == 'Deposit'
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Account type and date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAccountTypeColor(transaction.accountType),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.accountType,
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.white),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(transaction.date),
                  style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTransactionType(String type) {
    switch (type) {
      case 'Deposit':
        return 'Deposit';
      case 'Withdraw':
        return 'Withdrawal';
      case 'Transfer':
        return 'Fund Transfer';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getAccountTypeColor(String accountType) {
    return accountType == 'Savings'
        ? CupertinoColors.systemBlue
        : CupertinoColors.systemPurple;
  }
}
