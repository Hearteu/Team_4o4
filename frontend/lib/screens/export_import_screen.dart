import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../theme/app_theme.dart';

class ExportImportScreen extends StatefulWidget {
  const ExportImportScreen({super.key});

  @override
  State<ExportImportScreen> createState() => _ExportImportScreenState();
}

class _ExportImportScreenState extends State<ExportImportScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _importStatus;
  String? _importError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Export & Import'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Export Data', Icons.download),
            const SizedBox(height: 16),
            _buildExportSection(),
            const SizedBox(height: 32),
            _buildSectionHeader('Import Data', Icons.upload),
            const SizedBox(height: 16),
            _buildImportSection(),
            const SizedBox(height: 32),
            _buildSectionHeader('Templates', Icons.description),
            const SizedBox(height: 16),
            _buildTemplatesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.heading2.copyWith(color: AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildExportSection() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _buildExportCard(
              'Export All Data',
              'Export all data to CSV and JSON formats',
              Icons.archive,
              () => _exportAllData(provider),
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              'Export Products',
              'Export products list to CSV',
              Icons.inventory,
              () => _exportProducts(provider),
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              'Export Inventory',
              'Export current inventory status',
              Icons.assessment,
              () => _exportInventory(provider),
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              'Export Transactions',
              'Export transaction history',
              Icons.receipt_long,
              () => _exportTransactions(provider),
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              'Export Categories',
              'Export product categories',
              Icons.category,
              () => _exportCategories(provider),
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              'Export Suppliers',
              'Export supplier information',
              Icons.business,
              () => _exportSuppliers(provider),
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              'Low Stock Report',
              'Export low stock items report',
              Icons.warning,
              () => _exportLowStockReport(provider),
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              'Sales Report',
              'Export sales transaction report',
              Icons.trending_up,
              () => _exportSalesReport(provider),
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              'Purchase Report',
              'Export purchase transaction report',
              Icons.shopping_cart,
              () => _exportPurchaseReport(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExportCard(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: AppTheme.bodyLarge),
        subtitle: Text(description, style: AppTheme.bodyMedium),
        trailing: _isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _isExporting ? null : onTap,
      ),
    );
  }

  Widget _buildImportSection() {
    return Column(
      children: [
        _buildImportCard(
          'Import Products',
          'Import products from CSV file',
          Icons.inventory,
          () => _importProducts(),
        ),
        const SizedBox(height: 12),
        _buildImportCard(
          'Import Categories',
          'Import categories from CSV file',
          Icons.category,
          () => _importCategories(),
        ),
        const SizedBox(height: 12),
        _buildImportCard(
          'Import Suppliers',
          'Import suppliers from CSV file',
          Icons.business,
          () => _importSuppliers(),
        ),
        const SizedBox(height: 12),
        _buildImportCard(
          'Import Transactions',
          'Import transactions from CSV file',
          Icons.receipt_long,
          () => _importTransactions(),
        ),
        if (_importStatus != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _importStatus!,
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_importError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _importError!,
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImportCard(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: AppTheme.bodyLarge),
        subtitle: Text(description, style: AppTheme.bodyMedium),
        trailing: _isImporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _isImporting ? null : onTap,
      ),
    );
  }

  Widget _buildTemplatesSection() {
    return Column(
      children: [
        _buildTemplateCard(
          'Product Template',
          'Download CSV template for products',
          Icons.inventory,
          () => _downloadProductTemplate(),
        ),
        const SizedBox(height: 12),
        _buildTemplateCard(
          'Category Template',
          'Download CSV template for categories',
          Icons.category,
          () => _downloadCategoryTemplate(),
        ),
        const SizedBox(height: 12),
        _buildTemplateCard(
          'Supplier Template',
          'Download CSV template for suppliers',
          Icons.business,
          () => _downloadSupplierTemplate(),
        ),
        const SizedBox(height: 12),
        _buildTemplateCard(
          'Transaction Template',
          'Download CSV template for transactions',
          Icons.receipt_long,
          () => _downloadTransactionTemplate(),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: AppTheme.bodyLarge),
        subtitle: Text(description, style: AppTheme.bodyMedium),
        trailing: const Icon(Icons.download, color: AppTheme.primaryColor),
        onTap: onTap,
      ),
    );
  }

  // Export methods
  void _exportAllData(InventoryProvider provider) async {
    setState(() => _isExporting = true);
    try {
      ExportService.exportAllData(
        products: provider.products,
        inventory: provider.inventory,
        transactions: provider.transactions,
        categories: provider.categories,
        suppliers: provider.suppliers,
      );
      _showSnackBar('All data exported successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error exporting data: $e', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _exportProducts(InventoryProvider provider) async {
    setState(() => _isExporting = true);
    try {
      ExportService.exportProducts(provider.products);
      _showSnackBar('Products exported successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error exporting products: $e', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _exportInventory(InventoryProvider provider) async {
    setState(() => _isExporting = true);
    try {
      ExportService.exportInventory(provider.inventory);
      _showSnackBar('Inventory exported successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error exporting inventory: $e', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _exportTransactions(InventoryProvider provider) async {
    setState(() => _isExporting = true);
    try {
      ExportService.exportTransactions(provider.transactions);
      _showSnackBar('Transactions exported successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error exporting transactions: $e', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _exportCategories(InventoryProvider provider) async {
    setState(() => _isExporting = true);
    try {
      ExportService.exportCategories(provider.categories);
      _showSnackBar('Categories exported successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error exporting categories: $e', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _exportSuppliers(InventoryProvider provider) async {
    setState(() => _isExporting = true);
    try {
      ExportService.exportSuppliers(provider.suppliers);
      _showSnackBar('Suppliers exported successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error exporting suppliers: $e', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _exportLowStockReport(InventoryProvider provider) async {
    setState(() => _isExporting = true);
    try {
      ExportService.exportLowStockReport(provider.inventory);
      _showSnackBar('Low stock report exported successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error exporting low stock report: $e', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _exportSalesReport(InventoryProvider provider) async {
    setState(() => _isExporting = true);
    try {
      ExportService.exportSalesReport(provider.transactions);
      _showSnackBar('Sales report exported successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error exporting sales report: $e', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _exportPurchaseReport(InventoryProvider provider) async {
    setState(() => _isExporting = true);
    try {
      ExportService.exportPurchaseReport(provider.transactions);
      _showSnackBar('Purchase report exported successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error exporting purchase report: $e', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // Import methods
  void _importProducts() async {
    final input = html.FileUploadInputElement()..accept = '.csv';
    input.click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        setState(() {
          _isImporting = true;
          _importStatus = null;
          _importError = null;
        });

        try {
          final products = await ImportService.importProductsFromCSV(
            files.first,
          );
          await ImportService.bulkImportProducts(products);

          setState(() {
            _importStatus =
                'Successfully imported ${products.length} products!';
          });

          // Refresh data
          context.read<InventoryProvider>().refreshData();
        } catch (e) {
          setState(() {
            _importError = 'Error importing products: $e';
          });
        } finally {
          setState(() => _isImporting = false);
        }
      }
    });
  }

  void _importCategories() async {
    final input = html.FileUploadInputElement()..accept = '.csv';
    input.click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        setState(() {
          _isImporting = true;
          _importStatus = null;
          _importError = null;
        });

        try {
          final categories = await ImportService.importCategoriesFromCSV(
            files.first,
          );
          await ImportService.bulkImportCategories(categories);

          setState(() {
            _importStatus =
                'Successfully imported ${categories.length} categories!';
          });

          // Refresh data
          context.read<InventoryProvider>().refreshData();
        } catch (e) {
          setState(() {
            _importError = 'Error importing categories: $e';
          });
        } finally {
          setState(() => _isImporting = false);
        }
      }
    });
  }

  void _importSuppliers() async {
    final input = html.FileUploadInputElement()..accept = '.csv';
    input.click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        setState(() {
          _isImporting = true;
          _importStatus = null;
          _importError = null;
        });

        try {
          final suppliers = await ImportService.importSuppliersFromCSV(
            files.first,
          );
          await ImportService.bulkImportSuppliers(suppliers);

          setState(() {
            _importStatus =
                'Successfully imported ${suppliers.length} suppliers!';
          });

          // Refresh data
          context.read<InventoryProvider>().refreshData();
        } catch (e) {
          setState(() {
            _importError = 'Error importing suppliers: $e';
          });
        } finally {
          setState(() => _isImporting = false);
        }
      }
    });
  }

  void _importTransactions() async {
    final input = html.FileUploadInputElement()..accept = '.csv';
    input.click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        setState(() {
          _isImporting = true;
          _importStatus = null;
          _importError = null;
        });

        try {
          final transactions = await ImportService.importTransactionsFromCSV(
            files.first,
          );
          await ImportService.bulkImportTransactions(transactions);

          setState(() {
            _importStatus =
                'Successfully imported ${transactions.length} transactions!';
          });

          // Refresh data
          context.read<InventoryProvider>().refreshData();
        } catch (e) {
          setState(() {
            _importError = 'Error importing transactions: $e';
          });
        } finally {
          setState(() => _isImporting = false);
        }
      }
    });
  }

  // Template download methods
  void _downloadProductTemplate() {
    final template = ImportService.getProductCSVTemplate();
    _downloadCSV(template, 'medeasy_product_template.csv');
  }

  void _downloadCategoryTemplate() {
    final template = ImportService.getCategoryCSVTemplate();
    _downloadCSV(template, 'medeasy_category_template.csv');
  }

  void _downloadSupplierTemplate() {
    final template = ImportService.getSupplierCSVTemplate();
    _downloadCSV(template, 'medeasy_supplier_template.csv');
  }

  void _downloadTransactionTemplate() {
    final template = ImportService.getTransactionCSVTemplate();
    _downloadCSV(template, 'medeasy_transaction_template.csv');
  }

  void _downloadCSV(List<List<String>> csvData, String filename) {
    final csvString = const ListToCsvConverter().convert(csvData);
    final bytes = utf8.encode(csvString);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
