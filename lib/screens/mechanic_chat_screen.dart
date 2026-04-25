import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/chat_message.dart';
import '../models/conversation_model.dart';
import '../services/conversation_service.dart';
import '../services/mechanic_chat_service.dart';

class MechanicChatScreen extends StatefulWidget {
  const MechanicChatScreen({
    super.key,
    this.assetBrand,
    this.assetModel,
    this.assetCategory,
  });

  final String? assetBrand;
  final String? assetModel;
  final String? assetCategory;

  @override
  State<MechanicChatScreen> createState() => _MechanicChatScreenState();
}

class _MechanicChatScreenState extends State<MechanicChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _titleController = TextEditingController();

  List<ChatMessage> _messages = [];
  List<Conversation> _conversations = [];
  String? _currentConversationId;
  bool _isSending = false;
  bool _isLoadingConversations = true;
  bool _isLoadingMessages = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await ConversationService.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _isLoadingConversations = false;
        if (_conversations.isNotEmpty) {
          _currentConversationId = _conversations.first.id;
          _loadConversationMessages(_conversations.first.id);
        } else {
          _messages = [];
          _addInitialMessage();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingConversations = false);
      _showErrorSnackbar('Failed to load conversations: $e');
    }
  }

  Future<void> _loadConversationMessages(String conversationId) async {
    setState(() => _isLoadingMessages = true);
    try {
      final conversation =
          await ConversationService.getConversationById(conversationId);
      if (!mounted) return;
      setState(() {
        _messages = conversation.messages
            .map((msg) => ChatMessage(
                  text: msg.content,
                  isUser: msg.isUserMessage,
                  timestamp: msg.createdAt,
                ))
            .toList();
        _currentConversationId = conversationId;
        _isLoadingMessages = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMessages = false);
      _showErrorSnackbar('Failed to load conversation: $e');
    }
  }

  void _addInitialMessage() {
    setState(() {
      final assetInfo = widget.assetBrand != null || widget.assetModel != null
          ? '\n\nYou are asking about: ${[widget.assetBrand, widget.assetModel].where((e) => e != null).join(', ')}'
          : '';
      _messages = [
        ChatMessage(
          text:
              'Hello! I am your agricultural mechanic assistant. Ask me about machinery repairs, maintenance, diagnostics, and troubleshooting.$assetInfo',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
    });
  }

  Future<void> _createNewConversation() async {
    _titleController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Mechanic Chat'),
        content: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Enter conversation title (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final title = _titleController.text.trim().isEmpty
                    ? 'Mechanic Chat ${DateTime.now().toLocal()}'
                    : _titleController.text.trim();
                final conversation =
                    await ConversationService.createConversation(title);
                if (!mounted) return;
                setState(() {
                  _conversations.insert(0, conversation);
                  _currentConversationId = conversation.id;
                  _messages = [];
                  _addInitialMessage();
                });
              } catch (e) {
                _showErrorSnackbar('Failed to create conversation: $e');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation(String conversationId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content:
            const Text('Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ConversationService.deleteConversation(conversationId);
                if (!mounted) return;
                setState(() {
                  _conversations
                      .removeWhere((c) => c.id == conversationId);
                  if (_currentConversationId == conversationId) {
                    if (_conversations.isNotEmpty) {
                      _currentConversationId = _conversations.first.id;
                      _loadConversationMessages(_conversations.first.id);
                    } else {
                      _currentConversationId = null;
                      _messages = [];
                      _addInitialMessage();
                    }
                  }
                });
              } catch (e) {
                _showErrorSnackbar('Failed to delete conversation: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSending = true);
    _controller.clear();

    try {
      final result = await MechanicChatService.sendMessage(
        message,
        brand: widget.assetBrand,
        model: widget.assetModel,
        category: widget.assetCategory,
        conversationId: _currentConversationId,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(ChatMessage(
          text: message,
          isUser: true,
          timestamp: DateTime.now(),
        ));
        _messages.add(ChatMessage(
          text: result['reply'] as String,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        if (_currentConversationId == null) {
          _currentConversationId = result['conversationId'] as String?;
          _loadConversations();
        }
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      _showErrorSnackbar('Failed to send message: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08140E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08140E),
        surfaceTintColor: Colors.transparent,
        title: Text(
          '🔧 Mechanic Assistant',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        actions: [
          PopupMenuButton(
            color: const Color(0xFF1a2a1f),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('New Chat'),
                onTap: _createNewConversation,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoadingConversations)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (_conversations.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: _conversations
                      .take(5)
                      .map((conv) => GestureDetector(
                            onTap: () => _loadConversationMessages(conv.id),
                            onLongPress: () =>
                                _deleteConversation(conv.id),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _currentConversationId == conv.id
                                    ? const Color(0xFF2F8ED1)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _currentConversationId == conv.id
                                      ? const Color(0xFF2F8ED1)
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                conv.title.length > 15
                                    ? '${conv.title.substring(0, 15)}...'
                                    : conv.title,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          Expanded(
            child: _isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? const Color(0xFF2F8ED1)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: message.isUser
                                ? null
                                : Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                          ),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Text(
                            message.text,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask about machinery...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                    ),
                    enabled: !_isSending,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F8ED1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
