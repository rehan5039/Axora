import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:axora/models/meditation.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomMeditationDetailScreen extends StatefulWidget {
  final CustomMeditation meditation;

  const CustomMeditationDetailScreen({Key? key, required this.meditation}) : super(key: key);

  @override
  _CustomMeditationDetailScreenState createState() => _CustomMeditationDetailScreenState();
}

class _CustomMeditationDetailScreenState extends State<CustomMeditationDetailScreen> {
  bool _isCompleted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkCompletionStatus();
  }

  Future<void> _checkCompletionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completedMeditations = prefs.getStringList('completed_meditations') ?? [];
    setState(() {
      _isCompleted = completedMeditations.contains(widget.meditation.id);
      _isLoading = false;
    });
  }

  Future<void> _toggleCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final completedMeditations = prefs.getStringList('completed_meditations') ?? [];
    
    setState(() {
      if (_isCompleted) {
        completedMeditations.remove(widget.meditation.id);
      } else {
        completedMeditations.add(widget.meditation.id);
      }
      _isCompleted = !_isCompleted;
    });
    
    await prefs.setStringList('completed_meditations', completedMeditations);
  }

  Color _getDurationColor(int duration) {
    switch (duration) {
      case 5:
        return Colors.green;
      case 10:
        return Colors.blue;
      case 15:
        return Colors.purple;
      case 30:
        return Colors.orange;
      default:
        return Colors.teal;
    }
  }

  String? get _audioUrl => widget.meditation.audio['url'] as String?;
  
  String? get _articleContent {
    if (widget.meditation.article != null) {
      return widget.meditation.article!['content'] as String?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final color = _getDurationColor(widget.meditation.durationMinutes);
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.meditation.title),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                color: _isCompleted ? Colors.green : (isDarkMode ? Colors.white60 : Colors.grey),
              ),
              onPressed: _toggleCompletion,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with duration badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer, size: 18, color: color),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.meditation.durationMinutes} minutes',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (_isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text(
                                      'Completed',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.meditation.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.meditation.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Enhanced Audio section
                  if (_audioUrl != null && _audioUrl!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.headphones,
                                color: color,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Audio Meditation',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Audio player controls
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              children: [
                                // Play/Pause button and title
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        // TODO: Implement actual audio playback
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Audio playback feature coming soon!'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: CircleAvatar(
                                        backgroundColor: color,
                                        radius: 24,
                                        child: const Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isDarkMode ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            'Guided Meditation',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDarkMode ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Audio controls
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.replay_10,
                                            color: color,
                                          ),
                                          onPressed: () {
                                            // TODO: Implement 10-second rewind
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.forward_10,
                                            color: color,
                                          ),
                                          onPressed: () {
                                            // TODO: Implement 10-second forward
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Progress bar (placeholder)
                                Column(
                                  children: [
                                    LinearProgressIndicator(
                                      value: 0.3, // Placeholder progress
                                      backgroundColor: Colors.grey.withOpacity(0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(color),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '2:30',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          '8:00',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Content section (markdown or html would be rendered here)
                  if (_articleContent != null && _articleContent!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Meditation Guide',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _articleContent ?? 'No content available',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Complete button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _toggleCompletion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCompleted ? Colors.grey : color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 