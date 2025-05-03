import 'package:flutter/material.dart';

class ArticleViewer extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onComplete;
  
  const ArticleViewer({
    super.key,
    required this.title,
    required this.content,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16.0),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32.0),
          Center(
            child: ElevatedButton(
              onPressed: onComplete,
              child: const Text('Mark as Read'),
            ),
          ),
        ],
      ),
    );
  }
} 