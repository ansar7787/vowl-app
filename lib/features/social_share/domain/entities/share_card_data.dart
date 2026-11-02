import 'package:flutter/foundation.dart';

@immutable
class ShareCardData {
  final String userName;
  final String? userPhotoUrl;
  final int? rank;
  final int? streak;
  final int? totalXp;
  final int? level;
  final String title;
  final String subtitle;
  final String? referralCode;

  const ShareCardData({
    required this.userName,
    this.userPhotoUrl,
    this.rank,
    this.streak,
    this.totalXp,
    this.level,
    required this.title,
    required this.subtitle,
    this.referralCode,
  });

  factory ShareCardData.fromRank({
    required String userName,
    String? userPhotoUrl,
    required int rank,
    required int totalXp,
    required int streak,
    String? referralCode,
  }) {
    return ShareCardData(
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      rank: rank,
      totalXp: totalXp,
      streak: streak,
      title: 'Rank #$rank Global Standing',
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
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      streak: streak,
      totalXp: totalXp,
      title: '$streak-Day Learning Streak',
      subtitle: 'Committed to English mastery on Vowl',
      referralCode: referralCode,
    );
  }
}

