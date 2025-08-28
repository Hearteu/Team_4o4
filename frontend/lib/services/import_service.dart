import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/inventory.dart';
import '../models/transaction.dart';
import '../models/category.dart' as app_category;
import '../models/supplier.dart';
import 'api_service.dart';

class ImportService {
  // Import products from CSV
  static Future<List<Map<String, dynamic>>> importProductsFromCSV(
    html.File file,
  ) async {
    try {
      final csvString = await _readFileAsText(file);
      final csvData = const CsvToListConverter().convert(csvString);

      if (csvData.isEmpty || csvData.length < 2) {
        throw Exception('Invalid CSV file: No data found');
      }

      final headers = csvData[0];
      final data = csvData.skip(1).toList();

      final products = <Map<String, dynamic>>[];

      for (final row in data) {
        if (row.length >= headers.length) {
          final product = <String, dynamic>{};
          for (int i = 0; i < headers.length; i++) {
            final header = headers[i].toString().toLowerCase();
            final value = row[i];

            switch (header) {
              case 'name':
                product['name'] = value.toString();
                break;
              case 'sku':
                product['sku'] = value.toString();
                break;
              case 'description':
                product['description'] = value.toString();
                break;
              case 'unit_price':
                product['unit_price'] =
                    double.tryParse(value.toString()) ?? 0.0;
                break;
              case 'cost_price':
                product['cost_price'] =
                    double.tryParse(value.toString()) ?? 0.0;
                break;
              case 'reorder_level':
                product['reorder_level'] = int.tryParse(value.toString()) ?? 0;
                break;
              case 'is_active':
                product['is_active'] = value.toString().toLowerCase() == 'true';
                break;
            }
          }
          products.add(product);
        }
      }

      debugPrint('✅ Imported ${products.length} products from CSV');
      return products;
    } catch (e) {
      debugPrint('❌ Error importing products from CSV: $e');
      rethrow;
    }
  }

  // Import categories from CSV
  static Future<List<Map<String, dynamic>>> importCategoriesFromCSV(
    html.File file,
  ) async {
    try {
      final csvString = await _readFileAsText(file);
      final csvData = const CsvToListConverter().convert(csvString);

      if (csvData.isEmpty || csvData.length < 2) {
        throw Exception('Invalid CSV file: No data found');
      }

      final headers = csvData[0];
      final data = csvData.skip(1).toList();

      final categories = <Map<String, dynamic>>[];

      for (final row in data) {
        if (row.length >= headers.length) {
          final category = <String, dynamic>{};
          for (int i = 0; i < headers.length; i++) {
            final header = headers[i].toString().toLowerCase();
            final value = row[i];

            switch (header) {
              case 'name':
                category['name'] = value.toString();
                break;
              case 'description':
                category['description'] = value.toString();
                break;
            }
          }
          categories.add(category);
        }
      }

      debugPrint('✅ Imported ${categories.length} categories from CSV');
      return categories;
    } catch (e) {
      debugPrint('❌ Error importing categories from CSV: $e');
      rethrow;
    }
  }

  // Import suppliers from CSV
  static Future<List<Map<String, dynamic>>> importSuppliersFromCSV(
    html.File file,
  ) async {
    try {
      final csvString = await _readFileAsText(file);
      final csvData = const CsvToListConverter().convert(csvString);

      if (csvData.isEmpty || csvData.length < 2) {
        throw Exception('Invalid CSV file: No data found');
      }

      final headers = csvData[0];
      final data = csvData.skip(1).toList();

      final suppliers = <Map<String, dynamic>>[];

      for (final row in data) {
        if (row.length >= headers.length) {
          final supplier = <String, dynamic>{};
          for (int i = 0; i < headers.length; i++) {
            final header = headers[i].toString().toLowerCase();
            final value = row[i];

            switch (header) {
              case 'name':
                supplier['name'] = value.toString();
                break;
              case 'contact_person':
                supplier['contact_person'] = value.toString();
                break;
              case 'email':
                supplier['email'] = value.toString();
                break;
              case 'phone':
                supplier['phone'] = value.toString();
                break;
              case 'address':
                supplier['address'] = value.toString();
                break;
              case 'is_active':
                supplier['is_active'] =
                    value.toString().toLowerCase() == 'true';
                break;
            }
          }
          suppliers.add(supplier);
        }
      }

      debugPrint('✅ Imported ${suppliers.length} suppliers from CSV');
      return suppliers;
    } catch (e) {
      debugPrint('❌ Error importing suppliers from CSV: $e');
      rethrow;
    }
  }

  // Import transactions from CSV
  static Future<List<Map<String, dynamic>>> importTransactionsFromCSV(
    html.File file,
  ) async {
    try {
      final csvString = await _readFileAsText(file);
      final csvData = const CsvToListConverter().convert(csvString);

      if (csvData.isEmpty || csvData.length < 2) {
        throw Exception('Invalid CSV file: No data found');
      }

      final headers = csvData[0];
      final data = csvData.skip(1).toList();

      final transactions = <Map<String, dynamic>>[];

      for (final row in data) {
        if (row.length >= headers.length) {
          final transaction = <String, dynamic>{};
          for (int i = 0; i < headers.length; i++) {
            final header = headers[i].toString().toLowerCase();
            final value = row[i];

            switch (header) {
              case 'product_sku':
                transaction['product_sku'] = value.toString();
                break;
              case 'transaction_type':
                transaction['transaction_type'] = value
                    .toString()
                    .toUpperCase();
                break;
              case 'quantity':
                transaction['quantity'] = int.tryParse(value.toString()) ?? 0;
                break;
              case 'unit_price':
                transaction['unit_price'] =
                    double.tryParse(value.toString()) ?? 0.0;
                break;
              case 'reference':
                transaction['reference'] = value.toString();
                break;
              case 'notes':
                transaction['notes'] = value.toString();
                break;
            }
          }
          transactions.add(transaction);
        }
      }

      debugPrint('✅ Imported ${transactions.length} transactions from CSV');
      return transactions;
    } catch (e) {
      debugPrint('❌ Error importing transactions from CSV: $e');
      rethrow;
    }
  }

  // Import from JSON format
  static Future<Map<String, dynamic>> importFromJSON(html.File file) async {
    try {
      final jsonString = await _readFileAsText(file);
      final data = json.decode(jsonString) as Map<String, dynamic>;

      debugPrint('✅ Imported data from JSON');
      return data;
    } catch (e) {
      debugPrint('❌ Error importing from JSON: $e');
      rethrow;
    }
  }

  // Bulk import products
  static Future<void> bulkImportProducts(
    List<Map<String, dynamic>> products,
  ) async {
    try {
      for (final product in products) {
        await ApiService.createProduct(product);
      }
      debugPrint('✅ Successfully imported ${products.length} products');
    } catch (e) {
      debugPrint('❌ Error bulk importing products: $e');
      rethrow;
    }
  }

  // Bulk import categories
  static Future<void> bulkImportCategories(
    List<Map<String, dynamic>> categories,
  ) async {
    try {
      for (final category in categories) {
        await ApiService.createCategory(category);
      }
      debugPrint('✅ Successfully imported ${categories.length} categories');
    } catch (e) {
      debugPrint('❌ Error bulk importing categories: $e');
      rethrow;
    }
  }

  // Bulk import suppliers
  static Future<void> bulkImportSuppliers(
    List<Map<String, dynamic>> suppliers,
  ) async {
    try {
      for (final supplier in suppliers) {
        await ApiService.createSupplier(supplier);
      }
      debugPrint('✅ Successfully imported ${suppliers.length} suppliers');
    } catch (e) {
      debugPrint('❌ Error bulk importing suppliers: $e');
      rethrow;
    }
  }

  // Bulk import transactions
  static Future<void> bulkImportTransactions(
    List<Map<String, dynamic>> transactions,
  ) async {
    try {
      for (final transaction in transactions) {
        await ApiService.createTransaction(transaction);
      }
      debugPrint('✅ Successfully imported ${transactions.length} transactions');
    } catch (e) {
      debugPrint('❌ Error bulk importing transactions: $e');
      rethrow;
    }
  }

  // Helper method to read file as text
  static Future<String> _readFileAsText(html.File file) async {
    final reader = html.FileReader();
    reader.readAsText(file);

    await reader.onLoad.first;
    return reader.result as String;
  }

  // Validate CSV file format
  static bool validateCSVFormat(
    List<List<dynamic>> csvData,
    List<String> requiredHeaders,
  ) {
    if (csvData.isEmpty || csvData.length < 2) {
      return false;
    }

    final headers = csvData[0].map((h) => h.toString().toLowerCase()).toList();

    for (final requiredHeader in requiredHeaders) {
      if (!headers.contains(requiredHeader.toLowerCase())) {
        return false;
      }
    }

    return true;
  }

  // Get CSV template for products
  static List<List<String>> getProductCSVTemplate() {
    return [
      [
        'Name',
        'SKU',
        'Description',
        'Unit Price',
        'Cost Price',
        'Reorder Level',
        'Is Active',
      ],
      [
        'Sample Product',
        'SAMPLE001',
        'Sample description',
        '10.00',
        '8.00',
        '5',
        'true',
      ],
    ];
  }

  // Get CSV template for categories
  static List<List<String>> getCategoryCSVTemplate() {
    return [
      ['Name', 'Description'],
      ['Sample Category', 'Sample category description'],
    ];
  }

  // Get CSV template for suppliers
  static List<List<String>> getSupplierCSVTemplate() {
    return [
      ['Name', 'Contact Person', 'Email', 'Phone', 'Address', 'Is Active'],
      [
        'Sample Supplier',
        'John Doe',
        'john@example.com',
        '+1234567890',
        'Sample Address',
        'true',
      ],
    ];
  }

  // Get CSV template for transactions
  static List<List<String>> getTransactionCSVTemplate() {
    return [
      [
        'Product SKU',
        'Transaction Type',
        'Quantity',
        'Unit Price',
        'Reference',
        'Notes',
      ],
      ['SAMPLE001', 'IN', '10', '8.00', 'PO-001', 'Sample purchase'],
    ];
  }
}
