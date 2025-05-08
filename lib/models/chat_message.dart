import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;
  final bool isAdmin;
  final String? replyToId;     // ID of the message this is replying to
  final String? replyToText;   // Text of the message this is replying to
  final String? replyToUser;   // Username of the original message sender

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
    required this.isAdmin,
    this.replyToId,
    this.replyToText,
    this.replyToUser,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Handle the case where timestamp might be null
    final timestamp = data['timestamp'];
    return ChatMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      message: data['message'] ?? '',
      timestamp: timestamp != null ? (timestamp as Timestamp).toDate() : DateTime.now(),
      isAdmin: data['isAdmin'] ?? false,
      replyToId: data['replyToId'],
      replyToText: data['replyToText'],
      replyToUser: data['replyToUser'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isAdmin': isAdmin,
      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToUser': replyToUser,
    };
  }
} 