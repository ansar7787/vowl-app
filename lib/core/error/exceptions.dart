import 'package:flutter/foundation.dart';

/// Base class representing all application-specific exceptions.
/// 
/// Resides in the core layer to ensure centralized, predictable error handling,
/// telemetry logging, and Crashlytics tracking.
@immutable
abstract class AppException implements Exception {
  /// User-friendly message explaining the error.
  final String message;

  /// System-level unique error code (e.g. 'AUTH_INVALID_CREDENTIALS').
  final String? code;

  /// Optional underlying object or diagnostic stack trace related to the exception.
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() {
    final prefix = code != null ? '[$code] ' : '';
    return '$prefix$runtimeType: $message';
  }
}

/// Represents backend, API, or Firestore database failure.
/// 
/// Retains full backward compatibility with positional constructors.
class ServerException extends AppException {
  final int? statusCode;

  const ServerException([
    String? message,
    String? code,
    this.statusCode,
    dynamic details,
  ]) : super(
          message: message ?? 'ServerException',
          code: code,
          details: details,
        );
}

/// Represents local database caching or persistent storage failures (e.g., SQLite, Hive, SharedPreferences).
/// 
/// Retains full backward compatibility with positional constructors.
class CacheException extends AppException {
  const CacheException([
    String? message,
    String? code,
    dynamic details,
  ]) : super(
          message: message ?? 'CacheException',
          code: code,
          details: details,
        );
}

/// Represents internet offline status, socket timeouts, or bad gateways.
class NetworkException extends AppException {
  const NetworkException([
    String? message,
    String? code,
    dynamic details,
  ]) : super(
          message: message ?? 'NetworkException',
          code: code,
          details: details,
        );
}

/// Represents authentication anomalies (e.g., expired tokens, invalid credentials, Google Sign-in cancellations).
class AuthException extends AppException {
  const AuthException([
    String? message,
    String? code,
    dynamic details,
  ]) : super(
          message: message ?? 'AuthException',
          code: code,
          details: details,
        );
}

/// Represents Text-To-Speech (TTS), speech-to-text recorders, or microphonic hardware processing failures.
class SpeechException extends AppException {
  const SpeechException([
    String? message,
    String? code,
    dynamic details,
  ]) : super(
          message: message ?? 'SpeechException',
          code: code,
          details: details,
        );
}

/// Represents mobile advertising provider disruptions (e.g., ad load, reward video failures).
class AdException extends AppException {
  const AdException([
    String? message,
    String? code,
    dynamic details,
  ]) : super(
          message: message ?? 'AdException',
          code: code,
          details: details,
        );
}

/// Represents in-app purchase, standard subscription billing, or VIP claim anomalies.
class PaymentException extends AppException {
  const PaymentException([
    String? message,
    String? code,
    dynamic details,
  ]) : super(
          message: message ?? 'PaymentException',
          code: code,
          details: details,
        );
}

/// Represents local audio file streaming, system playback, or recorder hardware initialization bugs.
class AudioException extends AppException {
  const AudioException([
    String? message,
    String? code,
    dynamic details,
  ]) : super(
          message: message ?? 'AudioException',
          code: code,
          details: details,
        );
}

/// Represents input validation formatting conflicts (e.g. invalid emails, corrupt JSON files).
class ValidationException extends AppException {
  const ValidationException([
    String? message,
    String? code,
    dynamic details,
  ]) : super(
          message: message ?? 'ValidationException',
          code: code,
          details: details,
        );
}
