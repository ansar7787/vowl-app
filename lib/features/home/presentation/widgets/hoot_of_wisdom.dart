import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class HootOfWisdom extends StatefulWidget {
  const HootOfWisdom({super.key});

  @override
  State<HootOfWisdom> createState() => _HootOfWisdomState();
}

class _HootOfWisdomState extends State<HootOfWisdom> {
  String _hootTitle = "OWLY'S HOOT";
  String _hootText = "...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyHoot();
  }

  Future<void> _loadDailyHoot() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/curriculum/calendar/vowl_calendar.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final now = DateTime.now();
      final String dateKey = DateFormat('MM-DD').format(now);
      final String specificKey = DateFormat('yyyy-MM-DD').format(now);

      String title = "OWLY'S WISDOM";
      String text = "";

      // 1. Check Specific Date (e.g. 2026-04-28)
      if (data['specific'] != null && data['specific'][specificKey] != null) {
        title = data['specific'][specificKey]['title'];
        text = data['specific'][specificKey]['text'];
      } 
      // 2. Check Annual Date (e.g. 12-25)
      else if (data['annual'] != null && data['annual'][dateKey] != null) {
        title = data['annual'][dateKey]['title'];
        text = data['annual'][dateKey]['text'];
      } 
      // 3. Fallback to Random Wisdom
      else {
        title = "DAILY MOTIVATION";
        final List<dynamic> fallbacks = data['fallbacks'] ?? [];
        if (fallbacks.isNotEmpty) {
          text = fallbacks[Random().nextInt(fallbacks.length)];
        } else {
          text = "Hoot! Your dedication is truly majestic!";
        }
      }

      if (mounted) {
        setState(() {
          _hootTitle = title;
          _hootText = text;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hootText = "Hoot! I'm feeling a bit quiet today. Keep soaring!";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final dayStr = DateFormat('dd').format(now);
    final monthStr = DateFormat('MMM').format(now).toUpperCase();

    return GlassTile(
      borderRadius: BorderRadius.circular(32.r),
      padding: EdgeInsets.all(24.r),
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
        : Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Date Badge (Standard App Style)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          monthStr,
                          style: GoogleFonts.outfit(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        Text(
                          dayStr,
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Owly Identifier
                  Row(
                    children: [
                      Text(
                        _hootTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2563EB),
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text("🦉", style: TextStyle(fontSize: 22.sp)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              
              // 3. The Wisdom Text
              Text(
                _hootText,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF1E293B),
                  height: 1.5,
                ),
              ),
            ],
          ),
    );
  }
}
