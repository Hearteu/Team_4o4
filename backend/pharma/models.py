from decimal import Decimal

from django.core.exceptions import ValidationError
from django.core.validators import MinValueValidator
from django.db import models
from django.utils import timezone


class Category(models.Model):
    """Product categories for organizing inventory"""
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "Categories"
        ordering = ['name']

    def __str__(self):
        return self.name

class Supplier(models.Model):
    """Supplier information for products"""
    name = models.CharField(max_length=200)
    contact_person = models.CharField(max_length=100, blank=True)
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name

class Product(models.Model):
    """Product model for inventory items"""
    name = models.CharField(max_length=200)
    sku = models.CharField(max_length=50, unique=True, help_text="Stock Keeping Unit")
    description = models.TextField(blank=True)
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='products')
    supplier = models.ForeignKey(Supplier, on_delete=models.SET_NULL, null=True, blank=True, related_name='products')
    unit_price = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(Decimal('0.01'))])
    cost_price = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(Decimal('0.01'))])
    reorder_level = models.PositiveIntegerField(default=10, help_text="Minimum stock level before reordering")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.sku})"

class Inventory(models.Model):
    """Current inventory levels for products"""
    product = models.OneToOneField(Product, on_delete=models.CASCADE, related_name='inventory')
    quantity = models.PositiveIntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "Inventories"

    def __str__(self):
        return f"{self.product.name}: {self.quantity} units"

    @property
    def total_value(self):
        """Calculate total inventory value"""
        return self.quantity * self.product.unit_price

    @property
    def is_low_stock(self):
        """Check if stock is below reorder level"""
        return self.quantity <= self.product.reorder_level

class StockBatch(models.Model):
    """Per-lot inventory with its own expiry"""
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='batches')
    lot_number = models.CharField(max_length=100, blank=True)
    expiry_date = models.DateField(null=True, blank=True)  
    quantity = models.PositiveIntegerField(default=0)
    unit_cost = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    supplier = models.ForeignKey(Supplier, on_delete=models.SET_NULL, null=True, blank=True, related_name='batches')
    received_at = models.DateTimeField(default=timezone.now)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['expiry_date', 'created_at']
        indexes = [
            models.Index(fields=['product', 'expiry_date']),
            models.Index(fields=['product', 'lot_number']),
        ]
        constraints = []

    def __str__(self):
        exp = self.expiry_date.isoformat() if self.expiry_date else "no-expiry"
        return f"{self.product.sku} [{self.lot_number or 'LOT?'}] exp:{exp} qty:{self.quantity}"

    @property
    def is_expired(self):
        return bool(self.expiry_date and self.expiry_date < timezone.now().date())

    @property
    def days_to_expiry(self):
        if not self.expiry_date:
            return None
        return (self.expiry_date - timezone.now().date()).days


class Transaction(models.Model):
    """Inventory transactions (in/out)"""
    TRANSACTION_TYPES = [
        ('IN', 'Stock In'),
        ('OUT', 'Stock Out'),
        ('ADJUST', 'Adjustment'),
    ]

    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='transactions')
    batch = models.ForeignKey(StockBatch, on_delete=models.SET_NULL, null=True, blank=True, related_name='transactions')
    transaction_type = models.CharField(max_length=10, choices=TRANSACTION_TYPES)
    quantity = models.IntegerField(help_text="Positive for IN, negative for OUT")
    unit_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    reference = models.CharField(max_length=100, blank=True, help_text="Invoice number, PO number, etc.")
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.get_transaction_type_display()} - {self.product.name}: {self.quantity}"

    def clean(self):
        if self.transaction_type == 'IN' and self.quantity < 0:
            raise ValidationError("IN transactions must have positive quantity.")
        if self.transaction_type == 'OUT' and self.quantity > 0:
            raise ValidationError("OUT transactions must have negative quantity.")
        if self.batch and self.batch.product_id != self.product_id:
            raise ValidationError("Selected batch does not belong to this product.")

    def _get_fefo_batch(self, required_qty):
        """
        Pick the earliest-expiring batch with sufficient qty (FEFO).
        Simple version: must fit in a single batch; else raise.
        """
        return (StockBatch.objects
                .select_for_update()
                .filter(product=self.product, quantity__gte=required_qty)
                .order_by('expiry_date', 'created_at')
                .first())

    def save(self, *args, **kwargs):
        """Override save to update inventory and (now) batch levels."""
        is_new = self.pk is None

        self.clean()

        super().save(*args, **kwargs)

        if is_new:
            inventory, _ = Inventory.objects.get_or_create(product=self.product)

            if self.transaction_type == 'IN':
                if self.batch is None:
                    self.batch = StockBatch.objects.create(
                        product=self.product,
                        quantity=0,  
                    )
                    
                    Transaction.objects.filter(pk=self.pk).update(batch=self.batch)

                self.batch.quantity += self.quantity
                self.batch.save(update_fields=['quantity'])

                inventory.quantity += self.quantity
                inventory.save(update_fields=['quantity'])

            elif self.transaction_type == 'OUT':
                needed = abs(self.quantity)

                if self.batch:
                    if self.batch.quantity < needed:
                        raise ValidationError(
                            f"Batch {self.batch.id} has only {self.batch.quantity}, but {needed} requested."
                        )
                    self.batch.quantity -= needed
                    self.batch.save(update_fields=['quantity'])
                else:
                    fefo = self._get_fefo_batch(needed)
                    if not fefo:
                        raise ValidationError("No batch with sufficient quantity for FEFO allocation.")
                    fefo.quantity -= needed
                    fefo.save(update_fields=['quantity'])
                    Transaction.objects.filter(pk=self.pk).update(batch=fefo)

                inventory.quantity = max(0, inventory.quantity - needed)
                inventory.save(update_fields=['quantity'])
