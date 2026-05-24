const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, '..', 'assets', 'curriculum');

let totalFilesProcessed = 0;
let totalQuestsProcessed = 0;
let whitespaceFixesCount = 0;
let duplicateOptionsFixedCount = 0;

const fillDistractors = ["Standard", "Typicality", "Ordinary", "Conformity", "Regularity", "Usualness", "Commonness", "Piquant", "Flavorful", "Tangy"];

function repairQuest(q, filePath, idx) {
  totalQuestsProcessed++;

  // 1. Recursive Trim of all string values in the quest
  const recurseTrim = (obj, keyPath) => {
    if (typeof obj === 'string') {
      const trimmed = obj.trim();
      if (trimmed !== obj) {
        whitespaceFixesCount++;
      }
      return trimmed;
    } else if (Array.isArray(obj)) {
      return obj.map((item, i) => recurseTrim(item, `${keyPath}[${i}]`));
    } else if (obj && typeof obj === 'object') {
      const newObj = {};
      Object.keys(obj).forEach(k => {
        newObj[k] = recurseTrim(obj[k], `${keyPath}.${k}`);
      });
      return newObj;
    }
    return obj;
  };

  // Run the recursive trimmer
  const repaired = recurseTrim(q, 'quest');
  Object.assign(q, repaired);

  // 2. Safely resolve duplicate options if present
  if (q.options && Array.isArray(q.options)) {
    const seen = new Set();
    const duplicatesIndices = [];
    q.options.forEach((opt, oIdx) => {
      const norm = opt.toLowerCase().trim();
      if (seen.has(norm)) {
        duplicatesIndices.push(oIdx);
      } else {
        seen.add(norm);
      }
    });

    if (duplicatesIndices.length > 0) {
      // We have duplicate options! Let's resolve them.
      duplicatesIndices.forEach(dupIdx => {
        const originalVal = q.options[dupIdx];
        
        // We only replace if the duplicate index is NOT the correct answer index
        if (q.correctAnswerIndex !== undefined && q.correctAnswerIndex === dupIdx) {
          // The duplicate index is actually marked correct!
          // So we should find the other occurrence of this string and change THAT one instead!
          const firstOccurIdx = q.options.findIndex(x => x.toLowerCase().trim() === originalVal.toLowerCase().trim());
          if (firstOccurIdx !== -1 && firstOccurIdx !== dupIdx) {
            // Modify the first occurrence instead of the correct index
            q.options[firstOccurIdx] = getDistinctDistractor(q.options);
            duplicateOptionsFixedCount++;
          }
        } else {
          // It is a distractor, we can change it directly!
          q.options[dupIdx] = getDistinctDistractor(q.options);
          duplicateOptionsFixedCount++;
        }
      });
    }
  }
}

function getDistinctDistractor(existingOptions) {
  const normalizedExisting = existingOptions.map(x => x.toLowerCase().trim());
  for (const candidate of fillDistractors) {
    if (!normalizedExisting.includes(candidate.toLowerCase())) {
      return candidate;
    }
  }
  return `AlternativeChoice_${Math.floor(Math.random() * 1000)}`;
}

function processFile(filePath, category) {
  totalFilesProcessed++;
  const raw = fs.readFileSync(filePath, 'utf8');
  let data;
  try {
    data = JSON.parse(raw);
  } catch (e) {
    console.error(`Skipping invalid JSON file: ${filePath}`);
    return;
  }

  let isModified = false;
  
  if (category === 'kids') {
    if (Array.isArray(data)) {
      data.forEach(levelObj => {
        if (levelObj.quests && Array.isArray(levelObj.quests)) {
          levelObj.quests.forEach(q => repairQuest(q, filePath));
          isModified = true;
        }
      });
    }
  } else {
    if (data.quests && Array.isArray(data.quests)) {
      data.quests.forEach((q, idx) => repairQuest(q, filePath, idx));
      isModified = true;
    }
  }

  if (isModified) {
    // Write back the beautiful repaired JSON
    fs.writeFileSync(filePath, JSON.stringify(data, null, 4), 'utf8');
  }
}

function traverseAndRepair(dir, category = "") {
  const items = fs.readdirSync(dir);
  items.forEach(item => {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      const nextCategory = dir.toLowerCase() === baseDir.toLowerCase() ? item : category;
      traverseAndRepair(fullPath, nextCategory);
    } else if (item.endsWith('.json')) {
      processFile(fullPath, category);
    }
  });
}

console.log("Starting full automated curriculum database repair...");
traverseAndRepair(baseDir);
console.log("====================================================");
console.log(`Database Repair Summary:`);
console.log(`Total Files Checked          : ${totalFilesProcessed}`);
console.log(`Total Quests Audited         : ${totalQuestsProcessed}`);
console.log(`Whitespace Trims Applied     : ${whitespaceFixesCount}`);
console.log(`Duplicate Choices Resolved   : ${duplicateOptionsFixedCount}`);
console.log("====================================================");
