#!/usr/bin/env python3
"""
Database Population Script for Pharmacy Inventory System
Creates realistic pharmacy data including categories, suppliers, products,
batches with expiry, inventory shells, and transactions (IN/OUT).
Matches the behaviors in your models.py (Transaction.save adjusts Inventory).
"""

import os
import random
import sys
from datetime import timedelta
from decimal import ROUND_HALF_UP, Decimal

import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from django.db import transaction as db_transaction
from django.utils import timezone
from pharma.models import Category, Inventory, Product, Supplier, Transaction

# --- Optional: StockBatch (required for expiries) --------------------------------
try:
    from pharma.models import StockBatch
    HAS_BATCH = True
except Exception:
    StockBatch = None
    HAS_BATCH = False

# ---------- Helpers ----------
def money(val):
    return Decimal(str(val)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

def pick(lst):
    return random.choice(lst)

def rand_ref(prefix, dt):
    """PO/POS style reference with date and random block."""
    return f"{prefix}-{dt.strftime('%Y%m%d')}-{random.randint(1001, 9999)}"

# Rough shelf-life (in days) by category for realistic expiries
SHELF_LIFE = {
    'Antibiotics': (365, 720),
    'Pain Relief': (540, 1095),
    'Cardiovascular': (540, 1095),
    'Diabetes': (365, 720),
    'Respiratory': (365, 730),
    'Mental Health': (540, 1095),
    'Vitamins & Supplements': (365, 1460),
    'First Aid': (365, 1460),
    'Personal Care': (365, 1095),
    'Baby Care': (270, 720),
    'Dental Care': (365, 1095),
    'Eye Care': (365, 540),
    'Skin Care': (365, 730),
    "Women's Health": (365, 730),
    "Men's Health": (365, 730),
}
def shelf_life_days(category_name):
    lo, hi = SHELF_LIFE.get(category_name, (365, 730))
    return random.randint(lo, hi)

BRANDS_BY_GENERIC = {
    # Antibiotics
    "Amoxicillin": ["Amoxil", "Himox", "Moxillin"],
    "Azithromycin": ["Zithromax", "AzithroMax", "Z-Pak (generic)"],
    "Ciprofloxacin": ["Cipro", "Ciprobay", "Cifran"],
    # Pain Relief
    "Ibuprofen": ["Advil", "Nurofen", "Brufen"],
    "Acetaminophen": ["Tylenol", "Biogesic", "Tempra"],
    "Naproxen": ["Aleve", "Naprogesic", "Flanax"],
    # Cardiovascular
    "Lisinopril": ["Prinivil", "Zestril"],
    "Amlodipine": ["Norvasc", "Amdipen"],
    "Metoprolol": ["Lopressor", "Betaloc"],
    # Diabetes
    "Metformin": ["Glucophage", "Glumet"],
    "Glipizide": ["Glucotrol", "Minidiab"],
    "Insulin": ["Humulin R", "Actrapid"],
    # Respiratory
    "Albuterol": ["Ventolin", "ProAir", "Salbutamol (PH)"],
    "Fluticasone": ["Flonase", "Flixotide"],
    "Montelukast": ["Singulair", "Montecar"],
    # Mental Health
    "Sertraline": ["Zoloft", "Serlift"],
    "Bupropion": ["Wellbutrin", "Zyban"],
    "Lorazepam": ["Ativan"],
    # Vitamins
    "Vitamin": ["Centrum", "Revicon"],
    "Omega-3": ["Fish Oil Plus", "Nordic Naturals"],
}

DOSAGE_FORMS = {
    "Antibiotics": ["Capsule", "Tablet", "Suspension"],
    "Pain Relief": ["Tablet", "Capsule"],
    "Cardiovascular": ["Tablet"],
    "Diabetes": ["Tablet", "Injection"],
    "Respiratory": ["Inhaler", "Nasal Spray", "Tablet"],
    "Mental Health": ["Tablet"],
    "Vitamins & Supplements": ["Tablet", "Softgel", "Capsule"],
    "First Aid": ["Solution", "Pads", "Bandage"],
    "Personal Care": ["Gel", "Lotion", "Spray"],
    "Baby Care": ["Diaper", "Wipes", "Formula"],
    "Dental Care": ["Toothpaste", "Floss", "Mouthwash"],
    "Eye Care": ["Solution", "Drops", "Glasses"],
    "Skin Care": ["Cream", "Ointment", "Gel"],
    "Women's Health": ["Tablet", "Pads", "Capsule"],
    "Men's Health": ["Tablet", "Capsule"],
}

PACK_SIZES = {
    "Tablet": [10, 30, 50, 100],
    "Capsule": [10, 30, 50, 100],
    "Suspension": [60, 100, 120],  # mL
    "Injection": [1, 5, 10],       # vials
    "Inhaler": [1],
    "Nasal Spray": [1],
    "Gel": [15, 30, 50],           # g
    "Lotion": [100, 200, 500],     # mL
    "Spray": [50, 100],
    "Solution": [60, 100, 250],    # mL
    "Pads": [10, 25, 50],
    "Bandage": [20, 50, 100],
    "Diaper": [24, 36, 48],
    "Wipes": [40, 80, 120],
    "Formula": [400, 900],         # g
    "Toothpaste": [100, 150],      # mL
    "Floss": [50],                 # m
    "Mouthwash": [250, 500],       # mL
    "Drops": [10, 15],             # mL
    "Glasses": [1],
    "Cream": [15, 30],             # g
    "Ointment": [15, 30],          # g
    "Softgel": [30, 60, 90],
}

def format_product_name(base_name, category):
    """
    Make realistic display names like:
    'Amoxicillin 500 mg Capsule (Amoxil) — 10’s blister'
    """
    parts = base_name.split()
    generic = parts[0]
    strength = " ".join(parts[1:])
    strength = strength.replace("mg", " mg").replace("IU", " IU").strip()

    generic_key = "Insulin" if "Insulin" in generic else generic
    brand = pick(BRANDS_BY_GENERIC.get(generic_key, [generic + " (generic)"]))

    form = pick(DOSAGE_FORMS.get(category, ["Tablet"]))
    pack = pick(PACK_SIZES.get(form, [10]))

    if form in {"Suspension", "Solution", "Lotion", "Mouthwash", "Spray"}:
        pack_str = f"{pack} mL"; suffix = ""
    elif form in {"Cream", "Ointment", "Gel", "Formula"}:
        pack_str = f"{pack} g"; suffix = ""
    elif form == "Floss":
        pack_str = f"{pack} m"; suffix = ""
    elif form in {"Inhaler", "Glasses", "Injection"}:
        pack_str = f"{pack} unit" if pack == 1 else f"{pack} units"; suffix = ""
    else:
        pack_str = f"{pack}’s"
        suffix = " blister" if form in {"Tablet", "Capsule"} and pack in {10, 30} else ""

    if "Regular" in strength:
        strength = strength.replace("Regular", "").strip()

    space_strength = f" {strength}" if strength else ""
    return f"{generic}{space_strength} {form} ({brand}) — {pack_str}{suffix}".strip()

def random_dt_between(start_dt, end_dt):
    total_seconds = int((end_dt - start_dt).total_seconds())
    offset = random.randint(0, total_seconds)
    return start_dt + timedelta(seconds=offset)

def backdate_created_at(txn, dt):
    """Backdate created_at without re-triggering save() inventory math."""
    Transaction.objects.filter(pk=txn.pk).update(created_at=dt)

# ---------- Seeders ----------
def create_categories():
    data = [
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
        {'name': "Women's Health", 'description': "Feminine hygiene and women's health products"},
        {'name': "Men's Health", 'description': "Men's health and wellness products"},
    ]
    out = []
    for d in data:
        obj, created = Category.objects.get_or_create(
            name=d['name'],
            defaults={'description': d['description']}
        )
        out.append(obj)
        if created:
            print(f"✅ Created category: {obj.name}")
    return out

def create_suppliers():
    data = [
        {'name': 'PharmaCorp International', 'contact_person': 'Dr. Sarah Johnson', 'email': 'sarah.johnson@pharmacorp.com', 'phone': '+1-555-0101', 'address': '123 Pharma Blvd, Medical District, NY 10001'},
        {'name': 'MedSupply Plus', 'contact_person': 'Mike Chen', 'email': 'mike.chen@medsupply.com', 'phone': '+1-555-0102', 'address': '456 Healthcare Ave, Business Park, CA 90210'},
        {'name': 'Global Pharmaceuticals', 'contact_person': 'Dr. Emily Rodriguez', 'email': 'emily.rodriguez@globalpharma.com', 'phone': '+1-555-0103', 'address': '789 Medicine Way, Industrial Zone, TX 75001'},
        {'name': 'Quality Drug Co.', 'contact_person': 'James Wilson', 'email': 'james.wilson@qualitydrug.com', 'phone': '+1-555-0104', 'address': '321 Pharmacy St, Downtown, FL 33101'},
        {'name': 'Premium Medical Supplies', 'contact_person': 'Lisa Thompson', 'email': 'lisa.thompson@premiummed.com', 'phone': '+1-555-0105', 'address': '654 Medical Center Dr, Healthcare Hub, IL 60601'},
        {'name': 'Reliable Pharma Solutions', 'contact_person': 'David Kim', 'email': 'david.kim@reliablepharma.com', 'phone': '+1-555-0106', 'address': '987 Drug Lane, Medical Complex, WA 98101'},
        {'name': 'Express Medical', 'contact_person': 'Amanda Davis', 'email': 'amanda.davis@expressmed.com', 'phone': '+1-555-0107', 'address': '147 Health Plaza, Medical District, PA 19101'},
        {'name': 'First Choice Pharmaceuticals', 'contact_person': 'Robert Martinez', 'email': 'robert.martinez@firstchoice.com', 'phone': '+1-555-0108', 'address': '258 Medicine Circle, Healthcare Park, OH 43201'},
    ]
    out = []
    for d in data:
        obj, created = Supplier.objects.get_or_create(
            name=d['name'],
            defaults={
                'contact_person': d['contact_person'],
                'email': d['email'],
                'phone': d['phone'],
                'address': d['address'],
                'is_active': True
            }
        )
        out.append(obj)
        if created:
            print(f"✅ Created supplier: {obj.name}")
    return out

def create_products(categories, suppliers):
    # (unchanged list of product dicts from your script)  <-- keep as-is
    data = [
        # Antibiotics
        {'name': 'Amoxicillin 500mg', 'sku': 'AMOX500', 'description': 'Broad-spectrum antibiotic for bacterial infections', 'category': 'Antibiotics', 'unit_price': 15.99, 'cost_price': 8.50, 'reorder_level': 50, 'supplier': 'PharmaCorp International'},
        {'name': 'Azithromycin 250mg', 'sku': 'AZITH250', 'description': 'Macrolide antibiotic for respiratory infections', 'category': 'Antibiotics', 'unit_price': 22.50, 'cost_price': 12.00, 'reorder_level': 30, 'supplier': 'MedSupply Plus'},
        {'name': 'Ciprofloxacin 500mg', 'sku': 'CIPRO500', 'description': 'Fluoroquinolone antibiotic for UTIs', 'category': 'Antibiotics', 'unit_price': 18.75, 'cost_price': 10.25, 'reorder_level': 40, 'supplier': 'Global Pharmaceuticals'},
        # Pain Relief
        {'name': 'Ibuprofen 400mg', 'sku': 'IBUP400', 'description': 'NSAID for pain and fever', 'category': 'Pain Relief', 'unit_price': 8.99, 'cost_price': 4.50, 'reorder_level': 100, 'supplier': 'Quality Drug Co.'},
        {'name': 'Acetaminophen 500mg', 'sku': 'ACET500', 'description': 'Pain reliever and fever reducer', 'category': 'Pain Relief', 'unit_price': 6.50, 'cost_price': 3.25, 'reorder_level': 150, 'supplier': 'Premium Medical Supplies'},
        {'name': 'Naproxen 500mg', 'sku': 'NAPR500', 'description': 'Long-acting pain reliever for arthritis', 'category': 'Pain Relief', 'unit_price': 12.99, 'cost_price': 6.75, 'reorder_level': 60, 'supplier': 'Reliable Pharma Solutions'},
        # Cardiovascular
        {'name': 'Lisinopril 10mg', 'sku': 'LISI10', 'description': 'ACE inhibitor for hypertension', 'category': 'Cardiovascular', 'unit_price': 25.99, 'cost_price': 13.50, 'reorder_level': 40, 'supplier': 'PharmaCorp International'},
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
        {'name': 'Sertraline 50mg', 'sku': 'SERT50', 'description': 'SSRI antidepressant', 'category': 'Mental Health', 'unit_price': 38.99, 'cost_price': 20.00, 'reorder_level': 40, 'supplier': 'Quality Drug Co.'},
        {'name': 'Bupropion 150mg', 'sku': 'BUP150', 'description': 'Atypical antidepressant', 'category': 'Mental Health', 'unit_price': 42.50, 'cost_price': 22.25, 'reorder_level': 35, 'supplier': 'Premium Medical Supplies'},
        {'name': 'Lorazepam 1mg', 'sku': 'LORA1', 'description': 'Benzodiazepine for anxiety/insomnia', 'category': 'Mental Health', 'unit_price': 15.75, 'cost_price': 8.25, 'reorder_level': 60, 'supplier': 'Reliable Pharma Solutions'},
        # Vitamins & Supplements
        {'name': 'Vitamin D3 1000IU', 'sku': 'VITD1000', 'description': 'Vitamin D for bone health', 'category': 'Vitamins & Supplements', 'unit_price': 12.99, 'cost_price': 6.50, 'reorder_level': 100, 'supplier': 'Express Medical'},
        {'name': 'Omega-3 Fish Oil', 'sku': 'OMEGA3', 'description': 'Essential fatty acids for heart health', 'category': 'Vitamins & Supplements', 'unit_price': 18.50, 'cost_price': 9.25, 'reorder_level': 80, 'supplier': 'First Choice Pharmaceuticals'},
        {'name': 'Multivitamin Daily', 'sku': 'MULTIVIT', 'description': 'Complete daily multivitamin', 'category': 'Vitamins & Supplements', 'unit_price': 15.99, 'cost_price': 8.00, 'reorder_level': 90, 'supplier': 'PharmaCorp International'},
        # First Aid
        {'name': 'Adhesive Bandages', 'sku': 'BANDAGE', 'description': 'Sterile adhesive bandages', 'category': 'First Aid', 'unit_price': 5.99, 'cost_price': 3.00, 'reorder_level': 200, 'supplier': 'MedSupply Plus'},
        {'name': 'Antiseptic Solution', 'sku': 'ANTISEP', 'description': 'Antiseptic for wound cleaning', 'category': 'First Aid', 'unit_price': 8.50, 'cost_price': 4.25, 'reorder_level': 150, 'supplier': 'Global Pharmaceuticals'},
        {'name': 'Gauze Pads 4x4', 'sku': 'GAUZE4', 'description': 'Sterile gauze pads', 'category': 'First Aid', 'unit_price': 7.99, 'cost_price': 4.00, 'reorder_level': 180, 'supplier': 'Quality Drug Co.'},
        # Personal Care
        {'name': 'Hand Sanitizer 500ml', 'sku': 'HANDSAN', 'description': 'Alcohol-based hand sanitizer', 'category': 'Personal Care', 'unit_price': 6.99, 'cost_price': 3.50, 'reorder_level': 120, 'supplier': 'Premium Medical Supplies'},
        {'name': 'Sunscreen SPF 50', 'sku': 'SUNSPF50', 'description': 'Broad-spectrum sunscreen', 'category': 'Personal Care', 'unit_price': 14.99, 'cost_price': 7.50, 'reorder_level': 80, 'supplier': 'Reliable Pharma Solutions'},
        {'name': 'Moisturizing Lotion', 'sku': 'MOISTLOT', 'description': 'Hydrating body lotion', 'category': 'Personal Care', 'unit_price': 9.99, 'cost_price': 5.00, 'reorder_level': 100, 'supplier': 'Express Medical'},
        # Baby Care
        {'name': 'Baby Diapers Size 3', 'sku': 'DIAPER3', 'description': 'Disposable diapers', 'category': 'Baby Care', 'unit_price': 24.99, 'cost_price': 12.50, 'reorder_level': 50, 'supplier': 'First Choice Pharmaceuticals'},
        {'name': 'Baby Wipes', 'sku': 'BABYWIPE', 'description': 'Gentle wipes for sensitive skin', 'category': 'Baby Care', 'unit_price': 8.99, 'cost_price': 4.50, 'reorder_level': 100, 'supplier': 'PharmaCorp International'},
        {'name': 'Baby Formula', 'sku': 'BABYFORM', 'description': 'Complete infant nutrition', 'category': 'Baby Care', 'unit_price': 32.99, 'cost_price': 16.50, 'reorder_level': 40, 'supplier': 'MedSupply Plus'},
        # Dental Care
        {'name': 'Toothpaste Fluoride', 'sku': 'TOOTHPASTE', 'description': 'Cavity prevention toothpaste', 'category': 'Dental Care', 'unit_price': 4.99, 'cost_price': 2.50, 'reorder_level': 150, 'supplier': 'Global Pharmaceuticals'},
        {'name': 'Dental Floss', 'sku': 'DENTFLOSS', 'description': 'Waxed dental floss', 'category': 'Dental Care', 'unit_price': 3.99, 'cost_price': 2.00, 'reorder_level': 200, 'supplier': 'Quality Drug Co.'},
        {'name': 'Mouthwash Antiseptic', 'sku': 'MOUTHWASH', 'description': 'Antiseptic mouthwash', 'category': 'Dental Care', 'unit_price': 7.99, 'cost_price': 4.00, 'reorder_level': 120, 'supplier': 'Premium Medical Supplies'},
        # Eye Care
        {'name': 'Contact Lens Solution', 'sku': 'LENSSOL', 'description': 'Multi-purpose lens solution', 'category': 'Eye Care', 'unit_price': 12.99, 'cost_price': 6.50, 'reorder_level': 80, 'supplier': 'Reliable Pharma Solutions'},
        {'name': 'Eye Drops Lubricating', 'sku': 'EYEDROP', 'description': 'Lubricating eye drops', 'category': 'Eye Care', 'unit_price': 9.99, 'cost_price': 5.00, 'reorder_level': 100, 'supplier': 'Express Medical'},
        {'name': 'Reading Glasses +2.0', 'sku': 'READGLASS', 'description': 'Reading glasses +2.0', 'category': 'Eye Care', 'unit_price': 18.99, 'cost_price': 9.50, 'reorder_level': 60, 'supplier': 'First Choice Pharmaceuticals'},
        # Skin Care
        {'name': 'Hydrocortisone Cream 1%', 'sku': 'HYDROCORT', 'description': 'Topical steroid for inflammation', 'category': 'Skin Care', 'unit_price': 8.99, 'cost_price': 4.50, 'reorder_level': 100, 'supplier': 'PharmaCorp International'},
        {'name': 'Antifungal Cream', 'sku': 'ANTIFUNG', 'description': 'Topical antifungal', 'category': 'Skin Care', 'unit_price': 11.99, 'cost_price': 6.00, 'reorder_level': 80, 'supplier': 'MedSupply Plus'},
        {'name': 'Acne Treatment Gel', 'sku': 'ACNEGEL', 'description': 'Benzoyl peroxide gel', 'category': 'Skin Care', 'unit_price': 13.99, 'cost_price': 7.00, 'reorder_level': 90, 'supplier': 'Global Pharmaceuticals'},
        # Women's Health
        {'name': 'Prenatal Vitamins', 'sku': 'PRENATAL', 'description': 'Complete prenatal vitamins', 'category': "Women's Health", 'unit_price': 22.99, 'cost_price': 11.50, 'reorder_level': 60, 'supplier': 'Quality Drug Co.'},
        {'name': 'Feminine Hygiene Products', 'sku': 'FEMHYG', 'description': 'Feminine hygiene essentials', 'category': "Women's Health", 'unit_price': 8.99, 'cost_price': 4.50, 'reorder_level': 120, 'supplier': 'Premium Medical Supplies'},
        {'name': 'Iron Supplement', 'sku': 'IRONSUPP', 'description': 'Iron supplement', 'category': "Women's Health", 'unit_price': 16.99, 'cost_price': 8.50, 'reorder_level': 80, 'supplier': 'Reliable Pharma Solutions'},
        # Men's Health
        {'name': "Men's Multivitamin", 'sku': 'MENVIT', 'description': 'Complete multivitamin for men', 'category': "Men's Health", 'unit_price': 19.99, 'cost_price': 10.00, 'reorder_level': 70, 'supplier': 'Express Medical'},
        {'name': 'Testosterone Support', 'sku': 'TESTO', 'description': 'Testosterone support supplement', 'category': "Men's Health", 'unit_price': 28.99, 'cost_price': 14.50, 'reorder_level': 50, 'supplier': 'First Choice Pharmaceuticals'},
        {'name': 'Prostate Health', 'sku': 'PROSTATE', 'description': 'Saw palmetto for prostate health', 'category': "Men's Health", 'unit_price': 24.99, 'cost_price': 12.50, 'reorder_level': 60, 'supplier': 'PharmaCorp International'},
    ]

    cat_map = {c.name: c for c in categories}
    sup_map = {s.name: s for s in suppliers}

    out = []
    for d in data:
        category = cat_map.get(d['category'])
        supplier = sup_map.get(d['supplier'])
        if not (category and supplier):
            continue

        pretty_name = format_product_name(d['name'], d['category'])

        obj, created = Product.objects.get_or_create(
            sku=d['sku'],
            defaults={
                'name': pretty_name,
                'description': d['description'],
                'category': category,
                'supplier': supplier,
                'unit_price': money(d['unit_price']),
                'cost_price': money(d['cost_price']),
                'reorder_level': d['reorder_level'],
                'is_active': True,
            }
        )
        if not created and obj.name != pretty_name:
            obj.name = pretty_name
            obj.save(update_fields=['name'])

        out.append(obj)
        print(f"{'✅ Created' if created else 'ℹ️  Using existing'} product: {obj.name} ({obj.sku})")
    return out

def ensure_inventory_shells(products):
    """Create Inventory rows with 0 qty; all movement will happen via transactions."""
    out = []
    for p in products:
        inv, created = Inventory.objects.get_or_create(product=p, defaults={'quantity': 0})
        if created:
            print(f"✅ Created inventory shell: {p.name} - 0 units")
        out.append(inv)
    return out

# ---------- Batches + Transactions ----------
def make_batch(product, qty, received_dt, supplier=None):
    """Create a StockBatch with lot/expiry/unit_cost and return it."""
    if not HAS_BATCH:
        raise RuntimeError("StockBatch model not found. Add it to models.py and run migrations.")
    life = shelf_life_days(product.category.name)
    expiry = (received_dt.date() + timedelta(days=life))
    lot = f"{product.sku}-{received_dt.strftime('%y%m%d')}-{random.randint(100,999)}"
    unit_cost = money(Decimal(product.cost_price) * Decimal(str(random.uniform(0.95, 1.08))))
    batch = StockBatch.objects.create(
        product=product,
        lot_number=lot,
        expiry_date=expiry,
        quantity=qty,
        unit_cost=unit_cost,
        supplier=supplier or product.supplier,
        received_at=received_dt,
    )
    return batch

def fefo_batch(product):
    """Earliest expiring batch with remaining quantity."""
    return (StockBatch.objects
            .filter(product=product, quantity__gt=0)
            .order_by('expiry_date', 'created_at')
            .first())

def seed_batches_and_transactions(products):
    """
    For each product:
      - Create 1–3 initial batches (IN) before the 90d window.
      - Then create 4–10 mixed transactions within last 90d:
          * IN → new batch (with expiry)
          * OUT → consume the earliest-expiring batch (FEFO)
    """
    if not HAS_BATCH:
        raise RuntimeError("You asked to add expiries, but StockBatch model is missing.")

    end_dt = timezone.now()
    start_dt = end_dt - timedelta(days=90)

    created_batches = 0
    created_txns = 0

    out_qty_ranges_by_cat = {
        'Antibiotics': (1, 3),
        'Pain Relief': (1, 6),
        'Vitamins & Supplements': (1, 5),
        'Baby Care': (1, 4),
        'First Aid': (1, 8),
    }

    txn_fields = {f.name for f in Transaction._meta.get_fields()}
    has_txn_batch_fk = 'batch' in txn_fields  # optional FK

    with db_transaction.atomic():
        for p in products:
            # Ensure inventory row exists
            Inventory.objects.get_or_create(product=p, defaults={'quantity': 0})

            # --- Initial batches (IN) before window ---
            initial_batches = random.randint(1, 3)
            for _ in range(initial_batches):
                qty = random.randint(40, 150)
                recv = random_dt_between(start_dt - timedelta(days=45), start_dt - timedelta(days=1))
                batch = make_batch(p, qty, recv, supplier=p.supplier)
                created_batches += 1

                txn = Transaction.objects.create(
                    product=p,
                    transaction_type='IN',
                    quantity=qty,
                    unit_price=batch.unit_cost,
                    reference=rand_ref('PO', recv),
                    notes=f"Initial stock lot {batch.lot_number}",
                )
                update_kwargs = {'created_at': recv}
                if has_txn_batch_fk:
                    update_kwargs['batch'] = batch
                Transaction.objects.filter(pk=txn.pk).update(**update_kwargs)
                created_txns += 1

            # --- Mixed activity inside 90d window ---
            n = random.randint(4, 10)
            for _ in range(n):
                when = random_dt_between(start_dt, end_dt)
                if random.random() < 0.35:
                    # IN: receive new batch
                    qty = random.randint(20, 120)
                    batch = make_batch(p, qty, when, supplier=p.supplier)
                    created_batches += 1
                    txn = Transaction.objects.create(
                        product=p,
                        transaction_type='IN',
                        quantity=qty,
                        unit_price=batch.unit_cost,
                        reference=rand_ref('PO', when),
                        notes=f"Restock lot {batch.lot_number}",
                    )
                    update_kwargs = {'created_at': when}
                    if has_txn_batch_fk:
                        update_kwargs['batch'] = batch
                    Transaction.objects.filter(pk=txn.pk).update(**update_kwargs)
                    created_txns += 1
                else:
                    # OUT: sell from earliest-expiring batch
                    batch = fefo_batch(p)
                    if not batch:
                        continue
                    low, high = out_qty_ranges_by_cat.get(p.category.name, (1, 6))
                    desired = random.randint(low, high)
                    qty = min(desired, batch.quantity)
                    if qty <= 0:
                        continue

                    # Reduce the batch balance first; Transaction.save will reduce Inventory
                    batch.quantity -= qty
                    batch.save(update_fields=['quantity'])

                    unit_price = money(Decimal(p.unit_price) * Decimal(str(random.uniform(0.95, 1.08))))
                    txn = Transaction.objects.create(
                        product=p,
                        transaction_type='OUT',
                        quantity=-qty,  # negative for OUT
                        unit_price=unit_price,
                        reference=rand_ref('POS', when),
                        notes=f"Sale (FEFO lot {batch.lot_number})",
                    )
                    update_kwargs = {'created_at': when}
                    if has_txn_batch_fk:
                        update_kwargs['batch'] = batch
                    Transaction.objects.filter(pk=txn.pk).update(**update_kwargs)
                    created_txns += 1

    print(f"✅ Created {created_batches} batches and {created_txns} transactions")
    return created_batches, created_txns

# ---------- Main ----------
def main():
    print("🏥 Pharmacy Database Population Script (with batch expiries)")
    print("=" * 50)
    try:
        if not HAS_BATCH:
            raise RuntimeError("StockBatch model not found. Add it, run makemigrations/migrate, then re-run this script.")

        print("\n📋 Creating categories...")
        categories = create_categories()

        print("\n🏢 Creating suppliers...")
        suppliers = create_suppliers()

        print("\n💊 Creating products (realistic names/packaging)...")
        products = create_products(categories, suppliers)

        print("\n📦 Ensuring inventory rows (0 qty; transactions will fill)...")
        ensure_inventory_shells(products)

        print("\n🧪 Seeding batches (with expiries) and 90 days of transactions...")
        nbatches, ntxns = seed_batches_and_transactions(products)

        print("\n" + "=" * 50)
        print("🎉 Database Population Complete!")
        print(f"✅ Products: {len(products)}")
        print(f"✅ Batches: {nbatches}")
        print(f"✅ Transactions: {ntxns}")
        print("\n🚀 Inventory now reflects batch-based stock with realistic expiries (FEFO).")
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
