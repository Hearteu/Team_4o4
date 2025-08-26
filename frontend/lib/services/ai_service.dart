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

Please provide a response based on the user's question and the current pharmacy data above. Focus on giving specific, actionable insights based on the real data provided.
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
