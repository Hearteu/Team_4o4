from rest_framework import serializers

from .models import Category, Inventory, Product, Supplier, Transaction


class CategorySerializer(serializers.ModelSerializer):
    """Serializer for Category model"""
    product_count = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = ['id', 'name', 'description', 'created_at', 'updated_at', 'product_count']

    def get_product_count(self, obj):
        return obj.products.count()

class SupplierSerializer(serializers.ModelSerializer):
    """Serializer for Supplier model"""
    product_count = serializers.SerializerMethodField()

    class Meta:
        model = Supplier
        fields = ['id', 'name', 'contact_person', 'email', 'phone', 'address', 
                 'is_active', 'created_at', 'updated_at', 'product_count']

    def get_product_count(self, obj):
        return obj.products.count()

class ProductSerializer(serializers.ModelSerializer):
    """Serializer for Product model"""
    category_name = serializers.CharField(source='category.name', read_only=True)
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    current_stock = serializers.SerializerMethodField()
    total_value = serializers.SerializerMethodField()
    is_low_stock = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = ['id', 'name', 'sku', 'description', 'category', 'category_name',
                 'supplier', 'supplier_name', 'unit_price', 'cost_price', 
                 'reorder_level', 'is_active', 'created_at', 'updated_at',
                 'current_stock', 'total_value', 'is_low_stock']

    def get_current_stock(self, obj):
        try:
            return obj.inventory.quantity
        except Inventory.DoesNotExist:
            return 0

    def get_total_value(self, obj):
        try:
            return obj.inventory.total_value
        except Inventory.DoesNotExist:
            return 0

    def get_is_low_stock(self, obj):
        try:
            return obj.inventory.is_low_stock
        except Inventory.DoesNotExist:
            return True

class InventorySerializer(serializers.ModelSerializer):
    """Serializer for Inventory model"""
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_sku = serializers.CharField(source='product.sku', read_only=True)
    unit_price = serializers.DecimalField(source='product.unit_price', max_digits=10, decimal_places=2, read_only=True)
    total_value  = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True, source='total_value_db')
    is_low_stock = serializers.SerializerMethodField()
    
    class Meta:
        model = Inventory
        fields = ['id', 'product', 'product_name', 'product_sku', 'quantity', 
                 'unit_price', 'total_value', 'is_low_stock', 'last_updated']
    
    def get_is_low_stock(self, obj):
        """Calculate if stock is low based on reorder level"""
        return obj.quantity <= obj.product.reorder_level

class TransactionSerializer(serializers.ModelSerializer):
    """Serializer for Transaction model"""
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_sku = serializers.CharField(source='product.sku', read_only=True)
    transaction_type_display = serializers.CharField(source='get_transaction_type_display', read_only=True)

    class Meta:
        model = Transaction
        fields = ['id', 'product', 'product_name', 'product_sku', 'transaction_type',
                 'transaction_type_display', 'quantity', 'unit_price', 'reference',
                 'notes', 'created_at']

    def validate_quantity(self, value):
        """Validate quantity based on transaction type"""
        transaction_type = self.initial_data.get('transaction_type')
        
        if transaction_type == 'OUT' and value > 0:
            raise serializers.ValidationError("Quantity should be negative for stock out transactions")
        elif transaction_type == 'IN' and value < 0:
            raise serializers.ValidationError("Quantity should be positive for stock in transactions")
        
        return value

    def validate(self, data):
        """Additional validation for transactions"""
        if data.get('transaction_type') == 'OUT':
            # Check if there's enough stock for stock out
            product = data.get('product')
            quantity = abs(data.get('quantity'))
            
            try:
                current_stock = product.inventory.quantity
                if current_stock < quantity:
                    raise serializers.ValidationError(
                        f"Insufficient stock. Available: {current_stock}, Requested: {quantity}"
                    )
            except Inventory.DoesNotExist:
                raise serializers.ValidationError("No inventory record found for this product")
        
        return data

# Nested serializers for detailed views
class ProductDetailSerializer(ProductSerializer):
    """Detailed product serializer with nested data"""
    category = CategorySerializer(read_only=True)
    supplier = SupplierSerializer(read_only=True)
    transactions = TransactionSerializer(many=True, read_only=True)

    class Meta(ProductSerializer.Meta):
        fields = ProductSerializer.Meta.fields + ['transactions']

class CategoryDetailSerializer(CategorySerializer):
    """Detailed category serializer with products"""
    products = ProductSerializer(many=True, read_only=True)

    class Meta(CategorySerializer.Meta):
        fields = CategorySerializer.Meta.fields + ['products']

class SupplierDetailSerializer(SupplierSerializer):
    """Detailed supplier serializer with products"""
    products = ProductSerializer(many=True, read_only=True)

    class Meta(SupplierSerializer.Meta):
        fields = SupplierSerializer.Meta.fields + ['products']
