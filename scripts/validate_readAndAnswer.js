const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/reading');
const files = fs.readdirSync(dir).filter(f => f.startsWith('readAndAnswer_') && f.endsWith('.json'));

console.log(`Found ${files.length} Read & Answer curriculum files. Beginning audits...\n`);

const allPassages = new Set();
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
  
  if (data.gameType !== 'readAndAnswer') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'readAndAnswer', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "passage", "question", "options", "correctAnswer", "correctAnswerIndex", "hint", "explanation"];
    required.forEach(field => {
      if (q[field] === undefined || q[field] === null || q[field] === '') {
        missingFields.push(`Missing field '${field}' in quest ${q.id || 'unknown'} inside ${file}`);
      }
    });
    
    // Check sentence uniqueness
    if (q.passage) {
      const normalized = q.passage.trim().toLowerCase();
      if (allPassages.has(normalized)) {
        duplicates.push(`Duplicate passage: "${q.passage.substring(0, 40)}..." in ${file} (Quest ID: ${q.id})`);
      }
      allPassages.add(normalized);
    }
  });
});

console.log(`================ AUDIT REPORT ================`);
console.log(`Total Files Checked: ${files.length}`);
console.log(`Total Questions Scanned: ${totalQuestsCount}`);
console.log(`Unique Passages Registered: ${allPassages.size}`);

if (duplicates.length > 0) {
  console.log(`\n❌ DUPLICATE PASSAGES DETECTED (${duplicates.length}):`);
  console.log(duplicates.slice(0, 10).join('\n'));
} else {
  console.log(`\n✅ Zero duplicate passages! Uniqueness verified successfully.`);
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
  console.log(`🏆 CONGRATULATIONS: Read & Answer curriculum is 100% PERFECT!`);
  process.exit(0);
}
