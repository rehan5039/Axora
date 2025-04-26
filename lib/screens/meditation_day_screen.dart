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
        
        // Check if both article and audio are actually completed in Firebase
        if (_userId != null) {
          final articleDoc = await _firestore
              .collection('user_profiles')
              .doc(_userId)
              .collection('completed_articles')
              .doc(widget.content.id)
              .get();
              
          final audioDoc = await _firestore
              .collection('user_profiles')
              .doc(_userId)
              .collection('completed_audios')
              .doc(widget.content.id)
              .get();
              
          if (!articleDoc.exists || !audioDoc.exists) {
            print('WARNING: Local state shows completed but Firebase docs do not match:');
            print('Article doc exists: ${articleDoc.exists}');
            print('Audio doc exists: ${audioDoc.exists}');
            
            // Try to fix the mismatch by marking them again
            if (!articleDoc.exists) {
              print('Attempting to re-mark article as completed');
              await _meditationService.markArticleAsCompleted(widget.content.id);
            }
            
            if (!audioDoc.exists) {
              print('Attempting to re-mark audio as completed');
              await _meditationService.markAudioAsCompleted(widget.content.id);
            }
            
            // Give Firebase a moment to update
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
        
        // Now proceed with completion
        bool dayCompleted = false;
        bool stickerAwarded = false;
        
        try {
          // Try to complete the day in Firebase
          dayCompleted = await _meditationService.checkAndCompleteDayIfBothCompleted(widget.content.id);
          print('Completion check result: $dayCompleted');
          
          if (dayCompleted) {
            print('Day ${widget.content.day} marked as completed! Sticker should be awarded.');
            
            // Verify if sticker was awarded
            final stickers = await _meditationService.getUserStickers();
            stickerAwarded = stickers?.hasStickerForDay(widget.content.day) ?? false;
            print('User now has ${stickers?.stickers ?? 0} stickers');
            print('Sticker for day ${widget.content.day} exists: $stickerAwarded');
            
            // If sticker was not awarded, try to directly add it
            if (!stickerAwarded && stickers != null) {
              print('WARNING: Sticker was not awarded automatically. Trying to add it directly...');
              await _meditationService.addStickerForDay(widget.content.day);
              
              // Verify again
              final verifyStickers = await _meditationService.getUserStickers();
              stickerAwarded = verifyStickers?.hasStickerForDay(widget.content.day) ?? false;
              print('After direct add, user has ${verifyStickers?.stickers ?? 0} stickers');
              print('Sticker for day ${widget.content.day} exists: $stickerAwarded');
            }
          }
        } catch (e) {
          print('Error during day completion: $e');
          print('Will mark day as completed locally anyway');
        }
        
        // Mark day as completed even if Firebase had issues
        setState(() {
          _isDayCompleted = true;
          _isCheckingCompletion = false;
        });
        
        // Always show success dialog, even if Firebase had issues
        _showCompletionDialog(stickerAwarded);
        widget.onComplete(); // Notify parent to refresh
        
      } catch (e) {
        print('Error completing day: $e');
        print('Stack trace: ${StackTrace.current}');
        setState(() {
          _isCheckingCompletion = false;
        });
        
        // Show error dialog with retry option
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('There was a problem completing the day. Would you like to try again?'),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${e.toString()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isCheckingCompletion = false;
                    });
                    _checkAndCompleteDayIfBothCompleted();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }
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
  
  void _showCompletionDialog([bool stickerAwarded = true]) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[850] 
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.amber,
            width: 2,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, color: Colors.amber),
            SizedBox(width: 10),
            Text('Congratulations!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 84,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[850]! 
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'You\'ve completed Day ${widget.content.day}!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            if (stickerAwarded)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'New Sticker Awarded!',
                      style: TextStyle(
                        color: Colors.amber[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Text(
                      'Day marked as completed',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        '24-Hour Timer Started',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.content.day < 30
                        ? 'Day ${widget.content.day + 1} will be unlocked after a 24-hour countdown.'
                        : 'You\'ve completed the entire meditation journey!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton.icon(
              icon: Icon(Icons.check_circle),
              label: Text('Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Return to journey screen automatically
                Navigator.of(context).pop(); // Return to journey screen
              },
            ),
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
                child: Text(
                  article.buttonText,
                  style: const TextStyle(
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
            audioScript: audio.audioScript,
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