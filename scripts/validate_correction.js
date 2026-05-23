const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/writing');
const files = fs.readdirSync(dir).filter(f => f.startsWith('correctionWriting_') && f.endsWith('.json'));

console.log(`Found ${files.length} Correction Writing curriculum files. Beginning audits...\n`);

const allPassages = new Set();
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
  
  if (data.gameType !== 'correctionWriting') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'correctionWriting', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "passage", "options", "correctAnswer", "hint", "explanation"];
    required.forEach(field => {
      if (q[field] === undefined || q[field] === null || q[field] === '') {
        missingFields.push(`Missing field '${field}' in quest ${q.id || 'unknown'} inside ${file}`);
      }
    });
    
    // Verify options is an array of size 4
    if (q.options) {
      if (!Array.isArray(q.options)) {
        missingFields.push(`options is not an array in quest ${q.id} in ${file}`);
      } else if (q.options.length !== 4) {
        missingFields.push(`options array must have exactly 4 elements, got ${q.options.length} in quest ${q.id} in ${file}`);
      }
    }
    
    // Verify correctAnswer is within options array
    if (q.options && q.correctAnswer) {
      if (!q.options.includes(q.correctAnswer)) {
        invalidOptions.push(`correctAnswer '${q.correctAnswer}' is not present in options array inside quest ${q.id} in ${file}`);
      }
    }
    
    // Check passage uniqueness
    if (q.passage) {
      const normalized = q.passage.trim().toLowerCase();
      if (allPassages.has(normalized)) {
        duplicates.push(`Duplicate passage: "${q.passage.substring(0, 40)}..." in ${file} (Quest ID: ${q.id})`);
      }
      allPassages.add(normalized);
    }
  });
});

console.log("================ AUDIT REPORT ================");
console.log(`Total Files Checked: ${files.length}`);
console.log(`Total Questions Scanned: ${totalQuestsCount}`);
console.log(`Unique Passages Registered: ${allPassages.size}`);

if (duplicates.length > 0) {
  console.log(`\n❌ DUPLICATE PASSAGES DETECTED (${duplicates.length}):`);
  console.log(duplicates.slice(0, 10).join('\n'));
} else {
  console.log(`\n✅ Zero duplicate passages! Uniqueness verified successfully.`);
}

if (invalidOptions.length > 0) {
  console.log(`\n❌ INVALID CORRECT ANSWER MATCHES DETECTED (${invalidOptions.length}):`);
  console.log(invalidOptions.slice(0, 10).join('\n'));
} else {
  console.log(`✅ Zero matching options errors! correctAnswer is verified inside options bounds.`);
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
  console.log(`🏆 CONGRATULATIONS: Correction Writing curriculum is 100% PERFECT!`);
  process.exit(0);
}
