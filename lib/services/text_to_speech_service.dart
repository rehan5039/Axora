import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  
  TextToSpeechService() {
    _initTts();
  }
  
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("hi-IN"); // Setting to Hindi by default for Hinglish
    
    // Set different speech rates based on platform
    if (!kIsWeb && Platform.isAndroid) {
      // Android needs a slower rate since it runs faster
      await _flutterTts.setSpeechRate(0.4);
    } else {
      // Web and other platforms use this rate
      await _flutterTts.setSpeechRate(0.8);
    }
    
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
    });
  }
  
  Future<void> speak(String text) async {
    if (!_isPlaying) {
      _isPlaying = true;
      await _flutterTts.speak(text);
    }
  }
  
  Future<void> stop() async {
    _isPlaying = false;
    await _flutterTts.stop();
  }
  
  bool get isPlaying => _isPlaying;
  
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }
  
  void setCompletionHandler(VoidCallback callback) {
    _flutterTts.setCompletionHandler(callback);
  }
  
  void dispose() {
    _flutterTts.stop();
  }
} 