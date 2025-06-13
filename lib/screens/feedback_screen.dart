import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  final String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.rr.axora.axora';
  
  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'How would you rate your experience with Axora?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: index < _rating ? Colors.amber : Colors.grey,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            
            // Feedback text field - visible for ratings 1-3
            if (_rating > 0 && _rating <= 3)
              TextField(
                controller: _feedbackController,
                maxLength: 500,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Please tell us how we can improve',
                  border: OutlineInputBorder(),
                ),
              ),
              
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _rating > 0 ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSubmitting 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit Feedback', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Avoid multiple submissions
    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Log analytics event
      await FirebaseAnalytics.instance.logEvent(
        name: 'submit_feedback',
        parameters: {'rating': _rating},
      );
      
      // For 4-5 star ratings, redirect to Play Store
      if (_rating >= 4) {
        // Show confirmation dialog
        bool result = await _showPlayStoreConfirmation();
        if (result) {
          // Launch Play Store URL
          final Uri url = Uri.parse(_playStoreUrl);
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            // If launching fails, show error
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open Play Store')),
              );
            }
          } else {
            // Still save that they were redirected to Play Store
            await _saveFeedbackToFirestore(redirectedToPlayStore: true);
            if (mounted) {
              Navigator.pop(context);
            }
          }
        }
      } else {
        // For 1-3 star ratings, save feedback to Firestore
        await _saveFeedbackToFirestore();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you for your feedback!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error submitting feedback. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _saveFeedbackToFirestore({bool redirectedToPlayStore = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await FirebaseFirestore.instance.collection('feedback').add({
      'userId': user.uid,
      'userEmail': user.email,
      'rating': _rating,
      'feedback': _rating <= 3 ? _feedbackController.text.trim() : '',
      'redirectedToPlayStore': redirectedToPlayStore,
      'timestamp': FieldValue.serverTimestamp(),
      'platform': 'Android', // You might want to make this dynamic based on platform
    });
  }

  Future<bool> _showPlayStoreConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thank You!'),
        content: const Text('We\'re glad you\'re enjoying Axora! Would you like to share your positive experience by rating us on the Play Store?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Maybe Later'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rate Now'),
          ),
        ],
      ),
    ) ?? false;
  }
} 