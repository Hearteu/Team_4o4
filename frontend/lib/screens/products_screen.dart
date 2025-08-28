import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import '../widgets/product_form.dart';
import '../widgets/product_detail_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<Product> _getFilteredProducts(InventoryProvider provider) {
    List<Product> products = provider.products;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      products = provider.searchProducts(_searchQuery);
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      final category = provider.categories.firstWhere(
        (cat) => cat.name == _selectedCategory,
      );
      products = products.where((p) => p.category == category.id).toList();
    }

    // Apply status filter
    if (_selectedStatus == 'Active') {
      products = products.where((p) => p.isActive).toList();
    } else if (_selectedStatus == 'Inactive') {
      products = products.where((p) => !p.isActive).toList();
    }

    // Apply low stock filter
    if (_showLowStockOnly) {
      products = products.where((p) => p.isLowStock).toList();
    }

    return products;
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => const ProductFormDialog(),
    );
  }

  void _showEditProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(product: product),
    );
  }

  void _showProductDetail(Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailDialog(product: product),
    );
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteProduct(product);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final provider = context.read<InventoryProvider>();
    try {
      await provider.deleteProduct(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('MedEasy Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddProductDialog,
            tooltip: 'Add Product',
          ),
        ],
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
                  Text('Error loading products', style: AppTheme.heading3),
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

          final filteredProducts = _getFilteredProducts(provider);

          return Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Filters
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'All',
                                child: Text('All Categories'),
                              ),
                              ...provider.categories.map(
                                (category) => DropdownMenuItem(
                                  value: category.name,
                                  child: Text(category.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'All',
                                child: Text('All Status'),
                              ),
                              DropdownMenuItem(
                                value: 'Active',
                                child: Text('Active'),
                              ),
                              DropdownMenuItem(
                                value: 'Inactive',
                                child: Text('Inactive'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Low Stock Toggle
                    Row(
                      children: [
                        Checkbox(
                          value: _showLowStockOnly,
                          onChanged: (value) {
                            setState(() {
                              _showLowStockOnly = value!;
                            });
                          },
                        ),
                        const Text('Show Low Stock Only'),
                        const Spacer(),
                        Text(
                          '${filteredProducts.length} products',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Products List
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: AppTheme.heading3.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _ProductCard(
                            product: product,
                            onTap: () => _showProductDetail(product),
                            onEdit: () => _showEditProductDialog(product),
                            onDelete: () => _showDeleteConfirmation(product),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTheme.heading4.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${product.sku}',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: product.isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price: ₱${product.unitPrice.toStringAsFixed(2)}',
                          style: AppTheme.bodyLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stock: ${product.currentStock}',
                          style: AppTheme.bodyMedium.copyWith(
                            color: product.isLowStock
                                ? AppTheme.warningColor
                                : AppTheme.textSecondary,
                            fontWeight: product.isLowStock
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: onEdit,
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: onDelete,
                        tooltip: 'Delete',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
