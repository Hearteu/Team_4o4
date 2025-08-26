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
    // Use Future.microtask to avoid setState during build
    Future.microtask(() => _loadFilteredData());
  }

  void _loadFilteredData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Get data from provider
      final provider = context.read<InventoryProvider>();
      await provider.initializeData();

      // Filter data based on context and query
      _filterDataByContext();

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading filtered data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          filteredData = [];
        });
      }
    }
  }

  void _filterDataByContext() {
    final provider = context.read<InventoryProvider>();
    final query = widget.userQuery.toLowerCase();

    // Check for ranking queries first (top N, best N, etc.)
    if (_isRankingQuery(query)) {
      _handleRankingQuery(query, provider);
      return;
    }

    // Extract specific products mentioned in the AI response
    List<String> mentionedProducts = _extractProductsFromAIResponse();

    if (mentionedProducts.isNotEmpty) {
      // Show only the products mentioned in the AI response
      _showMentionedProducts(mentionedProducts, provider);
      return;
    }

    switch (widget.dataContext['type']) {
      case 'ranking':
        // Handle ranking queries (top N, best N, etc.)
        _handleRankingQuery(query, provider);
        break;

      case 'inventory':
        // Show inventory items, filtered by specific query
        List<Map<String, dynamic>> allInventory = provider.inventory
            .map<Map<String, dynamic>>(
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

        // Apply precise filtering based on query
        if (query.isNotEmpty) {
          // Extract specific product names from query
          List<String> searchTerms = _extractSearchTerms(query);

          filteredData = allInventory.where((item) {
            String productName = item['Product'].toString().toLowerCase();
            String sku = item['SKU'].toString().toLowerCase();

            // Check if any search term matches the product
            return searchTerms.any(
              (term) => productName.contains(term) || sku.contains(term),
            );
          }).toList();
        } else {
          // If no specific query, show all inventory
          filteredData = allInventory;
        }
        break;

      case 'products':
        // Show products, filtered by specific query
        List<Map<String, dynamic>> allProducts = provider.products
            .map<Map<String, dynamic>>(
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
          // Extract specific product names from query
          List<String> searchTerms = _extractSearchTerms(query);

          filteredData = allProducts.where((item) {
            String productName = item['Product'].toString().toLowerCase();
            String sku = item['SKU'].toString().toLowerCase();
            String category = item['Category'].toString().toLowerCase();

            // Check if any search term matches the product
            return searchTerms.any(
              (term) =>
                  productName.contains(term) ||
                  sku.contains(term) ||
                  category.contains(term),
            );
          }).toList();
        } else {
          // If no specific query, show all products
          filteredData = allProducts;
        }
        break;

      case 'transactions':
        // Show recent transactions, optionally filtered by product
        List<Map<String, dynamic>> allTransactions = provider.transactions
            .take(20)
            .map<Map<String, dynamic>>(
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

        if (query.isNotEmpty) {
          // Extract specific product names from query
          List<String> searchTerms = _extractSearchTerms(query);

          filteredData = allTransactions.where((item) {
            String productName = item['Product'].toString().toLowerCase();

            // Check if any search term matches the product
            return searchTerms.any((term) => productName.contains(term));
          }).toList();
        } else {
          // If no specific query, show all transactions
          filteredData = allTransactions;
        }
        break;

      case 'low_stock':
        // Show only low stock items, optionally filtered by query
        List<Map<String, dynamic>> lowStockItems = provider.inventory
            .where((item) => item.isLowStock)
            .map<Map<String, dynamic>>(
              (item) => {
                'Product': item.productName,
                'SKU': item.productSku,
                'Current Stock': item.quantity.toString(),
                'Unit Price': '\$${item.unitPrice.toStringAsFixed(2)}',
                'Total Value': '\$${item.totalValue.toStringAsFixed(2)}',
              },
            )
            .toList();

        if (query.isNotEmpty) {
          // Extract specific product names from query
          List<String> searchTerms = _extractSearchTerms(query);

          filteredData = lowStockItems.where((item) {
            String productName = item['Product'].toString().toLowerCase();
            String sku = item['SKU'].toString().toLowerCase();

            // Check if any search term matches the product
            return searchTerms.any(
              (term) => productName.contains(term) || sku.contains(term),
            );
          }).toList();
        } else {
          // If no specific query, show all low stock items
          filteredData = lowStockItems;
        }
        break;

      case 'categories':
        // Show products grouped by category, filtered by query
        if (query.isNotEmpty) {
          // Extract specific category names from query
          List<String> searchTerms = _extractSearchTerms(query);

          final categoryMap = <String, List<Map<String, dynamic>>>{};
          for (final product in provider.products) {
            String category = product.categoryName;
            String productName = product.name.toLowerCase();
            String sku = product.sku.toLowerCase();

            // Check if product matches search terms
            bool matchesSearch = searchTerms.any(
              (term) =>
                  productName.contains(term) ||
                  sku.contains(term) ||
                  category.toLowerCase().contains(term),
            );

            if (matchesSearch) {
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
        } else {
          // Show all categories if no specific query
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
        }
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

  // Check if the query is asking for ranking (top N, best N, etc.)
  bool _isRankingQuery(String query) {
    List<String> rankingKeywords = [
      'top',
      'best',
      'highest',
      'most',
      'popular',
      'leading',
      'ranked',
      'first',
      'second',
      'third',
      'fourth',
      'fifth',
      'sixth',
      'seventh',
      'eighth',
      'ninth',
      'tenth',
    ];

    return rankingKeywords.any((keyword) => query.contains(keyword));
  }

  // Handle ranking queries like "top 5 products"
  void _handleRankingQuery(String query, dynamic provider) {
    // Extract the number from the query
    int limit = _extractNumberFromQuery(query);
    if (limit == 0) limit = 5; // Default to 5 if no number found

    // Determine ranking criteria
    String criteria = _determineRankingCriteria(query);

    List<Map<String, dynamic>> data = [];

    switch (criteria) {
      case 'quantity':
        // Top products by quantity
        data =
            provider.inventory
                .map<Map<String, dynamic>>(
                  (item) => {
                    'Product': item.productName,
                    'SKU': item.productSku,
                    'Quantity': item.quantity.toString(),
                    'Unit Price': '\$${item.unitPrice.toStringAsFixed(2)}',
                    'Total Value': '\$${item.totalValue.toStringAsFixed(2)}',
                    'Low Stock': item.isLowStock ? 'Yes' : 'No',
                  },
                )
                .toList()
              ..sort(
                (a, b) => int.parse(
                  b['Quantity'],
                ).compareTo(int.parse(a['Quantity'])),
              );
        break;

      case 'value':
        // Top products by total value
        data =
            provider.inventory
                .map<Map<String, dynamic>>(
                  (item) => {
                    'Product': item.productName,
                    'SKU': item.productSku,
                    'Quantity': item.quantity.toString(),
                    'Unit Price': '\$${item.unitPrice.toStringAsFixed(2)}',
                    'Total Value': '\$${item.totalValue.toStringAsFixed(2)}',
                    'Low Stock': item.isLowStock ? 'Yes' : 'No',
                  },
                )
                .toList()
              ..sort(
                (a, b) => double.parse(b['Total Value'].replaceAll('\$', ''))
                    .compareTo(
                      double.parse(a['Total Value'].replaceAll('\$', '')),
                    ),
              );
        break;

      case 'price':
        // Top products by unit price
        data =
            provider.inventory
                .map<Map<String, dynamic>>(
                  (item) => {
                    'Product': item.productName,
                    'SKU': item.productSku,
                    'Quantity': item.quantity.toString(),
                    'Unit Price': '\$${item.unitPrice.toStringAsFixed(2)}',
                    'Total Value': '\$${item.totalValue.toStringAsFixed(2)}',
                    'Low Stock': item.isLowStock ? 'Yes' : 'No',
                  },
                )
                .toList()
              ..sort(
                (a, b) => double.parse(
                  b['Unit Price'].replaceAll('\$', ''),
                ).compareTo(double.parse(a['Unit Price'].replaceAll('\$', ''))),
              );
        break;

      default:
        // Default to quantity ranking
        data =
            provider.inventory
                .map<Map<String, dynamic>>(
                  (item) => {
                    'Product': item.productName,
                    'SKU': item.productSku,
                    'Quantity': item.quantity.toString(),
                    'Unit Price': '\$${item.unitPrice.toStringAsFixed(2)}',
                    'Total Value': '\$${item.totalValue.toStringAsFixed(2)}',
                    'Low Stock': item.isLowStock ? 'Yes' : 'No',
                  },
                )
                .toList()
              ..sort(
                (a, b) => int.parse(
                  b['Quantity'],
                ).compareTo(int.parse(a['Quantity'])),
              );
        break;
    }

    // Take only the top N items
    filteredData = data.take(limit).toList();
  }

  // Extract number from query (e.g., "top 5" -> 5)
  int _extractNumberFromQuery(String query) {
    RegExp regex = RegExp(r'\d+');
    Match? match = regex.firstMatch(query);
    return match != null ? int.parse(match.group(0)!) : 0;
  }

  // Determine ranking criteria based on query
  String _determineRankingCriteria(String query) {
    if (query.contains('value') ||
        query.contains('worth') ||
        query.contains('expensive')) {
      return 'value';
    } else if (query.contains('price') || query.contains('cost')) {
      return 'price';
    } else if (query.contains('quantity') ||
        query.contains('stock') ||
        query.contains('amount')) {
      return 'quantity';
    } else {
      return 'quantity'; // Default to quantity
    }
  }

  // Extract meaningful search terms from user query
  List<String> _extractSearchTerms(String query) {
    // Common pharmacy product keywords
    List<String> pharmacyKeywords = [
      'dental',
      'floss',
      'toothpaste',
      'tooth',
      'brush',
      'vitamin',
      'supplement',
      'medicine',
      'drug',
      'pill',
      'tablet',
      'capsule',
      'syrup',
      'cream',
      'gel',
      'ointment',
      'drops',
      'spray',
      'inhaler',
      'bandage',
      'gauze',
      'cotton',
      'alcohol',
      'antiseptic',
      'antibiotic',
      'pain',
      'fever',
      'cold',
      'flu',
      'allergy',
      'diabetes',
      'blood',
      'pressure',
      'heart',
      'cholesterol',
      'baby',
      'diaper',
      'wipe',
      'formula',
      'milk',
      'adult',
      'senior',
      'men',
      'women',
      'prenatal',
      'iron',
      'calcium',
      'magnesium',
      'zinc',
      'omega',
      'fish',
      'oil',
      'probiotic',
      'enzyme',
      'hormone',
      'testosterone',
      'prostate',
      'eye',
      'ear',
      'nose',
      'throat',
      'skin',
      'hair',
      'nail',
      'sunscreen',
      'lotion',
      'soap',
      'shampoo',
      'conditioner',
      'deodorant',
      'perfume',
      'cosmetic',
      'makeup',
      'razor',
      'blade',
      'shave',
      'trim',
      'reading',
      'glasses',
      'contact',
      'lens',
      'hearing',
      'aid',
      'cane',
      'walker',
      'wheelchair',
      'crutch',
      'brace',
      'splint',
      'cast',
      'tape',
      'adhesive',
      'band',
      'plaster',
      'thermometer',
      'scale',
      'monitor',
      'device',
      'equipment',
      'tool',
      'instrument',
      'machine',
      'apparatus',
    ];

    // Split query into words and filter meaningful terms
    List<String> words = query
        .split(' ')
        .where((word) => word.length > 2) // Filter out short words
        .map((word) => word.toLowerCase())
        .toList();

    // Add pharmacy-specific keywords that match the query
    List<String> searchTerms = [];

    // Add individual words from query
    searchTerms.addAll(words);

    // Add pharmacy keywords that are mentioned in the query
    for (String keyword in pharmacyKeywords) {
      if (query.contains(keyword)) {
        searchTerms.add(keyword);
      }
    }

    // Remove duplicates and return
    return searchTerms.toSet().toList();
  }

  // Extract specific products mentioned in the AI response
  List<String> _extractProductsFromAIResponse() {
    List<String> mentionedProducts = [];

    // Check if the dataContext has any specific product information
    if (widget.dataContext.containsKey('mentioned_products')) {
      mentionedProducts = List<String>.from(
        widget.dataContext['mentioned_products'],
      );
    }

    // Also extract from user query
    List<String> queryProducts = _extractSearchTerms(widget.userQuery);
    mentionedProducts.addAll(queryProducts);

    // Remove duplicates and return
    return mentionedProducts.toSet().toList();
  }

  // Show only the products mentioned in the AI response
  void _showMentionedProducts(
    List<String> mentionedProducts,
    dynamic provider,
  ) {
    List<Map<String, dynamic>> matchingProducts = [];

    // Search through inventory for exact matches
    for (final item in provider.inventory) {
      String productName = item.productName.toLowerCase();
      String sku = item.productSku.toLowerCase();

      // Check if this product was mentioned
      bool isMentioned = mentionedProducts.any((term) {
        String termLower = term.toLowerCase();
        return productName.contains(termLower) || sku.contains(termLower);
      });

      if (isMentioned) {
        matchingProducts.add({
          'Product': item.productName,
          'SKU': item.productSku,
          'Quantity': item.quantity.toString(),
          'Unit Price': '\$${item.unitPrice.toStringAsFixed(2)}',
          'Total Value': '\$${item.totalValue.toStringAsFixed(2)}',
          'Low Stock': item.isLowStock ? 'Yes' : 'No',
        });
      }
    }

    // If no exact matches found, try partial matches
    if (matchingProducts.isEmpty) {
      for (final item in provider.inventory) {
        String productName = item.productName.toLowerCase();
        String sku = item.productSku.toLowerCase();

        // Check for partial matches
        bool isPartialMatch = mentionedProducts.any((term) {
          String termLower = term.toLowerCase();
          // Split terms and check if any part matches
          List<String> termParts = termLower.split(' ');
          return termParts.any(
            (part) => productName.contains(part) || sku.contains(part),
          );
        });

        if (isPartialMatch) {
          matchingProducts.add({
            'Product': item.productName,
            'SKU': item.productSku,
            'Quantity': item.quantity.toString(),
            'Unit Price': '\$${item.unitPrice.toStringAsFixed(2)}',
            'Total Value': '\$${item.totalValue.toStringAsFixed(2)}',
            'Low Stock': item.isLowStock ? 'Yes' : 'No',
          });
        }
      }
    }

    filteredData = matchingProducts;
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
