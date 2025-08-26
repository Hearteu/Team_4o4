from datetime import datetime, time, timedelta

from django.db import transaction as db_txn
from django.db.models import Count, DecimalField, ExpressionWrapper, F, Q, Sum
from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .filters import InventoryFilter
from .models import (Category, Inventory, Product, StockBatch, Supplier,
                     Transaction)
from .serializers import (CategoryDetailSerializer, CategorySerializer,
                          InventorySerializer, ProductDetailSerializer,
                          ProductSerializer, StockBatchSerializer,
                          SupplierDetailSerializer, SupplierSerializer,
                          TransactionSerializer)


class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    """ViewSet for Category CRUD operations"""
    def get_queryset(self):
        return Category.objects.annotate(product_count=Count('products'))

    serializer_class = CategorySerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'created_at', 'product_count']
    ordering = ['name']

    def get_serializer_class(self):
        return CategoryDetailSerializer if self.action == 'retrieve' else CategorySerializer

    @action(detail=True, methods=['get'])
    def products(self, request, pk=None):
        """Get all products in a category"""
        category = self.get_object()
        products = category.products.all()
        return Response(ProductSerializer(products, many=True).data)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get category statistics"""
        total_categories = Category.objects.count()
        categories_with_products = Category.objects.filter(products__isnull=False).distinct().count()
        return Response({
            'total_categories': total_categories,
            'categories_with_products': categories_with_products,
            'empty_categories': total_categories - categories_with_products
        })


class SupplierViewSet(viewsets.ModelViewSet):
    queryset = Supplier.objects.all()
    """ViewSet for Supplier CRUD operations"""
    def get_queryset(self):
        return Supplier.objects.annotate(product_count=Count('products'))

    serializer_class = SupplierSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['is_active']
    search_fields = ['name', 'contact_person', 'email']
    ordering_fields = ['name', 'created_at', 'product_count']
    ordering = ['name']

    def get_serializer_class(self):
        return SupplierDetailSerializer if self.action == 'retrieve' else SupplierSerializer

    @action(detail=True, methods=['get'])
    def products(self, request, pk=None):
        """Get all products from a supplier"""
        supplier = self.get_object()
        products = supplier.products.all()
        return Response(ProductSerializer(products, many=True).data)

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get only active suppliers"""
        suppliers = self.get_queryset().filter(is_active=True)
        return Response(self.get_serializer(suppliers, many=True).data)


class ProductViewSet(viewsets.ModelViewSet):
    """ViewSet for Product CRUD operations"""
    queryset = (Product.objects
        .select_related('category', 'supplier')
        .annotate(current_stock=F('inventory__quantity')))
    serializer_class = ProductSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'supplier', 'is_active']
    search_fields = ['name', 'sku', 'description']
    ordering_fields = ['name', 'sku', 'unit_price', 'created_at']
    ordering = ['name']

    def get_serializer_class(self):
        return ProductDetailSerializer if self.action == 'retrieve' else ProductSerializer

    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """Get products with low stock"""
        products = self.get_queryset().filter(inventory__quantity__lte=F('reorder_level'))
        return Response(self.get_serializer(products, many=True).data)

    @action(detail=False, methods=['get'])
    def out_of_stock(self, request):
        """Get products that are out of stock"""
        products = self.get_queryset().filter(inventory__quantity=0)
        return Response(self.get_serializer(products, many=True).data)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get product statistics"""
        total_products = Product.objects.count()
        active_products = Product.objects.filter(is_active=True).count()
        low_stock_products = Product.objects.filter(inventory__quantity__lte=F('reorder_level')).count()
        out_of_stock_products = Product.objects.filter(inventory__quantity=0).count()
        total_value = Inventory.objects.aggregate(
            total=Sum(F('quantity') * F('product__unit_price'))
        )['total'] or 0
        return Response({
            'total_products': total_products,
            'active_products': active_products,
            'low_stock_products': low_stock_products,
            'out_of_stock_products': out_of_stock_products,
            'total_inventory_value': total_value
        })

    @action(detail=True, methods=['post'])
    def adjust_stock(self, request, pk=None):
        """Adjust stock for a product (+/- quantity)"""
        product = self.get_object()
        try:
            delta = int(request.data.get('quantity'))
        except (TypeError, ValueError):
            return Response({'error': 'Quantity must be an integer'}, status=status.HTTP_400_BAD_REQUEST)
        notes = request.data.get('notes', '')

        with db_txn.atomic():
            inv, _ = Inventory.objects.select_for_update().get_or_create(product=product)
            inv.quantity = F('quantity') + delta
            inv.save(update_fields=['quantity'])

            txn = Transaction.objects.create(
                product=product,
                transaction_type='ADJUST',
                quantity=delta,
                unit_price=product.unit_price,
                notes=notes
            )
        return Response(TransactionSerializer(txn).data, status=status.HTTP_201_CREATED)

class StockBatchViewSet(viewsets.ModelViewSet):
    queryset = (StockBatch.objects
                .select_related('product', 'supplier', 'product__category'))
    serializer_class = StockBatchSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['product', 'product__category', 'supplier', 'expiry_date']
    search_fields = ['lot_number', 'product__name', 'product__sku']
    ordering_fields = ['expiry_date', 'quantity', 'received_at', 'updated_at']
    ordering = ['expiry_date']

class InventoryViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for Inventory read operations"""
    queryset = (Inventory.objects
        .select_related('product', 'product__category', 'product__supplier')
        .annotate(
            total_value_db=ExpressionWrapper(
                F('quantity') * F('product__unit_price'),
                output_field=DecimalField(max_digits=12, decimal_places=2),
            )
        ))
    serializer_class = InventorySerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = InventoryFilter
    search_fields = ['product__name', 'product__sku']
    ordering_fields = ['quantity', 'last_updated', 'total_value_db']
    ordering = ['-quantity']

    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """Get inventory items with low stock (explicit condition; no non-DB fields)"""
        inventory = self.get_queryset().filter(quantity__lte=F('product__reorder_level'))
        return Response(self.get_serializer(inventory, many=True).data)

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get inventory summary"""
        total_items = Inventory.objects.count()
        low_stock_items = Inventory.objects.filter(quantity__lte=F('product__reorder_level')).count()
        out_of_stock_items = Inventory.objects.filter(quantity=0).count()
        total_value = Inventory.objects.aggregate(
            total=Sum(F('quantity') * F('product__unit_price'))
        )['total'] or 0
        return Response({
            'total_items': total_items,
            'low_stock_items': low_stock_items,
            'out_of_stock_items': out_of_stock_items,
            'total_value': total_value
        })


class TransactionViewSet(viewsets.ModelViewSet):
    """ViewSet for Transaction CRUD operations"""
    queryset = Transaction.objects.select_related('product', 'product__category')
    serializer_class = TransactionSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['transaction_type', 'product', 'product__category']
    search_fields = ['product__name', 'product__sku', 'reference', 'notes']
    ordering_fields = ['created_at', 'quantity', 'unit_price']
    ordering = ['-created_at']

    @action(detail=False, methods=['get'])
    def recent(self, request):
        """Get recent transactions (last 30 days)"""
        thirty_days_ago = timezone.now() - timedelta(days=30)
        transactions = self.get_queryset().filter(created_at__gte=thirty_days_ago)
        return Response(self.get_serializer(transactions, many=True).data)

    @action(detail=False, methods=['get'])
    def today(self, request):
        """Get today's transactions (index-friendly range)"""
        tznow = timezone.now()
        start = datetime.combine(tznow.date(), time.min, tzinfo=tznow.tzinfo)
        end = datetime.combine(tznow.date(), time.max, tzinfo=tznow.tzinfo)
        transactions = self.get_queryset().filter(created_at__gte=start, created_at__lte=end)
        return Response(self.get_serializer(transactions, many=True).data)

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get transaction summary"""
        tznow = timezone.now()
        start_today = datetime.combine(tznow.date(), time.min, tzinfo=tznow.tzinfo)
        end_today = datetime.combine(tznow.date(), time.max, tzinfo=tznow.tzinfo)
        thirty_days_ago = tznow - timedelta(days=30)

        today_qs = Transaction.objects.filter(created_at__gte=start_today, created_at__lte=end_today)
        last30_qs = Transaction.objects.filter(created_at__gte=thirty_days_ago)

        today_stats = today_qs.aggregate(
            total_in=Sum('quantity', filter=Q(transaction_type='IN')),
            total_out=Sum('quantity', filter=Q(transaction_type='OUT')),
            count=Count('id')
        )
        monthly_stats = last30_qs.aggregate(
            total_in=Sum('quantity', filter=Q(transaction_type='IN')),
            total_out=Sum('quantity', filter=Q(transaction_type='OUT')),
            count=Count('id')
        )

        return Response({
            'today': {
                'stock_in': today_stats['total_in'] or 0,
                'stock_out': today_stats['total_out'] or 0,
                'transaction_count': today_stats['count'] or 0
            },
            'last_30_days': {
                'stock_in': monthly_stats['total_in'] or 0,
                'stock_out': monthly_stats['total_out'] or 0,
                'transaction_count': monthly_stats['count'] or 0
            }
        })

    @action(detail=False, methods=['post'])
    def bulk_stock_in(self, request):
        """Bulk stock in operation (atomic + updates inventory)"""
        items = request.data.get('items', [])
        reference = request.data.get('reference', '')
        notes = request.data.get('notes', '')
        if not items:
            return Response({'error': 'Items list is required'}, status=status.HTTP_400_BAD_REQUEST)

        created = []
        with db_txn.atomic():
            for item in items:
                pid = item.get('product_id')
                qty = item.get('quantity')
                price = item.get('unit_price')
                try:
                    qty = int(qty)
                    product = Product.objects.select_related('inventory').get(id=pid)
                except (TypeError, ValueError, Product.DoesNotExist):
                    continue

                inv, _ = Inventory.objects.select_for_update().get_or_create(product=product)
                inv.quantity = F('quantity') + qty
                inv.save(update_fields=['quantity'])

                created.append(Transaction.objects.create(
                    product=product, transaction_type='IN',
                    quantity=qty, unit_price=price, reference=reference, notes=notes
                ))
        return Response(TransactionSerializer(created, many=True).data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'])
    def stock_out(self, request):
        """Single-item stock out (dispense/sale)"""
        pid = request.data.get('product_id')
        qty = request.data.get('quantity')
        reference = request.data.get('reference', '')
        notes = request.data.get('notes', '')
        try:
            qty = int(qty)
            product = Product.objects.select_related('inventory').get(id=pid)
        except (TypeError, ValueError, Product.DoesNotExist):
            return Response({'error': 'Invalid product_id or quantity'}, status=status.HTTP_400_BAD_REQUEST)

        with db_txn.atomic():
            inv, _ = Inventory.objects.select_for_update().get_or_create(product=product)
            inv.refresh_from_db(fields=['quantity'])
            if inv.quantity < qty:
                return Response({'error': 'Insufficient stock'}, status=status.HTTP_400_BAD_REQUEST)
            inv.quantity = F('quantity') - qty
            inv.save(update_fields=['quantity'])

            txn = Transaction.objects.create(
                product=product, transaction_type='OUT',
                quantity=qty, unit_price=product.unit_price,
                reference=reference, notes=notes
            )
        return Response(TransactionSerializer(txn).data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'])
    def bulk_stock_out(self, request):
        """Bulk stock out (atomic)"""
        items = request.data.get('items', [])
        reference = request.data.get('reference', '')
        notes = request.data.get('notes', '')
        if not items:
            return Response({'error': 'Items list is required'}, status=status.HTTP_400_BAD_REQUEST)

        created = []
        with db_txn.atomic():
            for item in items:
                pid = item.get('product_id')
                qty = item.get('quantity')
                try:
                    qty = int(qty)
                    product = Product.objects.select_related('inventory').get(id=pid)
                except (TypeError, ValueError, Product.DoesNotExist):
                    continue

                inv, _ = Inventory.objects.select_for_update().get_or_create(product=product)
                inv.refresh_from_db(fields=['quantity'])
                if inv.quantity < qty:
                    return Response({'error': f'Insufficient stock for product {pid}'}, status=status.HTTP_400_BAD_REQUEST)

                inv.quantity = F('quantity') - qty
                inv.save(update_fields=['quantity'])

                created.append(Transaction.objects.create(
                    product=product, transaction_type='OUT',
                    quantity=qty, unit_price=product.unit_price,
                    reference=reference, notes=notes
                ))
        return Response(TransactionSerializer(created, many=True).data, status=status.HTTP_201_CREATED)
