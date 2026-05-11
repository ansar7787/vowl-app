import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/features/kids_zone/data/datasources/kids_quest_upload_service.dart';

class KidsAdminScreen extends StatefulWidget {
  const KidsAdminScreen({super.key});

  @override
  State<KidsAdminScreen> createState() => _KidsAdminScreenState();
}

class _KidsAdminScreenState extends State<KidsAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _jsonController = TextEditingController();
  final _uploadService = KidsQuestUploadService();
  String _selectedGameType = 'alphabet';
  bool _isLoading = false;
  String _status = 'Ready to push content... 🚀';

  // Stats
  int _detectedQuests = 0;
  int _detectedLevels = 0;
  int _firestoreQuests = 0;
  int _firestoreLevels = 0;

  final Map<String, String> _gamePrompts = {
    'alphabet':
        "Uppercase/Lowercase recognition and basic phonics identification.",
    'numbers': "Counting 1-100 and digit recognition with visual aids.",
    'colors': "Primary and secondary colors in real-world contexts.",
    'shapes': "Basic 2D shapes with real-world object comparisons.",
    'animals': "Animal names and sounds across farm, jungle, and ocean.",
    'fruits': "Common fruit identification including names and colors.",
    'family': "Relationships: Mother, Father, Sister, Brother, etc.",
    'school': "Classroom items and learning tools vocabulary.",
    'verbs': "Simple daily actions (Run, Jump, Eat, Read).",
    'emotions': "Social-emotional learning (Happy, Sad, Angry).",
    'routine': "Sequence of daily life activities (Brushing, Eating).",
    'opposites': "Comparison concepts (Big/Small, Hot/Cold).",
    'prepositions': "Spatial awareness (In, On, Under, Over).",
    'phonics': "Starting sounds and simple word stems.",
    'day_night': "Time of day, weekdays, and seasonal concepts.",
    'transport': "Vehicles and modes of travel (Air, Sea, Land).",
    'home_kids': "Rooms and household furniture identification.",
    'food_kids': "Healthy vs Treat food identification.",
    'nature': "Natural elements (Rainbow, Sun, River) identification.",
    'time': "Analog and digital clock reading basics.",
  };

  final List<String> _gameTypes = [
    'alphabet',
    'numbers',
    'colors',
    'shapes',
    'animals',
    'fruits',
    'family',
    'school',
    'verbs',
    'emotions',
    'routine',
    'opposites',
    'prepositions',
    'phonics',
    'day_night',
    'transport',
    'home_kids',
    'food_kids',
    'nature',
    'time',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _jsonController.addListener(_updateStats);
    _fetchFirestoreStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  void _updateStats() {
    try {
      if (_jsonController.text.trim().isEmpty) {
        setState(() {
          _detectedQuests = 0;
          _detectedLevels = 0;
        });
        return;
      }
      final List<dynamic> decoded = jsonDecode(_jsonController.text);
      final Set<int> levels = {};
      for (var item in decoded) {
        if (item is Map && item.containsKey('level')) {
          levels.add(item['level']);
        }
      }
      setState(() {
        _detectedQuests = decoded.length;
        _detectedLevels = levels.length;
      });
    } catch (_) {
      // Quietly fail for invalid JSON
    }
  }

  Future<void> _fetchFirestoreStats() async {
    final stats = await _uploadService.fetchGameStats(_selectedGameType);
    setState(() {
      _firestoreQuests = stats['questCount'] ?? 0;
      _firestoreLevels = stats['levelCount'] ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6366F1); // Elegant Indigo

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        toolbarHeight: 100.h,
        title: Column(
          children: [
            Text(
              'KIDS COMMAND',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                fontSize: 18.sp,
                color: primaryColor,
              ),
            ),
            Text(
              'FIRESTORE SEEDING ENGINE v2.0',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 10.sp,
                color: Colors.black26,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.black26,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'SEEDING', icon: Icon(Icons.bolt_rounded)),
            Tab(text: 'MAINTENANCE', icon: Icon(Icons.settings_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSeedingTab(primaryColor), _buildMaintenanceTab()],
      ),
      bottomNavigationBar: _buildStatusFooter(),
    );
  }

  Widget _buildSeedingTab(Color primaryColor) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          _buildConfigPanel(primaryColor),
          SizedBox(height: 20.h),
          _buildInputPanel(primaryColor),
          SizedBox(height: 24.h),
          _buildActionButton(primaryColor),
        ],
      ),
    );
  }

  Widget _buildConfigPanel(Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORY SELECTION',
            style: GoogleFonts.outfit(
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 12.h),
          DropdownButton<String>(
            value: _selectedGameType,
            isExpanded: true,
            underline: const SizedBox(),
            items: _gameTypes
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.toUpperCase(),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() => _selectedGameType = val!);
              _fetchFirestoreStats();
            },
          ),
          SizedBox(height: 15.h),
          _buildFirestoreStatus(primaryColor),
          SizedBox(height: 15.h),
          _buildPromptHelper(primaryColor),
        ],
      ),
    );
  }

  Widget _buildFirestoreStatus(Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FIRESTORE LIVE STATUS',
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey[400],
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '$_firestoreLevels Levels | $_firestoreQuests Quests Exist',
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _fetchFirestoreStats,
            icon: Icon(Icons.refresh_rounded, color: primaryColor),
            tooltip: 'Refresh Cloud Stats',
          ),
        ],
      ),
    );
  }

  Widget _buildPromptHelper(Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GENERATION FOCUS:',
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _gamePrompts[_selectedGameType] ?? "General education focus.",
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              color: Colors.blueGrey[800],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 12.h),
          TextButton.icon(
            onPressed: _copyPrompt,
            icon: Icon(Icons.copy_rounded, size: 16.sp),
            label: const Text('COPY GENERATION PROMPT'),
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel(Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'QUEST DATA (JSON ARRAY)',
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: 2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => _jsonController.clear(),
                child: Text(
                  'CLEAR',
                  style: TextStyle(color: Colors.red[300], fontSize: 10.sp),
                ),
              ),
              _buildStatsBadge(),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _jsonController,
            maxLines: 12,
            style: GoogleFonts.robotoMono(fontSize: 12.sp),
            decoration: InputDecoration(
              hintText: 'Paste quests JSON array here...',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        '$_detectedLevels Levels | $_detectedQuests Quests',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: Colors.green[700],
        ),
      ),
    );
  }

  Widget _buildActionButton(Color primaryColor) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _uploadData,
      icon: _isLoading
          ? SizedBox(
              width: 20.r,
              height: 20.r,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.cloud_upload_rounded),
      label: Text(
        'PUSH TO FIRESTORE',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 60.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        elevation: 10,
        shadowColor: Colors.green.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 60.r, color: Colors.orange),
            SizedBox(height: 16.h),
            Text(
              'DANGER ZONE',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 20.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'These actions are permanent and affect all students.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey),
            ),
            SizedBox(height: 32.h),
            _buildMaintenanceCard(
              title: 'Wipe Category Data',
              subtitle:
                  'Clear all quests for ${_selectedGameType.toUpperCase()}',
              icon: Icons.delete_sweep_rounded,
              color: Colors.red,
              onTap: _clearGame,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12.sp)),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
    );
  }

  Widget _buildStatusFooter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      color: Colors.white,
      child: Text(
        _status,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: _status.contains('failed') ? Colors.red : Colors.blueGrey[700],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _copyPrompt() {
    final focus = _gamePrompts[_selectedGameType];
    final fullPrompt =
        """
Generate 50 levels of JSON data for the category: $_selectedGameType.
Instruction Focus: $focus

Rules:
1. Each level should have 3-5 unique quest objects.
2. Levels 1-50 must increase gradually in difficulty.
3. Instruction must be simple for kids (3-7 years old).
4. Output MUST be a single raw JSON array of objects.
5. Use this JSON template:
{
  "id": "${_selectedGameType}_L[LEVEL]_[INDEX]",
  "gameType": "choice_multi",
  "level": [LEVEL],
  "instruction": "...",
  "question": "...",
  "options": ["...", "...", ...],
  "correctAnswer": "...",
  "imageUrl": "optional_prompt_or_url"
}
""";
    Clipboard.setData(ClipboardData(text: fullPrompt));
    setState(
      () => _status = 'Prompt for $_selectedGameType copied to clipboard! 📋',
    );
  }

  Future<void> _uploadData() async {
    if (_jsonController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _status = 'Pushing to Firestore... 🧪';
    });

    final result = await _uploadService.uploadKidsBatch(
      jsonInput: _jsonController.text,
      gameType: _selectedGameType,
    );

    setState(() {
      _isLoading = false;
      _status = result['message'];
      if (result['success']) {
        _jsonController.clear();
        _fetchFirestoreStats();
      }
    });
  }

  Future<void> _clearGame() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wipe Data?'),
        content: Text(
          'Delete ALL data for $_selectedGameType? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('WIPE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _status = 'Wiping engine... 🧹';
      });
      await _uploadService.deleteGameQuests(_selectedGameType);
      setState(() {
        _isLoading = false;
        _status = 'Curriculum for $_selectedGameType wiped. ✅';
      });
    }
  }
}

