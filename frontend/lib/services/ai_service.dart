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

  // Note: All AI functionality is now handled through the chat endpoint
  // Use generateAIResponse() for all AI interactions

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

  // Generate AI response based on user message using the new chat endpoint
  static Future<String> generateAIResponse(String userMessage) async {
    try {
      debugPrint(
        '🤖 AI Service: Sending message to chat endpoint: $userMessage',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/chat/'),
        headers: _headers,
        body: json.encode({'message': userMessage}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiResponse = data['data']['message'];
        debugPrint('✅ AI Service: Chat response received');
        return aiResponse;
      } else {
        debugPrint(
          '❌ AI Service: Chat endpoint failed - ${response.statusCode}',
        );
        throw Exception('Failed to get chat response');
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error in chat endpoint - $e');
      return "I'm having trouble connecting to the AI system right now. Please try again later or check your connection.";
    }
  }

  // Get chat history
  static Future<List<Map<String, dynamic>>> getChatHistory() async {
    try {
      debugPrint('🤖 AI Service: Getting chat history...');
      final response = await http.get(
        Uri.parse('$baseUrl/chat/history/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ AI Service: Chat history received');
        return List<Map<String, dynamic>>.from(data['data']['history']);
      } else {
        debugPrint(
          '❌ AI Service: Failed to get chat history - ${response.statusCode}',
        );
        throw Exception('Failed to get chat history');
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error getting chat history - $e');
      throw Exception('Network error: $e');
    }
  }

  // Clear chat history
  static Future<void> clearChatHistory() async {
    try {
      debugPrint('🤖 AI Service: Clearing chat history...');
      final response = await http.post(
        Uri.parse('$baseUrl/chat/clear/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ AI Service: Chat history cleared');
      } else {
        debugPrint(
          '❌ AI Service: Failed to clear chat history - ${response.statusCode}',
        );
        throw Exception('Failed to clear chat history');
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error clearing chat history - $e');
      throw Exception('Network error: $e');
    }
  }
}
