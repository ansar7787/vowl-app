const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, '..', 'assets', 'curriculum');

let totalFilesChecked = 0;
let totalQuestsChecked = 0;
let duplicateIds = [];
let emptyFieldQuests = [];
const seenIds = new Set();

const gameQuestions = {};
let duplicateTextCount = 0;

// Category specific fields mapper
function extractQuestData(q, category) {
  let instruction = "";
  let question = "";
  let correct = "";

  // Common baseline fallbacks
  instruction = q.instruction || q.hint || q.explanation || "";
  
  if (q.correctAnswerIndex !== undefined && q.options && Array.isArray(q.options)) {
    correct = q.options[q.correctAnswerIndex] || "";
  } else if (q.correctOrder !== undefined) {
    correct = Array.isArray(q.correctOrder) ? q.correctOrder.join(',') : q.correctOrder.toString();
  } else if (q.pairs !== undefined) {
    correct = JSON.stringify(q.pairs);
  } else {
    correct = q.correctAnswer || q.sampleAnswer || q.correctSentence || q.correctOption || q.missingWord || q.textToSpeak || q.word || q.explanation || "";
  }

  switch (category) {
    case 'speaking':
      question = q.prompt || q.partnerDialogue || q.sceneText || q.question || q.textToSpeak || "";
      break;
    case 'listening':
      question = q.textToSpeak || q.textWithBlanks || q.question || "";
      break;
    case 'reading':
      question = q.readingPassage || q.clozeText || q.question || q.prompt || (q.pairs ? JSON.stringify(q.pairs.map(p => p.key)) : "");
      break;
    case 'writing':
      question = q.prompt || q.sceneDescription || q.dailyTopic || q.question || q.situation || "";
      break;
    case 'grammar':
      question = q.incorrectSentence || q.scrambledWords || q.prompt || q.scrambledSentence || q.question || "";
      break;
    case 'vocabulary':
      question = q.word || q.definition || q.prompt || q.question || "";
      break;
    case 'accent':
      question = q.stressedSyllable || q.mimicDialogue || q.wordPair || q.phoneme || q.prompt || q.question || q.word || q.textToSpeak || "";
      break;
    case 'roleplay':
      question = q.partnerStatement || q.partnerDialogue || q.prompt || q.question || "";
      break;
    case 'elite_mastery':
      question = q.prompt || q.question || q.textToSpeak || "";
      break;
    case 'kids':
      instruction = q.instruction || "";
      question = q.question || "";
      break;
    default:
      question = q.question || q.prompt || q.textToSpeak || "";
  }

  return { instruction, question, correct };
}

function auditFile(filePath, category) {
  totalFilesChecked++;
  const raw = fs.readFileSync(filePath, 'utf8');
  let data;
  try {
    data = JSON.parse(raw);
  } catch (e) {
    console.error(`Invalid JSON in file: ${filePath}. Error: ${e.message}`);
    return;
  }

  let questsList = [];
  if (category === 'kids') {
    if (Array.isArray(data)) {
      data.forEach(levelObj => {
        if (levelObj.quests && Array.isArray(levelObj.quests)) {
          questsList.push(...levelObj.quests);
        }
      });
    }
  } else {
    if (data.quests && Array.isArray(data.quests)) {
      questsList = data.quests;
    }
  }

  questsList.forEach(q => {
    totalQuestsChecked++;
    
    // 1. Check ID uniqueness
    if (q.id) {
      if (seenIds.has(q.id)) {
        duplicateIds.push({ id: q.id, file: filePath });
      } else {
        seenIds.add(q.id);
      }
    } else {
      emptyFieldQuests.push({ error: "Missing ID", file: filePath });
    }

    // 2. Category-aware verification
    const { instruction, question, correct } = extractQuestData(q, category);

    if (!question && !instruction) {
      emptyFieldQuests.push({ error: `Missing question/instruction for category [${category}]`, id: q.id, file: filePath });
    }
    if (!correct) {
      emptyFieldQuests.push({ error: `Missing correctAnswer for category [${category}]`, id: q.id, file: filePath });
    }

    // 3. Uniqueness Check per Game Subtype
    const gameType = q.gameType || q.subtype || category || "unknown";
    if (!gameQuestions[gameType]) {
      gameQuestions[gameType] = new Set();
    }
    const uniqKey = `${instruction}::${question}::${correct}`.toLowerCase();
    if (gameQuestions[gameType].has(uniqKey)) {
      duplicateTextCount++;
    } else {
      gameQuestions[gameType].add(uniqKey);
    }
  });
}

function traverseAndAudit(dir, category = "") {
  const items = fs.readdirSync(dir);
  items.forEach(item => {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      const nextCategory = dir.toLowerCase() === baseDir.toLowerCase() ? item : category;
      traverseAndAudit(fullPath, nextCategory);
    } else if (item.endsWith('.json')) {
      auditFile(fullPath, category);
    }
  });
}

console.log("Starting comprehensive 2,440 JSON file curriculum audit with category-specific mapping...");
traverseAndAudit(baseDir);
console.log("====================================================");
console.log(`Audit Summary:`);
console.log(`Total Files Checked      : ${totalFilesChecked}`);
console.log(`Total Questions Checked  : ${totalQuestsChecked}`);
console.log(`Duplicate Quest IDs      : ${duplicateIds.length}`);
console.log(`Empty/Invalid Quests     : ${emptyFieldQuests.length}`);
console.log(`Repeating Questions Found: ${duplicateTextCount}`);
console.log("====================================================");

// Print grouped summary of files with errors
const errorFilesMap = {};
emptyFieldQuests.forEach(err => {
  if (!errorFilesMap[err.file]) {
    errorFilesMap[err.file] = [];
  }
  errorFilesMap[err.file].push(err);
});

console.log("=== DETAILED REPORT OF ALL FILES WITH SCHEMA ERRORS ===");
Object.keys(errorFilesMap).forEach(file => {
  console.log(`File: ${file} | Errors count: ${errorFilesMap[file].length}`);
  console.log(`Sample errors in this file:`);
  console.log(errorFilesMap[file].slice(0, 3));
  console.log("----------------------------------------------------");
});
