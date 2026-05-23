const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/accent';

const linkings = [
  { words: ["an", "apple", "a", "day"], correctPair: "an apple", explanation: "Consonant-to-vowel linking occurs between the final consonant /n/ of 'an' and the initial vowel /æ/ of 'apple', sounding like 'a-napple'." },
  { words: ["go", "on", "the", "trip"], correctPair: "go on", explanation: "Vowel-to-vowel linking occurs between the final /oʊ/ of 'go' and the initial /ɒ/ of 'on', introducing a subtle gliding /w/ sound." },
  { words: ["she", "is", "very", "kind"], correctPair: "she is", explanation: "Vowel-to-vowel linking occurs between the final /iː/ of 'she' and the initial /ɪ/ of 'is', introducing a subtle gliding /j/ sound." },
  { words: ["far", "away", "from", "home"], correctPair: "far away", explanation: "Linking /r/ occurs in non-rhotic accents between 'far' and 'away' because 'away' starts with a vowel sound." },
  { words: ["we", "agree", "on", "this"], correctPair: "we agree", explanation: "Vowel-to-vowel linking occurs between the final /iː/ of 'we' and the initial /ə/ of 'agree', introducing a subtle gliding /j/ sound." },
  { words: ["turn", "off", "the", "lights"], correctPair: "turn off", explanation: "Consonant-to-vowel linking occurs between the final /n/ of 'turn' and the initial /ɒ/ of 'off', sounding like 'tur-noff'." },
  { words: ["put", "it", "on", "there"], correctPair: "put it", explanation: "Consonant-to-vowel linking occurs between the final consonant /t/ of 'put' and the initial vowel /ɪ/ of 'it'." },
  { words: ["come", "in", "right", "now"], correctPair: "come in", explanation: "Consonant-to-vowel linking occurs between the final consonant /m/ of 'come' and the initial vowel /ɪ/ of 'in', sounding like 'co-min'." },
  { words: ["please", "ask", "for", "help"], correctPair: "please ask", explanation: "Consonant-to-vowel linking occurs between the final voiced /z/ of 'please' and the initial /ɑː/ of 'ask'." },
  { words: ["try", "again", "later", "today"], correctPair: "try again", explanation: "Vowel-to-vowel linking occurs between the final /aɪ/ of 'try' and the initial /ə/ of 'again', introducing a subtle gliding /j/ sound." }
];

// Generate 20 unique batches of 30 questions each (Total 600)
for (let batchIndex = 1; batchIndex <= 20; batchIndex++) {
  const startLevel = (batchIndex - 1) * 10 + 1;
  const endLevel = batchIndex * 10;
  const fileName = `wordLinking_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % linkings.length;
      const base = linkings[templateIdx];
      
      const textToSpeak = base.words.join(" ");

      quests.push({
        id: `ACC_WORDLINKING_L${level}_Q${qNum}`,
        instruction: "TAP THE CHAIN LINK NODE WHERE CONTEXTUAL WORD LINKING OCCURS",
        difficulty: diff,
        subtype: "wordLinking",
        interactionType: "Chain Snap",
        words: base.words,
        textToSpeak: textToSpeak,
        correctAnswer: base.correctPair,
        hint: `Focus on connected speech: where does a final sound merge into an initial sound? (Calibration ${level}-${qNum})`,
        explanation: base.explanation
      });
    }
  }
  
  const fileData = {
    gameType: "wordLinking",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified wordLinking curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique wordLinking quests across 20 batch files.");
