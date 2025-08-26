import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../services/api_service.dart';
import '../models/stock_batch.dart';
import '../theme/app_theme.dart';

class ExpirationScreen extends StatefulWidget {
  const ExpirationScreen({super.key});

  @override
  State<ExpirationScreen> createState() => _ExpirationScreenState();
}

class _ExpirationScreenState extends State<ExpirationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  List<StockBatch> _expiredBatches = [];
  List<StockBatch> _expiringSoonBatches = [];
  List<StockBatch> _expiringThisWeekBatches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadExpirationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExpirationData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getExpirationSummary(),
        ApiService.getExpiredBatches(),
        ApiService.getExpiringSoonBatches(),
        ApiService.getExpiringThisWeekBatches(),
      ]);

      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _expiredBatches = results[1] as List<StockBatch>;
        _expiringSoonBatches = results[2] as List<StockBatch>;
        _expiringThisWeekBatches = results[3] as List<StockBatch>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading expiration data: $e'),
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
        title: const Text('Expiration Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Expired'),
            Tab(text: 'Expiring Soon'),
            Tab(text: 'This Week'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildExpiredTab(),
                _buildExpiringSoonTab(),
                _buildExpiringThisWeekTab(),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    if (_summary == null) {
      return const Center(child: Text('No summary data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadExpirationData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildAlertCards(),
            const SizedBox(height: 16),
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expiration Summary',
              style: AppTheme.heading3.copyWith(color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Batches',
                    '${_summary!['total_batches_with_expiry'] ?? 0}',
                    Icons.inventory,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Expired',
                    '${_summary!['expired_batches_count'] ?? 0}',
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Expiring Soon',
                    '${_summary!['expiring_soon_count'] ?? 0}',
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'This Week',
                    '${_summary!['expiring_this_week_count'] ?? 0}',
                    Icons.priority_high,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: AppTheme.heading2.copyWith(color: color)),
        Text(
          title,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAlertCards() {
    final expiredValue = _summary!['expired_value'] ?? 0.0;
    final expiringSoonValue = _summary!['expiring_soon_value'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Impact',
          style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAlertCard(
                'Expired Value',
                '₱${NumberFormat('#,##0.00').format(expiredValue)}',
                Colors.red,
                Icons.money_off,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAlertCard(
                'At Risk',
                '₱${NumberFormat('#,##0.00').format(expiringSoonValue)}',
                Colors.orange,
                Icons.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.heading3.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: AppTheme.bodyMedium.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final expiredCount = _summary!['expired_batches_count'] ?? 0;
    final expiringThisWeekCount = _summary!['expiring_this_week_count'] ?? 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations',
              style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            if (expiredCount > 0) ...[
              _buildRecommendationItem(
                '🚨 Immediate Action Required',
                'Dispose of $expiredCount expired batches to prevent health risks',
                Colors.red,
              ),
              const SizedBox(height: 8),
            ],
            if (expiringThisWeekCount > 0) ...[
              _buildRecommendationItem(
                '⚠️ Urgent Attention',
                'Prioritize sales of $expiringThisWeekCount batches expiring this week',
                Colors.orange,
              ),
              const SizedBox(height: 8),
            ],
            _buildRecommendationItem(
              '📊 Review Inventory',
              'Consider adjusting reorder quantities to prevent overstocking',
              AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredTab() {
    return _buildBatchListTab(_expiredBatches, 'No expired batches found');
  }

  Widget _buildExpiringSoonTab() {
    return _buildBatchListTab(_expiringSoonBatches, 'No batches expiring soon');
  }

  Widget _buildExpiringThisWeekTab() {
    return _buildBatchListTab(
      _expiringThisWeekBatches,
      'No batches expiring this week',
    );
  }

  Widget _buildBatchListTab(List<StockBatch> batches, String emptyMessage) {
    return RefreshIndicator(
      onRefresh: _loadExpirationData,
      child: batches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: batches.length,
              itemBuilder: (context, index) {
                final batch = batches[index];
                return _buildBatchCard(batch);
              },
            ),
    );
  }

  Widget _buildBatchCard(StockBatch batch) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(batch).withOpacity(0.1),
          child: Icon(_getStatusIcon(batch), color: _getStatusColor(batch)),
        ),
        title: Text(
          batch.productName,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('SKU: ${batch.productSku}', style: AppTheme.bodyMedium),
            if (batch.lotNumber != null) ...[
              const SizedBox(height: 2),
              Text('Lot: ${batch.lotNumber}', style: AppTheme.bodyMedium),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Qty: ${batch.quantity}', style: AppTheme.bodyMedium),
                const SizedBox(width: 16),
                if (batch.totalValue != null)
                  Text(
                    'Value: ₱${NumberFormat('#,##0.00').format(batch.totalValue)}',
                    style: AppTheme.bodyMedium,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (batch.expiryDate != null) ...[
              Text(
                'Expires: ${DateFormat('MMM dd, yyyy').format(batch.expiryDate!)}',
                style: AppTheme.bodyMedium.copyWith(
                  color: _getStatusColor(batch),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (batch.daysToExpiry != null) ...[
                const SizedBox(height: 2),
                Text(
                  batch.isExpired
                      ? 'Expired ${batch.daysToExpiry!.abs()} days ago'
                      : '${batch.daysToExpiry} days remaining',
                  style: AppTheme.bodySmall.copyWith(
                    color: _getStatusColor(batch),
                  ),
                ),
              ],
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleBatchAction(value, batch),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'dispose',
              child: Row(
                children: [
                  Icon(Icons.delete_outline),
                  SizedBox(width: 8),
                  Text('Dispose'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(StockBatch batch) {
    if (batch.isExpired) return Colors.red;
    if (batch.daysToExpiry != null) {
      if (batch.daysToExpiry! <= 7) return Colors.red;
      if (batch.daysToExpiry! <= 30) return Colors.orange;
    }
    return Colors.green;
  }

  IconData _getStatusIcon(StockBatch batch) {
    if (batch.isExpired) return Icons.warning;
    if (batch.daysToExpiry != null) {
      if (batch.daysToExpiry! <= 7) return Icons.priority_high;
      if (batch.daysToExpiry! <= 30) return Icons.schedule;
    }
    return Icons.check_circle;
  }

  void _handleBatchAction(String action, StockBatch batch) {
    switch (action) {
      case 'details':
        _showBatchDetails(batch);
        break;
      case 'dispose':
        _showDisposeDialog(batch);
        break;
    }
  }

  void _showBatchDetails(StockBatch batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(batch.productName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${batch.productSku}'),
            if (batch.lotNumber != null) Text('Lot Number: ${batch.lotNumber}'),
            Text('Quantity: ${batch.quantity}'),
            if (batch.unitCost != null)
              Text(
                'Unit Cost: ₱${NumberFormat('#,##0.00').format(batch.unitCost)}',
              ),
            if (batch.totalValue != null)
              Text(
                'Total Value: ₱${NumberFormat('#,##0.00').format(batch.totalValue)}',
              ),
            if (batch.expiryDate != null)
              Text(
                'Expiry Date: ${DateFormat('MMM dd, yyyy').format(batch.expiryDate!)}',
              ),
            Text(
              'Received: ${DateFormat('MMM dd, yyyy').format(batch.receivedAt)}',
            ),
            if (batch.supplierName != null)
              Text('Supplier: ${batch.supplierName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDisposeDialog(StockBatch batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispose Batch'),
        content: Text(
          'Are you sure you want to dispose of ${batch.quantity} units of ${batch.productName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement dispose functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dispose functionality coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Dispose'),
          ),
        ],
      ),
    );
  }
}
