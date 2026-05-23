const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/accent');
const files = fs.readdirSync(dir).filter(f => f.startsWith('syllableStress_') && f.endsWith('.json'));

console.log(`Found ${files.length} Syllable Stress curriculum files. Beginning audits...\n`);

const allQuests = new Set();
const duplicates = [];
const missingFields = [];
const invalidOptions = [];
let totalQuestsCount = 0;

files.forEach(file => {
  const filePath = path.join(dir, file);
  let data;
  try {
    data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (err) {
    missingFields.push(`Failed to parse JSON file: ${file}`);
    return;
  }
  
  if (data.gameType !== 'syllableStress') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'syllableStress', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "word", "textToSpeak", "syllables", "correctAnswerIndex", "hint", "explanation"];
    required.forEach(field => {
      if (q[field] === undefined || q[field] === null || q[field] === '') {
        missingFields.push(`Missing field '${field}' in quest ${q.id || 'unknown'} inside ${file}`);
      }
    });
    
    // Verify syllables array size
    if (q.syllables) {
      if (!Array.isArray(q.syllables)) {
        missingFields.push(`syllables is not an array in quest ${q.id} in ${file}`);
      } else if (q.syllables.length < 1) {
        missingFields.push(`syllables must have at least 1 elements, got ${q.syllables.length} in quest ${q.id} in ${file}`);
      }
    }
    
    // Verify correctAnswerIndex matches bounds of syllables array
    if (q.correctAnswerIndex !== undefined && q.syllables) {
      if (q.correctAnswerIndex < 0 || q.correctAnswerIndex >= q.syllables.length) {
        invalidOptions.push(`correctAnswerIndex ${q.correctAnswerIndex} out of bounds of syllables array (length ${q.syllables.length}) in quest ${q.id} in ${file}`);
      }
    }
    
    // Verify unique quest IDs
    if (q.id) {
      if (allQuests.has(q.id)) {
        duplicates.push(`Duplicate quest ID: ${q.id} in ${file}`);
      }
      allQuests.add(q.id);
    }
  });
});

console.log("================ AUDIT REPORT ================");
console.log(`Total Files Checked: ${files.length}`);
console.log(`Total Questions Scanned: ${totalQuestsCount}`);
console.log(`Unique Quest IDs Registered: ${allQuests.size}`);

if (duplicates.length > 0) {
  console.log(`\n❌ DUPLICATE QUEST IDS DETECTED (${duplicates.length}):`);
  console.log(duplicates.slice(0, 10).join('\n'));
} else {
  console.log(`\n✅ Zero duplicate quest IDs! Uniqueness verified successfully.`);
}

if (invalidOptions.length > 0) {
  console.log(`\n❌ INVALID CORRECT ANSWER INDEX DETECTED (${invalidOptions.length}):`);
  console.log(invalidOptions.slice(0, 10).join('\n'));
} else {
  console.log(`✅ Zero matching options errors! correctAnswerIndex matches options bounds.`);
}

if (missingFields.length > 0) {
  console.log(`\n❌ STRUCTURAL OR SCHEMA ERRORS DETECTED (${missingFields.length}):`);
  console.log(missingFields.slice(0, 10).join('\n'));
} else {
  console.log(`✅ Zero schema or missing field violations! Schema structural integrity is perfect.`);
}

console.log("==============================================");

if (duplicates.length > 0 || missingFields.length > 0 || invalidOptions.length > 0) {
  process.exit(1);
} else {
  console.log(`🏆 CONGRATULATIONS: Syllable Stress curriculum is 100% PERFECT!`);
  process.exit(0);
}
