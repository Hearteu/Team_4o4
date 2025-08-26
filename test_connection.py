#!/usr/bin/env python3
"""
Test script to verify backend and frontend connection
"""

import requests
import json

def test_backend_connection():
    """Test backend API endpoints"""
    print("🔍 Testing Backend Connection...")
    
    base_url = "http://localhost:8000"
    
    # Test basic API
    try:
        response = requests.get(f"{base_url}/")
        if response.status_code == 200:
            print("✅ Basic API endpoint working")
        else:
            print(f"❌ Basic API failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Basic API error: {e}")
    
    # Test categories API
    try:
        response = requests.get(f"{base_url}/api/categories/")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Categories API working - {data['count']} categories found")
        else:
            print(f"❌ Categories API failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Categories API error: {e}")
    
    # Test products API
    try:
        response = requests.get(f"{base_url}/api/products/")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Products API working - {data['count']} products found")
        else:
            print(f"❌ Products API failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Products API error: {e}")
    
    # Test AI system health
    try:
        response = requests.get(f"{base_url}/api/ai/system-health/")
        if response.status_code == 200:
            data = response.json()
            health_score = data['data']['overall_score']
            status = data['data']['status']
            print(f"✅ AI System Health working - Score: {health_score}% ({status})")
        else:
            print(f"❌ AI System Health failed: {response.status_code}")
    except Exception as e:
        print(f"❌ AI System Health error: {e}")
    
    # Test AI demand forecast
    try:
        response = requests.get(f"{base_url}/api/ai/demand-forecast/?days=30")
        if response.status_code == 200:
            data = response.json()
            products_forecasted = data['data']['total_products_forecasted']
            print(f"✅ AI Demand Forecast working - {products_forecasted} products forecasted")
        else:
            print(f"❌ AI Demand Forecast failed: {response.status_code}")
    except Exception as e:
        print(f"❌ AI Demand Forecast error: {e}")

def test_frontend_urls():
    """Test frontend URL configuration"""
    print("\n🔍 Testing Frontend URL Configuration...")
    
    # Test if frontend URLs are correctly configured
    frontend_urls = [
        "http://10.0.2.2:8000/api/categories/",
        "http://10.0.2.2:8000/api/products/",
        "http://10.0.2.2:8000/api/ai/system-health/",
    ]
    
    for url in frontend_urls:
        try:
            response = requests.get(url)
            if response.status_code == 200:
                print(f"✅ Frontend URL working: {url}")
            else:
                print(f"❌ Frontend URL failed: {url} - Status: {response.status_code}")
        except Exception as e:
            print(f"❌ Frontend URL error: {url} - {e}")

def main():
    """Main test function"""
    print("🚀 Pharmacy System Connection Test")
    print("=" * 50)
    
    test_backend_connection()
    test_frontend_urls()
    
    print("\n🎉 Test Complete!")
    print("\nTo start the frontend:")
    print("1. cd frontend")
    print("2. flutter run -d chrome --web-port=8080")
    print("\nTo start the backend:")
    print("1. cd backend")
    print("2. source venv/bin/activate")
    print("3. python manage.py runserver")

if __name__ == "__main__":
    main()
