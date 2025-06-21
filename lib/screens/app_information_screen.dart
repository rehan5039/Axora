import 'package:flutter/material.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppInformationScreen extends StatefulWidget {
  const AppInformationScreen({Key? key}) : super(key: key);

  @override
  State<AppInformationScreen> createState() => _AppInformationScreenState();
}

class _AppInformationScreenState extends State<AppInformationScreen> {
  String _version = '2.0.3';
  String _buildNumber = '1';
  String _packageName = 'com.axora.meditation';
  String _platformVersion = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      // Get package info
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _packageName = packageInfo.packageName;
        
        // Determine platform
        if (kIsWeb) {
          _platformVersion = 'Web';
        } else if (Platform.isAndroid) {
          _platformVersion = 'Android ${Platform.operatingSystemVersion}';
        } else if (Platform.isIOS) {
          _platformVersion = 'iOS ${Platform.operatingSystemVersion}';
        } else {
          _platformVersion = Platform.operatingSystem;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      // In case of error, use default values
      setState(() {
        _platformVersion = 'Unknown';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('App Information'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildInfoSection(
              context,
              'App Details',
              'Name: Axora\nVersion: $_version (Build $_buildNumber)\nPackage: $_packageName\nPlatform: $_platformVersion'
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              context,
              'About Axora',
              'Axora is a comprehensive meditation and mindfulness application designed to help users achieve mental well-being through guided meditation practices. The app offers a structured journey to build a consistent meditation habit with content specifically designed for beginners and experienced practitioners alike.'
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              context,
              'Features',
              '• Progressive 30-day meditation journey\n• Daily guided meditation sessions\n• Mindfulness reminders and notifications\n• Flow tracking for consistency\n• Audio and text-based content\n• Community support and challenges\n• Customizable meditation experiences\n• User progress tracking and statistics'
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              context,
              'Technical Information',
              'Framework: Flutter\nDatabase: Firebase\nAuthentication: Firebase Auth\nStorage: Firebase Cloud Storage\nMessaging: Firebase Cloud Messaging\nAnalytics: Firebase Analytics\n\nDevelopment Started: April 21, 2025\nLatest Release: June 20, 2025'
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              context,
              'Support & Contact',
              'For any issues or questions regarding the app, please contact our support team at:\n\naxora.app@gmail.com\n\nOr visit our website:\nwww.axora-we.web.app'
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              context,
              'Acknowledgements',
              'This app was built with Flutter and Firebase. Special thanks to all the contributors and the open source community.'
            ),
          ],
        ),
    );
  }
  
  Widget _buildInfoSection(BuildContext context, String title, String content) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 16,
            color: secondaryTextColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }
} 