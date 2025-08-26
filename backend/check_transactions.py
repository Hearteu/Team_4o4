#!/usr/bin/env python3
import os
import sys
import django

# Add the backend directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from pharma.models import Transaction
from decimal import Decimal

def check_transactions():
    print("=== DATABASE TRANSACTION ANALYSIS ===\n")
    
    # Get all transactions
    all_transactions = Transaction.objects.all()
    print(f"Total transactions in database: {all_transactions.count()}")
    
    # Group by transaction type
    stock_in = all_transactions.filter(transaction_type='IN')
    stock_out = all_transactions.filter(transaction_type='OUT')
    
    print(f"\nStock IN transactions: {stock_in.count()}")
    print(f"Stock OUT transactions: {stock_out.count()}")
    
    # Calculate totals for Stock IN (purchases)
    stock_in_total = Decimal('0.00')
    stock_in_count = 0
    print("\n=== STOCK IN TRANSACTIONS (PURCHASES) ===")
    for t in stock_in:
        if t.unit_price:
            amount = t.quantity * t.unit_price
            stock_in_total += amount
            stock_in_count += 1
            print(f"ID: {t.id}, Product: {t.product.name}, Qty: {t.quantity}, Price: ₱{t.unit_price}, Total: ₱{amount}")
    
    print(f"\nStock IN Total: ₱{stock_in_total}")
    print(f"Stock IN Count: {stock_in_count}")
    
    # Calculate totals for Stock OUT (sales)
    stock_out_total = Decimal('0.00')
    stock_out_count = 0
    print("\n=== STOCK OUT TRANSACTIONS (SALES) ===")
    for t in stock_out:
        if t.unit_price:
            amount = t.quantity * t.unit_price
            stock_out_total += amount
            stock_out_count += 1
            print(f"ID: {t.id}, Product: {t.product.name}, Qty: {t.quantity}, Price: ₱{t.unit_price}, Total: ₱{amount}")
    
    print(f"\nStock OUT Total: ₱{stock_out_total}")
    print(f"Stock OUT Count: {stock_out_count}")
    
    # Calculate net value
    net_value = stock_out_total - stock_in_total
    print(f"\n=== SUMMARY ===")
    print(f"Revenue (Stock OUT): ₱{stock_out_total}")
    print(f"Cost (Stock IN): ₱{stock_in_total}")
    print(f"Net Value: ₱{net_value}")
    
    # Check for any large amounts
    print(f"\n=== LARGE AMOUNTS CHECK ===")
    large_transactions = all_transactions.filter(unit_price__gt=1000)
    if large_transactions.exists():
        print("Found transactions with unit price > ₱1,000:")
        for t in large_transactions:
            amount = t.quantity * t.unit_price if t.unit_price else 0
            print(f"ID: {t.id}, Product: {t.product.name}, Qty: {t.quantity}, Price: ₱{t.unit_price}, Total: ₱{amount}")
    else:
        print("No transactions with unit price > ₱1,000 found")

if __name__ == "__main__":
    check_transactions()
