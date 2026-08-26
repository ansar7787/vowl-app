import 'package:flutter_bloc/flutter_bloc.dart';

enum TrophyFilter { all, legendary, standard }

class TrophyRoomState {
  final List<String> allBadges;
  final List<String> filteredBadges;
  final TrophyFilter currentFilter;

  const TrophyRoomState({
    required this.allBadges,
    required this.filteredBadges,
    required this.currentFilter,
  });

  factory TrophyRoomState.initial(List<String> badges) {
    return TrophyRoomState(
      allBadges: badges,
      filteredBadges: badges,
      currentFilter: TrophyFilter.all,
    );
  }

  TrophyRoomState copyWith({
    List<String>? allBadges,
    List<String>? filteredBadges,
    TrophyFilter? currentFilter,
  }) {
    return TrophyRoomState(
      allBadges: allBadges ?? this.allBadges,
      filteredBadges: filteredBadges ?? this.filteredBadges,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class TrophyRoomCubit extends Cubit<TrophyRoomState> {
  TrophyRoomCubit(List<String> initialBadges)
    : super(TrophyRoomState.initial(initialBadges));

  void updateFilter(TrophyFilter filter) {
    List<String> filtered;
    switch (filter) {
      case TrophyFilter.legendary:
        filtered = state.allBadges.where((b) => _isLegendary(b)).toList();
        break;
      case TrophyFilter.standard:
        filtered = state.allBadges.where((b) => !_isLegendary(b)).toList();
        break;
      case TrophyFilter.all:
        filtered = List.from(state.allBadges);
        break;
    }
    emit(state.copyWith(currentFilter: filter, filteredBadges: filtered));
  }

  bool _isLegendary(String badgeId) {
    return badgeId.contains('master') ||
        badgeId.contains('legend') ||
        badgeId.contains('100');
  }
}
