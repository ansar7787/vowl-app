/**
 * Accent Curriculum Generator (Unified)
 * Generates unique questions for all 12 accent games × 200 levels × 3 questions per level.
 */
const fs = require('fs');
const path = require('path');
const pools = require('./accent_pools');

const OUTPUT_DIR = path.join(__dirname, '..', 'assets', 'curriculum', 'accent');
const TOTAL_LEVELS = 200;
const QUESTIONS_PER_LEVEL = 3;
const BATCH_SIZE = 10;

const GAME_TYPES = [
  'minimalPairs', 'intonationMimic', 'syllableStress', 'wordLinking',
  'shadowingChallenge', 'vowelDistinction', 'consonantClarity', 'pitchPatternMatch',
  'speedVariance', 'dialectDrill', 'pitchModulation', 'connectedSpeech'
];

const PREFIXES = {
  minimalPairs: 'mp', intonationMimic: 'im', syllableStress: 'ss', wordLinking: 'wl',
  shadowingChallenge: 'sc', vowelDistinction: 'vd', consonantClarity: 'cc', pitchPatternMatch: 'ppm',
  speedVariance: 'sv', dialectDrill: 'dd', pitchModulation: 'pm', connectedSpeech: 'cs'
};

const VISUALS = [
  { painter: 'VocalResonanceSync', color: '0xFF00FFCC', effect: 'audio_wave_ripple' },
  { painter: 'EchoChamberSync', color: '0xFF03A9F4', effect: 'plasma_drift' },
  { painter: 'NeuralNegotiationSync', color: '0xFF9E9E9E', effect: 'brain_bloom' },
  { painter: 'SanctumFlowSync', color: '0xFFFFFFFF', effect: 'glitch_jitter' },
  { painter: 'VoidStasisSync', color: '0xFFF44336', effect: 'signal_ghosting' },
  { painter: 'ZenithBufferSync', color: '0xFFFFEB3B', effect: 'data_cascade' },
  { painter: 'ArchiveDecryptSync', color: '0xFF9C27B0', effect: 'mist_drift' },
  { painter: 'CouncilHallSync', color: '0xFF00BCD4', effect: 'binary_pulse' },
  { painter: 'PurgeGridSync', color: '0xFFFF9800', effect: 'matrix_scan' },
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

  for (let batch = 0; batch < TOTAL_LEVELS / BATCH_SIZE; batch++) {
    const startLevel = batch * BATCH_SIZE + 1;
    const endLevel = (batch + 1) * BATCH_SIZE;
    const fileName = `${gameType}_${startLevel}_${endLevel}.json`;
    const filePath = path.join(OUTPUT_DIR, fileName);

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

console.log('Generating unified Accent curriculum...');
if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });

for (const gameType of GAME_TYPES) {
  generateForGame(gameType);
}

console.log('Accent Curriculum Generation Complete!');
