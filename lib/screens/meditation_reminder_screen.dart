import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/services/notification_service.dart';
import 'package:axora/services/user_database_service.dart';
import 'package:axora/services/realtime_database_service.dart';
import 'package:timezone/timezone.dart' as tz;

class MeditationReminderScreen extends StatefulWidget {
  const MeditationReminderScreen({super.key});

  @override
  State<MeditationReminderScreen> createState() => _MeditationReminderScreenState();
}

class _MeditationReminderScreenState extends State<MeditationReminderScreen> {
  final TextEditingController _reminderTextController = TextEditingController();
  
  final NotificationService _notificationService = NotificationService();
  final UserDatabaseService _firestoreService = UserDatabaseService();
  final RealtimeDatabaseService _realtimeDbService = RealtimeDatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  TimeOfDay _selectedTime = TimeOfDay(hour: 8, minute: 0); // Default 8:00 AM
  bool _isReminderEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _loadReminderSettings();
    _requestNotificationPermission();
  }
  
  Future<void> _requestNotificationPermission() async {
    await _notificationService.requestPermissions();
  }
  
  Future<void> _loadReminderSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Load from user database
      final userData = await _firestoreService.getUserById(user.uid);
      if (userData != null && 
          userData.containsKey('userSettings') && 
          userData['userSettings'] is Map &&
          userData['userSettings'].containsKey('meditationReminder')) {
          
        final reminderSettings = userData['userSettings']['meditationReminder'] as Map<String, dynamic>;
        
        setState(() {
          _isReminderEnabled = reminderSettings['enabled'] ?? false;
          
          if (reminderSettings.containsKey('reminderText')) {
            _reminderTextController.text = reminderSettings['reminderText'] as String;
          }
          
          if (reminderSettings.containsKey('hour') && reminderSettings.containsKey('minute')) {
            _selectedTime = TimeOfDay(
              hour: reminderSettings['hour'] as int, 
              minute: reminderSettings['minute'] as int
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading meditation reminder settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _saveReminderSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Prepare settings data
      final reminderSettings = {
        'enabled': _isReminderEnabled,
        'reminderText': _reminderTextController.text,
        'hour': _selectedTime.hour,
        'minute': _selectedTime.minute,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Save to user settings
      await _firestoreService.updateUserSettings(
        user.uid, 
        {'meditationReminder': reminderSettings}
      );
      
      // Also save to realtime database
      await _realtimeDbService.updateUserSettings(
        user.uid, 
        {'meditationReminder': reminderSettings}
      );
      
      // If enabled, schedule the notification
      if (_isReminderEnabled) {
        await _scheduleReminderNotification();
      } else {
        // Cancel existing reminder notification
        await _notificationService.cancelNotification(9000); // Use consistent ID for meditation reminder
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Meditation reminder settings saved'))
        );
      }
    } catch (e) {
      debugPrint('Error saving meditation reminder settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: ${e.toString()}'))
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _scheduleReminderNotification() async {
    try {
      // Get user name for personalized notification
      final user = _auth.currentUser;
      final userName = user?.displayName ?? 'User';
      
      // Schedule the daily reminder
      await _notificationService.scheduleDailyMeditationReminder(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        userName: userName,
        customMessage: _reminderTextController.text,
      );
      
      debugPrint('Daily meditation reminder scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling meditation reminder: $e');
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }
  
  @override
  void dispose() {
    _reminderTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Meditation Reminder'),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Enable Daily Reminder'),
                  subtitle: const Text('Receive a notification at your selected time'),
                  value: _isReminderEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isReminderEnabled = value;
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                if (_isReminderEnabled) ...[
                  const Text(
                    'Custom Reminder Text',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter what you will do after receiving this reminder:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reminderTextController,
                    decoration: InputDecoration(
                      hintText: 'e.g., "I will meditate now"',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Reminder Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Set daily reminder time'),
                    subtitle: Text(
                      '${_selectedTime.format(context)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _selectTime(context),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Divider(),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Preview:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi ${_auth.currentUser?.displayName ?? 'User'}, Tumhara meditation session ready hai.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_reminderTextController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(_reminderTextController.text),
                          ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveReminderSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Reminder Settings'),
                  ),
                ),
              ],
            ),
          ),
    );
  }
} 