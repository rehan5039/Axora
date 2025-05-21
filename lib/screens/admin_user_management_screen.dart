import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/services/user_management_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> with SingleTickerProviderStateMixin {
  final _userManagementService = UserManagementService();
  bool _isLoading = true;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _activityLogs = [];
  late TabController _tabController;
  String? _searchQuery;
  bool _filterAnonymous = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdminAndLoadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _checkAdminAndLoadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isAdmin = await _userManagementService.isAdmin();
      
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

      await _loadUserData();
      await _loadActivityLogs();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
  
  Future<void> _loadUserData() async {
    try {
      final users = await _userManagementService.getAllUsers();
      
      if (mounted) {
        setState(() {
          _users = users;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadActivityLogs() async {
    try {
      final logs = await _userManagementService.getAdminActivityLogs();
      
      if (mounted) {
        setState(() {
          _activityLogs = logs;
        });
      }
    } catch (e) {
      print('Error loading activity logs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading activity logs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    
    await _loadUserData();
    await _loadActivityLogs();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _makeUserAdmin(String userId, String userEmail) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _userManagementService.makeUserAdmin(userId, userEmail);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userEmail is now an admin'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh data
          await _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to make $userEmail an admin'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error making user admin: $e');
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
      }
    }
  }
  
  Future<void> _removeAdminPrivileges(String userId, String userEmail) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _userManagementService.removeAdminPrivileges(userId, userEmail);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Admin privileges removed from $userEmail'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh data
          await _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove admin privileges from $userEmail'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error removing admin privileges: $e');
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
      }
    }
  }
  
  Future<void> _deleteUser(String userId, String userEmail) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _userManagementService.deleteUser(userId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User $userEmail deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh data
          await _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete user $userEmail'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error deleting user: $e');
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
      }
    }
  }
  
  Future<void> _deleteAllAnonymousAccounts() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final result = await _userManagementService.deleteAllAnonymousAccounts();
      
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted ${result['successCount']} anonymous accounts. Failed: ${result['failureCount']}'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh data
          await _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete anonymous accounts: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error deleting anonymous accounts: $e');
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
      }
    }
  }
  
  // Get filtered users based on search query and anonymous filter
  List<Map<String, dynamic>> get _filteredUsers {
    List<Map<String, dynamic>> filteredList = _users;
    
    // Apply anonymous filter if enabled
    if (_filterAnonymous) {
      filteredList = filteredList.where((user) => user['isAnonymous'] == true).toList();
    }
    
    // Apply search query if provided
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filteredList = filteredList.where((user) {
        final email = (user['email'] as String?) ?? '';
        final displayName = (user['displayName'] as String?) ?? '';
        
        return email.toLowerCase().contains(query) || 
               displayName.toLowerCase().contains(query);
      }).toList();
    }
    
    return filteredList;
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'USERS'),
            Tab(text: 'ACTIVITY LOGS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(isDarkMode),
                _buildActivityLogsTab(isDarkMode),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : () => _showDeleteAnonymousAccountsDialog(),
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Delete All Anonymous'),
              backgroundColor: isDarkMode ? Colors.redAccent : Colors.red,
            )
          : null,
    );
  }
  
  Widget _buildUsersTab(bool isDarkMode) {
    final cardBgColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    // Count anonymous users
    final anonymousCount = _users.where((user) => user['isAnonymous'] == true).length;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search users by email or name',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              // Anonymous filter toggle
              SwitchListTile(
                title: Text(
                  'Show only anonymous users',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'Anonymous accounts: $anonymousCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                value: _filterAnonymous,
                onChanged: (value) {
                  setState(() {
                    _filterAnonymous = value;
                  });
                },
                dense: true,
                activeColor: Colors.red,
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(color: textColor),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    final email = user['email'] as String? ?? 'No email';
                    final displayName = user['displayName'] as String? ?? 'No name';
                    final isUserAdmin = user['isAdmin'] as bool? ?? false;
                    final isAnonymous = user['isAnonymous'] as bool? ?? false;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: cardBgColor,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isUserAdmin
                              ? Colors.purpleAccent
                              : isAnonymous
                                  ? Colors.redAccent
                                  : isDarkMode
                                      ? Colors.blueGrey
                                      : Colors.blue[100],
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : email.isNotEmpty
                                    ? email[0].toUpperCase()
                                    : '?',
                            style: TextStyle(
                              color: isUserAdmin
                                  ? Colors.white
                                  : isDarkMode
                                      ? Colors.white
                                      : Colors.blue[900],
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName, 
                                style: TextStyle(color: textColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isAnonymous)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Guest',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            if (isUserAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Admin',
                                  style: TextStyle(
                                    color: Colors.purpleAccent,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          email, 
                          style: TextStyle(color: textColor.withOpacity(0.7)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            switch (value) {
                              case 'view':
                                _showUserDetailsDialog(user, isDarkMode);
                                break;
                              case 'makeAdmin':
                                _showMakeAdminDialog(user['id'] as String, email);
                                break;
                              case 'removeAdmin':
                                _showRemoveAdminDialog(user['id'] as String, email);
                                break;
                              case 'delete':
                                _showDeleteUserDialog(user['id'] as String, email);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 18),
                                  SizedBox(width: 8),
                                  Text('View Details'),
                                ],
                              ),
                            ),
                            if (!isUserAdmin)
                              const PopupMenuItem(
                                value: 'makeAdmin',
                                child: Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings, size: 18),
                                    SizedBox(width: 8),
                                    Text('Make Admin'),
                                  ],
                                ),
                              ),
                            if (isUserAdmin)
                              const PopupMenuItem(
                                value: 'removeAdmin',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_remove, size: 18),
                                    SizedBox(width: 8),
                                    Text('Remove Admin'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Delete User', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showUserDetailsDialog(user, isDarkMode),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildActivityLogsTab(bool isDarkMode) {
    final cardBgColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return _activityLogs.isEmpty
        ? Center(
            child: Text(
              'No activity logs found',
              style: TextStyle(color: textColor),
            ),
          )
        : ListView.builder(
            itemCount: _activityLogs.length,
            itemBuilder: (context, index) {
              final log = _activityLogs[index];
              final action = log['action'] as String? ?? 'Unknown action';
              final targetUserEmail = log['targetUserEmail'] as String? ?? 'Unknown user';
              final performedByEmail = log['performedByEmail'] as String? ?? 'Unknown admin';
              final timestamp = log['timestamp'] as dynamic;
              final date = timestamp != null && timestamp is Map && timestamp.containsKey('seconds')
                  ? DateTime.fromMillisecondsSinceEpoch((timestamp['seconds'] as int) * 1000)
                  : DateTime.now();
              
              IconData actionIcon;
              Color actionColor;
              
              switch (action) {
                case 'make_admin':
                  actionIcon = Icons.admin_panel_settings;
                  actionColor = Colors.green;
                  break;
                case 'remove_admin':
                  actionIcon = Icons.person_remove;
                  actionColor = Colors.orange;
                  break;
                case 'delete_user':
                  actionIcon = Icons.delete;
                  actionColor = Colors.red;
                  break;
                case 'delete_anonymous_accounts':
                  actionIcon = Icons.delete_sweep;
                  actionColor = Colors.red;
                  break;
                case 'ban_user':
                  actionIcon = Icons.block;
                  actionColor = Colors.red;
                  break;
                default:
                  actionIcon = Icons.info;
                  actionColor = Colors.blue;
              }
              
              String actionText;
              switch (action) {
                case 'make_admin':
                  actionText = '$performedByEmail made $targetUserEmail an admin';
                  break;
                case 'remove_admin':
                  actionText = '$performedByEmail removed admin privileges from $targetUserEmail';
                  break;
                case 'delete_user':
                  actionText = '$performedByEmail deleted user $targetUserEmail';
                  break;
                case 'delete_anonymous_accounts':
                  final count = log['count'] as int? ?? 0;
                  actionText = '$performedByEmail deleted $count anonymous accounts';
                  break;
                case 'ban_user':
                  actionText = '$performedByEmail banned $targetUserEmail';
                  break;
                default:
                  actionText = '$performedByEmail performed action on $targetUserEmail';
              }
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: cardBgColor,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: actionColor.withOpacity(0.2),
                    child: Icon(actionIcon, color: actionColor),
                  ),
                  title: Text(actionText, style: TextStyle(color: textColor)),
                  subtitle: Text(
                    'Date: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}',
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
                ),
              );
            },
          );
  }
  
  void _showMakeAdminDialog(String userId, String userEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make User Admin'),
        content: Text('Are you sure you want to make $userEmail an admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _makeUserAdmin(userId, userEmail);
            },
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }
  
  void _showRemoveAdminDialog(String userId, String userEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin Privileges'),
        content: Text('Are you sure you want to remove admin privileges from $userEmail?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeAdminPrivileges(userId, userEmail);
            },
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteUserDialog(String userId, String userEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete user $userEmail?\n\n'
          'This will permanently remove all user data including progress and cannot be undone.',
          style: const TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(userId, userEmail);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteAnonymousAccountsDialog() {
    // Count anonymous users
    final anonymousCount = _users.where((user) => user['isAnonymous'] == true).length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Anonymous Accounts'),
        content: Text(
          'Are you sure you want to delete all anonymous guest accounts?\n\n'
          'This will permanently remove $anonymousCount anonymous accounts and their data.\n'
          'This action cannot be undone.',
          style: const TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllAnonymousAccounts();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );
  }
  
  void _showUserDetailsDialog(Map<String, dynamic> user, bool isDarkMode) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final email = user['email'] as String? ?? 'No email';
    final displayName = user['displayName'] as String? ?? 'No name';
    final isUserAdmin = user['isAdmin'] as bool? ?? false;
    final isAnonymous = user['isAnonymous'] as bool? ?? false;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details', style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('User ID', user['id'] as String),
            const SizedBox(height: 8),
            _buildDetailRow('Email', email),
            const SizedBox(height: 8),
            _buildDetailRow('Display Name', displayName),
            const SizedBox(height: 8),
            _buildDetailRow('Admin Status', isUserAdmin ? 'Admin' : 'Regular User'),
            const SizedBox(height: 8),
            _buildDetailRow('Account Type', isAnonymous ? 'Anonymous Guest' : 'Registered User'),
          ],
        ),
        actions: [
          // Close button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          
          // Reset Account button
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showResetAccountDialog(user['id'] as String, email);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('RESET ACCOUNT'),
          ),
          
          // Edit Flow button
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditFlowDialog(user['id'] as String, email);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: const Text('EDIT FLOW'),
          ),
          
          // Edit Day button
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditDayDialog(user['id'] as String, email);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('EDIT DAY'),
          ),
          
          // Admin status toggle button
          if (!isUserAdmin)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showMakeAdminDialog(user['id'] as String, email);
              },
              child: const Text('MAKE ADMIN'),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showRemoveAdminDialog(user['id'] as String, email);
              },
              child: const Text('REMOVE ADMIN'),
            ),
          
          // Delete User button
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteUserDialog(user['id'] as String, email);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE USER'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
  
  Future<void> _resetUserAccount(String userId, String userEmail) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _userManagementService.resetUserAccount(userId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account reset for $userEmail'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh data
          await _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reset account for $userEmail'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error resetting user account: $e');
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
      }
    }
  }
  
  Future<void> _editUserFlow(String userId, String userEmail, int newFlowValue) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _userManagementService.editUserFlow(userId, newFlowValue);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Flow updated to $newFlowValue for $userEmail'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh data
          await _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update flow for $userEmail'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error editing user flow: $e');
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
      }
    }
  }
  
  void _showResetAccountDialog(String userId, String userEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset User Account'),
        content: Text(
          'Are you sure you want to reset the account for $userEmail?\n\n'
          'This will reset all progress, flows, and statistics to the initial state. '
          'This action cannot be undone.',
          style: const TextStyle(color: Colors.orange),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetUserAccount(userId, userEmail);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }
  
  void _showEditFlowDialog(String userId, String userEmail) {
    final TextEditingController _flowController = TextEditingController();
    bool _isLoading = true;
    int _currentFlow = 0;
    
    // Create a stateful builder to handle loading state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // Function to fetch current flow
          Future<void> _fetchCurrentFlow() async {
            setState(() {
              _isLoading = true;
            });
            
            try {
              // Get the user's current flow from Firestore
              final flowDoc = await FirebaseFirestore.instance
                  .collection('meditation_flow')
                  .doc(userId)
                  .get();
              
              if (flowDoc.exists && flowDoc.data() != null) {
                final flowData = flowDoc.data()!;
                _currentFlow = (flowData['flow'] as num?)?.toInt() ?? 0;
                _flowController.text = _currentFlow.toString();
              } else {
                _currentFlow = 0;
                _flowController.text = '0';
              }
            } catch (e) {
              print('Error fetching flow: $e');
              _currentFlow = 0;
              _flowController.text = '0';
            }
            
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
          
          // Fetch current flow when dialog opens
          if (_isLoading) {
            _fetchCurrentFlow();
          }
          
          return AlertDialog(
            title: const Text('Edit User Flow'),
            content: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Fetching current flow...'),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Enter new flow value for $userEmail:'),
                      const SizedBox(height: 8),
                      Text(
                        'Current Flow: $_currentFlow',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _flowController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Flow Value',
                          hintText: 'Enter a number (0 or greater)',
                        ),
                      ),
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              if (!_isLoading)
                TextButton(
                  onPressed: () {
                    final flowText = _flowController.text.trim();
                    if (flowText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a flow value'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    final flowValue = int.tryParse(flowText);
                    if (flowValue == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid number'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    if (flowValue < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Flow value cannot be negative'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.pop(context);
                    _editUserFlow(userId, userEmail, flowValue);
                  },
                  child: const Text('UPDATE'),
                ),
            ],
          );
        },
      ),
    );
  }
  
  void _showEditDayDialog(String userId, String userEmail) {
    final TextEditingController _dayController = TextEditingController();
    bool _isLoading = true;
    int _currentDay = 1;
    
    // Create a stateful builder to handle loading state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // Function to fetch current day
          Future<void> _fetchCurrentDay() async {
            setState(() {
              _isLoading = true;
            });
            
            try {
              // Get the user's current day from Firestore
              final progressDoc = await FirebaseFirestore.instance
                  .collection('meditation_progress')
                  .doc(userId)
                  .get();
              
              if (progressDoc.exists && progressDoc.data() != null) {
                final progressData = progressDoc.data()!;
                _currentDay = (progressData['currentDay'] as num?)?.toInt() ?? 1;
                _dayController.text = _currentDay.toString();
              } else {
                _currentDay = 1;
                _dayController.text = '1';
              }
            } catch (e) {
              print('Error fetching current day: $e');
              _currentDay = 1;
              _dayController.text = '1';
            }
            
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
          
          // Fetch current day when dialog opens
          if (_isLoading) {
            _fetchCurrentDay();
          }
          
          return AlertDialog(
            title: const Text('Edit User Meditation Day'),
            content: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Fetching current day...'),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Enter new meditation day for $userEmail:'),
                      const SizedBox(height: 8),
                      Text(
                        'Current Day: $_currentDay',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _dayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Day Value',
                          hintText: 'Enter a number (1 or greater)',
                        ),
                      ),
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              if (!_isLoading)
                TextButton(
                  onPressed: () {
                    final dayText = _dayController.text.trim();
                    if (dayText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a day value'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    final dayValue = int.tryParse(dayText);
                    if (dayValue == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid number'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    if (dayValue < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Day value cannot be less than 1'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.pop(context);
                    _editUserDay(userId, userEmail, dayValue);
                  },
                  child: const Text('UPDATE'),
                ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _editUserDay(String userId, String userEmail, int newDayValue) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _userManagementService.editUserMeditationDay(userId, newDayValue);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Meditation day updated to $newDayValue for $userEmail'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh data
          await _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update meditation day for $userEmail'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error editing user meditation day: $e');
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
      }
    }
  }
} 