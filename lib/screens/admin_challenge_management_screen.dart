import 'package:flutter/material.dart';
import 'package:axora/models/challenge.dart';
import 'package:axora/services/challenge_service.dart';
import 'package:axora/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:axora/screens/add_edit_challenge_screen.dart';

class AdminChallengeManagementScreen extends StatefulWidget {
  const AdminChallengeManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminChallengeManagementScreen> createState() => _AdminChallengeManagementScreenState();
}

class _AdminChallengeManagementScreenState extends State<AdminChallengeManagementScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Management'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadChallenges,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _challenges.length + 1, // +1 for the "Add New Challenge" button
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _AddChallengeButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddEditChallengeScreen(),
                          ),
                        ).then((_) => _loadChallenges());
                      },
                    );
                  }

                  final challenge = _challenges[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _ChallengeAdminCard(
                      challenge: challenge,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditChallengeScreen(
                              challenge: challenge,
                            ),
                          ),
                        ).then((_) => _loadChallenges());
                      },
                      onDelete: () => _showDeleteConfirmation(challenge),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _showDeleteConfirmation(Challenge challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Challenge'),
        content: Text('Are you sure you want to delete "${challenge.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _challengeService.deleteChallenge(challenge.id);
        _loadChallenges();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge deleted successfully'),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete challenge: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _AddChallengeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddChallengeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle,
              color: AppColors.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Create New Challenge',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeAdminCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChallengeAdminCard({
    required this.challenge,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final secondaryColor = isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;

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

    final dateFormat = DateFormat('MMM d, yyyy');
    final startDate = dateFormat.format(challenge.startDate);
    final endDate = dateFormat.format(challenge.endDate);

    return Container(
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
                        color: AppColors.primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: secondaryColor),
                onPressed: onEdit,
                tooltip: 'Edit Challenge',
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red.shade300),
                onPressed: onDelete,
                tooltip: 'Delete Challenge',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            challenge.description,
            style: TextStyle(
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            'Active period: $startDate to $endDate',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 