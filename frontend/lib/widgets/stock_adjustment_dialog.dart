import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory.dart';
import '../services/api_service.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final Inventory inventory;

  const StockAdjustmentDialog({super.key, required this.inventory});

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _unitPriceController = TextEditingController();

  String _transactionType = 'IN';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _unitPriceController.text = widget.inventory.unitPrice.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _adjustStock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<InventoryProvider>();
      final quantity = int.parse(_quantityController.text);
      final unitPrice = double.parse(_unitPriceController.text);
      final totalAmount = quantity * unitPrice;

      final stockData = {
        'transaction_type': _transactionType,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_amount': totalAmount,
        'reason': _reasonController.text.trim(),
        'notes': 'Stock adjustment via inventory management',
      };

      // Create transaction using the API service
      await ApiService.adjustProductStock(widget.inventory.product, stockData);

      // Refresh data
      await provider.refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock ${_transactionType == 'IN' ? 'added' : 'removed'} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adjusting stock: $e'),
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
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Adjust Stock - ${widget.inventory.productName}',
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
              // Current Stock Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Stock Information',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Quantity: ${widget.inventory.quantity}',
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Unit Price: ₱${widget.inventory.unitPrice.toStringAsFixed(2)}',
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Value: ₱${widget.inventory.totalValue.toStringAsFixed(2)}',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Transaction Type
              Text(
                'Transaction Type',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Stock In'),
                      value: 'IN',
                      groupValue: _transactionType,
                      onChanged: (value) {
                        setState(() {
                          _transactionType = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Stock Out'),
                      value: 'OUT',
                      groupValue: _transactionType,
                      onChanged: (value) {
                        setState(() {
                          _transactionType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Quantity is required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Unit Price
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(
                  labelText: 'Unit Price (₱) *',
                  border: OutlineInputBorder(),
                  prefixText: '₱',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Unit price is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) < 0) {
                    return 'Price cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Reason
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Reason is required';
                  }
                  return null;
                },
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
                    onPressed: _isLoading ? null : _adjustStock,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _transactionType == 'IN'
                                ? 'Add Stock'
                                : 'Remove Stock',
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
