import 'package:flutter/material.dart';
import 'package:axora/models/challenge.dart';
import 'package:axora/services/challenge_service.dart';
import 'package:axora/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/screens/challenge_detail_screen.dart';

class ChallengeListScreen extends StatefulWidget {
  const ChallengeListScreen({Key? key}) : super(key: key);

  @override
  State<ChallengeListScreen> createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends State<ChallengeListScreen> {
  final _challengeService = ChallengeService();
  List<Challenge> _challenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final challenges = await _challengeService.getActiveChallenges();
      setState(() {
        _challenges = challenges;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading challenges: $e');
      setState(() {
        _challenges = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Challenges'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadChallenges,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _challenges.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 64,
                          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active challenges',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new challenges',
                          style: TextStyle(
                            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _challenges.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final challenge = _challenges[index];
                      return _ChallengeCard(
                        challenge: challenge,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChallengeDetailScreen(
                                challenge: challenge,
                              ),
                            ),
                          ).then((_) => _loadChallenges());
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.challenge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    IconData getIconForType() {
      switch (challenge.type) {
        case ChallengeType.meditation:
          return Icons.self_improvement;
        case ChallengeType.poll:
          return Icons.poll;
        case ChallengeType.task:
          return Icons.task_alt;
        case ChallengeType.quiz:
          return Icons.quiz;
        default:
          return Icons.star;
      }
    }

    Color getColorForType() {
      switch (challenge.type) {
        case ChallengeType.meditation:
          return Colors.purple;
        case ChallengeType.poll:
          return Colors.blue;
        case ChallengeType.task:
          return Colors.orange;
        case ChallengeType.quiz:
          return Colors.green;
        default:
          return Colors.teal;
      }
    }

    String getTypeText() {
      switch (challenge.type) {
        case ChallengeType.meditation:
          return 'Meditation';
        case ChallengeType.poll:
          return 'Poll';
        case ChallengeType.task:
          return 'Task';
        case ChallengeType.quiz:
          return 'Quiz';
        default:
          return 'Challenge';
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: getColorForType().withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getIconForType(),
                    color: getColorForType(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getTypeText(),
                        style: TextStyle(
                          color: getColorForType(),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (challenge.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              challenge.description,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (challenge.type != ChallengeType.poll) ...[
              LinearProgressIndicator(
                value: challenge.userProgress ?? 0.0,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(getColorForType()),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                '${((challenge.userProgress ?? 0.0) * 100).toInt()}% Complete',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ] else if (challenge.pollOptions != null) ...[
              Wrap(
                spacing: 8,
                children: challenge.pollOptions!.keys.map((option) {
                  return Chip(
                    label: Text(
                      option,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: isDarkMode 
                        ? Colors.grey.shade800 
                        : Colors.grey.shade200,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 