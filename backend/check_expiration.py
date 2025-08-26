#!/usr/bin/env python3
import os
import sys
import django
from datetime import date, timedelta

# Add the backend directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from pharma.models import StockBatch, Product, Inventory
from django.utils import timezone

def check_expiration_data():
    print("=== EXPIRATION DATA ANALYSIS ===\n")
    
    # Get all stock batches
    all_batches = StockBatch.objects.all()
    print(f"Total stock batches in database: {all_batches.count()}")
    
    # Check batches with expiry dates
    batches_with_expiry = all_batches.filter(expiry_date__isnull=False)
    batches_without_expiry = all_batches.filter(expiry_date__isnull=True)
    
    print(f"Batches with expiry dates: {batches_with_expiry.count()}")
    print(f"Batches without expiry dates: {batches_without_expiry.count()}")
    
    if batches_with_expiry.exists():
        print("\n=== BATCHES WITH EXPIRY DATES ===")
        
        # Check expired batches
        today = timezone.now().date()
        expired_batches = batches_with_expiry.filter(expiry_date__lt=today)
        expiring_soon = batches_with_expiry.filter(
            expiry_date__gte=today,
            expiry_date__lte=today + timedelta(days=30)
        )
        expiring_this_week = batches_with_expiry.filter(
            expiry_date__gte=today,
            expiry_date__lte=today + timedelta(days=7)
        )
        
        print(f"Expired batches: {expired_batches.count()}")
        print(f"Expiring within 30 days: {expiring_soon.count()}")
        print(f"Expiring within 7 days: {expiring_this_week.count()}")
        
        # Show expired batches
        if expired_batches.exists():
            print("\n--- EXPIRED BATCHES ---")
            for batch in expired_batches:
                days_expired = (today - batch.expiry_date).days
                print(f"• {batch.product.name} (SKU: {batch.product.sku})")
                print(f"  Lot: {batch.lot_number or 'N/A'}")
                print(f"  Expired: {batch.expiry_date} ({days_expired} days ago)")
                print(f"  Quantity: {batch.quantity}")
                print(f"  Value: ₱{batch.quantity * batch.unit_cost if batch.unit_cost else 0:.2f}")
                print()
        
        # Show expiring soon batches
        if expiring_soon.exists():
            print("\n--- EXPIRING WITHIN 30 DAYS ---")
            for batch in expiring_soon.order_by('expiry_date'):
                days_to_expiry = (batch.expiry_date - today).days
                print(f"• {batch.product.name} (SKU: {batch.product.sku})")
                print(f"  Lot: {batch.lot_number or 'N/A'}")
                print(f"  Expires: {batch.expiry_date} (in {days_to_expiry} days)")
                print(f"  Quantity: {batch.quantity}")
                print(f"  Value: ₱{batch.quantity * batch.unit_cost if batch.unit_cost else 0:.2f}")
                print()
        
        # Show expiring this week
        if expiring_this_week.exists():
            print("\n--- EXPIRING WITHIN 7 DAYS (URGENT) ---")
            for batch in expiring_this_week.order_by('expiry_date'):
                days_to_expiry = (batch.expiry_date - today).days
                print(f"• {batch.product.name} (SKU: {batch.product.sku})")
                print(f"  Lot: {batch.lot_number or 'N/A'}")
                print(f"  Expires: {batch.expiry_date} (in {days_to_expiry} days)")
                print(f"  Quantity: {batch.quantity}")
                print(f"  Value: ₱{batch.quantity * batch.unit_cost if batch.unit_cost else 0:.2f}")
                print()
    
    # Check products without expiry tracking
    print("\n=== PRODUCTS WITHOUT EXPIRY TRACKING ===")
    products_with_batches = Product.objects.filter(batches__isnull=False).distinct()
    products_without_batches = Product.objects.filter(batches__isnull=True)
    
    print(f"Products with batch tracking: {products_with_batches.count()}")
    print(f"Products without batch tracking: {products_without_batches.count()}")
    
    if products_without_batches.exists():
        print("\nProducts that need expiry tracking:")
        for product in products_without_batches:
            inventory = Inventory.objects.filter(product=product).first()
            current_stock = inventory.quantity if inventory else 0
            print(f"• {product.name} (SKU: {product.sku}) - Current stock: {current_stock}")
    
    # Summary statistics
    print("\n=== SUMMARY ===")
    total_expired_quantity = sum(batch.quantity for batch in expired_batches)
    total_expired_value = sum(
        batch.quantity * batch.unit_cost 
        for batch in expired_batches 
        if batch.unit_cost
    )
    
    total_expiring_soon_quantity = sum(batch.quantity for batch in expiring_soon)
    total_expiring_soon_value = sum(
        batch.quantity * batch.unit_cost 
        for batch in expiring_soon 
        if batch.unit_cost
    )
    
    print(f"Total expired quantity: {total_expired_quantity}")
    print(f"Total expired value: ₱{total_expired_value:.2f}")
    print(f"Total expiring soon quantity: {total_expiring_soon_quantity}")
    print(f"Total expiring soon value: ₱{total_expiring_soon_value:.2f}")

if __name__ == "__main__":
    check_expiration_data()
