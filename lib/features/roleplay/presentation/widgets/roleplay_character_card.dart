import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

/// Displays the role name and icon of the AI character in the current quest.
///
/// Stateless and const-constructible — safe to use in any rebuild context.
class RoleplayCharacterCard extends StatelessWidget {
  const RoleplayCharacterCard({
    super.key,
    required this.roleName,
    required this.icon,
    required this.primaryColor,
  });

  final String roleName;
  final IconData icon;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Character: $roleName',
      header: true,
      child: GlassTile(
        padding: EdgeInsets.all(24.r),
        borderRadius: BorderRadius.circular(32.r),
        color: primaryColor.withValues(alpha: 0.1),
        child: Row(
          children: [
            _IconBadge(icon: icon, primaryColor: primaryColor),
            SizedBox(width: 20.w),
            Expanded(
              child: Text(
                roleName,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.primaryColor});

  final IconData icon;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: primaryColor, size: 32.r),
    );
  }
}
