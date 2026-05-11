const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/grammar';
const files = fs.readdirSync(basePath).filter(f => f.endsWith('.json') && !f.startsWith('wordReorder_'));

let sentences = new Set();
for (const f of files) {
  const filePath = path.join(basePath, f);
  let data;
  try {
    data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch(e) { continue; }
  
  if (!data.quests) continue;
  
  for (const q of data.quests) {
    let text = "";
    if (q.sentence) text = q.sentence;
    else if (q.question && !q.question.includes('Convert') && !q.question.includes('Arrange') && !q.question.includes('Select') && !q.question.includes('Identify')) text = q.question;
    else if (q.correctAnswer && typeof q.correctAnswer === 'string') text = q.correctAnswer;
    else if (q.options && q.options.length > 0 && typeof q.options[0] === 'string') text = q.options[0];
    
    if (text) {
      let clean = text.replace(/[.,!?";()]/g, '').toLowerCase().trim();
      let words = clean.split(/\s+/);
      if (words.length >= 4 && words.length <= 10) {
        sentences.add(clean);
      }
    }
  }
}

// Convert to array
let sentenceArray = Array.from(sentences);
// Shuffle
sentenceArray.sort(() => Math.random() - 0.5);

if (sentenceArray.length < 600) {
  console.log("Not enough unique sentences found! Found: " + sentenceArray.length);
  // Add some fallback words if needed but it should find plenty.
} else {
  console.log("Found " + sentenceArray.length + " unique sentences. Selecting 600.");
  sentenceArray = sentenceArray.slice(0, 600);
}

const VISUALS = [
  { painter: 'NeuralNegotiationSync', color: '0xFF00FFCC' },
  { painter: 'DataLogSync', color: '0xFF03A9F4' },
  { painter: 'ArchiveDecryptSync', color: '0xFF9E9E9E' },
  { painter: 'CouncilHallSync', color: '0xFFFFFFFF' },
  { painter: 'PurgeGridSync', color: '0xFFF44336' },
  { painter: 'NeuralNegotiationSync', color: '0xFFFFD700' }
];

function getDifficulty(level) {
  if (level <= 40) return 1;
  if (level <= 80) return 2;
  if (level <= 120) return 3;
  if (level <= 160) return 4;
  return 5;
}

const BATCH_SIZE = 10;
const QUESTIONS_PER_LEVEL = 3;
let globalIndex = 0;

for (let batch = 0; batch < 20; batch++) {
  const startLevel = batch * BATCH_SIZE + 1;
  const endLevel = (batch + 1) * BATCH_SIZE;
  const fileName = `wordReorder_${startLevel}_${endLevel}.json`;
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = getDifficulty(level);
    for (let q = 1; q <= QUESTIONS_PER_LEVEL; q++) {
      let cleanSentence = sentenceArray[globalIndex];
      globalIndex++;
      
      let words = cleanSentence.split(/\s+/);
      let shuffled = [...words].sort(() => Math.random() - 0.5);
      // Ensure it's actually shuffled
      if (shuffled.join(' ') === cleanSentence) {
        shuffled.reverse();
      }
      
      const visual = VISUALS[(level + q) % VISUALS.length];
      
      quests.push({
        id: `wr_l${level}_q${q}`,
        instruction: "Reorder the words to form a correct sentence.",
        difficulty: diff,
        subtype: "wordReorder",
        interactionType: "word_reorder",
        question: `Arrange: ${shuffled.join(' / ')}`,
        options: words,
        correctAnswer: cleanSentence,
        hint: "Start with the subject.",
        explanation: "Standard sentence structure.",
        xpReward: level * 2,
        coinReward: level * 4,
        visual_config: {
          painter_type: visual.painter,
          primary_color: visual.color
        }
      });
    }
  }
  
  const fileData = {
    gameType: "wordReorder",
    batchIndex: batch + 1,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated ${fileName}`);
}

console.log("All 600 unique wordReorder quests generated.");
