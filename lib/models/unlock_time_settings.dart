import 'package:cloud_firestore/cloud_firestore.dart';

class UnlockTimeSettings {
  final String userId;
  final DailyUnlockTime unlockTime;
  final DateTime startDate;
  final Timestamp createdAt;
  
  UnlockTimeSettings({
    required this.userId,
    required this.unlockTime,
    required this.startDate,
    required this.createdAt,
  });
  
  factory UnlockTimeSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timeMap = data['unlockTime'] as Map<String, dynamic>;
    
    return UnlockTimeSettings(
      userId: doc.id,
      unlockTime: DailyUnlockTime(
        hour: timeMap['hour'] ?? 7, 
        minute: timeMap['minute'] ?? 0
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'unlockTime': {
        'hour': unlockTime.hour,
        'minute': unlockTime.minute,
      },
      'startDate': Timestamp.fromDate(startDate),
      'createdAt': createdAt,
    };
  }
  
  // Get the next unlock time from now
  DateTime getNextUnlockTime() {
    final now = DateTime.now();
    
    // Create a DateTime for today with the unlock time
    final unlockTimeToday = DateTime(
      now.year,
      now.month,
      now.day,
      unlockTime.hour,
      unlockTime.minute,
    );
    
    // If today's unlock time is in the future, return it
    if (unlockTimeToday.isAfter(now)) {
      return unlockTimeToday;
    }
    
    // Otherwise, return tomorrow's unlock time
    return unlockTimeToday.add(const Duration(days: 1));
  }
  
  // Calculate seconds until next unlock
  int getSecondsUntilNextUnlock() {
    final now = DateTime.now();
    final nextUnlock = getNextUnlockTime();
    
    return nextUnlock.difference(now).inSeconds;
  }
  
  // Get formatted string of time remaining until next day unlocks
  String getFormattedTimeRemaining() {
    final totalSeconds = getSecondsUntilNextUnlock();
    if (totalSeconds <= 0) return "00h 00m 00s";
    
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }
}

class DailyUnlockTime {
  final int hour;
  final int minute;
  
  const DailyUnlockTime({
    required this.hour,
    required this.minute,
  });
  
  String format() {
    final hourString = hour.toString().padLeft(2, '0');
    final minuteString = minute.toString().padLeft(2, '0');
    return '$hourString:$minuteString';
  }
} 