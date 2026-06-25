import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Base class representing domain-level failures returned by Repositories.
///
/// Resides in the core layer to cleanly isolate errors from leakage into
/// business use cases, keeping state presentation deterministic and highly testable.
@immutable
abstract class Failure extends Equatable {
  /// Localized or user-friendly message describing the error.
  final String message;

  /// Unique system-level internal error code (e.g., 'AUTH_USER_NOT_FOUND').
  final String? code;

  /// Optional underlying object or diagnostics related to the failure.
  final dynamic details;

  const Failure(this.message, {this.code, this.details});

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() {
    final prefix = code != null ? '[$code] ' : '';
    return '$prefix$runtimeType: $message';
  }
}

/// Represents backend, API endpoint, or remote database failure.
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(
    super.message, {
    super.code,
    this.statusCode,
    super.details,
  });
}

/// Represents authentication exceptions, permission blockages, or expired sessions.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.details});
}

/// Represents local persistent caching database or preference loading anomalies.
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code, super.details});
}

/// Represents internet offline states, connection timeouts, or socket failures.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code, super.details});
}

/// Represents Text-To-Speech (TTS), speech-to-text recorders, or microphonic hardware processing failures.
class SpeechFailure extends Failure {
  const SpeechFailure(super.message, {super.code, super.details});
}

/// Represents mobile advertising provider disruptions (e.g., ad load, reward video failures).
class AdFailure extends Failure {
  const AdFailure(super.message, {super.code, super.details});
}

/// Represents in-app purchase, standard subscription billing, or VIP claim anomalies.
class PaymentFailure extends Failure {
  const PaymentFailure(super.message, {super.code, super.details});
}

/// Represents local audio file streaming, system playback, or recorder hardware initialization bugs.
class AudioFailure extends Failure {
  const AudioFailure(super.message, {super.code, super.details});
}

/// Represents client-side dynamic validation conflicts or data parser formatting issues.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.details});
}
