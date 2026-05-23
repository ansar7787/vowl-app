const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/writing');
const files = fs.readdirSync(dir).filter(f => f.startsWith('completeSentence_') && f.endsWith('.json'));

console.log(`Found ${files.length} Complete Sentence curriculum files. Beginning audits...\n`);

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
  
  if (data.gameType !== 'completeSentence') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'completeSentence', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "partialSentence", "options", "correctAnswer", "hint", "explanation"];
    required.forEach(field => {
      if (q[field] === undefined || q[field] === null || q[field] === '') {
        missingFields.push(`Missing field '${field}' in quest ${q.id || 'unknown'} inside ${file}`);
      }
    });
    
    // Verify options contains correctAnswer
    if (q.options && q.correctAnswer) {
      if (!Array.isArray(q.options)) {
        missingFields.push(`options is not an array in quest ${q.id} inside ${file}`);
      } else if (!q.options.includes(q.correctAnswer)) {
        invalidOptions.push(`correctAnswer "${q.correctAnswer}" is not present in options array [${q.options.join(', ')}] in quest ${q.id} in ${file}`);
      }
    }
    
    // Check passage uniqueness
    if (q.partialSentence) {
      const normalized = q.partialSentence.trim().toLowerCase();
      if (allPassages.has(normalized)) {
        duplicates.push(`Duplicate partialSentence: "${q.partialSentence.substring(0, 40)}..." in ${file} (Quest ID: ${q.id})`);
      }
      allPassages.add(normalized);
    }
  });
});

console.log("================ AUDIT REPORT ================");
console.log(`Total Files Checked: ${files.length}`);
console.log(`Total Questions Scanned: ${totalQuestsCount}`);
console.log(`Unique Sentences Registered: ${allPassages.size}`);

if (duplicates.length > 0) {
  console.log(`\n❌ DUPLICATE SENTENCES DETECTED (${duplicates.length}):`);
  console.log(duplicates.slice(0, 10).join('\n'));
} else {
  console.log(`\n✅ Zero duplicate sentences! Uniqueness verified successfully.`);
}

if (invalidOptions.length > 0) {
  console.log(`\n❌ INVALID OPTIONS DETECTED (${invalidOptions.length}):`);
  console.log(invalidOptions.slice(0, 10).join('\n'));
} else {
  console.log(`✅ Zero option format errors! Every correctAnswer is perfectly listed in the options array.`);
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
  console.log(`🏆 CONGRATULATIONS: Complete Sentence curriculum is 100% PERFECT!`);
  process.exit(0);
}
