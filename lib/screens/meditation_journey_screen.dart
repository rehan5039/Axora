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

class MeditationJourneyScreen extends StatefulWidget {
  const MeditationJourneyScreen({super.key});

  @override
  State<MeditationJourneyScreen> createState() => _MeditationJourneyScreenState();
}

class _MeditationJourneyScreenState extends State<MeditationJourneyScreen> {
  final _meditationService = MeditationService();
  bool _isLoading = true;
  List<MeditationContent> _meditationContents = [];
  UserProgress? _userProgress;
  UserStickers? _userStickers;
  Timer? _unlockTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _unlockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading meditation journey data...');
      
      // Load user data first
      final progress = await _meditationService.getUserProgress();
      final stickers = await _meditationService.getUserStickers();
      
      print('User progress loaded: ${progress?.currentDay ?? 'null'}');
      print('Last completed day: ${progress?.lastCompletedDay ?? 'null'}');
      print('Completed days: ${progress?.completedDays?.join(', ') ?? 'none'}');
      print('User stickers loaded: ${stickers?.stickers ?? 'null'}');
      print('Stickers earned from days: ${stickers?.earnedFromDays?.join(', ') ?? 'none'}');
      
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
      if (_userProgress != null) {
        print('  Can unlock next day: ${_userProgress!.canUnlockNextDay()}');
        print('  Seconds until next unlock: ${_userProgress!.getSecondsUntilNextDayUnlocks()}');
        print('  Time remaining: ${_userProgress!.getFormattedTimeRemaining()}');
        print('  Current timer value: ${_timeRemaining.inSeconds} seconds');
      }
    } catch (e) {
      print('Error loading meditation journey data: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // Even on error, update UI state
      setState(() {
        _isLoading = false;
      });
      
      // Show error message to user
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
  
  void _updateUnlockTimer() {
    _unlockTimer?.cancel();
    
    // Only set up timer if we have user progress
    if (_userProgress == null) {
      print('Cannot update unlock timer - user progress is null');
      return;
    }
    
    // Calculate time until next day unlocks
    if (_userProgress!.lastCompletedDay > 0 && !_userProgress!.canUnlockNextDay()) {
      final now = Timestamp.now();
      final lastCompletedAt = _userProgress!.lastCompletedAt;
      final secondsSinceLastCompleted = now.seconds - lastCompletedAt.seconds;
      
      // 24 hours (86400 seconds) from last completion
      final remainingSeconds = 86400 - secondsSinceLastCompleted;
      
      if (remainingSeconds > 0) {
        print('Setting unlock timer for ${remainingSeconds} seconds');
        _timeRemaining = Duration(seconds: remainingSeconds.toInt());
        
        // Update timer every second
        _unlockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_timeRemaining.inSeconds <= 0) {
            print('Timer completed - cancelling timer and reloading data');
            timer.cancel();
            _loadData(); // Refresh data as new day is available
          } else {
            setState(() {
              _timeRemaining = Duration(seconds: _timeRemaining.inSeconds - 1);
            });
          }
        });
      } else {
        print('No time remaining for next unlock - can unlock now');
      }
    } else {
      print('No unlock timer needed - either no completed days or can already unlock next day');
    }
  }
  
  String get _formattedTimeRemaining {
    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes.remainder(60);
    final seconds = _timeRemaining.inSeconds.remainder(60);
    
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
                      if (_timeRemaining.inSeconds > 0)
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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Next Day Unlocks In:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formattedTimeRemaining,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
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
    
    final cardColor = isCompleted
        ? (isDarkMode ? Colors.green[900] : Colors.green[100])
        : (isDarkMode ? Colors.grey[800] : Colors.white);
    
    final article = ArticleContent.fromMap(content.article);
    final audio = AudioContent.fromMap(content.audio);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCurrentDay ? 4 : 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentDay 
            ? BorderSide(color: isDarkMode ? Colors.deepPurple : Colors.blue, width: 2)
            : BorderSide.none,
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
        ],
      ),
    );
  }
} 