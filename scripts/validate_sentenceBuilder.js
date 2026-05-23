const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/writing');
const files = fs.readdirSync(dir).filter(f => f.startsWith('sentenceBuilder_') && f.endsWith('.json'));

console.log(`Found ${files.length} Sentence Builder curriculum files. Beginning audits...\n`);

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
  
  if (data.gameType !== 'sentenceBuilder') {
    missingFields.push(`Incorrect gameType in ${file}: expected 'sentenceBuilder', got '${data.gameType}'`);
  }
  
  if (!data.quests || !Array.isArray(data.quests)) {
    missingFields.push(`Missing or invalid quests array in ${file}`);
    return;
  }
  
  data.quests.forEach(q => {
    totalQuestsCount++;
    
    // Check required fields
    const required = ["id", "instruction", "difficulty", "subtype", "interactionType", "shuffledWords", "correctAnswer", "hint", "explanation"];
    required.forEach(field => {
      if (q[field] === undefined || q[field] === null || q[field] === '') {
        missingFields.push(`Missing field '${field}' in quest ${q.id || 'unknown'} inside ${file}`);
      }
    });
    
    // Verify shuffledWords contain exactly all words in correctAnswer
    if (q.shuffledWords && q.correctAnswer) {
      if (!Array.isArray(q.shuffledWords)) {
        missingFields.push(`shuffledWords is not an array in quest ${q.id} inside ${file}`);
      } else {
        const correctWords = q.correctAnswer.split(' ').map(w => w.trim());
        const sortedCorrect = [...correctWords].sort();
        const sortedShuffled = [...q.shuffledWords].sort();
        
        if (JSON.stringify(sortedCorrect) !== JSON.stringify(sortedShuffled)) {
          invalidOptions.push(`shuffledWords mismatch in quest ${q.id} in ${file}:\nExpected: [${sortedCorrect.join(', ')}]\nGot: [${sortedShuffled.join(', ')}]`);
        }
      }
    }
    
    // Check passage uniqueness
    if (q.correctAnswer) {
      const normalized = q.correctAnswer.trim().toLowerCase();
      if (allPassages.has(normalized)) {
        duplicates.push(`Duplicate correctAnswer: "${q.correctAnswer.substring(0, 40)}..." in ${file} (Quest ID: ${q.id})`);
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
  console.log(`\n❌ WORD POOL MISMATCH DETECTED (${invalidOptions.length}):`);
  console.log(invalidOptions.slice(0, 5).join('\n'));
} else {
  console.log(`✅ Zero word pool mismatches! Every shuffledWords list matches the target correctAnswer exactly.`);
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
  console.log(`🏆 CONGRATULATIONS: Sentence Builder curriculum is 100% PERFECT!`);
  process.exit(0);
}
