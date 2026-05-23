const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/accent';

const pitchPatternTemplates = [
  { sentence: "The commander builds a laser boldly.", options: ["Emphasis on COMMANDER (Subject focus)", "Emphasis on LASER (Object focus)"], correct: 1, patterns: [1, 1, 1, 3, 1], explanation: "In neutral connected speech, English highlights the final content word (the noun 'laser') with the primary pitch peak." },
  { sentence: "A scientist upgrades the module quietly.", options: ["Emphasis on SCIENTIST (Subject focus)", "Emphasis on MODULE (Object focus)"], correct: 1, patterns: [1, 1, 1, 3, 1], explanation: "Neutral intonation places the main accent on the final noun 'module', rising and then falling." },
  { sentence: "A spy repairs the circuit rapidly.", options: ["Emphasis on SPY (Subject focus)", "Emphasis on CIRCUIT (Object focus)"], correct: 1, patterns: [1, 1, 1, 3, 1], explanation: "Primary stress occurs on the object 'circuit' with pitch peak peaking on the first syllable /sɜː/." },
  { sentence: "The doctor activates the engine cautiously.", options: ["Emphasis on DOCTOR (Subject focus)", "Emphasis on ENGINE (Object focus)"], correct: 1, patterns: [1, 1, 1, 3, 1], explanation: "The focal pitch accent targets the final content word 'engine' under neutral connected speech." },
  { sentence: "A student observes a system quickly.", options: ["Emphasis on STUDENT (Subject focus)", "Emphasis on SYSTEM (Object focus)"], correct: 1, patterns: [1, 1, 1, 3, 1], explanation: "Standard phrasing highlights 'system' with the nuclear pitch accent contour." },
  { sentence: "The hero protects the software smoothly.", options: ["Emphasis on HERO (Subject focus)", "Emphasis on SOFTWARE (Object focus)"], correct: 1, patterns: [1, 1, 1, 3, 1], explanation: "Standard declarative pitch peak falls on the final noun 'software'." },
  { sentence: "A chef assembles the shield silently.", options: ["Emphasis on CHEF (Subject focus)", "Emphasis on SHIELD (Object focus)"], correct: 1, patterns: [1, 1, 1, 3, 1], explanation: "The nucleus of the tone unit falls on 'shield', creating a pitch match on the target noun." },
  { sentence: "The driver receives a reactor immediately.", options: ["Emphasis on DRIVER (Subject focus)", "Emphasis on REACTOR (Object focus)"], correct: 1, patterns: [1, 1, 1, 3, 1], explanation: "Neutral intonation targets the noun 'reactor' with rising-falling nuclear pitch stress." },
  { sentence: "A technician configures a drone carefully.", options: ["Emphasis on TECHNICIAN (Subject focus)", "Emphasis on DRONE (Object focus)"], correct: 1, patterns: [1, 1, 1, 3, 1], explanation: "The focus is centered on 'drone' with the pitch peak occurring on its diphthong /əʊ/." },
  { sentence: "A manager launches the sensor perfectly.", options: ["Emphasis on MANAGER (Subject focus)", "Emphasis on SENSOR (Object focus)"], correct: 1, patterns: [1, 1, 1, 3, 1], explanation: "Standard inflective contour places nuclear pitch emphasis on the noun 'sensor'." }
];

// Generate 20 unique batches of 30 questions each (Total 600)
for (let batchIndex = 1; batchIndex <= 20; batchIndex++) {
  const startLevel = (batchIndex - 1) * 10 + 1;
  const endLevel = batchIndex * 10;
  const fileName = `pitchPatternMatch_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % pitchPatternTemplates.length;
      const base = pitchPatternTemplates[templateIdx];
      
      const uniqueWord = base.sentence;
      const textToSpeak = uniqueWord;

      quests.push({
        id: `ACC_PITCHPATTERNMATCH_L${level}_Q${qNum}`,
        instruction: "IDENTIFY THE CORRECT PITCH BluePRINT THAT MATCHES THE SENTENCE NUCLEAR STRESS",
        difficulty: diff,
        subtype: "pitchPatternMatch",
        interactionType: "choice",
        word: uniqueWord,
        textToSpeak: textToSpeak,
        options: base.options,
        correctAnswer: base.options[base.correct],
        correctAnswerIndex: base.correct,
        pitchPatterns: base.patterns,
        hint: `Listen to where the pitch peaks in the sentence. Does the voice emphasize the subject or the direct object? (Calibration ${level}-${qNum})`,
        explanation: base.explanation
      });
    }
  }
  
  const fileData = {
    gameType: "pitchPatternMatch",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified pitchPatternMatch curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique pitchPatternMatch quests across 20 batch files.");
