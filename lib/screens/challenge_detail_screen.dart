import 'package:flutter/material.dart';
import 'package:axora/models/challenge.dart';
import 'package:axora/services/challenge_service.dart';
import 'package:axora/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:intl/intl.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({
    Key? key,
    required this.challenge,
  }) : super(key: key);

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final _challengeService = ChallengeService();
  bool _isLoading = false;
  double _progress = 0.0;
  String? _selectedPollOption;
  List<String> _selectedPollOptions = [];
  List<int> _selectedQuizAnswers = [];
  int _currentQuizQuestion = 0;
  bool _quizSubmitted = false;
  int _quizCorrectAnswers = 0;

  @override
  void initState() {
    super.initState();
    _progress = widget.challenge.userProgress ?? 0.0;
    _quizSubmitted = widget.challenge.isCompleted;
    
    if (widget.challenge.type == ChallengeType.quiz && 
        widget.challenge.quizQuestions != null) {
      _selectedQuizAnswers = List.filled(widget.challenge.quizQuestions!.length, -1);
    }
  }

  Future<void> _updateProgress(double value) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _challengeService.updateChallengeProgress(
        widget.challenge.id,
        value,
      );

      setState(() {
        _progress = value;
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update progress: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _submitPollVote(String option) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _selectedPollOption = option;
    });

    try {
      await _challengeService.submitPollVote(
        widget.challenge.id,
        option,
      );

      setState(() {
        _progress = 1.0;
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote submitted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _selectedPollOption = null;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit vote: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _submitMultiplePollVotes(List<String> options) async {
    if (_isLoading) return;
    if (options.isEmpty) {
      // Show error message if no options selected
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one option'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedPollOptions = options;
    });

    try {
      await _challengeService.submitMultiplePollVotes(
        widget.challenge.id,
        options,
      );

      setState(() {
        _progress = 1.0;
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votes submitted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _selectedPollOptions = [];
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit votes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _submitQuizAnswers() async {
    if (_isLoading) return;

    // Validate that all questions are answered
    if (_selectedQuizAnswers.contains(-1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before submitting'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate correct answers
      int correctAnswers = 0;
      List<Map<String, dynamic>> userAnswers = [];
      
      for (int i = 0; i < widget.challenge.quizQuestions!.length; i++) {
        final question = widget.challenge.quizQuestions![i];
        final userAnswer = _selectedQuizAnswers[i];
        final correctAnswer = question['correctAnswer'] as int;
        
        if (userAnswer == correctAnswer) {
          correctAnswers++;
        }
        
        userAnswers.add({
          'questionIndex': i,
          'userAnswer': userAnswer,
          'isCorrect': userAnswer == correctAnswer,
        });
      }
      
      _quizCorrectAnswers = correctAnswers;
      
      await _challengeService.submitQuizAnswers(
        widget.challenge.id,
        userAnswers,
        correctAnswers,
      );

      setState(() {
        _progress = correctAnswers / widget.challenge.quizQuestions!.length;
        _quizSubmitted = true;
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quiz submitted successfully! Score: $correctAnswers/${widget.challenge.quizQuestions!.length}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit quiz: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Details'),
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Challenge header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ChallengeTypeIcon(type: widget.challenge.type),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.challenge.title,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatDate(widget.challenge.startDate)} - ${_formatDate(widget.challenge.endDate)}',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.challenge.description,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (widget.challenge.type != ChallengeType.poll) ...[
                          Text(
                            'Your Progress',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                            minHeight: 10,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_progress * 100).toInt()}% Complete',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Challenge interaction
                  if (widget.challenge.type == ChallengeType.meditation) ...[
                    _MeditationChallengeWidget(
                      challenge: widget.challenge,
                      progress: _progress,
                      onUpdateProgress: _updateProgress,
                    ),
                  ] else if (widget.challenge.type == ChallengeType.poll && widget.challenge.pollOptions != null) ...[
                    widget.challenge.isMultiSelect
                        ? _MultiSelectPollChallengeWidget(
                            challenge: widget.challenge,
                            selectedOptions: _selectedPollOptions,
                            isCompleted: widget.challenge.isCompleted,
                            onVote: _submitMultiplePollVotes,
                          )
                        : _PollChallengeWidget(
                            challenge: widget.challenge,
                            selectedOption: _selectedPollOption,
                            isCompleted: widget.challenge.isCompleted,
                            onVote: _submitPollVote,
                          ),
                  ] else if (widget.challenge.type == ChallengeType.quiz && widget.challenge.quizQuestions != null) ...[
                    _QuizChallengeWidget(
                      challenge: widget.challenge,
                      selectedAnswers: _selectedQuizAnswers,
                      currentQuestion: _currentQuizQuestion,
                      isSubmitted: _quizSubmitted,
                      correctAnswers: _quizCorrectAnswers,
                      onAnswerSelected: (questionIndex, answerIndex) {
                        setState(() {
                          _selectedQuizAnswers[questionIndex] = answerIndex;
                        });
                      },
                      onQuestionChange: (questionIndex) {
                        setState(() {
                          _currentQuizQuestion = questionIndex;
                        });
                      },
                      onSubmit: _submitQuizAnswers,
                    ),
                  ] else if (widget.challenge.type == ChallengeType.task) ...[
                    _TaskChallengeWidget(
                      challenge: widget.challenge,
                      progress: _progress,
                      onUpdateProgress: _updateProgress,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ChallengeTypeIcon extends StatelessWidget {
  final ChallengeType type;

  const _ChallengeTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case ChallengeType.meditation:
        backgroundColor = Colors.purple.withOpacity(0.2);
        iconColor = Colors.purple;
        icon = Icons.self_improvement;
        break;
      case ChallengeType.poll:
        backgroundColor = Colors.blue.withOpacity(0.2);
        iconColor = Colors.blue;
        icon = Icons.poll;
        break;
      case ChallengeType.task:
        backgroundColor = Colors.orange.withOpacity(0.2);
        iconColor = Colors.orange;
        icon = Icons.task_alt;
        break;
      case ChallengeType.quiz:
        backgroundColor = Colors.green.withOpacity(0.2);
        iconColor = Colors.green;
        icon = Icons.quiz;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 24,
      ),
    );
  }
}

class _MeditationChallengeWidget extends StatelessWidget {
  final Challenge challenge;
  final double progress;
  final Function(double) onUpdateProgress;

  const _MeditationChallengeWidget({
    required this.challenge,
    required this.progress,
    required this.onUpdateProgress,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meditation Challenge',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Complete a ${challenge.durationMinutes}-minute meditation session',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          if (progress < 1.0) ...[
            ElevatedButton(
              onPressed: () {
                onUpdateProgress(1.0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                challenge.buttonText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Challenge Completed!',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PollChallengeWidget extends StatelessWidget {
  final Challenge challenge;
  final String? selectedOption;
  final bool isCompleted;
  final Function(String) onVote;

  const _PollChallengeWidget({
    required this.challenge,
    required this.selectedOption,
    required this.isCompleted,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;

    // Calculate total votes
    final pollOptions = challenge.pollOptions ?? {};
    final totalVotes = pollOptions.values.fold(0, (sum, votes) => sum + votes);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Poll Challenge',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cast your vote:',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ...pollOptions.entries.map((entry) {
            final option = entry.key;
            final votes = entry.value;
            final percentage = totalVotes > 0 ? (votes / totalVotes * 100).toInt() : 0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: isCompleted ? null : () => onVote(option),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selectedOption == option
                        ? AppColors.primaryBlue.withOpacity(0.15)
                        : isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: selectedOption == option
                        ? Border.all(color: AppColors.primaryBlue, width: 2)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: selectedOption == option
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isCompleted || selectedOption != null)
                            Text(
                              '$votes votes ($percentage%)',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          if (selectedOption == option)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.check_circle,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      if (isCompleted || selectedOption != null) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            selectedOption == option
                                ? AppColors.primaryBlue
                                : isDarkMode
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                          ),
                          minHeight: 8,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          
          if (selectedOption != null && !isCompleted) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onVote(selectedOption!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                challenge.buttonText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
          
          if (isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vote Submitted!',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskChallengeWidget extends StatelessWidget {
  final Challenge challenge;
  final double progress;
  final Function(double) onUpdateProgress;

  const _TaskChallengeWidget({
    required this.challenge,
    required this.progress,
    required this.onUpdateProgress,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Challenge',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Update your progress:',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: progress,
            onChanged: (value) {
              // Round to nearest 0.25
              final roundedValue = (value * 4).round() / 4;
              onUpdateProgress(roundedValue);
            },
            activeColor: AppColors.primaryBlue,
            inactiveColor: Colors.grey.withOpacity(0.2),
            divisions: 4,
            label: '${(progress * 100).toInt()}%',
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0%',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              Text(
                '25%',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              Text(
                '50%',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              Text(
                '75%',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              Text(
                '100%',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (progress < 1.0) ...[
            ElevatedButton(
              onPressed: () {
                onUpdateProgress(1.0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                challenge.buttonText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Challenge Completed!',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MultiSelectPollChallengeWidget extends StatefulWidget {
  final Challenge challenge;
  final List<String> selectedOptions;
  final bool isCompleted;
  final Function(List<String>) onVote;

  const _MultiSelectPollChallengeWidget({
    required this.challenge,
    required this.selectedOptions,
    required this.isCompleted,
    required this.onVote,
  });

  @override
  State<_MultiSelectPollChallengeWidget> createState() => _MultiSelectPollChallengeWidgetState();
}

class _MultiSelectPollChallengeWidgetState extends State<_MultiSelectPollChallengeWidget> {
  List<String> _tempSelectedOptions = [];

  @override
  void initState() {
    super.initState();
    _tempSelectedOptions = List.from(widget.selectedOptions);
  }

  void _toggleOption(String option) {
    if (widget.isCompleted) return;
    
    setState(() {
      if (_tempSelectedOptions.contains(option)) {
        _tempSelectedOptions.remove(option);
      } else {
        _tempSelectedOptions.add(option);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;

    // Calculate total votes
    final pollOptions = widget.challenge.pollOptions ?? {};
    final totalVotes = pollOptions.values.fold(0, (sum, votes) => sum + votes);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Multi-Select Poll',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select all options that apply:',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ...pollOptions.entries.map((entry) {
            final option = entry.key;
            final votes = entry.value;
            final percentage = totalVotes > 0 ? (votes / totalVotes * 100).toInt() : 0;
            final isSelected = _tempSelectedOptions.contains(option);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: widget.isCompleted ? null : () => _toggleOption(option),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue.withOpacity(0.15)
                        : isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppColors.primaryBlue, width: 2)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: widget.isCompleted ? null : (value) => _toggleOption(option),
                          ),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (widget.isCompleted || widget.selectedOptions.isNotEmpty)
                            Text(
                              '$votes votes ($percentage%)',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                      if (widget.isCompleted || widget.selectedOptions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isSelected
                                ? AppColors.primaryBlue
                                : isDarkMode
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                          ),
                          minHeight: 8,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          
          if (!widget.isCompleted) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                widget.onVote(_tempSelectedOptions);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.challenge.buttonText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Votes Submitted!',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizChallengeWidget extends StatefulWidget {
  final Challenge challenge;
  final List<int> selectedAnswers;
  final int currentQuestion;
  final bool isSubmitted;
  final int correctAnswers;
  final Function(int, int) onAnswerSelected;
  final Function(int) onQuestionChange;
  final VoidCallback onSubmit;

  const _QuizChallengeWidget({
    required this.challenge,
    required this.selectedAnswers,
    required this.currentQuestion,
    required this.isSubmitted,
    required this.correctAnswers,
    required this.onAnswerSelected,
    required this.onQuestionChange,
    required this.onSubmit,
  });

  @override
  State<_QuizChallengeWidget> createState() => _QuizChallengeWidgetState();
}

class _QuizChallengeWidgetState extends State<_QuizChallengeWidget> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentQuestion);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    
    final quizQuestions = widget.challenge.quizQuestions!;
    
    if (widget.isSubmitted) {
      // Show results if quiz is submitted
      return _buildQuizResults(context, cardColor, textColor);
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Challenge',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Question indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Question ${widget.currentQuestion + 1} of ${quizQuestions.length}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // Question navigation indicators
          SizedBox(
            height: 50,
            child: Center(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: quizQuestions.length,
                itemBuilder: (context, index) {
                  final isAnswered = widget.selectedAnswers[index] != -1;
                  final isCurrent = widget.currentQuestion == index;
                  
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      widget.onQuestionChange(index);
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primaryBlue
                            : isAnswered
                                ? AppColors.primaryBlue.withOpacity(0.3)
                                : isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(color: AppColors.primaryBlue, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrent || isAnswered
                                ? Colors.white
                                : textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Questions PageView
          SizedBox(
            height: 400,
            child: PageView.builder(
              controller: _pageController,
              itemCount: quizQuestions.length,
              onPageChanged: widget.onQuestionChange,
              itemBuilder: (context, questionIndex) {
                final question = quizQuestions[questionIndex];
                final questionText = question['question'] as String;
                final options = question['options'] as List;
                final selectedAnswer = widget.selectedAnswers[questionIndex];
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        questionText,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(options.length, (optionIndex) {
                      final option = options[optionIndex] as String;
                      final isSelected = selectedAnswer == optionIndex;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => widget.onAnswerSelected(questionIndex, optionIndex),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBlue.withOpacity(0.15)
                                  : isDarkMode
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: AppColors.primaryBlue, width: 2)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.primaryBlue
                                        : isDarkMode
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade300,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.currentQuestion > 0)
                ElevatedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    foregroundColor: textColor,
                  ),
                  child: const Text('Previous'),
                )
              else
                const SizedBox(width: 80),
                
              if (widget.currentQuestion < quizQuestions.length - 1)
                ElevatedButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: const Text('Next'),
                )
              else
                ElevatedButton(
                  onPressed: widget.onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: Text(widget.challenge.buttonText),
                ),
            ],
          ),
          
          // Progress indicator
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: widget.selectedAnswers.where((a) => a != -1).length / quizQuestions.length,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.selectedAnswers.where((a) => a != -1).length}/${quizQuestions.length} questions answered',
            style: TextStyle(
              color: isDarkMode
                  ? Colors.grey.shade400
                  : Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizResults(BuildContext context, Color cardColor, Color textColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final quizQuestions = widget.challenge.quizQuestions!;
    final score = widget.correctAnswers;
    final totalQuestions = quizQuestions.length;
    final percentage = (score / totalQuestions * 100).toInt();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Results',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Score display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryBlue,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Your Score',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$score / $totalQuestions',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Pass/Fail indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: percentage >= 70 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    percentage >= 70 ? 'PASSED' : 'FAILED',
                    style: TextStyle(
                      color: percentage >= 70 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Questions review
          Text(
            'Review Questions',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // List of questions with correct/incorrect indicators
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quizQuestions.length,
            itemBuilder: (context, questionIndex) {
              final question = quizQuestions[questionIndex];
              final questionText = question['question'] as String;
              final options = question['options'] as List;
              final correctAnswer = question['correctAnswer'] as int;
              final userAnswer = widget.selectedAnswers[questionIndex];
              final isCorrect = userAnswer == correctAnswer;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            questionText,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your answer: ${options[userAnswer]}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isCorrect) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Correct answer: ${options[correctAnswer]}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 