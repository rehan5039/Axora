import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axora/models/custom_meditation.dart';
import 'package:axora/services/meditation_service.dart';
import 'package:axora/screens/custom_meditation_screen.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomMeditationListScreen extends StatefulWidget {
  const CustomMeditationListScreen({super.key});

  @override
  State<CustomMeditationListScreen> createState() => _CustomMeditationListScreenState();
}

class _CustomMeditationListScreenState extends State<CustomMeditationListScreen> {
  final _meditationService = MeditationService();
  List<int> _availableDurations = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadMeditations();
  }
  
  Future<void> _loadMeditations() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final durations = await _meditationService.getAvailableDurations();
      setState(() {
        _availableDurations = durations;
        _isLoading = false;
      });
      print('Available durations: $_availableDurations');
    } catch (e) {
      print('Error loading meditations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _navigateToDurationPage(int duration) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _DurationSpecificScreen(duration: duration),
      ),
    );
    
    // Refresh the list when coming back
    _loadMeditations();
    print('Main screen refreshed after returning from duration screen');
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Custom Meditations'),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableDurations.isEmpty
              ? const Center(
                  child: Text(
                    'No meditations available',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _availableDurations.length,
                  itemBuilder: (context, index) {
                    final duration = _availableDurations[index];
                    Color cardColor = isDarkMode
                        ? Colors.grey[850]!
                        : Colors.white;
                    
                    return GestureDetector(
                      onTap: () => _navigateToDurationPage(duration),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        color: cardColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$duration',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: _getDurationColor(duration),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'minutes',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
  
  Color _getDurationColor(int duration) {
    if (duration <= 5) return Colors.blue;
    if (duration <= 10) return Colors.green;
    if (duration <= 15) return Colors.orange;
    return Colors.purple;
  }
}

class _DurationSpecificScreen extends StatefulWidget {
  final int duration;
  
  const _DurationSpecificScreen({required this.duration});
  
  @override
  State<_DurationSpecificScreen> createState() => _DurationSpecificScreenState();
}

class _DurationSpecificScreenState extends State<_DurationSpecificScreen> {
  final _meditationService = MeditationService();
  List<CustomMeditation> _meditations = [];
  List<String> _completedMeditations = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadMeditations();
    _loadCompletionStatus();
  }
  
  Future<void> _loadMeditations() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final meditations = await _meditationService.getMeditationsByDuration(
        widget.duration,
      );
      setState(() {
        _meditations = meditations;
        _isLoading = false;
      });
      
      print('Loaded meditations: ${_meditations.length}');
    } catch (e) {
      print('Error loading meditations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadCompletionStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        setState(() {
          _completedMeditations = [];
        });
        return;
      }
      
      final userId = user.uid;
      final userProgressDoc = await FirebaseFirestore.instance
          .collection('user_meditation_progress')
          .doc(userId)
          .get();
      
      if (!userProgressDoc.exists) {
        print('No progress data for user');
        setState(() {
          _completedMeditations = [];
        });
        return;
      }
      
      final completedMeditations = List<String>.from(
          userProgressDoc.data()?['completed_meditations'] ?? []);
      
      print('Loaded completed meditations from Firebase: $completedMeditations');
      
      setState(() {
        _completedMeditations = completedMeditations;
      });
      
      // Sort the meditations with completed ones at the bottom
      _sortMeditations();
    } catch (e) {
      print('Error loading completion status: $e');
    }
  }
  
  void _sortMeditations() {
    // Sort so incomplete meditations appear first
    _meditations.sort((a, b) {
      final aCompleted = _completedMeditations.contains(a.id);
      final bCompleted = _completedMeditations.contains(b.id);
      
      if (aCompleted && !bCompleted) {
        return 1; // a goes after b
      } else if (!aCompleted && bCompleted) {
        return -1; // a goes before b
      } else {
        return 0; // maintain original order
      }
    });
    
    setState(() {});
  }
  
  Future<void> _openMeditationDetails(BuildContext context, CustomMeditation meditation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomMeditationScreen(meditation: meditation),
      ),
    );
    
    // Refresh completion status when returning from meditation screen
    await _loadCompletionStatus();
    print('Meditation list refreshed after returning from details');
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: Text('${widget.duration} Minute Meditations'),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadCompletionStatus();
              print('Manual refresh requested');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _meditations.isEmpty
              ? const Center(
                  child: Text(
                    'No meditations available for this duration',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _meditations.length,
                  itemBuilder: (context, index) {
                    final meditation = _meditations[index];
                    final isCompleted = _completedMeditations.contains(meditation.id);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        color: isCompleted
                            ? (isDarkMode ? Colors.grey[850]!.withOpacity(0.5) : Colors.grey[200])
                            : (isDarkMode ? Colors.grey[850] : Colors.white),
                        child: InkWell(
                          onTap: () => _openMeditationDetails(context, meditation),
                          borderRadius: BorderRadius.circular(12.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? Colors.green.withOpacity(0.8)
                                        : _getDurationColor(meditation.durationMinutes),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: isCompleted
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 28,
                                          )
                                        : Text(
                                            '${meditation.durationMinutes}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        meditation.title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          decoration: isCompleted
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                          color: isCompleted
                                              ? (isDarkMode ? Colors.grey[500] : Colors.grey[700])
                                              : (isDarkMode ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                      if (meditation.description.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            meditation.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isCompleted
                                                  ? (isDarkMode ? Colors.grey[600] : Colors.grey[600])
                                                  : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isCompleted
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isCompleted
                                        ? Colors.green
                                        : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    _openMeditationDetails(context, meditation);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
  
  Color _getDurationColor(int duration) {
    if (duration <= 5) return Colors.blue;
    if (duration <= 10) return Colors.green;
    if (duration <= 15) return Colors.orange;
    return Colors.purple;
  }
} 