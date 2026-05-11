const fs = require('fs');
const path = require('path');
const pools = require('./reading_pools');

const OUTPUT_DIR = path.join(__dirname, '../assets/curriculum/reading');

if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

const painters = [
  'NeuralNegotiationSync',
  'EchoChamberSync',
  'NexusCoreSync',
  'PurgeGridSync',
  'SanctumFlowSync',
  'VoidStasisSync',
  'ZenithBufferSync',
  'ArchiveDecryptSync',
  'CouncilHallSync'
];

const shaders = [
  'brain_bloom',
  'plasma_drift',
  'neon_pulse',
  'void_ripple',
  'glitch_jitter',
  'signal_ghosting',
  'data_cascade',
  'terminal_flicker',
  'binary_pulse'
];

const colors = [
  '0xFFF44336', // Red
  '0xFF4CAF50', // Green
  '0xFFE91E63', // Pink
  '0xFFFFEB3B', // Yellow
  '0xFF9C27B0', // Purple
  '0xFF00BCD4', // Cyan
  '0xFFFF9800', // Orange
  '0xFF607D8B', // Blue Grey
  '0xFF2196F3'  // Blue
];

function generateQuests(gameType, pool, startLevel, endLevel, batchIndex) {
  const quests = [];
  let poolIdx = 0;

  for (let level = startLevel; level <= endLevel; level++) {
    for (let qNum = 1; qNum <= 3; qNum++) {
      const data = pool[poolIdx % pool.length];
      poolIdx++;

      const questId = `${gameType.substring(0, 3)}_l${level}_q${qNum}`;
      
      const visualIdx = (level - 1) % painters.length;
      const visualConfig = {
        painter_type: painters[visualIdx],
        primary_color: colors[visualIdx],
        pulse_intensity: 0.5 + (level % 5) * 0.1,
        shader_effect: shaders[(level - 1) % shaders.length]
      };

      const quest = {
        id: questId,
        instruction: data.instruction,
        difficulty: Math.ceil(level / 40),
        subtype: gameType,
        interactionType: 'choice',
        xpReward: level,
        coinReward: level * 2,
        visual_config: visualConfig,
        hint: data.fields.hint,
        passage: data.fields.main,
      };

      switch (gameType) {
        case 'readAndAnswer':
        case 'readingInference':
        case 'skimmingScanning':
          quest.question = data.fields.extra;
          quest.options = data.fields.options;
          quest.correctAnswerIndex = data.fields.correctIndex;
          break;
        case 'findWordMeaning':
          quest.highlightedWord = data.fields.extra;
          quest.targetWord = data.fields.extra;
          quest.options = data.fields.options;
          quest.correctAnswerIndex = data.fields.correctIndex;
          break;
        case 'trueFalseReading':
          quest.statement = data.fields.extra;
          quest.options = data.fields.options;
          quest.correctAnswerIndex = data.fields.correctIndex;
          quest.interactionType = 'trueFalse';
          break;
        case 'sentenceOrderReading':
          quest.shuffledSentences = data.fields.sentences;
          quest.correctOrder = data.fields.correctOrder;
          quest.interactionType = 'reorder';
          break;
        case 'readingSpeedCheck':
          quest.timeGoal = data.fields.timeGoal;
          quest.interactionType = 'text';
          break;
        case 'guessTitle':
        case 'paragraphSummary':
        case 'readingConclusion':
          quest.options = data.fields.options;
          quest.correctAnswerIndex = data.fields.correctIndex;
          break;
        case 'readAndMatch':
          quest.pairs = Object.entries(data.fields.pairs).map(([k, v]) => ({ key: k, value: v }));
          quest.interactionType = 'match';
          break;
        case 'clozeTest':
          quest.options = data.fields.options;
          quest.correctAnswerIndex = data.fields.correctIndices[0]; // Simplified for now
          break;
        default:
          quest.options = data.fields.options;
          quest.correctAnswerIndex = data.fields.correctIndex;
      }

      quests.push(quest);
    }
  }

  const output = {
    gameType,
    batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests
  };

  const fileName = `${gameType}_${startLevel}_${endLevel}.json`;
  fs.writeFileSync(path.join(OUTPUT_DIR, fileName), JSON.stringify(output, null, 2));
}

const gamesToGenerate = Object.keys(pools);

gamesToGenerate.forEach(game => {
  const pool = pools[game];
  for (let batch = 1; batch <= 20; batch++) {
    const startLevel = (batch - 1) * 10 + 1;
    const endLevel = batch * 10;
    generateQuests(game, pool, startLevel, endLevel, batch);
  }
});
