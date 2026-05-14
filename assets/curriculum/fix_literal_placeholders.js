const fs = require('fs');
const path = require('path');

const subjects = ["The engineer", "A scientist", "The commander", "A pilot", "The technician", "An explorer", "The droid", "A student", "The analyst", "A manager", "The hero", "A robot", "The traveler", "A doctor", "The teacher", "A researcher", "The detective", "A spy", "The driver", "A chef"];
const verbs = ["builds", "monitors", "repairs", "analyzes", "creates", "activates", "observes", "protects", "receives", "sends", "discovers", "investigates", "operates", "navigates", "evaluates", "upgrades", "assembles", "launches", "configures", "tests"];
const objects = ["the circuit", "a system", "the data", "a reactor", "the module", "the portal", "the signal", "the archive", "a drone", "the database", "the engine", "a spaceship", "the software", "a machine", "the network", "the shield", "a satellite", "the sensor", "a laser", "the battery"];
const adverbs = ["quickly", "carefully", "efficiently", "silently", "successfully", "immediately", "accurately", "cautiously", "perfectly", "rapidly", "steadily", "quietly", "smoothly", "flawlessly", "swiftly", "safely", "cleverly", "boldly", "wisely", "gently"];
const adjectives = ["red", "blue", "large", "small", "heavy", "light", "fast", "slow", "bright", "dark", "shiny", "dull", "hot", "cold", "loud", "quiet", "sharp", "smooth", "rough", "soft"];
const nouns = ["device", "tool", "screen", "button", "lever", "switch", "cable", "lens", "gear", "wheel", "key", "lock", "code", "map", "plan", "goal", "task", "job", "mission", "quest"];

function getWord(list, index) { return list[index % list.length]; }

function generateSentence(idHash) {
  const s = getWord(subjects, idHash);
  const v = getWord(verbs, Math.floor(idHash / subjects.length));
  const o = getWord(objects, Math.floor(idHash / (subjects.length * verbs.length)));
  const a = getWord(adverbs, Math.floor(idHash / (subjects.length * verbs.length * objects.length)));
  return s + ' ' + v + ' ' + o + ' ' + a + '.';
}

function generateParagraph(idHash) {
  return generateSentence(idHash) + ' ' + generateSentence(idHash + 1) + ' ' + generateSentence(idHash + 2);
}

function generateIdiom(idHash) {
  return getWord(adjectives, idHash) + ' as a ' + getWord(nouns, idHash + 1);
}

const interactionFixers = {
  'DEFAULT': (q, idHash) => {
    if (q.textToSpeak) q.textToSpeak = generateSentence(idHash);
    if (q.sentence) q.sentence = generateSentence(idHash);
    if (q.passage) q.passage = generateParagraph(idHash);
    if (q.story) q.story = generateParagraph(idHash);
    if (q.prompt) q.prompt = generateSentence(idHash);
    if (q.idiom) q.idiom = generateIdiom(idHash);
    if (q.meaning) q.meaning = 'It means to be very ' + getWord(adjectives, idHash) + ' and ' + getWord(adverbs, idHash) + '.';
    if (q.options && q.options.length > 0) {
      for(let i=0; i<q.options.length; i++) {
        q.options[i] = getWord(adjectives, idHash + i) + ' ' + getWord(nouns, idHash + i);
      }
    }
    if (q.correctAnswer && typeof q.correctAnswer === 'string') {
      if (q.options && q.options.length > 0) {
        q.correctAnswer = q.options[q.correctAnswerIndex || 0];
      } else {
        q.correctAnswer = generateSentence(idHash + 5);
      }
    }
    if (q.sampleAnswer) q.sampleAnswer = generateSentence(idHash + 3);
    if (q.shuffledWords) q.shuffledWords = generateSentence(idHash).replace('.','').split(' ').sort((a,b) => (idHash % 3) - 1);
  }
};

function hashCode(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash |= 0;
  }
  return Math.abs(hash);
}

const categories = ['accent', 'elite_mastery', 'grammar', 'listening', 'reading', 'roleplay', 'speaking', 'writing'];
const basePath = 'assets/curriculum';

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
            data.forEach(levelBlock => {
              if (levelBlock.quests) quests = quests.concat(levelBlock.quests);
            });
          } else if (data.quests) {
            quests = data.quests;
          }
          quests.forEach((q, idx) => {
            const idHash = hashCode(q.id);
            if (q.interactionType !== 'Voice Toggle' && q.interactionType !== 'Spatial Radar' && q.interactionType !== 'Dialog Tree' && q.interactionType !== 'Echo Translate') {
              interactionFixers['DEFAULT'](q, idHash);
              modified = true;
            }
          });
          if (modified) fs.writeFileSync(filePath, JSON.stringify(data, null, 4));
        } catch(e) {}
      } else if (fs.statSync(filePath).isDirectory()) {
        walkSync(filePath);
      }
    });
  }
  walkSync(catPath);
});
console.log('Fixed literal placeholders.');
