import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axora/models/custom_meditation.dart';
import 'package:axora/services/meditation_service.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';

class AdminCustomMeditationScreen extends StatefulWidget {
  const AdminCustomMeditationScreen({super.key});

  @override
  State<AdminCustomMeditationScreen> createState() => _AdminCustomMeditationScreenState();
}

class _AdminCustomMeditationScreenState extends State<AdminCustomMeditationScreen> {
  final _meditationService = MeditationService();
  bool _isLoading = true;
  bool _isAdmin = false;
  Map<int, List<CustomMeditation>> _meditationsByDuration = {};
  
  // Standard duration categories
  final List<int> _durationCategories = [5, 10, 15, 30];
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _audioTitleController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _audioScriptController = TextEditingController();
  final _articleTitleController = TextEditingController();
  final _articleContentController = TextEditingController();
  
  String? _selectedMeditationId;
  bool _formIsActive = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _audioTitleController.dispose();
    _audioUrlController.dispose();
    _audioScriptController.dispose();
    _articleTitleController.dispose();
    _articleContentController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isAdmin = await _meditationService.isAdmin();
      
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
        });
      }

      if (!isAdmin && mounted) {
        // If not admin, show error and pop back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to access this page'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
        return;
      }
      
      // Load all meditations
      await _loadMeditations();
    } catch (e) {
      print('Error checking admin status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop();
      }
    }
  }
  
  Future<void> _loadMeditations() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('Loading all custom meditations for admin view...');
      // Get all custom meditations without filtering or ordering in the query
      final querySnapshot = await FirebaseFirestore.instance
          .collection('custom_meditation')
          .get();
      
      print('Found ${querySnapshot.docs.length} meditation documents in admin view');
      final meditations = querySnapshot.docs
          .map((doc) => CustomMeditation.fromFirestore(doc))
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort in memory
      
      print('Parsed ${meditations.length} meditation objects for admin');
      
      // Group meditations by duration
      final Map<int, List<CustomMeditation>> grouped = {};
      
      // Initialize the map with empty lists for each standard duration
      for (var duration in _durationCategories) {
        grouped[duration] = [];
      }
      
      // Add meditations to their respective duration groups
      for (var meditation in meditations) {
        if (grouped.containsKey(meditation.durationMinutes)) {
          grouped[meditation.durationMinutes]!.add(meditation);
          print('Added meditation "${meditation.title}" to ${meditation.durationMinutes} minutes group (admin)');
        } else {
          // Handle non-standard durations by adding them to the map
          grouped[meditation.durationMinutes] = [meditation];
          print('Created new group for ${meditation.durationMinutes} minutes with meditation "${meditation.title}" (admin)');
        }
      }
      
      // Debug print the grouped meditations
      for (var entry in grouped.entries) {
        print('Admin view: Duration ${entry.key} minutes has ${entry.value.length} meditations');
      }
      
      setState(() {
        _meditationsByDuration = grouped;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading custom meditations for admin: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading meditations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _durationController.clear();
    _audioTitleController.clear();
    _audioUrlController.clear();
    _audioScriptController.clear();
    _articleTitleController.clear();
    _articleContentController.clear();
    setState(() {
      _selectedMeditationId = null;
      _formIsActive = true;
    });
  }
  
  void _loadMeditationForEdit(CustomMeditation meditation) {
    _titleController.text = meditation.title;
    _descriptionController.text = meditation.description;
    _durationController.text = meditation.durationMinutes.toString();
    
    // Audio data
    final audioData = meditation.audio;
    _audioTitleController.text = audioData['title'] as String? ?? '';
    _audioUrlController.text = audioData['url'] as String? ?? '';
    _audioScriptController.text = audioData['audio-script'] as String? ?? '';
    
    // Article data
    final articleData = meditation.article;
    _articleTitleController.text = articleData['title'] as String? ?? '';
    _articleContentController.text = articleData['content'] as String? ?? '';
    
    setState(() {
      _selectedMeditationId = meditation.id;
      _formIsActive = meditation.isActive;
    });
  }
  
  Future<void> _saveMeditation() async {
    // Validate form
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _durationController.text.isEmpty ||
        _audioTitleController.text.isEmpty ||
        _audioUrlController.text.isEmpty ||
        _articleTitleController.text.isEmpty ||
        _articleContentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Parse duration
    final durationMinutes = int.tryParse(_durationController.text);
    if (durationMinutes == null || durationMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid duration'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Create audio and article objects
      final audio = CustomMeditationAudio(
        title: _audioTitleController.text,
        url: _audioUrlController.text,
        durationInSeconds: durationMinutes * 60,
      );
      
      final article = CustomMeditationArticle(
        title: _articleTitleController.text,
        content: _articleContentController.text,
      );
      
      bool success;
      
      if (_selectedMeditationId != null) {
        // Update existing meditation
        success = await _meditationService.updateCustomMeditation(
          id: _selectedMeditationId!,
          title: _titleController.text,
          description: _descriptionController.text,
          durationMinutes: durationMinutes,
          audio: audio,
          article: article,
          isActive: _formIsActive,
        );
      } else {
        // Add new meditation
        success = await _meditationService.addCustomMeditation(
          title: _titleController.text,
          description: _descriptionController.text,
          durationMinutes: durationMinutes,
          audio: audio,
          article: article,
          isActive: _formIsActive,
        );
      }
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedMeditationId != null 
                ? 'Meditation updated successfully' 
                : 'Meditation added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        _resetForm();
        await _loadMeditations();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save meditation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error saving meditation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteMeditation(String id) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Meditation'),
          content: const Text('Are you sure you want to delete this meditation? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('DELETE'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      // Delete the meditation
      await FirebaseFirestore.instance
          .collection('custom_meditation')
          .doc(id)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meditation deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        if (_selectedMeditationId == id) {
          _resetForm();
        }
        
        await _loadMeditations();
      }
    } catch (e) {
      print('Error deleting meditation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting meditation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Custom Meditations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMeditations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isAdmin
              ? _buildContent(isDarkMode)
              : const Center(child: Text('Unauthorized Access')),
    );
  }
  
  Widget _buildContent(bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: List of meditations grouped by duration
        Expanded(
          flex: 1,
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isEmpty() 
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.self_improvement,
                            size: 48,
                            color: isDarkMode ? Colors.white60 : Colors.black38,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No meditations yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create one using the form',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? Colors.white60 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildDurationList(isDarkMode),
          ),
        ),
        
        // Right side: Form
        Expanded(
          flex: 2,
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _selectedMeditationId != null ? Icons.edit : Icons.add_circle,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedMeditationId != null 
                              ? 'Edit Custom Meditation' 
                              : 'Add New Custom Meditation',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Basic info
                    _buildSectionTitle('Basic Information'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes) *',
                        border: OutlineInputBorder(),
                        helperText: 'Recommended: 5, 10, 15, or 30 minutes',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    
                    // Audio information
                    _buildSectionTitle('Audio Information'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _audioTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Audio Title *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _audioUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Audio URL *',
                        border: OutlineInputBorder(),
                        helperText: 'Full URL to the audio file',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _audioScriptController,
                      decoration: const InputDecoration(
                        labelText: 'Audio Script (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    
                    // Article information
                    _buildSectionTitle('Article Information'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _articleTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Article Title *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _articleContentController,
                      decoration: const InputDecoration(
                        labelText: 'Article Content *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                    ),
                    const SizedBox(height: 24),
                    
                    // Active/Inactive toggle
                    Row(
                      children: [
                        Text(
                          'Status:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Switch(
                          value: _formIsActive,
                          onChanged: (value) {
                            setState(() {
                              _formIsActive = value;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                        Text(
                          _formIsActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: _formIsActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _resetForm,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('RESET'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _saveMeditation,
                          icon: _isSubmitting 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(_selectedMeditationId != null ? Icons.save : Icons.add, size: 16),
                          label: Text(_selectedMeditationId != null ? 'UPDATE' : 'SAVE'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            backgroundColor: _selectedMeditationId != null ? Colors.blue : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  bool _isEmpty() {
    return _meditationsByDuration.values.every((list) => list.isEmpty);
  }
  
  Widget _buildDurationList(bool isDarkMode) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // First display standard durations with items
        ..._durationCategories
            .where((duration) => _meditationsByDuration[duration]?.isNotEmpty ?? false)
            .map((duration) => _buildDurationSection(duration, _meditationsByDuration[duration]!, isDarkMode)),
        
        // Then display non-standard durations with items
        ..._meditationsByDuration.entries
            .where((entry) => !_durationCategories.contains(entry.key) && entry.value.isNotEmpty)
            .map((entry) => _buildDurationSection(entry.key, entry.value, isDarkMode)),
        
        // Button to add standard durations if they don't exist
        ..._durationCategories
            .where((duration) => _meditationsByDuration[duration]?.isEmpty ?? true)
            .map((duration) => _buildEmptyDurationSection(duration, isDarkMode)),
      ],
    );
  }
  
  Widget _buildDurationSection(int durationMinutes, List<CustomMeditation> meditations, bool isDarkMode) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return ExpansionTile(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getDurationColor(durationMinutes),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$durationMinutes',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$durationMinutes Min Meditations',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      initiallyExpanded: true,
      children: [
        ...meditations.map((meditation) => ListTile(
          title: Text(
            meditation.title,
            style: TextStyle(
              fontWeight: _selectedMeditationId == meditation.id ? FontWeight.bold : FontWeight.normal,
              color: textColor,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
          subtitle: Text(
            meditation.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12),
          ),
          leading: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: meditation.isActive ? Colors.green : Colors.red,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, size: 18, color: Theme.of(context).primaryColor),
                onPressed: () => _loadMeditationForEdit(meditation),
                constraints: BoxConstraints(minWidth: 30, minHeight: 36),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => _deleteMeditation(meditation.id),
                constraints: BoxConstraints(minWidth: 30, minHeight: 36),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          selected: _selectedMeditationId == meditation.id,
          onTap: () => _loadMeditationForEdit(meditation),
          dense: true,
        )),
        ListTile(
          title: Row(
            children: [
              Icon(Icons.add, size: 16, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add New ${durationMinutes}-Min Meditation',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          onTap: () {
            _resetForm();
            _durationController.text = durationMinutes.toString();
          },
          dense: true,
        ),
      ],
    );
  }
  
  Widget _buildEmptyDurationSection(int durationMinutes, bool isDarkMode) {
    return ListTile(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getDurationColor(durationMinutes).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$durationMinutes',
                style: TextStyle(
                  color: _getDurationColor(durationMinutes),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add $durationMinutes Min',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        _resetForm();
        _durationController.text = durationMinutes.toString();
      },
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
            margin: const EdgeInsets.only(right: 8),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getDurationColor(int minutes) {
    switch (minutes) {
      case 5:
        return Colors.green;
      case 10:
        return Colors.blue;
      case 15:
        return Colors.purple;
      case 30:
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }
} 