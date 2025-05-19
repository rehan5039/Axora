import 'package:flutter/material.dart';
import 'package:axora/models/meditation_content.dart';
import 'package:axora/services/meditation_service.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/widgets/custom_audio_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axora/services/stats_service.dart';
import 'package:axora/screens/flow_intro_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:axora/services/text_to_speech_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

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
  
  // Add variables to track current article page
  int _currentArticlePage = 0;
  late PageController _pageController;
  
  final TextToSpeechService _tts = TextToSpeechService();
  final Map<int, bool> _isSpeaking = {};
  
  // Check if the platform is Android
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();
    _checkCompletionStatus();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _tts.dispose();
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
        bool flowAwarded = false;
        
        try {
          // Try to complete the day in Firebase
          dayCompleted = await _meditationService.checkAndCompleteDayIfBothCompleted(widget.content.id);
          print('Completion check result: $dayCompleted');
          
          if (dayCompleted) {
            print('Day ${widget.content.day} marked as completed! Flow should be awarded.');
            
            // Verify if flow was awarded
            final flow = await _meditationService.getUserFlow();
            flowAwarded = flow?.hasFlowForDay(widget.content.day) ?? false;
            print('User now has ${flow?.flow ?? 0} flow');
            print('Flow for day ${widget.content.day} exists: $flowAwarded');
            
            // Update streak count when a day is completed and flow awarded
            if (flowAwarded) {
              try {
                final statsService = StatsService();
                // First get existing stats
                final userStats = await statsService.getUserStats();
                if (userStats != null) {
                  // Increment streak by 1 if this is a new day completion
                  final newStreak = userStats.currentStreak + 1;
                  final newLongestStreak = newStreak > userStats.longestStreak 
                      ? newStreak 
                      : userStats.longestStreak;
                  
                  // Update the streak stats
                  await statsService.updateStreakForDayCompletion(
                    newStreak, 
                    newLongestStreak,
                    dayNumber: widget.content.day
                  );
                  print('Updated user streak to $newStreak (day ${widget.content.day} completion)');
                }
              } catch (e) {
                print('Error updating streak for day completion: $e');
                // Don't block the main flow if streak update fails
              }
            }
            
            // If flow was not awarded, try to directly add it
            if (!flowAwarded && flow != null) {
              print('WARNING: Flow was not awarded automatically. Trying to add it directly...');
              await _meditationService.addFlowForDay(widget.content.day);
              
              // Verify again
              final verifyFlow = await _meditationService.getUserFlow();
              flowAwarded = verifyFlow?.hasFlowForDay(widget.content.day) ?? false;
              print('After direct add, user has ${verifyFlow?.flow ?? 0} flow');
              print('Flow for day ${widget.content.day} exists: $flowAwarded');
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
        
        // Show Great Job dialog when completed
        if (mounted) {
          // Show the dialog and wait for user confirmation
          _showGreatJobDialog();
          // Calling widget.onComplete() here actually updates the parent widget
          // without dismissing the current screen
          widget.onComplete();
        }
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
        
        // Make sure the Great Job dialog is displayed
        if (mounted && _isDayCompleted) {
          _showGreatJobDialog();
        }
        
        // Don't automatically navigate back - let the user click OK on the dialog
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
      
      // Update statistics - add meditation minutes
      final audioContent = AudioContent.fromMap(widget.content.audio);
      final durationInMinutes = (audioContent.durationInSeconds / 60).ceil(); // Round up to nearest minute
      
      try {
        final statsService = StatsService();
        await statsService.updateSessionCompletion(
          durationInMinutes,
          contentId: widget.content.id,
        );
        print('Updated meditation statistics: added $durationInMinutes minutes');
      } catch (e) {
        print('Error updating meditation statistics: $e');
        // Don't block the main flow if statistics update fails
      }
      
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
        
        // Make sure the Great Job dialog is displayed
        if (mounted && _isDayCompleted) {
          _showGreatJobDialog();
        }
        
        // Don't automatically navigate back - let the user click OK on the dialog
      }
    } catch (e) {
      print('Error marking audio as completed: $e');
      setState(() {
        _isAudioCompleted = false;
      });
    }
  }
  
  void _showCompletionDialog([bool flowAwarded = true]) {
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
            Image.asset(
              'assets/images/flow_icon.png',
              width: 24,
              height: 24,
              color: Colors.amber,
            ),
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
                Image.asset(
                  'assets/images/flow_icon.png',
                  width: 84,
                  height: 84,
                  color: Colors.amber,
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
            if (flowAwarded)
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
                    Image.asset(
                      'assets/images/flow_icon.png',
                      width: 24,
                      height: 24,
                      color: Colors.amber,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'New Flow Awarded!',
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
                
                // Show the "Great Job Today!" dialog after closing the completion dialog
                Future.delayed(Duration(milliseconds: 300), () {
                  if (mounted) {
                    _showGreatJobDialog();
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _showGreatJobDialog() {
    print('Showing Great Job dialog for day ${widget.content.day}');
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Ensure that this is called when the widget is properly mounted
    if (!mounted) {
      print('Not showing Great Job dialog - widget not mounted');
      return;
    }
    
    // Add a small delay to ensure layout is complete before showing dialog
    Future.delayed(Duration(milliseconds: 100), () {
      // Check if this is Day 1 completion - show Flow Intro instead
      if (widget.content.day == 1) {
        print('Day 1 completed - showing Flow Intro');
        
        // Make sure we don't show multiple dialogs
        if (ModalRoute.of(context)?.isCurrent != true) {
          print('Not showing Flow Intro - route is not current');
          return;
        }
        
        // Show Flow Intro screen with a slight delay to ensure rendering is complete
        print('Displaying Flow Intro Screen');
        Future.delayed(Duration(milliseconds: 150), () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const FlowIntroScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeOutQuint;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          ).then((_) {
            print('Flow Intro closed');
            // After intro is closed, mark flow intro as shown
            _markFlowIntroAsShown();
            
            // Return to journey screen after a brief delay
            Future.delayed(Duration(milliseconds: 100), () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          });
        });
        
        // Don't show the Great Job dialog for Day 1, just show the Flow Intro
        return;
      }
      
      // For other days, show the Great Job dialog
      
      // Prevent showing multiple dialogs
      if (ModalRoute.of(context)?.isCurrent != true) {
        print('Not showing Great Job dialog - route is not current');
        return;
      }
      
      // Show a dialog that won't auto-dismiss
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismiss by tapping outside
        builder: (context) {
          return WillPopScope(
            // Prevent dialog from being dismissed with back button
            onWillPop: () async => false,
            child: TweenAnimationBuilder(
              // Add attention-grabbing animation
              duration: Duration(milliseconds: 500),
              tween: Tween<double>(begin: 0.8, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                elevation: 10,
                backgroundColor: isDarkMode ? Color(0xFF2D2D3A) : Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Add an attention-grabbing celebration icon at the top
                      TweenAnimationBuilder(
                        duration: Duration(milliseconds: 800),
                        tween: Tween<double>(begin: 0.5, end: 1.0),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Icon(
                          Icons.celebration,
                          size: 60,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Great Job Today!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'You\'ve completed today\'s meditation journey.',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Take this time to reflect and recharge.',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Come back tomorrow for your next step.',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      // Animate the button to draw attention
                      TweenAnimationBuilder(
                        duration: Duration(milliseconds: 1000),
                        tween: ColorTween(
                          begin: Colors.grey,
                          end: isDarkMode ? Colors.deepPurple : Colors.blue,
                        ),
                        builder: (context, Color? color, child) {
                          return ElevatedButton(
                            onPressed: () {
                              // Only pop once to close this dialog
                              // Do not automatically return to journey screen
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'OK',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ).then((_) {
        // After dialog is closed, we can return to journey screen with a delay
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            print('Great Job dialog closed, returning to journey screen');
            Navigator.of(context).pop();
          }
        });
      });
    });
  }

  // Helper method to mark that we've shown the Flow intro
  Future<void> _markFlowIntroAsShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('shown_flow_intro', true);
      print('Flow intro marked as shown');
    } catch (e) {
      print('Error marking flow intro as shown: $e');
    }
  }

  // Helper method to check if we've already shown the Flow intro
  Future<bool> _hasShownFlowIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('shown_flow_intro') ?? false;
    } catch (e) {
      print('Error checking if flow intro was shown: $e');
      return false;
    }
  }

  void _toggleSpeech(int pageIndex, String title, String content) {
    if (_isSpeaking[pageIndex] == true) {
      _tts.stop();
      setState(() {
        _isSpeaking.clear();
      });
    } else {
      // Stop any currently playing speech
      _tts.stop();
      setState(() {
        _isSpeaking.clear();
        _isSpeaking[pageIndex] = true;
      });
      
      // Combine title and content for reading
      final textToRead = "$title. $content";
      _tts.speak(textToRead);
      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking[pageIndex] = false;
          });
        }
      });
    }
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
    final pages = widget.content.getAllPages();
    final totalPages = pages.length;
    
    return Column(
      children: [
        // Page indicators
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < totalPages; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 8,
                      width: _currentArticlePage == i ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentArticlePage == i 
                            ? (isDarkMode ? Colors.deepPurple : Colors.blue)
                            : Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        
        // Current page content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalPages,
            onPageChanged: (index) {
              setState(() {
                _currentArticlePage = index;
              });
            },
            itemBuilder: (context, index) {
              final page = pages[index];
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            page.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        // Only show TTS button on Android
                        if (_isAndroid)
                          IconButton(
                            onPressed: () => _toggleSpeech(index, page.title, page.content),
                            icon: Icon(
                              _isSpeaking[index] == true ? Icons.volume_up : Icons.volume_up_outlined,
                              color: _isSpeaking[index] == true ? (isDarkMode ? Colors.deepPurple : Colors.blue) : Colors.grey,
                              size: 28,
                            ),
                            tooltip: _isSpeaking[index] == true ? 'Stop Reading' : 'Read Article',
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      page.content,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Bottom navigation for pages - fixed alignment
                    if (totalPages > 1 && index > 0)
                      // Show back and next/complete buttons on middle/last pages
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back button
                          OutlinedButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back'),
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                          
                          // Next or complete button
                          if (index < totalPages - 1)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_forward),
                              label: Text(page.buttonText.isNotEmpty ? page.buttonText : 'Next'),
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            )
                          else
                            ElevatedButton.icon(
                              icon: Icon(_isArticleCompleted ? Icons.check : Icons.check_circle_outline),
                              label: Text(_isArticleCompleted 
                                  ? 'Completed' 
                                  : (page.buttonText.isNotEmpty ? page.buttonText : 'Mark as Read')),
                              onPressed: _isArticleCompleted ? null : _markArticleAsCompleted,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isArticleCompleted 
                                    ? Colors.green 
                                    : (isDarkMode ? Colors.deepPurple : Colors.blue),
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      )
                    else if (totalPages > 1)
                      // First page of multi-page article - only show "Next" button centered
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(page.buttonText.isNotEmpty ? page.buttonText : 'Continue'),
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? Colors.deepPurple : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                      )
                    else
                      // Single page article - centered "Mark as Read" button
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(_isArticleCompleted ? Icons.check : Icons.check_circle_outline),
                          label: Text(_isArticleCompleted 
                              ? 'Completed' 
                              : (page.buttonText.isNotEmpty ? page.buttonText : 'Mark as Read')),
                          onPressed: _isArticleCompleted ? null : _markArticleAsCompleted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isArticleCompleted 
                                ? Colors.green 
                                : (isDarkMode ? Colors.deepPurple : Colors.blue),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
                imageUrl: 'https://firebasestorage.googleapis.com/v0/b/axora-we.appspot.com/o/meditation_images%2Fday${widget.content.day}.jpg?alt=media',
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