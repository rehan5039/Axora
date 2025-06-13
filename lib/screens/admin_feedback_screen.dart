import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _filterRating = 0; // 0 means show all ratings
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Feedback'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            onSelected: (int rating) {
              setState(() {
                _filterRating = rating;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(
                value: 0,
                child: Text('All Ratings'),
              ),
              const PopupMenuItem<int>(
                value: 1,
                child: Text('⭐ (1 Star)'),
              ),
              const PopupMenuItem<int>(
                value: 2,
                child: Text('⭐⭐ (2 Stars)'),
              ),
              const PopupMenuItem<int>(
                value: 3,
                child: Text('⭐⭐⭐ (3 Stars)'),
              ),
              const PopupMenuItem<int>(
                value: 4,
                child: Text('⭐⭐⭐⭐ (4 Stars)'),
              ),
              const PopupMenuItem<int>(
                value: 5,
                child: Text('⭐⭐⭐⭐⭐ (5 Stars)'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildFeedbackQuery(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                _filterRating > 0 
                    ? 'No $_filterRating-star feedback found' 
                    : 'No feedback yet',
              ),
            );
          }
          
          final feedbackDocs = snapshot.data!.docs;
          
          return ListView.builder(
            itemCount: feedbackDocs.length,
            itemBuilder: (context, index) {
              final data = feedbackDocs[index].data() as Map<String, dynamic>;
              final rating = data['rating'] as int;
              final feedback = data['feedback'] as String? ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              final userEmail = data['userEmail'] as String? ?? 'Unknown user';
              final redirectedToPlayStore = data['redirectedToPlayStore'] as bool? ?? false;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: index < rating ? Colors.amber : Colors.grey,
                              ),
                            ),
                          ),
                          Text(
                            timestamp != null
                                ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
                                : 'Unknown date',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'From: $userEmail',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      if (redirectedToPlayStore) 
                        const Text('User was redirected to Play Store', 
                          style: TextStyle(fontStyle: FontStyle.italic)),
                      if (feedback.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(feedback),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Stream<QuerySnapshot> _buildFeedbackQuery() {
    Query query = _firestore.collection('feedback')
        .orderBy('timestamp', descending: true);
        
    // Apply rating filter if needed
    if (_filterRating > 0) {
      query = query.where('rating', isEqualTo: _filterRating);
    }
    
    return query.snapshots();
  }
} 