import 'package:flutter/foundation.dart';

enum ShareCardType { rank, streak, arenaVictory, arenaInvite, referral }

@immutable
class ShareCardData {
  final ShareCardType type;
  final String userName;
  final String? userPhotoUrl;
  final int? rank;
  final int? streak;
  final int? totalXp;
  final int? level;
  final String title;
  final String subtitle;
  final String? referralCode;

  // 1v1 Arena Duel details
  final int? myScore;
  final int? rivalScore;
  final String? rivalName;
  final String? roomCode;
  final int? payoutCoins;
  final bool isAiRival;

  const ShareCardData({
    this.type = ShareCardType.rank,
    required this.userName,
    this.userPhotoUrl,
    this.rank,
    this.streak,
    this.totalXp,
    this.level,
    required this.title,
    required this.subtitle,
    this.referralCode,
    this.myScore,
    this.rivalScore,
    this.rivalName,
    this.roomCode,
    this.payoutCoins,
    this.isAiRival = false,
  });

  factory ShareCardData.fromArenaVictory({
    required String userName,
    String? userPhotoUrl,
    required int myScore,
    required int rivalScore,
    required String rivalName,
    required String roomCode,
    required int payoutCoins,
    bool isAiRival = false,
  }) {
    return ShareCardData(
      type: ShareCardType.arenaVictory,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      myScore: myScore,
      rivalScore: rivalScore,
      rivalName: rivalName,
      roomCode: roomCode,
      payoutCoins: payoutCoins,
      isAiRival: isAiRival,
      title: '1v1 DUEL WINNER',
      subtitle: rivalName.isNotEmpty
          ? 'Beat $rivalName in a 1v1 English Duel'
          : '1v1 English Duel Victory',
    );
  }

  factory ShareCardData.fromArenaDefeat({
    required String userName,
    String? userPhotoUrl,
    required int myScore,
    required int rivalScore,
    required String rivalName,
    required String roomCode,
    required int payoutCoins,
    bool isAiRival = false,
  }) {
    return ShareCardData(
      type: ShareCardType.arenaVictory,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      myScore: myScore,
      rivalScore: rivalScore,
      rivalName: rivalName,
      roomCode: roomCode,
      payoutCoins: payoutCoins,
      isAiRival: isAiRival,
      title: '1v1 DUEL CONTENDER',
      subtitle: rivalName.isNotEmpty
          ? 'Battled $rivalName in a 1v1 English Duel — rematch incoming!'
          : '1v1 English Duel Contender',
    );
  }

  factory ShareCardData.fromDuelInvite({
    required String userName,
    String? userPhotoUrl,
    required String roomCode,
  }) {
    return ShareCardData(
      type: ShareCardType.arenaInvite,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      roomCode: roomCode,
      payoutCoins: 50,
      title: '1v1 DUEL CHALLENGE',
      subtitle: 'Enter room code on Vowl to play live!',
    );
  }

  factory ShareCardData.fromReferral({
    required String userName,
    String? userPhotoUrl,
    required String referralCode,
  }) {
    return ShareCardData(
      type: ShareCardType.referral,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      referralCode: referralCode,
      title: 'INVITE FROM $userName',
      subtitle: 'Get 100 free coins & test your English on Vowl',
    );
  }

  factory ShareCardData.fromRank({
    required String userName,
    String? userPhotoUrl,
    required int rank,
    required int totalXp,
    required int streak,
    String? referralCode,
  }) {
    return ShareCardData(
      type: ShareCardType.rank,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      rank: rank,
      totalXp: totalXp,
      streak: streak,
      title: 'Rank #$rank on Vowl',
      subtitle: '$totalXp Total XP · $streak-Day Streak',
      referralCode: referralCode,
    );
  }

  factory ShareCardData.fromStreak({
    required String userName,
    String? userPhotoUrl,
    required int streak,
    required int totalXp,
    String? referralCode,
  }) {
    return ShareCardData(
      type: ShareCardType.streak,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      streak: streak,
      totalXp: totalXp,
      title: '$streak-Day Learning Streak',
      subtitle: '$streak days of learning English on Vowl',
      referralCode: referralCode,
    );
  }
}
