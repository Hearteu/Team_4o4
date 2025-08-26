class Inventory {
  final int id;
  final int product;
  final String productName;
  final String productSku;
  final int quantity;
  final double unitPrice;
  final double totalValue;
  final bool isLowStock;
  final DateTime lastUpdated;

  Inventory({
    required this.id,
    required this.product,
    required this.productName,
    required this.productSku,
    required this.quantity,
    required this.unitPrice,
    required this.totalValue,
    required this.isLowStock,
    required this.lastUpdated,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'],
      product: json['product'],
      productName: json['product_name'] ?? '',
      productSku: json['product_sku'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: double.parse((json['unit_price'] ?? 0).toString()),
      totalValue: double.parse((json['total_value'] ?? 0).toString()),
      isLowStock: json['is_low_stock'] ?? false,
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'product_name': productName,
      'product_sku': productSku,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_value': totalValue,
      'is_low_stock': isLowStock,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  Inventory copyWith({
    int? id,
    int? product,
    String? productName,
    String? productSku,
    int? quantity,
    double? unitPrice,
    double? totalValue,
    bool? isLowStock,
    DateTime? lastUpdated,
  }) {
    return Inventory(
      id: id ?? this.id,
      product: product ?? this.product,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalValue: totalValue ?? this.totalValue,
      isLowStock: isLowStock ?? this.isLowStock,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
