import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  bool _isPetting = false;

  void _onPet() {
    if (_isPetting) return;
    setState(() => _isPetting = true);
    Future.delayed(2.seconds, () {
      if (mounted) setState(() => _isPetting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
          fallback: 'MAJESTIC GUIDANCE ACTIVE',
        );

        return Container(
          margin: EdgeInsets.symmetric(vertical: 12.h),
          child: Semantics(
            button: true,
            label:
                '${mascotName.toUpperCase()}, $sanctuaryLabel, $guidanceLabel',
            child: ScaleButton(
              onTap: () => context.push(AppRouter.vowlMascotRoute),
              child: Stack(
                children: [
                  // 1. Layered Emerald Glow
                  Positioned.fill(
                    child:
                        ExcludeSemantics(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 24,
                                      spreadRadius: -4,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .shimmer(
                              duration: 3.seconds,
                              color: primaryColor.withValues(alpha: 0.05),
                            ),
                  ),

                  // Premium Floating Card Wrap
                  GlassTile(
                        borderRadius: BorderRadius.circular(28.r),
                        padding: EdgeInsets.all(1.5.r),
                        child: Container(
                          padding: EdgeInsets.all(18.r),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26.r),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryColor.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              // 2. Mascot Emerald Core — also a "pet" affordance,
                              // exposed as its own accessible action distinct
                              // from the card's navigation action.
                              Semantics(
                                button: true,
                                label: context.tr(
                                  'vowl_mascot_card.pet_action', fallback: 'Pet Vowl',
                                  fallback: 'Pet your mascot',
                                ),
                                child: Container(
                                  width: 72.r,
                                  height: 72.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        primaryColor.withValues(alpha: 0.25),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Enhanced Neural Bloom Pulse
                                        ExcludeSemantics(
                                          child:
                                              Container(
                                                    width: 58.r,
                                                    height: 58.r,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: primaryColor
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                  )
                                                  .animate(
                                                    onPlay: (c) => c.repeat(),
                                                  )
                                                  .scale(
                                                    begin: const Offset(
                                                      0.8,
                                                      0.8,
                                                    ),
                                                    end: const Offset(1.4, 1.4),
                                                    duration: 2.seconds,
                                                    curve: Curves.easeOutExpo,
                                                  )
                                                  .fadeOut(duration: 2.seconds)
                                                  .blur(
                                                    begin: const Offset(0, 0),
                                                    end: const Offset(6, 6),
                                                  ),
                                        ),

                                        GestureDetector(
                                          onTap: _onPet,
                                          behavior: HitTestBehavior.opaque,
                                          child: VowlMascot(
                                            state: _isPetting
                                                ? VowlMascotState.happy
                                                : VowlMascotState.neutral,
                                            size: 56.r,
                                            accessoryId: equippedAccessory,
                                            level: data.level,
                                            useFloatingAnimation:
                                                false, // Card already floats
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 20.w),

                              // 3. Info (Elite Branding)
                              Expanded(
                                child: ExcludeSemantics(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: primaryColor,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: primaryColor,
                                                      blurRadius: 6,
                                                    ),
                                                  ],
                                                ),
                                              )
                                              .animate(
                                                onPlay: (c) => c.repeat(),
                                              )
                                              .fadeOut(duration: 1.seconds),
                                          SizedBox(width: 8.w),
                                          Flexible(
                                            child: Text(
                                              sanctuaryLabel,
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 8.5.sp,
                                                fontWeight: FontWeight.w900,
                                                color: primaryColor,
                                                letterSpacing: 2.0,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6.h),
                                      Text(
                                            mascotName.toUpperCase(),
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 22.sp,
                                              fontWeight: FontWeight.w900,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                              letterSpacing: 0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                          .animate()
                                          .fadeIn(delay: 200.ms)
                                          .slideX(begin: -0.1),
                                      Text(
                                        guidanceLabel,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white38
                                              : const Color(0xFF64748B),
                                          letterSpacing: 1.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 4. Elite Access Icon
                              ExcludeSemantics(
                                child:
                                    Container(
                                          padding: EdgeInsets.all(10.r),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withValues(
                                              alpha: 0.12,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: primaryColor.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),
                                          child: Icon(
                                            isRtl
                                                ? Icons
                                                      .keyboard_double_arrow_left_rounded
                                                : Icons
                                                      .keyboard_double_arrow_right_rounded,
                                            color: primaryColor,
                                            size: 20.r,
                                          ),
                                        )
                                        .animate(onPlay: (c) => c.repeat())
                                        .shimmer(
                                          delay: 1.seconds,
                                          duration: 2.seconds,
                                        ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(
                        begin: 0,
                        end: -6,
                        duration: 3.seconds,
                        curve: Curves.easeInOut,
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
