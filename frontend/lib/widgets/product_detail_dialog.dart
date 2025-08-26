import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';

class ProductDetailDialog extends StatelessWidget {
  final Product product;

  const ProductDetailDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product.name,
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
            const SizedBox(height: 24),
            // Product Details
            _DetailRow('SKU', product.sku),
            _DetailRow('Category', product.categoryName),
            if (product.supplierName.isNotEmpty)
              _DetailRow('Supplier', product.supplierName),
            if (product.description.isNotEmpty)
              _DetailRow('Description', product.description),
            const SizedBox(height: 16),
            // Pricing Information
            _DetailRow(
              'Unit Price',
              '₱${product.unitPrice.toStringAsFixed(2)}',
            ),
            _DetailRow(
              'Cost Price',
              '₱${product.costPrice.toStringAsFixed(2)}',
            ),
            _DetailRow('Current Stock', product.currentStock.toString()),
            _DetailRow('Reorder Level', product.reorderLevel.toString()),
            _DetailRow(
              'Total Value',
              '₱${product.totalValue.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
            // Status Information
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: product.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    product.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (product.isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Low Stock',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (product.currentStock == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Out of Stock',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // Timestamps
            _DetailRow('Created', _formatDate(product.createdAt)),
            _DetailRow('Last Updated', _formatDate(product.updatedAt)),
            const SizedBox(height: 24),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTheme.bodyLarge)),
        ],
      ),
    );
  }
}
