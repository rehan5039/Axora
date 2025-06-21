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
  
  // Add additional fields and controllers for managing multiple pages
  List<Map<String, TextEditingController>> _additionalPageControllers = [];

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
    
    // Dispose of all additional page controllers
    for (var controllers in _additionalPageControllers) {
      controllers['title']?.dispose();
      controllers['content']?.dispose();
      controllers['buttonText']?.dispose();
    }
    
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
    
    // Clear all additional page controllers
    for (var controllers in _additionalPageControllers) {
      controllers['title']?.dispose();
      controllers['content']?.dispose();
      controllers['buttonText']?.dispose();
    }
    
    setState(() {
      _additionalPageControllers = [];
    });
  }
  
  void _addPageControllers() {
    _additionalPageControllers.add({
      'title': TextEditingController(),
      'content': TextEditingController(),
      'buttonText': TextEditingController(text: 'Continue'),
    });
  }

  void _removePageControllers(int index) {
    if (index >= 0 && index < _additionalPageControllers.length) {
      // Dispose of controllers first
      _additionalPageControllers[index]['title']?.dispose();
      _additionalPageControllers[index]['content']?.dispose();
      _additionalPageControllers[index]['buttonText']?.dispose();
      
      setState(() {
        _additionalPageControllers.removeAt(index);
      });
    }
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
      
      // Create additional pages array
      List<Map<String, dynamic>> articlePages = [];
      for (var controllers in _additionalPageControllers) {
        if (controllers['title']!.text.isNotEmpty && controllers['content']!.text.isNotEmpty) {
          final page = ArticleContent(
            title: controllers['title']!.text,
            content: controllers['content']!.text,
            buttonText: controllers['buttonText']!.text.isNotEmpty 
                ? controllers['buttonText']!.text 
                : 'Continue',
          );
          articlePages.add(page.toMap());
        }
      }
      
      print('Saving meditation content:');
      print('Day: $day, Title: $title');
      print('Article: ${article.toMap()}');
      print('Audio: ${audio.toMap()}');
      print('Additional Pages: $articlePages');
      
      final success = await _meditationService.addMeditationContent(
        day: day,
        title: title,
        article: article,
        audio: audio,
        articlePages: articlePages,
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
    
    // Get all pages including the main article
    final allPages = content.getAllPages();
    int currentPageIndex = 0;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Day ${content.day}: ${content.title}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      
                      // Activity status indicator
                      Chip(
                        label: Text(
                          content.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: content.isActive ? Colors.green : Colors.red,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Add page navigation UI
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Article Pages (${allPages.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Page tabs
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (int i = 0; i < allPages.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text('Page ${i + 1}'),
                                      selected: currentPageIndex == i,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            currentPageIndex = i;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                // Add new page button
                                ActionChip(
                                  avatar: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Page'),
                                  onPressed: () {
                                    _addNewArticlePage(content);
                                  },
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Current page contents
                          _buildArticlePageDetails(
                            allPages[currentPageIndex], 
                            currentPageIndex, 
                            content.id,
                            setState,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      const Text(
                        'Audio Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Audio details display
                      ListTile(
                        title: const Text('Title'),
                        subtitle: Text(audio.title),
                      ),
                      ListTile(
                        title: const Text('URL'),
                        subtitle: Text(audio.url),
                      ),
                      ListTile(
                        title: const Text('Duration'),
                        subtitle: Text('${audio.durationInSeconds} seconds'),
                      ),
                      ListTile(
                        title: const Text('Audio Script'),
                        subtitle: Text(audio.audioScript.isNotEmpty 
                            ? audio.audioScript 
                            : 'No script available'),
                      ),
                      
                      const SizedBox(height: 24),

                      // Action buttons at the bottom
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Delete button
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: const Text('Delete', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showDeleteConfirmDialog(content);
                            },
                          ),
                          
                          // Edit button
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _setupEditForm(content);
                              _showAddEditDialog(isEdit: true);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Helper method to build article page details with edit/delete options
  Widget _buildArticlePageDetails(
    ArticleContent page,
    int pageIndex,
    String contentId,
    StateSetter setState,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    page.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (pageIndex > 0) // Only show delete for additional pages
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete this page',
                    onPressed: () {
                      _showDeletePageConfirmDialog(contentId, pageIndex);
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit this page',
                  onPressed: () {
                    _editArticlePage(contentId, pageIndex, page);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              page.content,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Button Text: ${page.buttonText}',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
  
  // Add a new article page
  Future<void> _addNewArticlePage(MeditationContent content) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final buttonTextController = TextEditingController(text: 'Continue');
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Page'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Page Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => 
                        value == null || value.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'Page Content',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 10,
                    validator: (value) => 
                        value == null || value.isEmpty ? 'Content is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: buttonTextController,
                    decoration: const InputDecoration(
                      labelText: 'Button Text',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Add Page'),
            ),
          ],
        );
      },
    );
    
    if (result == true) {
      setState(() {
        _isSaving = true;
      });
      
      final newPage = ArticleContent(
        title: titleController.text,
        content: contentController.text,
        buttonText: buttonTextController.text,
      );
      
      try {
        final success = await _meditationService.addArticlePage(
          contentId: content.id,
          page: newPage,
        );
        
        if (success) {
          await _loadMeditationContents();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New page added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to add new page'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('Error adding new page: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  // Edit an existing article page
  Future<void> _editArticlePage(String contentId, int pageIndex, ArticleContent page) async {
    final titleController = TextEditingController(text: page.title);
    final contentController = TextEditingController(text: page.content);
    final buttonTextController = TextEditingController(text: page.buttonText);
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Page ${pageIndex + 1}'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Page Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => 
                        value == null || value.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'Page Content',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 10,
                    validator: (value) => 
                        value == null || value.isEmpty ? 'Content is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: buttonTextController,
                    decoration: const InputDecoration(
                      labelText: 'Button Text',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
    
    if (result == true) {
      setState(() {
        _isSaving = true;
      });
      
      final updatedPage = ArticleContent(
        title: titleController.text,
        content: contentController.text,
        buttonText: buttonTextController.text,
      );
      
      try {
        final success = await _meditationService.updateArticlePage(
          contentId: contentId,
          pageIndex: pageIndex,
          updatedPage: updatedPage,
        );
        
        if (success) {
          await _loadMeditationContents();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Page updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update page'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('Error updating page: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  // Confirm and delete an article page
  Future<void> _showDeletePageConfirmDialog(String contentId, int pageIndex) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Page'),
          content: const Text('Are you sure you want to delete this page? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    
    if (result == true) {
      setState(() {
        _isSaving = true;
      });
      
      try {
        final success = await _meditationService.removeArticlePage(
          contentId: contentId,
          pageIndex: pageIndex,
        );
        
        if (success) {
          await _loadMeditationContents();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Page deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete page'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('Error deleting page: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
    
    // Clear and recreate additional page controllers
    for (var controllers in _additionalPageControllers) {
      controllers['title']?.dispose();
      controllers['content']?.dispose();
      controllers['buttonText']?.dispose();
    }
    _additionalPageControllers = [];
    
    // Add controllers for additional pages
    for (int i = 0; i < content.articlePages.length; i++) {
      final page = ArticleContent.fromMap(content.articlePages[i]);
      final controllers = {
        'title': TextEditingController(text: page.title),
        'content': TextEditingController(text: page.content),
        'buttonText': TextEditingController(text: page.buttonText),
      };
      _additionalPageControllers.add(controllers);
    }
    
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
                  _buildAddContentForm(),
                  const Divider(height: 1),
                  if (_meditationContents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No meditation content available.',
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
                        // Get reversed index to display days in reverse order
                        final reversedIndex = _meditationContents.length - 1 - index;
                        final content = _meditationContents[reversedIndex];
                        return _buildContentCard(content);
                      },
                    ),
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
                  onPressed: () => _showDeleteConfirmDialog(content),
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
  
  Future<void> _showDeleteConfirmDialog(MeditationContent content) async {
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

    if (confirmed == true) {
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
        setState(() => _isLoading = false);
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
    final newAudioUrl = 'https://firebasestorage.googleapis.com/v0/b/axora-we.appspot.com/o/meditation_audios%2Fday1.mp3?alt=media';
    
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

  Future<void> _showAddEditDialog({bool isEdit = false}) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog.fullscreen(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(isEdit ? 'Edit Meditation Content' : 'Add Meditation Content'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                await _saveMeditationContent();
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save'),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                body: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Basic content information
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Basic Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _dayController,
                                  decoration: const InputDecoration(
                                    labelText: 'Day Number *',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Day number is required';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Day must be a valid number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Title *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Title is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  title: const Text('Active'),
                                  subtitle: const Text('Toggle visibility to users'),
                                  value: _isActive,
                                  onChanged: (value) {
                                    setModalState(() {
                                      _isActive = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Main article content
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Main Article (Page 1)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _articleTitleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Article Title *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Article title is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _articleContentController,
                                  decoration: const InputDecoration(
                                    labelText: 'Article Content *',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                  maxLines: 10,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Article content is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _articleButtonController,
                                  decoration: const InputDecoration(
                                    labelText: 'Button Text (optional)',
                                    hintText: 'Default: "Mark as Read"',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Additional Pages
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Additional Pages',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Page'),
                                      onPressed: () {
                                        setModalState(() {
                                          _addPageControllers();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // List of additional pages
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _additionalPageControllers.length,
                                  itemBuilder: (context, index) {
                                    return Card(
                                      elevation: 1,
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Page ${index + 2}', // +2 because main article is page 1
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () {
                                                    setModalState(() {
                                                      _removePageControllers(index);
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _additionalPageControllers[index]['title']!,
                                              decoration: const InputDecoration(
                                                labelText: 'Page Title *',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Page title is required';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                            TextFormField(
                                              controller: _additionalPageControllers[index]['content']!,
                                              decoration: const InputDecoration(
                                                labelText: 'Page Content *',
                                                border: OutlineInputBorder(),
                                                alignLabelWithHint: true,
                                              ),
                                              maxLines: 10,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Page content is required';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                            TextFormField(
                                              controller: _additionalPageControllers[index]['buttonText']!,
                                              decoration: const InputDecoration(
                                                labelText: 'Button Text (optional)',
                                                hintText: 'Default: "Continue"',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                
                                if (_additionalPageControllers.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: Text(
                                        'No additional pages added',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Audio content
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Audio',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _audioTitleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Audio Title *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Audio title is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _audioUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'Audio URL *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Audio URL is required';
                                    }
                                    if (!Uri.tryParse(value)!.isAbsolute) {
                                      return 'Please enter a valid URL';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _durationController,
                                  decoration: const InputDecoration(
                                    labelText: 'Duration (seconds) *',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Duration is required';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Duration must be a valid number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _audioScriptController,
                                  decoration: const InputDecoration(
                                    labelText: 'Audio Script (optional)',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                  maxLines: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _setupEditForm(MeditationContent content) {
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
    
    // Clear and recreate additional page controllers
    for (var controllers in _additionalPageControllers) {
      controllers['title']?.dispose();
      controllers['content']?.dispose();
      controllers['buttonText']?.dispose();
    }
    _additionalPageControllers = [];
    
    // Add controllers for additional pages
    for (int i = 0; i < content.articlePages.length; i++) {
      final page = ArticleContent.fromMap(content.articlePages[i]);
      final controllers = {
        'title': TextEditingController(text: page.title),
        'content': TextEditingController(text: page.content),
        'buttonText': TextEditingController(text: page.buttonText),
      };
      _additionalPageControllers.add(controllers);
    }
  }
}