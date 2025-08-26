import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AIService {
  // Rev21 Labs AI API Configuration
  static const String _rev21BaseUrl = 'https://ai-tools.rev21labs.com/api/v1';
  static const String _apiKey =
      'MTc0NTI4NTItYzNkYS00NmQ0LWI0MTktMDc2MmVhYjc2OWE3';

  // Backend API for database context
  static const String _backendBaseUrl = 'http://localhost:8000/api';

  // Session management
  static String? _sessionId;

  // Headers for Rev21 Labs API requests
  static Map<String, String> get _rev21Headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'x-api-key': _apiKey,
  };

  // Headers for backend API requests
  static Map<String, String> get _backendHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Initialize chat session with Rev21 Labs
  static Future<String> _initializeSession() async {
    if (_sessionId != null) return _sessionId!;

    try {
      debugPrint('🤖 AI Service: Initializing Rev21 Labs chat session...');
      final response = await http
          .get(Uri.parse('$_rev21BaseUrl/ai/session'), headers: _rev21Headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _sessionId = data['session_id'];
        debugPrint(
          '✅ AI Service: Rev21 Labs session initialized - $_sessionId',
        );
        return _sessionId!;
      } else {
        debugPrint(
          '❌ AI Service: Failed to initialize Rev21 Labs session - ${response.statusCode}',
        );
        throw Exception('Failed to initialize Rev21 Labs session');
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error initializing Rev21 Labs session - $e');
      throw Exception('Network error: $e');
    }
  }

  // Get database context from backend
  static Future<Map<String, dynamic>> _getDatabaseContext() async {
    try {
      debugPrint('🤖 AI Service: Getting database context from backend...');
      final response = await http
          .get(
            Uri.parse('$_backendBaseUrl/ai/database-context/'),
            headers: _backendHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ AI Service: Database context received');
        return data['data'];
      } else {
        debugPrint(
          '❌ AI Service: Failed to get database context - ${response.statusCode}',
        );
        return {}; // Return empty context if backend is unavailable
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error getting database context - $e');
      return {}; // Return empty context if backend is unavailable
    }
  }

  // Generate AI response using Rev21 Labs API with database context
  static Future<String> generateAIResponse(String userMessage) async {
    try {
      debugPrint('🤖 AI Service: Processing message with Rev21 Labs AI...');

      // Ensure Rev21 Labs session is initialized
      final sessionId = await _initializeSession();

      // Get database context from backend
      final dbContext = await _getDatabaseContext();

      // Prepare the enhanced message with database context
      String enhancedMessage = userMessage;
      if (dbContext.isNotEmpty) {
        enhancedMessage =
            '''
User Question: $userMessage

Current Pharmacy Database Context:
${json.encode(dbContext)}

           Instructions: You have access to the complete pharmacy inventory data including all products, quantities, prices, categories, and stock batches. When asked about specific products (like "dental floss"), search through the inventory_items array to find matching products. You can also access stock_batches data to provide detailed information about lot numbers, expiry dates, suppliers, and batch-specific quantities. 

           IMPORTANT: For casual greetings (hi, hello, hey, etc.), respond with a simple, friendly greeting and offer general pharmacy assistance. Do NOT provide unsolicited analytics or data analysis for casual conversations. Only provide detailed analytics when specifically asked for them. 

           IMPORTANT TRANSACTION DATA INTERPRETATION:
           - "OUT" transactions with negative quantities are SALES (products sold to customers)
           - "IN" transactions with positive quantities are PURCHASES (products received from suppliers)
           - For best-selling products, analyze "OUT" transactions and use the "absolute_quantity" field
           - For sales analysis, use "absolute_quantity" which shows positive sales numbers
           - Recent transactions show actual sales activity for determining best-sellers
           - Use "total_amount" for revenue analysis (ignore negative sign for sales)
           
           TOP SELLING PRODUCTS DATA:
           - Use "top_selling_products" array for ranking best-selling products
           - This data is pre-calculated and sorted by total sold quantity (highest first)
           - Each item contains: product_name, product_sku, total_sold_quantity, total_sold_value, transaction_count
           - For "top 5 best-selling products", use the first 5 items from this array

           Provide specific details about quantities, prices, stock status, categories, and batch information when relevant. If a product is not found, clearly state that it's not in the current inventory.

FORMATTING GUIDELINES:
1. Always display all monetary values using Philippine Peso (P) currency symbol. Never use \$ (US Dollar) symbol.
2. Use clean, readable formatting with proper spacing and line breaks.
3. For product listings, use this detailed bullet format:
   • Product Name
     - Price: PXX.XX
     - Quantity: XX
     - Stock Status: Low/Normal/Out
     - Total Value: PXX.XX
4. For rankings, use numbered lists with detailed bullets:
   1. Product Name
      - Price: PXX.XX
      - Quantity: XX
      - Total Value: PXX.XX
5. Use bullet points (•) for general lists and categories.
6. Avoid creating tables or complex formatting that might display poorly.
7. Use clear section headers with dashes or colons.
8. Keep responses concise but informative.
9. Use proper spacing between sections for better readability.
10. NEVER show internal processing notes like "updating order", "corrected", "note:", or any debugging information.
11. Provide clean, final answers without showing your thought process or corrections.
12. If you need to correct rankings, just present the final correct list without mentioning the correction process.

Examples:
• Dental Floss
  - Price: P3.99
  - Quantity: 179
  - Stock Status: Low
  - Total Value: P714.21
  - Stock Batches: 3 batches with lot numbers and expiry dates

• Product with Stock Batches:
  - Product: Ciprofloxacin 500 mg Tablet
  - Lot Number: CIPRO500-250419-679
  - Expiry Date: 2026-04-19
  - Quantity: 50 units
  - Supplier: PharmaCorp
  - Days to Expiry: 365 days

• Top 5 Products by Value:
  1. Product A
     - Price: P1,234.56
     - Quantity: 10
     - Total Value: P12,345.60
  2. Product B
     - Price: P987.65
     - Quantity: 15
     - Total Value: P14,814.75

• Stock Batch Information:
  - When asked about specific products, you can provide batch details including lot numbers, expiry dates, suppliers, and quantities
  - Use stock_batches data to show detailed inventory tracking information
  - Include expiry warnings for products expiring soon

  
• Ranking Guidelines:
  - For "best selling", rank by TOTAL sold quantity (sum of all OUT transactions)
  - #1 should be the product with the HIGHEST total sold quantity
  - If there are multiple products with the same total sold quantity, rank by total sold value (highest first)
  - Calculate total sold quantity by summing absolute_quantity from all OUT transactions for each product
  - Sort in descending order (highest to lowest)
  - Use format: "1. Product Name - Total Sold: X units - Revenue: PXXX.XX"
''';
      }

      // Prepare headers with session ID
      final headers = Map<String, String>.from(_rev21Headers);
      headers['session-id'] = sessionId;

      debugPrint('🔍 Sending enhanced message to Rev21 Labs AI...');
      final response = await http
          .post(
            Uri.parse('$_rev21BaseUrl/ai/chat'),
            headers: headers,
            body: json.encode({'content': enhancedMessage}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiResponse = data['content'];
        debugPrint('✅ AI Service: Rev21 Labs AI response received');
        return aiResponse;
      } else {
        debugPrint(
          '❌ AI Service: Rev21 Labs AI endpoint failed - ${response.statusCode}',
        );
        debugPrint('Response: ${response.body}');
        throw Exception('Failed to get AI response');
      }
    } catch (e) {
      debugPrint('❌ AI Service: Error in Rev21 Labs AI endpoint - $e');
      return "I'm having trouble connecting to the AI system right now. Please try again later or check your connection.";
    }
  }

  // Get chat history (not available with Rev21 Labs API, but keeping for compatibility)
  static Future<List<Map<String, dynamic>>> getChatHistory() async {
    debugPrint('🤖 AI Service: Chat history not available with Rev21 Labs API');
    return [];
  }

  // Clear chat history (reset session)
  static Future<void> clearChatHistory() async {
    try {
      debugPrint('🤖 AI Service: Clearing Rev21 Labs chat session...');
      _sessionId = null; // Reset session
      debugPrint('✅ AI Service: Rev21 Labs session cleared');
    } catch (e) {
      debugPrint('❌ AI Service: Error clearing Rev21 Labs session - $e');
      throw Exception('Network error: $e');
    }
  }

  // Note: This hybrid approach uses Rev21 Labs for conversational AI
  // while leveraging your backend database for real-time pharmacy data
}
