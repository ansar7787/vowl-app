const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/grammar');
const files = fs.readdirSync(dir).filter(f => f.startsWith('punctuationMastery_') && f.endsWith('.json'));

console.log(`Found ${files.length} Punctuation Mastery curriculum files. Beginning audits...\n`);

const allSentences = new Set();
const duplicates = [];
const missingFields = [];
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
  
  if (data.gameType !== 'punctuationMastery') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'punctuationMastery', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "sentence", "correctAnswer", "hint", "explanation"];
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

console.log(`\n==============================================`);

if (duplicates.length > 0 || missingFields.length > 0) {
  process.exit(1);
} else {
  console.log(`🏆 CONGRATULATIONS: Punctuation Mastery curriculum is 100% PERFECT!`);
  process.exit(0);
}
