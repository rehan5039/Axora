import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<FAQCategory> _categories = [
    FAQCategory(
      title: 'Getting Started',
      questions: [
        FAQItem(
          question: 'How to start meditation?',
          answer: 'Start with just 5 minutes daily in a quiet space. Focus on your breath, and when your mind wanders, gently bring it back to your breathing. Gradually increase your time as you become more comfortable.'
        ),
        FAQItem(
          question: 'What time of day is best for meditation?',
          answer: 'Many people prefer meditating in the morning to start their day with clarity, but the best time is whenever you can consistently practice. Find a time when you won\'t be disturbed and can make it part of your daily routine.'
        ),
        FAQItem(
          question: 'How long should I meditate?',
          answer: 'For beginners, 5-10 minutes daily is an excellent start. As you build your practice, you can gradually extend to 15-20 minutes. Consistency matters more than duration - regular short sessions are better than occasional long ones.'
        ),
      ],
    ),
    FAQCategory(
      title: 'Meditation Techniques',
      questions: [
        FAQItem(
          question: 'What is mindfulness meditation?',
          answer: 'Mindfulness meditation involves focusing on the present moment, usually by paying attention to your breath, bodily sensations, or surroundings without judgment. When thoughts arise, you acknowledge them and gently return to your focus.'
        ),
        FAQItem(
          question: 'What is Third Eye meditation?',
          answer: 'Third Eye meditation focuses on the area between your eyebrows (the Ajna chakra). It involves directing your attention to this point to enhance intuition, clarity, and spiritual awareness. It\'s believed to help access deeper states of consciousness.'
        ),
        FAQItem(
          question: 'How does guided meditation work?',
          answer: 'Guided meditation uses verbal instructions to direct your attention and imagination. It\'s excellent for beginners as it provides structure and helps keep your mind from wandering. In Axora, you can choose from various guided meditations tailored to specific goals.'
        ),
      ],
    ),
    FAQCategory(
      title: 'Common Challenges',
      questions: [
        FAQItem(
          question: 'How do I deal with a wandering mind?',
          answer: 'A wandering mind is normal, not a failure. When you notice your thoughts drifting, acknowledge it without judgment and gently redirect your attention back to your breath or meditation focus. This gets easier with practice.'
        ),
        FAQItem(
          question: 'How to deal with physical discomfort while sitting?',
          answer: 'Start with shorter sessions and use proper support like cushions or chairs. Don\'t force uncomfortable positions; meditation doesn\'t require perfect lotus posture. You can even meditate lying down if needed, though this may lead to sleepiness.'
        ),
        FAQItem(
          question: 'What if I fall asleep during meditation?',
          answer: 'This is common, especially when tired. Try meditating when you\'re more alert, sit upright instead of lying down, open your eyes slightly, or practice in a cooler room. If you do fall asleep, don\'t worry - you likely needed the rest.'
        ),
      ],
    ),
    FAQCategory(
      title: 'Benefits & Progress',
      questions: [
        FAQItem(
          question: 'How long before I see benefits from meditation?',
          answer: 'Some benefits like reduced stress may be noticed after just a few sessions. More significant changes to focus, emotional regulation, and overall well-being typically develop over weeks or months of consistent practice. Everyone\'s experience differs.'
        ),
        FAQItem(
          question: 'Can meditation help with anxiety?',
          answer: 'Yes, research shows meditation can significantly reduce anxiety by calming the mind, regulating stress hormones, and teaching you to observe anxious thoughts without being consumed by them. Regular practice can build resilience against anxiety triggers.'
        ),
        FAQItem(
          question: 'How do I know if I\'m making progress?',
          answer: 'Progress in meditation isn\'t always obvious. Look for subtle changes like increased awareness of your thoughts, better emotional regulation, improved focus, or enhanced ability to return to the present moment. The Axora app helps track your consistency, which is key to progress.'
        ),
      ],
    ),
    FAQCategory(
      title: 'Using Axora App',
      questions: [
        FAQItem(
          question: 'How do I track my meditation streak?',
          answer: 'Your meditation streak is automatically tracked on your profile page. Complete daily meditations to build your streak and see your progress over time.'
        ),
        FAQItem(
          question: 'Can I customize meditation reminders?',
          answer: 'Yes, go to the Meditation Reminder screen from Settings to set up daily notifications that work with your schedule. You can customize time, days, and message.'
        ),
        FAQItem(
          question: 'What are meditation challenges?',
          answer: 'Challenges are structured meditation programs designed to help you develop specific skills or address particular needs. They typically last 7-30 days and include curated meditation sessions to help you maintain consistency and depth in your practice.'
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Log screen view to Firebase Analytics
    FirebaseAnalytics.instance.logScreenView(
      screenName: 'FAQ Screen',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation FAQ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ...List.generate(_categories.length, (categoryIndex) {
            final category = _categories[categoryIndex];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    category.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                ...List.generate(category.questions.length, (questionIndex) {
                  final faqItem = category.questions[questionIndex];
                  return FAQExpansionTile(
                    faqItem: faqItem,
                    isLast: questionIndex == category.questions.length - 1,
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class FAQExpansionTile extends StatelessWidget {
  final FAQItem faqItem;
  final bool isLast;

  const FAQExpansionTile({
    super.key,
    required this.faqItem,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        ExpansionTile(
          title: Text(
            faqItem.question,
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                faqItem.answer,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

class FAQCategory {
  final String title;
  final List<FAQItem> questions;

  FAQCategory({
    required this.title,
    required this.questions,
  });
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
} 