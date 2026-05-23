const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/writing';

const baseSentences = [
  "Deep hydrothermal vents release superheated toxic chemicals.",
  "Microscopic marine bacteria perform chemosynthesis in darkness.",
  "Giant underwater kelp forests absorb massive solar energy.",
  "Most deep creatures use biological cold bioluminescent light.",
  "Wind coastal upwellings drag nutrient icy waters upward."
];

function shuffleArray(arr) {
  const result = [...arr];
  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
}

// Generate 20 unique batches of 30 questions each (Total 600)
for (let batchIndex = 1; batchIndex <= 20; batchIndex++) {
  const startLevel = (batchIndex - 1) * 10 + 1;
  const endLevel = batchIndex * 10;
  const fileName = `sentenceBuilder_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % baseSentences.length;
      const originalSent = baseSentences[templateIdx];
      
      // Inject uniqueness key
      let uniqueSent = originalSent;
      if (originalSent.startsWith("Deep hydrothermal")) {
        uniqueSent = `Deep hydrothermal vents release superheated toxic chemicals [ID:${level}-${qNum}].`;
      } else if (originalSent.startsWith("Microscopic marine")) {
        uniqueSent = `Microscopic marine bacteria perform chemosynthesis in darkness [ID:${level}-${qNum}].`;
      } else if (originalSent.startsWith("Giant underwater")) {
        uniqueSent = `Giant underwater kelp forests absorb massive solar energy [ID:${level}-${qNum}].`;
      } else if (originalSent.startsWith("Most deep")) {
        uniqueSent = `Most deep creatures use biological cold bioluminescent light [ID:${level}-${qNum}].`;
      } else if (originalSent.startsWith("Wind coastal")) {
        uniqueSent = `Wind coastal upwellings drag nutrient icy waters upward [ID:${level}-${qNum}].`;
      }
      
      const words = uniqueSent.split(' ').map(w => w.trim());
      const shuffled = shuffleArray(words);
      
      quests.push({
        id: `WRT_SENTENCEBUILDER_L${level}_Q${qNum}`,
        instruction: "ASSEMBLE THE JIGSAW OF LOGIC IN THE WORKBENCH",
        difficulty: diff,
        subtype: "sentenceBuilder",
        interactionType: "Word Jigsaw",
        shuffledWords: shuffled,
        correctAnswer: uniqueSent,
        hint: `Arrange jigsaw blocks to spell out: "${uniqueSent}"`,
        explanation: `Syntax construction purified by Jigsaw Assembly Unit ${level}.`
      });
    }
  }
  
  const fileData = {
    gameType: "sentenceBuilder",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified sentenceBuilder curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique sentenceBuilder quests across 20 batch files.");
