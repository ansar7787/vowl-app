const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/writing');
const files = fs.readdirSync(dir).filter(f => f.startsWith('describeSituationWriting_') && f.endsWith('.json'));

console.log(`Found ${files.length} Describe Situation curriculum files. Beginning audits...\n`);

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
  
  if (data.gameType !== 'describeSituationWriting') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'describeSituationWriting', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "situation", "emojis", "keywords", "minWords", "hint", "explanation"];
    required.forEach(field => {
      if (q[field] === undefined || q[field] === null || q[field] === '') {
        missingFields.push(`Missing field '${field}' in quest ${q.id || 'unknown'} inside ${file}`);
      }
    });
    
    // Verify emojis is an array of size 4
    if (q.emojis) {
      if (!Array.isArray(q.emojis)) {
        missingFields.push(`emojis is not an array in quest ${q.id} in ${file}`);
      } else if (q.emojis.length !== 4) {
        missingFields.push(`emojis array must have exactly 4 elements, got ${q.emojis.length} in quest ${q.id} in ${file}`);
      }
    }
    
    // Verify keywords is a map of keys "0", "1", "2", "3" to string arrays
    if (q.keywords) {
      const keys = ["0", "1", "2", "3"];
      keys.forEach(k => {
        if (!q.keywords[k] || !Array.isArray(q.keywords[k])) {
          missingFields.push(`keywords is missing or has invalid format for key '${k}' in quest ${q.id} in ${file}`);
        }
      });
    }
    
    // Check passage uniqueness
    if (q.situation) {
      const normalized = q.situation.trim().toLowerCase();
      if (allPassages.has(normalized)) {
        duplicates.push(`Duplicate situation: "${q.situation.substring(0, 40)}..." in ${file} (Quest ID: ${q.id})`);
      }
      allPassages.add(normalized);
    }
  });
});

console.log("================ AUDIT REPORT ================");
console.log(`Total Files Checked: ${files.length}`);
console.log(`Total Questions Scanned: ${totalQuestsCount}`);
console.log(`Unique Situations Registered: ${allPassages.size}`);

if (duplicates.length > 0) {
  console.log(`\n❌ DUPLICATE SITUATIONS DETECTED (${duplicates.length}):`);
  console.log(duplicates.slice(0, 10).join('\n'));
} else {
  console.log(`\n✅ Zero duplicate situations! Uniqueness verified successfully.`);
}

if (missingFields.length > 0) {
  console.log(`\n❌ STRUCTURAL OR SCHEMA ERRORS DETECTED (${missingFields.length}):`);
  console.log(missingFields.slice(0, 10).join('\n'));
} else {
  console.log(`✅ Zero schema or missing field violations! Schema structural integrity is perfect.`);
}

console.log("==============================================");

if (duplicates.length > 0 || missingFields.length > 0) {
  process.exit(1);
} else {
  console.log(`🏆 CONGRATULATIONS: Describe Situation curriculum is 100% PERFECT!`);
  process.exit(0);
}
