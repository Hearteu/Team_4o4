import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/supplier.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;

  const ProductFormDialog({super.key, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _reorderLevelController = TextEditingController();

  Category? _selectedCategory;
  Supplier? _selectedSupplier;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _skuController.text = widget.product!.sku;
      _descriptionController.text = widget.product!.description;
      _unitPriceController.text = widget.product!.unitPrice.toString();
      _costPriceController.text = widget.product!.costPrice.toString();
      _reorderLevelController.text = widget.product!.reorderLevel.toString();
      _isActive = widget.product!.isActive;

      // Initialize selected category and supplier after data is loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeSelectedValues();
      });
    }
  }

  void _initializeSelectedValues() {
    final provider = context.read<InventoryProvider>();

    // Set selected category
    _selectedCategory = provider.categories.firstWhere(
      (cat) => cat.id == widget.product!.category,
    );

    // Set selected supplier if exists
    if (widget.product!.supplier != null) {
      _selectedSupplier = provider.suppliers.firstWhere(
        (sup) => sup.id == widget.product!.supplier,
      );
    }

    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _unitPriceController.dispose();
    _costPriceController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<InventoryProvider>();
      final productData = {
        'name': _nameController.text.trim(),
        'sku': _skuController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory!.id,
        'supplier': _selectedSupplier?.id,
        'unit_price': double.parse(_unitPriceController.text),
        'cost_price': double.parse(_costPriceController.text),
        'reorder_level': int.parse(_reorderLevelController.text),
        'is_active': _isActive,
      };

      if (widget.product != null) {
        await provider.updateProduct(widget.product!.id, productData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.product!.name} updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await provider.createProduct(productData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_nameController.text} created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.product != null ? Icons.edit : Icons.add,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.product != null ? 'Edit Product' : 'Add New Product',
                    style: AppTheme.heading3,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // SKU
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'SKU is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Category and Supplier
              Row(
                children: [
                  Expanded(
                    child: Consumer<InventoryProvider>(
                      builder: (context, provider, child) {
                        return DropdownButtonFormField<Category>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            border: OutlineInputBorder(),
                          ),
                          items: provider.categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (category) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<InventoryProvider>(
                      builder: (context, provider, child) {
                        return DropdownButtonFormField<Supplier>(
                          value: _selectedSupplier,
                          decoration: const InputDecoration(
                            labelText: 'Supplier',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<Supplier>(
                              value: null,
                              child: Text('No Supplier'),
                            ),
                            ...provider.suppliers.map((supplier) {
                              return DropdownMenuItem(
                                value: supplier,
                                child: Text(supplier.name),
                              );
                            }),
                          ],
                          onChanged: (supplier) {
                            setState(() {
                              _selectedSupplier = supplier;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Prices
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price (₱) *',
                        border: OutlineInputBorder(),
                        prefixText: '₱',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Cost price is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) < 0) {
                          return 'Cost cannot be negative';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Reorder Level
              TextFormField(
                controller: _reorderLevelController,
                decoration: const InputDecoration(
                  labelText: 'Reorder Level *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Reorder level is required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) < 0) {
                    return 'Reorder level cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Active Status
              Row(
                children: [
                  Checkbox(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value!;
                      });
                    },
                  ),
                  const Text('Active'),
                ],
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
                    onPressed: _isLoading ? null : _saveProduct,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.product != null ? 'Update' : 'Create'),
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
