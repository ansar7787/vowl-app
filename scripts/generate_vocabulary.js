const fs = require('fs');
const path = require('path');
const pools = require('./vocabulary_pools');

const OUTPUT_DIR = path.join(__dirname, '../assets/curriculum/vocabulary');
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

const PAINTERS = ["ArchiveDecryptSync", "CouncilHallSync", "EchoChamberSync", "NexusCoreSync", "NeuralNegotiationSync", "PurgeGridSync", "SanctumFlowSync", "VoidStasisSync", "ZenithBufferSync"];
const SHADERS = ["terminal_flicker", "binary_pulse", "plasma_drift", "neon_pulse", "brain_bloom", "void_ripple", "glitch_jitter", "signal_ghosting", "data_cascade"];
const COLORS = ["0xFF2196F3", "0xFFF44336", "0xFF4CAF50", "0xFFE91E63", "0xFFFFEB3B", "0xFF9C27B0", "0xFF00BCD4", "0xFFFF9800", "0xFF607D8B"];

function getVisualConfig(level) {
  return {
    painter_type: PAINTERS[level % PAINTERS.length],
    primary_color: COLORS[level % COLORS.length],
    pulse_intensity: 0.5 + (level % 5) * 0.1,
    shader_effect: SHADERS[level % SHADERS.length]
  };
}

function generateBatches(gameType, questPool) {
  console.log(`Generating curriculum for: ${gameType}...`);
  
  // 20 batches of 10 levels (Total 200 levels)
  for (let b = 0; b < 20; b++) {
    const startLevel = b * 10 + 1;
    const endLevel = (b + 1) * 10;
    const batchQuests = [];

    for (let l = startLevel; l <= endLevel; l++) {
      // 3 questions per level
      for (let qIdx = 1; qIdx <= 3; qIdx++) {
        const poolIndex = ((l - 1) * 3 + (qIdx - 1)) % questPool.length;
        const baseQuest = questPool[poolIndex];
        
        let interactionType = "choice";
        if (gameType === "synonymSearch") interactionType = "lens";
        if (gameType === "antonymSearch") interactionType = "mirror";
        if (baseQuest.interactionType) interactionType = baseQuest.interactionType;

        batchQuests.push({
          id: `VOC_${gameType.toUpperCase()}_L${l}_Q${qIdx}`,
          instruction: baseQuest.instruction || "Choose the correct option.",
          difficulty: Math.ceil(l / 50),
          subtype: gameType,
          interactionType: interactionType,
          word: baseQuest.fields.transcript,
          options: baseQuest.fields.options,
          correctAnswer: baseQuest.fields.options[baseQuest.fields.correctAnswerIndex],
          hint: baseQuest.fields.hint,
          explanation: baseQuest.fields.explanation || "Correct match found.",
          visual_config: getVisualConfig(l)
        });
      }
    }

    const filename = `${gameType}_${startLevel}_${endLevel}.json`;
    const filepath = path.join(OUTPUT_DIR, filename);
    
    const output = {
      gameType: gameType,
      batchIndex: b + 1,
      levels: `${startLevel}-${endLevel}`,
      quests: batchQuests
    };

    fs.writeFileSync(filepath, JSON.stringify(output, null, 2));
  }
}

const gamesToGenerate = [
  'flashcards',
  'synonymSearch',
  'antonymSearch',
  'contextClues',
  'idioms',
  'phrasalVerbs',
  'prefixSuffix',
  'wordFormation',
  'topicVocab',
  'academicWord',
  'collocations',
  'contextualUsage'
];

gamesToGenerate.forEach(game => {
  if (pools[game]) {
    generateBatches(game, pools[game]);
  } else {
    console.error(`Pool for ${game} not found!`);
  }
});

console.log("Vocabulary curriculum generation complete!");
