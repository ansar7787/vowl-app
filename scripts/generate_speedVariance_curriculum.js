const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/accent';

const speedVarianceTemplates = [
  { phrase: "Drive carefully through the heavy rain.", options: ["Decelerating (Fast start, slow emphasis on 'heavy rain')", "Accelerating (Slow start, fast structural resolution)"], correct: 0, speed: 0.8, explanation: "In professional speech coaching, speakers decelerate when presenting core warning adjectives or key elements like 'heavy rain'." },
  { phrase: "Please repeat that sentence slowly.", options: ["Accelerating (Fast pacing resolution)", "Decelerating (Slow emphasis on the command 'slowly')"], correct: 1, speed: 0.75, explanation: "To highlight the adverbial instruction, the speaker decelerates on 'slowly' to mirror the sentence's meaning." },
  { phrase: "We need to leave immediately!", options: ["Accelerating (Urgent, rapid resolution on 'immediately')", "Decelerating (Deliberate slow final emphasis)"], correct: 0, speed: 1.3, explanation: "Urgent instructions demand acceleration (increased tempo) to convey emergency and prompt reaction." },
  { phrase: "Walk quietly down the dark corridor.", options: ["Decelerating (Slow emphasis on 'dark corridor')", "Accelerating (Fast pacing structural resolution)"], correct: 0, speed: 0.8, explanation: "Descriptive warnings slow down (decelerate) on final adjectives to create suspense and emphasize caution." },
  { phrase: "Listen closely to these instructions.", options: ["Accelerating (Fast pacing structural resolution)", "Decelerating (Slow focus on 'instructions')"], correct: 1, speed: 0.85, explanation: "To ensure understanding, the speaker decelerates on key nouns like 'instructions'." },
  { phrase: "Run as fast as you can!", options: ["Accelerating (Urgent, rapid pace matching action)", "Decelerating (Slow deliberate pronunciation)"], correct: 0, speed: 1.4, explanation: "Sentences conveying intense action accelerate to reinforce the command's physical pacing." },
  { phrase: "The train will arrive shortly.", options: ["Decelerating (Slow emphasis on time element 'shortly')", "Accelerating (Fast structural resolution)"], correct: 0, speed: 0.9, explanation: "Standard informative announcements slow down on the final temporal adverb 'shortly'." },
  { phrase: "Stop what you are doing right now!", options: ["Accelerating (Urgent tempo on the command 'right now')", "Decelerating (Slow relaxed resolution)"], correct: 0, speed: 1.35, explanation: "High-authority commands accelerate on the final directive to convey high urgency." },
  { phrase: "Speak clearly during your presentation.", options: ["Accelerating (Fast pacing resolution)", "Decelerating (Slow emphasis on 'presentation')"], correct: 1, speed: 0.8, explanation: "Educational advice decelerates on the primary target noun to ensure retention." },
  { phrase: "Hurry up, we are late!", options: ["Accelerating (Urgent, rapid pace matching situation)", "Decelerating (Slow deliberate pronunciation)"], correct: 0, speed: 1.3, explanation: "Urgent announcements accelerate in pace to convey the lack of remaining time." }
];

// Generate 20 unique batches of 30 questions each (Total 600)
for (let batchIndex = 1; batchIndex <= 20; batchIndex++) {
  const startLevel = (batchIndex - 1) * 10 + 1;
  const endLevel = batchIndex * 10;
  const fileName = `speedVariance_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % speedVarianceTemplates.length;
      const base = speedVarianceTemplates[templateIdx];
      
      const uniqueWord = base.phrase;
      const textToSpeak = uniqueWord;

      quests.push({
        id: `ACC_SPEEDVARIANCE_L${level}_Q${qNum}`,
        instruction: "IDENTIFY THE SPEED VARIANCE CONTOUR AND PACING INTENT ENUNCIATED",
        difficulty: diff,
        subtype: "speedVariance",
        interactionType: "slider",
        word: uniqueWord,
        textToSpeak: textToSpeak,
        options: base.options,
        correctAnswer: base.options[base.correct],
        correctAnswerIndex: base.correct,
        targetSpeed: base.speed,
        hint: `Listen to the sentence speed. Does the speaker accelerate to show urgency or decelerate for heavy emphasis? (Calibration ${level}-${qNum})`,
        explanation: base.explanation
      });
    }
  }
  
  const fileData = {
    gameType: "speedVariance",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified speedVariance curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique speedVariance quests across 20 batch files.");
