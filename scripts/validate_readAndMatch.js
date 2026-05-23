const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/reading');
const files = fs.readdirSync(dir).filter(f => f.startsWith('readAndMatch_') && f.endsWith('.json'));

console.log(`Found ${files.length} Read & Match curriculum files. Beginning audits...\n`);

const allKeys = new Set();
const duplicates = [];
const missingFields = [];
const invalidPairs = [];
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
  
  if (data.gameType !== 'readAndMatch') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'readAndMatch', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "pairs", "hint", "explanation"];
    required.forEach(field => {
      if (q[field] === undefined || q[field] === null || q[field] === '') {
        missingFields.push(`Missing field '${field}' in quest ${q.id || 'unknown'} inside ${file}`);
      }
    });
    
    // Check pairs validity
    if (q.pairs) {
      if (!Array.isArray(q.pairs)) {
        missingFields.push(`pairs is not an array in quest ${q.id} inside ${file}`);
      } else if (q.pairs.length < 2) {
        invalidPairs.push(`Too few pairs (${q.pairs.length}) in quest ${q.id} inside ${file}`);
      } else {
        q.pairs.forEach(p => {
          if (!p.key || !p.value) {
            invalidPairs.push(`Invalid pair structure in quest ${q.id} inside ${file}: expected key/value, got ${JSON.stringify(p)}`);
          } else {
            const normalizedKey = p.key.trim().toLowerCase();
            if (allKeys.has(normalizedKey)) {
              duplicates.push(`Duplicate key: "${p.key}" in ${file} (Quest ID: ${q.id})`);
            }
            allKeys.add(normalizedKey);
          }
        });
      }
    }
  });
});

console.log(`================ AUDIT REPORT ================`);
console.log(`Total Files Checked: ${files.length}`);
console.log(`Total Questions Scanned: ${totalQuestsCount}`);
console.log(`Unique Keys Registered: ${allKeys.size}`);

if (duplicates.length > 0) {
  console.log(`\n❌ DUPLICATE KEYS DETECTED (${duplicates.length}):`);
  console.log(duplicates.slice(0, 10).join('\n'));
} else {
  console.log(`\n✅ Zero duplicate keys! Uniqueness verified successfully.`);
}

if (invalidPairs.length > 0) {
  console.log(`\n❌ INVALID PAIRS DETECTED (${invalidPairs.length}):`);
  console.log(invalidPairs.slice(0, 10).join('\n'));
} else {
  console.log(`✅ Zero pair structure errors! Every pair has a valid non-empty key and value.`);
}

if (missingFields.length > 0) {
  console.log(`\n❌ STRUCTURAL OR SCHEMA ERRORS DETECTED (${missingFields.length}):`);
  console.log(missingFields.slice(0, 10).join('\n'));
} else {
  console.log(`✅ Zero schema or missing field violations! Schema structural integrity is perfect.`);
}

console.log(`\n==============================================`);

if (duplicates.length > 0 || missingFields.length > 0 || invalidPairs.length > 0) {
  process.exit(1);
} else {
  console.log(`🏆 CONGRATULATIONS: Read & Match curriculum is 100% PERFECT!`);
  process.exit(0);
}
