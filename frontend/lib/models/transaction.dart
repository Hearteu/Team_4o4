enum TransactionType { IN, OUT, ADJUST }

class Transaction {
  final int id;
  final int product;
  final String productName;
  final String productSku;
  final TransactionType transactionType;
  final String transactionTypeDisplay;
  final int quantity;
  final double? unitPrice;
  final String reference;
  final String notes;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.product,
    required this.productName,
    required this.productSku,
    required this.transactionType,
    required this.transactionTypeDisplay,
    required this.quantity,
    this.unitPrice,
    required this.reference,
    required this.notes,
    required this.createdAt,
  });

  /// Calculate total amount based on quantity and unit price
  double? get totalAmount {
    if (unitPrice == null) return null;
    return quantity * unitPrice!;
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      product: json['product'],
      productName: json['product_name'] ?? '',
      productSku: json['product_sku'] ?? '',
      transactionType: _parseTransactionType(json['transaction_type']),
      transactionTypeDisplay: json['transaction_type_display'] ?? '',
      quantity: json['quantity'],
      unitPrice: json['unit_price'] != null
          ? double.parse(json['unit_price'].toString())
          : null,
      reference: json['reference'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static TransactionType _parseTransactionType(String type) {
    switch (type) {
      case 'IN':
        return TransactionType.IN;
      case 'OUT':
        return TransactionType.OUT;
      case 'ADJUST':
        return TransactionType.ADJUST;
      default:
        return TransactionType.IN;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'product_name': productName,
      'product_sku': productSku,
      'transaction_type': transactionType.name,
      'transaction_type_display': transactionTypeDisplay,
      'quantity': quantity,
      'unit_price': unitPrice,
      'reference': reference,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    int? id,
    int? product,
    String? productName,
    String? productSku,
    TransactionType? transactionType,
    String? transactionTypeDisplay,
    int? quantity,
    double? unitPrice,
    String? reference,
    String? notes,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      product: product ?? this.product,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      transactionType: transactionType ?? this.transactionType,
      transactionTypeDisplay:
          transactionTypeDisplay ?? this.transactionTypeDisplay,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
