from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views, ai_views

router = DefaultRouter()
router.register(r'categories', views.CategoryViewSet)
router.register(r'suppliers', views.SupplierViewSet)
router.register(r'products', views.ProductViewSet)
router.register(r'inventory', views.InventoryViewSet)
router.register(r'transactions', views.TransactionViewSet)

urlpatterns = [
    path('', include(router.urls)),
    
    # AI Agent endpoints
    path('ai/system-health/', ai_views.ai_system_health, name='ai_system_health'),
    path('ai/demand-forecast/', ai_views.ai_demand_forecast, name='ai_demand_forecast'),
    path('ai/inventory-optimization/', ai_views.ai_inventory_optimization, name='ai_inventory_optimization'),
    path('ai/sales-trends/', ai_views.ai_sales_trends, name='ai_sales_trends'),
    path('ai/comprehensive-insights/', ai_views.ai_comprehensive_insights, name='ai_comprehensive_insights'),
    path('ai/product-recommendations/<int:product_id>/', ai_views.ai_product_recommendations, name='ai_product_recommendations'),
    path('ai/alert-summary/', ai_views.ai_alert_summary, name='ai_alert_summary'),
    
    # Database context endpoint for external AI services
    path('ai/database-context/', ai_views.get_database_context, name='get_database_context'),
    
    # AI Chat endpoints
    path('ai/chat/', ai_views.ai_chat, name='ai_chat'),
    path('ai/chat/history/', ai_views.ai_chat_history, name='ai_chat_history'),
    path('ai/chat/clear/', ai_views.ai_chat_clear, name='ai_chat_clear'),
]
