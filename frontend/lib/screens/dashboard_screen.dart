import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_transactions_widget.dart';
import '../widgets/product_form.dart';
import '../widgets/bulk_stock_dialog.dart';
import '../screens/export_import_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/expiration_screen.dart';
import '../screens/transactions_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.refreshData(),
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppTheme.surfaceColor,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'MedEasy Dashboard',
                      style: AppTheme.heading3.copyWith(color: Colors.white),
                    ),
                    background: Container(
                      decoration: AppTheme.gradientDecoration,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        // TODO: Implement notifications
                      },
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Welcome Section
                      _buildWelcomeSection(context),
                      const SizedBox(height: AppTheme.spacingL),

                      // Statistics Cards
                      _buildStatisticsSection(context, provider),
                      const SizedBox(height: AppTheme.spacingL),

                      // Recommendations
                      _buildRecommendationsSection(context, provider),
                      const SizedBox(height: AppTheme.spacingL),

                      // Quick Actions
                      _buildQuickActionsSection(context),
                      const SizedBox(height: AppTheme.spacingL),

                      // Recent Transactions
                      _buildRecentTransactionsSection(context, provider),
                      const SizedBox(height: AppTheme.spacingL),

                      // Low Stock Alerts
                      _buildLowStockSection(context, provider),
                      const SizedBox(height: AppTheme.spacingL),

                      // AI Insights Section
                      // AI insights section removed - use chatbot instead
                      const SizedBox(height: AppTheme.spacingXXL),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: AppTheme.heading2.copyWith(color: AppTheme.primaryColor),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Welcome to your inventory management dashboard',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            DateFormat('EEEE, MMMM d, y').format(now),
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    InventoryProvider provider,
  ) {
    // Show loading if data is not ready yet
    if (provider.isLoading || !provider.isDataReady) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: AppTheme.spacingM),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingL),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    // Use real-time stats if cached stats are not available
    final stats = provider.productStats ?? provider.realTimeStats;
    final inventorySummary =
        provider.inventorySummary ??
        {
          'total_value': provider.realTimeStats['total_inventory_value'],
          'total_items': provider.realTimeStats['total_inventory_items'],
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Products',
                value: '${stats['total_products'] ?? 0}',
                icon: Icons.inventory_2,
                color: AppTheme.primaryColor,
                subtitle: '${stats['active_products'] ?? 0} active',
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: StatCard(
                title: 'Total Value',
                value:
                    '₱${_formatCurrency(inventorySummary['total_value'] ?? 0)}',
                icon: Icons.monetization_on,
                color: AppTheme.successColor,
                subtitle: 'Inventory value',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Low Stock',
                value: '${stats['low_stock_items'] ?? 0}',
                icon: Icons.warning,
                color: AppTheme.warningColor,
                subtitle: 'Need attention',
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: StatCard(
                title: 'Out of Stock',
                value: '${stats['out_of_stock_items'] ?? 0}',
                icon: Icons.remove_shopping_cart,
                color: AppTheme.errorColor,
                subtitle: 'Requires restocking',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(
    BuildContext context,
    InventoryProvider provider,
  ) {
    // Show loading if data is not ready yet
    if (provider.isLoading || !provider.isDataReady) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations',
            style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: AppTheme.spacingM),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingL),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    final stats = provider.productStats ?? provider.realTimeStats;
    final lowStockCount = stats['low_stock_items'] ?? 0;
    final outOfStockCount = stats['out_of_stock_items'] ?? 0;
    final totalProducts = stats['total_products'] ?? 0;

    List<Map<String, dynamic>> recommendations = [];

    // Generate recommendations based on current data
    if (outOfStockCount > 0) {
      recommendations.add({
        'title': 'Restock Urgent Items',
        'description':
            '$outOfStockCount products are out of stock and need immediate attention.',
        'icon': Icons.priority_high,
        'color': AppTheme.errorColor,
        'action': 'View Out of Stock',
      });
    }

    if (lowStockCount > 0) {
      recommendations.add({
        'title': 'Monitor Low Stock',
        'description':
            '$lowStockCount products are running low and may need reordering soon.',
        'icon': Icons.warning,
        'color': AppTheme.warningColor,
        'action': 'View Low Stock',
      });
    }

    if (totalProducts < 50) {
      recommendations.add({
        'title': 'Expand Product Catalog',
        'description':
            'Consider adding more products to diversify your inventory.',
        'icon': Icons.add_business,
        'color': AppTheme.infoColor,
        'action': 'Add Products',
      });
    }

    // Add general recommendations
    recommendations.add({
      'title': 'Review Expiring Items',
      'description': 'Check for items approaching expiration to avoid waste.',
      'icon': Icons.schedule,
      'color': AppTheme.warningColor,
      'action': 'View Expiration',
    });

    recommendations.add({
      'title': 'Generate Reports',
      'description':
          'Create detailed reports to analyze your inventory performance.',
      'icon': Icons.analytics,
      'color': AppTheme.primaryColor,
      'action': 'Export Data',
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: AppTheme.spacingM),
        ...recommendations
            .take(3)
            .map(
              (rec) => Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: AppTheme.cardDecoration.copyWith(
                  border: Border.all(
                    color: rec['color'].withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: rec['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Icon(rec['icon'], color: rec['color'], size: 24),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec['title'],
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          Text(
                            rec['description'],
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _handleRecommendationAction(context, rec['action']),
                      child: Text(
                        rec['action'],
                        style: AppTheme.bodySmall.copyWith(
                          color: rec['color'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                title: 'Add Product',
                icon: Icons.add_box,
                color: AppTheme.primaryColor,
                onTap: () => _showAddProductDialog(context),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: QuickActionCard(
                title: 'Stock In',
                icon: Icons.input,
                color: AppTheme.successColor,
                onTap: () => _showBulkStockDialog(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                title: 'Stock Out',
                icon: Icons.output,
                color: AppTheme.warningColor,
                onTap: () => _showStockAdjustmentDialog(context),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: QuickActionCard(
                title: 'Export Data',
                icon: Icons.analytics,
                color: AppTheme.infoColor,
                onTap: () => _navigateToExportScreen(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection(
    BuildContext context,
    InventoryProvider provider,
  ) {
    final recentTransactions = provider.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionsScreen(),
                  ),
                );
              },
              child: Text(
                'View All',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        RecentTransactionsWidget(transactions: recentTransactions),
      ],
    );
  }

  Widget _buildLowStockSection(
    BuildContext context,
    InventoryProvider provider,
  ) {
    final lowStockItems = provider.lowStockItems;

    if (lowStockItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: AppTheme.successDecoration,
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 24),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Text(
                'All products are well stocked!',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Low Stock Alerts',
              style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              decoration: AppTheme.warningDecoration,
              child: Text(
                '${lowStockItems.length} items',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: AppTheme.warningDecoration,
          child: Column(
            children: lowStockItems
                .take(3)
                .map(
                  (item) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.warningColor.withOpacity(0.1),
                      child: Icon(
                        Icons.inventory_2,
                        color: AppTheme.warningColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.productName,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'SKU: ${item.productSku} • Stock: ${item.quantity}',
                      style: AppTheme.bodySmall,
                    ),
                    trailing: Text(
                      'Low Stock',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  void _handleRecommendationAction(BuildContext context, String action) {
    switch (action) {
      case 'View Out of Stock':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InventoryScreen()),
        );
        break;
      case 'View Low Stock':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InventoryScreen()),
        );
        break;
      case 'Add Products':
        _showAddProductDialog(context);
        break;
      case 'View Expiration':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExpirationScreen()),
        );
        break;
      case 'Export Data':
        _navigateToExportScreen(context);
        break;
    }
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ProductFormDialog(),
    );
  }

  void _showStockAdjustmentDialog(BuildContext context) {
    // Show a simple message for now - in a real app, you'd show a product selection dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Navigate to Inventory screen to adjust stock for specific products',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showBulkStockDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const BulkStockDialog());
  }

  void _navigateToExportScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExportImportScreen()),
    );
  }
}
