const fs = require('fs');
const path = require('path');
const pools = require('./listening_pools');

const OUTPUT_DIR = path.join(__dirname, '../assets/curriculum/listening');
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

// Configuration
const LEVELS_PER_BATCH = 10;
const TOTAL_LEVELS = 200;
const QUESTS_PER_LEVEL = 3;

const PAINTERS = [
  "ArchiveDecryptSync", 
  "CouncilHallSync", 
  "PurgeGridSync", 
  "NeuralNegotiationSync", 
  "SanctumFlowSync",
  "ZenithBufferSync",
  "VoidStasisSync",
  "NexusCoreSync",
  "EchoChamberSync"
];

const SHADERS = [
  "terminal_flicker",
  "binary_pulse",
  "void_ripple",
  "brain_bloom",
  "glitch_jitter",
  "data_cascade",
  "signal_ghosting",
  "neon_pulse",
  "plasma_drift"
];

const COLORS = [
  "0xFF03A9F4", // Light Blue
  "0xFFF44336", // Red
  "0xFF4CAF50", // Green
  "0xFFFFEB3B", // Yellow
  "0xFF9C27B0", // Purple
  "0xFFFF9800", // Orange
  "0xFF00BCD4", // Cyan
  "0xFFE91E63", // Pink
  "0xFF607D8B"  // Blue Grey
];

function getVisualConfig(levelId, questIndex) {
  const seed = levelId + questIndex;
  return {
    painter_type: PAINTERS[seed % PAINTERS.length],
    primary_color: COLORS[seed % COLORS.length],
    pulse_intensity: 0.5 + (seed % 5) * 0.1,
    shader_effect: SHADERS[seed % SHADERS.length]
  };
}

const games = [
  { type: 'audioFillBlanks', pool: pools.audioFillBlanks, prefix: 'afb' },
  { type: 'audioMultipleChoice', pool: pools.audioMultipleChoice, prefix: 'amc' },
  { type: 'audioSentenceOrder', pool: pools.audioSentenceOrder, prefix: 'aso' },
  { type: 'audioTrueFalse', pool: pools.audioTrueFalse, prefix: 'atf' },
  { type: 'soundImageMatch', pool: pools.soundImageMatch, prefix: 'sim' },
  { type: 'fastSpeechDecoder', pool: pools.fastSpeechDecoder, prefix: 'fsd' },
  { type: 'emotionRecognition', pool: pools.emotionRecognition, prefix: 'er' },
  { type: 'detailSpotlight', pool: pools.detailSpotlight, prefix: 'ds' },
  { type: 'listeningInference', pool: pools.listeningInference, prefix: 'li' },
  { type: 'ambientId', pool: pools.ambientId, prefix: 'ai' }
];

games.forEach(game => {
  const { type, pool, prefix } = game;
  console.log(`Generating curriculum for: ${type}...`);

  for (let b = 1; b <= TOTAL_LEVELS / LEVELS_PER_BATCH; b++) {
    const startLevel = (b - 1) * LEVELS_PER_BATCH + 1;
    const endLevel = b * LEVELS_PER_BATCH;
    const batchQuests = [];

    for (let l = startLevel; l <= endLevel; l++) {
      for (let q = 1; q <= QUESTS_PER_LEVEL; q++) {
        // Pick a template from pool using stable-ish pseudo-random rotation
        const templateIndex = (l * QUESTS_PER_LEVEL + q) % pool.length;
        const template = pool[templateIndex];

        const quest = {
          id: `${prefix}_l${l}_q${q}`,
          instruction: template.instruction,
          difficulty: Math.ceil(l / 40), // 1-5 difficulty
          subtype: type,
          interactionType: type === 'audioSentenceOrder' ? 'reorder' : 'choice',
          ...template.fields,
          xpReward: l,
          coinReward: l * 2,
          visual_config: getVisualConfig(l, q)
        };
        batchQuests.push(quest);
      }
    }

    const batchData = {
      gameType: type,
      batchIndex: b,
      levels: `${startLevel}-${endLevel}`,
      quests: batchQuests
    };

    const fileName = `${type}_${startLevel}_${endLevel}.json`;
    fs.writeFileSync(path.join(OUTPUT_DIR, fileName), JSON.stringify(batchData, null, 2));
  }
});

console.log('Listening curriculum generation complete!');
