import 'package:flutter/material.dart';
import 'package:axora/models/meditation_content.dart';
import 'package:axora/models/user_progress.dart';
import 'package:axora/models/user_stickers.dart';
import 'package:axora/services/meditation_service.dart';
import 'package:axora/screens/meditation_day_screen.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
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
      print('User stickers loaded: ${stickers?.stickers ?? 'null'}');
      
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
      return const Center(child: CircularProgressIndicator());
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
                  _buildStickerCounter(),
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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            color: Colors.amber,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            'Stickers: ${_userStickers?.stickers ?? 0}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
    
    final cardColor = isCompleted
        ? (isDarkMode ? Colors.green[900] : Colors.green[100])
        : (isDarkMode ? Colors.grey[800] : Colors.white);
    
    final article = ArticleContent.fromMap(content.article);
    final audio = AudioContent.fromMap(content.audio);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: cardColor,
      child: ListTile(
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
        leading: CircleAvatar(
          backgroundColor: isUnlocked
              ? (isDarkMode ? Colors.blue[700] : Colors.blue)
              : Colors.grey,
          child: isCompleted
              ? const Icon(Icons.star, color: Colors.amber)
              : Text('${content.day}'),
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
            Text(
              'Article: ${article.title}',
              style: TextStyle(
                color: isUnlocked
                    ? (isDarkMode ? Colors.white70 : Colors.black54)
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Audio: ${audio.title}',
              style: TextStyle(
                color: isUnlocked
                    ? (isDarkMode ? Colors.white70 : Colors.black54)
                    : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: isUnlocked
            ? const Icon(Icons.arrow_forward_ios)
            : const Icon(Icons.lock, color: Colors.grey),
      ),
    );
  }
} 