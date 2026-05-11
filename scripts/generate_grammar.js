/**
 * Grammar Curriculum Generator
 * Generates unique questions for all 10 grammar games × 200 levels × 3 questions per level.
 * Run: node scripts/generate_grammar.js
 */
const fs = require('fs');
const path = require('path');
const pools = require('./grammar_pools');

const OUTPUT_DIR = path.join(__dirname, '..', 'assets', 'curriculum', 'grammar');
const TOTAL_LEVELS = 200;
const QUESTIONS_PER_LEVEL = 3;
const BATCH_SIZE = 10;

const GAME_TYPES = [
  'grammarQuest', 'sentenceCorrection', 'wordReorder', 'tenseMastery',
  'partsOfSpeech', 'subjectVerbAgreement', 'clauseConnector', 'voiceSwap',
  'questionFormatter', 'articleInsertion', 'modifierPlacement', 'conditionals',
  'directIndirectSpeech', 'pronounResolution', 'punctuationMastery',
  'modalsSelection', 'prepositionChoice', 'relativeClauses', 'conjunctions',
];

const PREFIXES = {
  grammarQuest: 'gq', sentenceCorrection: 'sc', wordReorder: 'wr', tenseMastery: 'tm',
  partsOfSpeech: 'pos', subjectVerbAgreement: 'sva', clauseConnector: 'cc', voiceSwap: 'vs',
  questionFormatter: 'qf', articleInsertion: 'ai', modifierPlacement: 'mp', conditionals: 'cl',
  directIndirectSpeech: 'dis', pronounResolution: 'pr', punctuationMastery: 'pm',
  modalsSelection: 'ms', prepositionChoice: 'pc', relativeClauses: 'rc', conjunctions: 'cj',
};

const VISUALS = [
  { painter: 'NeuralNegotiationSync', color: '0xFF00FFCC', effect: 'glow_shimmer' },
  { painter: 'DataLogSync', color: '0xFF03A9F4', effect: 'terminal_flicker' },
  { painter: 'ArchiveDecryptSync', color: '0xFF9E9E9E', effect: 'mist_drift' },
  { painter: 'CouncilHallSync', color: '0xFFFFFFFF', effect: 'binary_pulse' },
  { painter: 'PurgeGridSync', color: '0xFFF44336', effect: 'void_ripple' },
  { painter: 'NeuralNegotiationSync', color: '0xFF00FFCC', effect: 'brain_bloom' },
  { painter: 'CouncilHallSync', color: '0xFFFFFFFF', effect: 'signal_ghosting' },
  { painter: 'PurgeGridSync', color: '0xFFF44336', effect: 'matrix_scan' },
  { painter: 'NeuralNegotiationSync', color: '0xFFFFD700', effect: 'victory_sweep' },
];

function getDifficulty(level) {
  if (level <= 40) return 1;
  if (level <= 80) return 2;
  if (level <= 120) return 3;
  if (level <= 160) return 4;
  return 5;
}

function generateForGame(gameType) {
  const pool = pools[gameType];
  if (!pool || pool.length === 0) {
    console.error(`No pool for ${gameType}`);
    return;
  }

  const prefix = PREFIXES[gameType] || gameType;
  const totalNeeded = TOTAL_LEVELS * QUESTIONS_PER_LEVEL;
  console.log(`  ${gameType}: pool=${pool.length}, need=${totalNeeded}`);

  for (let batch = 0; batch < TOTAL_LEVELS / BATCH_SIZE; batch++) {
    const startLevel = batch * BATCH_SIZE + 1;
    const endLevel = (batch + 1) * BATCH_SIZE;
    const fileName = `${gameType}_${startLevel}_${endLevel}.json`;
    const filePath = path.join(OUTPUT_DIR, fileName);

    // Skip if already exists and complete (optional, but let's overwrite to ensure standard)
    const quests = [];

    for (let level = startLevel; level <= endLevel; level++) {
      const diff = getDifficulty(level);
      for (let q = 1; q <= QUESTIONS_PER_LEVEL; q++) {
        const globalIndex = ((level - 1) * QUESTIONS_PER_LEVEL + (q - 1)) % pool.length;
        const template = pool[globalIndex];
        const visual = VISUALS[((level - 1) * QUESTIONS_PER_LEVEL + (q - 1)) % VISUALS.length];
        
        const quest = {
          id: `${prefix}_l${level}_q${q}`,
          instruction: template.instruction,
          difficulty: diff,
          subtype: gameType,
          interactionType: template.interactionType || 'choice',
          ...template.fields,
          xpReward: level,
          coinReward: level * 2,
          visual_config: {
            painter_type: visual.painter,
            primary_color: visual.color,
            pulse_intensity: 0.5 + (q * 0.1),
            shader_effect: visual.effect,
          }
        };
        quests.push(quest);
      }
    }

    const fileData = {
      gameType,
      batchIndex: batch + 1,
      levels: `${startLevel}-${endLevel}`,
      quests,
    };

    fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  }
}

console.log('Generating grammar curriculum...');
if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });

for (const gameType of GAME_TYPES) {
  generateForGame(gameType);
}

// Verify
let totalFiles = 0;
const allFiles = fs.readdirSync(OUTPUT_DIR);
for (const gameType of GAME_TYPES) {
  const files = allFiles.filter(f => f.startsWith(gameType + '_'));
  totalFiles += files.length;
  console.log(`  ${gameType}: ${files.length} files`);
}
console.log(`Done! Total files: ${totalFiles}`);
