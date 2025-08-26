from django.http import JsonResponse
from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views
from . import ai_views


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
    
    # AI Agent endpoints
    path('api/ai/system-health/', ai_views.ai_system_health, name='ai_system_health'),
    path('api/ai/demand-forecast/', ai_views.ai_demand_forecast, name='ai_demand_forecast'),
    path('api/ai/inventory-optimization/', ai_views.ai_inventory_optimization, name='ai_inventory_optimization'),
    path('api/ai/sales-trends/', ai_views.ai_sales_trends, name='ai_sales_trends'),
    path('api/ai/comprehensive-insights/', ai_views.ai_comprehensive_insights, name='ai_comprehensive_insights'),
    path('api/ai/product-recommendations/<int:product_id>/', ai_views.ai_product_recommendations, name='ai_product_recommendations'),
    path('api/ai/alert-summary/', ai_views.ai_alert_summary, name='ai_alert_summary'),
    
    # AI Chat endpoints
    path('api/ai/chat/', ai_views.ai_chat, name='ai_chat'),
    path('api/ai/chat/history/', ai_views.ai_chat_history, name='ai_chat_history'),
    path('api/ai/chat/clear/', ai_views.ai_chat_clear, name='ai_chat_clear'),
]
