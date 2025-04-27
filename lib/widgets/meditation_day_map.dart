import 'package:flutter/material.dart';
import 'package:axora/models/user_stickers.dart';
import 'package:axora/models/user_progress.dart';
import 'dart:async';

class MeditationDayMap extends StatefulWidget {
  final UserProgress? userProgress;
  final UserStickers? userStickers;
  final bool isDarkMode;
  final int daysToShow;
  final int totalDays;
  final Function(int)? onDayTap;

  const MeditationDayMap({
    super.key,
    required this.userProgress,
    required this.userStickers,
    required this.isDarkMode,
    this.daysToShow = 7,
    this.totalDays = 30, // Assuming a 30-day journey
    this.onDayTap,
  });

  @override
  State<MeditationDayMap> createState() => _MeditationDayMapState();
}

class _MeditationDayMapState extends State<MeditationDayMap> {
  int _startDay = 1;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // If user is past the first week, show their current week
    final currentDay = widget.userProgress?.currentDay ?? 1;
    if (currentDay > widget.daysToShow) {
      _startDay = ((currentDay - 1) ~/ widget.daysToShow) * widget.daysToShow + 1;
    }
    
    // Start a timer to refresh the UI every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _goToPreviousWeek() {
    if (_startDay > widget.daysToShow) {
      setState(() {
        _startDay -= widget.daysToShow;
      });
    }
  }

  void _goToNextWeek() {
    if (_startDay + widget.daysToShow <= widget.totalDays) {
      setState(() {
        _startDay += widget.daysToShow;
      });
    }
  }

  void _goToCurrentDay() {
    final currentDay = widget.userProgress?.currentDay ?? 1;
    setState(() {
      _startDay = ((currentDay - 1) ~/ widget.daysToShow) * widget.daysToShow + 1;
    });
  }

  Duration? _getRemainingTime(int day) {
    if (day == 1) return null; // Day 1 has no timer
    
    final progress = widget.userProgress;
    if (progress == null) return null;
    
    final previousDayCompleted = widget.userStickers?.hasStickerForDay(day - 1) ?? false;
    if (!previousDayCompleted) return null;
    
    final lastCompletedAt = progress.lastCompletedAt?.toDate();
    if (lastCompletedAt == null) return null;
    
    final unlockTime = lastCompletedAt.add(const Duration(hours: 24));
    final now = DateTime.now();
    
    if (now.isAfter(unlockTime)) return null;
    return unlockTime.difference(now);
  }

  bool _isDayUnlocked(int day) {
    if (day == 1) return true; // Day 1 is always unlocked
    
    final progress = widget.userProgress;
    if (progress == null) return false;
    
    // Check if previous day is completed
    final previousDayCompleted = widget.userStickers?.hasStickerForDay(day - 1) ?? false;
    if (!previousDayCompleted) return false;
    
    // Check if this day is already completed
    final isCompleted = widget.userStickers?.hasStickerForDay(day) ?? false;
    if (isCompleted) return true;
    
    // Check if 24 hours have passed since previous day completion
    final lastCompletedAt = progress.lastCompletedAt?.toDate();
    if (lastCompletedAt == null) return false;
    
    final now = DateTime.now();
    final unlockTime = lastCompletedAt.add(const Duration(hours: 24));
    
    return now.isAfter(unlockTime);
  }

  String _getDayStatus(int day, bool isCompleted, bool isCurrentDay) {
    if (isCurrentDay) return 'Today';
    if (isCompleted) return 'Done';
    
    // Check remaining time for next day
    final remainingTime = _getRemainingTime(day);
    if (remainingTime != null) {
      final hours = remainingTime.inHours;
      final minutes = remainingTime.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
    
    return _isDayUnlocked(day) ? 'Ready' : '';
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = widget.userProgress?.currentDay ?? 1;
    final isShowingCurrentDay = currentDay >= _startDay && 
                               currentDay < _startDay + widget.daysToShow;
    
    // Days of the week abbreviations
    final List<String> daysOfWeek = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Week navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: _startDay > 1 
                      ? (widget.isDarkMode ? Colors.white70 : Colors.grey[700])
                      : (widget.isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _startDay > 1 ? _goToPreviousWeek : null,
                ),
                Text(
                  'Days ${_startDay} - ${_startDay + widget.daysToShow - 1}',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: _startDay + widget.daysToShow <= widget.totalDays 
                      ? (widget.isDarkMode ? Colors.white70 : Colors.grey[700])
                      : (widget.isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _startDay + widget.daysToShow <= widget.totalDays ? _goToNextWeek : null,
                ),
              ],
            ),
          ),
          
          // Day circles with connecting lines
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Stack(
              children: [
                // Connecting lines
                Positioned.fill(
                  top: 20,
                  child: CustomPaint(
                    painter: DayConnectionsPainter(
                      startDay: _startDay,
                      daysCount: widget.daysToShow,
                      currentDay: currentDay,
                      userStickers: widget.userStickers,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                ),
                
                // Day circles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(widget.daysToShow, (index) {
                    final day = _startDay + index;
                    final isCompleted = widget.userStickers?.hasStickerForDay(day) ?? false;
                    final isCurrentDay = day == currentDay;
                    final isUnlocked = _isDayUnlocked(day);
                    final dayOfWeekIndex = (index) % 7; // Map to day of week (0=Sunday, 6=Saturday)
                    final dayStatus = _getDayStatus(day, isCompleted, isCurrentDay);

                    return GestureDetector(
                      onTap: isUnlocked ? () => widget.onDayTap?.call(day) : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Day indicator circle
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: isCompleted 
                                  ? Colors.amber // Completed days in yellow/gold
                                  : (widget.isDarkMode ? Colors.grey[800] : Colors.grey[300]), // Unlocked & locked days
                              shape: BoxShape.circle,
                              border: isCurrentDay // Highlight current day with white border
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                              boxShadow: isCurrentDay
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5),
                                        blurRadius: 5,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : Text(
                                    daysOfWeek[dayOfWeekIndex],
                                    style: TextStyle(
                                      color: isUnlocked
                                        ? (widget.isDarkMode ? Colors.white : Colors.black87)
                                        : (widget.isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                                      fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Day status label
                          Text(
                            dayStatus,
                            style: TextStyle(
                              color: isCurrentDay
                                  ? Colors.white
                                  : (widget.isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                              fontSize: 11,
                              fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          
          // Today button if not showing current day
          if (!isShowingCurrentDay)
            TextButton.icon(
              onPressed: _goToCurrentDay,
              icon: const Icon(Icons.today, size: 16),
              label: const Text('Go to Today'),
              style: TextButton.styleFrom(
                foregroundColor: widget.isDarkMode ? Colors.deepPurple[200] : Colors.blue[700],
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                minimumSize: const Size(0, 24), // Reduce minimum size
                tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap target
              ),
            ),
        ],
      ),
    );
  }
}

class DayConnectionsPainter extends CustomPainter {
  final int startDay;
  final int daysCount;
  final int currentDay;
  final UserStickers? userStickers;
  final bool isDarkMode;

  DayConnectionsPainter({
    required this.startDay,
    required this.daysCount,
    required this.currentDay,
    required this.userStickers,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final circleSpacing = width / daysCount;
    final centerY = size.height / 2;
    final strokeWidth = 3.0;

    // Create paints for different states
    final completedLinePaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final uncompletedLinePaint = Paint()
      ..color = isDarkMode ? Colors.grey[700]! : Colors.grey[400]!
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw connection lines between days
    for (int i = 0; i < daysCount - 1; i++) {
      final currentLineDay = startDay + i;
      final nextLineDay = startDay + i + 1;
      
      final startX = (i * circleSpacing) + (circleSpacing / 2);
      final endX = ((i + 1) * circleSpacing) + (circleSpacing / 2);
      
      final isStartCompleted = userStickers?.hasStickerForDay(currentLineDay) ?? false;
      final isEndCompleted = userStickers?.hasStickerForDay(nextLineDay) ?? false;
      
      // Determine the paint to use based on completion status
      final paint = (isStartCompleted && isEndCompleted)
          ? completedLinePaint
          : uncompletedLinePaint;
      
      // Draw the line
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(endX, centerY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 