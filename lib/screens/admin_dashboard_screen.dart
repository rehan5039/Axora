import 'package:flutter/material.dart';
import 'package:axora/services/meditation_service.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/screens/admin_challenge_management_screen.dart';
import 'package:axora/utils/constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _meditationService = MeditationService();
  bool _isLoading = true;
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
      final isAdmin = await _meditationService.isAdmin();
      
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isAdmin
              ? _buildAdminDashboard(isDarkMode)
              : const Center(child: Text('Unauthorized Access')),
    );
  }

  Widget _buildAdminDashboard(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Features',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureGrid(isDarkMode),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.security),
              label: const Text('Admin Setup (Grant Database Permissions)'),
              onPressed: () => Navigator.of(context).pushNamed('/admin-setup'),
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(bool isDarkMode) {
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildFeatureCard(
          icon: Icons.spa,
          title: 'Manage Meditation Content',
          subtitle: 'Add, edit, or delete meditation content',
          onTap: () => Navigator.of(context).pushNamed('/admin-meditation'),
          color: cardColor,
          textColor: textColor,
          iconColor: isDarkMode ? Colors.purpleAccent : Colors.deepPurple,
        ),
        _buildFeatureCard(
          icon: Icons.timer,
          title: 'Custom Meditations',
          subtitle: 'Manage timed meditations (5, 10, 15, 30 min)',
          onTap: () => Navigator.of(context).pushNamed('/admin-custom-meditation'),
          color: cardColor,
          textColor: textColor,
          iconColor: isDarkMode ? Colors.orangeAccent : Colors.orange,
        ),
        _buildFeatureCard(
          icon: Icons.people,
          title: 'User Management',
          subtitle: 'View and manage user accounts',
          onTap: () => Navigator.of(context).pushNamed('/admin-user-management'),
          color: cardColor,
          textColor: textColor,
          iconColor: isDarkMode ? Colors.blueAccent : Colors.blue,
        ),
        _buildFeatureCard(
          icon: Icons.analytics,
          title: 'Analytics',
          subtitle: 'View app usage statistics',
          onTap: () {
            // This feature will be implemented later
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feature coming soon')),
            );
          },
          color: cardColor,
          textColor: textColor,
          iconColor: isDarkMode ? Colors.greenAccent : Colors.green,
        ),
        _buildFeatureCard(
          icon: Icons.emoji_events,
          title: 'Challenges',
          subtitle: 'Create and manage user challenges and polls',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminChallengeManagementScreen(),
              ),
            );
          },
          color: cardColor,
          textColor: textColor,
          iconColor: isDarkMode ? Colors.redAccent : Colors.red,
        ),
        _buildFeatureCard(
          icon: Icons.storage,
          title: 'Database Management',
          subtitle: 'View and delete database items',
          onTap: () => Navigator.of(context).pushNamed('/admin-database-management'),
          color: cardColor,
          textColor: textColor,
          iconColor: isDarkMode ? Colors.tealAccent : Colors.teal,
        ),
        _buildFeatureCard(
          icon: Icons.settings,
          title: 'App Settings',
          subtitle: 'Configure global app settings',
          onTap: () {
            // This feature will be implemented later
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feature coming soon')),
            );
          },
          color: cardColor,
          textColor: textColor,
          iconColor: isDarkMode ? Colors.amberAccent : Colors.amber,
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color? color,
    required Color textColor,
    required Color iconColor,
  }) {
    return Card(
      elevation: 4,
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 40,
                color: iconColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 