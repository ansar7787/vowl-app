import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/utils/praise_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

class GlobalAudioFeedbackListener extends StatelessWidget {
  final Widget child;

  const GlobalAudioFeedbackListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Kids Zone
        BlocListener<KidsBloc, KidsState>(
          bloc: di.sl<KidsBloc>(),
          listenWhen: (prev, curr) => 
            (curr is KidsLoaded && prev is KidsLoaded && curr.lastAnswerCorrect == true && prev.lastAnswerCorrect != true) ||
            (curr is KidsGameComplete && prev is! KidsGameComplete),
          listener: (context, state) {
            di.sl<PraiseService>().givePraise(isKids: true);
          },
        ),
        // Grammar
        BlocListener<GrammarBloc, GrammarState>(
          bloc: di.sl<GrammarBloc>(),
          listenWhen: (prev, curr) => 
            (curr is GrammarLoaded && prev is GrammarLoaded && curr.lastAnswerCorrect == true && prev.lastAnswerCorrect != true) ||
            (curr is GrammarGameComplete && prev is! GrammarGameComplete),
          listener: (context, state) {
            di.sl<PraiseService>().givePraise();
          },
        ),
        // Speaking
        BlocListener<SpeakingBloc, SpeakingState>(
          bloc: di.sl<SpeakingBloc>(),
          listenWhen: (prev, curr) => 
            (curr is SpeakingLoaded && prev is SpeakingLoaded && curr.lastAnswerCorrect == true && prev.lastAnswerCorrect != true) ||
            (curr is SpeakingGameComplete && prev is! SpeakingGameComplete),
          listener: (context, state) {
            di.sl<PraiseService>().givePraise();
          },
        ),
        // Reading
        BlocListener<ReadingBloc, ReadingState>(
          bloc: di.sl<ReadingBloc>(),
          listenWhen: (prev, curr) => 
            (curr is ReadingLoaded && prev is ReadingLoaded && curr.lastAnswerCorrect == true && prev.lastAnswerCorrect != true) ||
            (curr is ReadingGameComplete && prev is! ReadingGameComplete),
          listener: (context, state) {
            di.sl<PraiseService>().givePraise();
          },
        ),
        // Writing
        BlocListener<WritingBloc, WritingState>(
          bloc: di.sl<WritingBloc>(),
          listenWhen: (prev, curr) => 
            (curr is WritingLoaded && prev is WritingLoaded && curr.lastAnswerCorrect == true && prev.lastAnswerCorrect != true) ||
            (curr is WritingGameComplete && prev is! WritingGameComplete),
          listener: (context, state) {
            di.sl<PraiseService>().givePraise();
          },
        ),
        // Listening
        BlocListener<ListeningBloc, ListeningState>(
          bloc: di.sl<ListeningBloc>(),
          listenWhen: (prev, curr) => 
            (curr is ListeningLoaded && prev is ListeningLoaded && curr.lastAnswerCorrect == true && prev.lastAnswerCorrect != true) ||
            (curr is ListeningGameComplete && prev is! ListeningGameComplete),
          listener: (context, state) {
            di.sl<PraiseService>().givePraise();
          },
        ),
        // Accent
        BlocListener<AccentBloc, AccentState>(
          bloc: di.sl<AccentBloc>(),
          listenWhen: (prev, curr) => 
            (curr is AccentLoaded && prev is AccentLoaded && curr.lastAnswerCorrect == true && prev.lastAnswerCorrect != true) ||
            (curr is AccentGameComplete && prev is! AccentGameComplete),
          listener: (context, state) {
            di.sl<PraiseService>().givePraise();
          },
        ),
        // Roleplay
        BlocListener<RoleplayBloc, RoleplayState>(
          bloc: di.sl<RoleplayBloc>(),
          listenWhen: (prev, curr) => 
            (curr is RoleplayLoaded && prev is RoleplayLoaded && curr.lastAnswerCorrect == true && prev.lastAnswerCorrect != true) ||
            (curr is RoleplayGameComplete && prev is! RoleplayGameComplete),
          listener: (context, state) {
            di.sl<PraiseService>().givePraise();
          },
        ),
        // Vocabulary
        BlocListener<VocabularyBloc, VocabularyState>(
          bloc: di.sl<VocabularyBloc>(),
          listenWhen: (prev, curr) => 
            (curr is VocabularyLoaded && prev is VocabularyLoaded && curr.lastAnswerCorrect == true && prev.lastAnswerCorrect != true) ||
            (curr is VocabularyGameComplete && prev is! VocabularyGameComplete),
          listener: (context, state) {
            di.sl<PraiseService>().givePraise();
          },
        ),
      ],
      child: child,
    );
  }
}
