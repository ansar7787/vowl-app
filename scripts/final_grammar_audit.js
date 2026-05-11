const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/grammar';
const files = fs.readdirSync(basePath).filter(f => f.endsWith('.json'));

console.log(`Found ${files.length} JSON files in grammar curriculum.`);

const games = [
  'articleInsertion', 'clauseConnector', 'conditionals', 'conjunctions',
  'directIndirectSpeech', 'grammarQuest', 'modalsSelection', 'modifierPlacement',
  'partsOfSpeech', 'prepositionChoice', 'pronounResolution', 'punctuationMastery',
  'questionFormatter', 'relativeClauses', 'sentenceCorrection', 'subjectVerbAgreement',
  'tenseMastery', 'voiceSwap', 'wordReorder'
];

let totalQuests = 0;
let globalIds = new Set();
let duplicateIds = [];

const gameStats = {};
for (const g of games) {
  gameStats[g] = {
    files: 0,
    quests: 0,
    uniqueContent: new Set(),
    duplicateContentInGame: 0
  };
}

for (const f of files) {
  const filePath = path.join(basePath, f);
  let data;
  try {
    data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (e) { continue; }

  const gType = data.gameType;
  if (!gameStats[gType]) continue;
  gameStats[gType].files++;

  for (const q of data.quests) {
    gameStats[gType].quests++;
    totalQuests++;

    if (q.id) {
      if (globalIds.has(q.id)) duplicateIds.push(q.id);
      globalIds.add(q.id);
    }

    // Uniqueness Key: Question + Correct Answer + Options + Sentence
    let correctText = "";
    if (q.interactionType === 'choice' && q.options && q.correctAnswerIndex !== undefined) {
        correctText = q.options[q.correctAnswerIndex];
    } else if (q.correctAnswer) {
        correctText = q.correctAnswer;
    }
    
    let key = `${q.question || ''}|${q.sentence || ''}|${q.sentenceWithBlank || ''}|${q.targetWord || ''}|${q.correctAnswerIndex ?? ''}|${(q.shuffledWords || []).join(',')}|${correctText}|${(q.options || []).join(',')}`;
    key = key.trim().toLowerCase();

    if (gameStats[gType].uniqueContent.has(key)) {
      gameStats[gType].duplicateContentInGame++;
    }
    gameStats[gType].uniqueContent.add(key);
  }
}

console.log(`\n--- GLOBAL AUDIT RESULTS ---`);
console.log(`Total Quests: ${totalQuests}`);
console.log(`Duplicate IDs: ${duplicateIds.length}`);

console.log(`\n--- GAME MODULE BREAKDOWN ---`);
for (const g of games) {
  const stats = gameStats[g];
  const issues = [];
  if (stats.files !== 20) issues.push(`${stats.files}/20 files`);
  if (stats.quests !== 600) issues.push(`${stats.quests}/600 quests`);
  if (stats.uniqueContent.size !== 600) issues.push(`${stats.uniqueContent.size}/600 unique`);

  const status = issues.length === 0 ? "✅ PERFECT" : "❌ ISSUES: " + issues.join(', ');
  console.log(`${g.padEnd(22)} | ${status}`);
}
