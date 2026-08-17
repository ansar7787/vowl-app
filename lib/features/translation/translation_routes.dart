import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/translation/presentation/bloc/translation_bloc.dart';
import 'package:vowl/features/translation/presentation/pages/translate_screen.dart';

List<RouteBase> get translationRoutes => [
  GoRoute(
    path: AppRouter.translateRoute,
    builder: (context, state) {
      return BlocProvider(
        create: (_) => di.sl<TranslationBloc>(),
        child: const TranslateScreen(),
      );
    },
  ),
];
