const fs = require('fs');

let p1 = 'lib/features/grammar/pronoun_resolution/presentation/pages/pronoun_resolution_screen.dart';
let c1 = fs.readFileSync(p1, 'utf8');
c1 = c1.replace(/Widget _buildGravityWell\([\s\S]*?bool hasSecondStage,\s*\)/, `Widget _buildGravityWell(
    List<String> options,
    int correctIndex,
    String pronoun,
    Color primaryColor,
    bool isDark,
    bool isCompact,
    bool hasSecondStage,
    GameQuest quest,
  )`);
c1 = c1.replace(/_buildGravityWell\(\s*options,\s*quest\.correctAnswerIndex \?\? 0,\s*quest\.targetWord \?\? "it",\s*theme\.primaryColor,\s*isDark,\s*true,\s*true,\s*\)/g, '_buildGravityWell(options, quest.correctAnswerIndex ?? 0, quest.targetWord ?? "it", theme.primaryColor, isDark, true, true, quest)');
c1 = c1.replace(/_buildGravityWell\(\s*options,\s*quest\.correctAnswerIndex \?\? 0,\s*quest\.targetWord \?\? "it",\s*theme\.primaryColor,\s*isDark,\s*false,\s*true,\s*\)/g, '_buildGravityWell(options, quest.correctAnswerIndex ?? 0, quest.targetWord ?? "it", theme.primaryColor, isDark, false, true, quest)');
c1 = c1.replace(/_onFire\(i, correctIndex, hasSecondStage, currentQuestOrNull!\);/g, '_onFire(i, correctIndex, hasSecondStage, quest);');
c1 = c1.replace(/_onFire\(_activeShardIndex\.value!, context, true, currentQuestOrNull!\);/g, '_onFire(_activeShardIndex.value!, context, true, quest);');
fs.writeFileSync(p1, c1);
