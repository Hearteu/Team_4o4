#!/usr/bin/env python3
"""
Test script for Pharmacy AI Agent
Demonstrates AI functionality with sample data
"""

import os
import sys
import django
import requests
import json
from datetime import datetime, timedelta

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from pharma.models import Category, Supplier, Product, Inventory, Transaction
from pharma.ai_agent import PharmacyAIAgent

def create_sample_data():
    """Create sample data for testing AI agent"""
    print("🔄 Creating sample data...")
    
    # Create categories
    categories = [
        Category.objects.create(
            name='Pain Relief',
            description='Medications for pain management'
        ),
        Category.objects.create(
            name='Antibiotics',
            description='Anti-bacterial medications'
        ),
        Category.objects.create(
            name='Vitamins & Supplements',
            description='Nutritional supplements'
        ),
    ]
    
    # Create suppliers
    suppliers = [
        Supplier.objects.create(
            name='MedPharm Solutions',
            contact_person='Dr. Sarah Johnson',
            email='sarah@medpharm.com',
            phone='+1-555-0123',
            address='123 Medical Center Dr, Healthcare City, HC 12345',
            is_active=True
        ),
        Supplier.objects.create(
            name='Global Pharmaceuticals',
            contact_person='Michael Chen',
            email='mchen@globalpharma.com',
            phone='+1-555-0456',
            address='456 Pharma Ave, Business District, BD 67890',
            is_active=True
        ),
    ]
    
    # Create products
    products = [
        Product.objects.create(
            name='Acetaminophen 500mg',
            sku='ACET-500-001',
            description='Pain reliever and fever reducer',
            category=categories[0],
            supplier=suppliers[0],
            unit_price=8.99,
            cost_price=6.50,
            reorder_level=50,
            is_active=True
        ),
        Product.objects.create(
            name='Ibuprofen 200mg',
            sku='IBUP-200-001',
            description='Anti-inflammatory pain medication',
            category=categories[0],
            supplier=suppliers[0],
            unit_price=12.99,
            cost_price=9.50,
            reorder_level=40,
            is_active=True
        ),
        Product.objects.create(
            name='Amoxicillin 250mg',
            sku='AMOX-250-001',
            description='Broad-spectrum antibiotic',
            category=categories[1],
            supplier=suppliers[1],
            unit_price=45.99,
            cost_price=35.00,
            reorder_level=20,
            is_active=True
        ),
    ]
    
    # Create inventory records
    for i, product in enumerate(products):
        quantities = [75, 35, 15]  # Different stock levels for testing
        Inventory.objects.create(
            product=product,
            quantity=quantities[i]
        )
    
    # Create sample transactions
    transactions = [
        # Stock in transactions
        Transaction.objects.create(
            product=products[0],
            transaction_type='IN',
            quantity=50,
            unit_price=8.99,
            reference='PO-001',
            notes='Initial stock',
            created_at=datetime.now() - timedelta(days=5)
        ),
        Transaction.objects.create(
            product=products[1],
            transaction_type='IN',
            quantity=40,
            unit_price=12.99,
            reference='PO-002',
            notes='Initial stock',
            created_at=datetime.now() - timedelta(days=4)
        ),
        Transaction.objects.create(
            product=products[2],
            transaction_type='IN',
            quantity=20,
            unit_price=45.99,
            reference='PO-003',
            notes='Initial stock',
            created_at=datetime.now() - timedelta(days=3)
        ),
        
        # Stock out transactions (sales)
        Transaction.objects.create(
            product=products[0],
            transaction_type='OUT',
            quantity=10,
            unit_price=8.99,
            reference='SALE-001',
            notes='Customer purchase',
            created_at=datetime.now() - timedelta(days=2)
        ),
        Transaction.objects.create(
            product=products[0],
            transaction_type='OUT',
            quantity=15,
            unit_price=8.99,
            reference='SALE-002',
            notes='Customer purchase',
            created_at=datetime.now() - timedelta(days=1)
        ),
        Transaction.objects.create(
            product=products[1],
            transaction_type='OUT',
            quantity=5,
            unit_price=12.99,
            reference='SALE-003',
            notes='Customer purchase',
            created_at=datetime.now() - timedelta(hours=12)
        ),
        Transaction.objects.create(
            product=products[2],
            transaction_type='OUT',
            quantity=5,
            unit_price=45.99,
            reference='SALE-004',
            notes='Prescription filled',
            created_at=datetime.now() - timedelta(hours=6)
        ),
    ]
    
    print(f"✅ Created {len(categories)} categories, {len(suppliers)} suppliers, {len(products)} products, {len(transactions)} transactions")

def test_ai_agent():
    """Test the AI agent functionality"""
    print("\n🤖 Testing AI Agent...")
    
    ai_agent = PharmacyAIAgent()
    
    # Test system health
    print("\n📊 Testing System Health Analysis...")
    health = ai_agent.get_system_health_score()
    print(f"Overall Health Score: {health.get('overall_score', 0)}")
    print(f"Status: {health.get('status', 'Unknown')}")
    print(f"Low Stock Items: {health.get('low_stock_count', 0)}")
    print(f"Out of Stock Items: {health.get('out_of_stock_count', 0)}")
    
    # Test demand forecasting
    print("\n🔮 Testing Demand Forecasting...")
    products = Product.objects.all()
    for product in products:
        forecast = ai_agent.forecast_demand(product_id=product.id, days=30)
        if 'error' not in forecast:
            print(f"Product: {product.name}")
            print(f"  Forecasted Demand: {forecast.get('forecasted_demand', 0)}")
            print(f"  Stockout Risk: {forecast.get('stockout_risk', 0):.2%}")
            print(f"  Recommended Reorder: {forecast.get('recommended_reorder_quantity', 0)}")
    
    # Test inventory optimization
    print("\n⚙️ Testing Inventory Optimization...")
    optimization = ai_agent.optimize_inventory()
    if 'error' not in optimization:
        print(f"Products Analyzed: {optimization.get('total_products_analyzed', 0)}")
        summary = optimization.get('summary', {})
        print(f"Urgent Reorders Needed: {summary.get('urgent_reorders_needed', 0)}")
        print(f"Potential Daily Savings: ${summary.get('potential_savings', 0):.2f}")
    
    # Test sales trends
    print("\n📈 Testing Sales Trend Analysis...")
    trends = ai_agent.predict_sales_trends(days=30)
    if 'error' not in trends:
        print(f"Trend Direction: {trends.get('trend_direction', 'Unknown')}")
        print(f"Growth Rate: {trends.get('growth_rate_percent', 0):.1f}%")
        print(f"Average Daily Sales: ${trends.get('average_daily_sales', 0):.2f}")
    
    # Test comprehensive insights
    print("\n🧠 Testing Comprehensive AI Insights...")
    insights = ai_agent.get_ai_insights()
    if 'error' not in insights:
        executive_summary = insights.get('executive_summary', {})
        key_metrics = executive_summary.get('key_metrics', {})
        print(f"System Health Score: {key_metrics.get('system_health_score', 0)}")
        print(f"Total Products: {key_metrics.get('total_products', 0)}")
        print(f"Low Stock Items: {key_metrics.get('low_stock_items', 0)}")
        print(f"Urgent Reorders: {key_metrics.get('urgent_reorders', 0)}")
        
        # Print alerts
        alerts = executive_summary.get('critical_alerts', [])
        if alerts:
            print("\n🚨 Critical Alerts:")
            for alert in alerts:
                print(f"  - {alert}")
        
        # Print recommendations
        recommendations = executive_summary.get('recommendations', [])
        if recommendations:
            print("\n💡 Recommendations:")
            for rec in recommendations:
                print(f"  - {rec}")

def test_api_endpoints():
    """Test AI API endpoints"""
    print("\n🌐 Testing AI API Endpoints...")
    
    base_url = "http://localhost:8000"
    
    endpoints = [
        "/api/ai/system-health/",
        "/api/ai/demand-forecast/?days=30",
        "/api/ai/inventory-optimization/",
        "/api/ai/sales-trends/?days=30",
        "/api/ai/comprehensive-insights/",
        "/api/ai/alert-summary/",
    ]
    
    for endpoint in endpoints:
        try:
            response = requests.get(f"{base_url}{endpoint}")
            if response.status_code == 200:
                data = response.json()
                print(f"✅ {endpoint} - Success")
                if 'data' in data:
                    print(f"   Response keys: {list(data['data'].keys())}")
            else:
                print(f"❌ {endpoint} - Status: {response.status_code}")
        except requests.exceptions.ConnectionError:
            print(f"❌ {endpoint} - Connection Error (Is the server running?)")
        except Exception as e:
            print(f"❌ {endpoint} - Error: {e}")

def main():
    """Main test function"""
    print("🚀 Pharmacy AI Agent Test Suite")
    print("=" * 50)
    
    # Check if data exists
    if Product.objects.count() == 0:
        print("📝 No sample data found. Creating sample data...")
        create_sample_data()
    else:
        print(f"📊 Found {Product.objects.count()} existing products")
    
    # Test AI agent
    test_ai_agent()
    
    # Test API endpoints
    test_api_endpoints()
    
    print("\n🎉 AI Agent Test Complete!")
    print("\nTo start the server and test API endpoints:")
    print("1. cd backend")
    print("2. python manage.py runserver")
    print("3. Visit http://localhost:8000/api/ai/system-health/")

if __name__ == "__main__":
    main()
