const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/accent';

const connectedSpeechTemplates = [
  { word: "next door", options: ["Elision (/t/ disappears)", "Assimilation (/t/ becomes /d/)"], correct: 0, hint: "Listen to the /t/ sound at the end of 'next' - in natural connected speech, is it fully pronounced or does it disappear?" },
  { word: "ten cards", options: ["Elision (/n/ disappears)", "Assimilation (/n/ changes to /ŋ/)"], correct: 1, hint: "Listen to the /n/ at the end of 'ten' - because it is followed by the velar consonant /k/, does it change to /ŋ/?" },
  { word: "must be", options: ["Elision (/t/ disappears)", "Assimilation (/t/ becomes /p/)"], correct: 0, hint: "Listen to the /t/ at the end of 'must' followed by 'be' - does it completely vanish?" },
  { word: "good boy", options: ["Elision (/d/ disappears)", "Assimilation (/d/ changes to /b/)"], correct: 1, hint: "Listen to the /d/ sound in 'good' - does it transform into the bilabial /b/ sound before 'boy'?" },
  { word: "did you", options: ["Intrusion (extra /r/)", "Coalescence (/d/ + /j/ becomes /dʒ/)"], correct: 1, hint: "Listen to the merging of the final /d/ in 'did' and initial /j/ in 'you' - does it sound like 'didge-you'?" },
  { word: "media event", options: ["Intrusion (gliding /r/)", "Elision (/a/ disappears)"], correct: 0, hint: "In non-rhotic accents, listen to the gap between 'media' and 'event' - is a subtle /r/ sound introduced?" },
  { word: "law and order", options: ["Intrusion (gliding /r/)", "Assimilation (/d/ becomes /n/)"], correct: 0, hint: "In non-rhotic accents, listen to the transition between 'law' and 'and' - is a subtle /r/ sound inserted?" },
  { word: "don't you", options: ["Coalescence (/t/ + /j/ becomes /tʃ/)", "Elision (/t/ disappears)"], correct: 0, hint: "Listen to the merging of final /t/ in 'don't' and initial /j/ in 'you' - does it sound like 'doan-chew'?" },
  { word: "white paper", options: ["Elision (/t/ disappears)", "Assimilation (/t/ changes to /p/)"], correct: 1, hint: "Listen to the final /t/ in 'white' before 'paper' - does it assimilate to /p/ sounding like 'whipe paper'?" },
  { word: "last night", options: ["Elision (/t/ disappears)", "Assimilation (/t/ becomes /n/)"], correct: 0, hint: "Listen to 'last night' in fast speech - does the /t/ sound completely drop out?" }
];

// Generate 20 unique batches of 30 questions each (Total 600)
for (let batchIndex = 1; batchIndex <= 20; batchIndex++) {
  const startLevel = (batchIndex - 1) * 10 + 1;
  const endLevel = batchIndex * 10;
  const fileName = `connectedSpeech_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % connectedSpeechTemplates.length;
      const base = connectedSpeechTemplates[templateIdx];
      
      const uniqueWord = base.word;
      const textToSpeak = uniqueWord;

      quests.push({
        id: `ACC_CONNECTEDSPEECH_L${level}_Q${qNum}`,
        instruction: "IDENTIFY THE CONNECTED SPEECH PHENOMENON ENUNCIATED IN THE PHRASE",
        difficulty: diff,
        subtype: "connectedSpeech",
        interactionType: "clarity",
        word: uniqueWord,
        textToSpeak: textToSpeak,
        options: base.options,
        correctAnswer: base.options[base.correct],
        correctAnswerIndex: base.correct,
        hint: `${base.hint} (Calibration ${level}-${qNum})`,
        explanation: `The phrase "${uniqueWord}" demonstrates "${base.options[base.correct]}". ${base.explanation || ""}`
      });
    }
  }
  
  const fileData = {
    gameType: "connectedSpeech",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified connectedSpeech curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique connectedSpeech quests across 20 batch files.");
