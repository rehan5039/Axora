import 'package:flutter/material.dart';

class AudioPlayer extends StatefulWidget {
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
  State<AudioPlayer> createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<AudioPlayer> {
  bool _isPlaying = false;
  double _currentPosition = 0.0;
  final double _totalDuration = 100.0; // Simulated duration
  double _volume = 0.7;

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    // In a real implementation, this would control actual audio playback
  }

  void _seek(double value) {
    setState(() {
      _currentPosition = value;
    });
    // In a real implementation, this would seek to the specified position
  }

  void _changeVolume(double value) {
    setState(() {
      _volume = value;
    });
    // In a real implementation, this would adjust the volume
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
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
        
        // Progress slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Slider(
                value: _currentPosition,
                min: 0.0,
                max: _totalDuration,
                onChanged: _seek,
                activeColor: Theme.of(context).primaryColor,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(_currentPosition / 60).floor()}:${(_currentPosition % 60).floor().toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${(_totalDuration / 60).floor()}:${(_totalDuration % 60).floor().toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16.0),
        
        // Audio controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10),
              onPressed: () => _seek((_currentPosition - 10).clamp(0.0, _totalDuration)),
              tooltip: 'Rewind 10 seconds',
            ),
            const SizedBox(width: 8.0),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                iconSize: 32.0,
                onPressed: _togglePlayPause,
                tooltip: _isPlaying ? 'Pause' : 'Play',
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: const Icon(Icons.forward_10),
              onPressed: () => _seek((_currentPosition + 10).clamp(0.0, _totalDuration)),
              tooltip: 'Forward 10 seconds',
            ),
          ],
        ),
        
        const SizedBox(height: 16.0),
        
        // Volume control
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Row(
            children: [
              Icon(
                Icons.volume_down,
                color: Theme.of(context).primaryColor,
              ),
              Expanded(
                child: Slider(
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: _changeVolume,
                  activeColor: Theme.of(context).primaryColor,
                ),
              ),
              Icon(
                Icons.volume_up,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24.0),
        ElevatedButton(
          onPressed: widget.onComplete,
          child: const Text('Mark as Completed'),
        ),
      ],
    );
  }
} 