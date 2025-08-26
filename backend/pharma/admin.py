from django.contrib import admin
from .models import Category, Supplier, Product, Inventory, Transaction

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'description', 'created_at', 'product_count']
    search_fields = ['name', 'description']
    ordering = ['name']
    
    def product_count(self, obj):
        return obj.products.count()
    product_count.short_description = 'Products'

@admin.register(Supplier)
class SupplierAdmin(admin.ModelAdmin):
    list_display = ['name', 'contact_person', 'email', 'phone', 'is_active', 'product_count']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'contact_person', 'email']
    ordering = ['name']
    
    def product_count(self, obj):
        return obj.products.count()
    product_count.short_description = 'Products'

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ['name', 'sku', 'category', 'supplier', 'unit_price', 'current_stock', 'is_active']
    list_filter = ['category', 'supplier', 'is_active', 'created_at']
    search_fields = ['name', 'sku', 'description']
    ordering = ['name']
    readonly_fields = ['current_stock', 'total_value', 'is_low_stock']
    
    def current_stock(self, obj):
        try:
            return obj.inventory.quantity
        except Inventory.DoesNotExist:
            return 0
    current_stock.short_description = 'Current Stock'
    
    def total_value(self, obj):
        try:
            return obj.inventory.total_value
        except Inventory.DoesNotExist:
            return 0
    total_value.short_description = 'Total Value'
    
    def is_low_stock(self, obj):
        try:
            return obj.inventory.is_low_stock
        except Inventory.DoesNotExist:
            return True
    is_low_stock.short_description = 'Low Stock'
    is_low_stock.boolean = True

@admin.register(Inventory)
class InventoryAdmin(admin.ModelAdmin):
    list_display = ['product', 'quantity', 'total_value', 'is_low_stock', 'last_updated']
    list_filter = ['last_updated']
    search_fields = ['product__name', 'product__sku']
    ordering = ['-quantity']
    readonly_fields = ['total_value', 'is_low_stock', 'last_updated']

@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ['product', 'transaction_type', 'quantity', 'unit_price', 'reference', 'created_at']
    list_filter = ['transaction_type', 'created_at', 'product__category']
    search_fields = ['product__name', 'product__sku', 'reference', 'notes']
    ordering = ['-created_at']
    readonly_fields = ['created_at']
