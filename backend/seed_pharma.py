from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction
from django.db.models import F
from pharma.models import Category, Inventory, Product, Supplier, Transaction


class Command(BaseCommand):
    help = "Seed the dev database with sample pharmacy data (idempotent)."

    def handle(self, *args, **options):
        with transaction.atomic():
            # Categories
            antibiotics, _ = Category.objects.get_or_create(
                name="Antibiotics", defaults={"description": "All antibiotic medicines"}
            )
            analgesics, _ = Category.objects.get_or_create(
                name="Analgesics", defaults={"description": "Pain & fever relief"}
            )

            # Suppliers
            acme, _ = Supplier.objects.get_or_create(name="Acme Pharma", defaults={"is_active": True})
            medco, _ = Supplier.objects.get_or_create(name="MedCo", defaults={"is_active": True})

            # Products (update_or_create keeps it idempotent)
            products = [
                dict(name="Amoxicillin 500mg Cap", sku="AMOX500",
                     category=antibiotics, supplier=acme,
                     unit_price=Decimal("12.50"), cost_price=Decimal("10.00"),
                     reorder_level=20, is_active=True),
                dict(name="Cefalexin 500mg Cap", sku="CEFA500",
                     category=antibiotics, supplier=acme,
                     unit_price=Decimal("15.00"), cost_price=Decimal("12.00"),
                     reorder_level=15, is_active=True),
                dict(name="Paracetamol 500mg Tab", sku="PARA500",
                     category=analgesics, supplier=medco,
                     unit_price=Decimal("2.00"), cost_price=Decimal("1.20"),
                     reorder_level=50, is_active=True),
            ]

            created = []
            for p in products:
                prod, _ = Product.objects.update_or_create(sku=p["sku"], defaults=p)
                Inventory.objects.get_or_create(product=prod, defaults={"quantity": 0})
                created.append(prod)

            def stock_in(prod, qty, price, reference, notes="seed"):
                # idempotent: skip if we've already seeded this reference for this product
                if Transaction.objects.filter(
                    product=prod, transaction_type="IN", reference=reference
                ).exists():
                    return
                inv, _ = Inventory.objects.select_for_update().get_or_create(product=prod, defaults={"quantity": 0})
                inv.quantity = F("quantity") + qty
                inv.save(update_fields=["quantity"])
                Transaction.objects.create(
                    product=prod, transaction_type="IN",
                    quantity=qty, unit_price=price, reference=reference, notes=notes
                )
                # keep latest cost price
                prod.cost_price = price
                prod.save(update_fields=["cost_price"])

            def stock_out(prod, qty, reference, notes="seed"):
                if Transaction.objects.filter(
                    product=prod, transaction_type="OUT", reference=reference
                ).exists():
                    return
                inv = Inventory.objects.select_for_update().get(product=prod)
                if inv.quantity < qty:
                    self.stdout.write(self.style.WARNING(f"Skip OUT {qty} {prod.sku}: insufficient stock"))
                    return
                inv.quantity = F("quantity") - qty
                inv.save(update_fields=["quantity"])
                Transaction.objects.create(
                    product=prod, transaction_type="OUT",
                    quantity=qty, unit_price=prod.unit_price, reference=reference, notes=notes
                )

            # Seed a few movements
            stock_in(created[0], 100, Decimal("12.50"), "GRN-0001")
            stock_in(created[1], 60,  Decimal("15.00"), "GRN-0002")
            stock_in(created[2], 500, Decimal("2.00"),  "GRN-0003")
            stock_out(created[2], 20, "SALE-0001")

        self.stdout.write(self.style.SUCCESS("✅ Seed complete."))
        self.stdout.write("Open: /api/categories/, /api/products/, /api/inventory/, /api/transactions/")
