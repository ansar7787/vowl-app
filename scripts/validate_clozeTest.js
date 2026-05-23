const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/reading');
const files = fs.readdirSync(dir).filter(f => f.startsWith('clozeTest_') && f.endsWith('.json'));

console.log(`Found ${files.length} Cloze Test curriculum files. Beginning audits...\n`);

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
  
  if (data.gameType !== 'clozeTest') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'clozeTest', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "passage", "options", "correctAnswer", "missingWord", "hint", "explanation"];
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
  console.log(`🏆 CONGRATULATIONS: Cloze Test curriculum is 100% PERFECT!`);
  process.exit(0);
}
