import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class RecentTransactionsWidget extends StatelessWidget {
  final List<Transaction> transactions;

  const RecentTransactionsWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: AppTheme.cardDecoration,
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'No transactions yet',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Your recent transactions will appear here',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: transactions.map((transaction) {
          return _buildTransactionTile(transaction);
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final isStockIn = transaction.transactionType.name == 'IN';
    final isStockOut = transaction.transactionType.name == 'OUT';

    Color statusColor;
    IconData statusIcon;

    if (isStockIn) {
      statusColor = AppTheme.successColor;
      statusIcon = Icons.input;
    } else if (isStockOut) {
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.output;
    } else {
      statusColor = AppTheme.infoColor;
      statusIcon = Icons.tune;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(statusIcon, color: statusColor, size: 20),
      ),
      title: Text(
        transaction.productName,
        style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SKU: ${transaction.productSku}',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          Text(
            DateFormat('MMM d, y • h:mm a').format(transaction.createdAt),
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isStockIn ? '+' : ''}${transaction.quantity}',
            style: AppTheme.bodyMedium.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            transaction.transactionTypeDisplay,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}
