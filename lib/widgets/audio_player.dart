import 'package:flutter/material.dart';

class AudioPlayer extends StatelessWidget {
  final String audioUrl;
  final String title;
  final VoidCallback onComplete;

  const AudioPlayer({
    super.key,
    required this.audioUrl,
    required this.title,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24.0),
        Icon(
          Icons.headphones,
          size: 64.0,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 24.0),
        // Here we would typically have actual audio controls
        // This is a simplified placeholder
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              iconSize: 48.0,
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 24.0),
        ElevatedButton(
          onPressed: onComplete,
          child: const Text('Mark as Completed'),
        ),
      ],
    );
  }
} 