/**
 * Universal Curriculum Generator for ALL 7 remaining categories.
 * Each category has its own pools file: {category}_pools.js
 * Run: node scripts/generate_all.js
 */
const fs = require('fs');
const path = require('path');

const TOTAL_LEVELS = 200;
const QUESTIONS_PER_LEVEL = 3;
const BATCH_SIZE = 10;

const CATEGORIES = {
  reading: [
    'readAndAnswer','findWordMeaning','trueFalseReading','sentenceOrderReading',
    'readingSpeedCheck','guessTitle','readAndMatch','paragraphSummary',
    'readingInference','readingConclusion',
  ],
  vocabulary: [
    'flashcards','synonymSearch','antonymSearch','contextClues',
    'phrasalVerbs','idioms','academicWord','topicVocab',
    'wordFormation','prefixSuffix',
  ],
  writing: [
    'completeSentence','correctionWriting','dailyJournal','describeSituationWriting',
    'essayDrafting','fixTheSentence','opinionWriting','sentenceBuilder',
    'shortAnswerWriting','summarizeStoryWriting','writingEmail',
  ],
  speaking: [
    'dailyExpression','dialogueRoleplay','pronunciationFocus','repeatSentence',
    'sceneDescriptionSpeaking','situationSpeaking','speakMissingWord',
    'speakOpposite','speakSynonym','yesNoSpeaking',
  ],
  listening: [
    'ambientId','audioFillBlanks','audioMultipleChoice','audioSentenceOrder',
    'audioTrueFalse','detailSpotlight','emotionRecognition','fastSpeechDecoder',
    'listeningInference','soundImageMatch',
  ],
  roleplay: [
    'branchingDialogue','conflictResolver','elevatorPitch','emergencyHub',
    'gourmetOrder','jobInterview','medicalConsult','situationalResponse',
    'socialSpark','travelDesk',
  ],
  accent: [
    'consonantClarity','dialectDrill','intonationMimic','minimalPairs',
    'pitchPatternMatch','shadowingChallenge','speedVariance','syllableStress',
    'vowelDistinction','wordLinking',
  ],
};

function applyVariation(template, vocab, seed) {
  if (!vocab) return JSON.parse(JSON.stringify(template));
  
  const copy = JSON.parse(JSON.stringify(template));
  const keys = Object.keys(vocab);
  
  // Use a simple deterministic "random" based on level/q index
  let s = seed;
  const nextRand = () => {
    s = (s * 9301 + 49297) % 233280;
    return s / 233280;
  };

  const replacePlaceholders = (str) => {
    if (typeof str !== 'string') return str;
    let newStr = str;
    keys.forEach(key => {
      const regex = new RegExp(`{{${key}}}`, 'g');
      if (newStr.includes(`{{${key}}}`)) {
        const options = vocab[key];
        const val = options[Math.floor(nextRand() * (options.options?.length || options.length))];
        newStr = newStr.replace(regex, val);
      }
    });
    return newStr;
  };

  // Apply to fields
  if (copy.fields) {
    for (let f in copy.fields) {
      if (typeof copy.fields[f] === 'string') {
        copy.fields[f] = replacePlaceholders(copy.fields[f]);
      } else if (Array.isArray(copy.fields[f])) {
        copy.fields[f] = copy.fields[f].map(item => replacePlaceholders(item));
      }
    }
  }

  return copy;
}

function generateCategory(category, pools) {
  const outDir = path.join(__dirname, '..', 'assets', 'curriculum', category);
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

  const gameTypes = CATEGORIES[category];
  const vocab = pools.VOCAB;
  let totalFiles = 0;

  for (const gameType of gameTypes) {
    const pool = pools[gameType];
    if (!pool || pool.length === 0) {
      console.error(`  SKIP ${gameType}: no pool`);
      continue;
    }
    console.log(`  ${gameType}: pool=${pool.length}`);

    for (let batch = 0; batch < TOTAL_LEVELS / BATCH_SIZE; batch++) {
      const startLevel = batch * BATCH_SIZE + 1;
      const endLevel = (batch + 1) * BATCH_SIZE;
      const quests = [];

      for (let level = startLevel; level <= endLevel; level++) {
        for (let q = 1; q <= QUESTIONS_PER_LEVEL; q++) {
          const seed = (level * 100) + q;
          const gi = ((level - 1) * QUESTIONS_PER_LEVEL + (q - 1)) % pool.length;
          const baseTemplate = pool[gi];
          
          // Apply variations
          const t = applyVariation(baseTemplate, vocab, seed);

          const quest = {
            id: `${gameType}_l${level}_q${q}`,
            instruction: t.instruction,
            difficulty: 1,
            subtype: gameType,
            interactionType: t.interactionType || 'choice',
            ...t.fields,
            xpReward: 5,
            coinReward: 10,
          };
          quests.push(quest);
        }
      }

      const fileData = { gameType, batchIndex: batch + 1, levels: `${startLevel}-${endLevel}`, quests };
      const fileName = `${gameType}_${startLevel}_${endLevel}.json`;
      fs.writeFileSync(path.join(outDir, fileName), JSON.stringify(fileData, null, 2));
      totalFiles++;
    }
  }
  return totalFiles;
}

// Run all categories that have pool files
const args = process.argv.slice(2);
const categoriesToRun = args.length > 0 ? args : Object.keys(CATEGORIES);

let grandTotal = 0;
for (const cat of categoriesToRun) {
  if (!CATEGORIES[cat]) { console.error(`Unknown category: ${cat}`); continue; }
  const poolFile = path.join(__dirname, `${cat}_pools.js`);
  if (!fs.existsSync(poolFile)) { console.log(`SKIP ${cat}: no pool file at ${poolFile}`); continue; }
  console.log(`\n=== ${cat.toUpperCase()} ===`);
  const pools = require(poolFile);
  const count = generateCategory(cat, pools);
  grandTotal += count;
  console.log(`  Generated ${count} files`);
}
console.log(`\nDone! Grand total: ${grandTotal} files`);
