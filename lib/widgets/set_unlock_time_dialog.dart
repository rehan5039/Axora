import 'package:flutter/material.dart';
import 'package:axora/services/meditation_service.dart';
import 'package:axora/models/unlock_time_settings.dart';

class SetUnlockTimeDialog extends StatefulWidget {
  final Function? onTimeSet;
  
  const SetUnlockTimeDialog({super.key, this.onTimeSet});

  @override
  State<SetUnlockTimeDialog> createState() => _SetUnlockTimeDialogState();
}

class _SetUnlockTimeDialogState extends State<SetUnlockTimeDialog> {
  final _meditationService = MeditationService();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Daily Unlock Time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Congratulations on completing the day! Please set a daily time when you would like the next day to be unlocked automatically.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 10),
                  Text(
                    _formatTimeOfDay(_selectedTime),
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Every day at this time, a new meditation day will be unlocked for you.',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveUnlockTime,
          child: const Text('Set Time'),
        ),
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _saveUnlockTime() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert Flutter's TimeOfDay to our custom DailyUnlockTime
      final result = await _meditationService.saveUnlockTimeSettings(_selectedTime);
      
      if (result) {
        if (widget.onTimeSet != null) {
          widget.onTimeSet!();
        }
        
        if (mounted) {
          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Daily unlock time set to ${_formatTimeOfDay(_selectedTime)}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to set unlock time. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Show error
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
          _isLoading = false;
        });
      }
    }
  }
} 