import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/supplier.dart';
import '../models/product.dart';
import '../models/inventory.dart';
import '../models/transaction.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api'; // Web localhost

  // Headers for API requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Generic HTTP methods
  static Future<Map<String, dynamic>> _get(String endpoint) async {
    debugPrint('🌐 Making GET request to: $baseUrl$endpoint');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ GET request successful');
        return data;
      } else {
        debugPrint('❌ GET request failed: ${response.statusCode}');
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Network error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> _put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> _delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Category endpoints
  static Future<List<Category>> getCategories() async {
    final data = await _get('/categories/');
    final results = data['results'] as List;
    return results.map((json) => Category.fromJson(json)).toList();
  }

  static Future<Category> createCategory(
    Map<String, dynamic> categoryData,
  ) async {
    final data = await _post('/categories/', categoryData);
    return Category.fromJson(data);
  }

  static Future<Category> updateCategory(
    int id,
    Map<String, dynamic> categoryData,
  ) async {
    final data = await _put('/categories/$id/', categoryData);
    return Category.fromJson(data);
  }

  static Future<void> deleteCategory(int id) async {
    await _delete('/categories/$id/');
  }

  static Future<Map<String, dynamic>> getCategoryStats() async {
    return await _get('/categories/stats/');
  }

  // Supplier endpoints
  static Future<List<Supplier>> getSuppliers() async {
    final data = await _get('/suppliers/');
    final results = data['results'] as List;
    return results.map((json) => Supplier.fromJson(json)).toList();
  }

  static Future<Supplier> createSupplier(
    Map<String, dynamic> supplierData,
  ) async {
    final data = await _post('/suppliers/', supplierData);
    return Supplier.fromJson(data);
  }

  static Future<Supplier> updateSupplier(
    int id,
    Map<String, dynamic> supplierData,
  ) async {
    final data = await _put('/suppliers/$id/', supplierData);
    return Supplier.fromJson(data);
  }

  static Future<void> deleteSupplier(int id) async {
    await _delete('/suppliers/$id/');
  }

  static Future<List<Supplier>> getActiveSuppliers() async {
    final data = await _get('/suppliers/active/');
    final results = data['results'] as List;
    return results.map((json) => Supplier.fromJson(json)).toList();
  }

  // Product endpoints
  static Future<List<Product>> getProducts() async {
    final data = await _get('/products/');
    final results = data['results'] as List;
    return results.map((json) => Product.fromJson(json)).toList();
  }

  static Future<Product> createProduct(Map<String, dynamic> productData) async {
    final data = await _post('/products/', productData);
    return Product.fromJson(data);
  }

  static Future<Product> updateProduct(
    int id,
    Map<String, dynamic> productData,
  ) async {
    final data = await _put('/products/$id/', productData);
    return Product.fromJson(data);
  }

  static Future<void> deleteProduct(int id) async {
    await _delete('/products/$id/');
  }

  static Future<List<Product>> getLowStockProducts() async {
    final data = await _get('/products/low_stock/');
    final results = data['results'] as List;
    return results.map((json) => Product.fromJson(json)).toList();
  }

  static Future<List<Product>> getOutOfStockProducts() async {
    final data = await _get('/products/out_of_stock/');
    final results = data['results'] as List;
    return results.map((json) => Product.fromJson(json)).toList();
  }

  static Future<Map<String, dynamic>> getProductStats() async {
    return await _get('/products/stats/');
  }

  static Future<Transaction> adjustProductStock(
    int productId,
    Map<String, dynamic> stockData,
  ) async {
    final data = await _post('/products/$productId/adjust_stock/', stockData);
    return Transaction.fromJson(data);
  }

  // Inventory endpoints
  static Future<List<Inventory>> getInventory() async {
    List<Inventory> allInventory = [];
    String? nextUrl = '/inventory/';

    while (nextUrl != null) {
      final data = await _get(nextUrl);
      final results = data['results'] as List;
      allInventory.addAll(results.map((json) => Inventory.fromJson(json)));

      // Get next page URL
      nextUrl = data['next'];
      if (nextUrl != null) {
        // Extract just the path from the full URL, removing /api/ prefix
        final uri = Uri.parse(nextUrl);
        String path = uri.path;
        if (path.startsWith('/api/')) {
          path = path.substring(4); // Remove '/api/' prefix
        }
        nextUrl = path + (uri.query.isNotEmpty ? '?${uri.query}' : '');
      }
    }

    return allInventory;
  }

  static Future<List<Inventory>> getLowStockInventory() async {
    List<Inventory> allInventory = [];
    String? nextUrl = '/inventory/low_stock/';

    while (nextUrl != null) {
      final data = await _get(nextUrl);
      final results = data['results'] as List;
      allInventory.addAll(results.map((json) => Inventory.fromJson(json)));

      // Get next page URL
      nextUrl = data['next'];
      if (nextUrl != null) {
        // Extract just the path from the full URL, removing /api/ prefix
        final uri = Uri.parse(nextUrl);
        String path = uri.path;
        if (path.startsWith('/api/')) {
          path = path.substring(4); // Remove '/api/' prefix
        }
        nextUrl = path + (uri.query.isNotEmpty ? '?${uri.query}' : '');
      }
    }

    return allInventory;
  }

  static Future<Map<String, dynamic>> getInventorySummary() async {
    return await _get('/inventory/summary/');
  }

  // Transaction endpoints
  static Future<List<Transaction>> getTransactions() async {
    List<Transaction> allTransactions = [];
    String? nextUrl = '/transactions/';
    int pageCount = 0;

    while (nextUrl != null) {
      pageCount++;
      print('🔍 Fetching transactions page $pageCount: $nextUrl');

      final data = await _get(nextUrl);
      final results = data['results'] as List;
      allTransactions.addAll(results.map((json) => Transaction.fromJson(json)));

      print(
        '📊 Page $pageCount: ${results.length} transactions, Total so far: ${allTransactions.length}',
      );

      // Get next page URL
      nextUrl = data['next'];
      if (nextUrl != null) {
        // Extract just the path from the full URL, removing /api/ prefix
        final uri = Uri.parse(nextUrl);
        String path = uri.path;
        if (path.startsWith('/api/')) {
          path = path.substring(4); // Remove '/api/' prefix
        }
        nextUrl = path + (uri.query.isNotEmpty ? '?${uri.query}' : '');
        print('🔄 Next URL: $nextUrl');
      } else {
        print('✅ No more pages');
      }
    }

    print('🎯 Total transactions loaded: ${allTransactions.length}');
    return allTransactions;
  }

  static Future<Transaction> createTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    final data = await _post('/transactions/', transactionData);
    return Transaction.fromJson(data);
  }

  static Future<Transaction> updateTransaction(
    int id,
    Map<String, dynamic> transactionData,
  ) async {
    final data = await _put('/transactions/$id/', transactionData);
    return Transaction.fromJson(data);
  }

  static Future<void> deleteTransaction(int id) async {
    await _delete('/transactions/$id/');
  }

  static Future<List<Transaction>> getRecentTransactions() async {
    final data = await _get('/transactions/recent/');
    final results = data['results'] as List;
    return results.map((json) => Transaction.fromJson(json)).toList();
  }

  static Future<List<Transaction>> getTodayTransactions() async {
    final data = await _get('/transactions/today/');
    final results = data['results'] as List;
    return results.map((json) => Transaction.fromJson(json)).toList();
  }

  static Future<Map<String, dynamic>> getTransactionSummary() async {
    return await _get('/transactions/summary/');
  }

  static Future<List<Transaction>> bulkStockIn(
    Map<String, dynamic> bulkData,
  ) async {
    final data = await _post('/transactions/bulk_stock_in/', bulkData);
    final results = data['results'] as List;
    return results.map((json) => Transaction.fromJson(json)).toList();
  }

  // Search and filter methods
  static Future<List<Product>> searchProducts(String query) async {
    final data = await _get('/products/?search=$query');
    final results = data['results'] as List;
    return results.map((json) => Product.fromJson(json)).toList();
  }

  static Future<List<Product>> getProductsByCategory(int categoryId) async {
    final data = await _get('/products/?category=$categoryId');
    final results = data['results'] as List;
    return results.map((json) => Product.fromJson(json)).toList();
  }

  static Future<List<Transaction>> getTransactionsByType(String type) async {
    final data = await _get('/transactions/?transaction_type=$type');
    final results = data['results'] as List;
    return results.map((json) => Transaction.fromJson(json)).toList();
  }
}
