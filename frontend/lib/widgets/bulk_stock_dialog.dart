import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class BulkStockDialog extends StatefulWidget {
  const BulkStockDialog({super.key});

  @override
  State<BulkStockDialog> createState() => _BulkStockDialogState();
}

class _BulkStockDialogState extends State<BulkStockDialog> {
  final List<Map<String, dynamic>> _selectedProducts = [];
  bool _isLoading = false;

  void _addProduct() {
    setState(() {
      _selectedProducts.add({
        'product': null,
        'quantity': '',
        'unit_price': '',
        'reason': '',
      });
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
    });
  }

  void _updateProduct(int index, String field, dynamic value) {
    setState(() {
      _selectedProducts[index][field] = value;
    });
  }

  Future<void> _processBulkStock() async {
    // Validate all entries
    for (int i = 0; i < _selectedProducts.length; i++) {
      final product = _selectedProducts[i];
      if (product['product'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a product for item ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (product['quantity'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter quantity for item ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (product['unit_price'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter unit price for item ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (product['reason'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter reason for item ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<InventoryProvider>();
      final bulkData = {
        'transactions': _selectedProducts.map((product) {
          final quantity = int.parse(product['quantity']);
          final unitPrice = double.parse(product['unit_price']);
          return {
            'product': product['product'].id,
            'transaction_type': 'IN',
            'quantity': quantity,
            'unit_price': unitPrice,
            'total_amount': quantity * unitPrice,
            'reason': product['reason'].trim(),
            'notes': 'Bulk stock in operation',
          };
        }).toList(),
      };

      // Process bulk stock in
      await ApiService.bulkStockIn(bulkData);

      // Refresh data
      await provider.refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk stock in completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing bulk stock: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_shopping_cart, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text('Bulk Stock In', style: AppTheme.heading3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Add multiple products to inventory at once',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Add Product Button
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                ),
                const Spacer(),
                Text(
                  '${_selectedProducts.length} products selected',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Products List
            Expanded(
              child: _selectedProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_shopping_cart_outlined,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Products Selected',
                            style: AppTheme.heading4.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click "Add Product" to start',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _selectedProducts.length,
                      itemBuilder: (context, index) {
                        return _BulkProductCard(
                          index: index,
                          product: _selectedProducts[index],
                          onUpdate: (field, value) =>
                              _updateProduct(index, field, value),
                          onRemove: () => _removeProduct(index),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading || _selectedProducts.isEmpty
                      ? null
                      : _processBulkStock,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Process Bulk Stock'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkProductCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> product;
  final Function(String, dynamic) onUpdate;
  final VoidCallback onRemove;

  const _BulkProductCard({
    required this.index,
    required this.product,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Product ${index + 1}',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onRemove,
                  tooltip: 'Remove Product',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Product Selection
            Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<Product>(
                  initialValue: product['product'],
                  decoration: const InputDecoration(
                    labelText: 'Select Product *',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.products.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text('${p.name} (${p.sku})'),
                    );
                  }).toList(),
                  onChanged: (value) => onUpdate('product', value),
                );
              },
            ),
            const SizedBox(height: 16),
            // Quantity and Unit Price
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: product['quantity'],
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => onUpdate('quantity', value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: product['unit_price'],
                    decoration: const InputDecoration(
                      labelText: 'Unit Price (₱) *',
                      border: OutlineInputBorder(),
                      prefixText: '₱',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => onUpdate('unit_price', value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Reason
            TextFormField(
              initialValue: product['reason'],
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => onUpdate('reason', value),
            ),
          ],
        ),
      ),
    );
  }
}
