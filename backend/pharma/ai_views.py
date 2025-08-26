from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticatedOrReadOnly
from rest_framework.response import Response
from rest_framework import status
from django.http import JsonResponse
from .ai_agent import PharmacyAIAgent
import logging

logger = logging.getLogger(__name__)

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
        ai_agent = PharmacyAIAgent()
        
        # Get parameters from request
        product_id = request.GET.get('product_id')
        days = int(request.GET.get('days', 30))
        
        if product_id:
            product_id = int(product_id)
            forecast_data = ai_agent.forecast_demand(product_id=product_id, days=days)
        else:
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
            'message': 'Inventory optimization analysis completed successfully'
        })
    except Exception as e:
        logger.error(f"Error in AI inventory optimization endpoint: {e}")
        return Response(
            {'error': 'Failed to generate inventory optimization'}, 
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
        
        # Get parameters from request
        days = int(request.GET.get('days', 30))
        
        trends_data = ai_agent.predict_sales_trends(days=days)
        
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
    Get comprehensive AI insights for the pharmacy
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
            'message': 'Comprehensive AI insights generated successfully'
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
    Get AI recommendations for a specific product
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
        
        return Response({
            'success': True,
            'data': {
                'product_id': product_id,
                'forecast': forecast,
                'recommendations': recommendations,
                'summary': {
                    'total_recommendations': len(recommendations),
                    'high_priority_count': len([r for r in recommendations if r['priority'] == 'high']),
                    'risk_level': 'high' if forecast.get('stockout_risk', 0) > 0.3 else 'medium' if forecast.get('stockout_risk', 0) > 0.1 else 'low'
                }
            },
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
    Get AI-powered alert summary for critical issues
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
        
        return Response({
            'success': True,
            'data': {
                'total_alerts': len(alerts),
                'critical_alerts': len([a for a in alerts if a['severity'] == 'critical']),
                'high_alerts': len([a for a in alerts if a['severity'] == 'high']),
                'alerts': alerts,
                'last_updated': ai_agent.get_ai_insights().get('generated_at', '')
            },
            'message': 'Alert summary generated successfully'
        })
    except Exception as e:
        logger.error(f"Error in AI alert summary endpoint: {e}")
        return Response(
            {'error': 'Failed to generate alert summary'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
