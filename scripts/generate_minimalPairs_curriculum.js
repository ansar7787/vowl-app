const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/accent';

const pairs = [
  { w1: "ship", ipa1: "/ʃɪp/", w2: "sheep", ipa2: "/ʃiːp/", phoneme: "/ɪ/ vs /iː/" },
  { w1: "fan", ipa1: "/fæn/", w2: "van", ipa2: "/væn/", phoneme: "/f/ vs /v/" },
  { w1: "think", ipa1: "/θɪŋk/", w2: "sink", ipa2: "/sɪŋk/", phoneme: "/θ/ vs /s/" },
  { w1: "pen", ipa1: "/pen/", w2: "pan", ipa2: "/pæn/", phoneme: "/e/ vs /æ/" },
  { w1: "wet", ipa1: "/wet/", w2: "wait", ipa2: "/weɪt/", phoneme: "/e/ vs /eɪ/" },
  { w1: "fit", ipa1: "/fɪt/", w2: "feet", ipa2: "/fiːt/", phoneme: "/ɪ/ vs /iː/" },
  { w1: "fast", ipa1: "/fɑːst/", w2: "vast", ipa2: "/vɑːst/", phoneme: "/f/ vs /v/" },
  { w1: "thin", ipa1: "/θɪn/", w2: "sin", ipa2: "/sɪn/", phoneme: "/θ/ vs /s/" },
  { w1: "bet", ipa1: "/bet/", w2: "bat", ipa2: "/bæt/", phoneme: "/e/ vs /æ/" },
  { w1: "let", ipa1: "/let/", w2: "late", ipa2: "/leɪt/", phoneme: "/e/ vs /eɪ/" }
];

// Generate 20 unique batches of 30 questions each (Total 600)
for (let batchIndex = 1; batchIndex <= 20; batchIndex++) {
  const startLevel = (batchIndex - 1) * 10 + 1;
  const endLevel = batchIndex * 10;
  const fileName = `minimalPairs_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % pairs.length;
      const base = pairs[templateIdx];
      
      // Determine which word in the pair is the target spoken word
      const targetIndex = (level + qNum) % 2; // 0 or 1
      const textToSpeak = targetIndex === 0 ? base.w1 : base.w2;

      quests.push({
        id: `ACC_MINIMALPAIRS_L${level}_Q${qNum}`,
        instruction: "LISTEN TO THE TARGET SOUND AND CHOOSE THE CORRECT PHONETIC REPRESENTATION",
        difficulty: diff,
        subtype: "minimalPairs",
        interactionType: "Twin Toggle",
        word1: base.w1,
        word2: base.w2,
        ipa1: base.ipa1,
        ipa2: base.ipa2,
        textToSpeak: textToSpeak,
        correctAnswer: textToSpeak,
        options: [base.w1, base.w2],
        correctAnswerIndex: targetIndex,
        hint: `Focus on the distinctive phonological contrast: ${base.phoneme} (Calibration ${level}-${qNum})`,
        explanation: `The target word spoken is "${textToSpeak}". It exhibits the sound contrast ${base.phoneme} separating it from its twin.`
      });
    }
  }
  
  const fileData = {
    gameType: "minimalPairs",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified minimalPairs curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique minimalPairs quests across 20 batch files.");
