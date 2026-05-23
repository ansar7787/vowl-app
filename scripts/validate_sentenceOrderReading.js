const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/reading');
const files = fs.readdirSync(dir).filter(f => f.startsWith('sentenceOrderReading_') && f.endsWith('.json'));

console.log(`Found ${files.length} Sentence Order Reading curriculum files. Beginning audits...\n`);

const allSentences = new Set();
const duplicates = [];
const missingFields = [];
const invalidOrders = [];
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
  
  if (data.gameType !== 'sentenceOrderReading') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'sentenceOrderReading', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "shuffledSentences", "correctOrder", "hint", "explanation"];
    required.forEach(field => {
      if (q[field] === undefined || q[field] === null || q[field] === '') {
        missingFields.push(`Missing field '${field}' in quest ${q.id || 'unknown'} inside ${file}`);
      }
    });
    
    // Verify correctOrder has correct length and values
    if (q.shuffledSentences && q.correctOrder) {
      if (!Array.isArray(q.shuffledSentences) || !Array.isArray(q.correctOrder)) {
        missingFields.push(`shuffledSentences or correctOrder is not an array in quest ${q.id} in ${file}`);
      } else if (q.shuffledSentences.length !== q.correctOrder.length) {
        invalidOrders.push(`Length mismatch: shuffledSentences has ${q.shuffledSentences.length} items, but correctOrder has ${q.correctOrder.length} in quest ${q.id} in ${file}`);
      } else {
        q.correctOrder.forEach(idx => {
          if (idx < 0 || idx >= q.shuffledSentences.length) {
            invalidOrders.push(`Out of bounds index ${idx} in correctOrder of quest ${q.id} in ${file}`);
          }
        });
      }
    }
    
    // Check sentence uniqueness
    if (q.shuffledSentences) {
      q.shuffledSentences.forEach(s => {
        const normalized = s.trim().toLowerCase();
        if (allSentences.has(normalized)) {
          duplicates.push(`Duplicate sentence: "${s.substring(0, 40)}..." in ${file} (Quest ID: ${q.id})`);
        }
        allSentences.add(normalized);
      });
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
} else {
  console.log(`\n✅ Zero duplicate sentences! Uniqueness verified successfully.`);
}

if (invalidOrders.length > 0) {
  console.log(`\n❌ INVALID CORRECT ORDERS DETECTED (${invalidOrders.length}):`);
  console.log(invalidOrders.slice(0, 10).join('\n'));
} else {
  console.log(`✅ Zero order format errors! Every correctOrder matches shuffledSentences bounds.`);
}

if (missingFields.length > 0) {
  console.log(`\n❌ STRUCTURAL OR SCHEMA ERRORS DETECTED (${missingFields.length}):`);
  console.log(missingFields.slice(0, 10).join('\n'));
} else {
  console.log(`✅ Zero schema or missing field violations! Schema structural integrity is perfect.`);
}

console.log(`\n==============================================`);

if (duplicates.length > 0 || missingFields.length > 0 || invalidOrders.length > 0) {
  process.exit(1);
} else {
  console.log(`🏆 CONGRATULATIONS: Sentence Order Reading curriculum is 100% PERFECT!`);
  process.exit(0);
}
