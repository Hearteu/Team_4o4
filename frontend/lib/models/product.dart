class Product {
  final int id;
  final String name;
  final String sku;
  final String description;
  final int category;
  final String categoryName;
  final int? supplier;
  final String supplierName;
  final double unitPrice;
  final double costPrice;
  final int reorderLevel;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int currentStock;
  final double totalValue;
  final bool isLowStock;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.description,
    required this.category,
    required this.categoryName,
    this.supplier,
    required this.supplierName,
    required this.unitPrice,
    required this.costPrice,
    required this.reorderLevel,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.currentStock,
    required this.totalValue,
    required this.isLowStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      description: json['description'] ?? '',
      category: json['category'],
      categoryName: json['category_name'] ?? '',
      supplier: json['supplier'],
      supplierName: json['supplier_name'] ?? '',
      unitPrice: double.parse(json['unit_price'].toString()),
      costPrice: double.parse(json['cost_price'].toString()),
      reorderLevel: json['reorder_level'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      currentStock: json['current_stock'] ?? 0,
      totalValue: double.parse((json['total_value'] ?? 0).toString()),
      isLowStock: json['is_low_stock'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'description': description,
      'category': category,
      'category_name': categoryName,
      'supplier': supplier,
      'supplier_name': supplierName,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'reorder_level': reorderLevel,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'current_stock': currentStock,
      'total_value': totalValue,
      'is_low_stock': isLowStock,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    String? description,
    int? category,
    String? categoryName,
    int? supplier,
    String? supplierName,
    double? unitPrice,
    double? costPrice,
    int? reorderLevel,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentStock,
    double? totalValue,
    bool? isLowStock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryName: categoryName ?? this.categoryName,
      supplier: supplier ?? this.supplier,
      supplierName: supplierName ?? this.supplierName,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentStock: currentStock ?? this.currentStock,
      totalValue: totalValue ?? this.totalValue,
      isLowStock: isLowStock ?? this.isLowStock,
    );
  }
}
