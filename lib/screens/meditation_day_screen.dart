import 'package:flutter/material.dart';
import 'package:axora/models/meditation_content.dart';
import 'package:axora/services/meditation_service.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/widgets/custom_audio_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MeditationDayScreen extends StatefulWidget {
  final MeditationContent content;
  final VoidCallback onComplete;

  const MeditationDayScreen({
    super.key,
    required this.content,
    required this.onComplete,
  });

  @override
  State<MeditationDayScreen> createState() => _MeditationDayScreenState();
}

class _MeditationDayScreenState extends State<MeditationDayScreen> with SingleTickerProviderStateMixin {
  final _meditationService = MeditationService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  late TabController _tabController;
  bool _isArticleCompleted = false;
  bool _isAudioCompleted = false;
  bool _isDayCompleted = false;
  bool _isCheckingCompletion = false;
  bool _isAutoNavigating = false;
  
  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;
  
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
    if (_userId == null) return;
    
    try {
      // Check article completion
      final articleDoc = await _firestore
          .collection('user_profiles')
          .doc(_userId)
          .collection('completed_articles')
          .doc(widget.content.id)
          .get();
      
      // Check audio completion
      final audioDoc = await _firestore
          .collection('user_profiles')
          .doc(_userId)
          .collection('completed_audios')
          .doc(widget.content.id)
          .get();
      
      setState(() {
        _isArticleCompleted = articleDoc.exists;
        _isAudioCompleted = audioDoc.exists;
      });
    } catch (e) {
      print('Error checking completion status: $e');
    }
  }
  
  Future<void> _checkAndCompleteDayIfBothCompleted() async {
    if (_isArticleCompleted && _isAudioCompleted && !_isDayCompleted && !_isCheckingCompletion) {
      setState(() {
        _isCheckingCompletion = true;
      });
      
      try {
        print('Checking completion for content ID: ${widget.content.id}');
        
        // Force a delay to ensure Firebase operations complete
        await Future.delayed(const Duration(milliseconds: 500));
        
        final completed = await _meditationService.checkAndCompleteDayIfBothCompleted(widget.content.id);
        
        print('Completion check result: $completed');
        setState(() {
          _isDayCompleted = completed;
          _isCheckingCompletion = false;
        });
        
        if (completed) {
          print('Day ${widget.content.day} marked as completed! Sticker should be awarded.');
          
          // Verify if sticker was awarded
          final stickers = await _meditationService.getUserStickers();
          print('User now has ${stickers?.stickers ?? 0} stickers');
          print('Sticker for day ${widget.content.day} exists: ${stickers?.hasStickerForDay(widget.content.day) ?? false}');
          
          _showCompletionDialog();
          widget.onComplete(); // Notify parent to refresh
        }
      } catch (e) {
        print('Error completing day: $e');
        setState(() {
          _isCheckingCompletion = false;
        });
      }
    } else {
      print('Not ready for completion check:');
      print('Article completed: $_isArticleCompleted');
      print('Audio completed: $_isAudioCompleted');
      print('Day completed: $_isDayCompleted');
      print('Checking completion: $_isCheckingCompletion');
    }
  }
  
  Future<void> _markArticleAsCompleted() async {
    if (_isArticleCompleted) return;
    
    setState(() {
      _isArticleCompleted = true;
    });
    
    try {
      print('Marking article as completed for content ID: ${widget.content.id}');
      await _meditationService.markArticleAsCompleted(widget.content.id);
      
      // If audio is also completed, check and complete the day
      if (_isAudioCompleted) {
        print('Both article and audio completed - checking day completion');
        await _checkAndCompleteDayIfBothCompleted();
        
        // Return to journey screen automatically
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Show a snackbar to prompt the user to listen to the audio
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Article marked as read! Listen to the audio to complete this day.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error marking article as completed: $e');
      setState(() {
        _isArticleCompleted = false;
      });
    }
  }
  
  Future<void> _markAudioAsCompleted() async {
    if (_isAudioCompleted) return;
    
    setState(() {
      _isAudioCompleted = true;
    });
    
    try {
      print('Marking audio as completed for content ID: ${widget.content.id}');
      await _meditationService.markAudioAsCompleted(widget.content.id);
      
      // Auto-switch to article tab after audio completion
      if (!_isArticleCompleted && !_isAutoNavigating) {
        setState(() {
          _isAutoNavigating = true;
        });
        
        // Wait a moment for the completion UI to be visible before switching tabs
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _tabController.animateTo(1); // Switch to article tab (index 1)
            setState(() {
              _isAutoNavigating = false;
            });
            
            // Show a snackbar to prompt user to read the article
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Audio completed! Now read the article to finish this day.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      } else if (_isArticleCompleted) {
        // If article is already completed, check and complete the day
        print('Both audio and article completed - checking day completion');
        await _checkAndCompleteDayIfBothCompleted();
        
        // Return to journey screen automatically
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('Error marking audio as completed: $e');
      setState(() {
        _isAudioCompleted = false;
      });
    }
  }
  
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star,
              color: Colors.amber,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'You\'ve completed Day ${widget.content.day} and earned a sticker!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.content.day < 30
                  ? 'Day ${widget.content.day + 1} will be unlocked in 24 hours.'
                  : 'You\'ve completed the entire meditation journey!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // Return to journey screen automatically
              Navigator.of(context).pop(); // Return to journey screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final article = ArticleContent.fromMap(widget.content.article);
    final audio = AudioContent.fromMap(widget.content.audio);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${widget.content.day}: ${widget.content.title}'),
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          indicatorColor: isDarkMode ? Colors.deepPurple : Colors.blue,
          labelColor: isDarkMode ? Colors.white : Colors.black87,
          unselectedLabelColor: isDarkMode ? Colors.white60 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Audio Meditation', icon: Icon(Icons.headphones)),
            Tab(text: 'Article', icon: Icon(Icons.article)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Audio Tab
          _buildAudioTab(audio, isDarkMode),
          
          // Article Tab
          _buildArticleTab(article, isDarkMode),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isDarkMode),
    );
  }
  
  Widget _buildArticleTab(ArticleContent article, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            article.content,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
          if (!_isArticleCompleted)
            Center(
              child: ElevatedButton(
                onPressed: _markArticleAsCompleted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.deepPurple : Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Mark as Read',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioTab(AudioContent audio, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            audio.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.deepPurple[800] : Colors.blue[100],
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: CachedNetworkImage(
                imageUrl: 'https://firebasestorage.googleapis.com/v0/b/axora-5039.appspot.com/o/meditation_images%2Fday${widget.content.day}.jpg?alt=media',
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.self_improvement, size: 80),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 32),
          CustomAudioPlayer(
            audioUrl: audio.url,
            onComplete: _markAudioAsCompleted,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDarkMode) {
    if (_isDayCompleted) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: isDarkMode ? Colors.green[900] : Colors.green[100],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: isDarkMode ? Colors.green[100] : Colors.green[900],
            ),
            const SizedBox(width: 8),
            Text(
              'Day ${widget.content.day} Completed!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.green[100] : Colors.green[900],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
} 