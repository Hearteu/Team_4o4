import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/inventory.dart';
import '../models/transaction.dart';
import '../models/category.dart' as app_category;
import '../models/supplier.dart';

class ExportService {
  // Export products to CSV
  static void exportProducts(List<Product> products) {
    final csvData = [
      [
        'ID',
        'Name',
        'SKU',
        'Description',
        'Category',
        'Supplier',
        'Unit Price',
        'Selling Price',
        'Reorder Level',
        'Is Active',
        'Created At',
      ],
      ...products.map(
        (product) => [
          product.id.toString(),
          product.name,
          product.sku,
          product.description ?? '',
          product.categoryName,
          product.supplierName,
          product.unitPrice.toString(),
          product.costPrice.toString(),
          product.reorderLevel.toString(),
          product.isActive.toString(),
          product.createdAt.toIso8601String(),
        ],
      ),
    ];

    _downloadCSV(
      csvData,
      'medeasy_products_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
  }

  // Export inventory to CSV
  static void exportInventory(List<Inventory> inventory) {
    final csvData = [
      [
        'ID',
        'Product Name',
        'Product SKU',
        'Quantity',
        'Unit Price',
        'Total Value',
        'Is Low Stock',
        'Last Updated',
      ],
      ...inventory.map(
        (item) => [
          item.id.toString(),
          item.productName,
          item.productSku,
          item.quantity.toString(),
          item.unitPrice.toString() ?? '',
          item.totalValue.toString() ?? '',
          item.isLowStock.toString(),
          item.lastUpdated.toIso8601String(),
        ],
      ),
    ];

    _downloadCSV(
      csvData,
      'medeasy_inventory_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
  }

  // Export transactions to CSV
  static void exportTransactions(List<Transaction> transactions) {
    final csvData = [
      [
        'ID',
        'Product Name',
        'Product SKU',
        'Transaction Type',
        'Quantity',
        'Unit Price',
        'Total Amount',
        'Reference',
        'Notes',
        'Created At',
      ],
      ...transactions.map(
        (transaction) => [
          transaction.id.toString(),
          transaction.productName,
          transaction.productSku,
          transaction.transactionType.name,
          transaction.quantity.toString(),
          transaction.unitPrice?.toString() ?? '',
          transaction.totalAmount?.toString() ?? '',
          transaction.reference,
          transaction.notes,
          transaction.createdAt.toIso8601String(),
        ],
      ),
    ];

    _downloadCSV(
      csvData,
      'medeasy_transactions_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
  }

  // Export categories to CSV
  static void exportCategories(List<app_category.Category> categories) {
    final csvData = [
      ['ID', 'Name', 'Description', 'Is Active', 'Created At'],
      ...categories.map(
        (category) => [
          category.id.toString(),
          category.name,
          category.description ?? '',
          'true', // Category doesn't have isActive field
          category.createdAt.toIso8601String(),
        ],
      ),
    ];

    _downloadCSV(
      csvData,
      'medeasy_categories_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
  }

  // Export suppliers to CSV
  static void exportSuppliers(List<Supplier> suppliers) {
    final csvData = [
      [
        'ID',
        'Name',
        'Contact Person',
        'Email',
        'Phone',
        'Address',
        'Is Active',
        'Created At',
      ],
      ...suppliers.map(
        (supplier) => [
          supplier.id.toString(),
          supplier.name,
          supplier.contactPerson ?? '',
          supplier.email ?? '',
          supplier.phone ?? '',
          supplier.address ?? '',
          supplier.isActive.toString(),
          supplier.createdAt.toIso8601String(),
        ],
      ),
    ];

    _downloadCSV(
      csvData,
      'medeasy_suppliers_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
  }

  // Export all data to CSV
  static void exportAllData({
    required List<Product> products,
    required List<Inventory> inventory,
    required List<Transaction> transactions,
    required List<app_category.Category> categories,
    required List<Supplier> suppliers,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Export each data type to separate files
    exportProducts(products);
    exportInventory(inventory);
    exportTransactions(transactions);
    exportCategories(categories);
    exportSuppliers(suppliers);

    debugPrint('✅ All data exported successfully');
  }

  // Export inventory report (low stock items)
  static void exportLowStockReport(List<Inventory> inventory) {
    final lowStockItems = inventory.where((item) => item.isLowStock).toList();

    final csvData = [
      [
        'Product Name',
        'SKU',
        'Current Stock',
        'Reorder Level',
        'Unit Price',
        'Total Value',
        'Status',
      ],
      ...lowStockItems.map(
        (item) => [
          item.productName,
          item.productSku,
          item.quantity.toString(),
          'Reorder Level', // This would need to be fetched from product
          item.unitPrice.toString() ?? '',
          item.totalValue.toString() ?? '',
          item.quantity == 0 ? 'Out of Stock' : 'Low Stock',
        ],
      ),
    ];

    _downloadCSV(
      csvData,
      'medeasy_low_stock_report_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
  }

  // Export sales report
  static void exportSalesReport(List<Transaction> transactions) {
    final salesTransactions = transactions
        .where((t) => t.transactionType.name == 'OUT')
        .toList();

    final csvData = [
      [
        'Date',
        'Product Name',
        'SKU',
        'Quantity Sold',
        'Unit Price',
        'Total Revenue',
        'Reference',
      ],
      ...salesTransactions.map(
        (transaction) => [
          transaction.createdAt.toIso8601String().split('T')[0],
          transaction.productName,
          transaction.productSku,
          (-transaction.quantity).toString(), // Convert negative to positive
          transaction.unitPrice?.toString() ?? '',
          (-transaction.totalAmount!)
              .toString(), // Convert negative to positive
          transaction.reference,
        ],
      ),
    ];

    _downloadCSV(
      csvData,
      'medeasy_sales_report_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
  }

  // Export purchase report
  static void exportPurchaseReport(List<Transaction> transactions) {
    final purchaseTransactions = transactions
        .where((t) => t.transactionType.name == 'IN')
        .toList();

    final csvData = [
      [
        'Date',
        'Product Name',
        'SKU',
        'Quantity Purchased',
        'Unit Price',
        'Total Cost',
        'Reference',
      ],
      ...purchaseTransactions.map(
        (transaction) => [
          transaction.createdAt.toIso8601String().split('T')[0],
          transaction.productName,
          transaction.productSku,
          transaction.quantity.toString(),
          transaction.unitPrice?.toString() ?? '',
          transaction.totalAmount?.toString() ?? '',
          transaction.reference,
        ],
      ),
    ];

    _downloadCSV(
      csvData,
      'medeasy_purchase_report_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
  }

  // Helper method to download CSV file
  static void _downloadCSV(List<List<dynamic>> csvData, String filename) {
    final csvString = const ListToCsvConverter().convert(csvData);
    final bytes = utf8.encode(csvString);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Export to JSON format
  static void exportToJSON({
    required List<Product> products,
    required List<Inventory> inventory,
    required List<Transaction> transactions,
    required List<app_category.Category> categories,
    required List<Supplier> suppliers,
  }) {
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'products': products.map((p) => p.toJson()).toList(),
      'inventory': inventory.map((i) => i.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'suppliers': suppliers.map((s) => s.toJson()).toList(),
    };

    final jsonString = json.encode(data);
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'medeasy_data_${DateTime.now().millisecondsSinceEpoch}.json',
      )
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
