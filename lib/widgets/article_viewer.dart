import 'package:flutter/material.dart';
import 'package:axora/services/text_to_speech_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ArticleViewer extends StatefulWidget {
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
  State<ArticleViewer> createState() => _ArticleViewerState();
}

class _ArticleViewerState extends State<ArticleViewer> {
  final TextToSpeechService _tts = TextToSpeechService();
  bool _isPlaying = false;
  
  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }
  
  void _toggleSpeech() {
    if (_isPlaying) {
      _tts.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      // Combine title and content for reading
      final textToRead = "${widget.title}. ${widget.content}";
      _tts.speak(textToRead);
      setState(() {
        _isPlaying = true;
      });
    }
  }

  // Check if the platform is Android
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Text-to-Speech Button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              // Only show the TTS button on Android platforms
              if (_isAndroid)
                IconButton(
                  onPressed: _toggleSpeech,
                  icon: Icon(
                    _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                    color: _isPlaying ? Theme.of(context).primaryColor : Colors.grey,
                    size: 28,
                  ),
                  tooltip: _isPlaying ? 'Stop Reading' : 'Read Article',
                ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            widget.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32.0),
          Center(
            child: ElevatedButton(
              onPressed: widget.onComplete,
              child: const Text('Mark as Read'),
            ),
          ),
        ],
      ),
    );
  }
} 