import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/navigation_helpers.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';
import 'package:vowl/features/daily_words/presentation/bloc/daily_words_bloc.dart';
import 'package:vowl/features/daily_words/presentation/pages/daily_words_screen.dart';
import 'package:vowl/features/daily_words/presentation/pages/word_bank_screen.dart';

class DailyWordsRoutes {
  DailyWordsRoutes._();

  static const String dailyWordsRoute = '/daily-words';
  static const String wordBankRoute = '/word-bank';

  static final List<RouteBase> routes = [
    GoRoute(
      path: dailyWordsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: BlocProvider<DailyWordsBloc>(
          create: (_) => DailyWordsBloc(
            service: di.sl<DailyWordsService>(),
          ),
          child: const DailyWordsScreen(),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: wordBankRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: BlocProvider<DailyWordsBloc>(
          create: (_) => DailyWordsBloc(
            service: di.sl<DailyWordsService>(),
          ),
          child: const WordBankScreen(),
        ),
        state: state,
      ),
    ),
  ];
}
