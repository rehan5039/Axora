import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:axora/providers/theme_provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class FlowIntroScreen extends StatefulWidget {
  const FlowIntroScreen({super.key});

  @override
  State<FlowIntroScreen> createState() => _FlowIntroScreenState();
}

class _FlowIntroScreenState extends State<FlowIntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildFlowStep(BuildContext context, {
    required String day,
    required String meditationText,
    String? status,
    String? flow,
    bool isMissed = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Meditation icon
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F0FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.self_improvement,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Meditation text and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditationText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    if (status != null)
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 14,
                          color: isMissed ? Colors.red : const Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
              if (flow != null) ...[
                const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  flow,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlowVisualizationSection() {
    return Column(
      children: [
        // Flow visualization title
        const Text(
          "HOW FLOW WORKS",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
          textAlign: TextAlign.center,
        ),
        
        const Text(
          "Miss a day? Just 1 step back.\nEvery session builds your rhythm.",
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 30),
        
        // Flow visualization
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildFlowStep(
                context,
                day: "Day 1",
                meditationText: "Meditation",
                status: "Done",
                flow: "Flow 1"
              ),
              _buildFlowStep(
                context,
                day: "Day 2",
                meditationText: "Meditation",
                status: "Done",
                flow: "Flow 2"
              ),
              _buildFlowStep(
                context,
                day: "Day 3",
                meditationText: "Meditation",
                status: "Done",
                flow: "Flow 3"
              ),
              _buildFlowStep(
                context,
                day: "Day 4",
                meditationText: "Meditation",
                status: "Missed",
                flow: "Flow drops\nto Flow 2",
                isMissed: true
              ),
              _buildFlowStep(
                context,
                day: "Day 2",
                meditationText: "Meditation",
                status: "Done",
                flow: "Flow 3"
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonSection() {
    return Column(
      children: [
        const Text(
          "Flow vs Streak – Kya farq hai?",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 30),
        
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F0FF),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.waves,
                        size: 30,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Flow",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE6E6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_fire_department,
                        size: 30,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Streak",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 30),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F0FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Flow:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Ek din miss kiya toh sirf ek Flow Level kam hota hai.\nAapka progress safe rehta hai. Wapas aana aasaan hota hai.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEFEF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Streak:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF991B1B),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Ek din miss kiya toh pura streak toot jaata hai.\nZero se shuru karna padta hai. Pressure aur guilt badhta hai.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF991B1B),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        
        const Text(
          '"Har din ek kadam, har Flow ek journey."',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Color(0xFF1E3A8A),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        const Text(
          "Aapka Flow aapke saath rehta hai — bina judge kiye, bina reset kiye.\nBas ek baar shuru karo, aur dekho kaise aap apne flow mein aa jaate ho.",
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildFirstPage() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
              children: [
          const SizedBox(height: 20),
                // Flow concept image
          Center(
            child: Image.asset(
                  'assets/images/flow_concept.png',
              width: MediaQuery.of(context).size.width * (kIsWeb ? 0.4 : 0.7),
                  fit: BoxFit.contain,
                ),
          ),
          const SizedBox(height: 20),
                
                // Title
                Text(
                  "Welcome to the Flow System",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                Text(
            "Aapki Journey Consistency aur Growth ki taraf",
                  style: TextStyle(
                    fontSize: 18,
              color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                
          const SizedBox(height: 20),
                
                // Flow description
                Text(
            "Har baar jab aap meditation karte ho, aapka Flow Level badhta hai.\nSochiye jaise aap apne aap ko har din thoda aur behtar bana rahe ho.\nAap shuru karte ho Flow 1 se – phir jaise-jaise aap regular rehte ho, aapka Flow Level bhi badhta jaata hai.",
                  style: TextStyle(
                    fontSize: 16,
              color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Benefits section
          Text(
            "Flow System ke Benefits",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : const Color(0xFFE6F0FF).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                BenefitItem(
                  text: "Consistency ko reward karta hai, perfection ko nahi.",
                  isDarkMode: isDarkMode,
                ),
                BenefitItem(
                  text: "Flexible hai – guilt-free growth ke liye.",
                  isDarkMode: isDarkMode,
                ),
                BenefitItem(
                  text: "Har session ek naya kadam hai behtar version ki taraf.",
                  isDarkMode: isDarkMode,
                ),
                BenefitItem(
                  text: "Break liya? Bas ek step peeche, lekin safar chalu rehta hai.",
                  isDarkMode: isDarkMode,
                ),
                BenefitItem(
                  text: "Comeback karna Easy aur Progress Meaningful!",
                  isDarkMode: isDarkMode,
                  showDivider: false,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Next button
          Center(
            child: ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.deepPurple : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Next",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildSecondPage() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 20),
          _buildFlowVisualizationSection(),
          
          const SizedBox(height: 40),
          
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
                  foregroundColor: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
                  minimumSize: const Size(120, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Back",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.deepPurple : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildThirdPage() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 20),
          _buildComparisonSection(),
          
          const SizedBox(height: 40),
          
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
                  foregroundColor: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
                  minimumSize: const Size(120, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Back",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.deepPurple : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  minimumSize: const Size(120, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                  "Samajh Gaya",
                    style: TextStyle(
                    fontSize: 16,
                      fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page indicators
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 3; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentPage
                            ? (isDarkMode ? Colors.white : const Color(0xFF2563EB))
                            : (isDarkMode ? Colors.white.withOpacity(0.3) : Colors.grey.shade300),
                      ),
                    ),
              ],
            ),
          ),
            
            // PageView
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildFirstPage(),
                  _buildSecondPage(),
                  _buildThirdPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BenefitItem extends StatelessWidget {
  final String text;
  final bool isDarkMode;
  final bool showDivider;

  const BenefitItem({
    super.key,
    required this.text,
    required this.isDarkMode,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withOpacity(0.2) : const Color(0xFF2563EB).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: isDarkMode ? Colors.white : const Color(0xFF2563EB),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
            height: 1,
          ),
      ],
    );
  }
} 