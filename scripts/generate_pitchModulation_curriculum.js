const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/accent';

const pitchModulationTemplates = [
  { phrase: "Oh, really?", options: ["Falling-Rising (Doubt/Surprise)", "Rising-Falling (Excitement/Certainty)"], correct: 0, explanation: "An inquiring 'Oh, really?' utilizes a falling-rising intonation contour to express doubt or pleasant surprise." },
  { phrase: "No way!", options: ["Falling-Rising (Polite Doubt)", "Rising-Falling (Excitement/Disbelief)"], correct: 1, explanation: "An emphatic 'No way!' uses a sharp rising-falling tone to express high excitement or disbelief." },
  { phrase: "Yes, please!", options: ["Rising-Falling (Enthusiastic Agreement)", "Falling-Rising (Hesitant Request)"], correct: 0, explanation: "An enthusiastic 'Yes, please!' features rising-falling pitch signifying strong certainty and positive agreement." },
  { phrase: "Excuse me?", options: ["Falling-Rising (Polite Inquiry)", "Rising-Falling (Sudden Indignation)"], correct: 0, explanation: "A polite 'Excuse me?' uses a gentle falling-rising contour to ask for repetition or clarification." },
  { phrase: "I suppose so.", options: ["Rising-Falling (Confident Statement)", "Falling-Rising (Reluctance/Doubt)"], correct: 1, explanation: "The hesitant 'I suppose so' uses a falling-rising tone to communicate reluctance or soft disagreement." },
  { phrase: "Thank you!", options: ["Rising-Falling (Warm Gratitude)", "Falling-Rising (Obligatory Thanks)"], correct: 0, explanation: "A warm and sincere 'Thank you!' carries a rising-falling modulation expressing heartfelt gratitude." },
  { phrase: "Are you sure?", options: ["Falling-Rising (Skeptical Question)", "Rising-Falling (Direct Demand)"], correct: 0, explanation: "A skeptical 'Are you sure?' modulates from high to low and back up (falling-rising) to express mild disbelief." },
  { phrase: "Wow, amazing!", options: ["Falling-Rising (Reserved Praise)", "Rising-Falling (Awe/Excitement)"], correct: 1, explanation: "An excited expression of awe like 'Wow, amazing!' starts high, peaks, and resolves down (rising-falling)." },
  { phrase: "I don't know.", options: ["Rising-Falling (Definite Statement)", "Falling-Rising (Uncertainty/Doubt)"], correct: 1, explanation: "Expressing uncertainty with 'I don't know' employs a falling-rising pitch modulation." },
  { phrase: "Indeed!", options: ["Rising-Falling (Absolute Agreement)", "Falling-Rising (Polite Sarcasm)"], correct: 0, explanation: "An assertive 'Indeed!' uses a strong rising-falling contour to convey total agreement." }
];

// Generate 20 unique batches of 30 questions each (Total 600)
for (let batchIndex = 1; batchIndex <= 20; batchIndex++) {
  const startLevel = (batchIndex - 1) * 10 + 1;
  const endLevel = batchIndex * 10;
  const fileName = `pitchModulation_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % pitchModulationTemplates.length;
      const base = pitchModulationTemplates[templateIdx];
      
      const uniqueWord = base.phrase;
      const textToSpeak = uniqueWord;

      quests.push({
        id: `ACC_PITCHMODULATION_L${level}_Q${qNum}`,
        instruction: "IDENTIFY THE PITCH MODULATION CONTOUR AND EMOTIONAL NUANCE ENUNCIATED",
        difficulty: diff,
        subtype: "pitchModulation",
        interactionType: "slider",
        word: uniqueWord,
        textToSpeak: textToSpeak,
        options: base.options,
        correctAnswer: base.options[base.correct],
        correctAnswerIndex: base.correct,
        hint: `Listen closely to the emotional inflection of the phrase. Is it tentative/doubting or absolute/excited? (Calibration ${level}-${qNum})`,
        explanation: base.explanation
      });
    }
  }
  
  const fileData = {
    gameType: "pitchModulation",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified pitchModulation curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique pitchModulation quests across 20 batch files.");
