import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Log custom events
  Future<void> logCustomEvent(String name, Map<String, dynamic>? parameters) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  // Log when user starts meditation
  Future<void> logMeditationStart({
    required String meditationId,
    required String meditationType,
    required int durationMinutes,
  }) async {
    await _analytics.logEvent(
      name: 'meditation_started',
      parameters: {
        'meditation_id': meditationId,
        'meditation_type': meditationType,
        'duration_minutes': durationMinutes,
      },
    );
  }

  // Log when user completes meditation
  Future<void> logMeditationComplete({
    required String meditationId,
    required String meditationType,
    required int durationMinutes,
  }) async {
    await _analytics.logEvent(
      name: 'meditation_completed',
      parameters: {
        'meditation_id': meditationId,
        'meditation_type': meditationType,
        'duration_minutes': durationMinutes,
      },
    );
  }

  // Log when user starts a challenge
  Future<void> logChallengeStart({
    required String challengeId,
    required String challengeName,
  }) async {
    await _analytics.logEvent(
      name: 'challenge_started',
      parameters: {
        'challenge_id': challengeId,
        'challenge_name': challengeName,
      },
    );
  }

  // Log when user completes a challenge
  Future<void> logChallengeComplete({
    required String challengeId,
    required String challengeName,
  }) async {
    await _analytics.logEvent(
      name: 'challenge_completed',
      parameters: {
        'challenge_id': challengeId,
        'challenge_name': challengeName,
      },
    );
  }

  // Log user properties
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Set user ID
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  // Enable analytics collection
  Future<void> enableAnalytics() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  // Disable analytics collection
  Future<void> disableAnalytics() async {
    await _analytics.setAnalyticsCollectionEnabled(false);
  }
} 