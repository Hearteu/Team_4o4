#!/usr/bin/env python3
import requests
import json

def debug_api():
    print("=== API DEBUG ===\n")
    
    # Check what the API returns
    url = "http://localhost:8000/api/transactions/"
    response = requests.get(url)
    
    if response.status_code == 200:
        data = response.json()
        print(f"API Response Status: {response.status_code}")
        print(f"Total Count: {data.get('count', 'N/A')}")
        print(f"Results Count: {len(data.get('results', []))}")
        
        # Check first few transactions
        results = data.get('results', [])
        if results:
            print(f"\nFirst 3 transactions from API:")
            for i, transaction in enumerate(results[:3]):
                print(f"Transaction {i+1}:")
                print(f"  ID: {transaction.get('id')}")
                print(f"  Type: {transaction.get('transaction_type')}")
                print(f"  Quantity: {transaction.get('quantity')}")
                print(f"  Unit Price: {transaction.get('unit_price')}")
                print(f"  Calculated Total: {transaction.get('quantity', 0) * float(transaction.get('unit_price', 0))}")
                print()
        
        # Calculate totals from API data
        stock_in_total = 0
        stock_out_total = 0
        stock_in_count = 0
        stock_out_count = 0
        
        for transaction in results:
            quantity = transaction.get('quantity', 0)
            unit_price = float(transaction.get('unit_price', 0))
            total = quantity * unit_price
            
            if transaction.get('transaction_type') == 'IN':
                stock_in_total += total
                stock_in_count += 1
            elif transaction.get('transaction_type') == 'OUT':
                stock_out_total += total
                stock_out_count += 1
        
        print(f"=== API CALCULATIONS ===")
        print(f"Stock IN: {stock_in_count} transactions, Total: ₱{stock_in_total:.2f}")
        print(f"Stock OUT: {stock_out_count} transactions, Total: ₱{stock_out_total:.2f}")
        print(f"Revenue (|Stock OUT|): ₱{abs(stock_out_total):.2f}")
        print(f"Cost (Stock IN): ₱{stock_in_total:.2f}")
        print(f"Net: ₱{stock_out_total - stock_in_total:.2f}")
        
    else:
        print(f"API Error: {response.status_code}")
        print(response.text)

if __name__ == "__main__":
    debug_api()
