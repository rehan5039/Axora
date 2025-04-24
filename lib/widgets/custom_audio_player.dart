import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:rxdart/rxdart.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

class CustomAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final Function()? onComplete;
  final bool isDarkMode;
  final String audioScript;

  const CustomAudioPlayer({
    super.key,
    required this.audioUrl,
    this.onComplete,
    required this.isDarkMode,
    this.audioScript = '',
  });

  @override
  State<CustomAudioPlayer> createState() => _CustomAudioPlayerState();
}

class _CustomAudioPlayerState extends State<CustomAudioPlayer> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isCompleted = false;
  String _errorMessage = '';

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    
    try {
      setState(() => _isLoading = true);
      
      // Set up error handling
      _audioPlayer.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace st) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Error loading audio: ${e.toString()}';
          });
        },
      );

      // Load audio source
      await _audioPlayer.setUrl(widget.audioUrl);
      
      // Set up completion callback
      _audioPlayer.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          setState(() {
            _isCompleted = true;
          });
          widget.onComplete?.call();
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error initializing audio player: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Release the player's resources when not in use
      _audioPlayer.stop();
    }
  }

  Future<void> _retryLoading() async {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    await _initAudioPlayer();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isDarkMode ? Colors.deepPurple : Colors.blue;
    final backgroundColor = widget.isDarkMode 
        ? Colors.grey[850]!.withOpacity(0.5) 
        : Colors.grey[200]!.withOpacity(0.5);
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage,
              style: TextStyle(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retryLoading,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isCompleted)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else
            StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data ??
                    PositionData(Duration.zero, Duration.zero, Duration.zero);

                return Column(
                  children: [
                    // Progress bar
                    ProgressBar(
                      progress: positionData.position,
                      buffered: positionData.bufferedPosition,
                      total: positionData.duration,
                      onSeek: _audioPlayer.seek,
                      baseBarColor: widget.isDarkMode 
                          ? Colors.grey[700] 
                          : Colors.grey[300],
                      progressBarColor: primaryColor,
                      bufferedBarColor: primaryColor.withOpacity(0.3),
                      thumbColor: primaryColor,
                      barHeight: 4,
                      thumbRadius: 6,
                      timeLabelTextStyle: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildControlButton(
                          icon: Icons.replay_10,
                          onPressed: () => _audioPlayer.seek(
                            positionData.position - const Duration(seconds: 10),
                          ),
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(width: 24),
                        StreamBuilder<PlayerState>(
                          stream: _audioPlayer.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final processingState = playerState?.processingState;
                            final playing = playerState?.playing;

                            if (processingState == ProcessingState.loading ||
                                processingState == ProcessingState.buffering) {
                              return Container(
                                width: 64,
                                height: 64,
                                padding: const EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                ),
                              );
                            } else if (playing != true) {
                              return _buildControlButton(
                                icon: Icons.play_circle_filled,
                                onPressed: _audioPlayer.play,
                                primaryColor: primaryColor,
                                large: true,
                              );
                            } else {
                              return _buildControlButton(
                                icon: Icons.pause_circle_filled,
                                onPressed: _audioPlayer.pause,
                                primaryColor: primaryColor,
                                large: true,
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 24),
                        _buildControlButton(
                          icon: Icons.forward_10,
                          onPressed: () => _audioPlayer.seek(
                            positionData.position + const Duration(seconds: 10),
                          ),
                          primaryColor: primaryColor,
                        ),
                        
                        // Add script icon if script is available
                        if (widget.audioScript.isNotEmpty) ...[
                          const SizedBox(width: 24),
                          _buildControlButton(
                            icon: Icons.description,
                            onPressed: () => _showScriptDialog(context),
                            primaryColor: primaryColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color primaryColor,
    bool large = false,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        size: large ? 64 : 32,
        color: primaryColor,
      ),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      splashRadius: large ? 32 : 24,
    );
  }

  void _showScriptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Meditation Script',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Text(
              widget.audioScript,
              style: TextStyle(
                fontSize: 16,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ),
        backgroundColor: widget.isDarkMode ? Colors.grey[850] : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.deepPurple : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 