import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AIService {
  static const String baseUrl = 'http://localhost:8000/api/ai'; // Web localhost

  // Headers for API requests
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get system health
  static Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      debugPrint('🤖 AI Service: Getting system health...');
      final response = await http.get(
        Uri.parse('$baseUrl/system-health/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ AI Service: System health received');
        return data['data'];
      } else {
        debugPrint(
          '❌ AI Service: Failed to get system health - ${response.statusCode}',
        );
        throw Exception('Failed to get system health');
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error getting system health - $e');
      throw Exception('Network error: $e');
    }
  }

  // Get demand forecast
  static Future<Map<String, dynamic>> getDemandForecast({
    int? productId,
    int days = 30,
  }) async {
    try {
      debugPrint('🤖 AI Service: Getting demand forecast...');
      String url = '$baseUrl/demand-forecast/?days=$days';
      if (productId != null) {
        url += '&product_id=$productId';
      }

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ AI Service: Demand forecast received');
        return data['data'];
      } else {
        debugPrint(
          '❌ AI Service: Failed to get demand forecast - ${response.statusCode}',
        );
        throw Exception('Failed to get demand forecast');
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error getting demand forecast - $e');
      throw Exception('Network error: $e');
    }
  }

  // Get inventory optimization
  static Future<Map<String, dynamic>> getInventoryOptimization() async {
    try {
      debugPrint('🤖 AI Service: Getting inventory optimization...');
      final response = await http.get(
        Uri.parse('$baseUrl/inventory-optimization/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ AI Service: Inventory optimization received');
        return data['data'];
      } else {
        debugPrint(
          '❌ AI Service: Failed to get inventory optimization - ${response.statusCode}',
        );
        throw Exception('Failed to get inventory optimization');
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error getting inventory optimization - $e');
      throw Exception('Network error: $e');
    }
  }

  // Get sales trends
  static Future<Map<String, dynamic>> getSalesTrends({int days = 30}) async {
    try {
      debugPrint('🤖 AI Service: Getting sales trends...');
      final response = await http.get(
        Uri.parse('$baseUrl/sales-trends/?days=$days'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ AI Service: Sales trends received');
        return data['data'];
      } else {
        debugPrint(
          '❌ AI Service: Failed to get sales trends - ${response.statusCode}',
        );
        throw Exception('Failed to get sales trends');
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error getting sales trends - $e');
      throw Exception('Network error: $e');
    }
  }

  // Get comprehensive insights
  static Future<Map<String, dynamic>> getComprehensiveInsights() async {
    try {
      debugPrint('🤖 AI Service: Getting comprehensive insights...');
      final response = await http.get(
        Uri.parse('$baseUrl/comprehensive-insights/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ AI Service: Comprehensive insights received');
        return data['data'];
      } else {
        debugPrint(
          '❌ AI Service: Failed to get comprehensive insights - ${response.statusCode}',
        );
        throw Exception('Failed to get comprehensive insights');
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error getting comprehensive insights - $e');
      throw Exception('Network error: $e');
    }
  }

  // Get alert summary
  static Future<Map<String, dynamic>> getAlertSummary() async {
    try {
      debugPrint('🤖 AI Service: Getting alert summary...');
      final response = await http.get(
        Uri.parse('$baseUrl/alert-summary/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ AI Service: Alert summary received');
        return data['data'];
      } else {
        debugPrint(
          '❌ AI Service: Failed to get alert summary - ${response.statusCode}',
        );
        throw Exception('Failed to get alert summary');
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error getting alert summary - $e');
      throw Exception('Network error: $e');
    }
  }

  // Get product recommendations
  static Future<Map<String, dynamic>> getProductRecommendations(
    int productId,
  ) async {
    try {
      debugPrint(
        '🤖 AI Service: Getting product recommendations for product $productId...',
      );
      final response = await http.get(
        Uri.parse('$baseUrl/product-recommendations/$productId/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ AI Service: Product recommendations received');
        return data['data'];
      } else {
        debugPrint(
          '❌ AI Service: Failed to get product recommendations - ${response.statusCode}',
        );
        throw Exception('Failed to get product recommendations');
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error getting product recommendations - $e');
      throw Exception('Network error: $e');
    }
  }

  // Generate AI response based on user message
  static Future<String> generateAIResponse(String userMessage) async {
    try {
      final message = userMessage.toLowerCase();

      // Check for specific AI queries
      if (message.contains('health') || message.contains('status')) {
        final health = await getSystemHealth();
        return "Your pharmacy system health score is ${health['overall_score']} (${health['status']}). "
            "You have ${health['total_products']} products, ${health['low_stock_count']} low stock items, "
            "and ${health['out_of_stock_count']} out of stock items.";
      }

      if (message.contains('forecast') || message.contains('demand')) {
        final forecast = await getDemandForecast();
        return "Based on AI analysis, your total forecasted demand for the next 30 days is ${forecast['summary']['total_forecasted_demand']} units. "
            "You have ${forecast['summary']['high_risk_products']} high-risk products that need attention.";
      }

      if (message.contains('optimization') || message.contains('inventory')) {
        final optimization = await getInventoryOptimization();
        return "AI optimization analysis shows ${optimization['summary']['urgent_reorders_needed']} products need urgent reordering. "
            "Potential daily savings: \$${optimization['summary']['potential_savings']}.";
      }

      if (message.contains('alerts') || message.contains('issues')) {
        final alerts = await getAlertSummary();
        return "You have ${alerts['total_alerts']} active alerts: ${alerts['critical_alerts']} critical and ${alerts['high_alerts']} high priority. "
            "Please review the alerts section for details.";
      }

      if (message.contains('sales') || message.contains('trends')) {
        try {
          final trends = await getSalesTrends();
          return "Sales trend analysis shows ${trends['trend_direction']} trend with ${trends['growth_rate_percent']}% growth rate. "
              "Average daily sales: \$${trends['average_daily_sales']}.";
        } catch (e) {
          return "I can help you analyze sales trends and patterns. Would you like to see specific sales data?";
        }
      }

      // Default responses for general queries
      if (message.contains('stock') || message.contains('inventory')) {
        return "I can help you with inventory management! I can show you low stock items, demand forecasts, and optimization recommendations. What specific information do you need?";
      } else if (message.contains('reorder') || message.contains('order')) {
        return "I can help you with reordering! I analyze current stock levels, demand forecasts, and supplier information to recommend optimal reorder quantities and timing.";
      } else if (message.contains('help') ||
          message.contains('what can you do')) {
        return "I'm your AI pharmacy assistant! I can help with:\n• Inventory management and stock monitoring\n• Demand forecasting and predictions\n• Sales analysis and trends\n• Reorder recommendations\n• System health monitoring\n• Cost optimization\n\nJust ask me anything about your pharmacy operations!";
      } else {
        return "I'm here to help with your pharmacy management! I can assist with inventory, forecasting, sales analysis, and more. What would you like to know about?";
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error generating response - $e');
      return "I'm having trouble connecting to the AI system right now. Please try again later or check your connection.";
    }
  }
}
