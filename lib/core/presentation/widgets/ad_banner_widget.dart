import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';

/// A reusable banner ad widget that:
/// - Auto-loads on mount, auto-disposes on unmount
/// - Hides completely for premium users
/// - Shows an empty SizedBox while loading
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
    if (isPremium) return; // Premium users see no ads

    final adService = di.sl<AdService>();
    adService.loadBannerAd();

    // Use a small delay to let the ad load, then check
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && adService.isBannerLoaded && adService.bannerAd != null) {
        setState(() {
          _bannerAd = adService.bannerAd;
          _isLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    di.sl<AdService>().disposeBannerAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AuthBloc>().state.user?.isPremium ?? false;

    // Premium users: no banner at all
    if (isPremium) return const SizedBox.shrink();

    // Not loaded yet: reserve space to avoid layout jumps
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(height: 50);
    }

    return SafeArea(
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
