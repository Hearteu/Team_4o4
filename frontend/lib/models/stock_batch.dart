class StockBatch {
  final int id;
  final int product;
  final String productName;
  final String productSku;
  final String? lotNumber;
  final DateTime? expiryDate;
  final int quantity;
  final double? unitCost;
  final int? supplier;
  final String? supplierName;
  final DateTime receivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isExpired;
  final int? daysToExpiry;

  StockBatch({
    required this.id,
    required this.product,
    required this.productName,
    required this.productSku,
    this.lotNumber,
    this.expiryDate,
    required this.quantity,
    this.unitCost,
    this.supplier,
    this.supplierName,
    required this.receivedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isExpired,
    this.daysToExpiry,
  });

  factory StockBatch.fromJson(Map<String, dynamic> json) {
    return StockBatch(
      id: json['id'],
      product: json['product'],
      productName: json['product_name'] ?? '',
      productSku: json['product_sku'] ?? '',
      lotNumber: json['lot_number'],
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      quantity: json['quantity'] ?? 0,
      unitCost: json['unit_cost'] != null
          ? double.parse(json['unit_cost'].toString())
          : null,
      supplier: json['supplier'],
      supplierName: json['supplier_name'],
      receivedAt: DateTime.parse(json['received_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isExpired: json['is_expired'] ?? false,
      daysToExpiry: json['days_to_expiry'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'product_name': productName,
      'product_sku': productSku,
      'lot_number': lotNumber,
      'expiry_date': expiryDate?.toIso8601String(),
      'quantity': quantity,
      'unit_cost': unitCost,
      'supplier': supplier,
      'supplier_name': supplierName,
      'received_at': receivedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_expired': isExpired,
      'days_to_expiry': daysToExpiry,
    };
  }

  StockBatch copyWith({
    int? id,
    int? product,
    String? productName,
    String? productSku,
    String? lotNumber,
    DateTime? expiryDate,
    int? quantity,
    double? unitCost,
    int? supplier,
    String? supplierName,
    DateTime? receivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isExpired,
    int? daysToExpiry,
  }) {
    return StockBatch(
      id: id ?? this.id,
      product: product ?? this.product,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      lotNumber: lotNumber ?? this.lotNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      supplier: supplier ?? this.supplier,
      supplierName: supplierName ?? this.supplierName,
      receivedAt: receivedAt ?? this.receivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isExpired: isExpired ?? this.isExpired,
      daysToExpiry: daysToExpiry ?? this.daysToExpiry,
    );
  }

  // Helper methods
  double? get totalValue {
    if (unitCost == null) return null;
    return quantity * unitCost!;
  }

  String get expiryStatus {
    if (expiryDate == null) return 'No Expiry';
    if (isExpired) return 'Expired';
    if (daysToExpiry != null) {
      if (daysToExpiry! <= 0) return 'Expired';
      if (daysToExpiry! <= 7) return 'Expiring Soon';
      if (daysToExpiry! <= 30) return 'Expiring This Month';
      return 'Good';
    }
    return 'Unknown';
  }

  String get expiryStatusColor {
    switch (expiryStatus) {
      case 'Expired':
        return 'red';
      case 'Expiring Soon':
        return 'orange';
      case 'Expiring This Month':
        return 'yellow';
      case 'Good':
        return 'green';
      default:
        return 'gray';
    }
  }
}
