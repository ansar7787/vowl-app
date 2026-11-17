import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// Helper to optimistically record a completed game phase ('learn', 'practice', 'mastery')
/// into local BLoC state and cache so that map dots and routing immediately reflect the progress.
class PhaseProgressRecorder {
  PhaseProgressRecorder._();

  static void recordPhaseCompleted(
    BuildContext context, {
    required String gameType,
    required int level,
    required String phase,
  }) {
    try {
      context.read<AuthBloc>().add(
        AuthPhaseCompleted(
          gameType: gameType,
          level: level,
          phase: phase,
        ),
      );
    } catch (_) {}
  }
}
