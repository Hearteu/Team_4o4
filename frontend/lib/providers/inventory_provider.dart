import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../models/supplier.dart';
import '../models/product.dart';
import '../models/inventory.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class InventoryProvider with ChangeNotifier {
  // Data lists
  List<Category> _categories = [];
  List<Supplier> _suppliers = [];
  List<Product> _products = [];
  List<Inventory> _inventory = [];
  List<Transaction> _transactions = [];

  // Loading states
  bool _isLoading = false;
  bool _isDataReady = false;
  String? _error;

  // Getters
  List<Category> get categories => _categories;
  List<Supplier> get suppliers => _suppliers;
  List<Product> get products => _products;
  List<Inventory> get inventory => _inventory;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isDataReady => _isDataReady;
  String? get error => _error;

  // Statistics
  Map<String, dynamic>? _productStats;
  Map<String, dynamic>? _inventorySummary;
  Map<String, dynamic>? _transactionSummary;

  Map<String, dynamic>? get productStats => _productStats;
  Map<String, dynamic>? get inventorySummary => _inventorySummary;
  Map<String, dynamic>? get transactionSummary => _transactionSummary;

  // Initialize data
  Future<void> initializeData() async {
    debugPrint('🔄 Initializing inventory data...');
    try {
      _setLoading(true);

      // Load all data first
      await Future.wait([
        _loadCategoriesInternal(),
        _loadSuppliersInternal(),
        _loadProductsInternal(),
        _loadInventoryInternal(),
        _loadTransactionsInternal(),
      ]);

      // Then calculate statistics after data is loaded
      await _loadStatisticsInternal();

      _isDataReady = true;
      _setError(null);
      debugPrint('✅ Inventory data initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing data: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Internal load methods (without setting loading state)
  Future<void> _loadCategoriesInternal() async {
    try {
      _categories = await ApiService.getCategories();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<void> _loadSuppliersInternal() async {
    try {
      _suppliers = await ApiService.getSuppliers();
    } catch (e) {
      throw Exception('Failed to load suppliers: $e');
    }
  }

  Future<void> _loadProductsInternal() async {
    try {
      _products = await ApiService.getProducts();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Future<void> _loadInventoryInternal() async {
    try {
      _inventory = await ApiService.getInventory();
    } catch (e) {
      throw Exception('Failed to load inventory: $e');
    }
  }

  Future<void> _loadTransactionsInternal() async {
    try {
      _transactions = await ApiService.getTransactions();
      print('📋 InventoryProvider: Loaded ${_transactions.length} transactions');
      
      // Debug: Count by type
      final stockIn = _transactions.where((t) => t.transactionType == TransactionType.IN).length;
      final stockOut = _transactions.where((t) => t.transactionType == TransactionType.OUT).length;
      print('  Stock IN: $stockIn, Stock OUT: $stockOut');
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }

  Future<void> _loadStatisticsInternal() async {
    try {
      await Future.wait([
        _loadProductStats(),
        _loadInventorySummary(),
        _loadTransactionSummary(),
      ]);
    } catch (e) {
      throw Exception('Failed to load statistics: $e');
    }
  }

  // Reset data ready flag when data changes
  void _resetDataReady() {
    _isDataReady = false;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      _setLoading(true);
      _resetDataReady();
      _categories = await ApiService.getCategories();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load suppliers
  Future<void> loadSuppliers() async {
    try {
      _setLoading(true);
      _resetDataReady();
      _suppliers = await ApiService.getSuppliers();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load products
  Future<void> loadProducts() async {
    try {
      _setLoading(true);
      _resetDataReady();
      _products = await ApiService.getProducts();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load inventory
  Future<void> loadInventory() async {
    try {
      _setLoading(true);
      _resetDataReady();
      _inventory = await ApiService.getInventory();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load transactions
  Future<void> loadTransactions() async {
    try {
      _setLoading(true);
      _resetDataReady();
      _transactions = await ApiService.getTransactions();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    debugPrint('🔄 Refreshing statistics...');
    try {
      await _loadStatisticsInternal();
      debugPrint('✅ Statistics refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing statistics: $e');
      _setError(e.toString());
    }
  }

  Future<void> _loadProductStats() async {
    // Calculate real statistics from actual data
    final lowStockCount = _products
        .where((product) => product.isLowStock)
        .length;
    final outOfStockCount = _products
        .where((product) => product.currentStock == 0)
        .length;

    debugPrint('🔍 Low stock calculation:');
    debugPrint('   Total products: ${_products.length}');
    debugPrint('   Low stock products: $lowStockCount');
    debugPrint('   Out of stock products: $outOfStockCount');

    // Log low stock products for debugging
    final lowStockProducts = _products
        .where((product) => product.isLowStock)
        .toList();
    for (var product in lowStockProducts) {
      debugPrint(
        '   Low stock product: ${product.name} (Qty: ${product.currentStock}, isLowStock: ${product.isLowStock})',
      );
    }

    _productStats = {
      'total_products': _products.length,
      'active_products': _products.where((p) => p.isActive).length,
      'total_categories': _categories.length,
      'total_suppliers': _suppliers.length,
      'total_transactions': _transactions.length,
      'low_stock_items': lowStockCount,
      'out_of_stock_items': outOfStockCount,
      'total_inventory_value': _inventory.fold(
        0.0,
        (sum, item) => sum + item.totalValue,
      ),
      'monthly_revenue': _calculateMonthlyRevenue(),
      'monthly_expenses': _calculateMonthlyExpenses(),
    };
  }

  Future<void> _loadInventorySummary() async {
    // Calculate real inventory summary from actual data
    _inventorySummary = {
      'total_items': _inventory.fold(0, (sum, item) => sum + item.quantity),
      'total_value': _inventory.fold(0.0, (sum, item) => sum + item.totalValue),
      'low_stock_count': _products
          .where((product) => product.isLowStock)
          .length,
      'out_of_stock_count': _products
          .where((product) => product.currentStock == 0)
          .length,
      'categories_count': _categories.length,
    };
  }

  Future<void> _loadTransactionSummary() async {
    // Calculate real transaction summary from actual data
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final thisWeek = now.subtract(Duration(days: now.weekday - 1));
    final today = DateTime(now.year, now.month, now.day);

    final monthlyTransactions = _transactions
        .where((t) => t.createdAt.isAfter(thisMonth))
        .toList();
    final weeklyTransactions = _transactions
        .where((t) => t.createdAt.isAfter(thisWeek))
        .toList();
    final todayTransactions = _transactions
        .where((t) => t.createdAt.isAfter(today))
        .toList();

    final totalRevenue = _transactions
        .where((t) => t.transactionType == TransactionType.OUT)
        .fold(0.0, (sum, t) => sum + (t.quantity * (t.unitPrice ?? 0)));

    final totalExpenses = _transactions
        .where((t) => t.transactionType == TransactionType.IN)
        .fold(0.0, (sum, t) => sum + (t.quantity * (t.unitPrice ?? 0)));

    final monthlyRevenue = monthlyTransactions
        .where((t) => t.transactionType == TransactionType.OUT)
        .fold(0.0, (sum, t) => sum + (t.quantity * (t.unitPrice ?? 0)));

    final monthlyExpenses = monthlyTransactions
        .where((t) => t.transactionType == TransactionType.IN)
        .fold(0.0, (sum, t) => sum + (t.quantity * (t.unitPrice ?? 0)));

    _transactionSummary = {
      'total_transactions': _transactions.length,
      'total_revenue': totalRevenue,
      'total_expenses': totalExpenses,
      'net_profit': totalRevenue - totalExpenses,
      'transactions_today': todayTransactions.length,
      'transactions_this_week': weeklyTransactions.length,
      'transactions_this_month': monthlyTransactions.length,
      'monthly_revenue': monthlyRevenue,
      'monthly_expenses': monthlyExpenses,
      'monthly_profit': monthlyRevenue - monthlyExpenses,
    };
  }

  // Calculate monthly revenue from transactions
  double _calculateMonthlyRevenue() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    return _transactions
        .where(
          (t) =>
              t.transactionType == TransactionType.OUT &&
              t.createdAt.isAfter(thisMonth),
        )
        .fold(0.0, (sum, t) => sum + (t.quantity * (t.unitPrice ?? 0)));
  }

  // Calculate monthly expenses from transactions
  double _calculateMonthlyExpenses() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    return _transactions
        .where(
          (t) =>
              t.transactionType == TransactionType.IN &&
              t.createdAt.isAfter(thisMonth),
        )
        .fold(0.0, (sum, t) => sum + (t.quantity * (t.unitPrice ?? 0)));
  }

  // Create category
  Future<void> createCategory(Map<String, dynamic> categoryData) async {
    try {
      _setLoading(true);
      final category = await ApiService.createCategory(categoryData);
      _categories.add(category);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Create supplier
  Future<void> createSupplier(Map<String, dynamic> supplierData) async {
    try {
      _setLoading(true);
      final supplier = await ApiService.createSupplier(supplierData);
      _suppliers.add(supplier);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Create product
  Future<void> createProduct(Map<String, dynamic> productData) async {
    try {
      _setLoading(true);
      final product = await ApiService.createProduct(productData);
      _products.add(product);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Update product
  Future<void> updateProduct(int id, Map<String, dynamic> productData) async {
    try {
      _setLoading(true);
      final updatedProduct = await ApiService.updateProduct(id, productData);
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Delete product
  Future<void> deleteProduct(int id) async {
    try {
      _setLoading(true);
      await ApiService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Create transaction
  Future<void> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      _setLoading(true);
      final transaction = await ApiService.createTransaction(transactionData);
      _transactions.insert(0, transaction);
      await _loadInventoryInternal(); // Refresh inventory after transaction
      await _loadStatisticsInternal(); // Refresh statistics with new data
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get low stock products
  List<Product> get lowStockProducts {
    return _products.where((product) => product.isLowStock).toList();
  }

  // Get out of stock products
  List<Product> get outOfStockProducts {
    return _products.where((product) => product.currentStock == 0).toList();
  }

  // Get recent transactions
  List<Transaction> get recentTransactions {
    return _transactions.take(10).toList();
  }

  // Search products
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    return _products
        .where(
          (product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.sku.toLowerCase().contains(query.toLowerCase()) ||
              product.description.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // Get products by category
  List<Product> getProductsByCategory(int categoryId) {
    return _products
        .where((product) => product.category == categoryId)
        .toList();
  }

  // Get transactions by type
  List<Transaction> getTransactionsByType(String type) {
    return _transactions
        .where((transaction) => transaction.transactionType.name == type)
        .toList();
  }

  // Clear error
  void clearError() {
    _setError(null);
  }

  // Refresh all data
  Future<void> refreshData() async {
    debugPrint('🔄 Refreshing all data...');
    try {
      _isDataReady = false;
      _setLoading(true);

      // Load all data first
      await Future.wait([
        _loadCategoriesInternal(),
        _loadSuppliersInternal(),
        _loadProductsInternal(),
        _loadInventoryInternal(),
        _loadTransactionsInternal(),
      ]);

      // Then calculate statistics after data is loaded
      await _loadStatisticsInternal();

      _isDataReady = true;
      _setError(null);
      debugPrint('✅ Data refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Refresh statistics only
  Future<void> refreshStatistics() async {
    debugPrint('🔄 Refreshing statistics...');
    try {
      await loadStatistics();
      debugPrint('✅ Statistics refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing statistics: $e');
      _setError(e.toString());
    }
  }

  // Real-time statistics getters
  Map<String, dynamic> get realTimeStats {
    if (!_isDataReady) {
      return {
        'total_products': 0,
        'active_products': 0,
        'total_categories': 0,
        'total_suppliers': 0,
        'total_transactions': 0,
        'low_stock_items': 0,
        'out_of_stock_items': 0,
        'total_inventory_value': 0.0,
        'total_inventory_items': 0,
      };
    }

    return {
      'total_products': _products.length,
      'active_products': _products.where((p) => p.isActive).length,
      'total_categories': _categories.length,
      'total_suppliers': _suppliers.length,
      'total_transactions': _transactions.length,
      'low_stock_items': _products
          .where((product) => product.isLowStock)
          .length,
      'out_of_stock_items': _products
          .where((product) => product.currentStock == 0)
          .length,
      'total_inventory_value': _inventory.fold(
        0.0,
        (sum, item) => sum + item.totalValue,
      ),
      'total_inventory_items': _inventory.fold(
        0,
        (sum, item) => sum + item.quantity,
      ),
    };
  }

  Map<String, dynamic> get realTimeTransactionStats {
    if (!_isDataReady) {
      return {
        'total_transactions': 0,
        'total_revenue': 0.0,
        'total_expenses': 0.0,
        'net_profit': 0.0,
        'transactions_today': 0,
        'transactions_this_week': 0,
        'transactions_this_month': 0,
        'monthly_revenue': 0.0,
        'monthly_expenses': 0.0,
        'monthly_profit': 0.0,
      };
    }

    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final thisWeek = now.subtract(Duration(days: now.weekday - 1));
    final today = DateTime(now.year, now.month, now.day);

    final monthlyTransactions = _transactions
        .where((t) => t.createdAt.isAfter(thisMonth))
        .toList();
    final weeklyTransactions = _transactions
        .where((t) => t.createdAt.isAfter(thisWeek))
        .toList();
    final todayTransactions = _transactions
        .where((t) => t.createdAt.isAfter(today))
        .toList();

    final totalRevenue = _transactions
        .where((t) => t.transactionType == TransactionType.OUT)
        .fold(0.0, (sum, t) => sum + (t.quantity * (t.unitPrice ?? 0)));

    final totalExpenses = _transactions
        .where((t) => t.transactionType == TransactionType.IN)
        .fold(0.0, (sum, t) => sum + (t.quantity * (t.unitPrice ?? 0)));

    final monthlyRevenue = monthlyTransactions
        .where((t) => t.transactionType == TransactionType.OUT)
        .fold(0.0, (sum, t) => sum + (t.quantity * (t.unitPrice ?? 0)));

    final monthlyExpenses = monthlyTransactions
        .where((t) => t.transactionType == TransactionType.IN)
        .fold(0.0, (sum, t) => sum + (t.quantity * (t.unitPrice ?? 0)));

    return {
      'total_transactions': _transactions.length,
      'total_revenue': totalRevenue,
      'total_expenses': totalExpenses,
      'net_profit': totalRevenue - totalExpenses,
      'transactions_today': todayTransactions.length,
      'transactions_this_week': weeklyTransactions.length,
      'transactions_this_month': monthlyTransactions.length,
      'monthly_revenue': monthlyRevenue,
      'monthly_expenses': monthlyExpenses,
      'monthly_profit': monthlyRevenue - monthlyExpenses,
    };
  }
}
