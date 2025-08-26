import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from django.db.models import Sum, Count, Avg, Q, F
from django.utils import timezone
from .models import Product, Inventory, Transaction, Category, Supplier
import json
import random
from typing import Dict, List, Tuple, Optional
import logging

logger = logging.getLogger(__name__)

class PharmacyAIAgent:
    """
    AI Agent for Pharmacy Management System
    Provides intelligent insights, forecasting, and recommendations
    """
    
    def __init__(self):
        self.forecast_horizon = 30  # days
        self.confidence_level = 0.95
        
    def get_system_health_score(self) -> Dict:
        """
        Calculate overall system health score based on multiple factors
        """
        try:
            # Get basic metrics
            total_products = Product.objects.count()
            low_stock_products = 0
            out_of_stock_products = 0
            
            # Check each product's inventory
            for product in Product.objects.all():
                try:
                    inventory = product.inventory
                    if inventory.quantity <= product.reorder_level:
                        low_stock_products += 1
                    if inventory.quantity == 0:
                        out_of_stock_products += 1
                except Inventory.DoesNotExist:
                    out_of_stock_products += 1  # No inventory record means out of stock
            
            # Calculate health score (0-100)
            stock_health = max(0, 100 - (low_stock_products / total_products * 100)) if total_products > 0 else 100
            availability_health = max(0, 100 - (out_of_stock_products / total_products * 100)) if total_products > 0 else 100
            
            # Get recent transaction activity
            recent_transactions = Transaction.objects.filter(
                created_at__gte=timezone.now() - timedelta(days=7)
            ).count()
            activity_health = min(100, recent_transactions * 10)  # Scale based on activity
            
            overall_health = (stock_health * 0.4 + availability_health * 0.4 + activity_health * 0.2)
            
            return {
                'overall_score': round(overall_health, 1),
                'stock_health': round(stock_health, 1),
                'availability_health': round(availability_health, 1),
                'activity_health': round(activity_health, 1),
                'total_products': total_products,
                'low_stock_count': low_stock_products,
                'out_of_stock_count': out_of_stock_products,
                'recent_activity': recent_transactions,
                'status': self._get_health_status(overall_health)
            }
        except Exception as e:
            logger.error(f"Error calculating system health: {e}")
            return {'error': str(e)}
    
    def _get_health_status(self, score: float) -> str:
        """Get health status based on score"""
        if score >= 90:
            return "Excellent"
        elif score >= 75:
            return "Good"
        elif score >= 60:
            return "Fair"
        else:
            return "Needs Attention"
    
    def forecast_demand(self, product_id: int = None, days: int = 30) -> Dict:
        """
        Forecast product demand using historical transaction data
        """
        try:
            if product_id:
                # Forecast for specific product
                return self._forecast_single_product(product_id, days)
            else:
                # Forecast for all products
                return self._forecast_all_products(days)
        except Exception as e:
            logger.error(f"Error in demand forecasting: {e}")
            return {'error': str(e)}
    
    def _forecast_single_product(self, product_id: int, days: int) -> Dict:
        """Forecast demand for a single product"""
        try:
            # Get historical transaction data
            transactions = Transaction.objects.filter(
                product=product_id,
                transaction_type='OUT',
                created_at__gte=timezone.now() - timedelta(days=90)
            ).order_by('created_at')
            
            if not transactions.exists():
                return {'error': 'Insufficient historical data for forecasting'}
            
            # Calculate daily demand
            daily_demand = {}
            for transaction in transactions:
                date = transaction.created_at.date()
                daily_demand[date] = daily_demand.get(date, 0) + transaction.quantity
            
            # Calculate average daily demand
            avg_daily_demand = sum(daily_demand.values()) / len(daily_demand)
            
            # Calculate demand variability
            demand_values = list(daily_demand.values())
            demand_std = np.std(demand_values) if len(demand_values) > 1 else 0
            
            # Generate forecast
            forecast_demand = avg_daily_demand * days
            confidence_interval = demand_std * np.sqrt(days) * 1.96  # 95% confidence
            
            # Get current stock
            current_stock = Inventory.objects.filter(product=product_id).first()
            current_quantity = current_stock.quantity if current_stock else 0
            
            # Calculate stockout risk
            stockout_risk = self._calculate_stockout_risk(
                current_quantity, forecast_demand, demand_std, days
            )
            
            return {
                'product_id': product_id,
                'forecast_period_days': days,
                'forecasted_demand': round(forecast_demand, 2),
                'confidence_interval': round(confidence_interval, 2),
                'avg_daily_demand': round(avg_daily_demand, 2),
                'demand_volatility': round(demand_std, 2),
                'current_stock': current_quantity,
                'stockout_risk': round(stockout_risk, 2),
                'recommended_reorder_quantity': max(0, round(forecast_demand - current_quantity, 2)),
                'confidence_level': '95%'
            }
        except Exception as e:
            logger.error(f"Error forecasting single product: {e}")
            return {'error': str(e)}
    
    def _forecast_all_products(self, days: int) -> Dict:
        """Forecast demand for all products"""
        try:
            products = Product.objects.all()
            forecasts = {}
            
            for product in products:
                forecast = self._forecast_single_product(product.id, days)
                if 'error' not in forecast:
                    forecasts[product.id] = {
                        'product_name': product.name,
                        'sku': product.sku,
                        **forecast
                    }
            
            return {
                'forecast_period_days': days,
                'total_products_forecasted': len(forecasts),
                'forecasts': forecasts,
                'summary': self._generate_forecast_summary(forecasts)
            }
        except Exception as e:
            logger.error(f"Error forecasting all products: {e}")
            return {'error': str(e)}
    
    def _calculate_stockout_risk(self, current_stock: int, forecast_demand: float, 
                                demand_std: float, days: int) -> float:
        """Calculate probability of stockout"""
        if demand_std == 0:
            return 1.0 if current_stock < forecast_demand else 0.0
        
        # Using normal distribution approximation
        z_score = (current_stock - forecast_demand) / (demand_std * np.sqrt(days))
        from scipy.stats import norm
        stockout_probability = 1 - norm.cdf(z_score)
        return stockout_probability
    
    def _generate_forecast_summary(self, forecasts: Dict) -> Dict:
        """Generate summary statistics for all forecasts"""
        if not forecasts:
            return {}
        
        total_forecasted_demand = sum(f['forecasted_demand'] for f in forecasts.values())
        avg_stockout_risk = np.mean([f['stockout_risk'] for f in forecasts.values()])
        high_risk_products = len([f for f in forecasts.values() if f['stockout_risk'] > 0.3])
        
        return {
            'total_forecasted_demand': round(total_forecasted_demand, 2),
            'average_stockout_risk': round(avg_stockout_risk, 3),
            'high_risk_products': high_risk_products,
            'recommendations': self._generate_forecast_recommendations(forecasts)
        }
    
    def _generate_forecast_recommendations(self, forecasts: Dict) -> List[str]:
        """Generate recommendations based on forecasts"""
        recommendations = []
        
        high_risk_products = [f for f in forecasts.values() if f['stockout_risk'] > 0.3]
        if high_risk_products:
            recommendations.append(f"Consider reordering {len(high_risk_products)} high-risk products")
        
        low_stock_products = [f for f in forecasts.values() if f['current_stock'] < f['avg_daily_demand'] * 7]
        if low_stock_products:
            recommendations.append(f"Monitor {len(low_stock_products)} products with less than 1 week of stock")
        
        return recommendations
    
    def optimize_inventory(self) -> Dict:
        """
        Provide inventory optimization recommendations
        """
        try:
            products = Product.objects.all()
            optimization_data = []
            
            for product in products:
                inventory = Inventory.objects.filter(product=product).first()
                if not inventory:
                    continue
                
                # Get demand forecast
                forecast = self._forecast_single_product(product.id, 30)
                if 'error' in forecast:
                    continue
                
                # Calculate optimal stock levels
                optimal_stock = self._calculate_optimal_stock(
                    forecast['avg_daily_demand'],
                    forecast['demand_volatility'],
                    product.reorder_level
                )
                
                # Calculate holding cost
                holding_cost = self._calculate_holding_cost(
                    inventory.quantity,
                    product.unit_price
                )
                
                optimization_data.append({
                    'product_id': product.id,
                    'product_name': product.name,
                    'sku': product.sku,
                    'current_stock': inventory.quantity,
                    'optimal_stock': round(optimal_stock, 2),
                    'reorder_level': product.reorder_level,
                    'holding_cost': round(holding_cost, 2),
                    'stockout_risk': forecast.get('stockout_risk', 0),
                    'recommendation': self._get_stock_recommendation(
                        inventory.quantity, optimal_stock, product.reorder_level
                    )
                })
            
            return {
                'total_products_analyzed': len(optimization_data),
                'optimization_data': optimization_data,
                'summary': self._generate_optimization_summary(optimization_data)
            }
        except Exception as e:
            logger.error(f"Error in inventory optimization: {e}")
            return {'error': str(e)}
    
    def _calculate_optimal_stock(self, avg_demand: float, demand_std: float, 
                                reorder_level: int) -> float:
        """Calculate optimal stock level using safety stock formula"""
        # Safety stock = Z * σ * √(lead_time)
        # Assuming 7 days lead time
        lead_time = 7
        safety_stock = 1.96 * demand_std * np.sqrt(lead_time)  # 95% service level
        cycle_stock = avg_demand * lead_time / 2
        optimal_stock = safety_stock + cycle_stock
        return max(optimal_stock, reorder_level)
    
    def _calculate_holding_cost(self, quantity: int, unit_price) -> float:
        """Calculate annual holding cost (assuming 20% annual holding cost rate)"""
        annual_rate = 0.20
        # Convert Decimal to float if needed
        unit_price_float = float(unit_price)
        return quantity * unit_price_float * annual_rate / 365  # Daily holding cost
    
    def _get_stock_recommendation(self, current_stock: int, optimal_stock: float, 
                                 reorder_level: int) -> str:
        """Get stock level recommendation"""
        if current_stock <= reorder_level:
            return "URGENT: Reorder immediately"
        elif current_stock < optimal_stock * 0.8:
            return "Consider reordering soon"
        elif current_stock > optimal_stock * 1.5:
            return "Stock level is high - consider reducing orders"
        else:
            return "Stock level is optimal"
    
    def _generate_optimization_summary(self, optimization_data: List[Dict]) -> Dict:
        """Generate optimization summary"""
        urgent_reorders = len([d for d in optimization_data if 'URGENT' in d['recommendation']])
        high_holding_costs = len([d for d in optimization_data if d['holding_cost'] > 10])
        total_holding_cost = sum(d['holding_cost'] for d in optimization_data)
        
        return {
            'urgent_reorders_needed': urgent_reorders,
            'high_holding_cost_products': high_holding_costs,
            'total_daily_holding_cost': round(total_holding_cost, 2),
            'potential_savings': round(total_holding_cost * 0.2, 2)  # 20% potential savings
        }
    
    def predict_sales_trends(self, days: int = 30) -> Dict:
        """
        Predict sales trends and patterns
        """
        try:
            # Get historical sales data
            end_date = timezone.now()
            start_date = end_date - timedelta(days=days * 2)  # Get more data for analysis
            
            transactions = Transaction.objects.filter(
                transaction_type='OUT',
                created_at__gte=start_date,
                created_at__lte=end_date
            ).order_by('created_at')
            
            if not transactions.exists():
                return {'error': 'Insufficient sales data for trend analysis'}
            
            # Group by date and calculate daily sales
            daily_sales = {}
            for transaction in transactions:
                date = transaction.created_at.date()
                # Calculate total amount for this transaction
                total_amount = float(transaction.quantity * transaction.unit_price) if transaction.unit_price else 0
                daily_sales[date] = daily_sales.get(date, 0) + total_amount
            
            # Calculate trend
            dates = sorted(daily_sales.keys())
            sales_values = [daily_sales[date] for date in dates]
            
            if len(sales_values) < 2:
                return {'error': 'Insufficient data points for trend analysis'}
            
            # Simple linear trend
            x = np.arange(len(sales_values))
            trend_coefficient = np.polyfit(x, sales_values, 1)[0]
            
            # Calculate growth rate
            if sales_values[0] > 0:
                growth_rate = ((sales_values[-1] - sales_values[0]) / sales_values[0]) * 100
            else:
                growth_rate = 0
            
            # Predict future sales
            future_days = np.arange(len(sales_values), len(sales_values) + days)
            predicted_sales = np.polyval(np.polyfit(x, sales_values, 1), future_days)
            
            # Calculate seasonality (day of week patterns)
            day_of_week_sales = self._calculate_day_of_week_pattern(transactions)
            
            return {
                'analysis_period_days': days,
                'trend_direction': 'increasing' if trend_coefficient > 0 else 'decreasing',
                'trend_strength': abs(trend_coefficient),
                'growth_rate_percent': round(growth_rate, 2),
                'average_daily_sales': round(np.mean(sales_values), 2),
                'sales_volatility': round(np.std(sales_values), 2),
                'predicted_sales_next_period': round(sum(predicted_sales), 2),
                'day_of_week_pattern': day_of_week_sales,
                'recommendations': self._generate_sales_recommendations(
                    trend_coefficient, growth_rate, day_of_week_sales
                )
            }
        except Exception as e:
            logger.error(f"Error in sales trend prediction: {e}")
            return {'error': str(e)}
    
    def _calculate_day_of_week_pattern(self, transactions) -> Dict:
        """Calculate sales patterns by day of week"""
        day_sales = {i: 0 for i in range(7)}
        day_counts = {i: 0 for i in range(7)}
        
        for transaction in transactions:
            day = transaction.created_at.weekday()
            # Calculate total amount for this transaction
            total_amount = float(transaction.quantity * transaction.unit_price) if transaction.unit_price else 0
            day_sales[day] += total_amount
            day_counts[day] += 1
        
        day_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        pattern = {}
        
        for i, day_name in enumerate(day_names):
            avg_sales = day_sales[i] / day_counts[i] if day_counts[i] > 0 else 0
            pattern[day_name] = round(avg_sales, 2)
        
        return pattern
    
    def _generate_sales_recommendations(self, trend_coefficient: float, 
                                      growth_rate: float, day_pattern: Dict) -> List[str]:
        """Generate sales recommendations"""
        recommendations = []
        
        if trend_coefficient > 0:
            recommendations.append("Sales are trending upward - consider increasing inventory")
        else:
            recommendations.append("Sales are declining - review pricing and marketing strategies")
        
        if growth_rate > 10:
            recommendations.append("Strong growth detected - plan for capacity expansion")
        elif growth_rate < -5:
            recommendations.append("Declining sales - investigate causes and adjust strategy")
        
        # Find peak sales day
        peak_day = max(day_pattern, key=day_pattern.get)
        recommendations.append(f"Peak sales day is {peak_day} - ensure adequate staffing")
        
        return recommendations
    
    def get_ai_insights(self) -> Dict:
        """
        Get comprehensive AI insights for the pharmacy
        """
        try:
            insights = {
                'system_health': self.get_system_health_score(),
                'demand_forecast': self.forecast_demand(days=30),
                'inventory_optimization': self.optimize_inventory(),
                'sales_trends': self.predict_sales_trends(days=30),
                'generated_at': timezone.now().isoformat(),
                'ai_version': '1.0.0'
            }
            
            # Add executive summary
            insights['executive_summary'] = self._generate_executive_summary(insights)
            
            return insights
        except Exception as e:
            logger.error(f"Error generating AI insights: {e}")
            return {'error': str(e)}
    
    def _generate_executive_summary(self, insights: Dict) -> Dict:
        """Generate executive summary of all insights"""
        try:
            health = insights.get('system_health', {})
            forecast = insights.get('demand_forecast', {})
            optimization = insights.get('inventory_optimization', {})
            trends = insights.get('sales_trends', {})
            
            summary = {
                'key_metrics': {
                    'system_health_score': health.get('overall_score', 0),
                    'total_products': health.get('total_products', 0),
                    'low_stock_items': health.get('low_stock_count', 0),
                    'urgent_reorders': optimization.get('summary', {}).get('urgent_reorders_needed', 0)
                },
                'critical_alerts': [],
                'recommendations': [],
                'opportunities': []
            }
            
            # Generate alerts
            if health.get('overall_score', 100) < 70:
                summary['critical_alerts'].append("System health needs immediate attention")
            
            if health.get('low_stock_count', 0) > 5:
                summary['critical_alerts'].append(f"{health['low_stock_count']} products are low on stock")
            
            # Generate recommendations
            if optimization.get('summary', {}).get('urgent_reorders_needed', 0) > 0:
                summary['recommendations'].append("Place urgent reorders for critical products")
            
            if trends.get('trend_direction') == 'increasing':
                summary['opportunities'].append("Sales are growing - consider expanding inventory")
            
            return summary
        except Exception as e:
            logger.error(f"Error generating executive summary: {e}")
            return {'error': str(e)}
