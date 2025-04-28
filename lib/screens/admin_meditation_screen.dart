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
  final _articleButtonController = TextEditingController();
  final _audioTitleController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _durationController = TextEditingController();
  final _audioScriptController = TextEditingController();
  bool _isActive = true;
  
  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadContent();
  }
  
  @override
  void dispose() {
    _dayController.dispose();
    _titleController.dispose();
    _articleTitleController.dispose();
    _articleContentController.dispose();
    _articleButtonController.dispose();
    _audioTitleController.dispose();
    _audioUrlController.dispose();
    _durationController.dispose();
    _audioScriptController.dispose();
    super.dispose();
  }
  
  Future<void> _checkAdminAndLoadContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isAdmin = await _meditationService.isAdmin();
      if (!isAdmin) {
        // If not admin, show error and pop back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You do not have permission to access this page'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      await _loadMeditationContents();
    } catch (e) {
      print('Error checking admin status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }
  
  Future<void> _loadMeditationContents() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final contents = await _meditationService.getAllMeditationContent(forAdmin: true);
      
      // Sort by day number
      contents.sort((a, b) => a.day.compareTo(b.day));
      
      setState(() {
        _meditationContents = contents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _resetForm() {
    _dayController.clear();
    _titleController.clear();
    _articleTitleController.clear();
    _articleContentController.clear();
    _articleButtonController.clear();
    _audioTitleController.clear();
    _audioUrlController.clear();
    _durationController.clear();
    _audioScriptController.clear();
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
        buttonText: _articleButtonController.text.isNotEmpty 
            ? _articleButtonController.text 
            : 'Mark as Read',
      );
      
      final audio = AudioContent(
        title: _audioTitleController.text,
        url: _audioUrlController.text,
        durationInSeconds: int.parse(_durationController.text),
        audioScript: _audioScriptController.text,
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
                _buildDetailRow('Button Text', article.buttonText),
              ]),
              const SizedBox(height: 16),
              _buildDetailsSection('Audio', [
                _buildDetailRow('Title', audio.title),
                _buildDetailRow('URL', audio.url),
                _buildDetailRow('Duration', '${audio.durationInSeconds} seconds'),
                _buildDetailRow('Audio Script', audio.audioScript.isNotEmpty ? audio.audioScript : 'No script available'),
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
    // Pre-fill form with existing content
    _dayController.text = content.day.toString();
    _titleController.text = content.title;
    
    final article = ArticleContent.fromMap(content.article);
    _articleTitleController.text = article.title;
    _articleContentController.text = article.content;
    _articleButtonController.text = article.buttonText;
    
    final audio = AudioContent.fromMap(content.audio);
    _audioTitleController.text = audio.title;
    _audioUrlController.text = audio.url;
    _durationController.text = audio.durationInSeconds.toString();
    _audioScriptController.text = audio.audioScript;
    
    _isActive = content.isActive;
    
    // Show bottom sheet with edit form
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Meditation Content',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                      _resetForm();
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
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
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _articleButtonController,
                        decoration: const InputDecoration(
                          labelText: 'Read Button Text',
                          hintText: 'Enter text for the "Mark as Read" button',
                        ),
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
                      
                      // Add Audio Script field
                      TextFormField(
                        controller: _audioScriptController,
                        decoration: const InputDecoration(
                          labelText: 'Audio Script',
                          hintText: 'Enter the meditation script for this audio',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 8,
                        minLines: 3,
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
                      
                      // Update button
                      Center(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : () => _updateMeditationContent(content.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Update Content',
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
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _updateMeditationContent(String contentId) async {
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
        buttonText: _articleButtonController.text.isNotEmpty 
            ? _articleButtonController.text 
            : 'Mark as Read',
      );
      
      final audio = AudioContent(
        title: _audioTitleController.text,
        url: _audioUrlController.text,
        durationInSeconds: int.parse(_durationController.text),
        audioScript: _audioScriptController.text,
      );
      
      final success = await _meditationService.updateMeditationContent(
        contentId: contentId,
        title: title,
        article: article,
        audio: audio,
        isActive: _isActive,
      );
      
      if (success) {
        Navigator.pop(context); // Close edit form
        _resetForm();
        await _loadMeditationContents(); // Refresh list
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content updated successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update content'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating meditation content: $e');
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
          _isSaving = false;
        });
      }
    }
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
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (_meditationContents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No meditation content available.\nAdd a new one below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _meditationContents.length,
                      itemBuilder: (context, index) {
                        final content = _meditationContents[index];
                        return _buildContentCard(content);
                      },
                    ),
                  const Divider(height: 1),
                  _buildAddContentForm(),
                ],
              ),
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
      child: Column(
        children: [
          ListTile(
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Active Status Switch
                Row(
                  children: [
                    Text(
                      'Active:',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Switch(
                      value: content.isActive,
                      onChanged: (bool value) async {
                        final success = await _meditationService.updateMeditationContent(
                          contentId: content.id,
                          title: content.title,
                          article: ArticleContent.fromMap(content.article),
                          audio: AudioContent.fromMap(content.audio),
                          isActive: value,
                        );
                        
                        if (success) {
                          await _loadMeditationContents();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value 
                                    ? 'Content activated successfully' 
                                    : 'Content deactivated successfully'
                                ),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update content status'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      activeColor: isDarkMode ? Colors.deepPurple : Colors.blue,
                    ),
                  ],
                ),
                // Delete Button
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(content),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showDeleteConfirmation(MeditationContent content) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meditation Content'),
        content: Text(
          'Are you sure you want to delete Day ${content.day}: ${content.title}?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      
      try {
        final success = await _meditationService.deleteMeditationContent(content.id);
        
        if (success) {
          await _loadMeditationContents();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Content deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete content'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
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
                const SizedBox(height: 8),
                TextFormField(
                  controller: _articleButtonController,
                  decoration: const InputDecoration(
                    labelText: 'Read Button Text',
                    hintText: 'Enter text for the "Mark as Read" button',
                  ),
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
                
                // Add Audio Script field
                TextFormField(
                  controller: _audioScriptController,
                  decoration: const InputDecoration(
                    labelText: 'Audio Script',
                    hintText: 'Enter the meditation script for this audio',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  minLines: 3,
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