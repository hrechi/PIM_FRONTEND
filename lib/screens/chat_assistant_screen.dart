import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/conversation_model.dart';
import '../services/chat_service.dart';
import '../services/conversation_service.dart';
import '../utils/constants.dart';

class ChatAssistantScreen extends StatefulWidget {
  const ChatAssistantScreen({super.key});

  @override
  State<ChatAssistantScreen> createState() => _ChatAssistantScreenState();
}

class _ChatAssistantScreenState extends State<ChatAssistantScreen> {
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
            .map((msg) => _messages.isEmpty
                ? ChatMessage(
                    text: msg.content,
                    isUser: msg.isUserMessage,
                    timestamp: msg.createdAt,
                  )
                : ChatMessage(
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
      _messages = [
        ChatMessage(
          text:
              'Hello! I am your Fieldly assistant. Ask me about your fields, missions, or farming concepts.',
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
        title: const Text('New Conversation'),
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
                    ? 'Chat ${DateTime.now().toLocal()}'
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    // If no conversation exists yet, create one
    if (_currentConversationId == null) {
      try {
        final conversation = await ConversationService.createConversation(
          'Chat ${DateTime.now().toLocal()}',
        );
        setState(() {
          _conversations.insert(0, conversation);
          _currentConversationId = conversation.id;
        });
      } catch (e) {
        _showErrorSnackbar('Failed to create conversation: $e');
        return;
      }
    }

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isSending = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final result = await ChatService.sendMessage(
        text,
        conversationId: _currentConversationId,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: result['reply'] as String,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, something went wrong. ${e.toString()}'.trim(),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      if (!mounted) return;
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
      appBar: AppBar(
        title: const Text('Fieldly Assistant'),
        backgroundColor: AppColors.mistBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewConversation,
            tooltip: 'New Conversation',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar with conversations
          Container(
            width: MediaQuery.of(context).size.width > 600 ? 250 : 0,
            color: Colors.grey[100],
            child: MediaQuery.of(context).size.width <= 600
                ? const SizedBox.shrink()
                : _buildConversationsSidebar(),
          ),
          // Chat area
          Expanded(
            child: _isLoadingConversations
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: _isLoadingMessages
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  final isUser = message.isUser;
                                  return Align(
                                    alignment: isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      constraints:
                                          const BoxConstraints(maxWidth: 320),
                                      decoration: BoxDecoration(
                                        color: isUser
                                            ? AppColors.mistBlue
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        message.text,
                                        style: TextStyle(
                                          color: isUser
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendMessage(),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Ask about missions, fields, or farming...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed:
                                    _isSending ? null : _sendMessage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.mistBlue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                ),
                                child: _isSending
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.send,
                                        color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      // Mobile drawer for conversations
      drawer: MediaQuery.of(context).size.width <= 600
          ? Drawer(
              child: _buildConversationsList(),
            )
          : null,
    );
  }

  Widget _buildConversationsSidebar() {
    return Column(
      children: [
        Expanded(
          child: _buildConversationsList(),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton.icon(
            onPressed: _createNewConversation,
            icon: const Icon(Icons.add),
            label: const Text('New Chat'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.square(50),
              backgroundColor: AppColors.mistBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final isSelected = _currentConversationId == conversation.id;
        return Container(
          color: isSelected ? AppColors.mistBlue.withValues(alpha: 0.1) : null,
          child: ListTile(
            title: Text(
              conversation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            selected: isSelected,
            onTap: () {
              Navigator.of(context).maybePop(); // Close drawer on mobile
              _loadConversationMessages(conversation.id);
            },
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Delete'),
                  onTap: () =>
                      _deleteConversation(conversation.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
