import 'package:flutter/material.dart';
import 'package:axora/services/firebase_service.dart';
import 'package:axora/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'package:axora/widgets/axora_logo.dart';
import 'package:axora/widgets/theme_toggle_button.dart';
import 'package:axora/widgets/theme_showcase.dart';
import 'package:axora/screens/meditation_journey_screen.dart';
import 'package:axora/services/meditation_service.dart';
import 'package:axora/models/user_progress.dart';
import 'package:axora/providers/notification_provider.dart';
import 'package:axora/services/stats_service.dart';
import 'package:axora/models/user_stats.dart';
import 'package:axora/screens/about_axora_screen.dart';
import 'package:axora/screens/help_support_screen.dart';
import 'package:axora/screens/meditation_reminder_screen.dart';
import 'package:axora/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firebaseService = FirebaseService();
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MeditationTab(),
    const StatisticsTab(),
    const ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const AxoraLogo(fontSize: 28),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: Icon(
              notificationProvider.notificationsEnabled 
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: isDarkMode ? AppColors.darkText : AppColors.lightText,
            ),
            onPressed: () {
              notificationProvider.toggleNotifications();
              
              // Show confirmation snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    notificationProvider.notificationsEnabled
                        ? 'Notifications enabled'
                        : 'Notifications disabled'
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: 'Meditate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class MeditationTab extends StatefulWidget {
  const MeditationTab({super.key});

  @override
  State<MeditationTab> createState() => _MeditationTabState();
}

class _MeditationTabState extends State<MeditationTab> {
  final _meditationService = MeditationService();
  UserProgress? _userProgress;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }
  
  Future<void> _loadUserProgress() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final progress = await _meditationService.getUserProgress();
      setState(() {
        _userProgress = progress;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user progress: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textStyle = isDarkMode ? AppStyles.bodyTextDark : AppStyles.bodyTextLight;
    final headingStyle = isDarkMode ? AppStyles.heading2Dark : AppStyles.heading2Light;
    final user = FirebaseService().currentUser;
    final userName = user?.displayName ?? 'Alex';
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning,',
              style: headingStyle,
            ),
            Text(
              userName,
              style: headingStyle,
            ),
            const SizedBox(height: 24),
            _QuickActionButton(
              label: 'Start a Quick Meditation',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MeditationJourneyScreen(),
                  ),
                ).then((_) => _loadUserProgress());
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Your Meditation Journey'),
            const SizedBox(height: 16),
            _JourneyCard(
              currentDay: _userProgress?.currentDay ?? 1,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MeditationJourneyScreen(),
                  ),
                ).then((_) => _loadUserProgress());
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Today\'s Challenge'),
            const SizedBox(height: 16),
            _ChallengeCard(
              title: 'Complete a 5-minute session',
              progress: 0.4,
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Categories'),
            const SizedBox(height: 16),
            const _CategoryGrid(),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Top Sounds'),
            const SizedBox(height: 16),
            const _SoundSelector(),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textStyle = isDarkMode ? AppStyles.bodyTextDark : AppStyles.bodyTextLight;
    
    return Text(
      title,
      style: textStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final String title;
  final double progress;

  const _ChallengeCard({
    required this.title,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    
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
          Text(
            title,
            style: TextStyle(
              color: isDarkMode ? AppColors.darkText : AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Focus', 'icon': Icons.center_focus_strong},
      {'name': 'Sleep', 'icon': Icons.nightlight_round},
      {'name': 'Productivity', 'icon': Icons.trending_up},
      {'name': 'Deep Relaxation', 'icon': Icons.spa},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _CategoryItem(
          name: categories[index]['name'] as String,
          icon: categories[index]['icon'] as IconData,
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String name;
  final IconData icon;

  const _CategoryItem({
    required this.name,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundSelector extends StatelessWidget {
  const _SoundSelector();

  @override
  Widget build(BuildContext context) {
    final sounds = [
      {'name': 'Nature', 'icon': Icons.eco},
      {'name': 'Rain', 'icon': Icons.water_drop},
      {'name': 'Waves', 'icon': Icons.waves},
    ];
    
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sounds.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _SoundItem(
              name: sounds[index]['name'] as String,
              icon: sounds[index]['icon'] as IconData,
            ),
          );
        },
      ),
    );
  }
}

class _SoundItem extends StatelessWidget {
  final String name;
  final IconData icon;

  const _SoundItem({
    required this.name,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(12),
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final int currentDay;
  final VoidCallback onPressed;

  const _JourneyCard({
    required this.currentDay,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    
    return InkWell(
      onTap: onPressed,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.primaryGold.withOpacity(0.2) : AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meditation Journey',
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current day: $currentDay',
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: currentDay / 30,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              'Continue your journey',
              style: TextStyle(
                color: isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  final _statsService = StatsService();
  UserStats? _userStats;
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });
    
    try {
      // Delay slightly to allow Firebase operations to complete
      await Future.delayed(const Duration(milliseconds: 300));
      
      final stats = await _statsService.getUserStats();
      
      // Also get the current flow to ensure stats are in sync
      final meditationService = MeditationService();
      final userFlow = await meditationService.getUserFlow();
      
      // If both were loaded successfully, verify they're in sync
      if (stats != null && userFlow != null) {
        // If current streak doesn't match flow, sync them
        if (stats.currentStreak != userFlow.flow) {
          print('Current streak (${stats.currentStreak}) does not match flow (${userFlow.flow}). Syncing...');
          await _statsService.syncCurrentStreakWithFlow(userFlow.flow);
          
          // Reload stats after syncing
          final updatedStats = await _statsService.getUserStats();
          if (mounted) {
            setState(() {
              _userStats = updatedStats;
              _isLoading = false;
              _isRefreshing = false;
            });
          }
          return;
        }
      }
      
      if (mounted) {
        setState(() {
          _userStats = stats;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('Error loading user statistics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textStyle = isDarkMode ? AppStyles.bodyTextDark : AppStyles.bodyTextLight;
    final headingStyle = isDarkMode ? AppStyles.heading2Dark : AppStyles.heading2Light;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress', style: headingStyle),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: _isRefreshing ? null : _loadStats,
                    tooltip: 'Refresh stats',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _StatItem(
                label: 'Current Flow', 
                value: '${_userStats?.currentStreak ?? 0}',
              ),
              const SizedBox(height: 16),
              _StatItem(
                label: 'Total Minutes', 
                value: '${_userStats?.totalMinutes ?? 0}',
              ),
              const SizedBox(height: 16),
              _StatItem(
                label: 'Sessions Completed', 
                value: '${_userStats?.sessionsCompleted ?? 0}',
              ),
              const SizedBox(height: 16),
              _StatItem(
                label: 'Total Flow Lost', 
                value: '${_userStats?.totalFlowLost ?? 0}',
              ),
              const SizedBox(height: 24),
              Text('Badges', style: headingStyle),
              const SizedBox(height: 16),
              const _BadgeItem(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primaryGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Novice Meditator',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                  4,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: index < 1 ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _meditationService = MeditationService();
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _meditationService.isAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textStyle = isDarkMode ? AppStyles.bodyTextDark : AppStyles.bodyTextLight;
    final headingStyle = isDarkMode ? AppStyles.heading2Dark : AppStyles.heading2Light;
    
    final firebaseService = FirebaseService();
    final user = firebaseService.currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: isDarkMode ? AppColors.primaryGold : AppColors.primaryGreen,
              child: const Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Guest User',
              style: headingStyle,
            ),
            Text(
              user?.isAnonymous == true ? '' : (user?.email ?? ''),
              style: textStyle.copyWith(
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 32),
            _ProfileMenuItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            _ProfileMenuItem(
              icon: Icons.color_lens,
              title: 'Theme Settings',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ThemeShowcase(),
                  ),
                );
              },
            ),
            if (_isAdmin) // Only show admin options to admins
              _ProfileMenuItem(
                icon: Icons.admin_panel_settings,
                title: 'Admin Dashboard',
                onTap: () {
                  Navigator.of(context).pushNamed('/admin-dashboard');
                },
              ),
            _ProfileMenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen(),
                  ),
                );
              },
            ),
            _ProfileMenuItem(
              icon: Icons.info_outline,
              title: 'About Axora',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutAxoraScreen(),
                  ),
                );
              },
            ),
            if (user != null)
              _ProfileMenuItem(
                icon: Icons.logout,
                title: 'Logout',
                onTap: () async {
                  await firebaseService.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
} 