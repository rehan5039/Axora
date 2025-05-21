import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:axora/models/challenge.dart';
import 'package:axora/services/challenge_service.dart';
import 'package:axora/utils/constants.dart';

class AdminChallengeStatsScreen extends StatefulWidget {
  const AdminChallengeStatsScreen({super.key});

  @override
  State<AdminChallengeStatsScreen> createState() => _AdminChallengeStatsScreenState();
}

class _AdminChallengeStatsScreenState extends State<AdminChallengeStatsScreen> {
  final _database = FirebaseDatabase.instance;
  final _challengeService = ChallengeService();
  bool _isLoading = true;
  List<Challenge> _challenges = [];
  Map<String, Map<String, dynamic>> _userChallengeData = {};
  Map<String, String> _userEmails = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all challenges
      _challenges = await _challengeService.getActiveChallenges();

      // Load user challenge data
      final userChallengesSnapshot = await _database
          .ref()
          .child('userChallenges')
          .get();

      if (userChallengesSnapshot.exists) {
        final data = userChallengesSnapshot.value as Map<dynamic, dynamic>;
        data.forEach((userId, challengeData) {
          _userChallengeData[userId.toString()] = 
              Map<String, dynamic>.from(challengeData as Map);
        });
      }

      // Load user emails
      final usersSnapshot = await _database
          .ref()
          .child('users')
          .get();

      if (usersSnapshot.exists) {
        final data = usersSnapshot.value as Map<dynamic, dynamic>;
        data.forEach((userId, userData) {
          if (userData is Map && userData['email'] != null) {
            _userEmails[userId.toString()] = userData['email'].toString();
          }
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading challenge stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading challenge stats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildChallengeStats(Challenge challenge) {
    // Calculate completion statistics
    int totalUsers = _userEmails.length;
    int completedCount = 0;
    List<String> completedUsers = [];
    List<String> incompleteUsers = [];

    _userChallengeData.forEach((userId, challengeData) {
      if (challengeData[challenge.id] != null) {
        final userData = challengeData[challenge.id] as Map<dynamic, dynamic>;
        if (userData['completed'] == true) {
          completedCount++;
          completedUsers.add(_userEmails[userId] ?? userId);
        } else {
          incompleteUsers.add(_userEmails[userId] ?? userId);
        }
      } else {
        incompleteUsers.add(_userEmails[userId] ?? userId);
      }
    });

    final completionRate = totalUsers > 0 ? (completedCount / totalUsers * 100) : 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(challenge.title),
        subtitle: Text('${completionRate.toStringAsFixed(1)}% Completion Rate'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Challenge Statistics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Total Users: $totalUsers'),
                Text('Completed: $completedCount'),
                Text('Incomplete: ${totalUsers - completedCount}'),
                const SizedBox(height: 16),
                
                Text(
                  'Completed Users',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (completedUsers.isEmpty)
                  const Text('No users have completed this challenge yet')
                else
                  ...completedUsers.map((email) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(email)),
                      ],
                    ),
                  )),
                
                const SizedBox(height: 16),
                Text(
                  'Incomplete Users',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (incompleteUsers.isEmpty)
                  const Text('All users have completed this challenge!')
                else
                  ...incompleteUsers.map((email) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.pending, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(email)),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _challenges.isEmpty
              ? const Center(child: Text('No challenges found'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: _challenges
                        .map((challenge) => _buildChallengeStats(challenge))
                        .toList(),
                  ),
                ),
    );
  }
} 