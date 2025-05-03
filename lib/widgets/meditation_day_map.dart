import 'package:flutter/material.dart';
import 'package:axora/models/user_flow.dart';
import 'package:axora/models/user_progress.dart';
import 'package:axora/models/meditation_content.dart';
import 'dart:async';

class MeditationDayMap extends StatefulWidget {
  final UserProgress? userProgress;
  final UserFlow? userFlow;
  final bool isDarkMode;
  final int daysToShow;
  final int totalDays;
  final Function(MeditationContent)? onDayTap;

  const MeditationDayMap({
    super.key,
    required this.userProgress,
    required this.userFlow,
    required this.isDarkMode,
    this.daysToShow = 7,
    this.totalDays = 35, // Increasing default to 35 days
    this.onDayTap,
  });

  @override
  State<MeditationDayMap> createState() => _MeditationDayMapState();
}

class _MeditationDayMapState extends State<MeditationDayMap> with SingleTickerProviderStateMixin {
  int _startDay = 1;
  Timer? _refreshTimer;
  int? _holdingDayIndex;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  double _dragStartX = 0;
  bool _isDragging = false;
  bool _isHolding = false;
  int _lastHorizontalDirection = 0; // -1 for left, 1 for right, 0 for none
  bool _hasMovedWhileHolding = false;
  
  // Animation for week transitions
  bool _isAnimatingWeek = false;
  int _previousStartDay = 1;
  double _weekTransitionProgress = 1.0;
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    // If user is past the first week, show their current week
    final currentDay = widget.userProgress?.currentDay ?? 1;
    if (currentDay > widget.daysToShow) {
      _startDay = ((currentDay - 1) ~/ widget.daysToShow) * widget.daysToShow + 1;
      _previousStartDay = _startDay;
      
      // Ensure we don't go beyond valid ranges
      _startDay = _clampStartDay(_startDay);
    }
    
    // Start a timer to refresh the UI every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _transitionTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Helper to ensure start day is within valid range
  int _clampStartDay(int startDay) {
    final lastPossibleStartDay = ((widget.totalDays - 1) ~/ widget.daysToShow) * widget.daysToShow + 1;
    if (startDay > lastPossibleStartDay) {
      return lastPossibleStartDay;
    }
    return startDay > 0 ? startDay : 1;
  }

  void _animateToWeek(int targetStartDay, bool forward) {
    if (_isAnimatingWeek) {
      _transitionTimer?.cancel();
    }
    
    setState(() {
      _isAnimatingWeek = true;
      _previousStartDay = _startDay;
      _startDay = targetStartDay;
      _weekTransitionProgress = forward ? 0.0 : 1.0;
    });
    
    // Keep the same 500ms duration for web
    const transitionDuration = Duration(milliseconds: 500);
    const frameDuration = Duration(milliseconds: 16); // ~60fps
    final steps = transitionDuration.inMilliseconds ~/ frameDuration.inMilliseconds;
    final step = forward ? 1.0 / steps : -1.0 / steps;
    var progress = forward ? 0.0 : 1.0;
    
    _transitionTimer = Timer.periodic(frameDuration, (timer) {
      progress += step;
      if ((forward && progress >= 1.0) || (!forward && progress <= 0.0)) {
        progress = forward ? 1.0 : 0.0;
        timer.cancel();
        if (mounted) {
          setState(() {
            _isAnimatingWeek = false;
            _weekTransitionProgress = 1.0;
          });
        }
      } else if (mounted) {
        setState(() {
          _weekTransitionProgress = forward ? progress : 1.0 - progress;
        });
      }
    });
  }

  void _goToPreviousWeek() {
    if (_startDay > 1) {
      final newStartDay = _clampStartDay(_startDay - widget.daysToShow);
      _animateToWeek(newStartDay, false);
    }
  }

  void _goToNextWeek() {
    final lastStartDay = ((widget.totalDays - 1) ~/ widget.daysToShow) * widget.daysToShow + 1;
    if (_startDay < lastStartDay) {
      final newStartDay = _clampStartDay(_startDay + widget.daysToShow);
      _animateToWeek(newStartDay, true);
    }
  }

  void _goToCurrentDay() {
    final currentDay = widget.userProgress?.currentDay ?? 1;
    final newStartDay = _clampStartDay(((currentDay - 1) ~/ widget.daysToShow) * widget.daysToShow + 1);
    
    if (newStartDay > _startDay) {
      _animateToWeek(newStartDay, true);
    } else if (newStartDay < _startDay) {
      _animateToWeek(newStartDay, false);
    }
  }

  void _startHolding(int index) {
    print("Started holding day at index $index");
    setState(() {
      _holdingDayIndex = index;
      _isHolding = true;
      _hasMovedWhileHolding = false;
    });
    _animationController.forward();
  }

  void _stopHolding() {
    print("Stopped holding");
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _holdingDayIndex = null;
          _isHolding = false;
          _lastHorizontalDirection = 0;
          _hasMovedWhileHolding = false;
        });
      }
    });
  }

  void _swipeToDay(int index) {
    if (_holdingDayIndex != null && index >= 0 && index < widget.daysToShow) {
      // If we're already at this index, don't update
      if (index == _holdingDayIndex) return;
      
      print("Swiping from day ${_startDay + _holdingDayIndex!} to day ${_startDay + index}");
      
      // Check if we need to switch weeks
      if (index == widget.daysToShow - 1 && _holdingDayIndex == widget.daysToShow - 1) {
        // We're at the last day and trying to go further right
        if (_startDay + widget.daysToShow <= widget.totalDays) {
          _goToNextWeek();
          setState(() {
            _holdingDayIndex = 0; // Move to first day of next week
            _hasMovedWhileHolding = true;
          });
        }
      } else if (index == 0 && _holdingDayIndex == 0) {
        // We're at the first day and trying to go further left
        if (_startDay > widget.daysToShow) {
          _goToPreviousWeek();
          setState(() {
            _holdingDayIndex = widget.daysToShow - 1; // Move to last day of previous week
            _hasMovedWhileHolding = true;
          });
        }
      } else {
        // Normal day switch within the same week
        setState(() {
          _holdingDayIndex = index;
          _hasMovedWhileHolding = true;
        });
      }
    }
  }

  // Helper to calculate which day index is at a specific position
  int _getDayIndexAtPosition(Offset position, Size containerSize) {
    final width = containerSize.width;
    final dayWidth = width / widget.daysToShow;
    final index = (position.dx / dayWidth).floor();
    
    // Ensure the index is within bounds
    if (index < 0) return 0;
    if (index >= widget.daysToShow) return widget.daysToShow - 1;
    return index;
  }

  // Additional helper for continuous dragging
  void _handleDragAtEdge(Offset position, Size containerSize) {
    if (!_isHolding || _holdingDayIndex == null) return;
    
    final width = containerSize.width;
    
    // Check if we're at the edges
    if (position.dx >= width - 20 && _holdingDayIndex == widget.daysToShow - 1) {
      // We're at the right edge and holding the last day
      final lastStartDay = ((widget.totalDays - 1) ~/ widget.daysToShow) * widget.daysToShow + 1;
      if (_startDay < lastStartDay) {
        _goToNextWeek();
        setState(() {
          _holdingDayIndex = 0; // Move to first day of next week
          _hasMovedWhileHolding = true;
        });
      }
    } else if (position.dx <= 20 && _holdingDayIndex == 0) {
      // We're at the left edge and holding the first day
      if (_startDay > 1) {
        _goToPreviousWeek();
        setState(() {
          _holdingDayIndex = widget.daysToShow - 1; // Move to last day of previous week
          _hasMovedWhileHolding = true;
        });
      }
    }
  }

  bool _isDayUnlocked(int day) {
    if (day == 1) return true; // Day 1 is always unlocked
    
    final progress = widget.userProgress;
    if (progress == null) return false;
    
    // Check if previous day is completed
    final previousDayCompleted = widget.userFlow?.hasFlowForDay(day - 1) ?? false;
    if (!previousDayCompleted) return false;
    
    // Check if this day is already completed
    final isCompleted = widget.userFlow?.hasFlowForDay(day) ?? false;
    if (isCompleted) return true;
    
    // Check if 24 hours have passed since previous day completion
    final lastCompletedAt = progress.lastCompletedAt?.toDate();
    if (lastCompletedAt == null) return false;
    
    final now = DateTime.now();
    final unlockTime = lastCompletedAt.add(const Duration(hours: 24));
    
    // Always return false if we're within the 24 hour period
    if (now.isBefore(unlockTime)) return false;
    
    return true;
  }

  String _getDayStatus(int day, bool isCompleted, bool isCurrentDay) {
    if (isCurrentDay) return 'Today';
    if (isCompleted) return 'Done';
    
    // For Day 2 and onwards, always check the timer first
    if (day > 1) {
      final remainingTime = _getRemainingTime(day);
      if (remainingTime != null) {
        final hours = remainingTime.inHours;
        final minutes = remainingTime.inMinutes % 60;
        return '${hours}h ${minutes}m';
      }
    }
    
    // Only show "Ready" if the day is actually unlocked
    return _isDayUnlocked(day) ? 'Ready' : '';
  }

  Duration? _getRemainingTime(int day) {
    if (day == 1) return null; // Day 1 has no timer
    
    final progress = widget.userProgress;
    if (progress == null) return null;
    
    final previousDayCompleted = widget.userFlow?.hasFlowForDay(day - 1) ?? false;
    if (!previousDayCompleted) return null;
    
    final lastCompletedAt = progress.lastCompletedAt?.toDate();
    if (lastCompletedAt == null) return null;
    
    final unlockTime = lastCompletedAt.add(const Duration(hours: 24));
    final now = DateTime.now();
    
    // Always return remaining time if we're within the 24 hour period
    if (now.isBefore(unlockTime)) {
      return unlockTime.difference(now);
    }
    
    return null;
  }

  Widget _buildDayItem(int day, {required bool enabled}) {
    if (day > widget.totalDays) {
      return const SizedBox.shrink();
    }
    
    // Determine completion status
    final previousDayCompleted = widget.userFlow?.hasFlowForDay(day - 1) ?? false;
    final currentDay = widget.userProgress?.currentDay ?? 1;
    
    final isAccessible = day <= currentDay;
    final isCompleted = widget.userFlow?.hasFlowForDay(day) ?? false;
    
    // Days of the week abbreviations
    final List<String> daysOfWeek = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final dayOfWeekIndex = (day - 1) % 7;
    
    return GestureDetector(
      onTap: () {
        if (enabled) {
          widget.onDayTap?.call(MeditationContent.withDay(day: day));
        }
      },
      child: Column(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: isCompleted 
                ? Colors.amber
                : (widget.isDarkMode ? Colors.grey[800] : Colors.grey[300]),
              shape: BoxShape.circle,
              border: day == currentDay
                ? Border.all(color: Colors.white, width: 2)
                : null,
            ),
            child: Center(
              child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    daysOfWeek[dayOfWeekIndex],
                    style: TextStyle(
                      color: enabled
                        ? (widget.isDarkMode ? Colors.white : Colors.black87)
                        : (widget.isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                      fontWeight: day == currentDay ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Day $day',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCircle(int day, {bool isActive = false, bool isCompleted = false}) {
    // Use the existing method implementation
    final isCompleted = widget.userFlow?.hasFlowForDay(day) ?? false;
    
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: isCompleted 
          ? Colors.amber
          : (widget.isDarkMode ? Colors.grey[800] : Colors.grey[300]),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : Text(
              day.toString(),
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  // Add method to build day circles
  Widget _buildDayCircles(int startDay) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.daysToShow,
        (index) {
          final day = startDay + index;
          if (day > widget.totalDays) {
            return const SizedBox.shrink();
          }
          
          final currentDay = widget.userProgress?.currentDay ?? 1;
          final isCompleted = widget.userFlow?.hasFlowForDay(day) ?? false;
          final isActive = day <= currentDay;
          
          return GestureDetector(
            onTap: () {
              if (isActive || isCompleted) {
                widget.onDayTap?.call(MeditationContent.withDay(day: day));
              }
            },
            onLongPress: (isActive || isCompleted) ? () => _startHolding(index) : null,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final scale = index == _holdingDayIndex 
                  ? _scaleAnimation.value 
                  : (_holdingDayIndex != null ? 0.8 : 1.0);
                  
                return Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: isCompleted 
                            ? Colors.amber
                            : (widget.isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                          shape: BoxShape.circle,
                          border: day == currentDay
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        ),
                        child: Center(
                          child: isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : Text(
                                day.toString(),
                                style: TextStyle(
                                  color: (isActive || isCompleted)
                                    ? (widget.isDarkMode ? Colors.white : Colors.black87)
                                    : (widget.isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                                  fontWeight: day == currentDay ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Day $day',
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = widget.userProgress?.currentDay ?? 1;
    final isShowingCurrentDay = currentDay >= _startDay && 
                               currentDay < _startDay + widget.daysToShow;
    
    final endDay = _startDay + widget.daysToShow - 1 > widget.totalDays ? 
                   widget.totalDays : 
                   _startDay + widget.daysToShow - 1;
    
    final previousEndDay = _previousStartDay + widget.daysToShow - 1 > widget.totalDays ?
                           widget.totalDays :
                           _previousStartDay + widget.daysToShow - 1;

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
                  onPressed: (_startDay > 1 && !_isAnimatingWeek) ? _goToPreviousWeek : null,
                ),
                // Animated title with transition
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isAnimatingWeek 
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          // Previous week title
                          Opacity(
                            opacity: 1.0 - _weekTransitionProgress,
                            child: Transform.translate(
                              offset: Offset(
                                _previousStartDay < _startDay 
                                  ? -100 * _weekTransitionProgress 
                                  : 100 * _weekTransitionProgress,
                                0
                              ),
                              child: Text(
                                'Days ${_previousStartDay} - $previousEndDay',
                                key: ValueKey('prev-${_previousStartDay}'),
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white70 : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          // Current week title
                          Opacity(
                            opacity: _weekTransitionProgress,
                            child: Transform.translate(
                              offset: Offset(
                                _previousStartDay < _startDay 
                                  ? 100 * (1.0 - _weekTransitionProgress) 
                                  : -100 * (1.0 - _weekTransitionProgress),
                                0
                              ),
                              child: Text(
                                'Days ${_startDay} - $endDay',
                                key: ValueKey('curr-${_startDay}'),
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white70 : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Days ${_startDay} - $endDay',
                        key: ValueKey(_startDay),
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white70 : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: endDay < widget.totalDays 
                      ? (widget.isDarkMode ? Colors.white70 : Colors.grey[700])
                      : (widget.isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: (endDay < widget.totalDays && !_isAnimatingWeek) ? _goToNextWeek : null,
                ),
              ],
            ),
          ),
          
          // Day circles with connecting lines
          SizedBox(
            height: 100,
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                _dragStartX = event.position.dx;
              },
              onPointerMove: (PointerMoveEvent event) {
                if (_isAnimatingWeek) return; // Don't allow gestures during animation
                
                if (_isHolding && _holdingDayIndex != null) {
                  // When holding a day and dragging, navigate between individual days
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(event.position);
                  
                  // Check if we need to navigate to next/previous week
                  _handleDragAtEdge(localPosition, box.size);
                  
                  // Get the index of the day at this position
                  final hoveredIndex = _getDayIndexAtPosition(localPosition, box.size);
                  
                  // Calculate distance moved from starting position
                  final distance = event.position.dx - _dragStartX;
                  
                  // Only process if we've moved a bit (to avoid accidental moves)
                  if (distance.abs() > 10) {
                    _swipeToDay(hoveredIndex);
                  }
                } else if (!_isHolding) {
                  // For regular swipe to change week
                  final distance = event.position.dx - _dragStartX;
                  if (distance.abs() > 50) {
                    if (distance < 0 && _startDay + widget.daysToShow <= widget.totalDays) {
                      _goToNextWeek();
                      _dragStartX = event.position.dx; // Reset to avoid multiple triggers
                    } else if (distance > 0 && _startDay > 1) {
                      _goToPreviousWeek();
                      _dragStartX = event.position.dx; // Reset to avoid multiple triggers
                    }
                  }
                }
              },
              onPointerUp: (PointerUpEvent event) {
                if (_isHolding && !_hasMovedWhileHolding) {
                  // If we were holding but didn't move, this is a tap after a long press
                  final day = _startDay + (_holdingDayIndex ?? 0);
                  final isCompleted = widget.userFlow?.hasFlowForDay(day) ?? false;
                  final isUnlocked = _isDayUnlocked(day);
                  
                  if (isUnlocked || isCompleted) {
                    print("Releasing held day $day - calling onDayTap");
                    widget.onDayTap?.call(MeditationContent.withDay(day: day));
                  }
                }
                _stopHolding();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _isAnimatingWeek
                  ? Stack(
                      children: [
                        // Transitioning out week
                        Positioned.fill(
                          child: Opacity(
                            opacity: 1.0 - _weekTransitionProgress,
                            child: Transform.translate(
                              offset: Offset(
                                (_previousStartDay < _startDay) 
                                  ? -150 * _weekTransitionProgress 
                                  : 150 * _weekTransitionProgress,
                                0
                              ),
                              child: Transform.scale(
                                scale: 1.0 - (0.2 * _weekTransitionProgress),
                                child: Stack(
                                  children: [
                                    // Connecting lines
                                    Positioned.fill(
                                      top: 20,
                                      child: CustomPaint(
                                        painter: PathPainter(
                                          isDarkMode: widget.isDarkMode,
                                          userFlow: widget.userFlow,
                                          currentLineDay: _previousStartDay,
                                          nextLineDay: _previousStartDay + 1,
                                        ),
                                      ),
                                    ),
                                    // Day circles
                                    _buildDayCircles(_previousStartDay),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Transitioning in week
                        Positioned.fill(
                          child: Opacity(
                            opacity: _weekTransitionProgress,
                            child: Transform.translate(
                              offset: Offset(
                                (_previousStartDay < _startDay) 
                                  ? 150 * (1.0 - _weekTransitionProgress) 
                                  : -150 * (1.0 - _weekTransitionProgress),
                                0
                              ),
                              child: Transform.scale(
                                scale: 0.8 + (0.2 * _weekTransitionProgress),
                                child: Stack(
                                  children: [
                                    // Connecting lines
                                    Positioned.fill(
                                      top: 20,
                                      child: CustomPaint(
                                        painter: PathPainter(
                                          isDarkMode: widget.isDarkMode,
                                          userFlow: widget.userFlow,
                                          currentLineDay: _startDay,
                                          nextLineDay: _startDay + 1,
                                        ),
                                      ),
                                    ),
                                    // Day circles
                                    _buildDayCircles(_startDay),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        // Connecting lines
                        Positioned.fill(
                          top: 20,
                          child: CustomPaint(
                            painter: PathPainter(
                              isDarkMode: widget.isDarkMode,
                              userFlow: widget.userFlow,
                              currentLineDay: _startDay,
                              nextLineDay: _startDay + 1,
                            ),
                          ),
                        ),
                        // Day circles
                        _buildDayCircles(_startDay),
                      ],
                    ),
              ),
            ),
          ),
          
          // Today button if not showing current day
          if (!isShowingCurrentDay)
            TextButton.icon(
              onPressed: !_isAnimatingWeek ? _goToCurrentDay : null,
              icon: const Icon(Icons.today, size: 16),
              label: const Text('Go to Today'),
              style: TextButton.styleFrom(
                foregroundColor: widget.isDarkMode ? Colors.deepPurple[200] : Colors.blue[700],
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final bool isDarkMode;
  final UserFlow? userFlow;
  final int currentLineDay;
  final int nextLineDay;
  
  PathPainter({
    required this.isDarkMode,
    required this.userFlow,
    required this.currentLineDay,
    required this.nextLineDay,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final centerY = size.height / 2;
    final strokeWidth = 3.0;
    
    // Create paints for different states
    final completedPaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
      
    final uncompletedPaint = Paint()
      ..color = isDarkMode ? Colors.grey[700]! : Colors.grey[400]!
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    // Determine if the current day segment should be highlighted
    final isStartCompleted = userFlow?.hasFlowForDay(currentLineDay) ?? false;
    final isEndCompleted = userFlow?.hasFlowForDay(nextLineDay) ?? false;
    
    // Draw the line
    final paint = (isStartCompleted && isEndCompleted) ? completedPaint : uncompletedPaint;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(width, centerY),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PathPainter) {
      return oldDelegate.isDarkMode != isDarkMode ||
             oldDelegate.userFlow != userFlow ||
             oldDelegate.currentLineDay != currentLineDay ||
             oldDelegate.nextLineDay != nextLineDay;
    }
    return true;
  }
} 