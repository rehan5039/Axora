import 'package:flutter/material.dart';
import 'package:axora/models/custom_meditation.dart';
import 'package:axora/services/meditation_service.dart';
import 'package:axora/widgets/custom_audio_player.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomMeditationScreen extends StatefulWidget {
  final CustomMeditation meditation;

  const CustomMeditationScreen({
    super.key,
    required this.meditation,
  });

  @override
  State<CustomMeditationScreen> createState() => _CustomMeditationScreenState();
}

class _CustomMeditationScreenState extends State<CustomMeditationScreen> with SingleTickerProviderStateMixin {
  final _meditationService = MeditationService();
  bool _isLoading = false;
  bool _isCompleted = false;
  bool _isAudioCompleted = false;
  bool _isCheckingStatus = true;
  
  @override
  void initState() {
    super.initState();
    _checkCompletionStatus();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  Future<void> _checkCompletionStatus() async {
    setState(() {
      _isCheckingStatus = true;
    });
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isCompleted = false;
          _isAudioCompleted = false;
          _isCheckingStatus = false;
        });
        return;
      }
      
      // Get user progress document from Firestore
      final userProgressDoc = await FirebaseFirestore.instance
          .collection('user_meditation_progress')
          .doc(userId)
          .get();
      
      // Check if meditation is completed
      final completedMeditations = userProgressDoc.exists
          ? List<String>.from(userProgressDoc.data()?['completed_meditations'] ?? [])
          : [];
      
      final bool isAlreadyCompleted = completedMeditations.contains(widget.meditation.id);
      
      // Get audio completion status
      final userMeditationStatusDoc = await FirebaseFirestore.instance
          .collection('user_meditation_progress')
          .doc(userId)
          .collection('meditation_details')
          .doc(widget.meditation.id)
          .get();
      
      final isAudioDone = userMeditationStatusDoc.exists 
          ? (userMeditationStatusDoc.data()?['audio_completed'] == true) 
          : false;
      
      print('Checking completion status for meditation: ${widget.meditation.id}');
      print('Completed meditations: $completedMeditations');
      print('Is this meditation completed: $isAlreadyCompleted');
      print('Audio completed: $isAudioDone');
      
      setState(() {
        _isCompleted = isAlreadyCompleted;
        _isAudioCompleted = isAudioDone;
        _isCheckingStatus = false;
      });
      
      print('UI state updated - meditation=$_isCompleted, audio=$_isAudioCompleted');
    } catch (e) {
      print('Error checking completion status: $e');
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }
  
  void _onAudioComplete() {
    setState(() {
      _isAudioCompleted = true;
    });
    
    _saveAudioCompletion();
    // Auto-complete the meditation when audio is completed
    if (!_isCompleted) {
      _handleCompletion();
    }
  }
  
  Future<void> _saveAudioCompletion() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return;
    }
    
    try {
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('user_meditation_progress')
          .doc(userId)
          .collection('meditation_details')
          .doc(widget.meditation.id)
          .set({
            'audio_completed': true,
            'last_updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio completed!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error saving audio completion: $e');
      setState(() {
        _isAudioCompleted = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: Text('${widget.meditation.durationMinutes}-Minute Meditation'),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          // Show completion indicator
          if (_isCompleted)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
        ],
      ),
      body: _isCheckingStatus
          ? Center(child: CircularProgressIndicator(
              color: isDarkMode ? Colors.white : Colors.blue,
            ))
          : SafeArea(
              child: Column(
                children: [
                  // Meditation title and info
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.meditation.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.meditation.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                ? Colors.deepPurple.withOpacity(0.2) 
                                : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${widget.meditation.durationMinutes} min',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.deepPurpleAccent : Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Audio content
                  Expanded(
                    child: _buildAudioView(isDarkMode),
                  ),
                  
                  // Removing the completion button as it will be auto-completed
                ],
              ),
            ),
    );
  }
  
  Widget _buildAudioView(bool isDarkMode) {
    final audioData = widget.meditation.audio;
    final audioUrl = audioData['url'] as String? ?? '';
    final audioScript = audioData['audio-script'] as String? ?? '';
    final articleData = widget.meditation.article;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (audioUrl.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isAudioCompleted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        label: const Text(
                          'Audio Completed',
                          style: TextStyle(color: Colors.green),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                CustomAudioPlayer(
                  audioUrl: audioUrl,
                  isDarkMode: isDarkMode,
                  audioScript: audioScript,
                  onComplete: _onAudioComplete,
                ),
                
                // Display article if available
                if (articleData != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          articleData['title'] as String? ?? 'Article',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode 
                              ? Colors.grey.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkMode
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            articleData['content'] as String? ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            Center(
              child: Text(
                'No audio available for this meditation.',
                style: TextStyle(
                  fontSize: 16, 
                  fontStyle: FontStyle.italic,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Future<void> _handleCompletion() async {
    if (_isLoading || _isCompleted) return;
    
    if (!_isAudioCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the audio first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to track completion'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _meditationService.completeCustomMeditation(widget.meditation.id);
      
      if (success) {
        // Update user's completion data in Firestore
        final userProgressRef = FirebaseFirestore.instance
            .collection('user_meditation_progress')
            .doc(userId);
        
        // Add this meditation ID to the user's completed meditations list
        await userProgressRef.set({
          'completed_meditations': FieldValue.arrayUnion([widget.meditation.id]),
          'last_updated': FieldValue.serverTimestamp(),
          'user_id': userId,
        }, SetOptions(merge: true));
        
        // Also update meditation details to ensure audio is marked as completed
        await userProgressRef
            .collection('meditation_details')
            .doc(widget.meditation.id)
            .set({
              'audio_completed': true,
              'completed_at': FieldValue.serverTimestamp(),
              'duration_minutes': widget.meditation.durationMinutes,
            }, SetOptions(merge: true));
        
        print('Successfully added meditation ${widget.meditation.id} to completed list for user $userId');
        
        setState(() {
          _isCompleted = true;
          _isLoading = false;
        });
        
        // Check if flow was earned from Firestore
        final flowDoc = await FirebaseFirestore.instance
            .collection('meditation_flow')
            .doc(userId)
            .get();
        
        final bool earnedFlowToday = flowDoc.exists ? 
            (flowDoc.data()?['earnedFlowToday'] == true) : false;
        
        // Show appropriate success message based on whether flow was earned
        final lastUpdated = flowDoc.data()?['lastUpdated'];
        final bool justEarnedFlow = earnedFlowToday && 
            lastUpdated != null && 
            (lastUpdated as Timestamp).toDate().difference(DateTime.now()).inSeconds > -5;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(justEarnedFlow 
              ? '+1 Flow added for today!' 
              : 'Meditation completed successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete meditation. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error completing meditation: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 