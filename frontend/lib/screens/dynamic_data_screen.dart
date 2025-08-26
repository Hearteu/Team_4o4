import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DynamicDataScreen extends StatefulWidget {
  final Map<String, dynamic> dataContext;
  final String userQuery;

  const DynamicDataScreen({
    super.key,
    required this.dataContext,
    required this.userQuery,
  });

  @override
  State<DynamicDataScreen> createState() => _DynamicDataScreenState();
}

class _DynamicDataScreenState extends State<DynamicDataScreen> {
  List<Map<String, dynamic>> filteredData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFilteredData();
  }

  void _loadFilteredData() async {
    setState(() {
      isLoading = true;
    });

    // Get data from provider
    final provider = context.read<InventoryProvider>();
    await provider.initializeData();

    // Filter data based on context and query
    _filterDataByContext();

    setState(() {
      isLoading = false;
    });
  }

  void _filterDataByContext() {
    final provider = context.read<InventoryProvider>();
    final query = widget.userQuery.toLowerCase();

    switch (widget.dataContext['type']) {
      case 'inventory':
        // Show inventory items, optionally filtered by query
        filteredData = provider.inventory
            .map(
              (item) => {
                'Product': item.productName,
                'SKU': item.productSku,
                'Quantity': item.quantity.toString(),
                'Unit Price': '\$${item.unitPrice.toStringAsFixed(2)}',
                'Total Value': '\$${item.totalValue.toStringAsFixed(2)}',
                'Low Stock': item.isLowStock ? 'Yes' : 'No',
              },
            )
            .toList();

        // Filter by query if it contains specific product names
        if (query.isNotEmpty) {
          filteredData = filteredData
              .where(
                (item) =>
                    item['Product'].toString().toLowerCase().contains(query) ||
                    item['SKU'].toString().toLowerCase().contains(query),
              )
              .toList();
        }
        break;

      case 'products':
        // Show products, optionally filtered by query
        filteredData = provider.products
            .map(
              (product) => {
                'Product': product.name,
                'SKU': product.sku,
                'Category': product.categoryName,
                'Unit Price': '\$${product.unitPrice.toStringAsFixed(2)}',
                'Reorder Level': product.reorderLevel.toString(),
                'Current Stock': product.currentStock.toString(),
              },
            )
            .toList();

        if (query.isNotEmpty) {
          filteredData = filteredData
              .where(
                (item) =>
                    item['Product'].toString().toLowerCase().contains(query) ||
                    item['SKU'].toString().toLowerCase().contains(query) ||
                    item['Category'].toString().toLowerCase().contains(query),
              )
              .toList();
        }
        break;

      case 'transactions':
        // Show recent transactions
        filteredData = provider.transactions
            .take(20)
            .map(
              (trans) => {
                'Product': trans.productName,
                'Type': trans.transactionTypeDisplay,
                'Quantity': trans.quantity.toString(),
                'Amount':
                    '\$${(trans.quantity * (trans.unitPrice ?? 0)).toStringAsFixed(2)}',
                'Date': _formatDate(trans.createdAt),
              },
            )
            .toList();
        break;

      case 'low_stock':
        // Show only low stock items
        filteredData = provider.inventory
            .where((item) => item.isLowStock)
            .map(
              (item) => {
                'Product': item.productName,
                'SKU': item.productSku,
                'Current Stock': item.quantity.toString(),
                'Unit Price': '\$${item.unitPrice.toStringAsFixed(2)}',
                'Total Value': '\$${item.totalValue.toStringAsFixed(2)}',
              },
            )
            .toList();
        break;

      case 'categories':
        // Show products grouped by category
        final categoryMap = <String, List<Map<String, dynamic>>>{};
        for (final product in provider.products) {
          final category = product.categoryName;
          if (!categoryMap.containsKey(category)) {
            categoryMap[category] = [];
          }
          categoryMap[category]!.add({
            'Product': product.name,
            'SKU': product.sku,
            'Stock': product.currentStock.toString(),
            'Price': '\$${product.unitPrice.toStringAsFixed(2)}',
          });
        }

        // Flatten for table display
        filteredData = [];
        categoryMap.forEach((category, products) {
          filteredData.add({
            'Category': category,
            'Product Count': products.length.toString(),
            'Sample Products': products
                .take(3)
                .map((p) => p['Product'])
                .join(', '),
          });
        });
        break;

      default:
        // Show dashboard summary
        filteredData = [
          {
            'Metric': 'Total Products',
            'Value': provider.products.length.toString(),
          },
          {
            'Metric': 'Total Inventory Items',
            'Value': provider.inventory
                .fold(0, (sum, item) => sum + item.quantity)
                .toString(),
          },
          {
            'Metric': 'Low Stock Items',
            'Value': provider.inventory
                .where((item) => item.isLowStock)
                .length
                .toString(),
          },
          {
            'Metric': 'Total Categories',
            'Value': provider.categories.length.toString(),
          },
        ];
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.dataContext['title'] ?? 'Data View',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: _loadFilteredData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredData.isEmpty
          ? _buildEmptyState()
          : _buildDataTable(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No data found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (filteredData.isEmpty) return _buildEmptyState();

    final columns = filteredData.first.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Query context
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing data for: "${widget.userQuery}"',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Results count
          Text(
            '${filteredData.length} results found',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Data table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns
                    .map(
                      (column) => DataColumn(
                        label: Text(
                          column,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                rows: filteredData
                    .map(
                      (row) => DataRow(
                        cells: columns
                            .map(
                              (column) => DataCell(
                                Text(
                                  row[column]?.toString() ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                    .toList(),
                headingRowColor: MaterialStateProperty.all(
                  AppTheme.backgroundColor,
                ),
                dataRowColor: MaterialStateProperty.resolveWith<Color?>((
                  Set<MaterialState> states,
                ) {
                  if (states.contains(MaterialState.selected)) {
                    return AppTheme.primaryColor.withOpacity(0.08);
                  }
                  return null;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
