import 'package:flutter/material.dart';

class AdminAccountManagement extends StatefulWidget {
  @override
  _AdminAccountManagementState createState() => _AdminAccountManagementState();
}

class _AdminAccountManagementState extends State<AdminAccountManagement> {
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  void _handleDeleteAnonymousAccounts() {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    // Simulate an API call to delete anonymous accounts
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _result = {
          'success': true,
          'deletedIds': ['user1', 'user2', 'user3'],
          'successCount': 3,
          'failureCount': 0,
          'message': 'Anonymous accounts deleted successfully'
        };
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Account Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            // Delete anonymous accounts section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anonymous Accounts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Warning: This only deletes Firestore data for anonymous users. Authentication records must be deleted from the Firebase console or using Cloud Functions.',
                      style: TextStyle(color: Colors.red),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleDeleteAnonymousAccounts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Delete All Anonymous Data'),
                    ),
                    if (_result != null) ...[
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.all(8),
                        color: _result!['success'] ? Colors.green[100] : Colors.red[100],
                        child: Text(_result!['message'] ?? _result!['error'] ?? 'Unknown result'),
                      ),
                      if (_result!['success'] && _result!['deletedIds'] != null) ...[
                        SizedBox(height: 10),
                        Text('Deleted ${_result!['successCount']} accounts. Failed: ${_result!['failureCount']}'),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 