import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_transactions_widget.dart';

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
                      'Dashboard',
                      style: AppTheme.heading3.copyWith(
                        color: AppTheme.textPrimary,
                      ),
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
    final stats = provider.productStats;
    final inventorySummary = provider.inventorySummary;

    if (stats == null || inventorySummary == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
                    '\$${_formatCurrency(inventorySummary['total_value'] ?? 0)}',
                icon: Icons.attach_money,
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
                value: '${stats['low_stock_products'] ?? 0}',
                icon: Icons.warning,
                color: AppTheme.warningColor,
                subtitle: 'Need attention',
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: StatCard(
                title: 'Out of Stock',
                value: '${stats['out_of_stock_products'] ?? 0}',
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
                onTap: () {
                  // TODO: Navigate to add product screen
                },
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: QuickActionCard(
                title: 'Stock In',
                icon: Icons.input,
                color: AppTheme.successColor,
                onTap: () {
                  // TODO: Navigate to stock in screen
                },
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
                onTap: () {
                  // TODO: Navigate to stock out screen
                },
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: QuickActionCard(
                title: 'Reports',
                icon: Icons.analytics,
                color: AppTheme.infoColor,
                onTap: () {
                  // TODO: Navigate to reports screen
                },
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
                // TODO: Navigate to transactions screen
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
    final lowStockProducts = provider.lowStockProducts;

    if (lowStockProducts.isEmpty) {
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
                '${lowStockProducts.length} items',
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
            children: lowStockProducts
                .take(3)
                .map(
                  (product) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.warningColor.withOpacity(0.1),
                      child: Icon(
                        Icons.inventory_2,
                        color: AppTheme.warningColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'SKU: ${product.sku} • Stock: ${product.currentStock}',
                      style: AppTheme.bodySmall,
                    ),
                    trailing: Text(
                      'Reorder: ${product.reorderLevel}',
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
}
