/**
 * migrate_dialogs_v2.js
 * 
 * Handles the remaining 6 files with double-up ad completion patterns.
 * 
 * Usage: node scripts/migrate_dialogs_v2.js
 */

const fs = require('fs');
const path = require('path');

const FEATURES_DIR = path.join(__dirname, '..', 'lib', 'features');
const HELPER_IMPORT = "import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';";

let migratedFiles = 0;
let errorFiles = [];

function findDartFiles(dir) {
  const results = [];
  try {
    const items = fs.readdirSync(dir, { withFileTypes: true });
    for (const item of items) {
      const fullPath = path.join(dir, item.name);
      if (item.isDirectory()) {
        results.push(...findDartFiles(fullPath));
      } else if (item.name.endsWith('_screen.dart')) {
        results.push(fullPath);
      }
    }
  } catch (e) {}
  return results;
}

function extractStringLiteral(content, prefix) {
  const regex = new RegExp(prefix + `\\s*:\\s*\\n?\\s*['"]([^'"]+)['"]`);
  const m = content.match(regex);
  return m ? m[1] : null;
}

function extractMethodBody(content, methodName) {
  const startPattern = new RegExp(`\\s*void ${methodName}\\(`);
  const startMatch = startPattern.exec(content);
  if (!startMatch) return null;

  const startIdx = startMatch.index;
  let braceCount = 0;
  let foundFirst = false;
  let endIdx = startIdx;
  
  for (let i = startIdx; i < content.length; i++) {
    if (content[i] === '{') { braceCount++; foundFirst = true; }
    else if (content[i] === '}') {
      braceCount--;
      if (foundFirst && braceCount === 0) { endIdx = i + 1; break; }
    }
  }
  
  return { start: startIdx, end: endIdx, body: content.substring(startIdx, endIdx) };
}

function extractBlocType(content) {
  const m = content.match(/context\.read<(\w+Bloc)>\(\)\.add\(RestoreLife\(\)\)/);
  return m ? m[1] : null;
}

function migrateFile(filePath) {
  const fileName = path.basename(filePath);
  let content = fs.readFileSync(filePath, 'utf8');
  
  // Only process files that still use ModernGameDialog and don't use GameDialogHelper
  if (!content.includes('ModernGameDialog') || content.includes('GameDialogHelper')) return;
  if (!content.includes('_showCompletionDialog') && !content.includes('_showGameOverDialog')) return;
  
  const completionMethod = extractMethodBody(content, '_showCompletionDialog');
  const gameOverMethod = extractMethodBody(content, '_showGameOverDialog');
  
  if (!completionMethod && !gameOverMethod) return;
  
  try {
    // Extract completion dialog info
    let completionTitle = null, completionDesc = null, completionButton = null;
    let hasDoubleUp = false;
    
    if (completionMethod) {
      completionTitle = extractStringLiteral(completionMethod.body, 'title');
      completionDesc = extractStringLiteral(completionMethod.body, 'description');
      completionButton = extractStringLiteral(completionMethod.body, 'buttonText');
      hasDoubleUp = completionMethod.body.includes('onAdAction') || completionMethod.body.includes('DoubleUp');
    }
    
    // Extract game over dialog info
    let gameOverTitle = null, gameOverDesc = null, gameOverButton = null;
    let hasRescue = false, blocType = null;
    
    if (gameOverMethod) {
      gameOverTitle = extractStringLiteral(gameOverMethod.body, 'title');
      gameOverDesc = extractStringLiteral(gameOverMethod.body, 'description');
      gameOverButton = extractStringLiteral(gameOverMethod.body, 'buttonText');
      hasRescue = gameOverMethod.body.includes('RestoreLife') || gameOverMethod.body.includes('isRescueLife: true');
      blocType = extractBlocType(gameOverMethod.body);
    }
    
    // 1. Add game_dialog_helper import, replace modern_game_dialog
    if (!content.includes('game_dialog_helper.dart')) {
      if (content.includes("import 'package:voxai_quest/core/presentation/widgets/modern_game_dialog.dart';")) {
        content = content.replace(
          "import 'package:voxai_quest/core/presentation/widgets/modern_game_dialog.dart';",
          HELPER_IMPORT
        );
      } else {
        const insertPoint = content.indexOf("import 'package:voxai_quest/features/");
        if (insertPoint > 0) {
          content = content.substring(0, insertPoint) + HELPER_IMPORT + '\n' + content.substring(insertPoint);
        }
      }
    }
    
    // 2. Replace completion dialog call
    if (completionMethod && completionTitle) {
      let descStr = completionDesc || `You earned \${state.xpEarned} XP and \${state.coinsEarned} Coins!`;
      descStr = descStr.replace(/\$xp/g, '${state.xpEarned}').replace(/\$coins/g, '${state.coinsEarned}');
      
      const enableDoubleUpStr = hasDoubleUp ? '\n          enableDoubleUp: true,' : '';
      const popResultStr = completionMethod.body.includes('context.pop(true)') ? "\n          popResult: true," : '';
      
      const callRegex = /_showCompletionDialog\(\s*\n?\s*context,\s*state\.xpEarned,\s*state\.coinsEarned\s*,?\s*\)/g;
      const replacementCall = `GameDialogHelper.showCompletion(\n          context,\n          xp: state.xpEarned,\n          coins: state.coinsEarned,\n          title: '${completionTitle}',\n          description:\n              '${descStr}',${enableDoubleUpStr}${popResultStr}\n        )`;
      content = content.replace(callRegex, replacementCall);
    }
    
    // 3. Replace game over call
    if (gameOverMethod && gameOverTitle) {
      const gameOverCall = hasRescue && blocType
        ? `GameDialogHelper.showGameOver(\n        context,\n        title: '${gameOverTitle}',\n        description: '${gameOverDesc}',\n        onRestore: () => context.read<${blocType}>().add(RestoreLife()),\n      )`
        : `GameDialogHelper.showGameOver(\n        context,\n        title: '${gameOverTitle}',\n        description: '${gameOverDesc}',\n      )`;
      
      content = content.replace(/_showGameOverDialog\(context\)\s*;/g, gameOverCall + ';');
    }
    
    // 4. Remove old method bodies (re-extract after content changes)
    const updatedCompletion = extractMethodBody(content, '_showCompletionDialog');
    if (updatedCompletion) {
      content = content.substring(0, updatedCompletion.start) + content.substring(updatedCompletion.end);
    }
    const updatedGameOver = extractMethodBody(content, '_showGameOverDialog');
    if (updatedGameOver) {
      content = content.substring(0, updatedGameOver.start) + content.substring(updatedGameOver.end);
    }
    
    // 5. Remove ModernGameDialog import if no longer needed
    if (!content.includes('ModernGameDialog')) {
      content = content.replace(/import 'package:voxai_quest\/core\/presentation\/widgets\/modern_game_dialog\.dart';\r?\n/g, '');
    }
    
    // Clean up excessive blank lines
    content = content.replace(/\n{4,}/g, '\n\n');
    
    fs.writeFileSync(filePath, content, 'utf8');
    migratedFiles++;
    console.log(`  ✅ ${fileName} — "${completionTitle}" (doubleUp: ${hasDoubleUp})`);
    
  } catch (err) {
    console.log(`  ❌ ${fileName} — ${err.message}`);
    errorFiles.push(fileName);
  }
}

// Main
console.log('\n🔄 Migrating remaining files (v2 — with double-up support)...\n');

const files = findDartFiles(FEATURES_DIR);
for (const file of files) {
  migrateFile(file);
}

console.log(`\n${'═'.repeat(60)}`);
console.log(`✅ Migrated: ${migratedFiles}`);
console.log(`❌ Errors:   ${errorFiles.length}`);
if (errorFiles.length > 0) console.log(`   ${errorFiles.join(', ')}`);
console.log(`${'═'.repeat(60)}\n`);
