const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/accent');
const files = fs.readdirSync(dir).filter(f => f.startsWith('pitchPatternMatch_') && f.endsWith('.json'));

console.log(`Found ${files.length} Pitch Pattern Match curriculum files. Beginning audits...\n`);

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
  
  if (data.gameType !== 'pitchPatternMatch') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'pitchPatternMatch', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "word", "textToSpeak", "options", "correctAnswerIndex", "pitchPatterns", "hint", "explanation"];
    required.forEach(field => {
      if (q[field] === undefined || q[field] === null || q[field] === '') {
        missingFields.push(`Missing field '${field}' in quest ${q.id || 'unknown'} inside ${file}`);
      }
    });
    
    // Verify options size is 2
    if (q.options) {
      if (!Array.isArray(q.options)) {
        missingFields.push(`options is not an array in quest ${q.id} in ${file}`);
      } else if (q.options.length !== 2) {
        missingFields.push(`options must have exactly 2 elements, got ${q.options.length} in quest ${q.id} in ${file}`);
      }
    }
    
    // Verify correctAnswerIndex is between 0 and 1
    if (q.correctAnswerIndex !== undefined) {
      if (q.correctAnswerIndex < 0 || q.correctAnswerIndex > 1) {
        invalidOptions.push(`correctAnswerIndex ${q.correctAnswerIndex} must be 0 or 1 in quest ${q.id} in ${file}`);
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
  console.log(`🏆 CONGRATULATIONS: Pitch Pattern Match curriculum is 100% PERFECT!`);
  process.exit(0);
}
