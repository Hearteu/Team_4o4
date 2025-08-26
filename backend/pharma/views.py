from django.shortcuts import render
from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q, Sum, Count, F
from django.utils import timezone
from datetime import timedelta

from .models import Category, Supplier, Product, Inventory, Transaction
from .serializers import (
    CategorySerializer, CategoryDetailSerializer,
    SupplierSerializer, SupplierDetailSerializer,
    ProductSerializer, ProductDetailSerializer,
    InventorySerializer, TransactionSerializer
)

class CategoryViewSet(viewsets.ModelViewSet):
    """ViewSet for Category CRUD operations"""
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'created_at', 'product_count']
    ordering = ['name']

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return CategoryDetailSerializer
        return CategorySerializer

    @action(detail=True, methods=['get'])
    def products(self, request, pk=None):
        """Get all products in a category"""
        category = self.get_object()
        products = category.products.all()
        serializer = ProductSerializer(products, many=True)
        return Response(serializer.data)

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
    """ViewSet for Supplier CRUD operations"""
    queryset = Supplier.objects.all()
    serializer_class = SupplierSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['is_active']
    search_fields = ['name', 'contact_person', 'email']
    ordering_fields = ['name', 'created_at', 'product_count']
    ordering = ['name']

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return SupplierDetailSerializer
        return SupplierSerializer

    @action(detail=True, methods=['get'])
    def products(self, request, pk=None):
        """Get all products from a supplier"""
        supplier = self.get_object()
        products = supplier.products.all()
        serializer = ProductSerializer(products, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get only active suppliers"""
        suppliers = Supplier.objects.filter(is_active=True)
        serializer = self.get_serializer(suppliers, many=True)
        return Response(serializer.data)

class ProductViewSet(viewsets.ModelViewSet):
    """ViewSet for Product CRUD operations"""
    queryset = Product.objects.select_related('category', 'supplier').prefetch_related('inventory')
    serializer_class = ProductSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'supplier', 'is_active']
    search_fields = ['name', 'sku', 'description']
    ordering_fields = ['name', 'sku', 'unit_price', 'created_at', 'current_stock']
    ordering = ['name']

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProductDetailSerializer
        return ProductSerializer

    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """Get products with low stock"""
        products = self.get_queryset().filter(inventory__quantity__lte=F('reorder_level'))
        serializer = self.get_serializer(products, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def out_of_stock(self, request):
        """Get products that are out of stock"""
        products = self.get_queryset().filter(inventory__quantity=0)
        serializer = self.get_serializer(products, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get product statistics"""
        total_products = Product.objects.count()
        active_products = Product.objects.filter(is_active=True).count()
        low_stock_products = Product.objects.filter(inventory__quantity__lte=F('reorder_level')).count()
        out_of_stock_products = Product.objects.filter(inventory__quantity=0).count()
        
        # Calculate total inventory value
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
        """Adjust stock for a product"""
        product = self.get_object()
        quantity = request.data.get('quantity')
        notes = request.data.get('notes', '')
        
        if quantity is None:
            return Response(
                {'error': 'Quantity is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create transaction
        transaction = Transaction.objects.create(
            product=product,
            transaction_type='ADJUST',
            quantity=quantity,
            notes=notes
        )

        serializer = TransactionSerializer(transaction)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class InventoryViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for Inventory read operations"""
    queryset = Inventory.objects.select_related('product', 'product__category', 'product__supplier')
    serializer_class = InventorySerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['is_low_stock']
    search_fields = ['product__name', 'product__sku']
    ordering_fields = ['quantity', 'last_updated', 'total_value']
    ordering = ['-quantity']

    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """Get inventory items with low stock"""
        inventory = self.get_queryset().filter(is_low_stock=True)
        serializer = self.get_serializer(inventory, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get inventory summary"""
        total_items = Inventory.objects.count()
        low_stock_items = Inventory.objects.filter(is_low_stock=True).count()
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
        serializer = self.get_serializer(transactions, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def today(self, request):
        """Get today's transactions"""
        today = timezone.now().date()
        transactions = self.get_queryset().filter(created_at__date=today)
        serializer = self.get_serializer(transactions, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get transaction summary"""
        today = timezone.now().date()
        thirty_days_ago = timezone.now() - timedelta(days=30)

        today_stats = Transaction.objects.filter(created_at__date=today).aggregate(
            total_in=Sum('quantity', filter=Q(transaction_type='IN')),
            total_out=Sum('quantity', filter=Q(transaction_type='OUT')),
            count=Count('id')
        )

        monthly_stats = Transaction.objects.filter(created_at__gte=thirty_days_ago).aggregate(
            total_in=Sum('quantity', filter=Q(transaction_type='IN')),
            total_out=Sum('quantity', filter=Q(transaction_type='OUT')),
            count=Count('id')
        )

        return Response({
            'today': {
                'stock_in': today_stats['total_in'] or 0,
                'stock_out': abs(today_stats['total_out'] or 0),
                'transaction_count': today_stats['count']
            },
            'last_30_days': {
                'stock_in': monthly_stats['total_in'] or 0,
                'stock_out': abs(monthly_stats['total_out'] or 0),
                'transaction_count': monthly_stats['count']
            }
        })

    @action(detail=False, methods=['post'])
    def bulk_stock_in(self, request):
        """Bulk stock in operation"""
        items = request.data.get('items', [])
        reference = request.data.get('reference', '')
        notes = request.data.get('notes', '')

        if not items:
            return Response(
                {'error': 'Items list is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        transactions = []
        for item in items:
            product_id = item.get('product_id')
            quantity = item.get('quantity')
            unit_price = item.get('unit_price')

            if not product_id or not quantity:
                continue

            try:
                product = Product.objects.get(id=product_id)
                transaction = Transaction.objects.create(
                    product=product,
                    transaction_type='IN',
                    quantity=quantity,
                    unit_price=unit_price,
                    reference=reference,
                    notes=notes
                )
                transactions.append(transaction)
            except Product.DoesNotExist:
                continue

        serializer = TransactionSerializer(transactions, many=True)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
