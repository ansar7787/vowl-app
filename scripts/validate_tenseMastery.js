const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/grammar');
const files = fs.readdirSync(dir).filter(f => f.startsWith('tenseMastery_') && f.endsWith('.json'));

console.log(`Found ${files.length} Tense Mastery curriculum files. Beginning audits...\n`);

const allSentences = new Set();
const duplicates = [];
const missingFields = [];
const incorrectTenses = [];
let totalQuestsCount = 0;

const expectedTenses = ["Past", "Present", "Future"];

files.forEach(file => {
  const filePath = path.join(dir, file);
  let data;
  try {
    data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (err) {
    missingFields.push(`Failed to parse JSON file: ${file}`);
    return;
  }
  
  if (data.gameType !== 'tenseMastery') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'tenseMastery', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "sentence", "correctAnswer", "correctAnswerCategory", "hint", "explanation"];
    required.forEach(field => {
      if (q[field] === undefined || q[field] === null || q[field] === '') {
        missingFields.push(`Missing field '${field}' in quest ${q.id || 'unknown'} inside ${file}`);
      }
    });
    
    // Check sentence uniqueness
    if (q.sentence) {
      const normalized = q.sentence.trim().toLowerCase();
      if (allSentences.has(normalized)) {
        duplicates.push(`Duplicate sentence: "${q.sentence}" in ${file} (Quest ID: ${q.id})`);
      }
      allSentences.add(normalized);
    }
    
    // Check tense accuracy
    if (q.correctAnswer && !expectedTenses.includes(q.correctAnswer)) {
      incorrectTenses.push(`Invalid correctAnswer '${q.correctAnswer}' in quest ${q.id} inside ${file}`);
    }
    if (q.correctAnswerCategory && !expectedTenses.includes(q.correctAnswerCategory)) {
      incorrectTenses.push(`Invalid correctAnswerCategory '${q.correctAnswerCategory}' in quest ${q.id} inside ${file}`);
    }
    if (q.correctAnswer !== q.correctAnswerCategory) {
      incorrectTenses.push(`Mismatch between correctAnswer and correctAnswerCategory in quest ${q.id} inside ${file}`);
    }
    
    // Verify difficulty mapping
    const levelMatch = q.id.match(/tm_l(\d+)_q/);
    if (levelMatch) {
      const level = parseInt(levelMatch[1], 10);
      let expectedDiff;
      if (level <= 40) expectedDiff = 1;
      else if (level <= 80) expectedDiff = 2;
      else if (level <= 120) expectedDiff = 3;
      else if (level <= 160) expectedDiff = 4;
      else expectedDiff = 5;
      
      if (q.difficulty !== expectedDiff) {
        missingFields.push(`Incorrect difficulty mapping for level ${level} in quest ${q.id}: expected ${expectedDiff}, got ${q.difficulty}`);
      }
    }
  });
});

console.log(`================ AUDIT REPORT ================`);
console.log(`Total Files Checked: ${files.length}`);
console.log(`Total Questions Scanned: ${totalQuestsCount}`);
console.log(`Unique Sentences Registered: ${allSentences.size}`);

if (duplicates.length > 0) {
  console.log(`\n❌ DUPLICATE SENTENCES DETECTED (${duplicates.length}):`);
  console.log(duplicates.slice(0, 10).join('\n'));
  if (duplicates.length > 10) console.log(`...and ${duplicates.length - 10} more.`);
} else {
  console.log(`\n✅ Zero duplicate sentences! Uniqueness verified successfully.`);
}

if (missingFields.length > 0) {
  console.log(`\n❌ STRUCTURAL OR SCHEMA ERRORS DETECTED (${missingFields.length}):`);
  console.log(missingFields.slice(0, 10).join('\n'));
} else {
  console.log(`✅ Zero schema or missing field violations! Schema structural integrity is perfect.`);
}

if (incorrectTenses.length > 0) {
  console.log(`\n❌ INVALID TENSES OR TIMELINE MISMATCHES DETECTED (${incorrectTenses.length}):`);
  console.log(incorrectTenses.slice(0, 10).join('\n'));
} else {
  console.log(`✅ Zero timeline tenses errors! Slider category alignment is 100% accurate.`);
}

console.log(`\n==============================================`);

if (duplicates.length > 0 || missingFields.length > 0 || incorrectTenses.length > 0) {
  process.exit(1);
} else {
  console.log(`🏆 CONGRATULATIONS: Tense Mastery curriculum is 100% PERFECT!`);
  process.exit(0);
}
