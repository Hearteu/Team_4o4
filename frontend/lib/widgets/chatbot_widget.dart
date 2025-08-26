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

    // Check for ranking queries first (top N, best N, etc.)
    if (userQuery.contains('top') ||
        response.contains('top') ||
        userQuery.contains('best') ||
        response.contains('best') ||
        userQuery.contains('highest') ||
        response.contains('highest') ||
        userQuery.contains('most') ||
        response.contains('most') ||
        userQuery.contains('popular') ||
        response.contains('popular') ||
        userQuery.contains('leading') ||
        response.contains('leading')) {
      return {
        'type': 'ranking',
        'title': 'View Top Products',
        'description': 'Ranked products by quantity, value, or price',
      };
    }

    // Check for specific product queries
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
    // Get the last user message for precise filtering
    String userQuery = '';
    String aiResponse = '';
    if (_messages.isNotEmpty) {
      // Find the last user message and AI response
      for (int i = _messages.length - 1; i >= 0; i--) {
        if (_messages[i].isUser && userQuery.isEmpty) {
          userQuery = _messages[i].text;
        } else if (!_messages[i].isUser && aiResponse.isEmpty) {
          aiResponse = _messages[i].text;
        }
        if (userQuery.isNotEmpty && aiResponse.isNotEmpty) break;
      }
    }

    // Extract mentioned products from AI response
    List<String> mentionedProducts = _extractMentionedProducts(
      aiResponse,
      userQuery,
    );

    // Add mentioned products to data context
    Map<String, dynamic> enhancedContext = Map<String, dynamic>.from(
      dataContext,
    );
    enhancedContext['mentioned_products'] = mentionedProducts;
    enhancedContext['ai_response'] = aiResponse;

    // Pass the context data to show filtered results
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DynamicDataScreen(
          dataContext: enhancedContext,
          userQuery: userQuery,
        ),
      ),
    );
  }

  // Extract products mentioned in AI response
  List<String> _extractMentionedProducts(String aiResponse, String userQuery) {
    List<String> mentionedProducts = [];

    // Extract from AI response
    if (aiResponse.isNotEmpty) {
      // Look for product names in the AI response
      List<String> allProducts = [
        'Dental Floss',
        'Toothpaste Fluoride',
        'Antiseptic Solution',
        'Metoprolol 50mg',
        'Men\'s Multivitamin',
        'Prenatal Vitamins',
        'Iron Supplement',
        'Lisinopril 10mg',
        'Amlodipine 5mg',
        'Glipizide 5mg',
        'Prostate Health',
        'Sunscreen SPF 50',
        'Eye Drops Lubricating',
        'Baby Diapers Size 3',
        'Acne Treatment Gel',
        'Reading Glasses +2.0',
        'Azithromycin 250mg',
        'Fluticasone Nasal Spray',
        'Baby Wipes',
        'Testosterone Support',
      ];

      for (String product in allProducts) {
        if (aiResponse.toLowerCase().contains(product.toLowerCase())) {
          mentionedProducts.add(product);
        }
      }
    }

    // Also extract from user query
    if (userQuery.isNotEmpty) {
      List<String> queryTerms = _extractSearchTerms(userQuery);
      mentionedProducts.addAll(queryTerms);
    }

    // Remove duplicates and return
    return mentionedProducts.toSet().toList();
  }

  // Extract search terms from query (reuse existing method)
  List<String> _extractSearchTerms(String query) {
    // Common pharmacy product keywords
    List<String> pharmacyKeywords = [
      'dental',
      'floss',
      'toothpaste',
      'tooth',
      'brush',
      'vitamin',
      'supplement',
      'medicine',
      'drug',
      'pill',
      'tablet',
      'capsule',
      'syrup',
      'cream',
      'gel',
      'ointment',
      'drops',
      'spray',
      'inhaler',
      'bandage',
      'gauze',
      'cotton',
      'alcohol',
      'antiseptic',
      'antibiotic',
      'pain',
      'fever',
      'cold',
      'flu',
      'allergy',
      'diabetes',
      'blood',
      'pressure',
      'heart',
      'cholesterol',
      'baby',
      'diaper',
      'wipe',
      'formula',
      'milk',
      'adult',
      'senior',
      'men',
      'women',
      'prenatal',
      'iron',
      'calcium',
      'magnesium',
      'zinc',
      'omega',
      'fish',
      'oil',
      'probiotic',
      'enzyme',
      'hormone',
      'testosterone',
      'prostate',
      'eye',
      'ear',
      'nose',
      'throat',
      'skin',
      'hair',
      'nail',
      'sunscreen',
      'lotion',
      'soap',
      'shampoo',
      'conditioner',
      'deodorant',
      'perfume',
      'cosmetic',
      'makeup',
      'razor',
      'blade',
      'shave',
      'trim',
      'reading',
      'glasses',
      'contact',
      'lens',
      'hearing',
      'aid',
      'cane',
      'walker',
      'wheelchair',
      'crutch',
      'brace',
      'splint',
      'cast',
      'tape',
      'adhesive',
      'band',
      'plaster',
      'thermometer',
      'scale',
      'monitor',
      'device',
      'equipment',
      'tool',
      'instrument',
      'machine',
      'apparatus',
    ];

    // Split query into words and filter meaningful terms
    List<String> words = query
        .split(' ')
        .where((word) => word.length > 2) // Filter out short words
        .map((word) => word.toLowerCase())
        .toList();

    // Add pharmacy-specific keywords that match the query
    List<String> searchTerms = [];

    // Add individual words from query
    searchTerms.addAll(words);

    // Add pharmacy keywords that are mentioned in the query
    for (String keyword in pharmacyKeywords) {
      if (query.contains(keyword)) {
        searchTerms.add(keyword);
      }
    }

    // Remove duplicates and return
    return searchTerms.toSet().toList();
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
                  width: 450,
                  height: 500,
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
