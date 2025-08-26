from datetime import timedelta
from django.db.models import Sum, Count, F
from django.utils import timezone
from .models import Product, Inventory, Transaction, Category
import random


class PharmacyAIChat:
    def __init__(self):
        self.conversation_history = []
    
    def process_message(self, user_message):
        user_message = user_message.lower().strip()
        
        # Add to conversation history
        self.conversation_history.append({
            'user': user_message,
            'timestamp': timezone.now()
        })
        
        # Analyze intent
        intent = self._analyze_intent(user_message)
        
        # Generate response
        response = self._generate_response(intent)
        
        # Add response to history
        self.conversation_history.append({
            'ai': response['message'],
            'timestamp': timezone.now()
        })
        
        return response
    
    def _analyze_intent(self, message):
        if any(word in message for word in ['stock', 'inventory', 'quantity', 'low']):
            return 'inventory_query'
        elif any(word in message for word in ['sales', 'revenue', 'transactions']):
            return 'sales_analysis'
        elif any(word in message for word in ['product', 'medicine', 'drug']):
            return 'product_info'
        elif any(word in message for word in ['health', 'status', 'system']):
            return 'system_health'
        elif any(word in message for word in ['help', 'what can you do']):
            return 'help'
        elif any(word in message for word in ['hello', 'hi', 'hey']):
            return 'greeting'
        else:
            return 'general_query'
    
    def _generate_response(self, intent):
        try:
            if intent == 'greeting':
                return self._generate_greeting()
            elif intent == 'help':
                return self._generate_help_response()
            elif intent == 'inventory_query':
                return self._generate_inventory_response()
            elif intent == 'sales_analysis':
                return self._generate_sales_response()
            elif intent == 'product_info':
                return self._generate_product_response()
            elif intent == 'system_health':
                return self._generate_health_response()
            else:
                return self._generate_general_response()
        except Exception as e:
            return {
                'message': "I'm having trouble processing that request. Could you please rephrase it?",
                'type': 'error'
            }
    
    def _generate_greeting(self):
        total_products = Product.objects.count()
        low_stock_count = Inventory.objects.filter(quantity__lte=F('product__reorder_level')).count()
        
        greeting = f"Hello! I'm your AI pharmacy assistant. You have {total_products} products in your system"
        if low_stock_count > 0:
            greeting += f" with {low_stock_count} items that need reordering."
        else:
            greeting += " and all stock levels are healthy."
        greeting += " How can I assist you today?"
        
        return {
            'message': greeting,
            'type': 'greeting'
        }
    
    def _generate_help_response(self):
        help_text = "I'm your intelligent pharmacy assistant! I can help you with inventory management, sales analysis, product information, and system health monitoring. Just ask me about stock levels, sales trends, or any pharmacy operations!"
        
        return {
            'message': help_text,
            'type': 'help'
        }
    
    def _generate_inventory_response(self):
        total_products = Product.objects.count()
        low_stock_products = Inventory.objects.filter(quantity__lte=F('product__reorder_level')).count()
        out_of_stock_products = Inventory.objects.filter(quantity=0).count()
        total_inventory_value = sum(inv.total_value for inv in Inventory.objects.all())
        
        low_stock_items = Inventory.objects.filter(
            quantity__lte=F('product__reorder_level')
        ).select_related('product').order_by('quantity')[:5]
        
        message = f"Inventory Status Overview:\n"
        message += f"Total Products: {total_products}\n"
        message += f"Low Stock Items: {low_stock_products}\n"
        message += f"Out of Stock: {out_of_stock_products}\n"
        message += f"Total Inventory Value: ${total_inventory_value:,.2f}\n\n"
        
        if low_stock_items:
            message += "Items Needing Attention:\n"
            for item in low_stock_items:
                message += f"- {item.product.name}: {item.quantity} units (Reorder: {item.product.reorder_level})\n"
        
        return {
            'message': message,
            'type': 'inventory_status'
        }
    
    def _generate_sales_response(self):
        thirty_days_ago = timezone.now() - timedelta(days=30)
        transactions = Transaction.objects.filter(
            created_at__gte=thirty_days_ago,
            transaction_type='OUT'
        )
        
        total_sales = transactions.count()
        total_revenue = sum(t.quantity * t.unit_price for t in transactions if t.unit_price)
        total_quantity_sold = sum(abs(t.quantity) for t in transactions)
        
        top_products = transactions.values('product__name').annotate(
            total_quantity=Sum('quantity'),
            total_revenue=Sum(F('quantity') * F('unit_price'))
        ).order_by('-total_quantity')[:5]
        
        message = f"Sales Analysis (Last 30 days):\n"
        message += f"Total Sales Transactions: {total_sales}\n"
        message += f"Total Revenue: ${total_revenue:,.2f}\n"
        message += f"Total Units Sold: {total_quantity_sold}\n"
        message += f"Average Daily Sales: ${total_revenue/30:,.2f}\n\n"
        
        if top_products:
            message += "Top Selling Products:\n"
            for i, product in enumerate(top_products, 1):
                message += f"{i}. {product['product__name']}: {abs(product['total_quantity'])} units (${product['total_revenue']:,.2f})\n"
        
        return {
            'message': message,
            'type': 'sales_analysis'
        }
    
    def _generate_product_response(self):
        total_products = Product.objects.count()
        categories = Category.objects.annotate(product_count=Count('products'))
        
        message = f"Product Overview:\n"
        message += f"Total Products: {total_products}\n"
        message += f"Categories: {categories.count()}\n\n"
        
        message += "Products by Category:\n"
        for category in categories:
            message += f"- {category.name}: {category.product_count} products\n"
        
        sample_products = Product.objects.select_related('category').order_by('?')[:5]
        message += f"\nSample Products:\n"
        for product in sample_products:
            message += f"- {product.name} ({product.category.name}) - ${product.unit_price}\n"
        
        return {
            'message': message,
            'type': 'product_overview'
        }
    
    def _generate_health_response(self):
        total_products = Product.objects.count()
        low_stock_count = Inventory.objects.filter(quantity__lte=F('product__reorder_level')).count()
        out_of_stock_count = Inventory.objects.filter(quantity=0).count()
        
        if total_products > 0:
            health_score = max(0, 100 - (low_stock_count / total_products * 50) - (out_of_stock_count / total_products * 30))
        else:
            health_score = 100
        
        if health_score >= 80:
            status = "Excellent"
        elif health_score >= 60:
            status = "Good"
        else:
            status = "Needs Attention"
        
        message = f"System Health Status:\n"
        message += f"Overall Health: {status} ({health_score:.1f}%)\n"
        message += f"Total Products: {total_products}\n"
        message += f"Low Stock Items: {low_stock_count}\n"
        message += f"Out of Stock: {out_of_stock_count}\n\n"
        
        if low_stock_count > 0:
            message += f"Actions Needed: Review and reorder {low_stock_count} low stock items\n"
        
        if out_of_stock_count > 0:
            message += f"Restock {out_of_stock_count} out-of-stock items\n"
        
        if low_stock_count == 0 and out_of_stock_count == 0:
            message += f"System Status: All stock levels are healthy!\n"
        
        return {
            'message': message,
            'type': 'system_health'
        }
    
    def _generate_general_response(self):
        responses = [
            "I'm here to help with your pharmacy management! Try asking about inventory, sales, products, or system health.",
            "I can help you with inventory tracking, sales analysis, product information, and business insights. What would you like to know?",
            "I'm your AI pharmacy assistant. I can analyze your data, provide insights, and help with inventory management. How can I assist you?",
            "I'm here to help optimize your pharmacy operations! Ask me about stock levels, sales trends, or product recommendations."
        ]
        
        return {
            'message': random.choice(responses),
            'type': 'general'
        }
    
    def get_conversation_history(self):
        return self.conversation_history
    
    def clear_history(self):
        self.conversation_history = []
