/**
 * migrate_dialogs.js
 * 
 * Migrates all game screens from inline _showCompletionDialog / _showGameOverDialog
 * to the shared GameDialogHelper utility.
 * 
 * Usage: node scripts/migrate_dialogs.js
 */

const fs = require('fs');
const path = require('path');

const FEATURES_DIR = path.join(__dirname, '..', 'lib', 'features');
const HELPER_IMPORT = "import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';";

// Files to skip (already migrated)
const SKIP_FILES = [
  'minimal_pairs_screen.dart',
];

let totalFiles = 0;
let migratedFiles = 0;
let skippedFiles = 0;
let errorFiles = [];

function findDartFiles(dir) {
  const results = [];
  const items = fs.readdirSync(dir, { withFileTypes: true });
  for (const item of items) {
    const fullPath = path.join(dir, item.name);
    if (item.isDirectory()) {
      results.push(...findDartFiles(fullPath));
    } else if (item.name.endsWith('_screen.dart')) {
      results.push(fullPath);
    }
  }
  return results;
}

function extractStringLiteral(content, prefix) {
  // Match: prefix: 'value' or prefix: "value"
  const regex = new RegExp(prefix + `\\s*:\\s*['"]([^'"]+)['"]`);
  const m = content.match(regex);
  return m ? m[1] : null;
}

function extractDescriptionLiteral(content) {
  // Match description that may span multiple lines and contain $xp, $coins interpolation
  // Pattern 1: description: 'text $xp text $coins text'
  // Pattern 2: description:\n          'text'
  const regex = /description\s*:\s*\n?\s*['"](.+?)['"]\s*,/s;
  const m = content.match(regex);
  if (m) return m[1];
  
  // Try multi-line
  const regex2 = /description\s*:\s*\n?\s*['"](.+?)['"]/s;
  const m2 = content.match(regex2);
  return m2 ? m2[1] : null;
}

function extractBlocType(content) {
  // Find the BLoC type used for RestoreLife
  const m = content.match(/context\.read<(\w+Bloc)>\(\)\.add\(RestoreLife\(\)\)/);
  return m ? m[1] : null;
}

function extractMethodBody(content, methodName) {
  // Find the method start
  const startPattern = new RegExp(`void ${methodName}\\(`);
  const startMatch = startPattern.exec(content);
  if (!startMatch) return null;

  const startIdx = startMatch.index;
  
  // Find matching closing brace by counting braces
  let braceCount = 0;
  let foundFirst = false;
  let endIdx = startIdx;
  
  for (let i = startIdx; i < content.length; i++) {
    if (content[i] === '{') {
      braceCount++;
      foundFirst = true;
    } else if (content[i] === '}') {
      braceCount--;
      if (foundFirst && braceCount === 0) {
        endIdx = i + 1;
        break;
      }
    }
  }
  
  return {
    start: startIdx,
    end: endIdx,
    body: content.substring(startIdx, endIdx),
  };
}

function migrateFile(filePath) {
  const fileName = path.basename(filePath);
  if (SKIP_FILES.includes(fileName)) {
    skippedFiles++;
    return;
  }
  
  let content = fs.readFileSync(filePath, 'utf8');
  
  // Check if file has the dialog methods
  if (!content.includes('_showCompletionDialog') && !content.includes('_showGameOverDialog')) {
    return;
  }
  
  totalFiles++;
  
  // Extract completion dialog info
  const completionMethod = extractMethodBody(content, '_showCompletionDialog');
  let completionTitle = null, completionDesc = null, completionButton = null;
  let hasDoubleUp = false;
  
  if (completionMethod) {
    completionTitle = extractStringLiteral(completionMethod.body, 'title');
    completionDesc = extractDescriptionLiteral(completionMethod.body);
    completionButton = extractStringLiteral(completionMethod.body, 'buttonText');
    hasDoubleUp = completionMethod.body.includes('onAdAction') || completionMethod.body.includes('DoubleUp');
  }
  
  // Extract game over dialog info
  const gameOverMethod = extractMethodBody(content, '_showGameOverDialog');
  let gameOverTitle = null, gameOverDesc = null, gameOverButton = null;
  let hasRescue = false;
  let blocType = null;
  
  if (gameOverMethod) {
    gameOverTitle = extractStringLiteral(gameOverMethod.body, 'title');
    gameOverDesc = extractDescriptionLiteral(gameOverMethod.body);
    gameOverButton = extractStringLiteral(gameOverMethod.body, 'buttonText');
    hasRescue = gameOverMethod.body.includes('RestoreLife') || 
                gameOverMethod.body.includes('isRescueLife: true');
    blocType = extractBlocType(gameOverMethod.body);
  }
  
  // Skip files with complex double-up ad patterns (need manual review)
  if (hasDoubleUp) {
    console.log(`  ⚠️  SKIP (has double-up ad): ${fileName}`);
    console.log(`     Completion: title="${completionTitle}"`);
    skippedFiles++;
    return;
  }

  // Skip if we couldn't extract needed data
  if (completionMethod && !completionTitle) {
    console.log(`  ⚠️  SKIP (couldn't parse completion): ${fileName}`);
    skippedFiles++;
    return;
  }
  if (gameOverMethod && !gameOverTitle) {
    console.log(`  ⚠️  SKIP (couldn't parse game over): ${fileName}`);
    skippedFiles++;
    return;
  }

  try {
    // 1. Add game_dialog_helper import (if not present)
    if (!content.includes('game_dialog_helper.dart')) {
      // Insert after the last core import or before first feature import
      if (content.includes("import 'package:voxai_quest/core/presentation/widgets/modern_game_dialog.dart';")) {
        content = content.replace(
          "import 'package:voxai_quest/core/presentation/widgets/modern_game_dialog.dart';",
          `${HELPER_IMPORT}`
        );
      } else {
        // Add before the first feature import
        const insertPoint = content.indexOf("import 'package:voxai_quest/features/");
        if (insertPoint > 0) {
          content = content.substring(0, insertPoint) + HELPER_IMPORT + '\n' + content.substring(insertPoint);
        }
      }
    }
    
    // 2. Replace _showCompletionDialog call in BLoC listener
    if (completionMethod) {
      // Build description string with proper interpolation
      let descStr = completionDesc || `You earned \${state.xpEarned} XP and \${state.coinsEarned} Coins!`;
      // Convert $xp/$coins to state.xpEarned/state.coinsEarned
      descStr = descStr.replace(/\$xp/g, '${state.xpEarned}');
      descStr = descStr.replace(/\$coins/g, '${state.coinsEarned}');
      
      // Replace the call site
      // Pattern: _showCompletionDialog(context, state.xpEarned, state.coinsEarned)
      // or: _showCompletionDialog(\n              context, state.xpEarned, state.coinsEarned)
      const callRegex = /_showCompletionDialog\(\s*\n?\s*context,\s*state\.xpEarned,\s*state\.coinsEarned\s*,?\s*\)/g;
      
      const replacementCall = `GameDialogHelper.showCompletion(\n          context,\n          xp: state.xpEarned,\n          coins: state.coinsEarned,\n          title: '${completionTitle}',\n          description:\n              '${descStr}',\n        )`;
      content = content.replace(callRegex, replacementCall);
    }
    
    // 3. Replace _showGameOverDialog call in BLoC listener
    if (gameOverMethod) {
      const gameOverCall = hasRescue && blocType
        ? `GameDialogHelper.showGameOver(\n        context,\n        title: '${gameOverTitle}',\n        description: '${gameOverDesc}',\n        onRestore: () => context.read<${blocType}>().add(RestoreLife()),\n      )`
        : `GameDialogHelper.showGameOver(\n        context,\n        title: '${gameOverTitle}',\n        description: '${gameOverDesc}',\n      )`;
      
      content = content.replace(
        /_showGameOverDialog\(context\)\s*;/g,
        gameOverCall + ';'
      );
    }
    
    // 4. Remove the dialog method bodies
    // We need to re-extract positions after content changes
    const updatedCompletion = extractMethodBody(content, '_showCompletionDialog');
    if (updatedCompletion) {
      // Also remove any comment/whitespace before the method
      let removeStart = updatedCompletion.start;
      // Check for preceding comment line
      const before = content.substring(Math.max(0, removeStart - 200), removeStart);
      const commentMatch = before.match(/\n(\s*\/\/[^\n]*\n\s*\n?)\s*$/);
      if (commentMatch) {
        removeStart -= commentMatch[1].length;
      }
      content = content.substring(0, removeStart) + content.substring(updatedCompletion.end);
    }
    
    const updatedGameOver = extractMethodBody(content, '_showGameOverDialog');
    if (updatedGameOver) {
      let removeStart = updatedGameOver.start;
      const before = content.substring(Math.max(0, removeStart - 200), removeStart);
      const commentMatch = before.match(/\n(\s*\/\/[^\n]*\n\s*\n?)\s*$/);
      if (commentMatch) {
        removeStart -= commentMatch[1].length;
      }
      content = content.substring(0, removeStart) + content.substring(updatedGameOver.end);
    }
    
    // 5. Clean up now-unused imports
    // Only remove modern_game_dialog import if no other reference exists
    if (!content.includes('ModernGameDialog') && content.includes("modern_game_dialog.dart")) {
      content = content.replace(/import 'package:voxai_quest\/core\/presentation\/widgets\/modern_game_dialog\.dart';\r?\n/g, '');
    }
    
    // Remove ad_service import if no other reference
    if (!content.includes('AdService') && !content.includes('adService') && !content.includes('ad_service')) {
      // Don't remove - other parts might use it (showInterstitialAd)
    }
    
    // Clean up multiple consecutive blank lines
    content = content.replace(/\n{4,}/g, '\n\n');
    
    fs.writeFileSync(filePath, content, 'utf8');
    migratedFiles++;
    console.log(`  ✅ ${fileName} — title: "${completionTitle}" / "${gameOverTitle}"`);
    
  } catch (err) {
    console.log(`  ❌ ERROR: ${fileName} — ${err.message}`);
    errorFiles.push(fileName);
  }
}

// Main
console.log('\n🔄 Migrating game screens to GameDialogHelper...\n');

const files = findDartFiles(FEATURES_DIR);
const screenFiles = files.filter(f => {
  const content = fs.readFileSync(f, 'utf8');
  return content.includes('_showCompletionDialog') || content.includes('_showGameOverDialog');
});

console.log(`Found ${screenFiles.length} files with dialog methods.\n`);

for (const file of screenFiles) {
  migrateFile(file);
}

console.log(`\n${'═'.repeat(60)}`);
console.log(`✅ Migrated: ${migratedFiles}`);
console.log(`⚠️  Skipped:  ${skippedFiles}`);
console.log(`❌ Errors:   ${errorFiles.length}`);
if (errorFiles.length > 0) {
  console.log(`   ${errorFiles.join(', ')}`);
}
console.log(`${'═'.repeat(60)}\n`);
