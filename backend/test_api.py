#!/usr/bin/env python3
"""
Simple test script to verify the inventory management API is working
"""
import os
import sys
import django

# Add the project directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from pharma.models import Category, Supplier, Product, Inventory, Transaction
from pharma.serializers import CategorySerializer, ProductSerializer

def test_models():
    """Test creating and retrieving models"""
    print("Testing model creation...")
    
    # Create a category
    category = Category.objects.create(
        name="Electronics",
        description="Electronic devices and accessories"
    )
    print(f"Created category: {category}")
    
    # Create a supplier
    supplier = Supplier.objects.create(
        name="Tech Supplies Inc",
        contact_person="John Doe",
        email="john@techsupplies.com",
        phone="555-0123"
    )
    print(f"Created supplier: {supplier}")
    
    # Create a product
    product = Product.objects.create(
        name="Laptop",
        sku="LAP001",
        description="High-performance laptop",
        category=category,
        supplier=supplier,
        unit_price=999.99,
        cost_price=750.00,
        reorder_level=5
    )
    print(f"Created product: {product}")
    
    # Create inventory
    inventory = Inventory.objects.create(
        product=product,
        quantity=10
    )
    print(f"Created inventory: {inventory}")
    
    # Create a transaction
    transaction = Transaction.objects.create(
        product=product,
        transaction_type='IN',
        quantity=10,
        unit_price=750.00,
        reference="PO-2024-001",
        notes="Initial stock purchase"
    )
    print(f"Created transaction: {transaction}")
    
    print("\nTesting serializers...")
    
    # Test category serializer
    category_serializer = CategorySerializer(category)
    print(f"Category serialized: {category_serializer.data}")
    
    # Test product serializer
    product_serializer = ProductSerializer(product)
    print(f"Product serialized: {product_serializer.data}")
    
    print("\nAll tests passed! ✅")
    
    # Clean up
    Transaction.objects.all().delete()
    Inventory.objects.all().delete()
    Product.objects.all().delete()
    Supplier.objects.all().delete()
    Category.objects.all().delete()
    print("Test data cleaned up.")

if __name__ == "__main__":
    test_models()
