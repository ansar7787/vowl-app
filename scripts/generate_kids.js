/**
 * Kids Zone Curriculum Generator for VoxAI Quest
 * Generates 4,000 Levels with Proper Game-Themed Filenames
 */

const fs = require('fs');
const path = require('path');
const pools = require('./kids_pools');

const OUTPUT_DIR = path.join(__dirname, '../assets/curriculum/kids');
const BATCH_SIZE = 10;
const LEVELS_PER_MODULE = 200;

// Ensure output directory exists
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

const KIDS_VISUALS = [
  { painter: "RainbowSwirl", shader: "bubble_pop" },
  { painter: "SunnyMeadow", shader: "sparkle_dust" },
  { painter: "OceanWave", shader: "water_ripples" },
  { painter: "CandyCloud", shader: "sugar_glow" },
  { painter: "ForestFriend", shader: "leaf_flutter" },
  { painter: "StarryNight", shader: "magic_twinkle" },
  { painter: "PandaPlay", shader: "bamboo_breeze" },
  { painter: "UnicornMist", shader: "pastel_dream" },
  { painter: "DinoDesert", shader: "sand_swirl" },
];

function generateModule(moduleName, pool) {
  const moduleDir = path.join(OUTPUT_DIR, moduleName);
  if (fs.existsSync(moduleDir)) {
    fs.rmSync(moduleDir, { recursive: true, force: true });
  }
  fs.mkdirSync(moduleDir, { recursive: true });

  console.log(`Generating Kids Module: ${moduleName}...`);

  for (let b = 0; b < LEVELS_PER_MODULE / BATCH_SIZE; b++) {
    const batch = [];
    for (let l = 0; l < BATCH_SIZE; l++) {
      const levelNum = b * BATCH_SIZE + l + 1;
      const quests = [];

      for (let q = 0; q < 3; q++) {
        const template = pool[Math.floor(Math.random() * pool.length)];
        const visual = KIDS_VISUALS[levelNum % KIDS_VISUALS.length];

        quests.push({
          id: `kids_${moduleName}_${levelNum}_${q}`,
          instruction: template.instruction,
          question: template.question,
          options: template.options,
          correctAnswer: template.correctAnswer,
          hint: template.hint,
          imageUrl: template.question.match(/[\uD800-\uDBFF][\uDC00-\uDFFF]|\u200D/g) ? template.question : null,
          gameType: "choice_multi",
          interactionType: "choice",
          painter: visual.painter,
          shader: visual.shader,
          xpReward: 5,
          coinReward: 5
        });
      }

      batch.push({
        level: levelNum,
        quests: quests
      });
    }

    // NEW: Proper Game-Themed Filenames
    const fileName = `${moduleName}_batch_${b + 1}.json`;
    fs.writeFileSync(
      path.join(moduleDir, fileName),
      JSON.stringify(batch, null, 2)
    );
  }
}

Object.keys(pools).forEach(moduleName => {
  generateModule(moduleName, pools[moduleName]);
});

console.log("✅ Kids Zone Curriculum Generation Complete with Game-Themed Files!");
