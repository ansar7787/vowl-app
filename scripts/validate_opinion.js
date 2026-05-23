const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/writing');
const files = fs.readdirSync(dir).filter(f => f.startsWith('opinionWriting_') && f.endsWith('.json'));

console.log(`Found ${files.length} Opinion Writing curriculum files. Beginning audits...\n`);

const allTheses = new Set();
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
  
  if (data.gameType !== 'opinionWriting') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'opinionWriting', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "prompt", "options", "correctOrder", "hint", "explanation"];
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
    
    // Verify correctOrder is an array of size 2 and contains valid indices
    if (q.correctOrder) {
      if (!Array.isArray(q.correctOrder)) {
        missingFields.push(`correctOrder is not an array in quest ${q.id} in ${file}`);
      } else if (q.correctOrder.length !== 2) {
        missingFields.push(`correctOrder must have exactly 2 index elements in quest ${q.id} in ${file}`);
      } else {
        q.correctOrder.forEach(idx => {
          if (idx < 0 || idx >= 4) {
            invalidOptions.push(`Invalid index ${idx} in correctOrder array in quest ${q.id} in ${file}`);
          }
        });
      }
    }
    
    // Check thesis uniqueness
    if (q.prompt) {
      const normalized = q.prompt.trim().toLowerCase();
      if (allTheses.has(normalized)) {
        duplicates.push(`Duplicate thesis: "${q.prompt.substring(0, 40)}..." in ${file} (Quest ID: ${q.id})`);
      }
      allTheses.add(normalized);
    }
  });
});

console.log("================ AUDIT REPORT ================");
console.log(`Total Files Checked: ${files.length}`);
console.log(`Total Questions Scanned: ${totalQuestsCount}`);
console.log(`Unique Theses Registered: ${allTheses.size}`);

if (duplicates.length > 0) {
  console.log(`\n❌ DUPLICATE THESES DETECTED (${duplicates.length}):`);
  console.log(duplicates.slice(0, 10).join('\n'));
} else {
  console.log(`\n✅ Zero duplicate theses! Uniqueness verified successfully.`);
}

if (invalidOptions.length > 0) {
  console.log(`\n❌ INVALID SEQUENCING INDICES DETECTED (${invalidOptions.length}):`);
  console.log(invalidOptions.slice(0, 10).join('\n'));
} else {
  console.log(`✅ Zero sequencing indices errors! Indexes are verified inside bounds [0-3].`);
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
  console.log(`🏆 CONGRATULATIONS: Opinion Writing curriculum is 100% PERFECT!`);
  process.exit(0);
}
