import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';
import '../screens/dashboard_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/products_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/dynamic_data_screen.dart'; // Added import for DynamicDataScreen

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isTyping = false;
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Add welcome message
    _messages.add(
      ChatMessage(
        text:
            "Hello! I'm your AI pharmacy assistant. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });
    _messageController.clear();

    // Simulate AI response
    _simulateAIResponse(userMessage);
  }

  void _simulateAIResponse(String userMessage) async {
    try {
      final response = await AIService.generateAIResponse(userMessage);
      final dataContext = _detectDataContext(response, userMessage);

      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
            dataContext: dataContext,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text:
                "I'm having trouble connecting to the AI system right now. Please try again later.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  // Detect what type of data is referenced in the AI response
  Map<String, dynamic>? _detectDataContext(
    String aiResponse,
    String userMessage,
  ) {
    final response = aiResponse.toLowerCase();
    final userQuery = userMessage.toLowerCase();

    // Check for specific product queries first
    if (userQuery.contains('dental floss') ||
        response.contains('dental floss') ||
        userQuery.contains('toothpaste') ||
        response.contains('toothpaste') ||
        userQuery.contains('vitamin') ||
        response.contains('vitamin') ||
        userQuery.contains('medicine') ||
        response.contains('medicine') ||
        userQuery.contains('drug') ||
        response.contains('drug') ||
        userQuery.contains('supplement') ||
        response.contains('supplement')) {
      return {
        'type': 'inventory',
        'title': 'View Product Details',
        'description': 'Specific product information and stock levels',
      };
    }

    // Check for inventory-related queries
    if (response.contains('inventory') ||
        response.contains('stock') ||
        response.contains('quantity') ||
        response.contains('items') ||
        userQuery.contains('inventory') ||
        userQuery.contains('stock') ||
        userQuery.contains('quantity') ||
        userQuery.contains('items')) {
      return {
        'type': 'inventory',
        'title': 'View Inventory Data',
        'description': 'Current stock levels and inventory status',
      };
    }

    // Check for product-related queries
    if (response.contains('product') ||
        response.contains('products') ||
        response.contains('catalog') ||
        response.contains('items') ||
        userQuery.contains('product') ||
        userQuery.contains('products') ||
        userQuery.contains('catalog')) {
      return {
        'type': 'products',
        'title': 'View Product Catalog',
        'description': 'Complete product information and details',
      };
    }

    // Check for transaction-related queries
    if (response.contains('transaction') ||
        response.contains('transactions') ||
        response.contains('sales') ||
        response.contains('purchase') ||
        response.contains('recent') ||
        response.contains('history') ||
        userQuery.contains('transaction') ||
        userQuery.contains('transactions') ||
        userQuery.contains('sales') ||
        userQuery.contains('purchase') ||
        userQuery.contains('recent') ||
        userQuery.contains('history')) {
      return {
        'type': 'transactions',
        'title': 'View Transaction History',
        'description': 'Recent sales and purchase transactions',
      };
    }

    // Check for financial/summary queries
    if (response.contains('total') ||
        response.contains('value') ||
        response.contains('worth') ||
        response.contains('summary') ||
        response.contains('overview') ||
        response.contains('dashboard') ||
        userQuery.contains('total') ||
        userQuery.contains('value') ||
        userQuery.contains('worth') ||
        userQuery.contains('summary') ||
        userQuery.contains('overview') ||
        userQuery.contains('dashboard')) {
      return {
        'type': 'dashboard',
        'title': 'View Dashboard Summary',
        'description': 'Complete overview of pharmacy data',
      };
    }

    // Check for low stock alerts
    if (response.contains('low stock') ||
        response.contains('reorder') ||
        response.contains('out of stock') ||
        response.contains('alert') ||
        userQuery.contains('low stock') ||
        userQuery.contains('reorder') ||
        userQuery.contains('out of stock') ||
        userQuery.contains('alert')) {
      return {
        'type': 'low_stock',
        'title': 'View Low Stock Alerts',
        'description': 'Products that need reordering',
      };
    }

    // Check for category-related queries
    if (response.contains('category') ||
        response.contains('categories') ||
        response.contains('type') ||
        response.contains('group') ||
        userQuery.contains('category') ||
        userQuery.contains('categories') ||
        userQuery.contains('type') ||
        userQuery.contains('group')) {
      return {
        'type': 'categories',
        'title': 'View Categories',
        'description': 'Product categories and distribution',
      };
    }

    // No specific data context detected
    return null;
  }

  // Navigate to appropriate screen based on data context
  void _navigateToDataScreen(Map<String, dynamic> dataContext) {
    // Pass the context data to show filtered results
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DynamicDataScreen(
          dataContext: dataContext,
          userQuery: _messageController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Chat window
          if (_isExpanded)
            SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 320,
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.smart_toy,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Assistant',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Online',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _toggleChat,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Messages
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: ListView.builder(
                            reverse: true,
                            itemCount: _messages.length + (_isTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_isTyping && index == 0) {
                                return _buildTypingIndicator();
                              }
                              final messageIndex = _isTyping
                                  ? index - 1
                                  : index;
                              final message =
                                  _messages[_messages.length -
                                      1 -
                                      messageIndex];
                              return _buildMessageBubble(message);
                            },
                          ),
                        ),
                      ),

                      // Input area
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText: 'Type your message...',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: IconButton(
                                onPressed: _sendMessage,
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Chat button
          GestureDetector(
            onTap: _toggleChat,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                _isExpanded ? Icons.keyboard_arrow_down : Icons.chat,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.primaryColor
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.poppins(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  if (!message.isUser) ...[
                    const SizedBox(height: 8),
                    if (message.dataContext != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () =>
                              _navigateToDataScreen(message.dataContext!),
                          child: Text(message.dataContext!['title']),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: AppTheme.primaryColor,
                            textStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [_buildDot(0), _buildDot(1), _buildDot(2)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index * 0.2;
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(delay, delay + 0.3, curve: Curves.easeInOut),
          ),
        );

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[600]!.withOpacity(animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? dataContext;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.dataContext,
  });
}
