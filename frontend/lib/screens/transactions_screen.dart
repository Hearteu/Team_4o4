import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../widgets/transaction_detail_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTransactionType = 'All';
  String _selectedTimeFilter = 'All Time';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _getFilteredTransactions(InventoryProvider provider) {
    List<Transaction> transactions = provider.transactions;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      transactions = transactions
          .where(
            (transaction) =>
                transaction.productName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                transaction.productSku.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                transaction.reference.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                transaction.notes.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply transaction type filter
    if (_selectedTransactionType != 'All') {
      transactions = transactions
          .where(
            (transaction) =>
                transaction.transactionType.name == _selectedTransactionType,
          )
          .toList();
    }

    // Apply time filter
    final now = DateTime.now();
    switch (_selectedTimeFilter) {
      case 'Today':
        final today = DateTime(now.year, now.month, now.day);
        transactions = transactions
            .where((transaction) => transaction.createdAt.isAfter(today))
            .toList();
        break;
      case 'This Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        transactions = transactions
            .where((transaction) => transaction.createdAt.isAfter(weekAgo))
            .toList();
        break;
      case 'This Month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        transactions = transactions
            .where((transaction) => transaction.createdAt.isAfter(monthAgo))
            .toList();
        break;
      case 'Last 30 Days':
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        transactions = transactions
            .where(
              (transaction) => transaction.createdAt.isAfter(thirtyDaysAgo),
            )
            .toList();
        break;
    }

    return transactions;
  }

  void _showTransactionDetail(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => TransactionDetailDialog(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('MedEase Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to add transaction screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add Transaction feature coming soon!'),
                ),
              );
            },
            tooltip: 'Add Transaction',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Transactions'),
            Tab(text: 'Sales'),
            Tab(text: 'Purchases'),
          ],
        ),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text('Error loading transactions', style: AppTheme.heading3),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllTransactions(provider),
              _buildSalesTransactions(provider),
              _buildPurchaseTransactions(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAllTransactions(InventoryProvider provider) {
    final transactions = _getFilteredTransactions(provider);

    return Column(
      children: [
        _buildFilters(),
        _buildTransactionStats(provider, transactions),
        Expanded(child: _buildTransactionList(transactions)),
      ],
    );
  }

  Widget _buildSalesTransactions(InventoryProvider provider) {
    final allTransactions = _getFilteredTransactions(provider);
    final salesTransactions = allTransactions
        .where(
          (transaction) => transaction.transactionType == TransactionType.OUT,
        )
        .toList();

    return Column(
      children: [
        _buildFilters(),
        _buildSalesStats(provider, salesTransactions),
        Expanded(child: _buildTransactionList(salesTransactions)),
      ],
    );
  }

  Widget _buildPurchaseTransactions(InventoryProvider provider) {
    final allTransactions = _getFilteredTransactions(provider);
    final purchaseTransactions = allTransactions
        .where(
          (transaction) => transaction.transactionType == TransactionType.IN,
        )
        .toList();

    return Column(
      children: [
        _buildFilters(),
        _buildPurchaseStats(provider, purchaseTransactions),
        Expanded(child: _buildTransactionList(purchaseTransactions)),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Filter row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTransactionType,
                  decoration: InputDecoration(
                    labelText: 'Transaction Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Types')),
                    DropdownMenuItem(value: 'IN', child: Text('Stock In')),
                    DropdownMenuItem(value: 'OUT', child: Text('Stock Out')),
                    DropdownMenuItem(
                      value: 'ADJUST',
                      child: Text('Adjustment'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTransactionType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTimeFilter,
                  decoration: InputDecoration(
                    labelText: 'Time Period',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'All Time',
                      child: Text('All Time'),
                    ),
                    DropdownMenuItem(value: 'Today', child: Text('Today')),
                    DropdownMenuItem(
                      value: 'This Week',
                      child: Text('This Week'),
                    ),
                    DropdownMenuItem(
                      value: 'This Month',
                      child: Text('This Month'),
                    ),
                    DropdownMenuItem(
                      value: 'Last 30 Days',
                      child: Text('Last 30 Days'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeFilter = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionStats(
    InventoryProvider provider,
    List<Transaction> transactions,
  ) {
    final totalTransactions = transactions.length;

    // Calculate transaction counts for display
    final stockInCount = transactions
        .where((t) => t.transactionType == TransactionType.IN)
        .length;
    final stockOutCount = transactions
        .where((t) => t.transactionType == TransactionType.OUT)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Total',
              value: totalTransactions.toString(),
              icon: Icons.receipt_long,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),

          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: 'Stock In',
              value: stockInCount.toString(),
              icon: Icons.arrow_downward,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: 'Stock Out',
              value: stockOutCount.toString(),
              icon: Icons.arrow_upward,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesStats(
    InventoryProvider provider,
    List<Transaction> transactions,
  ) {
    final totalSales = transactions.length;
    final totalRevenue = transactions.fold<double>(0, (sum, transaction) {
      if (transaction.totalAmount == null) return sum;
      // Stock Out has negative quantity, so totalAmount is negative, but we want positive (money received)
      final amount = -transaction.totalAmount!;
      print(
        '    Revenue calc: ID ${transaction.id}, Original: ₱${transaction.totalAmount}, Converted: ₱$amount',
      );
      return sum + amount;
    });

    // Debug information
    print('🛒 Sales Stats Debug:');
    print('  Total transactions: $totalSales');
    print('  Total revenue: ₱${totalRevenue.toStringAsFixed(2)}');
    print('  Sample transactions:');
    for (int i = 0; i < transactions.length && i < 3; i++) {
      final t = transactions[i];
      print(
        '    ${i + 1}. ID: ${t.id}, Type: ${t.transactionType}, Qty: ${t.quantity}, Price: ₱${t.unitPrice}, Total: ₱${t.totalAmount}',
      );
    }

    // Check for any large values
    final largeTransactions = transactions
        .where(
          (t) =>
              t.totalAmount != null &&
              (t.totalAmount! > 1000 || t.totalAmount! < -1000),
        )
        .toList();
    if (largeTransactions.isNotEmpty) {
      print('  ⚠️ Large transactions found:');
      for (final t in largeTransactions.take(5)) {
        print('    ID: ${t.id}, Total: ₱${t.totalAmount}');
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Sales',
              value: totalSales.toString(),
              icon: Icons.shopping_cart,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: 'Revenue',
              value: '₱${totalRevenue.toStringAsFixed(2)}',
              icon: Icons.monetization_on,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseStats(
    InventoryProvider provider,
    List<Transaction> transactions,
  ) {
    final totalPurchases = transactions.length;
    final totalCost = transactions.fold<double>(0, (sum, transaction) {
      if (transaction.totalAmount == null) return sum;
      // Stock In has positive quantity, so totalAmount is positive, but we want positive (money spent)
      final amount = transaction.totalAmount!;
      print('    Cost calc: ID ${transaction.id}, Amount: ₱$amount');
      return sum + amount;
    });

    // Debug information
    print('🛍️ Purchase Stats Debug:');
    print('  Total transactions: $totalPurchases');
    print('  Total cost: ₱${totalCost.toStringAsFixed(2)}');
    print('  Sample transactions:');
    for (int i = 0; i < transactions.length && i < 3; i++) {
      final t = transactions[i];
      print(
        '    ${i + 1}. ID: ${t.id}, Type: ${t.transactionType}, Qty: ${t.quantity}, Price: ₱${t.unitPrice}, Total: ₱${t.totalAmount}',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Purchases',
              value: totalPurchases.toString(),
              icon: Icons.shopping_basket,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: 'Cost',
              value: '₱${totalCost.toStringAsFixed(2)}',
              icon: Icons.payments,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: AppTheme.heading3.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: AppTheme.bodyMedium.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _TransactionCard(
          transaction: transaction,
          onTap: () => _showTransactionDetail(transaction),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.heading3.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionCard({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isStockIn = transaction.transactionType == TransactionType.IN;
    final isStockOut = transaction.transactionType == TransactionType.OUT;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isStockIn) {
      statusColor = Colors.red;
      statusIcon = Icons.arrow_downward;
      statusText = 'Stock In';
    } else if (isStockOut) {
      statusColor = Colors.green;
      statusIcon = Icons.arrow_upward;
      statusText = 'Stock Out';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.edit;
      statusText = 'Adjustment';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 16),
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.productName,
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: AppTheme.bodySmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${transaction.productSku}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Qty: ${transaction.quantity}',
                          style: AppTheme.bodyMedium,
                        ),
                        const SizedBox(width: 16),
                        if (transaction.unitPrice != null)
                          Text(
                            'Price: ₱${transaction.unitPrice!.toStringAsFixed(2)}',
                            style: AppTheme.bodyMedium,
                          ),
                      ],
                    ),
                    if (transaction.reference.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Ref: ${transaction.reference}',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Amount and date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (transaction.totalAmount != null)
                    Text(
                      _formatAmount(transaction),
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(transaction.createdAt),
                    style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(Transaction transaction) {
    if (transaction.totalAmount == null) return '';

    // Stock Out (Sales) should be positive, Stock In (Purchases) should be negative
    // Stock Out has negative quantity, so totalAmount is negative, but we want positive (money received)
    // Stock In has positive quantity, so totalAmount is positive, but we want negative (money spent)
    final amount = transaction.transactionType == TransactionType.OUT
        ? -transaction.totalAmount! // Stock Out = Make positive (+)
        : -transaction.totalAmount!; // Stock In = Make negative (-)

    final sign = amount >= 0 ? '+' : '';
    return '₱$sign${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
