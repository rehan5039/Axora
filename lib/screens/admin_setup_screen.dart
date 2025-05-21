import 'package:flutter/material.dart';
import 'package:axora/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/utils/constants.dart';

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({Key? key}) : super(key: key);

  @override
  _AdminSetupScreenState createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _isAdmin = false;
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }
  
  Future<void> _checkAdminStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final isAdmin = await _firebaseService.canModifyDatabase();
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking admin status: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking admin status: $e')),
      );
    }
  }
  
  Future<void> _makeAdmin() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _firebaseService.addCurrentUserAsAdmin();
      await _checkAdminStatus(); // Refresh admin status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully made you an admin! You can now manage the database.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error making user admin: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error making you an admin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Setup'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    _isAdmin ? Icons.verified_user : Icons.admin_panel_settings,
                    size: 72,
                    color: _isAdmin
                        ? Colors.green
                        : (isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isAdmin
                        ? 'You are an admin!'
                        : 'You need admin privileges',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isAdmin
                        ? 'You can now manage the database.'
                        : 'You need to be an admin to manage the database. Click the button below to make yourself an admin.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (!_isAdmin)
                    ElevatedButton.icon(
                      onPressed: _makeAdmin,
                      icon: const Icon(Icons.security),
                      label: const Text('Make Me Admin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? AppColors.primaryGold
                            : AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/admin-database-management');
                      },
                      icon: const Icon(Icons.storage),
                      label: const Text('Go to Database Management'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
} 