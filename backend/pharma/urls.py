from django.http import JsonResponse
from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views


def home(request):
    return JsonResponse({"message": "Welcome to the Pharmacy Inventory API"})

router = DefaultRouter()
router.register(r'categories', views.CategoryViewSet)
router.register(r'suppliers', views.SupplierViewSet)
router.register(r'products', views.ProductViewSet)
router.register(r'inventory', views.InventoryViewSet)
router.register(r'transactions', views.TransactionViewSet)

app_name = 'pharma'

urlpatterns = [
    path('api/', include(router.urls)),
    path('', home),
]
