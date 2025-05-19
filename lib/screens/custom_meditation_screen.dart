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
  bool _isArticleCompleted = false;
  bool _isCheckingStatus = true;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkCompletionStatus();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
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
          _isArticleCompleted = false;
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
      
      // Get audio and article completion status
      final userMeditationStatusDoc = await FirebaseFirestore.instance
          .collection('user_meditation_progress')
          .doc(userId)
          .collection('meditation_details')
          .doc(widget.meditation.id)
          .get();
      
      final isAudioDone = userMeditationStatusDoc.exists 
          ? (userMeditationStatusDoc.data()?['audio_completed'] == true) 
          : false;
      
      final isArticleDone = userMeditationStatusDoc.exists 
          ? (userMeditationStatusDoc.data()?['article_completed'] == true) 
          : false;
      
      print('Checking completion status for meditation: ${widget.meditation.id}');
      print('Completed meditations: $completedMeditations');
      print('Is this meditation completed: $isAlreadyCompleted');
      print('Audio completed: $isAudioDone, Article completed: $isArticleDone');
      
      setState(() {
        _isCompleted = isAlreadyCompleted;
        _isAudioCompleted = isAudioDone;
        _isArticleCompleted = isArticleDone;
        _isCheckingStatus = false;
      });
      
      print('UI state updated - meditation=$_isCompleted, audio=$_isAudioCompleted, article=$_isArticleCompleted');
    } catch (e) {
      print('Error checking completion status: $e');
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }
  
  Future<void> _markArticleAsRead() async {
    if (_isArticleCompleted) return;
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to track progress'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isArticleCompleted = true;
    });
    
    try {
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('user_meditation_progress')
          .doc(userId)
          .collection('meditation_details')
          .doc(widget.meditation.id)
          .set({
            'article_completed': true,
            'last_updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Article marked as read!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error marking article as read: $e');
      setState(() {
        _isArticleCompleted = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking article as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _onAudioComplete() {
    setState(() {
      _isAudioCompleted = true;
    });
    
    _saveAudioCompletion();
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
                  
                  // Tab bar - styled for dark mode
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: isDarkMode ? Colors.deepPurpleAccent : Colors.black,
                      labelColor: isDarkMode ? Colors.white : Colors.black,
                      unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.headphones, 
                                size: 18,
                                color: _tabController.index == 0 
                                  ? (isDarkMode ? Colors.white : Colors.black)
                                  : (isDarkMode ? Colors.grey[400] : Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              Text('Audio'),
                              if (_isAudioCompleted)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.article, 
                                size: 18,
                                color: _tabController.index == 1 
                                  ? (isDarkMode ? Colors.white : Colors.black)
                                  : (isDarkMode ? Colors.grey[400] : Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              Text('Article'),
                              if (_isArticleCompleted)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Audio Tab
                        _buildAudioView(isDarkMode),
                        
                        // Article Tab
                        _buildArticleView(isDarkMode),
                      ],
                    ),
                  ),
                  
                  // Completion button at the bottom
                  if (!_isCompleted)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildCompletionButton(),
                    ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildAudioView(bool isDarkMode) {
    final audioData = widget.meditation.audio;
    final audioUrl = audioData['url'] as String? ?? '';
    final audioScript = audioData['audio-script'] as String? ?? '';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (audioUrl.isNotEmpty)
            CustomAudioPlayer(
              audioUrl: audioUrl,
              isDarkMode: isDarkMode,
              audioScript: audioScript,
              onComplete: _onAudioComplete,
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
  
  Widget _buildArticleView(bool isDarkMode) {
    final articleData = widget.meditation.article;
    final articleTitle = articleData['title'] as String? ?? 'Article';
    final articleContent = articleData['content'] as String? ?? 'No content available.';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article completed button - styled to match screenshot
          if (_isArticleCompleted) 
            Center(
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle, color: Colors.green),
                label: const Text(
                  'Article Completed',
                  style: TextStyle(color: Colors.green),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            )
          else if (!_isArticleCompleted)
            Center(
              child: OutlinedButton.icon(
                onPressed: _markArticleAsRead,
                icon: Icon(Icons.article, 
                  color: isDarkMode ? Colors.white : null
                ),
                label: Text('Mark as Read',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : null
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Article content - simple text without heading
          Text(
            articleContent,
            style: TextStyle(
              fontSize: 16, 
              height: 1.5,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompletionButton() {
    final bool canComplete = _isAudioCompleted && _isArticleCompleted;
    
    return ElevatedButton(
      onPressed: canComplete && !_isLoading ? _handleCompletion : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: canComplete ? Colors.green : Colors.grey,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(
              canComplete 
                ? 'Complete Meditation' 
                : 'Complete Audio & Article First',
              style: const TextStyle(fontSize: 16),
            ),
    );
  }
  
  Future<void> _handleCompletion() async {
    if (_isLoading || _isCompleted) return;
    
    if (!_isAudioCompleted || !_isArticleCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete both audio and article first'),
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
        
        // Also update meditation details to ensure both audio and article are marked as completed
        await userProgressRef
            .collection('meditation_details')
            .doc(widget.meditation.id)
            .set({
              'audio_completed': true,
              'article_completed': true,
              'completed_at': FieldValue.serverTimestamp(),
              'duration_minutes': widget.meditation.durationMinutes,
            }, SetOptions(merge: true));
        
        print('Successfully added meditation ${widget.meditation.id} to completed list for user $userId');
        
        setState(() {
          _isCompleted = true;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+${widget.meditation.durationMinutes} Flow added!'),
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