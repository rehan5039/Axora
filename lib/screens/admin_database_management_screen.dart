import 'package:flutter/material.dart';
import 'package:axora/services/firebase_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axora/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';

class AdminDatabaseManagementScreen extends StatefulWidget {
  const AdminDatabaseManagementScreen({Key? key}) : super(key: key);

  @override
  _AdminDatabaseManagementScreenState createState() => _AdminDatabaseManagementScreenState();
}

class _AdminDatabaseManagementScreenState extends State<AdminDatabaseManagementScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  
  late TabController _tabController;
  bool _isAdmin = false;
  bool _isLoading = true;
  bool _isGlobalSearching = false;
  String _globalSearchQuery = '';
  
  // Global search results
  List<Map<String, dynamic>> _globalSearchResults = [];
  bool _isSearchingGlobally = false;
  
  final _realtimeDatabaseTabKey = GlobalKey<_RealtimeDatabaseTabState>();
  final _firestoreTabKey = GlobalKey<_FirestoreTabState>();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdminStatus();
    
    // Listen to tab changes to reset global search
    _tabController.addListener(() {
      if (_isGlobalSearching) {
        setState(() {
          _isGlobalSearching = false;
          _globalSearchQuery = '';
          _globalSearchResults = [];
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _checkAdminStatus() async {
    final isAdmin = await _firebaseService.canModifyDatabase();
    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });
  }
  
  void _toggleGlobalSearch() {
    setState(() {
      _isGlobalSearching = !_isGlobalSearching;
      if (!_isGlobalSearching) {
        _globalSearchQuery = '';
        _globalSearchResults = [];
      }
    });
  }
  
  Future<void> _performGlobalSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _globalSearchResults = [];
        _isSearchingGlobally = false;
      });
      return;
    }
    
    setState(() {
      _isSearchingGlobally = true;
      _globalSearchQuery = query;
    });
    
    // Get the current tab index
    final currentTab = _tabController.index;
    
    try {
      // For Realtime Database, we'll search the root
      if (currentTab == 0) {
        // Get root data from Realtime Database
        final rootData = await _firebaseService.getRealtimeDatabaseData('');
        
        // Search results
        final results = <Map<String, dynamic>>[];
        
        // Recursive search function for Realtime Database
        void searchInRealtimeDB(String path, Map<String, dynamic> data) {
          data.forEach((key, value) {
            final currentPath = path.isEmpty ? key : '$path/$key';
            
            // Check if key contains query
            if (key.toLowerCase().contains(query.toLowerCase())) {
              results.add({
                'type': 'realtime',
                'path': currentPath,
                'key': key,
                'value': value is Map ? 'Object with ${(value as Map).length} items' : value.toString(),
              });
            }
            
            // Check value if it's a primitive type
            if (value is String && value.toLowerCase().contains(query.toLowerCase())) {
              results.add({
                'type': 'realtime',
                'path': currentPath,
                'key': key,
                'value': value,
              });
            } else if (value is num && value.toString().contains(query.toLowerCase())) {
              results.add({
                'type': 'realtime',
                'path': currentPath,
                'key': key,
                'value': value.toString(),
              });
            } else if (value is bool && value.toString().toLowerCase().contains(query.toLowerCase())) {
              results.add({
                'type': 'realtime',
                'path': currentPath,
                'key': key,
                'value': value.toString(),
              });
            }
            
            // If it's a map, recurse into it
            if (value is Map) {
              searchInRealtimeDB(currentPath, Map<String, dynamic>.from(value as Map));
            }
          });
        }
        
        // Start the recursive search
        searchInRealtimeDB('', rootData);
        
        setState(() {
          _globalSearchResults = results;
          _isSearchingGlobally = false;
        });
      } 
      // For Firestore, we'll search through collections
      else if (currentTab == 1) {
        // Get list of collections
        final collections = await _firebaseService.getFirestoreCollections();
        
        // Search results
        final results = <Map<String, dynamic>>[];
        
        // Search in each collection
        for (final collection in collections) {
          // Check if collection name contains query
          if (collection.toLowerCase().contains(query.toLowerCase())) {
            results.add({
              'type': 'firestore_collection',
              'path': collection,
              'key': collection,
              'value': 'Collection',
            });
          }
          
          // Get documents in this collection
          try {
            final documents = await _firebaseService.getFirestoreDocuments(collection);
            
            // Search in each document
            for (final doc in documents) {
              final docId = doc['_id'] as String;
              
              // Check if document ID contains query
              if (docId.toLowerCase().contains(query.toLowerCase())) {
                results.add({
                  'type': 'firestore_document',
                  'path': '$collection/$docId',
                  'key': docId,
                  'value': 'Document in $collection',
                });
              }
              
              // Recursive search function for document fields
              void searchInDocument(String fieldPath, Map<String, dynamic> fields) {
                fields.forEach((key, value) {
                  if (key == '_id') return; // Skip the ID field
                  
                  final currentPath = fieldPath.isEmpty ? key : '$fieldPath.$key';
                  
                  // Check if field key contains query
                  if (key.toLowerCase().contains(query.toLowerCase())) {
                    results.add({
                      'type': 'firestore_field',
                      'path': '$collection/$docId',
                      'field_path': currentPath,
                      'key': key,
                      'value': value is Map || value is List 
                          ? 'Complex value' 
                          : value.toString(),
                    });
                  }
                  
                  // Check value if it's a primitive type
                  if (value is String && value.toLowerCase().contains(query.toLowerCase())) {
                    results.add({
                      'type': 'firestore_field',
                      'path': '$collection/$docId',
                      'field_path': currentPath,
                      'key': key,
                      'value': value,
                    });
                  } else if (value is num && value.toString().contains(query.toLowerCase())) {
                    results.add({
                      'type': 'firestore_field',
                      'path': '$collection/$docId',
                      'field_path': currentPath,
                      'key': key,
                      'value': value.toString(),
                    });
                  } else if (value is bool && value.toString().toLowerCase().contains(query.toLowerCase())) {
                    results.add({
                      'type': 'firestore_field',
                      'path': '$collection/$docId',
                      'field_path': currentPath,
                      'key': key,
                      'value': value.toString(),
                    });
                  }
                  
                  // If it's a map, recurse into it
                  if (value is Map) {
                    searchInDocument(currentPath, Map<String, dynamic>.from(value as Map));
                  }
                });
              }
              
              // Start recursive search in the document
              searchInDocument('', doc);
            }
          } catch (e) {
            print('Error searching in collection $collection: $e');
            // Continue with other collections
          }
        }
        
        setState(() {
          _globalSearchResults = results;
          _isSearchingGlobally = false;
        });
      }
    } catch (e) {
      print('Error performing global search: $e');
      setState(() {
        _globalSearchResults = [];
        _isSearchingGlobally = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error performing search: $e')),
      );
    }
  }
  
  void _navigateToSearchResult(Map<String, dynamic> result) {
    final type = result['type'] as String;
    final path = result['path'] as String;
    
    // Handle different result types
    if (type.startsWith('realtime')) {
      // Switch to Realtime Database tab
      _tabController.animateTo(0);
      
      // Get path components
      final components = path.split('/');
      if (components.isNotEmpty) {
        // Wait for tab change to complete
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_realtimeDatabaseTabKey.currentState != null) {
            // Navigate to the path
            _realtimeDatabaseTabKey.currentState!.navigateToPathFromSearch(path);
          }
        });
      }
    } else if (type.startsWith('firestore')) {
      // Switch to Firestore tab
      _tabController.animateTo(1);
      
      // Wait for tab change to complete
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_firestoreTabKey.currentState != null) {
          if (type == 'firestore_collection') {
            // Navigate to the collection
            _firestoreTabKey.currentState!.navigateToCollection(path);
          } else if (type == 'firestore_document' || type == 'firestore_field') {
            // Path format: collection/document
            final components = path.split('/');
            if (components.length >= 2) {
              final collection = components[0];
              final documentId = components[1];
              
              // Navigate to the document
              _firestoreTabKey.currentState!.navigateToDocument(collection, documentId);
            }
          }
        }
      });
    }
    
    // Close global search
    setState(() {
      _isGlobalSearching = false;
      _globalSearchQuery = '';
      _globalSearchResults = [];
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: _isGlobalSearching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search across all databases...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _performGlobalSearch,
              )
            : const Text('Database Management'),
        actions: [
          // Global search toggle
          if (!_isLoading && _isAdmin)
            IconButton(
              icon: Icon(_isGlobalSearching ? Icons.close : Icons.search),
              onPressed: _toggleGlobalSearch,
              tooltip: _isGlobalSearching ? 'Cancel search' : 'Search across databases',
            ),
        ],
        bottom: _isLoading || !_isAdmin || _isGlobalSearching ? null : TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.storage),
              text: 'Realtime DB',
            ),
            Tab(
              icon: Icon(Icons.cloud),
              text: 'Firestore',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
              ? const Center(
                  child: Text(
                    'You need admin privileges to manage the database',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : _isGlobalSearching
                  ? _buildGlobalSearchResults(isDarkMode)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Realtime Database Tab
                        RealtimeDatabaseTab(
                          key: _realtimeDatabaseTabKey,
                          firebaseService: _firebaseService,
                        ),
                        
                        // Firestore Database Tab
                        FirestoreTab(
                          key: _firestoreTabKey,
                          firebaseService: _firebaseService,
                        ),
                      ],
                    ),
    );
  }
  
  Widget _buildGlobalSearchResults(bool isDarkMode) {
    if (_isSearchingGlobally) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_globalSearchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 48,
              color: isDarkMode ? Colors.white60 : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter search query to search across all databases',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_globalSearchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: isDarkMode ? Colors.white60 : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_globalSearchQuery"',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Search results for "$_globalSearchQuery"',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _globalSearchResults.length,
            itemBuilder: (context, index) {
              final result = _globalSearchResults[index];
              final type = result['type'] as String;
              final path = result['path'] as String;
              final key = result['key'] as String;
              final value = result['value'] as String;
              
              // Determine icon and color based on type
              IconData icon;
              Color iconColor;
              
              if (type == 'realtime') {
                icon = Icons.storage;
                iconColor = isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen;
              } else if (type == 'firestore_collection') {
                icon = Icons.folder;
                iconColor = Colors.amber;
              } else if (type == 'firestore_document') {
                icon = Icons.description;
                iconColor = Colors.blue;
              } else { // firestore_field
                icon = Icons.data_object;
                iconColor = Colors.purple;
              }
              
              return ListTile(
                leading: Icon(icon, color: iconColor),
                title: Text(key),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Path: $path',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    Text(
                      'Value: $value',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                onTap: () => _navigateToSearchResult(result),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Realtime Database Tab
class RealtimeDatabaseTab extends StatefulWidget {
  final FirebaseService firebaseService;
  
  const RealtimeDatabaseTab({
    Key? key,
    required this.firebaseService,
  }) : super(key: key);
  
  @override
  State<RealtimeDatabaseTab> createState() => _RealtimeDatabaseTabState();
}

class _RealtimeDatabaseTabState extends State<RealtimeDatabaseTab> {
  final DatabaseReference _rootRef = FirebaseDatabase.instance.ref();
  
  String _currentPath = '';
  Map<String, dynamic> _currentData = {};
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSearching = false;
  Map<String, dynamic> _filteredData = {};
  
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
      final path = _currentPath.isEmpty ? _rootRef : _rootRef.child(_currentPath);
      final snapshot = await path.get();
      
      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is Map) {
          setState(() {
            _currentData = Map<String, dynamic>.from(data as Map);
            _applySearch(); // Apply search filter if any
            _isLoading = false;
          });
        } else {
          // Handle non-map data (like strings, numbers, etc.)
          setState(() {
            _currentData = {'value': data};
            _applySearch(); // Apply search filter if any
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _currentData = {};
          _filteredData = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _currentData = {};
        _filteredData = {};
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }
  
  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredData = Map.from(_currentData);
      return;
    }
    
    _filteredData = {};
    _currentData.forEach((key, value) {
      if (_matchesSearch(key, value, _searchQuery.toLowerCase())) {
        _filteredData[key] = value;
      }
    });
  }
  
  bool _matchesSearch(String key, dynamic value, String query) {
    // Check if key contains the query
    if (key.toLowerCase().contains(query)) {
      return true;
    }
    
    // Check value
    if (value is String && value.toLowerCase().contains(query)) {
      return true;
    } else if (value is num && value.toString().contains(query)) {
      return true;
    } else if (value is bool && value.toString().toLowerCase().contains(query)) {
      return true;
    } else if (value is Map) {
      // For nested maps, check if any child contains the query
      bool hasMatch = false;
      value.forEach((childKey, childValue) {
        if (_matchesSearch(childKey.toString(), childValue, query)) {
          hasMatch = true;
        }
      });
      return hasMatch;
    }
    
    return false;
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _applySearch();
      }
    });
  }
  
  void _navigateToPath(String path) {
    setState(() {
      if (_currentPath.isEmpty) {
        _currentPath = path;
      } else {
        _currentPath = '$_currentPath/$path';
      }
      _searchQuery = '';
      _isSearching = false;
    });
    _loadData();
  }
  
  void _navigateUp() {
    setState(() {
      final parts = _currentPath.split('/');
      if (parts.length > 1) {
        parts.removeLast();
        _currentPath = parts.join('/');
      } else {
        _currentPath = '';
      }
      _searchQuery = '';
      _isSearching = false;
    });
    _loadData();
  }
  
  Future<void> _deleteItem(String key) async {
    final path = _currentPath.isEmpty ? key : '$_currentPath/$key';
    
    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$key" and all its data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm) {
      try {
        await widget.firebaseService.deleteFromDatabase(path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "$key" successfully')),
        );
        _loadData(); // Refresh the data
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting data: $e')),
        );
      }
    }
  }
  
  Future<void> _editItem(String key, dynamic value) async {
    final path = _currentPath.isEmpty ? key : '$_currentPath/$key';
    final initialValue = value is Map ? null : value.toString();
    final TextEditingController controller = TextEditingController(text: initialValue);
    
    if (value is Map) {
      // For maps (complex objects), show a message and don't allow direct editing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complex objects can\'t be edited directly. Navigate into them to edit individual fields.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Show edit dialog
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit "$key"'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Value',
            border: OutlineInputBorder(),
          ),
          keyboardType: value is int ? TextInputType.number : TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    
    if (newValue != null && newValue != initialValue) {
      // Convert the string value to the original type
      dynamic convertedValue;
      if (value is int) {
        convertedValue = int.tryParse(newValue) ?? 0;
      } else if (value is double) {
        convertedValue = double.tryParse(newValue) ?? 0.0;
      } else if (value is bool) {
        convertedValue = newValue.toLowerCase() == 'true';
      } else {
        convertedValue = newValue;
      }
      
      try {
        // Update the database
        await widget.firebaseService.updateRealtimeDatabase(path, convertedValue);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated "$key" successfully')),
        );
        _loadData(); // Refresh the data
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating data: $e')),
        );
      }
    }
  }
  
  Future<void> _addNewItem() async {
    final TextEditingController keyController = TextEditingController();
    final TextEditingController valueController = TextEditingController();
    
    // Show add dialog
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              if (keyController.text.isNotEmpty) {
                Navigator.of(context).pop({
                  'key': keyController.text,
                  'value': valueController.text,
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Key cannot be empty')),
                );
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      final key = result['key']!;
      final value = result['value']!;
      
      final path = _currentPath.isEmpty ? key : '$_currentPath/$key';
      
      try {
        // Update the database
        await widget.firebaseService.updateRealtimeDatabase(path, value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "$key" successfully')),
        );
        _loadData(); // Refresh the data
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding data: $e')),
        );
      }
    }
  }
  
  // Method to navigate to a path from search results
  void navigateToPathFromSearch(String path) {
    // Reset any existing search
    setState(() {
      _isSearching = false;
      _searchQuery = '';
    });
    
    // Split the path into components
    final components = path.split('/');
    
    // First, navigate to root
    setState(() {
      _currentPath = '';
    });
    
    // Then navigate through each component
    if (components.isNotEmpty) {
      _loadData().then((_) {
        _navigateToPathRecursively(components, 0);
      });
    }
  }
  
  void _navigateToPathRecursively(List<String> components, int index) {
    if (index >= components.length) return;
    
    final component = components[index];
    if (component.isEmpty) {
      // Skip empty components
      _navigateToPathRecursively(components, index + 1);
      return;
    }
    
    // Navigate to this component
    setState(() {
      if (_currentPath.isEmpty) {
        _currentPath = component;
      } else {
        _currentPath = '$_currentPath/$component';
      }
    });
    
    // Load data and continue navigating if needed
    if (index < components.length - 1) {
      _loadData().then((_) {
        _navigateToPathRecursively(components, index + 1);
      });
    } else {
      // Final component reached, just load the data
      _loadData();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Column(
      children: [
        // Path display and navigation
        Container(
          padding: const EdgeInsets.all(16),
          color: isDarkMode 
              ? Colors.grey[850] 
              : Colors.grey[200],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Current Path:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode 
                          ? Colors.white70 
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentPath.isEmpty ? '/ (root)' : _currentPath,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: isDarkMode 
                            ? AppColors.primaryGold 
                            : AppColors.primaryGreen,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isSearching)
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search in current path...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _applySearch();
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applySearch();
                    });
                  },
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Navigate up button
                  if (_currentPath.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _navigateUp,
                      icon: const Icon(Icons.arrow_upward),
                      label: const Text('Go Up'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode 
                            ? AppColors.primaryGold 
                            : AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  const Spacer(),
                  // Search button
                  IconButton(
                    icon: Icon(_isSearching ? Icons.search_off : Icons.search),
                    onPressed: _toggleSearch,
                    tooltip: _isSearching ? 'Cancel search' : 'Search',
                  ),
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadData,
                    tooltip: 'Refresh',
                  ),
                  // Add button
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addNewItem,
                    tooltip: 'Add new item',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Data display
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredData.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'No search results found'
                            : 'No data found at this path',
                        style: TextStyle(
                          color: isDarkMode 
                              ? Colors.white70 
                              : Colors.black54,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredData.length,
                      itemBuilder: (context, index) {
                        final key = _filteredData.keys.elementAt(index);
                        final value = _filteredData[key];
                        
                        // Determine if this is a branch or a leaf
                        final isBranch = value is Map;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: Icon(
                              isBranch 
                                  ? Icons.folder 
                                  : Icons.insert_drive_file,
                              color: isBranch
                                  ? (isDarkMode 
                                      ? AppColors.primaryGold 
                                      : AppColors.primaryGreen)
                                  : Colors.grey,
                            ),
                            title: Text(key),
                            subtitle: Text(
                              isBranch
                                  ? 'Contains ${(value as Map).length} items'
                                  : value.toString(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Edit button (only for non-branches)
                                if (!isBranch)
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editItem(key, value),
                                    tooltip: 'Edit',
                                  ),
                                
                                // Navigate button (only for branches)
                                if (isBranch)
                                  IconButton(
                                    icon: const Icon(Icons.navigate_next),
                                    onPressed: () => _navigateToPath(key),
                                    tooltip: 'Navigate to',
                                  ),
                                
                                // Delete button
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red[400],
                                  ),
                                  onPressed: () => _deleteItem(key),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                            onTap: isBranch ? () => _navigateToPath(key) : null,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// Firestore Database Tab
class FirestoreTab extends StatefulWidget {
  final FirebaseService firebaseService;
  
  const FirestoreTab({
    Key? key,
    required this.firebaseService,
  }) : super(key: key);
  
  @override
  State<FirestoreTab> createState() => _FirestoreTabState();
}

class _FirestoreTabState extends State<FirestoreTab> {
  List<String> _collections = [];
  List<String> _filteredCollections = [];
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _filteredDocuments = [];
  Map<String, dynamic>? _currentDocument;
  
  String _currentCollection = '';
  String _currentDocumentId = '';
  
  bool _isLoadingCollections = true;
  bool _isLoadingDocuments = false;
  bool _isLoadingDocument = false;
  String _errorMessage = '';
  
  bool _isSearching = false;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadCollections();
  }
  
  Future<void> _loadCollections() async {
    setState(() {
      _isLoadingCollections = true;
      _errorMessage = '';
    });
    
    try {
      final collections = await widget.firebaseService.getFirestoreCollections();
      setState(() {
        _collections = collections;
        _applyCollectionSearch();
        _isLoadingCollections = false;
        _errorMessage = '';
      });
    } catch (e) {
      print('Error loading collections: $e');
      setState(() {
        _collections = [];
        _filteredCollections = [];
        _isLoadingCollections = false;
        _errorMessage = 'Permission denied: You may need to be an admin to access Firestore.';
      });
    }
  }
  
  Future<void> _loadDocuments(String collectionPath) async {
    setState(() {
      _currentCollection = collectionPath;
      _currentDocumentId = '';
      _currentDocument = null;
      _isLoadingDocuments = true;
      _isSearching = false;
      _searchQuery = '';
    });
    
    try {
      final documents = await widget.firebaseService.getFirestoreDocuments(collectionPath);
      setState(() {
        _documents = documents;
        _applyDocumentSearch();
        _isLoadingDocuments = false;
      });
    } catch (e) {
      print('Error loading documents: $e');
      setState(() {
        _documents = [];
        _filteredDocuments = [];
        _isLoadingDocuments = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading documents: $e')),
      );
    }
  }
  
  void _applyCollectionSearch() {
    if (_searchQuery.isEmpty) {
      _filteredCollections = List.from(_collections);
      return;
    }
    
    final query = _searchQuery.toLowerCase();
    _filteredCollections = _collections
        .where((collection) => collection.toLowerCase().contains(query))
        .toList();
  }
  
  void _applyDocumentSearch() {
    if (_searchQuery.isEmpty) {
      _filteredDocuments = List.from(_documents);
      return;
    }
    
    final query = _searchQuery.toLowerCase();
    _filteredDocuments = _documents.where((doc) {
      // Check document ID
      if (doc['_id'].toString().toLowerCase().contains(query)) {
        return true;
      }
      
      // Search in all fields recursively
      return _searchInMap(doc, query);
    }).toList();
  }
  
  bool _searchInMap(Map<String, dynamic> map, String query) {
    for (var entry in map.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      
      // Check if key matches
      if (key.contains(query)) {
        return true;
      }
      
      // Check value based on type
      if (value is String && value.toLowerCase().contains(query)) {
        return true;
      } else if (value is num && value.toString().contains(query)) {
        return true;
      } else if (value is bool && value.toString().toLowerCase().contains(query)) {
        return true;
      } else if (value is Map) {
        // Search recursively in nested maps
        if (_searchInMap(value as Map<String, dynamic>, query)) {
          return true;
        }
      } else if (value is List) {
        // Search in list items
        for (var item in value) {
          if (item is String && item.toLowerCase().contains(query)) {
            return true;
          } else if (item is num && item.toString().contains(query)) {
            return true;
          } else if (item is Map && _searchInMap(item as Map<String, dynamic>, query)) {
            return true;
          }
        }
      }
    }
    
    return false;
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        if (_currentCollection.isEmpty) {
          _applyCollectionSearch();
        } else if (_currentDocumentId.isEmpty) {
          _applyDocumentSearch();
        }
      }
    });
  }
  
  Future<void> _loadDocument(String documentId) async {
    setState(() {
      _currentDocumentId = documentId;
      _isLoadingDocument = true;
      _isSearching = false;
      _searchQuery = '';
    });
    
    try {
      final document = await widget.firebaseService.getFirestoreDocument(_currentCollection, documentId);
      setState(() {
        _currentDocument = document;
        _isLoadingDocument = false;
      });
    } catch (e) {
      print('Error loading document: $e');
      setState(() {
        _currentDocument = null;
        _isLoadingDocument = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading document: $e')),
      );
    }
  }
  
  void _goBackToCollections() {
    setState(() {
      _currentCollection = '';
      _currentDocumentId = '';
      _documents = [];
      _filteredDocuments = [];
      _currentDocument = null;
      _isSearching = false;
      _searchQuery = '';
    });
  }
  
  void _goBackToDocuments() {
    setState(() {
      _currentDocumentId = '';
      _currentDocument = null;
      _isSearching = false;
      _searchQuery = '';
    });
  }
  
  Future<void> _deleteDocument() async {
    if (_currentCollection.isEmpty || _currentDocumentId.isEmpty) return;
    
    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete document "$_currentDocumentId"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm) {
      try {
        await widget.firebaseService.deleteFirestoreDocument(_currentCollection, _currentDocumentId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted document $_currentDocumentId successfully')),
        );
        _goBackToDocuments();
        _loadDocuments(_currentCollection); // Refresh documents
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting document: $e')),
        );
      }
    }
  }
  
  Future<void> _editDocumentField(String field, dynamic value) async {
    if (_currentCollection.isEmpty || _currentDocumentId.isEmpty) return;
    
    final initialValue = value is Map || value is List ? null : value.toString();
    final TextEditingController controller = TextEditingController(text: initialValue);
    
    if (value is Map || value is List) {
      // For complex types, we'd need a more advanced editor
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complex field types cannot be edited directly'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Show edit dialog
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Field "$field"'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Value',
            border: OutlineInputBorder(),
          ),
          keyboardType: value is num ? TextInputType.number : TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    
    if (newValue != null && newValue != initialValue) {
      // Convert the string value to the original type
      dynamic convertedValue;
      if (value is int) {
        convertedValue = int.tryParse(newValue) ?? 0;
      } else if (value is double) {
        convertedValue = double.tryParse(newValue) ?? 0.0;
      } else if (value is bool) {
        convertedValue = newValue.toLowerCase() == 'true';
      } else {
        convertedValue = newValue;
      }
      
      try {
        // Create update map with just this field
        final updateData = {field: convertedValue};
        
        // Update the document
        await widget.firebaseService.updateFirestoreDocument(
          _currentCollection, 
          _currentDocumentId,
          updateData
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated field "$field" successfully')),
        );
        
        // Refresh the document
        _loadDocument(_currentDocumentId);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating field: $e')),
        );
      }
    }
  }
  
  Future<void> _addNewDocument() async {
    if (_currentCollection.isEmpty) return;
    
    // For simplicity, we'll just add a document with a timestamp
    final data = {
      'created': FieldValue.serverTimestamp(),
      'type': 'new_document',
      'name': 'New Document',
    };
    
    try {
      final docId = await widget.firebaseService.createFirestoreDocument(_currentCollection, data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created new document with ID: $docId')),
      );
      _loadDocuments(_currentCollection); // Refresh the documents
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating document: $e')),
      );
    }
  }
  
  Future<void> _addNewCollection() async {
    // Firestore doesn't allow creating empty collections
    // We need to add a document to create a collection
    
    final TextEditingController collectionController = TextEditingController();
    
    // Show dialog to enter collection name
    final collectionName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: collectionController,
              decoration: const InputDecoration(
                labelText: 'Collection Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: A new document will be created in this collection',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              if (collectionController.text.isNotEmpty) {
                Navigator.of(context).pop(collectionController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Collection name cannot be empty')),
                );
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
    
    if (collectionName != null && collectionName.isNotEmpty) {
      // Create a document in the new collection
      final data = {
        'created': FieldValue.serverTimestamp(),
        'type': 'initial_document',
        'name': 'Initial Document',
        'description': 'Created automatically when collection was created',
      };
      
      try {
        await widget.firebaseService.createFirestoreDocument(collectionName, data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created new collection: $collectionName')),
        );
        _loadCollections(); // Refresh the collections
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating collection: $e')),
        );
      }
    }
  }
  
  // Method to navigate to a collection from search results
  void navigateToCollection(String collectionPath) {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
    });
    
    _loadDocuments(collectionPath);
  }
  
  // Method to navigate to a document from search results
  void navigateToDocument(String collectionPath, String documentId) {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
    });
    
    _loadDocuments(collectionPath).then((_) {
      _loadDocument(documentId);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    // If viewing collections
    if (_currentCollection.isEmpty) {
      return Stack(
        children: [
          Column(
            children: [
              // Search bar for collections
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search collections...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _applyCollectionSearch();
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applyCollectionSearch();
                      });
                    },
                  ),
                ),
              
              // Collections list or loading/error states
              Expanded(
                child: _isLoadingCollections
                    ? const Center(child: CircularProgressIndicator())
                    : _collections.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _errorMessage.isNotEmpty 
                                      ? _errorMessage 
                                      : 'No collections found',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _errorMessage.isNotEmpty ? Colors.red : null,
                                  ),
                                ),
                                if (_errorMessage.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadCollections,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDarkMode 
                                          ? AppColors.primaryGold 
                                          : AppColors.primaryGreen,
                                    ),
                                    child: const Text('Try Again'),
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                    child: Text(
                                      'To resolve this issue, please make sure you have admin privileges in both Realtime Database AND Firestore. Check the security rules to understand what permissions you need.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : _filteredCollections.isEmpty && _searchQuery.isNotEmpty
                            ? Center(
                                child: Text(
                                  'No collections found matching "$_searchQuery"',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredCollections.length,
                                itemBuilder: (context, index) {
                                  final collection = _filteredCollections[index];
                                  return ListTile(
                                    leading: const Icon(Icons.folder),
                                    title: Text(collection),
                                    onTap: () => _loadDocuments(collection),
                                  );
                                },
                              ),
              ),
            ],
          ),
          
          // Search toggle button
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: "searchCollectionsBtn",
              mini: true,
              onPressed: _toggleSearch,
              tooltip: _isSearching ? 'Cancel search' : 'Search collections',
              child: Icon(_isSearching ? Icons.close : Icons.search),
              backgroundColor: isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
            ),
          ),
          
          // Add collection button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _addNewCollection,
              tooltip: 'Create new collection',
              child: const Icon(Icons.create_new_folder),
              backgroundColor: isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
            ),
          ),
        ],
      );
    }
    
    // If viewing documents in a collection
    if (_currentDocumentId.isEmpty) {
      return Stack(
        children: [
          Column(
            children: [
              // Header with navigation
              Container(
                padding: const EdgeInsets.all(16),
                color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _goBackToCollections,
                      tooltip: 'Back to collections',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Collection: $_currentCollection',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isSearching ? Icons.search_off : Icons.search),
                      onPressed: _toggleSearch,
                      tooltip: _isSearching ? 'Cancel search' : 'Search documents',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _loadDocuments(_currentCollection),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
              
              // Search bar for documents
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search documents...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _applyDocumentSearch();
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applyDocumentSearch();
                      });
                    },
                  ),
                ),
              
              // Documents list
              Expanded(
                child: _isLoadingDocuments
                    ? const Center(child: CircularProgressIndicator())
                    : _documents.isEmpty
                        ? const Center(child: Text('No documents found in this collection'))
                        : _filteredDocuments.isEmpty && _searchQuery.isNotEmpty
                            ? Center(
                                child: Text(
                                  'No documents found matching "$_searchQuery"',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredDocuments.length,
                                itemBuilder: (context, index) {
                                  final document = _filteredDocuments[index];
                                  final documentId = document['_id'] as String;
                                  
                                  // Try to get a title for the document
                                  String documentTitle;
                                  if (document.containsKey('name')) {
                                    documentTitle = document['name'].toString();
                                  } else if (document.containsKey('title')) {
                                    documentTitle = document['title'].toString();
                                  } else if (document.containsKey('id')) {
                                    documentTitle = document['id'].toString();
                                  } else {
                                    documentTitle = documentId;
                                  }
                                  
                                  return ListTile(
                                    leading: const Icon(Icons.description),
                                    title: Text(documentTitle),
                                    subtitle: Text(
                                      'ID: $documentId',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    onTap: () => _loadDocument(documentId),
                                  );
                                },
                              ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _addNewDocument,
              tooltip: 'Add new document',
              child: const Icon(Icons.add),
              backgroundColor: isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
            ),
          ),
        ],
      );
    }
    
    // If viewing a specific document
    return Column(
      children: [
        // Header with navigation
        Container(
          padding: const EdgeInsets.all(16),
          color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBackToDocuments,
                tooltip: 'Back to documents',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collection: $_currentCollection',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Document: $_currentDocumentId',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.red[400],
                ),
                onPressed: _deleteDocument,
                tooltip: 'Delete document',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadDocument(_currentDocumentId),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        
        // Document fields
        Expanded(
          child: _isLoadingDocument
              ? const Center(child: CircularProgressIndicator())
              : _currentDocument == null
                  ? const Center(child: Text('Document not found'))
                  : ListView.builder(
                      itemCount: _currentDocument!.length,
                      itemBuilder: (context, index) {
                        final field = _currentDocument!.keys.elementAt(index);
                        final value = _currentDocument![field];
                        
                        // Skip the _id field as it's not a real field
                        if (field == '_id') return const SizedBox.shrink();
                        
                        // Format timestamps nicely
                        String valueText;
                        if (value is Timestamp) {
                          valueText = DateTime.fromMillisecondsSinceEpoch(
                            value.millisecondsSinceEpoch
                          ).toString();
                        } else if (value is Map) {
                          valueText = '{...} (Object with ${value.length} fields)';
                        } else if (value is List) {
                          valueText = '[...] (Array with ${value.length} items)';
                        } else {
                          valueText = value.toString();
                        }
                        
                        return ListTile(
                          title: Text(
                            field,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            valueText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editDocumentField(field, value),
                            tooltip: 'Edit field',
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}