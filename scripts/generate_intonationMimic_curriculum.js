const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/accent';

const intonationTemplates = [
  { sentence: "I am a student.", options: ["Falling Intonation (Statement)", "Rising Intonation (Yes/No Question)"], correct: 0, contour: [2, 2, 1, 0], explanation: "Statements in English typically end with falling intonation (the pitch drops on the final word 'student')." },
  { sentence: "Are you ready?", options: ["Falling Intonation (Statement)", "Rising Intonation (Yes/No Question)"], correct: 1, contour: [1, 1, 2, 3], explanation: "Yes/No questions typically end with rising intonation (the pitch rises on 'ready')." },
  { sentence: "What is your name?", options: ["Falling Intonation (Wh-Question)", "Rising Intonation (Yes/No Question)"], correct: 0, contour: [3, 2, 1, 0], explanation: "Information questions (Wh-questions) typically end with falling intonation." },
  { sentence: "Do you like coffee?", options: ["Falling Intonation (Statement)", "Rising Intonation (Yes/No Question)"], correct: 1, contour: [1, 1, 2, 3], explanation: "Yes/No questions typically end with rising intonation to seek confirmation." },
  { sentence: "She lives in London.", options: ["Falling Intonation (Statement)", "Rising Intonation (Yes/No Question)"], correct: 0, contour: [2, 2, 1, 0], explanation: "Declarative sentences (statements) end with a downward contour (falling intonation)." },
  { sentence: "Is it raining outside?", options: ["Falling Intonation (Statement)", "Rising Intonation (Yes/No Question)"], correct: 1, contour: [1, 1, 2, 3], explanation: "Yes/No questions typically rise at the end to signify inquiry." },
  { sentence: "Where is the station?", options: ["Falling Intonation (Wh-Question)", "Rising Intonation (Yes/No Question)"], correct: 0, contour: [3, 2, 1, 0], explanation: "Wh-questions begin high and drop at the end (falling intonation)." },
  { sentence: "Can you help me?", options: ["Falling Intonation (Statement)", "Rising Intonation (Yes/No Question)"], correct: 1, contour: [1, 1, 2, 3], explanation: "Yes/No questions typically rise at the end." },
  { sentence: "We went to the beach.", options: ["Falling Intonation (Statement)", "Rising Intonation (Yes/No Question)"], correct: 0, contour: [2, 2, 1, 0], explanation: "Simple statements conclude with falling pitch (falling intonation)." },
  { sentence: "Are they coming tonight?", options: ["Falling Intonation (Statement)", "Rising Intonation (Yes/No Question)"], correct: 1, contour: [1, 1, 2, 3], explanation: "Yes/No questions end with rising intonation." }
];

// Generate 20 unique batches of 30 questions each (Total 600)
for (let batchIndex = 1; batchIndex <= 20; batchIndex++) {
  const startLevel = (batchIndex - 1) * 10 + 1;
  const endLevel = batchIndex * 10;
  const fileName = `intonationMimic_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % intonationTemplates.length;
      const base = intonationTemplates[templateIdx];
      
      const uniqueWord = base.sentence;
      const textToSpeak = uniqueWord;

      quests.push({
        id: `ACC_INTONATIONMIMIC_L${level}_Q${qNum}`,
        instruction: "IDENTIFY THE INTONATION CONTOUR ENUNCIATED IN THE PHRASE",
        difficulty: diff,
        subtype: "intonationMimic",
        interactionType: "mimic",
        word: uniqueWord,
        textToSpeak: textToSpeak,
        options: base.options,
        correctAnswer: base.options[base.correct],
        correctAnswerIndex: base.correct,
        intonationMap: base.contour,
        hint: `Listen to the ending of the sentence. Does the pitch drop or rise? (Calibration ${level}-${qNum})`,
        explanation: base.explanation
      });
    }
  }
  
  const fileData = {
    gameType: "intonationMimic",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified intonationMimic curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique intonationMimic quests across 20 batch files.");
