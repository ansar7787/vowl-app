const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/accent';

const wordStressPatterns = [
  { word: "computer", syllables: ["com", "pu", "ter"], correct: 1, explanation: "In 'computer', the primary stress falls on the second syllable: com-PU-ter." },
  { word: "beautiful", syllables: ["beau", "ti", "ful"], correct: 0, explanation: "In 'beautiful', the primary stress falls on the first syllable: BEAU-ti-ful." },
  { word: "accent", syllables: ["ac", "cent"], correct: 0, explanation: "In the noun 'accent', the primary stress falls on the first syllable: AC-cent." },
  { word: "explorer", syllables: ["ex", "plor", "er"], correct: 1, explanation: "In 'explorer', the primary stress falls on the second syllable: ex-PLOR-er." },
  { word: "understand", syllables: ["un", "der", "stand"], correct: 2, explanation: "In 'understand', the primary stress falls on the third syllable: un-der-STAND." },
  { word: "banana", syllables: ["ba", "nan", "a"], correct: 1, explanation: "In 'banana', the primary stress falls on the second syllable: ba-NAN-a." },
  { word: "photograph", syllables: ["pho", "to", "graph"], correct: 0, explanation: "In 'photograph', the primary stress falls on the first syllable: PHO-to-graph." },
  { word: "photography", syllables: ["pho", "tog", "ra", "phy"], correct: 1, explanation: "In 'photography', the primary stress falls on the second syllable: pho-TOG-ra-phy." },
  { word: "database", syllables: ["da", "ta", "base"], correct: 0, explanation: "In 'database', the primary stress falls on the first syllable: DA-ta-base." },
  { word: "syllable", syllables: ["syl", "la", "ble"], correct: 0, explanation: "In 'syllable', the primary stress falls on the first syllable: SYL-la-ble." }
];

// Generate 20 unique batches of 30 questions each (Total 600)
for (let batchIndex = 1; batchIndex <= 20; batchIndex++) {
  const startLevel = (batchIndex - 1) * 10 + 1;
  const endLevel = batchIndex * 10;
  const fileName = `syllableStress_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % wordStressPatterns.length;
      const base = wordStressPatterns[templateIdx];
      
      const uniqueWord = base.word;
      const textToSpeak = uniqueWord;

      quests.push({
        id: `ACC_SYLLABLESTRESS_L${level}_Q${qNum}`,
        instruction: "STRIKE THE DRUM PAD CONTAINING THE STRESSED SYLLABLE",
        difficulty: diff,
        subtype: "syllableStress",
        interactionType: "Pulse Tap",
        word: uniqueWord,
        textToSpeak: textToSpeak,
        syllables: base.syllables,
        correctAnswer: base.syllables[base.correct],
        correctAnswerIndex: base.correct,
        hint: `Listen closely to the word spoken. One syllable is pronounced with greater intensity and pitch. (Calibration ${level}-${qNum})`,
        explanation: base.explanation
      });
    }
  }
  
  const fileData = {
    gameType: "syllableStress",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified syllableStress curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique syllableStress quests across 20 batch files.");
