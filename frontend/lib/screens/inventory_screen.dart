import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory.dart';
import '../models/transaction.dart';
import '../widgets/stock_adjustment_dialog.dart';
import '../widgets/bulk_stock_dialog.dart';
import '../widgets/stock_movement_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStockStatus = 'All';
  bool _showLowStockOnly = false;
  bool _showOutOfStockOnly = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<Inventory> _getFilteredInventory(InventoryProvider provider) {
    List<Inventory> inventory = provider.inventory;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      inventory = inventory
          .where(
            (item) =>
                item.productName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                item.productSku.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      final category = provider.categories.firstWhere(
        (cat) => cat.name == _selectedCategory,
      );
      final categoryProducts = provider.products
          .where((p) => p.category == category.id)
          .map((p) => p.id)
          .toSet();
      inventory = inventory
          .where((item) => categoryProducts.contains(item.product))
          .toList();
    }

    // Apply stock status filters (checkboxes take priority over dropdown)
    if (_showLowStockOnly) {
      inventory = inventory.where((item) => item.isLowStock).toList();
    } else if (_showOutOfStockOnly) {
      inventory = inventory.where((item) => item.quantity == 0).toList();
    } else if (_selectedStockStatus != 'All') {
      // Only apply dropdown filter if checkboxes are not selected
      if (_selectedStockStatus == 'Low Stock') {
        inventory = inventory.where((item) => item.isLowStock).toList();
      } else if (_selectedStockStatus == 'Out of Stock') {
        inventory = inventory.where((item) => item.quantity == 0).toList();
      } else if (_selectedStockStatus == 'In Stock') {
        inventory = inventory.where((item) => item.quantity > 0).toList();
      }
    }

    return inventory;
  }

  void _showStockAdjustment(Inventory inventory) {
    showDialog(
      context: context,
      builder: (context) => StockAdjustmentDialog(inventory: inventory),
    );
  }

  void _showBulkStockDialog() {
    showDialog(context: context, builder: (context) => const BulkStockDialog());
  }

  void _showStockMovement(Inventory inventory) {
    showDialog(
      context: context,
      builder: (context) => StockMovementDialog(inventory: inventory),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('MedEasy Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: _showBulkStockDialog,
            tooltip: 'Bulk Stock In',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stock Overview'),
            Tab(text: 'Low Stock Alerts'),
            Tab(text: 'Stock Movement'),
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
                  Text('Error loading inventory', style: AppTheme.heading3),
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
              _buildStockOverview(provider),
              _buildLowStockAlerts(provider),
              _buildStockMovement(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStockOverview(InventoryProvider provider) {
    final filteredInventory = _getFilteredInventory(provider);
    final summary = provider.inventorySummary;

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
                  hintText: 'Search inventory...',
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
                      initialValue: _selectedStockStatus,
                      decoration: const InputDecoration(
                        labelText: 'Stock Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text('All Status'),
                        ),
                        DropdownMenuItem(
                          value: 'In Stock',
                          child: Text('In Stock'),
                        ),
                        DropdownMenuItem(
                          value: 'Low Stock',
                          child: Text('Low Stock'),
                        ),
                        DropdownMenuItem(
                          value: 'Out of Stock',
                          child: Text('Out of Stock'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStockStatus = value!;
                          // Reset checkboxes when dropdown is used
                          _showLowStockOnly = false;
                          _showOutOfStockOnly = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Quick Filters
              Row(
                children: [
                  Checkbox(
                    value: _showLowStockOnly,
                    onChanged: (value) {
                      setState(() {
                        _showLowStockOnly = value!;
                        if (value) {
                          _showOutOfStockOnly = false;
                          _selectedStockStatus =
                              'All'; // Reset dropdown when checkbox is used
                        }
                      });
                    },
                  ),
                  const Text('Low Stock Only'),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: _showOutOfStockOnly,
                    onChanged: (value) {
                      setState(() {
                        _showOutOfStockOnly = value!;
                        if (value) {
                          _showLowStockOnly = false;
                          _selectedStockStatus =
                              'All'; // Reset dropdown when checkbox is used
                        }
                      });
                    },
                  ),
                  const Text('Out of Stock Only'),
                  const Spacer(),
                  Text(
                    '${filteredInventory.length} items',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Inventory Summary Cards
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total Items',
                  value: '${summary?['total_items'] ?? 0}',
                  icon: Icons.inventory_2,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Total Value',
                  value: '₱${_formatCurrency(summary?['total_value'] ?? 0)}',
                  icon: Icons.monetization_on,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Low Stock',
                  value: '${summary?['low_stock_count'] ?? 0}',
                  icon: Icons.warning,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Out of Stock',
                  value: '${summary?['out_of_stock_count'] ?? 0}',
                  icon: Icons.remove_shopping_cart,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Inventory List
        Expanded(
          child: filteredInventory.isEmpty
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
                        'No inventory items found',
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
                  itemCount: filteredInventory.length,
                  itemBuilder: (context, index) {
                    final inventory = filteredInventory[index];
                    return _InventoryCard(
                      inventory: inventory,
                      onAdjust: () => _showStockAdjustment(inventory),
                      onMovement: () => _showStockMovement(inventory),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLowStockAlerts(InventoryProvider provider) {
    final lowStockItems = provider.inventory
        .where((item) => item.isLowStock)
        .toList();
    final outOfStockItems = provider.inventory
        .where((item) => item.quantity == 0)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Low Stock Section
        if (lowStockItems.isNotEmpty) ...[
          _AlertSection(
            title: 'Low Stock Items',
            icon: Icons.warning,
            color: AppTheme.warningColor,
            items: lowStockItems,
            onAdjust: _showStockAdjustment,
          ),
          const SizedBox(height: 24),
        ],
        // Out of Stock Section
        if (outOfStockItems.isNotEmpty) ...[
          _AlertSection(
            title: 'Out of Stock Items',
            icon: Icons.remove_shopping_cart,
            color: AppTheme.errorColor,
            items: outOfStockItems,
            onAdjust: _showStockAdjustment,
          ),
        ],
        // No Alerts
        if (lowStockItems.isEmpty && outOfStockItems.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppTheme.successColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Stock Alerts',
                  style: AppTheme.heading3.copyWith(
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All inventory items are well stocked',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStockMovement(InventoryProvider provider) {
    final recentTransactions = provider.recentTransactions;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Recent Stock Movements', style: AppTheme.heading3),
        const SizedBox(height: 16),
        if (recentTransactions.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'No Recent Movements',
                  style: AppTheme.heading3.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stock movement history will appear here',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...recentTransactions.map(
            (transaction) => _TransactionCard(transaction: transaction),
          ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2);
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.heading4.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final Inventory inventory;
  final VoidCallback onAdjust;
  final VoidCallback onMovement;

  const _InventoryCard({
    required this.inventory,
    required this.onAdjust,
    required this.onMovement,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inventory.productName,
                        style: AppTheme.heading4.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${inventory.productSku}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Stock Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: inventory.quantity == 0
                        ? AppTheme.errorColor
                        : inventory.isLowStock
                        ? AppTheme.warningColor
                        : AppTheme.successColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    inventory.quantity == 0
                        ? 'Out of Stock'
                        : inventory.isLowStock
                        ? 'Low Stock'
                        : 'In Stock',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
                        'Quantity: ${inventory.quantity}',
                        style: AppTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unit Price: ₱${inventory.unitPrice.toStringAsFixed(2)}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Value: ₱${inventory.totalValue.toStringAsFixed(2)}',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onAdjust,
                      tooltip: 'Adjust Stock',
                    ),
                    IconButton(
                      icon: const Icon(Icons.history, size: 20),
                      onPressed: onMovement,
                      tooltip: 'View Movement',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${_formatDate(inventory.lastUpdated)}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
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

class _AlertSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Inventory> items;
  final Function(Inventory) onAdjust;

  const _AlertSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: AppTheme.heading4.copyWith(color: color)),
            const Spacer(),
            Text(
              '${items.length} items',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item.productName),
              subtitle: Text('SKU: ${item.productSku}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Qty: ${item.quantity}',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '₱${item.totalValue.toStringAsFixed(2)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              onTap: () => onAdjust(item),
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isStockIn = transaction.transactionType == TransactionType.IN;
    final totalAmount = transaction.totalAmount ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isStockIn
              ? AppTheme.successColor
              : AppTheme.errorColor,
          child: Icon(
            isStockIn ? Icons.add : Icons.remove,
            color: Colors.white,
          ),
        ),
        title: Text(transaction.productName),
        subtitle: Text(
          '${transaction.transactionTypeDisplay} - ${transaction.quantity.abs()} units',
        ),
        trailing: Text(
          '₱${totalAmount.toStringAsFixed(2)}',
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
