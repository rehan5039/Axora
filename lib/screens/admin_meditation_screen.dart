import 'package:flutter/material.dart';
import 'package:axora/models/meditation_content.dart';
import 'package:axora/services/meditation_service.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMeditationScreen extends StatefulWidget {
  const AdminMeditationScreen({super.key});

  @override
  State<AdminMeditationScreen> createState() => _AdminMeditationScreenState();
}

class _AdminMeditationScreenState extends State<AdminMeditationScreen> {
  final _meditationService = MeditationService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  List<MeditationContent> _meditationContents = [];
  
  // Form fields
  final _dayController = TextEditingController();
  final _titleController = TextEditingController();
  final _articleTitleController = TextEditingController();
  final _articleContentController = TextEditingController();
  final _audioTitleController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isActive = true;
  
  @override
  void initState() {
    super.initState();
    _loadMeditationContents();
  }
  
  @override
  void dispose() {
    _dayController.dispose();
    _titleController.dispose();
    _articleTitleController.dispose();
    _articleContentController.dispose();
    _audioTitleController.dispose();
    _audioUrlController.dispose();
    _durationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMeditationContents() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final contents = await _meditationService.getAllMeditationContent();
      setState(() {
        _meditationContents = contents;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading meditation contents: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading content: $e')),
      );
    }
  }
  
  void _resetForm() {
    _dayController.clear();
    _titleController.clear();
    _articleTitleController.clear();
    _articleContentController.clear();
    _audioTitleController.clear();
    _audioUrlController.clear();
    _durationController.clear();
    _isActive = true;
  }
  
  Future<void> _saveMeditationContent() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final day = int.parse(_dayController.text);
      final title = _titleController.text;
      
      final article = ArticleContent(
        title: _articleTitleController.text,
        content: _articleContentController.text,
      );
      
      final audio = AudioContent(
        title: _audioTitleController.text,
        url: _audioUrlController.text,
        durationInSeconds: int.parse(_durationController.text),
      );
      
      print('Saving meditation content:');
      print('Day: $day, Title: $title');
      print('Article: ${article.toMap()}');
      print('Audio: ${audio.toMap()}');
      
      final success = await _meditationService.addMeditationContent(
        day: day,
        title: title,
        article: article,
        audio: audio,
      );
      
      if (success) {
        _resetForm();
        await _loadMeditationContents();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meditation content added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add content')),
        );
      }
    } catch (e) {
      print('Error saving meditation content: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Future<void> _showContentDetails(MeditationContent content) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    final article = ArticleContent.fromMap(content.article);
    final audio = AudioContent.fromMap(content.audio);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Day ${content.day}: ${content.title}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Status: ${content.isActive ? "Active" : "Inactive"}',
                style: TextStyle(
                  color: content.isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailsSection('Article', [
                _buildDetailRow('Title', article.title),
                _buildDetailRow('Content', article.content),
              ]),
              const SizedBox(height: 16),
              _buildDetailsSection('Audio', [
                _buildDetailRow('Title', audio.title),
                _buildDetailRow('URL', audio.url),
                _buildDetailRow('Duration', '${audio.durationInSeconds} seconds'),
              ]),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _editContent(content);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.deepPurple : Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Edit Content'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _editContent(MeditationContent content) {
    // TODO: Implement edit functionality
    // This would be similar to the add form, but pre-filled with the content data
    // For now, we'll show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality not yet implemented')),
    );
  }
  
  Widget _buildDetailsSection(String title, List<Widget> children) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Meditation Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMeditationContents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _meditationContents.isEmpty
                      ? Center(
                          child: Text(
                            'No meditation content available.\nAdd a new one below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _meditationContents.length,
                          itemBuilder: (context, index) {
                            final content = _meditationContents[index];
                            return _buildContentCard(content);
                          },
                        ),
                ),
                const Divider(height: 1),
                _buildAddContentForm(),
              ],
            ),
    );
  }
  
  Widget _buildContentCard(MeditationContent content) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final article = ArticleContent.fromMap(content.article);
    final audio = AudioContent.fromMap(content.audio);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => _showContentDetails(content),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.deepPurple : Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${content.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
                    content.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${article.title} | ${audio.title}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: content.isActive
                ? (isDarkMode ? Colors.green[900] : Colors.green[100])
                : (isDarkMode ? Colors.red[900] : Colors.red[100]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: content.isActive
                  ? (isDarkMode ? Colors.green[100] : Colors.green[900])
                  : (isDarkMode ? Colors.red[100] : Colors.red[900]),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAddContentForm() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return ExpansionTile(
      title: const Text('Add New Meditation Content'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day and Title
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _dayController,
                        decoration: const InputDecoration(
                          labelText: 'Day',
                          hintText: 'Enter day number',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter day number';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter meditation title',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter title';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Article
                const Text(
                  'Article',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _articleTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Article Title',
                    hintText: 'Enter article title',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter article title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _articleContentController,
                  decoration: const InputDecoration(
                    labelText: 'Article Content',
                    hintText: 'Enter article content',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter article content';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Audio
                const Text(
                  'Audio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _audioTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Audio Title',
                    hintText: 'Enter audio title',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter audio title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _audioUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Audio URL',
                    hintText: 'Enter audio URL',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter audio URL';
                    }
                    if (!Uri.tryParse(value)!.isAbsolute) {
                      return 'Please enter a valid URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (seconds)',
                    hintText: 'Enter audio duration in seconds',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter duration';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Active status
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Make this content available to users'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // Submit button
                Center(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveMeditationContent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.deepPurple : Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Meditation Content',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateDay1AudioUrl() async {
    final meditationService = MeditationService();
    final newAudioUrl = 'https://firebasestorage.googleapis.com/v0/b/axora-5039.appspot.com/o/meditation_audios%2Fday1.mp3?alt=media';
    
    final success = await meditationService.updateMeditationAudioUrl(
      documentId: 'Day-1',
      audioUrl: newAudioUrl,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio URL updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update audio URL')),
      );
    }
  }
}