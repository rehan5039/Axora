import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axora/models/quote.dart';
import 'package:axora/models/quote_category.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminQuotesScreen extends StatefulWidget {
  const AdminQuotesScreen({super.key});

  @override
  State<AdminQuotesScreen> createState() => _AdminQuotesScreenState();
}

class _AdminQuotesScreenState extends State<AdminQuotesScreen> with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  List<Quote> _quotes = [];
  List<QuoteCategory> _categories = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(_handleTabChange);
    _loadData();
    _checkAdminStatus();
    
    // Log screen view for analytics
    FirebaseAnalytics.instance.logScreenView(
      screenName: 'admin_quotes_screen',
      screenClass: 'AdminQuotesScreen',
    );
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      debugPrint('Tab changed to: ${_tabController.index}');
    }
  }
  
  Future<void> _checkAdminStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user logged in');
        return;
      }
      
      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      final isAdmin = adminDoc.exists;
      
      debugPrint('User ${user.uid} is admin: $isAdmin');
    } catch (e) {
      debugPrint('Error checking admin status: $e');
    }
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get categories
      final categorySnapshot = await _firestore.collection('quote_categories').get();
      final categories = categorySnapshot.docs
          .map((doc) => QuoteCategory.fromJson(doc.data(), doc.id))
          .toList();
      
      debugPrint('Loaded ${categories.length} categories');
      
      // Get quotes
      final quoteSnapshot = await _firestore
          .collection('meditation_quotes')
          .orderBy('createdAt', descending: true)
          .get();
      final quotes = quoteSnapshot.docs
          .map((doc) => Quote.fromJson(doc.data(), doc.id))
          .toList();
      
      debugPrint('Loaded ${quotes.length} quotes');
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _quotes = quotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }
  
  Future<void> _deleteQuote(Quote quote) async {
    try {
      await _firestore
          .collection('meditation_quotes')
          .doc(quote.id)
          .delete();
      
      if (mounted) {
        setState(() {
          _quotes.removeWhere((q) => q.id == quote.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting quote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _addEditQuote({Quote? quote}) {
    if (_categories.isEmpty) {
      // Show message that categories need to be created first
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Categories'),
          content: const Text('You need to create at least one category before adding quotes.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _addEditCategory(); // Open category creation dialog
              },
              child: const Text('CREATE CATEGORY'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
          ],
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => _AddEditQuoteDialog(
        quote: quote,
        categories: _categories,
        onSave: (updatedQuote) {
          // Refresh quotes list
          _loadData();
        },
      ),
    );
  }
  
  void _addEditCategory({QuoteCategory? category}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditCategoryDialog(
        category: category,
        onSave: (updatedCategory) {
          // Refresh categories list
          _loadData();
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quotes'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Quotes'),
            Tab(text: 'Categories'),
          ],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorWeight: 3,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Quotes tab
          _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _quotes.isEmpty
              ? Center(
                  child: Text(
                    'No quotes found',
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _quotes.length,
                  itemBuilder: (context, index) {
                    final quote = _quotes[index];
                    return _buildQuoteItem(quote, theme);
                  },
                ),
          
          // Categories tab
          _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No categories found',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a category to get started',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _addEditCategory(),
                        icon: const Icon(Icons.add),
                        label: const Text('ADD CATEGORY'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategoryItem(category, theme);
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final currentTab = _tabController.index;
          debugPrint('FAB pressed, current tab: $currentTab');
          if (currentTab == 0) {
            // Quotes tab
            _addEditQuote();
          } else {
            // Categories tab
            _addEditCategory();
          }
        },
        tooltip: _tabController.index == 0 ? 'Add Quote' : 'Add Category',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 6,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildQuoteItem(Quote quote, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          quote.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        subtitle: Text(
          'By: ${quote.author} | Category: ${quote.categoryName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _addEditQuote(quote: quote),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Quote'),
                    content: const Text('Are you sure you want to delete this quote?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteQuote(quote);
                        },
                        child: const Text('DELETE'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryItem(QuoteCategory category, ThemeData theme) {
    IconData getIconData() {
      try {
        switch (category.iconName) {
          case 'format_quote':
            return Icons.format_quote;
          case 'psychology':
            return Icons.psychology;
          case 'emoji_emotions':
            return Icons.emoji_emotions;
          case 'spa':
            return Icons.spa;
          default:
            // Instead of creating a dynamic IconData, use a predefined icon
            return Icons.format_quote;
        }
      } catch (e) {
        return Icons.format_quote;
      }
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          getIconData(),
          color: theme.colorScheme.primary,
          size: 28,
        ),
        title: Text(category.name),
        subtitle: Text(
          category.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _addEditCategory(category: category),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () {
                // Count quotes in this category first
                final quoteCount = _quotes.where((q) => q.categoryId == category.id).length;
                
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Category'),
                    content: Text(
                      quoteCount > 0
                          ? 'This category contains $quoteCount quotes. '
                            'Deleting it will make those quotes uncategorized.'
                          : 'Are you sure you want to delete this category?'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await _firestore
                                .collection('quote_categories')
                                .doc(category.id)
                                .delete();
                                
                            if (mounted) {
                              setState(() {
                                _categories.removeWhere((c) => c.id == category.id);
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Category deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting category: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('DELETE'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddEditQuoteDialog extends StatefulWidget {
  final Quote? quote;
  final List<QuoteCategory> categories;
  final Function(Quote) onSave;

  const _AddEditQuoteDialog({
    this.quote,
    required this.categories,
    required this.onSave,
  });

  @override
  State<_AddEditQuoteDialog> createState() => _AddEditQuoteDialogState();
}

class _AddEditQuoteDialogState extends State<_AddEditQuoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _authorController = TextEditingController();
  String? _selectedCategoryId;
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.quote != null) {
      _textController.text = widget.quote!.text;
      _authorController.text = widget.quote!.author;
      _selectedCategoryId = widget.quote!.categoryId;
    } else if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
    super.dispose();
  }
  
  Future<void> _saveQuote() async {
    if (_formKey.currentState?.validate() != true) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final firestore = FirebaseFirestore.instance;
      final selectedCategory = widget.categories
          .firstWhere((c) => c.id == _selectedCategoryId);
      
      debugPrint('Selected category: ${selectedCategory.name}');
      
      final quoteData = {
        'text': _textController.text.trim(),
        'author': _authorController.text.trim(),
        'categoryId': _selectedCategoryId,
        'categoryName': selectedCategory.name,
        'createdAt': widget.quote?.createdAt.millisecondsSinceEpoch ?? 
            DateTime.now().millisecondsSinceEpoch,
      };
      
      debugPrint('Saving quote: $quoteData');
      
      if (widget.quote == null) {
        // Create new quote
        final docRef = await firestore
            .collection('meditation_quotes')
            .add(quoteData);
            
        debugPrint('Created quote with ID: ${docRef.id}');
            
        final newQuote = Quote(
          id: docRef.id,
          text: _textController.text.trim(),
          author: _authorController.text.trim(),
          categoryId: _selectedCategoryId!,
          categoryName: selectedCategory.name,
          createdAt: DateTime.now(),
        );
        
        if (mounted) {
          widget.onSave(newQuote);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quote created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context);
        }
      } else {
        // Update existing quote
        await firestore
            .collection('meditation_quotes')
            .doc(widget.quote!.id)
            .update(quoteData);
            
        debugPrint('Updated quote with ID: ${widget.quote!.id}');
            
        final updatedQuote = Quote(
          id: widget.quote!.id,
          text: _textController.text.trim(),
          author: _authorController.text.trim(),
          categoryId: _selectedCategoryId!,
          categoryName: selectedCategory.name,
          createdAt: widget.quote!.createdAt,
          isFavorite: widget.quote!.isFavorite,
          imageUrl: widget.quote!.imageUrl,
        );
        
        if (mounted) {
          widget.onSave(updatedQuote);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error saving quote: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving quote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.quote != null;
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(isEditing ? 'Edit Quote' : 'Add New Quote'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Quote Text',
                  alignLabelWithHint: true,
                  hintText: 'Enter the quote text',
                ),
                maxLines: 4,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quote text';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  hintText: 'Who said this quote?',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter author name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                value: _selectedCategoryId,
                items: widget.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _saveQuote,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEditing ? 'UPDATE' : 'SAVE'),
        ),
      ],
    );
  }
}

class _AddEditCategoryDialog extends StatefulWidget {
  final QuoteCategory? category;
  final Function(QuoteCategory) onSave;

  const _AddEditCategoryDialog({
    this.category,
    required this.onSave,
  });

  @override
  State<_AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<_AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconController = TextEditingController();
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description;
      _iconController.text = widget.category!.iconName;
    } else {
      // Default icon for new categories
      _iconController.text = 'format_quote';
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    super.dispose();
  }
  
  Future<void> _saveCategory() async {
    if (_formKey.currentState?.validate() != true) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final firestore = FirebaseFirestore.instance;
      
      final categoryData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'iconName': _iconController.text.trim(),
      };
      
      debugPrint('Saving category: $categoryData');
      
      if (widget.category == null) {
        // Create new category
        final docRef = await firestore
            .collection('quote_categories')
            .add(categoryData);
            
        debugPrint('Created category with ID: ${docRef.id}');
            
        final newCategory = QuoteCategory(
          id: docRef.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          iconName: _iconController.text.trim(),
        );
        
        if (mounted) {
          widget.onSave(newCategory);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context);
        }
      } else {
        // Update existing category
        await firestore
            .collection('quote_categories')
            .doc(widget.category!.id)
            .update(categoryData);
            
        debugPrint('Updated category with ID: ${widget.category!.id}');
            
        final updatedCategory = QuoteCategory(
          id: widget.category!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          iconName: _iconController.text.trim(),
          imageUrl: widget.category!.imageUrl,
        );
        
        if (mounted) {
          widget.onSave(updatedCategory);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error saving category: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(isEditing ? 'Edit Category' : 'Add New Category'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Mindfulness, Gratitude, Inspiration',
                  prefixIcon: Icon(Icons.category),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Short description of this category',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _iconController,
                decoration: const InputDecoration(
                  labelText: 'Icon Name',
                  hintText: 'format_quote, favorite, star, etc.',
                  prefixIcon: Icon(Icons.emoji_emotions),
                  helperText: 'Use Material icon names like "format_quote"',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an icon name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _saveCategory,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEditing ? 'UPDATE' : 'SAVE'),
        ),
      ],
    );
  }
} 