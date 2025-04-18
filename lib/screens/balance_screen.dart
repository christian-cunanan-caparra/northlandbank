import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

class BalanceScreen extends StatefulWidget {
  final User user;

  const BalanceScreen({super.key, required this.user});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  Map<String, double>? _balances;
  bool _isLoading = true;
  String? _errorMessage;

  Future<void> _fetchBalances() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.0.25/api/get_balance.php?card_number=${widget.user.cardNumber}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            _balances = {
              'current': double.parse(data['balance']['current_balance'].toString()),
              'savings': double.parse(data['balance']['savings_balance'].toString()),
            };
            _isLoading = false;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to fetch balances';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server returned ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to server: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchBalances();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Account Balance'),
        backgroundColor: CupertinoColors.systemRed,
        brightness: Brightness.dark,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.ellipsis, color: CupertinoColors.white),
          onPressed: () => _showMoreOptions(context),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : _errorMessage != null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: CupertinoColors.systemRed),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  child: const Text('Retry'),
                  onPressed: _fetchBalances,
                ),
              ],
            ),
          )
              : Column(
            children: [
              // Account Summary Card
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
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
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Balance',
                                style: TextStyle(
                                  color: CupertinoColors.extraLightBackgroundGray,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₱${_balances?['current']?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Savings Balance',
                                style: TextStyle(
                                  color: CupertinoColors.extraLightBackgroundGray,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₱${_balances?['savings']?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(
                    icon: CupertinoIcons.arrow_right_arrow_left,
                    label: 'Transfer',
                    onTap: () => _navigateToTransfer(context),
                  ),
                  _buildQuickAction(
                    icon: CupertinoIcons.plus,
                    label: 'Deposit',
                    onTap: () => _navigateToDeposit(context),
                  ),
                  _buildQuickAction(
                    icon: CupertinoIcons.minus,
                    label: 'Withdraw',
                    onTap: () => _navigateToWithdraw(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              color: CupertinoColors.systemRed,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Account Options'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Add your transaction history navigation here
            },
            child: const Text('Transaction History'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Add your statement download functionality here
            },
            child: const Text('Download Statement'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _navigateToTransfer(BuildContext context) {
    // Implement transfer navigation
  }

  void _navigateToDeposit(BuildContext context) {
    // Implement deposit navigation
  }

  void _navigateToWithdraw(BuildContext context) {
    // Implement withdraw navigation
  }
}