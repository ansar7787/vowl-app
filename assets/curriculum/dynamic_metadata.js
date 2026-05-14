const fs = require('fs');
const path = require('path');
const categories = ['accent', 'elite_mastery', 'grammar', 'listening', 'reading', 'roleplay', 'speaking', 'writing'];
const basePath = 'assets/curriculum';

function hashCode(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash) + str.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash);
}

const hintIntros = ['Listen closely', 'Pay attention', 'Focus carefully', 'Make sure', 'Concentrate', 'Be sure', 'Take care', 'Always check', 'Remember'];
const hintMiddles = ['to the audio', 'to the spoken words', 'to what is being said', 'to the track', 'to the sentence', 'to the context', 'to the structure'];
const hintActions = ['and compare it to the text.', 'to see if it matches.', 'and check for accuracy.', 'to find discrepancies.', 'to identify any differences.', 'and verify the statement.'];

const explainIntros = ['Identifying', 'Recognizing', 'Finding', 'Discovering', 'Spotting', 'Understanding', 'Mastering'];
const explainMiddles = ['discrepancies', 'differences', 'mismatches', 'errors', 'variations'];
const explainActions = ['improves listening accuracy.', 'builds audio comprehension.', 'enhances focus.', 'strengthens your ear.', 'boosts fluency.'];

function getWord(list, hash) { return list[hash % list.length]; }

function generateDynamicHint(interactionType, h) {
  if (interactionType === 'Static Filter' || interactionType.includes('Audio') || interactionType.includes('Sound')) {
    return getWord(hintIntros, h) + ' ' + getWord(hintMiddles, h+1) + ' ' + getWord(hintActions, h+2);
  } else if (interactionType === 'Voice Toggle' || interactionType.includes('Grammar') || interactionType.includes('Tense')) {
    const grammIntros = ['Focus on', 'Pay attention to', 'Look at', 'Examine', 'Check'];
    const grammMiddles = ['the subject', 'the verb', 'the action', 'who receives the action', 'the sentence structure'];
    const grammActions = ['to switch voices.', 'to find the correct form.', 'to choose the right answer.', 'to understand the context.'];
    return getWord(grammIntros, h) + ' ' + getWord(grammMiddles, h+1) + ' ' + getWord(grammActions, h+2);
  } else if (interactionType === 'Dialog Tree' || interactionType.includes('Roleplay') || interactionType.includes('Scene')) {
    const roleIntros = ['Consider', 'Think about', 'Reflect on', 'Analyze', 'Evaluate'];
    const roleMiddles = ['the tone', 'the context', 'the situation', 'the relationship', "the speaker's intent"];
    const roleActions = ['before responding.', 'to choose the best reply.', 'to select the appropriate answer.'];
    return getWord(roleIntros, h) + ' ' + getWord(roleMiddles, h+1) + ' ' + getWord(roleActions, h+2);
  } else {
    const defIntros = ['Review', 'Analyze', 'Check', 'Read', 'Examine'];
    const defMiddles = ['the context', 'the details', 'the provided text', 'the sentence', 'the words'];
    const defActions = ['carefully.', 'to determine the best answer.', 'to find the correct option.', 'closely.'];
    return getWord(defIntros, h) + ' ' + getWord(defMiddles, h+1) + ' ' + getWord(defActions, h+2);
  }
}

function generateDynamicExplanation(interactionType, h) {
  if (interactionType === 'Static Filter' || interactionType.includes('Audio') || interactionType.includes('Sound')) {
    return getWord(explainIntros, h) + ' ' + getWord(explainMiddles, h+1) + ' ' + getWord(explainActions, h+2);
  } else if (interactionType === 'Voice Toggle' || interactionType.includes('Grammar') || interactionType.includes('Tense')) {
    const gIntros = ['Mastering', 'Understanding', 'Practicing', 'Learning', 'Recognizing'];
    const gMiddles = ['active and passive voice', 'sentence structure', 'grammar rules', 'verb forms'];
    const gActions = ['strengthens flexibility.', 'builds sentence variety.', 'improves fluency.', 'enhances writing skills.'];
    return getWord(gIntros, h) + ' ' + getWord(gMiddles, h+1) + ' ' + getWord(gActions, h+2);
  } else if (interactionType === 'Dialog Tree' || interactionType.includes('Roleplay') || interactionType.includes('Scene')) {
    const rIntros = ['Selecting', 'Choosing', 'Picking', 'Identifying', 'Finding'];
    const rMiddles = ['the appropriate response', 'the best reply', 'the right words', 'the correct tone'];
    const rActions = ['builds communication skills.', 'improves practical fluency.', 'enhances conversational abilities.'];
    return getWord(rIntros, h) + ' ' + getWord(rMiddles, h+1) + ' ' + getWord(rActions, h+2);
  } else {
    const dIntros = ['Practicing', 'Mastering', 'Improving', 'Developing', 'Refining'];
    const dMiddles = ['this specific skill', 'your comprehension', 'your vocabulary', 'your reading speed'];
    const dActions = ['reinforces language accuracy.', 'boosts overall fluency.', 'helps with daily communication.'];
    return getWord(dIntros, h) + ' ' + getWord(dMiddles, h+1) + ' ' + getWord(dActions, h+2);
  }
}

let modifiedCount = 0;

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
            
            const h = hashCode(q.id);
            const newHint = generateDynamicHint(q.interactionType, h);
            const newExp = generateDynamicExplanation(q.interactionType, h);
            
            if (q.hint !== newHint || q.explanation !== newExp) {
               q.hint = newHint;
               q.explanation = newExp;
               modified = true;
               modifiedCount++;
            }
          });
          if (modified) fs.writeFileSync(filePath, JSON.stringify(data, null, 4));
        } catch(e) {}
      } else if (fs.statSync(filePath).isDirectory()) { walkSync(filePath); }
    });
  }
  walkSync(catPath);
});

console.log('Dynamic hints and explanations applied. Modified:', modifiedCount);
