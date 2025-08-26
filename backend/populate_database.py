#!/usr/bin/env python3
"""
Database Population Script for Pharmacy Inventory System
Creates realistic pharmacy data including categories, suppliers, products, inventory, and transactions.
"""

import os
import sys
import django
import random
from decimal import Decimal
from datetime import datetime, timedelta

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from django.utils import timezone
from pharma.models import Category, Supplier, Product, Inventory, Transaction

def create_categories():
    """Create pharmacy categories"""
    categories_data = [
        {'name': 'Antibiotics', 'description': 'Antibacterial medications for treating infections'},
        {'name': 'Pain Relief', 'description': 'Analgesics and pain management medications'},
        {'name': 'Cardiovascular', 'description': 'Heart and blood pressure medications'},
        {'name': 'Diabetes', 'description': 'Diabetes management and insulin products'},
        {'name': 'Respiratory', 'description': 'Asthma and respiratory medications'},
        {'name': 'Mental Health', 'description': 'Antidepressants and psychiatric medications'},
        {'name': 'Vitamins & Supplements', 'description': 'Nutritional supplements and vitamins'},
        {'name': 'First Aid', 'description': 'Bandages, antiseptics, and first aid supplies'},
        {'name': 'Personal Care', 'description': 'Hygiene and personal care products'},
        {'name': 'Baby Care', 'description': 'Infant and baby care products'},
        {'name': 'Dental Care', 'description': 'Oral hygiene and dental products'},
        {'name': 'Eye Care', 'description': 'Contact lenses, eye drops, and vision care'},
        {'name': 'Skin Care', 'description': 'Dermatological and skin treatment products'},
        {'name': 'Women\'s Health', 'description': 'Feminine hygiene and women\'s health products'},
        {'name': 'Men\'s Health', 'description': 'Men\'s health and wellness products'},
    ]
    
    categories = []
    for data in categories_data:
        category, created = Category.objects.get_or_create(
            name=data['name'],
            defaults={'description': data['description']}
        )
        categories.append(category)
        if created:
            print(f"✅ Created category: {category.name}")
    
    return categories

def create_suppliers():
    """Create pharmaceutical suppliers"""
    suppliers_data = [
        {'name': 'PharmaCorp International', 'contact_person': 'Dr. Sarah Johnson', 'email': 'sarah.johnson@pharmacorp.com', 'phone': '+1-555-0101', 'address': '123 Pharma Blvd, Medical District, NY 10001'},
        {'name': 'MedSupply Plus', 'contact_person': 'Mike Chen', 'email': 'mike.chen@medsupply.com', 'phone': '+1-555-0102', 'address': '456 Healthcare Ave, Business Park, CA 90210'},
        {'name': 'Global Pharmaceuticals', 'contact_person': 'Dr. Emily Rodriguez', 'email': 'emily.rodriguez@globalpharma.com', 'phone': '+1-555-0103', 'address': '789 Medicine Way, Industrial Zone, TX 75001'},
        {'name': 'Quality Drug Co.', 'contact_person': 'James Wilson', 'email': 'james.wilson@qualitydrug.com', 'phone': '+1-555-0104', 'address': '321 Pharmacy St, Downtown, FL 33101'},
        {'name': 'Premium Medical Supplies', 'contact_person': 'Lisa Thompson', 'email': 'lisa.thompson@premiummed.com', 'phone': '+1-555-0105', 'address': '654 Medical Center Dr, Healthcare Hub, IL 60601'},
        {'name': 'Reliable Pharma Solutions', 'contact_person': 'David Kim', 'email': 'david.kim@reliablepharma.com', 'phone': '+1-555-0106', 'address': '987 Drug Lane, Medical Complex, WA 98101'},
        {'name': 'Express Medical', 'contact_person': 'Amanda Davis', 'email': 'amanda.davis@expressmed.com', 'phone': '+1-555-0107', 'address': '147 Health Plaza, Medical District, PA 19101'},
        {'name': 'First Choice Pharmaceuticals', 'contact_person': 'Robert Martinez', 'email': 'robert.martinez@firstchoice.com', 'phone': '+1-555-0108', 'address': '258 Medicine Circle, Healthcare Park, OH 43201'},
    ]
    
    suppliers = []
    for data in suppliers_data:
        supplier, created = Supplier.objects.get_or_create(
            name=data['name'],
            defaults={
                'contact_person': data['contact_person'],
                'email': data['email'],
                'phone': data['phone'],
                'address': data['address'],
                'is_active': True
            }
        )
        suppliers.append(supplier)
        if created:
            print(f"✅ Created supplier: {supplier.name}")
    
    return suppliers

def create_products(categories, suppliers):
    """Create pharmacy products"""
    products_data = [
        # Antibiotics
        {'name': 'Amoxicillin 500mg', 'sku': 'AMOX500', 'description': 'Broad-spectrum antibiotic for bacterial infections', 'category': 'Antibiotics', 'unit_price': 15.99, 'cost_price': 8.50, 'reorder_level': 50, 'supplier': 'PharmaCorp International'},
        {'name': 'Azithromycin 250mg', 'sku': 'AZITH250', 'description': 'Macrolide antibiotic for respiratory infections', 'category': 'Antibiotics', 'unit_price': 22.50, 'cost_price': 12.00, 'reorder_level': 30, 'supplier': 'MedSupply Plus'},
        {'name': 'Ciprofloxacin 500mg', 'sku': 'CIPRO500', 'description': 'Fluoroquinolone antibiotic for urinary tract infections', 'category': 'Antibiotics', 'unit_price': 18.75, 'cost_price': 10.25, 'reorder_level': 40, 'supplier': 'Global Pharmaceuticals'},
        
        # Pain Relief
        {'name': 'Ibuprofen 400mg', 'sku': 'IBUP400', 'description': 'Non-steroidal anti-inflammatory for pain and fever', 'category': 'Pain Relief', 'unit_price': 8.99, 'cost_price': 4.50, 'reorder_level': 100, 'supplier': 'Quality Drug Co.'},
        {'name': 'Acetaminophen 500mg', 'sku': 'ACET500', 'description': 'Pain reliever and fever reducer', 'category': 'Pain Relief', 'unit_price': 6.50, 'cost_price': 3.25, 'reorder_level': 150, 'supplier': 'Premium Medical Supplies'},
        {'name': 'Naproxen 500mg', 'sku': 'NAPR500', 'description': 'Long-acting pain reliever for arthritis', 'category': 'Pain Relief', 'unit_price': 12.99, 'cost_price': 6.75, 'reorder_level': 60, 'supplier': 'Reliable Pharma Solutions'},
        
        # Cardiovascular
        {'name': 'Lisinopril 10mg', 'sku': 'LISI10', 'description': 'ACE inhibitor for high blood pressure', 'category': 'Cardiovascular', 'unit_price': 25.99, 'cost_price': 13.50, 'reorder_level': 40, 'supplier': 'PharmaCorp International'},
        {'name': 'Amlodipine 5mg', 'sku': 'AMLO5', 'description': 'Calcium channel blocker for hypertension', 'category': 'Cardiovascular', 'unit_price': 28.50, 'cost_price': 15.00, 'reorder_level': 35, 'supplier': 'MedSupply Plus'},
        {'name': 'Metoprolol 50mg', 'sku': 'METO50', 'description': 'Beta blocker for heart conditions', 'category': 'Cardiovascular', 'unit_price': 22.75, 'cost_price': 11.75, 'reorder_level': 45, 'supplier': 'Global Pharmaceuticals'},
        
        # Diabetes
        {'name': 'Metformin 500mg', 'sku': 'METF500', 'description': 'Oral diabetes medication', 'category': 'Diabetes', 'unit_price': 18.99, 'cost_price': 9.50, 'reorder_level': 80, 'supplier': 'Quality Drug Co.'},
        {'name': 'Glipizide 5mg', 'sku': 'GLIP5', 'description': 'Sulfonylurea for type 2 diabetes', 'category': 'Diabetes', 'unit_price': 24.50, 'cost_price': 12.75, 'reorder_level': 50, 'supplier': 'Premium Medical Supplies'},
        {'name': 'Insulin Regular', 'sku': 'INSUL', 'description': 'Short-acting insulin for diabetes management', 'category': 'Diabetes', 'unit_price': 45.99, 'cost_price': 25.00, 'reorder_level': 25, 'supplier': 'Reliable Pharma Solutions'},
        
        # Respiratory
        {'name': 'Albuterol Inhaler', 'sku': 'ALBUINH', 'description': 'Bronchodilator for asthma and COPD', 'category': 'Respiratory', 'unit_price': 35.99, 'cost_price': 18.50, 'reorder_level': 30, 'supplier': 'PharmaCorp International'},
        {'name': 'Fluticasone Nasal Spray', 'sku': 'FLUTNAS', 'description': 'Corticosteroid for allergic rhinitis', 'category': 'Respiratory', 'unit_price': 28.75, 'cost_price': 14.75, 'reorder_level': 40, 'supplier': 'MedSupply Plus'},
        {'name': 'Montelukast 10mg', 'sku': 'MONT10', 'description': 'Leukotriene receptor antagonist for asthma', 'category': 'Respiratory', 'unit_price': 32.50, 'cost_price': 16.75, 'reorder_level': 35, 'supplier': 'Global Pharmaceuticals'},
        
        # Mental Health
        {'name': 'Sertraline 50mg', 'sku': 'SERT50', 'description': 'SSRI antidepressant for depression and anxiety', 'category': 'Mental Health', 'unit_price': 38.99, 'cost_price': 20.00, 'reorder_level': 40, 'supplier': 'Quality Drug Co.'},
        {'name': 'Bupropion 150mg', 'sku': 'BUP150', 'description': 'Atypical antidepressant for depression', 'category': 'Mental Health', 'unit_price': 42.50, 'cost_price': 22.25, 'reorder_level': 35, 'supplier': 'Premium Medical Supplies'},
        {'name': 'Lorazepam 1mg', 'sku': 'LORA1', 'description': 'Benzodiazepine for anxiety and insomnia', 'category': 'Mental Health', 'unit_price': 15.75, 'cost_price': 8.25, 'reorder_level': 60, 'supplier': 'Reliable Pharma Solutions'},
        
        # Vitamins & Supplements
        {'name': 'Vitamin D3 1000IU', 'sku': 'VITD1000', 'description': 'Vitamin D supplement for bone health', 'category': 'Vitamins & Supplements', 'unit_price': 12.99, 'cost_price': 6.50, 'reorder_level': 100, 'supplier': 'Express Medical'},
        {'name': 'Omega-3 Fish Oil', 'sku': 'OMEGA3', 'description': 'Essential fatty acids for heart health', 'category': 'Vitamins & Supplements', 'unit_price': 18.50, 'cost_price': 9.25, 'reorder_level': 80, 'supplier': 'First Choice Pharmaceuticals'},
        {'name': 'Multivitamin Daily', 'sku': 'MULTIVIT', 'description': 'Complete daily multivitamin supplement', 'category': 'Vitamins & Supplements', 'unit_price': 15.99, 'cost_price': 8.00, 'reorder_level': 90, 'supplier': 'PharmaCorp International'},
        
        # First Aid
        {'name': 'Adhesive Bandages', 'sku': 'BANDAGE', 'description': 'Sterile adhesive bandages for minor cuts', 'category': 'First Aid', 'unit_price': 5.99, 'cost_price': 3.00, 'reorder_level': 200, 'supplier': 'MedSupply Plus'},
        {'name': 'Antiseptic Solution', 'sku': 'ANTISEP', 'description': 'Antiseptic for wound cleaning', 'category': 'First Aid', 'unit_price': 8.50, 'cost_price': 4.25, 'reorder_level': 150, 'supplier': 'Global Pharmaceuticals'},
        {'name': 'Gauze Pads 4x4', 'sku': 'GAUZE4', 'description': 'Sterile gauze pads for wound dressing', 'category': 'First Aid', 'unit_price': 7.99, 'cost_price': 4.00, 'reorder_level': 180, 'supplier': 'Quality Drug Co.'},
        
        # Personal Care
        {'name': 'Hand Sanitizer 500ml', 'sku': 'HANDSAN', 'description': 'Alcohol-based hand sanitizer', 'category': 'Personal Care', 'unit_price': 6.99, 'cost_price': 3.50, 'reorder_level': 120, 'supplier': 'Premium Medical Supplies'},
        {'name': 'Sunscreen SPF 50', 'sku': 'SUNSPF50', 'description': 'Broad-spectrum sunscreen protection', 'category': 'Personal Care', 'unit_price': 14.99, 'cost_price': 7.50, 'reorder_level': 80, 'supplier': 'Reliable Pharma Solutions'},
        {'name': 'Moisturizing Lotion', 'sku': 'MOISTLOT', 'description': 'Hydrating body lotion for dry skin', 'category': 'Personal Care', 'unit_price': 9.99, 'cost_price': 5.00, 'reorder_level': 100, 'supplier': 'Express Medical'},
        
        # Baby Care
        {'name': 'Baby Diapers Size 3', 'sku': 'DIAPER3', 'description': 'Disposable diapers for infants', 'category': 'Baby Care', 'unit_price': 24.99, 'cost_price': 12.50, 'reorder_level': 50, 'supplier': 'First Choice Pharmaceuticals'},
        {'name': 'Baby Wipes', 'sku': 'BABYWIPE', 'description': 'Gentle baby wipes for sensitive skin', 'category': 'Baby Care', 'unit_price': 8.99, 'cost_price': 4.50, 'reorder_level': 100, 'supplier': 'PharmaCorp International'},
        {'name': 'Baby Formula', 'sku': 'BABYFORM', 'description': 'Complete nutrition for infants', 'category': 'Baby Care', 'unit_price': 32.99, 'cost_price': 16.50, 'reorder_level': 40, 'supplier': 'MedSupply Plus'},
        
        # Dental Care
        {'name': 'Toothpaste Fluoride', 'sku': 'TOOTHPASTE', 'description': 'Fluoride toothpaste for cavity prevention', 'category': 'Dental Care', 'unit_price': 4.99, 'cost_price': 2.50, 'reorder_level': 150, 'supplier': 'Global Pharmaceuticals'},
        {'name': 'Dental Floss', 'sku': 'DENTFLOSS', 'description': 'Waxed dental floss for oral hygiene', 'category': 'Dental Care', 'unit_price': 3.99, 'cost_price': 2.00, 'reorder_level': 200, 'supplier': 'Quality Drug Co.'},
        {'name': 'Mouthwash Antiseptic', 'sku': 'MOUTHWASH', 'description': 'Antiseptic mouthwash for oral health', 'category': 'Dental Care', 'unit_price': 7.99, 'cost_price': 4.00, 'reorder_level': 120, 'supplier': 'Premium Medical Supplies'},
        
        # Eye Care
        {'name': 'Contact Lens Solution', 'sku': 'LENSSOL', 'description': 'Multi-purpose contact lens solution', 'category': 'Eye Care', 'unit_price': 12.99, 'cost_price': 6.50, 'reorder_level': 80, 'supplier': 'Reliable Pharma Solutions'},
        {'name': 'Eye Drops Lubricating', 'sku': 'EYEDROP', 'description': 'Lubricating eye drops for dry eyes', 'category': 'Eye Care', 'unit_price': 9.99, 'cost_price': 5.00, 'reorder_level': 100, 'supplier': 'Express Medical'},
        {'name': 'Reading Glasses +2.0', 'sku': 'READGLASS', 'description': 'Prescription reading glasses', 'category': 'Eye Care', 'unit_price': 18.99, 'cost_price': 9.50, 'reorder_level': 60, 'supplier': 'First Choice Pharmaceuticals'},
        
        # Skin Care
        {'name': 'Hydrocortisone Cream 1%', 'sku': 'HYDROCORT', 'description': 'Topical steroid for skin inflammation', 'category': 'Skin Care', 'unit_price': 8.99, 'cost_price': 4.50, 'reorder_level': 100, 'supplier': 'PharmaCorp International'},
        {'name': 'Antifungal Cream', 'sku': 'ANTIFUNG', 'description': 'Topical antifungal for skin infections', 'category': 'Skin Care', 'unit_price': 11.99, 'cost_price': 6.00, 'reorder_level': 80, 'supplier': 'MedSupply Plus'},
        {'name': 'Acne Treatment Gel', 'sku': 'ACNEGEL', 'description': 'Benzoyl peroxide gel for acne', 'category': 'Skin Care', 'unit_price': 13.99, 'cost_price': 7.00, 'reorder_level': 90, 'supplier': 'Global Pharmaceuticals'},
        
        # Women's Health
        {'name': 'Prenatal Vitamins', 'sku': 'PRENATAL', 'description': 'Complete prenatal vitamin supplement', 'category': 'Women\'s Health', 'unit_price': 22.99, 'cost_price': 11.50, 'reorder_level': 60, 'supplier': 'Quality Drug Co.'},
        {'name': 'Feminine Hygiene Products', 'sku': 'FEMHYG', 'description': 'Feminine hygiene essentials', 'category': 'Women\'s Health', 'unit_price': 8.99, 'cost_price': 4.50, 'reorder_level': 120, 'supplier': 'Premium Medical Supplies'},
        {'name': 'Iron Supplement', 'sku': 'IRONSUPP', 'description': 'Iron supplement for women', 'category': 'Women\'s Health', 'unit_price': 16.99, 'cost_price': 8.50, 'reorder_level': 80, 'supplier': 'Reliable Pharma Solutions'},
        
        # Men's Health
        {'name': 'Men\'s Multivitamin', 'sku': 'MENVIT', 'description': 'Complete multivitamin for men', 'category': 'Men\'s Health', 'unit_price': 19.99, 'cost_price': 10.00, 'reorder_level': 70, 'supplier': 'Express Medical'},
        {'name': 'Testosterone Support', 'sku': 'TESTO', 'description': 'Natural testosterone support supplement', 'category': 'Men\'s Health', 'unit_price': 28.99, 'cost_price': 14.50, 'reorder_level': 50, 'supplier': 'First Choice Pharmaceuticals'},
        {'name': 'Prostate Health', 'sku': 'PROSTATE', 'description': 'Saw palmetto for prostate health', 'category': 'Men\'s Health', 'unit_price': 24.99, 'cost_price': 12.50, 'reorder_level': 60, 'supplier': 'PharmaCorp International'},
    ]
    
    # Create category and supplier mappings
    category_map = {cat.name: cat for cat in categories}
    supplier_map = {sup.name: sup for sup in suppliers}
    
    products = []
    for data in products_data:
        category = category_map.get(data['category'])
        supplier = supplier_map.get(data['supplier'])
        
        if category and supplier:
            product, created = Product.objects.get_or_create(
                sku=data['sku'],
                defaults={
                    'name': data['name'],
                    'description': data['description'],
                    'category': category,
                    'supplier': supplier,
                    'unit_price': Decimal(str(data['unit_price'])),
                    'cost_price': Decimal(str(data['cost_price'])),
                    'reorder_level': data['reorder_level']
                }
            )
            products.append(product)
            if created:
                print(f"✅ Created product: {product.name}")
    
    return products

def create_inventory(products):
    """Create inventory records for products"""
    inventory_records = []
    
    for product in products:
        # Generate random initial stock levels
        initial_quantity = random.randint(20, 200)
        
        inventory, created = Inventory.objects.get_or_create(
            product=product,
            defaults={'quantity': initial_quantity}
        )
        
        if created:
            inventory_records.append(inventory)
            print(f"✅ Created inventory: {product.name} - {initial_quantity} units")
    
    return inventory_records

def create_transactions(products):
    """Create realistic transaction history"""
    transactions = []
    
    # Generate transactions for the last 90 days
    end_date = timezone.now()
    start_date = end_date - timedelta(days=90)
    
    transaction_types = ['IN', 'OUT']
    
    for product in products:
        # Create 3-8 transactions per product
        num_transactions = random.randint(3, 8)
        
        for i in range(num_transactions):
            # Random transaction type (more OUT than IN)
            transaction_type = random.choices(transaction_types, weights=[0.3, 0.7])[0]
            
            # Random quantity (positive for IN, negative for OUT)
            if transaction_type == 'IN':
                quantity = random.randint(10, 100)  # Stock in (positive)
            else:
                quantity = -random.randint(1, 20)   # Sales out (negative)
            
            # Random unit price (slight variation from product price)
            price_variation = random.uniform(0.9, 1.1)
            unit_price = product.unit_price * Decimal(str(price_variation))
            
            # Create transaction
            transaction = Transaction.objects.create(
                product=product,
                transaction_type=transaction_type,
                quantity=quantity,
                unit_price=unit_price,
                notes=f"Auto-generated transaction #{i+1} for {product.name}"
            )
            
            transactions.append(transaction)
            
            # Update inventory
            inventory = product.inventory
            if transaction_type == 'IN':
                inventory.quantity += quantity
            else:
                inventory.quantity = max(0, inventory.quantity - quantity)
            inventory.save()
    
    print(f"✅ Created {len(transactions)} transactions")
    return transactions

def main():
    """Main function to populate the database"""
    print("🏥 Pharmacy Database Population Script")
    print("=" * 50)
    
    try:
        # Create categories
        print("\n📋 Creating categories...")
        categories = create_categories()
        
        # Create suppliers
        print("\n🏢 Creating suppliers...")
        suppliers = create_suppliers()
        
        # Create products
        print("\n💊 Creating products...")
        products = create_products(categories, suppliers)
        
        # Create inventory
        print("\n📦 Creating inventory records...")
        inventory_records = create_inventory(products)
        
        # Create transactions
        print("\n💰 Creating transaction history...")
        transactions = create_transactions(products)
        
        # Summary
        print("\n" + "=" * 50)
        print("🎉 Database Population Complete!")
        print(f"✅ Categories: {len(categories)}")
        print(f"✅ Suppliers: {len(suppliers)}")
        print(f"✅ Products: {len(products)}")
        print(f"✅ Inventory Records: {len(inventory_records)}")
        print(f"✅ Transactions: {len(transactions)}")
        print(f"✅ Total Records: {len(categories) + len(suppliers) + len(products) + len(inventory_records) + len(transactions)}")
        print("\n🚀 Your pharmacy database is now populated with realistic data!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
