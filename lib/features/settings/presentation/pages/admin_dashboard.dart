import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/utils/generation_strategies.dart';
import 'package:vowl/core/utils/quest_upload_service.dart';
import 'package:vowl/core/utils/game_content_generator.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _status = 'System Standing By...';
  final _uploadService = QuestUploadService();

  // Seeding State
  final TextEditingController _manualJsonController = TextEditingController();
  int _manualLevel = 1;
  QuestType _selectedSkill = QuestType.speaking;
  late GameSubtype _selectedGameType;

  // Verification State
  int _startLevel = 1;
  int _endLevel = 200;
  final List<String> _verificationLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedGameType = _selectedSkill.subtypes.first;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualJsonController.dispose();
    super.dispose();
  }

  // --- LOGIC METHODS ---

  Future<void> _saveManualQuest() async {
    if (_manualJsonController.text.isEmpty) {
      setState(() => _status = 'Error: JSON cannot be empty ❌');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Processing batch save... ⏳';
    });

    final result = await _uploadService.uploadBatch(
      jsonInput: _manualJsonController.text,
      skill: _selectedSkill,
      subtype: _selectedGameType,
    );

    if (!mounted) return;
    setState(() {
      _status = result['message'];
      if (result['success']) {
        _manualJsonController.clear();
        _manualLevel = (result['maxLevel'] as int) + 1;
      }
      _isLoading = false;
    });
  }

  void _loadTemplate() {
    final strategy = PromptStrategy().getSpecificInstructions(
      _selectedSkill,
      _selectedGameType,
    );
    String template = '[\n';
    for (int i = 1; i <= 3; i++) {
      template += '  {\n';
      template +=
          '    "id": "${_selectedGameType.name}_L${_manualLevel}_$i",\n';
      template += '    "instruction": "Level Item $i",\n';
      if (strategy.contains('"textToSpeak"')) {
        template += '    "textToSpeak": "Listen and repeat item $i",\n';
      }
      if (strategy.contains('"passage"')) {
        template += '    "passage": "Sample passage for level item $i",\n';
      }
      if (strategy.contains('"question"')) {
        template += '    "question": "Level Question $i?",\n';
      }
      if (strategy.contains('"options"')) {
        template += '    "options": ["A", "B", "C", "D"],\n';
        template += '    "correctAnswerIndex": 0,\n';
      }
      template += '    "difficulty": $_manualLevel,\n';
      template += '    "xpReward": 25,\n';
      template += '    "coinReward": 10,\n';
      template += '    "livesAllowed": 3\n';
      template += i == 3 ? '  }\n' : '  },\n';
    }
    template += ']';
    _manualJsonController.text = template;
    setState(
      () => _status = 'Template loaded for ${_selectedGameType.name} 📝',
    );
  }

  void _formatJson() {
    try {
      final obj = jsonDecode(_manualJsonController.text);
      _manualJsonController.text = const JsonEncoder.withIndent(
        '  ',
      ).convert(obj);
      setState(() => _status = 'JSON Formatted! ✨');
    } catch (e) {
      setState(() => _status = 'Error: Invalid JSON format: $e ❌');
    }
  }

  Future<void> _bulkSeedCurrentGame() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bulk Seed 30 Levels?'),
        content: Text(
          'This will generate and upload 90 questions (30 levels) for ${_selectedGameType.name}. Existing levels with same numbers will be merged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('PROCEED'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _status = 'Generating and seeding 30 levels... 🚀';
    });

    try {
      final quests = GameContentGenerator.generateLevels(
        subtype: _selectedGameType,
        category: _selectedSkill,
      );

      final jsonInput = jsonEncode(quests);

      final result = await _uploadService.uploadBatch(
        jsonInput: jsonInput,
        skill: _selectedSkill,
        subtype: _selectedGameType,
      );

      if (!mounted) return;
      setState(() {
        _status = result['message'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Bulk seed failed: $e ❌';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyLevels() async {
    setState(() {
      _isLoading = true;
      _status = 'Verifying integrity...';
      _verificationLogs.clear();
    });

    try {
      final firestore = FirebaseFirestore.instance;
      int ok = 0, fail = 0;
      for (int i = _startLevel; i <= _endLevel; i++) {
        final doc = await firestore
            .collection('quests')
            .doc(_selectedGameType.name)
            .collection('levels')
            .doc(i.toString())
            .get();
        if (doc.exists) {
          final quests = (doc.data()?['quests'] as List?)?.length ?? 0;
          _verificationLogs.add('Level $i: OK ($quests Quests) ✅');
          ok++;
        } else {
          _verificationLogs.add('Level $i: MISSING ❌');
          fail++;
        }
        if (i % 10 == 0) await Future.delayed(Duration.zero);
      }
      if (!mounted) return;
      setState(() => _status = 'Verification Finished: $ok OK, $fail Missing');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Verify Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _wipeCurriculum() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Danger: Full Reset?'),
        content: const Text(
          'Delete ALL new structure levels for the current game type?',
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
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await _uploadService.wipeSubtype(_selectedGameType);
      setState(
        () => _status = 'Curriculum for ${_selectedGameType.name} wiped. 🧹',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Wipe Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xFF38BDF8)
        : const Color(0xFF0284C7);

    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final bgColor = isMidnight 
        ? Colors.black 
        : (isDark ? const Color(0xFF0F172A) : Colors.grey[50]!);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        toolbarHeight: 80.h,
        title: Column(
          children: [
            Text(
              'Vowl COMMAND',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                fontSize: 18.sp,
                color: primaryColor,
              ),
            ),
            Text(
              '2026 CORE EDITION • MANUAL SEEDING',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 10.sp,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          indicatorWeight: 4,
          labelColor: primaryColor,
          unselectedLabelColor: isDark ? Colors.white30 : Colors.black26,
          labelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
          ),
          tabs: const [
            Tab(text: '🕹️ SEEDING', icon: Icon(Icons.edit_note_rounded)),
            Tab(text: '🔍 VERIFY', icon: Icon(Icons.verified_rounded)),
            Tab(
              text: '🛠️ MAINTENANCE',
              icon: Icon(Icons.settings_suggest_rounded),
            ),
          ],
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: (isDark ? Colors.black : Colors.white).withValues(
                alpha: 0.2,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSeedingTab(isDark, primaryColor),
                  _buildVerifyTab(isDark, primaryColor),
                  _buildMaintenanceTab(isDark),
                ],
              ),
            ),
            _buildStatusFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedingTab(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          _buildPanelContainer(
            color: primaryColor,
            isDark: isDark,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<QuestType>(
                        label: 'Skill',
                        value: _selectedSkill,
                        items: QuestType.values,
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _selectedSkill = v;
                              _selectedGameType = v.subtypes.first;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildDropdown<GameSubtype>(
                        label: 'Game Type',
                        value: _selectedGameType,
                        items: _selectedSkill.subtypes,
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedGameType = v);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildNumberInput(
                  label: 'Starting Level',
                  value: _manualLevel,
                  onChanged: (v) => setState(() => _manualLevel = v),
                ),
                SizedBox(height: 16.h),
                Stack(
                  children: [
                    TextField(
                      controller: _manualJsonController,
                      maxLines: 12,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12.sp,
                        color: isDark ? Colors.greenAccent : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Paste ChatGPT JSON Array Batch here...',
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.white70,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _buildJsonStatBadge(),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8.w,
                  children: [
                    TextButton.icon(
                      onPressed: _formatJson,
                      icon: const Icon(
                        Icons.format_align_left_rounded,
                        size: 16,
                      ),
                      label: const Text('FORMAT JSON'),
                    ),
                    TextButton.icon(
                      onPressed: _loadTemplate,
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('LOAD TEMPLATE'),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveManualQuest,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    'SAVE BATCH TO FIRESTORE',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _bulkSeedCurrentGame,
                  icon: const Icon(Icons.bolt_rounded, color: Colors.amber),
                  label: Text(
                    '⚡ BULK SEED 30 LEVELS',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.amber : Colors.orange[800],
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50.h),
                    side: BorderSide(
                      color: isDark ? Colors.amber[300]! : Colors.orange[800]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyTab(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          _buildPanelContainer(
            color: Colors.orange,
            isDark: isDark,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberInput(
                        label: 'Start Range',
                        value: _startLevel,
                        onChanged: (v) => setState(() => _startLevel = v),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildNumberInput(
                        label: 'End Range',
                        value: _endLevel,
                        onChanged: (v) => setState(() => _endLevel = v),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _verifyLevels,
                  icon: const Icon(Icons.verified_user_rounded),
                  label: const Text('VERIFY LEVEL INTEGRITY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50.h),
                  ),
                ),
              ],
            ),
          ),
          if (_verificationLogs.isNotEmpty) ...[
            SizedBox(height: 24.h),
            Container(
              height: 400.h,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _verificationLogs.length,
                itemBuilder: (c, i) => Text(
                  _verificationLogs[i],
                  style: GoogleFonts.robotoMono(
                    color: _verificationLogs[i].contains('✅')
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          _buildMaintenanceCard(
            title: 'Export JSON',
            subtitle: 'Export current game curriculum to logs.',
            icon: Icons.download_rounded,
            color: Colors.blue,
            onTap: _exportAll,
          ),
          SizedBox(height: 12.h),
          _buildMaintenanceCard(
            title: 'Clear Legacy',
            subtitle: 'Remove old _quests collections.',
            icon: Icons.delete_sweep_rounded,
            color: Colors.orange,
            onTap: _clearLegacyData,
          ),
          SizedBox(height: 12.h),
          _buildMaintenanceCard(
            title: 'Kids Zone Admin',
            subtitle: 'Manage kids games levels and quests.',
            icon: Icons.child_care_rounded,
            color: Colors.purple,
            onTap: () => context.push(AppRouter.kidsAdminRoute),
          ),
          SizedBox(height: 12.h),
          _buildMaintenanceCard(
            title: 'Wipe Current Game',
            subtitle: 'Delete ALL levels for current selection.',
            icon: Icons.dangerous_rounded,
            color: Colors.red,
            onTap: _wipeCurriculum,
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
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
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12.sp)),
      tileColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white10
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
    );
  }

  Widget _buildStatusFooter(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.black45 : Colors.white70,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          _isLoading
              ? SizedBox(
                  width: 14.w,
                  height: 14.w,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.circle,
                  size: 10,
                  color: _status.contains('Error')
                      ? Colors.red
                      : Colors.greenAccent,
                ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _status,
              style: GoogleFonts.outfit(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelContainer({
    required Widget child,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
      ),
      child: child,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        DropdownButton<T>(
          value: value,
          isExpanded: true,
          underline: SizedBox(),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e.toString().split('.').last,
                    style: GoogleFonts.outfit(fontSize: 14.sp),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _exportAll() async {
    setState(() {
      _isLoading = true;
      _status = 'Exporting data for ${_selectedGameType.name}...';
      _verificationLogs.clear();
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quests')
          .doc(_selectedGameType.name)
          .collection('levels')
          .get();

      final Map<String, dynamic> exportData = {};
      for (var doc in snapshot.docs) {
        exportData[doc.id] = doc.data();
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      debugPrint(
        '--- JSON EXPORT [${_selectedGameType.name}] ---\n$jsonString',
      );

      _verificationLogs.add(
        'Exported ${snapshot.docs.length} levels to Debug Console. ✅',
      );
      if (!mounted) return;
      setState(() => _status = 'Export Complete! Check debug logs. 📂');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Export Error: $e ❌');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearLegacyData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cleanup Legacy?'),
        content: const Text(
          'This will delete all documents in "speaking_quests", "reading_quests", etc. This is permanent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'PROCEED',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _status = 'Deleting legacy collections...';
    });

    final legacy = [
      'speaking_quests',
      'reading_quests',
      'writing_quests',
      'grammar_quests',
      'listening_quests',
      'accent_quests',
      'roleplay_quests',
    ];

    try {
      final firestore = FirebaseFirestore.instance;
      for (var coll in legacy) {
        final docs = await firestore.collection(coll).get();
        if (docs.docs.isEmpty) {
          continue;
        }

        final batch = firestore.batch();
        for (var doc in docs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        _verificationLogs.add('Deleted legacy: $coll ✅');
      }
      setState(() => _status = 'Legacy Cleanup Successful! 🧹');
    } catch (e) {
      setState(() => _status = 'Cleanup Error: $e ❌');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- UI COMPONENTS ---

  Widget _buildNumberInput({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8.h),
          ),
          style: GoogleFonts.outfit(fontSize: 14.sp),
          // Using a key to prevent controller recreation issues while typing
          key: ValueKey('input_${label}_$value'),
          controller: TextEditingController(text: value.toString())
            ..selection = TextSelection.collapsed(
              offset: value.toString().length,
            ),
          onSubmitted: (v) {
            final parsed = int.tryParse(v);
            if (parsed != null) {
              onChanged(parsed);
            }
          },
          onChanged: (v) {
            final parsed = int.tryParse(v);
            if (parsed != null) {
              onChanged(parsed);
            }
          },
        ),
      ],
    );
  }

  Widget _buildJsonStatBadge() {
    if (_manualJsonController.text.isEmpty) {
      return const SizedBox.shrink();
    }
    try {
      final list = jsonDecode(_manualJsonController.text) as List;
      final levels = list.map((e) => (e as Map)['difficulty']).toSet().length;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.blue[700],
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          '$levels Levels Detected (${list.length} Items)',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } catch (_) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.red[700],
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          'INVALID JSON',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}
