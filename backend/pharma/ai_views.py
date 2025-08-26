from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticatedOrReadOnly
from rest_framework.response import Response
from rest_framework import status
from django.http import JsonResponse
from django.db.models import Sum, Count, Avg, Q, F
from django.utils import timezone
from datetime import timedelta
from .models import Product, Inventory, Transaction, Category, Supplier
from .ai_agent import PharmacyAIAgent
from .ai_chat import PharmacyAIChat
import logging

logger = logging.getLogger(__name__)

# Initialize AI Agent instance
ai_agent = PharmacyAIAgent()

# Initialize AI Chat instance
ai_chat_instance = PharmacyAIChat()

@api_view(['GET'])
@permission_classes([])  # Allow unauthenticated access for external API calls
def get_database_context(request):
    """
    Provide database context for external AI services
    This endpoint returns current pharmacy data that can be used by Rev21 Labs API
    """
    try:
        # Get current inventory data
        total_products = Product.objects.count()
        total_categories = Category.objects.count()
        total_suppliers = Supplier.objects.count()
        
        # Get inventory summary
        inventory_summary = Inventory.objects.aggregate(
            total_items=Sum('quantity'),
            total_value=Sum(F('quantity') * F('product__unit_price')),
            low_stock_count=Count('id', filter=Q(quantity__lte=F('product__reorder_level'))),
            out_of_stock_count=Count('id', filter=Q(quantity=0))
        )
        
        # Get recent transactions
        recent_transactions = Transaction.objects.select_related('product').order_by('-created_at')[:10]
        transactions_data = []
        for trans in recent_transactions:
            transactions_data.append({
                'product_name': trans.product.name,
                'transaction_type': trans.transaction_type,
                'quantity': trans.quantity,
                'timestamp': trans.created_at.isoformat(),
                'total_amount': trans.quantity * trans.unit_price
            })
        
        # Get low stock items
        low_stock_items = Inventory.objects.select_related('product').filter(
            quantity__lte=F('product__reorder_level')
        )[:10]
        low_stock_data = []
        for item in low_stock_items:
            low_stock_data.append({
                'product_name': item.product.name,
                'current_quantity': item.quantity,
                'reorder_level': item.product.reorder_level,
                'category': item.product.category.name if item.product.category else 'Uncategorized'
            })
        
        # Get top products by category
        categories_data = []
        categories = Category.objects.all()
        for category in categories:
            products_in_category = Product.objects.filter(category=category).count()
            categories_data.append({
                'category_name': category.name,
                'product_count': products_in_category
            })
        
        # Compile all data
        context_data = {
            'summary': {
                'total_products': total_products,
                'total_categories': total_categories,
                'total_suppliers': total_suppliers,
                'total_inventory_items': inventory_summary['total_items'] or 0,
                'total_inventory_value': float(inventory_summary['total_value'] or 0),
                'low_stock_count': inventory_summary['low_stock_count'] or 0,
                'out_of_stock_count': inventory_summary['out_of_stock_count'] or 0
            },
            'low_stock_items': low_stock_data,
            'recent_transactions': transactions_data,
            'categories': categories_data,
            'timestamp': timezone.now().isoformat()
        }
        
        return Response({
            'success': True,
            'data': context_data,
            'message': 'Database context retrieved successfully'
        })
        
    except Exception as e:
        logger.error(f"Error getting database context: {e}")
        return Response({
            'error': f'Failed to retrieve database context: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticatedOrReadOnly])
def ai_system_health(request):
    """
    Get AI-powered system health analysis
    """
    try:
        ai_agent = PharmacyAIAgent()
        health_data = ai_agent.get_system_health_score()
        
        if 'error' in health_data:
            return Response(
                {'error': health_data['error']}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response({
            'success': True,
            'data': health_data,
            'message': 'System health analysis completed successfully'
        })
    except Exception as e:
        logger.error(f"Error in AI system health endpoint: {e}")
        return Response(
            {'error': 'Failed to analyze system health'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsAuthenticatedOrReadOnly])
def ai_demand_forecast(request):
    """
    Get AI-powered demand forecasting
    """
    try:
        days = int(request.GET.get('days', 30))
        ai_agent = PharmacyAIAgent()
        forecast_data = ai_agent.forecast_demand(days=days)
        
        if 'error' in forecast_data:
            return Response(
                {'error': forecast_data['error']}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response({
            'success': True,
            'data': forecast_data,
            'message': 'Demand forecast generated successfully'
        })
    except Exception as e:
        logger.error(f"Error in AI demand forecast endpoint: {e}")
        return Response(
            {'error': 'Failed to generate demand forecast'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsAuthenticatedOrReadOnly])
def ai_inventory_optimization(request):
    """
    Get AI-powered inventory optimization recommendations
    """
    try:
        ai_agent = PharmacyAIAgent()
        optimization_data = ai_agent.optimize_inventory()
        
        if 'error' in optimization_data:
            return Response(
                {'error': optimization_data['error']}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response({
            'success': True,
            'data': optimization_data,
            'message': 'Inventory optimization completed successfully'
        })
    except Exception as e:
        logger.error(f"Error in AI inventory optimization endpoint: {e}")
        return Response(
            {'error': 'Failed to optimize inventory'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsAuthenticatedOrReadOnly])
def ai_sales_trends(request):
    """
    Get AI-powered sales trend analysis
    """
    try:
        ai_agent = PharmacyAIAgent()
        trends_data = ai_agent.predict_sales_trends()
        
        if 'error' in trends_data:
            return Response(
                {'error': trends_data['error']}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response({
            'success': True,
            'data': trends_data,
            'message': 'Sales trend analysis completed successfully'
        })
    except Exception as e:
        logger.error(f"Error in AI sales trends endpoint: {e}")
        return Response(
            {'error': 'Failed to analyze sales trends'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsAuthenticatedOrReadOnly])
def ai_comprehensive_insights(request):
    """
    Get comprehensive AI insights
    """
    try:
        ai_agent = PharmacyAIAgent()
        insights_data = ai_agent.get_ai_insights()
        
        if 'error' in insights_data:
            return Response(
                {'error': insights_data['error']}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response({
            'success': True,
            'data': insights_data,
            'message': 'Comprehensive insights generated successfully'
        })
    except Exception as e:
        logger.error(f"Error in AI comprehensive insights endpoint: {e}")
        return Response(
            {'error': 'Failed to generate comprehensive insights'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsAuthenticatedOrReadOnly])
def ai_product_recommendations(request, product_id):
    """
    Get AI-powered product recommendations
    """
    try:
        ai_agent = PharmacyAIAgent()
        # Get demand forecast for the product
        forecast = ai_agent.forecast_demand(product_id=product_id, days=30)
        
        if 'error' in forecast:
            return Response(
                {'error': forecast['error']}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        # Generate specific recommendations
        recommendations = []
        
        if forecast.get('stockout_risk', 0) > 0.3:
            recommendations.append({
                'type': 'high_risk',
                'message': 'High stockout risk detected',
                'action': 'Consider immediate reorder',
                'priority': 'high'
            })
        
        if forecast.get('current_stock', 0) < forecast.get('avg_daily_demand', 0) * 7:
            recommendations.append({
                'type': 'low_stock',
                'message': 'Less than 1 week of stock remaining',
                'action': 'Monitor closely and reorder soon',
                'priority': 'medium'
            })
        
        if forecast.get('demand_volatility', 0) > 5:
            recommendations.append({
                'type': 'volatile_demand',
                'message': 'High demand volatility detected',
                'action': 'Consider increasing safety stock',
                'priority': 'medium'
            })
        
        recommendations_data = {
            'product_id': product_id,
            'forecast': forecast,
            'recommendations': recommendations,
            'summary': {
                'total_recommendations': len(recommendations),
                'high_priority_count': len([r for r in recommendations if r['priority'] == 'high']),
                'risk_level': 'high' if forecast.get('stockout_risk', 0) > 0.3 else 'medium' if forecast.get('stockout_risk', 0) > 0.1 else 'low'
            }
        }
        
        if 'error' in recommendations_data:
            return Response(
                {'error': recommendations_data['error']}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response({
            'success': True,
            'data': recommendations_data,
            'message': 'Product recommendations generated successfully'
        })
    except Exception as e:
        logger.error(f"Error in AI product recommendations endpoint: {e}")
        return Response(
            {'error': 'Failed to generate product recommendations'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsAuthenticatedOrReadOnly])
def ai_alert_summary(request):
    """
    Get AI-powered alert summary
    """
    try:
        ai_agent = PharmacyAIAgent()
        # Get system health
        health = ai_agent.get_system_health_score()
        
        # Get inventory optimization
        optimization = ai_agent.optimize_inventory()
        
        # Generate alerts
        alerts = []
        
        if health.get('overall_score', 100) < 70:
            alerts.append({
                'type': 'system_health',
                'severity': 'critical',
                'message': f"System health score is {health.get('overall_score', 0)} - needs immediate attention",
                'action': 'Review system status and take corrective actions'
            })
        
        if health.get('low_stock_count', 0) > 5:
            alerts.append({
                'type': 'low_stock',
                'severity': 'high',
                'message': f"{health.get('low_stock_count', 0)} products are low on stock",
                'action': 'Review and reorder low stock items'
            })
        
        if health.get('out_of_stock_count', 0) > 0:
            alerts.append({
                'type': 'out_of_stock',
                'severity': 'critical',
                'message': f"{health.get('out_of_stock_count', 0)} products are out of stock",
                'action': 'Urgently reorder out of stock items'
            })
        
        urgent_reorders = optimization.get('summary', {}).get('urgent_reorders_needed', 0)
        if urgent_reorders > 0:
            alerts.append({
                'type': 'urgent_reorder',
                'severity': 'high',
                'message': f"{urgent_reorders} products need urgent reordering",
                'action': 'Place urgent reorders immediately'
            })
        
        alert_data = {
            'total_alerts': len(alerts),
            'critical_alerts': len([a for a in alerts if a['severity'] == 'critical']),
            'high_alerts': len([a for a in alerts if a['severity'] == 'high']),
            'alerts': alerts,
            'last_updated': ai_agent.get_ai_insights().get('generated_at', '')
        }
        
        if 'error' in alert_data:
            return Response(
                {'error': alert_data['error']}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response({
            'success': True,
            'data': alert_data,
            'message': 'Alert summary generated successfully'
        })
    except Exception as e:
        logger.error(f"Error in AI alert summary endpoint: {e}")
        return Response(
            {'error': 'Failed to generate alert summary'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([])
def ai_chat(request):
    """
    AI Chat endpoint for conversational pharmacy assistance
    """
    try:
        message = request.data.get('message', '').strip()
        
        if not message:
            return Response({
                'error': 'Message is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Process message through AI chat
        response = ai_chat_instance.process_message(message)
        
        return Response({
            'success': True,
            'data': response,
            'message': 'Chat response generated successfully'
        })
        
    except Exception as e:
        logger.error(f"Error in AI chat endpoint: {e}")
        return Response({
            'error': 'Failed to process chat message'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([])
def ai_chat_history(request):
    """
    Get AI chat conversation history
    """
    try:
        history = ai_chat_instance.get_conversation_history()
        
        return Response({
            'success': True,
            'data': {
                'history': history,
                'total_messages': len(history)
            },
            'message': 'Chat history retrieved successfully'
        })
        
    except Exception as e:
        logger.error(f"Error in AI chat history endpoint: {e}")
        return Response({
            'error': 'Failed to retrieve chat history'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([])
def ai_chat_clear(request):
    """
    Clear AI chat conversation history
    """
    try:
        ai_chat_instance.clear_history()
        
        return Response({
            'success': True,
            'message': 'Chat history cleared successfully'
        })
        
    except Exception as e:
        logger.error(f"Error in AI chat clear endpoint: {e}")
        return Response({
            'error': 'Failed to clear chat history'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
