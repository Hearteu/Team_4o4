import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../models/supplier.dart';
import '../models/product.dart';
import '../models/inventory.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/dummy_data_service.dart';

class InventoryProvider with ChangeNotifier {
  // Data lists
  List<Category> _categories = [];
  List<Supplier> _suppliers = [];
  List<Product> _products = [];
  List<Inventory> _inventory = [];
  List<Transaction> _transactions = [];

  // Loading states
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Category> get categories => _categories;
  List<Supplier> get suppliers => _suppliers;
  List<Product> get products => _products;
  List<Inventory> get inventory => _inventory;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
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
      await Future.wait([
        loadCategories(),
        loadSuppliers(),
        loadProducts(),
        loadInventory(),
        loadTransactions(),
        loadStatistics(),
      ]);
      debugPrint('✅ Inventory data initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing data: $e');
      _setError(e.toString());
    }
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
    try {
      _setLoading(true);
      await Future.wait([
        _loadProductStats(),
        _loadInventorySummary(),
        _loadTransactionSummary(),
      ]);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadProductStats() async {
    // Use dummy data instead of API call
    _productStats = DummyDataService.getDummyStats();
  }

  Future<void> _loadInventorySummary() async {
    // Use dummy data instead of API call
    _inventorySummary = DummyDataService.getDummyInventorySummary();
  }

  Future<void> _loadTransactionSummary() async {
    // Use dummy data instead of API call
    _transactionSummary = DummyDataService.getDummyTransactionSummary();
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

  // Create transaction
  Future<void> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      _setLoading(true);
      final transaction = await ApiService.createTransaction(transactionData);
      _transactions.insert(0, transaction);
      await loadInventory(); // Refresh inventory after transaction
      await loadStatistics(); // Refresh statistics
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
    await initializeData();
  }
}
