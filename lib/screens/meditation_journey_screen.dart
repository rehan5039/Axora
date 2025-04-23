import 'dart:async';
import 'package:flutter/material.dart';
import 'package:axora/models/meditation_content.dart';
import 'package:axora/models/user_progress.dart';
import 'package:axora/models/user_stickers.dart';
import 'package:axora/services/meditation_service.dart';
import 'package:axora/screens/meditation_day_screen.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MeditationJourneyScreen extends StatefulWidget {
  const MeditationJourneyScreen({super.key});

  @override
  State<MeditationJourneyScreen> createState() => _MeditationJourneyScreenState();
}

class _MeditationJourneyScreenState extends State<MeditationJourneyScreen> with WidgetsBindingObserver {
  final _meditationService = MeditationService();
  bool _isLoading = true;
  List<MeditationContent> _meditationContents = [];
  UserProgress? _userProgress;
  UserStickers? _userStickers;
  Timer? _unlockTimer;
  Duration _timeRemaining = Duration.zero;
  bool _isSyncingWithServer = false;
  String? _syncError;
  DateTime? _lastCompletedAt;
  int _currentDay = 1;
  bool _canUnlockNextDay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }
  
  @override
  void dispose() {
    _unlockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for expired timers each time the screen becomes visible
    _checkForExpiredTimersOnLoad();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App was resumed from background, sync with server
      print('App resumed, syncing with server...');
      _syncWithServerAndUnlockNextDay();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading meditation journey data...');
      
      // Fix any issues with the unlock time field
      await _meditationService.fixUnlockTimeField();
      
      // Load user data first
      final progress = await _meditationService.getUserProgress();
      final stickers = await _meditationService.getUserStickers();
      
      print('User progress loaded: ${progress?.currentDay ?? 'null'}');
      if (progress != null) {
        print('Last completed day: ${progress.lastCompletedDay}');
        print('Last completed at: ${progress.lastCompletedAt.toDate()}');
        print('Hours since last completed: ${progress.hoursSinceLastCompletion()}');
        print('Completed days: ${progress.completedDays.join(', ')}');
        
        // Always check if we need to display a timer after completing a day
        if (progress.lastCompletedDay > 0 || (stickers != null && stickers.stickers > 0)) {
          // Always calculate remaining time, even if canUnlockNextDay is true
          // This ensures we show 0:00:00 when the timer expires
          final remainingSeconds = progress.getSecondsUntilNextDayUnlocks();
          _timeRemaining = Duration(seconds: remainingSeconds);
          print('Time remaining for next day: $_timeRemaining');
          
          final canUnlock = progress.canUnlockNextDay();
          print('Can unlock next day: $canUnlock');
          
          if (canUnlock) {
            print('Timer has expired, checking with server...');
            await _meditationService.updateCurrentDayIfTimerExpired();
            // Reload progress after update
            final updatedProgress = await _meditationService.getUserProgress();
            if (updatedProgress != null) {
              setState(() {
                _userProgress = updatedProgress;
              });
            }
          } else {
            // Get time remaining from the server
            final serverUnlockTime = await _meditationService.getNextDayUnlockTime();
            final now = Timestamp.now();
            final remainingSeconds = serverUnlockTime.seconds - now.seconds;
            
            if (remainingSeconds > 0) {
              print('Setting time remaining from server: $remainingSeconds seconds');
              setState(() {
                _timeRemaining = Duration(seconds: remainingSeconds);
              });
            }
          }
        }
      }
      
      // Load meditation content
      var contents = await _meditationService.getAllMeditationContent();
      
      // Sort contents by day number
      contents.sort((a, b) => a.day.compareTo(b.day));
      
      print('Meditation contents loaded: ${contents.length} items');
      
      // If no content is found, and we're in debug mode, create a default day 1 content
      if (contents.isEmpty) {
        print('No meditation content found in Firestore, creating fallback content...');
        
        // Add a fallback content for day 1 for testing/debugging
        await _createFallbackContent();
        
        // Try loading again
        contents = await _meditationService.getAllMeditationContent();
        contents.sort((a, b) => a.day.compareTo(b.day));
        print('After fallback creation, loaded ${contents.length} items');
      }

      setState(() {
        _meditationContents = contents;
        _userProgress = progress;
        _userStickers = stickers;
        _isLoading = false;
      });
      
      // Setup timer for next day unlock if needed
      _updateUnlockTimer();
      
      // Debug the unlock timer status
      print('Unlock timer status:');
      if (_timeRemaining.inSeconds > 0) {
        print('Time remaining: ${_formattedTimeRemaining}');
        if (progress != null) {
          final unlockDateTime = progress.lastCompletedAt.toDate().add(Duration(hours: 24));
          print('Next day will unlock at: $unlockDateTime');
        }
      } else if (progress != null && progress.lastCompletedDay > 0) {
        print('Timer has expired - next day can be unlocked');
        
        // If timer has expired but still showing 0, make sure the UI shows something
        final nextDay = progress.lastCompletedDay + 1;
        print('Next day to unlock: $nextDay');
      } else {
        print('No active timer or next day already unlocked');
      }
    } catch (e) {
      print('Error loading meditation journey data: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load meditation content: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }
  
  Future<void> _syncWithServerAndUnlockNextDay() async {
    if (_isSyncingWithServer) return;
    
    setState(() {
      _isSyncingWithServer = true;
      _syncError = null;
    });
    
    try {
      print('Starting sync with server...');
      final meditationProgress = await _meditationService.getUserProgress();
      final userStickers = await _meditationService.getUserStickers();
      
      if (meditationProgress == null) {
        print('No meditation progress found during sync.');
        setState(() {
          _isSyncingWithServer = false;
          _syncError = 'Could not retrieve your meditation progress.';
        });
        return;
      }
      
      print('Got meditation progress - current day: ${meditationProgress.currentDay}');
      print('Last completed at: ${meditationProgress.lastCompletedAt?.toDate()}');
      print('User has ${userStickers?.stickers ?? 0} stickers');

      // Always update the UI with the latest progress
      setState(() {
        _currentDay = meditationProgress.currentDay;
        _lastCompletedAt = meditationProgress.lastCompletedAt?.toDate();
        _userStickers = userStickers;
      });
      
      // Check if user has completed a day based on stickers but it's not reflected in progress
      final hasCompletedBasedOnStickers = (userStickers?.stickers ?? 0) > 0;
      final hasCompletedBasedOnProgress = meditationProgress.lastCompletedDay > 0;
      
      // Calculate time since last completion
      final now = DateTime.now();
      if (_lastCompletedAt != null && (hasCompletedBasedOnProgress || hasCompletedBasedOnStickers)) {
        final difference = now.difference(_lastCompletedAt!);
        
        // Check if 24 hours have passed and if we need to unlock the next day
        if (difference.inHours >= 24) {
          print('24 hours have passed. Forcing unlock of next day...');
          
          // Explicitly call the method to update current day if the timer expired
          final unlockResult = await _meditationService.updateCurrentDayIfTimerExpired();
          print('Auto-unlock result: $unlockResult');
          
          // Reload progress after update
          final updatedProgress = await _meditationService.getUserProgress();
          if (updatedProgress != null) {
            setState(() {
              _userProgress = updatedProgress;
              _currentDay = updatedProgress.currentDay;
              _canUnlockNextDay = true;
              _timeRemaining = Duration.zero;
            });
            print('Updated current day to: ${updatedProgress.currentDay}');
          }
        } else {
          // Update the timer - remaining time until 24 hours
          _canUnlockNextDay = false;
          _timeRemaining = Duration(hours: 24) - difference;
          print('Time remaining: ${_timeRemaining.inHours}h ${_timeRemaining.inMinutes % 60}m');
          
          // Start or restart the timer
          _updateUnlockTimer();
        }
      } else if (_currentDay == 1 && !hasCompletedBasedOnStickers) {
        // First day, no waiting required
        _canUnlockNextDay = true;
        _timeRemaining = Duration.zero;
        _unlockTimer?.cancel();
      }
      
      // Make sure we always update the UI after syncing
      setState(() {
        _isLoading = false;
        _isSyncingWithServer = false;
      });
      
    } catch (e) {
      print('Error during sync: $e');
      setState(() {
        _isSyncingWithServer = false;
        _syncError = 'Failed to sync: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _updateUnlockTimer() {
    // Cancel any existing timer
    _unlockTimer?.cancel();
    
    // Only start a new timer if there's time remaining
    if (_timeRemaining > Duration.zero) {
      print('Starting timer with remaining time: ${_timeRemaining.inSeconds} seconds');
      
      // Update once a second
      _unlockTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
        if (_timeRemaining <= Duration.zero) {
          print('Timer completed! Unlocking next day...');
          timer.cancel();
          
          // First, explicitly try to update the current day
          final unlockResult = await _meditationService.updateCurrentDayIfTimerExpired();
          print('Timer expired auto-unlock result: $unlockResult');
          
          // Then reload updated progress
          final updatedProgress = await _meditationService.getUserProgress();
          
          setState(() {
            _canUnlockNextDay = true;
            _timeRemaining = Duration.zero;
            if (updatedProgress != null) {
              _userProgress = updatedProgress;
              _currentDay = updatedProgress.currentDay;
            }
          });
          
          // Re-sync with server to confirm unlock
          _syncWithServerAndUnlockNextDay();
        } else {
          setState(() {
            _timeRemaining = _timeRemaining - Duration(seconds: 1);
          });
        }
      });
    }
  }

  String get _formattedTimeRemaining {
    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes.remainder(60);
    final seconds = _timeRemaining.inSeconds.remainder(60);
    
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }

  // Create fallback content for testing/debugging
  Future<void> _createFallbackContent() async {
    try {
      print('Creating fallback meditation content for Day 1...');
      
      // Create basic article content
      final article = ArticleContent(
        title: 'Introduction to Mindfulness',
        content: 'Mindfulness is the practice of being fully present and engaged in the moment, '
            'aware of your thoughts and feelings without distraction or judgment. '
            'This practice has been shown to reduce stress and improve overall well-being. '
            'In this first session, we will focus on breath awareness, the foundation of meditation practice.',
      );
      
      // Create basic audio content
      final audio = AudioContent(
        title: 'Breath Awareness Meditation',
        url: 'https://firebasestorage.googleapis.com/v0/b/axora-5039.appspot.com/o/meditation_audios%2Fday1.mp3?alt=media',
        durationInSeconds: 300, // 5 minutes
      );
      
      // Try adding with explicit document ID first (matching what we see in Firebase console)
      bool success = await _meditationService.addMeditationContentWithId(
        day: 1,
        title: 'Breath Awareness',
        article: article,
        audio: audio,
        documentId: 'Day-1', // Matches the document ID seen in Firebase console
      );
      
      // If that fails, try the regular method
      if (!success) {
        success = await _meditationService.addMeditationContent(
          day: 1,
          title: 'Breath Awareness',
          article: article,
          audio: audio,
        );
      }
      
      print('Fallback content creation result: ${success ? 'Success' : 'Failed'}');
    } catch (e) {
      print('Error creating fallback content: $e');
    }
  }

  Future<void> _checkForExpiredTimersOnLoad() async {
    // Skip if we're already loading data
    if (_isLoading) return;
    
    try {
      final progress = await _meditationService.getUserProgress();
      if (progress != null && progress.canUnlockNextDay()) {
        print('Found expired timer on screen load - attempting to unlock next day');
        final result = await _meditationService.updateCurrentDayIfTimerExpired();
        if (result) {
          print('Successfully unlocked next day on screen load');
          _loadData(); // Reload to show updated state
        }
      }
    } catch (e) {
      print('Error checking for expired timers on load: $e');
    }
  }

  Future<void> _directlyForceUnlockDay(int day) async {
    print('Emergency direct unlock for day $day');
    
    try {
      // Get user progress and stickers
      final progress = await _meditationService.getUserProgress();
      final stickers = await _userStickers;
      
      if (progress != null) {
        // Create updates
        Map<String, dynamic> updates = {
          'currentDay': day,
          'timeUnlocked': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp()
        };
        
        // If this is day 2 and we have a sticker for day 1, fix lastCompletedDay
        if (day == 2 && stickers != null && stickers.stickers > 0) {
          updates['lastCompletedDay'] = 1;
        }
        
        // Direct update to database
        await FirebaseFirestore.instance
            .collection('meditation_progress')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update(updates);
        
        print('Emergency direct update successful!');
        
        // Refresh data
        await _loadData();
        setState(() {
          _currentDay = day; // Force update UI
        });
      }
    } catch (e) {
      print('Error in emergency unlock: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textStyle = TextStyle(
      color: isDarkMode ? Colors.white : Colors.black87,
      fontSize: 16,
    );
    final headingStyle = TextStyle(
      color: isDarkMode ? Colors.white : Colors.black87,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meditation Journey'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meditation Journey'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meditation Journey',
                    style: headingStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete each day to unlock the next one. Read the article and listen to the meditation to earn stickers.',
                    style: textStyle,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStickerCounter(),
                      // Only show timer if we have completed a day or timer is running
                      if (_userProgress != null && ((_userProgress!.lastCompletedDay > 0) || 
                          _timeRemaining.inSeconds > 0 || 
                          (_userStickers != null && _userStickers!.stickers > 0)))
                        _buildNextDayTimer(),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _meditationContents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No meditation content available yet.\nCheck back soon!',
                          textAlign: TextAlign.center,
                          style: textStyle,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Refreshing meditation content...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Loading Content'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _meditationContents.length,
                    itemBuilder: (context, index) {
                      final content = _meditationContents[index];
                      return _buildDayCard(content);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerCounter() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final stickersCount = _userStickers?.stickers ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.amber,
          width: stickersCount > 0 ? 2 : 0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.star,
                color: Colors.amber,
                size: 30,
              ),
              if (stickersCount > 0)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stickers',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                stickersCount.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: stickersCount > 0 ? Colors.amber : (isDarkMode ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextDayTimer() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Check if we have any stickers (completed days)
    final hasCompletedAnyDay = (_userProgress?.lastCompletedDay ?? 0) > 0 || 
                              (_userStickers != null && _userStickers!.stickers > 0);
    
    // Determine the next day to unlock
    int nextDayNumber;
    if (_userStickers != null && _userStickers!.stickers > 0) {
      // If we have stickers, use that count + 1 as the next day
      nextDayNumber = _userStickers!.stickers + 1;
    } else {
      // Otherwise fall back to the lastCompletedDay + 1
      nextDayNumber = (_userProgress?.lastCompletedDay ?? 0) + 1;
    }
    
    // If nextDayNumber is still 1, make it 2 if we have stickers
    if (nextDayNumber == 1 && _userStickers != null && _userStickers!.stickers > 0) {
      nextDayNumber = 2;
    }
    
    final canUnlock = _userProgress?.canUnlockNextDay() ?? false;
    final isTimeOver = _timeRemaining.inSeconds <= 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isTimeOver ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTimeOver ? Icons.check_circle : Icons.timer,
            color: isTimeOver ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasCompletedAnyDay 
                  ? 'Day $nextDayNumber ${isTimeOver ? "Ready!" : "Unlocks In:"}' 
                  : 'Complete Day 1 First',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    _formattedTimeRemaining,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isTimeOver ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // Show a message to the user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isTimeOver 
                            ? 'Refreshing to unlock Day $nextDayNumber...' 
                            : 'Syncing time remaining...'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      _syncWithServerAndUnlockNextDay();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        isTimeOver ? Icons.refresh : Icons.sync,
                        size: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(MeditationContent content) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final currentDay = _userProgress?.currentDay ?? 1;
    final isCompleted = _userStickers?.hasStickerForDay(content.day) ?? false;
    final isUnlocked = content.day <= currentDay;
    final isCurrentDay = content.day == currentDay;
    final isReadyToUnlock = content.day == currentDay + 1 && _canUnlockNextDay;
    
    final cardColor = isCompleted
        ? (isDarkMode ? Colors.green[900] : Colors.green[100])
        : (isDarkMode ? Colors.grey[800] : Colors.white);
    
    final article = ArticleContent.fromMap(content.article);
    final audio = AudioContent.fromMap(content.audio);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCurrentDay ? 4 : (isReadyToUnlock ? 3 : 2),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentDay 
            ? BorderSide(color: isDarkMode ? Colors.deepPurple : Colors.blue, width: 2)
            : (isReadyToUnlock 
                ? BorderSide(color: Colors.green, width: 2)
                : BorderSide.none),
      ),
      child: Stack(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            onTap: isUnlocked
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MeditationDayScreen(
                          content: content,
                          onComplete: _loadData,
                        ),
                      ),
                    );
                  }
                : content.day == currentDay + 1 && _canUnlockNextDay
                    ? () async {
                        // Try to unlock this day before opening
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Unlocking Day ${content.day}...'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        
                        // Force unlock the next day
                        try {
                          // First try to force update the database directly
                          final progress = await _meditationService.getUserProgress();
                          if (progress != null && progress.lastCompletedDay > 0) {
                            final nextDay = progress.lastCompletedDay + 1;
                            if (content.day == nextDay) {
                              // This is the correct next day to unlock - force it
                              print('Attempting to force Day $nextDay to unlock...');
                              
                              // Try the dedicated force unlock method first
                              final forceResult = await _meditationService.forceUnlockDay(nextDay);
                              if (forceResult) {
                                print('Successfully forced Day $nextDay to unlock with direct method');
                                
                                // Reload data immediately
                                await _loadData();
                                
                                // Now it should be unlocked, open the day
                                if (mounted) {
                                  // Open the day content
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MeditationDayScreen(
                                        content: content,
                                        onComplete: _loadData,
                                      ),
                                    ),
                                  );
                                  return; // Exit early, we've handled it
                                }
                              } else {
                                // If dedicated method fails, try the regular unlock method multiple times
                                bool success = false;
                                for (int i = 0; i < 3; i++) {
                                  final unlockResult = await _meditationService.updateCurrentDayIfTimerExpired();
                                  if (unlockResult) {
                                    success = true;
                                    break;
                                  }
                                  await Future.delayed(Duration(milliseconds: 300));
                                }
                                
                                if (success) {
                                  print('Successfully forced Day $nextDay to unlock after multiple attempts');
                                  
                                  // Reload data immediately
                                  await _loadData();
                                  
                                  // Now it should be unlocked, open the day
                                  if (mounted) {
                                    // Open the day content
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MeditationDayScreen(
                                          content: content,
                                          onComplete: _loadData,
                                        ),
                                      ),
                                    );
                                    return; // Exit early, we've handled it
                                  }
                                }
                              }
                            }
                          }
                          
                          // EMERGENCY: If all normal unlock methods failed, try direct database update
                          print('All normal unlock methods failed. Attempting emergency direct unlock for day ${content.day}');
                          await _directlyForceUnlockDay(content.day);
                          
                          // Reload data immediately
                          await _loadData();
                          
                          // Now it should be unlocked, open the day
                          if (mounted) {
                            // Open the day content
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MeditationDayScreen(
                                  content: content,
                                  onComplete: _loadData,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error during day unlock: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error unlocking day: ${e.toString()}'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      }
                    : null,
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: isUnlocked
                      ? (isDarkMode ? Colors.blue[700] : Colors.blue)
                      : Colors.grey,
                  child: isCompleted
                      ? const Icon(Icons.star, color: Colors.amber)
                      : Text('${content.day}'),
                ),
                if (isCompleted)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[800]! : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              content.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isUnlocked
                    ? (isDarkMode ? Colors.white : Colors.black87)
                    : Colors.grey,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.article,
                      size: 14,
                      color: isUnlocked
                          ? (isDarkMode ? Colors.white70 : Colors.black54)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Article: ${article.title}',
                        style: TextStyle(
                          color: isUnlocked
                              ? (isDarkMode ? Colors.white70 : Colors.black54)
                              : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.headphones,
                      size: 14,
                      color: isUnlocked
                          ? (isDarkMode ? Colors.white70 : Colors.black54)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Audio: ${audio.title}',
                        style: TextStyle(
                          color: isUnlocked
                              ? (isDarkMode ? Colors.white70 : Colors.black54)
                              : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: isUnlocked
                ? Icon(
                    isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
                    color: isCompleted ? Colors.green : null,
                  )
                : isReadyToUnlock
                    ? Icon(Icons.lock_open, color: Colors.green)
                    : const Icon(Icons.lock, color: Colors.grey),
          ),
          if (isCurrentDay)
            Positioned(
              top: 0,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.deepPurple : Colors.blue,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: const Text(
                  'TODAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (isReadyToUnlock)
            Positioned(
              top: 0,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: const Text(
                  'READY!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 