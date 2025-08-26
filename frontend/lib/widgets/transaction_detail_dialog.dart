import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class TransactionDetailDialog extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailDialog({super.key, required this.transaction});

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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Details',
                        style: AppTheme.heading2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          statusText,
                          style: AppTheme.bodyMedium.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Product Information
            _DetailSection(
              title: 'Product Information',
              children: [
                _DetailRow('Product Name', transaction.productName),
                _DetailRow('SKU', transaction.productSku),
                _DetailRow('Product ID', transaction.product.toString()),
              ],
            ),

            const SizedBox(height: 16),

            // Transaction Details
            _DetailSection(
              title: 'Transaction Details',
              children: [
                _DetailRow('Transaction ID', transaction.id.toString()),
                _DetailRow('Type', transaction.transactionTypeDisplay),
                _DetailRow('Quantity', transaction.quantity.toString()),
                if (transaction.unitPrice != null)
                  _DetailRow(
                    'Unit Price',
                    '₱${transaction.unitPrice!.toStringAsFixed(2)}',
                  ),
                if (transaction.totalAmount != null)
                  _DetailRow('Total Amount', _formatAmount(transaction)),
                _DetailRow('Date', _formatDateTime(transaction.createdAt)),
              ],
            ),

            if (transaction.reference.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DetailSection(
                title: 'Reference Information',
                children: [_DetailRow('Reference', transaction.reference)],
              ),
            ],

            if (transaction.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DetailSection(
                title: 'Notes',
                children: [_DetailRow('Notes', transaction.notes)],
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
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

  String _formatAmount(Transaction transaction) {
    if (transaction.totalAmount == null) return '₱0.00';

    // Stock Out (Sales) should be positive, Stock In (Purchases) should be negative
    // Stock Out has negative quantity, so totalAmount is negative, but we want positive (money received)
    // Stock In has positive quantity, so totalAmount is positive, but we want negative (money spent)
    final amount = transaction.transactionType == TransactionType.OUT
        ? -transaction.totalAmount! // Stock Out = Make positive (+)
        : -transaction.totalAmount!; // Stock In = Make negative (-)

    final sign = amount >= 0 ? '+' : '';
    return '₱$sign${amount.toStringAsFixed(2)}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
