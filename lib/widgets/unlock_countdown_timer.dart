import 'dart:async';
import 'package:flutter/material.dart';
import 'package:axora/services/meditation_service.dart';

class UnlockCountdownTimer extends StatefulWidget {
  const UnlockCountdownTimer({super.key});

  @override
  State<UnlockCountdownTimer> createState() => _UnlockCountdownTimerState();
}

class _UnlockCountdownTimerState extends State<UnlockCountdownTimer> {
  final _meditationService = MeditationService();
  String _timeRemaining = "--:--:--";
  DateTime? _nextUnlockTime;
  Timer? _timer;
  bool _hasSettings = false;
  
  @override
  void initState() {
    super.initState();
    _loadUnlockTime();
    // Update timer every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadUnlockTime() async {
    try {
      final settings = await _meditationService.getUnlockTimeSettings();
      if (settings != null) {
        setState(() {
          _hasSettings = true;
          _nextUnlockTime = settings.getNextUnlockTime();
          _updateTime();
        });
      }
    } catch (e) {
      debugPrint('Error loading unlock time: $e');
    }
  }
  
  void _updateTime() {
    if (_nextUnlockTime == null) return;
    
    final now = DateTime.now();
    final difference = _nextUnlockTime!.difference(now);
    
    // If difference is negative, reload the next unlock time
    if (difference.isNegative) {
      _loadUnlockTime();
      return;
    }
    
    final hours = difference.inHours;
    final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
    
    setState(() {
      _timeRemaining = '$hours:$minutes:$seconds';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_hasSettings) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 18),
          const SizedBox(width: 8),
          Text(
            'Next unlock in $_timeRemaining',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
} 