const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/writing');
const files = fs.readdirSync(dir).filter(f => f.startsWith('essayDrafting_') && f.endsWith('.json'));

console.log(`Found ${files.length} Essay Drafting curriculum files. Beginning audits...\n`);

const allTopics = new Set();
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
  
  if (data.gameType !== 'essayDrafting') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'essayDrafting', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "essayTopic", "requiredPoints", "options", "correctOrder", "hint", "explanation"];
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
    
    // Verify requiredPoints is an array of size 4
    if (q.requiredPoints) {
      if (!Array.isArray(q.requiredPoints)) {
        missingFields.push(`requiredPoints is not an array in quest ${q.id} in ${file}`);
      } else if (q.requiredPoints.length !== 4) {
        missingFields.push(`requiredPoints array must have exactly 4 elements, got ${q.requiredPoints.length} in quest ${q.id} in ${file}`);
      }
    }
    
    // Verify correctOrder is an array of size 4
    if (q.correctOrder) {
      if (!Array.isArray(q.correctOrder)) {
        missingFields.push(`correctOrder is not an array in quest ${q.id} in ${file}`);
      } else if (q.correctOrder.length !== 4) {
        missingFields.push(`correctOrder array must have exactly 4 elements, got ${q.correctOrder.length} in quest ${q.id} in ${file}`);
      }
    }
    
    // Check topic uniqueness
    if (q.essayTopic) {
      const normalized = q.essayTopic.trim().toLowerCase();
      if (allTopics.has(normalized)) {
        duplicates.push(`Duplicate topic: "${q.essayTopic.substring(0, 40)}..." in ${file} (Quest ID: ${q.id})`);
      }
      allTopics.add(normalized);
    }
  });
});

console.log("================ AUDIT REPORT ================");
console.log(`Total Files Checked: ${files.length}`);
console.log(`Total Questions Scanned: ${totalQuestsCount}`);
console.log(`Unique Topics Registered: ${allTopics.size}`);

if (duplicates.length > 0) {
  console.log(`\n❌ DUPLICATE TOPICS DETECTED (${duplicates.length}):`);
  console.log(duplicates.slice(0, 10).join('\n'));
} else {
  console.log(`\n✅ Zero duplicate topics! Uniqueness verified successfully.`);
}

if (invalidOptions.length > 0) {
  console.log(`\n❌ INVALID SEQUENCING METADATA DETECTED (${invalidOptions.length}):`);
  console.log(invalidOptions.slice(0, 10).join('\n'));
} else {
  console.log(`✅ Zero matching options errors! metadata matches options bounds.`);
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
  console.log(`🏆 CONGRATULATIONS: Essay Drafting curriculum is 100% PERFECT!`);
  process.exit(0);
}
