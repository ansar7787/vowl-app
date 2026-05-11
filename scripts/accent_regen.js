/**
 * Accent Curriculum Regenerator — 600 unique questions per game
 * Run: node scripts/accent_regen.js
 */
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, '..', 'assets', 'curriculum', 'accent');
const LEVELS = 200, QPL = 3, BATCH = 10;

// Helper: create quest object
function Q(gameType, level, qNum, template) {
  return {
    id: `${gameType}_l${level}_q${qNum}`,
    instruction: template.instruction,
    difficulty: Math.min(5, Math.ceil(level / 40)),
    subtype: gameType,
    interactionType: template.interactionType || 'choice',
    ...template.fields,
    xpReward: 5,
    coinReward: 10,
  };
}

// Write files for one game
function writeGame(gameType, pool) {
  const needed = LEVELS * QPL;
  if (pool.length < 200) {
    console.error(`  ERROR: ${gameType} pool=${pool.length}, need at least 200`);
    return 0;
  }
  if (pool.length < needed) {
    console.warn(`  WARN: ${gameType} pool=${pool.length}/${needed}, will cycle`);
  }
  let files = 0;
  for (let b = 0; b < LEVELS / BATCH; b++) {
    const s = b * BATCH + 1, e = (b + 1) * BATCH;
    const quests = [];
    for (let l = s; l <= e; l++) {
      for (let q = 1; q <= QPL; q++) {
        const idx = ((l - 1) * QPL + (q - 1)) % pool.length;
        quests.push(Q(gameType, l, q, pool[idx]));
      }
    }
    const fn = `${gameType}_${s}_${e}.json`;
    fs.writeFileSync(path.join(OUT, fn), JSON.stringify({ gameType, batchIndex: b + 1, levels: `${s}-${e}`, quests }, null, 2));
    files++;
  }
  return files;
}

// Load all pool generators
const pools = {};
pools.consonantClarity = require('./pools/consonant_clarity_pool.js')();
pools.intonationMimic = require('./pools/intonation_mimic_pool.js')();
pools.syllableStress = require('./pools/syllable_stress_pool.js')();
pools.minimalPairs = require('./pools/minimal_pairs_pool.js')();
pools.vowelDistinction = require('./pools/vowel_distinction_pool.js')();
pools.dialectDrill = require('./pools/dialect_drill_pool.js')();
pools.pitchPatternMatch = require('./pools/pitch_pattern_pool.js')();
pools.speedVariance = require('./pools/speed_variance_pool.js')();
pools.shadowingChallenge = require('./pools/shadowing_pool.js')();
pools.wordLinking = require('./pools/word_linking_pool.js')();

// Generate
if (!fs.existsSync(OUT)) fs.mkdirSync(OUT, { recursive: true });
let total = 0;
for (const [game, pool] of Object.entries(pools)) {
  console.log(`${game}: pool=${pool.length}`);
  total += writeGame(game, pool);
}
console.log(`\nDone! ${total} files generated.`);
