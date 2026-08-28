import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/utils/vowl_assets.dart';
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
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    constraints: BoxConstraints(minHeight: 160.h),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32.r),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF59E0B), // Premium Amber
                          Color(0xFFD97706), // Deep Amber
                          Color(0xFFFBBF24), // Bright Gold
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32.r),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Decorative background circles
                          PositionedDirectional(
                            end: -30.w,
                            bottom: -30.h,
                            child: Container(
                              width: 180.r,
                              height: 180.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                          ),

                          // Playful background icons
                          PositionedDirectional(
                            start: 20.w,
                            top: 20.h,
                            child: Icon(
                              Icons.diamond_rounded,
                              size: 24.r,
                              color: Colors.white.withValues(alpha: 0.25),
                            ).animate().scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1, 1),
                              duration: 800.ms,
                              curve: Curves.easeOutBack,
                            ),
                          ),

                          // Text Content (Moved to left side)
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                              24.w,
                              16.h,
                              130.w,
                              16.h,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 10.r,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4.w),
                                      Flexible(
                                        child: AutoSizeText(
                                          sanctuaryLabel,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            color: Colors.white,
                                            fontSize: 8.sp,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                          ),
                                          maxLines: 1,
                                          minFontSize: 6,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                AutoSizeText(
                                  mascotName.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    height: 1.0,
                                  ),
                                  maxLines: 1,
                                  minFontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                AutoSizeText(
                                  guidanceLabel,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  minFontSize: 8,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Mascot Area (Right Side)
                  PositionedDirectional(
                    end: 0,
                    bottom: 0,
                    top: 0,
                    child: SizedBox(
                      width: 140.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Outer Soft Glow
                          Container(
                            width: 140.r,
                            height: 140.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.2),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ).animate().scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1, 1),
                            duration: 800.ms,
                            curve: Curves.easeOutBack,
                          ),

                          // 2. Secondary Interactive Ring
                          Container(
                            width: 100.r,
                            height: 100.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                          ).animate().rotate(
                            begin: -0.5,
                            end: 0,
                            duration: 1000.ms,
                            curve: Curves.easeOutBack,
                          ),

                          // 3. The Mascot
                          Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2.r,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 25,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: VowlMascot(
                              state: VowlMascotState.neutral,
                              size: 56.r,
                              accessoryId: equippedAccessory,
                              level: data.level,
                              useFloatingAnimation: false,
                            ),
                          ).animate().scale(
                            begin: const Offset(0, 0),
                            end: const Offset(1, 1),
                            duration: 800.ms,
                            curve: Curves.easeOutBack,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
