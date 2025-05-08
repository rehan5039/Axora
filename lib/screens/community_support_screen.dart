import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axora/models/chat_message.dart';
import 'package:axora/services/meditation_service.dart';

class CommunitySupportScreen extends StatefulWidget {
  const CommunitySupportScreen({Key? key}) : super(key: key);

  @override
  State<CommunitySupportScreen> createState() => _CommunitySupportScreenState();
}

class _CommunitySupportScreenState extends State<CommunitySupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAdmin = false;
  bool _isLoading = false;
  final _meditationService = MeditationService();
  
  // For reply functionality
  ChatMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final isAdmin = await _meditationService.isAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearChat() async {
    if (!_isAdmin) return;
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Messages'),
        content: const Text('Are you sure you want to clear all chat messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('CLEAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      // Get all messages
      final snapshot = await FirebaseFirestore.instance
          .collection('community_chat')
          .get();
          
      // Create a batch to delete all messages
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat cleared successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing chat: $e')),
      );
    }
  }

  void _setReplyingTo(ChatMessage message) {
    setState(() {
      _replyingTo = message;
    });
    // Focus the text field for reply
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to send messages')),
      );
      return;
    }

    try {
      final messageData = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous User',
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isAdmin': _isAdmin,
      };
      
      // Add reply data if replying to a message
      if (_replyingTo != null) {
        messageData['replyToId'] = _replyingTo!.id;
        messageData['replyToText'] = _replyingTo!.message;
        messageData['replyToUser'] = _replyingTo!.userName;
      }

      await FirebaseFirestore.instance.collection('community_chat').add(messageData);

      _messageController.clear();
      
      // Clear the reply state
      if (_replyingTo != null) {
        setState(() {
          _replyingTo = null;
        });
      }
      
      // Scroll to bottom after message is sent
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBackground = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final inputBackground = isDarkMode ? AppColors.darkCardBackground.withOpacity(0.7) : Colors.grey.shade100;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Community Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              tooltip: 'Clear all messages',
              onPressed: _clearChat,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildChatMessages(cardBackground, textColor, isDarkMode),
          ),
          if (_replyingTo != null)
            _buildReplyPreview(isDarkMode, textColor),
          _buildMessageInput(inputBackground, textColor, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(bool isDarkMode, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${_replyingTo!.userName}',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingTo!.message,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelReply,
            color: textColor,
            iconSize: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages(Color cardBackground, Color textColor, bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_chat')
          .orderBy('timestamp', descending: false)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data?.docs.map(
          (doc) => ChatMessage.fromFirestore(doc),
        ).toList() ?? [];

        // Scroll to bottom on initial load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        if (messages.isEmpty) {
          return Center(
            child: Text(
              'No messages yet. Be the first to chat!',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          );
        }

        final currentUser = FirebaseAuth.instance.currentUser;

        return Column(
          children: [
            // Help text for swipe functionality
            Container(
              margin: const EdgeInsets.only(bottom: 12, top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? AppColors.primaryGold.withOpacity(0.1)
                    : AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swipe_right,
                    size: 18,
                    color: isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Swipe message right to reply',
                    style: TextStyle(
                      color: isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMyMessage = currentUser?.uid == message.userId;
                  
                  return SwipeToReply(
                    message: message,
                    onReply: _setReplyingTo,
                    isDarkMode: isDarkMode,
                    child: GestureDetector(
                      onLongPress: () {
                        _showMessageOptions(message, isMyMessage);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildMessageBubble(
                          message,
                          isMyMessage,
                          cardBackground,
                          textColor,
                          isDarkMode,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessageOptions(ChatMessage message, bool isMyMessage) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _setReplyingTo(message);
                },
              ),
              if (isMyMessage || _isAdmin)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Message', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _deleteMessage(message.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('community_chat')
          .doc(messageId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isMyMessage,
    Color cardBackground,
    Color textColor,
    bool isDarkMode,
  ) {
    final nameStyle = TextStyle(
      color: isMyMessage
          ? isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen
          : message.isAdmin
              ? Colors.purpleAccent
              : AppColors.primaryBlue,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    final messageStyle = TextStyle(
      color: textColor,
      fontSize: 14,
    );

    final timestampStyle = TextStyle(
      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
      fontSize: 10,
    );

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMyMessage
                ? (isDarkMode ? AppColors.primaryGold.withOpacity(0.2) : AppColors.primaryGreen.withOpacity(0.2))
                : cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMyMessage
                  ? (isDarkMode ? AppColors.primaryGold.withOpacity(0.5) : AppColors.primaryGreen.withOpacity(0.3))
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.userName,
                    style: nameStyle,
                  ),
                  if (message.isAdmin)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Show the reply message if there is one
              if (message.replyToText != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? Colors.grey.shade800.withOpacity(0.5) 
                        : Colors.grey.shade200.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.replyToUser ?? 'Unknown',
                        style: TextStyle(
                          color: isDarkMode 
                              ? AppColors.primaryBlue.withOpacity(0.8) 
                              : AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.replyToText!,
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              
              Text(
                message.message,
                style: messageStyle,
              ),
              const SizedBox(height: 2),
              Text(
                _formatTimestamp(message.timestamp),
                style: timestampStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return 'Today, ${_formatTime(timestamp)}';
    } else if (messageDate == yesterday) {
      return 'Yesterday, ${_formatTime(timestamp)}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}, ${_formatTime(timestamp)}';
    }
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildMessageInput(Color inputBackground, Color textColor, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCardBackground : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: inputBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: _replyingTo != null ? 'Reply to ${_replyingTo!.userName}...' : 'Type a message...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: TextStyle(color: textColor),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A widget that allows swiping on chat messages to reply
class SwipeToReply extends StatefulWidget {
  final Widget child;
  final ChatMessage message;
  final Function(ChatMessage) onReply;
  final bool isDarkMode;

  const SwipeToReply({
    Key? key,
    required this.child,
    required this.message,
    required this.onReply,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double _dragExtent = 0;
  static const double _activationThreshold = 70.0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent = _dragExtent + details.delta.dx;
      if (_dragExtent < 0) _dragExtent = 0;
      if (_dragExtent > _activationThreshold * 1.5) _dragExtent = _activationThreshold * 1.5;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragExtent >= _activationThreshold) {
      // Activate reply
      widget.onReply(widget.message);
      HapticFeedback.mediumImpact();
    }
    
    // Reset position with animation
    setState(() {
      _dragExtent = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final replyIconOpacity = (_dragExtent / _activationThreshold).clamp(0.0, 1.0);
    
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          // Reply arrow indicator that becomes more visible as user drags
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: replyIconOpacity,
                    child: Icon(
                      Icons.reply,
                      color: widget.isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
                      size: 20 + (replyIconOpacity * 8), // Icon grows slightly as opacity increases
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // The actual message, with transform based on drag
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
} 