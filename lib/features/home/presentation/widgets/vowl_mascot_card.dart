import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/utils/vowl_assets.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:auto_size_text/auto_size_text.dart';

class VowlMascotCard extends StatefulWidget {
  const VowlMascotCard({super.key});

  @override
  State<VowlMascotCard> createState() => _VowlMascotCardState();
}

/// Compact tuple of just the fields this card actually renders, so the
/// BlocSelector below only triggers a rebuild when one of these specific
/// values changes — not on every unrelated AuthState emission.
class _MascotCardData {
  final String? vowlMascot;
  final String? vowlEquippedAccessory;
  final int level;

  const _MascotCardData({
    required this.vowlMascot,
    required this.vowlEquippedAccessory,
    required this.level,
  });

  @override
  bool operator ==(Object other) =>
      other is _MascotCardData &&
      other.vowlMascot == vowlMascot &&
      other.vowlEquippedAccessory == vowlEquippedAccessory &&
      other.level == level;

  @override
  int get hashCode => Object.hash(vowlMascot, vowlEquippedAccessory, level);
}

class _VowlMascotCardState extends State<VowlMascotCard> {
  @override
  Widget build(BuildContext context) {
    // BUG FIX: this used to be a plain BlocBuilder, so this card's
    // continuously-repeating shimmer/pulse/float animations (built directly
    // into the widget tree via flutter_animate) restarted from frame zero
    // on *every* AuthState emission — including ones with nothing to do
    // with the mascot (e.g. coins or XP changing elsewhere). A BlocSelector
    // keyed to only the fields this card renders means those animations now
    // keep looping smoothly unless something the card actually displays
    // changes.
    return BlocSelector<AuthBloc, AuthState, _MascotCardData?>(
      selector: (state) {
        final user = state.user;
        if (user == null) return null;
        return _MascotCardData(
          vowlMascot: user.vowlMascot,
          vowlEquippedAccessory: user.vowlEquippedAccessory,
          level: user.level,
        );
      },
      builder: (context, data) {
        if (data == null) return const SizedBox.shrink();

        final mascotId = data.vowlMascot ?? 'vowl_prime';
        final mascotName =
            VowlAssets.mascotNames[mascotId] ??
            context.tr(
              'vowl_mascot.elite_fallback_name',
              fallback: 'Vowl Elite',
            );
        final equippedAccessory = data.vowlEquippedAccessory;
        final sanctuaryLabel = context.tr(
          'vowl_mascot_card.sanctuary_linked',
          fallback: 'SANCTUARY LINKED',
        );
        final guidanceLabel = context.tr(
          'vowl_mascot_card.majestic_guidance_active',
          fallback: 'MAJESTIC GUIDANCE',
        ).toUpperCase();

        return Semantics(
          button: true,
          label: '${mascotName.toUpperCase()}, $sanctuaryLabel, $guidanceLabel',
          child: ScaleButton(
            onTap: () => context.push(AppRouter.vowlMascotRoute),
            child: ExcludeSemantics(
              child: GlassTile(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    borderRadius: BorderRadius.circular(20.r),
                    borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    child: SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          // 1. Sleek Mascot Avatar
                          Container(
                            width: 56.r,
                            height: 56.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: VowlMascot(
                              state: VowlMascotState.neutral,
                              size: 40.r,
                              accessoryId: equippedAccessory,
                              level: data.level,
                              useFloatingAnimation: true,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          
                          // 2. Compact Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 10.r,
                                      color: const Color(0xFFF59E0B),
                                    ),
                                    SizedBox(width: 4.w),
                                    Expanded(
                                      child: AutoSizeText(
                                        sanctuaryLabel,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: const Color(0xFFF59E0B),
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                        maxLines: 2,
                                        minFontSize: 8,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                AutoSizeText(
                                  mascotName.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white 
                                        : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  minFontSize: 12,
                                  overflow: TextOverflow.visible,
                                ),
                                SizedBox(height: 2.h),
                                AutoSizeText(
                                  guidanceLabel,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.grey.shade500,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  minFontSize: 8,
                                  overflow: TextOverflow.visible,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          
                          // 3. Ultra-modern subtle chevron
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey.withValues(alpha: 0.3),
                            size: 28.r,
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
        );
      },
    );
  }
}
