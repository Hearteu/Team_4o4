import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory.dart';

class StockMovementDialog extends StatelessWidget {
  final Inventory inventory;

  const StockMovementDialog({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Stock Movement - ${inventory.productName}',
                    style: AppTheme.heading3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Current Stock Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Stock',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quantity: ${inventory.quantity}',
                          style: AppTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unit Price',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱${inventory.unitPrice.toStringAsFixed(2)}',
                          style: AppTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Value',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱${inventory.totalValue.toStringAsFixed(2)}',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Recent Stock Movements', style: AppTheme.heading4),
            const SizedBox(height: 16),
            // Stock Movement List
            Expanded(
              child: Consumer<InventoryProvider>(
                builder: (context, provider, child) {
                  final productTransactions = provider.transactions
                      .where((t) => t.product == inventory.product)
                      .take(20) // Show last 20 transactions
                      .toList();

                  if (productTransactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Stock Movements',
                            style: AppTheme.heading4.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No recent stock movements for this product',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: productTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = productTransactions[index];
                      return _MovementCard(transaction: transaction);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final dynamic
  transaction; // Using dynamic for now, should be Transaction model

  const _MovementCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isStockIn = transaction['transaction_type'] == 'IN';
    final quantity = transaction['quantity'] ?? 0;
    final totalAmount = transaction['total_amount'] ?? 0;
    final reason = transaction['reason'] ?? 'No reason provided';
    final timestamp = transaction['created_at'] != null
        ? DateTime.parse(transaction['created_at'])
        : DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Movement Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isStockIn ? AppTheme.successColor : AppTheme.errorColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isStockIn ? Icons.add : Icons.remove,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Movement Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isStockIn ? 'Stock In' : 'Stock Out',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isStockIn
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${isStockIn ? '+' : '-'}$quantity units',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isStockIn
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: AppTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(timestamp),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${totalAmount.toStringAsFixed(2)}',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  '₱${(totalAmount / quantity).toStringAsFixed(2)}/unit',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
