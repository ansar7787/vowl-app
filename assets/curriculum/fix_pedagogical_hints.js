const fs = require('fs');
const path = require('path');

const categories = ['accent', 'elite_mastery', 'grammar', 'listening', 'reading', 'roleplay', 'speaking', 'writing'];
const basePath = 'assets/curriculum';

const pedagogicalMap = {
  'Static Filter': {
    hint: 'Compare the spoken audio carefully against the written statement.',
    explanation: 'Identifying discrepancies between spoken and written text improves listening accuracy.'
  },
  'Voice Toggle': {
    hint: 'Focus on who or what receives the action to switch between active and passive voice.',
    explanation: 'Mastering active and passive voice strengthens grammatical flexibility and sentence variety.'
  },
  'Dialog Tree': {
    hint: 'Consider the tone and context of the conversation before choosing your response.',
    explanation: 'Selecting the most appropriate situational response builds practical communication skills.'
  },
  'Echo Translate': {
    hint: 'Listen to the audio and think about the direct meaning in the target language.',
    explanation: 'Translating spoken phrases directly improves bilingual processing speed.'
  },
  'Tonal Match': {
    hint: "Listen closely to the pitch and emotion behind the speaker's voice.",
    explanation: 'Recognizing tonal shifts is critical for understanding speaker intent and mood.'
  },
  'Word Jigsaw': {
    hint: 'Look at the scrambled words and find the subject and verb first.',
    explanation: 'Reconstructing sentences from scrambled words reinforces syntax and grammatical structure.'
  },
  'Balance Scale': {
    hint: 'Weigh the options and select the one that balances the sentence correctly.',
    explanation: 'Choosing the correct contextual fit enhances vocabulary precision.'
  },
  'Film Strip': {
    hint: 'Follow the sequence of events closely to determine what happens next.',
    explanation: 'Understanding narrative sequence improves reading comprehension and logic.'
  },
  'Ink Drip': {
    hint: 'Focus on the missing context and fill in the blank with the most logical word.',
    explanation: 'Using context clues to fill in missing information is key to reading fluency.'
  },
  'Slot Sorter': {
    hint: 'Identify the subject, verb, and recipient to organize the sentence correctly.',
    explanation: 'Categorizing sentence components strengthens core grammatical foundations.'
  },
  'DEFAULT': {
    hint: 'Review the provided context carefully to determine the best answer.',
    explanation: 'Practicing this skill reinforces your overall comprehension and language accuracy.'
  }
};

let fixedCount = 0;

categories.forEach(cat => {
  const catPath = path.join(basePath, cat);
  if (!fs.existsSync(catPath)) return;
  function walkSync(currentDirPath) {
    fs.readdirSync(currentDirPath).forEach(name => {
      const filePath = path.join(currentDirPath, name);
      if (fs.statSync(filePath).isFile() && filePath.endsWith('.json')) {
        let modified = false;
        try {
          const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
          let quests = [];
          if (Array.isArray(data)) {
            data.forEach(lb => { if (lb.quests) quests = quests.concat(lb.quests); });
          } else if (data.quests) {
            quests = data.quests;
          }
          quests.forEach(q => {
            if (q.interactionType === 'Spatial Radar') return;
            
            const mapping = pedagogicalMap[q.interactionType] || pedagogicalMap['DEFAULT'];
            
            if (q.hint !== mapping.hint || q.explanation !== mapping.explanation) {
               q.hint = mapping.hint;
               q.explanation = mapping.explanation;
               modified = true;
               fixedCount++;
            }
          });
          if (modified) fs.writeFileSync(filePath, JSON.stringify(data, null, 4));
        } catch(e) {}
      } else if (fs.statSync(filePath).isDirectory()) { walkSync(filePath); }
    });
  }
  walkSync(catPath);
});
console.log('Applied pedagogical hints and explanations. Total quests updated:', fixedCount);
