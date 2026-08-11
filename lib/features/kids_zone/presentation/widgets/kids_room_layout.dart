import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_background_renderer.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_furniture_renderer.dart';

class KidsRoomLayout extends StatelessWidget {
  final String theme;
  final Map<String, String> equippedFurniture;
  final Map<String, List<Map<String, dynamic>>> furnitureStore;
  final Widget mascotWidget;
  final Widget topBarWidget;
  final Widget actionPanelWidget;
  final Widget? overlayWidget; // For dialogs, feeding, etc.

  const KidsRoomLayout({
    super.key,
    required this.theme,
    required this.equippedFurniture,
    required this.furnitureStore,
    required this.mascotWidget,
    required this.topBarWidget,
    required this.actionPanelWidget,
    this.overlayWidget,
  });

  Map<String, dynamic>? _getEquippedItem(String category) {
    final id = equippedFurniture[category];
    if (id == null) return null;
    final items = furnitureStore[category];
    if (items == null) return null;
    try {
      return items.firstWhere((item) => item['id'] == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Wall Layer (Background)
        Positioned.fill(
          child: KidsBackgroundRenderer(
            painterName: _getThemePainter(),
            shaderName: '', // Not used
            primaryColor: _getThemeColor(),
            gameType: 'room',
          ),
        ),

        // 2. Day/Night Ambient Overlay based on device clock
        Positioned.fill(
          child: _buildAmbientOverlay(context),
        ),

        // 3. Wall Furniture (Window, Shelf)
        Positioned(
          top: 140.h,
          right: 30.w,
          child: KidsRoomFurnitureRenderer(
            item: _getEquippedItem('window'),
            category: 'window',
          ),
        ),
        if (furnitureStore.containsKey('shelf')) // Safe fallback
          Positioned(
            top: 160.h,
            left: 20.w,
            child: KidsRoomFurnitureRenderer(
              item: _getEquippedItem('shelf'),
              category: 'shelf',
            ),
          ),

        // 4. Floor Layer
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 250.h,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getThemeColor().withValues(alpha: 0.15),
                  _getThemeColor().withValues(alpha: 0.5),
                  _getThemeColor().withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 3.h,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: _getThemeColor().withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: const Offset(0, -10),
                )
              ]
            ),
          ),
        ),

        // 5. Floor Furniture (Rug)
        if (furnitureStore.containsKey('rug'))
          Positioned(
            bottom: 120.h,
            left: 0,
            right: 0,
            child: Center(
              child: KidsRoomFurnitureRenderer(
                item: _getEquippedItem('rug'),
                category: 'rug',
              ),
            ),
          ),

        // 6. Main Floor Furniture (Bed, Plant, Toy)
        Positioned(
          bottom: 160.h,
          left: 10.w,
          child: KidsRoomFurnitureRenderer(
            item: _getEquippedItem('bed'),
            category: 'bed',
          ),
        ),
        if (furnitureStore.containsKey('plant'))
          Positioned(
            bottom: 180.h,
            right: 20.w,
            child: KidsRoomFurnitureRenderer(
              item: _getEquippedItem('plant'),
              category: 'plant',
            ),
          ),
        if (furnitureStore.containsKey('toy'))
          Positioned(
            bottom: 140.h,
            right: 80.w,
            child: KidsRoomFurnitureRenderer(
              item: _getEquippedItem('toy'),
              category: 'toy',
            ),
          ),

        // 7. Mascot (Center Stage)
        Positioned(
          bottom: 150.h,
          left: 0,
          right: 0,
          child: mascotWidget,
        ),

        // 8. Top Bar & Action Panel
        Positioned.fill(
          child: SafeArea(
            child: Column(
              children: [
                topBarWidget,
                const Spacer(),
                actionPanelWidget,
              ],
            ),
          ),
        ),

        // 9. Overlays (Dialogs, interactions)
        if (overlayWidget != null)
          Positioned.fill(
            child: overlayWidget!,
          ),
      ],
    );
  }

  Widget _buildAmbientOverlay(BuildContext context) {
    final hour = DateTime.now().hour;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color overlayColor = Colors.transparent;
    BlendMode blendMode = BlendMode.dstOver;

    if (hour >= 20 || hour < 6) {
      // Night time
      overlayColor = isDark 
          ? const Color(0xFF0F172A).withValues(alpha: 0.5) 
          : const Color(0xFF1E1B4B).withValues(alpha: 0.4);
      blendMode = BlendMode.darken;
    } else if (hour >= 18 && hour < 20) {
      // Evening/Sunset
      overlayColor = const Color(0xFFF59E0B).withValues(alpha: 0.2);
      blendMode = BlendMode.overlay;
    }

    return Container(
      decoration: BoxDecoration(
        color: overlayColor,
        backgroundBlendMode: blendMode,
      ),
      // Prevent pointer events from being blocked
      child: const IgnorePointer(),
    );
  }

  String _getThemePainter() {
    switch (theme) {
      case 'space': return 'StarryNight';
      case 'ocean': return 'OceanWave';
      case 'sweet': return 'CandyCloud';
      case 'nature':
      default: return 'ForestFriend';
    }
  }

  Color _getThemeColor() {
    switch (theme) {
      case 'space': return const Color(0xFF312E81); // Indigo 900
      case 'ocean': return const Color(0xFF0284C7); // Light Blue 600
      case 'sweet': return const Color(0xFFBE185D); // Pink 700
      case 'nature':
      default: return const Color(0xFF15803D); // Green 700
    }
  }
}
