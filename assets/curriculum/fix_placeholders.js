const fs = require('fs');
const path = require('path');

const subjects = ["The engineer", "A scientist", "The commander", "A pilot", "The technician", "An explorer", "The droid", "A student", "The analyst", "A manager", "The hero", "A robot", "The traveler", "A doctor", "The teacher", "A researcher", "The detective", "A spy", "The driver", "A chef"];
const verbs = ["builds", "monitors", "repairs", "analyzes", "creates", "activates", "observes", "protects", "receives", "sends", "discovers", "investigates", "operates", "navigates", "evaluates", "upgrades", "assembles", "launches", "configures", "tests"];
const pastVerbs = ["built", "monitored", "repaired", "analyzed", "created", "activated", "observed", "protected", "received", "sent", "discovered", "investigated", "operated", "navigated", "evaluated", "upgraded", "assembled", "launched", "configured", "tested"];
const objects = ["the circuit", "a system", "the data", "a reactor", "the module", "the portal", "the signal", "the archive", "a drone", "the database", "the engine", "a spaceship", "the software", "a machine", "the network", "the shield", "a satellite", "the sensor", "a laser", "the battery"];
const adverbs = ["quickly", "carefully", "efficiently", "silently", "successfully", "immediately", "accurately", "cautiously", "perfectly", "rapidly", "steadily", "quietly", "smoothly", "flawlessly", "swiftly", "safely", "cleverly", "boldly", "wisely", "gently"];
const adjectives = ["red", "blue", "large", "small", "heavy", "light", "fast", "slow", "bright", "dark", "shiny", "dull", "hot", "cold", "loud", "quiet", "sharp", "smooth", "rough", "soft"];

function seededRandom(seed) {
  let x = Math.sin(seed++) * 10000;
  return x - Math.floor(x);
}

function getWord(list, index) {
  return list[index % list.length];
}

function generateSentence(idHash) {
  const s = getWord(subjects, idHash);
  const v = getWord(verbs, Math.floor(idHash / subjects.length));
  const o = getWord(objects, Math.floor(idHash / (subjects.length * verbs.length)));
  const a = getWord(adverbs, Math.floor(idHash / (subjects.length * verbs.length * objects.length)));
  return `${s} ${v} ${o} ${a}.`;
}

function generatePassiveAnswer(idHash) {
  const s = getWord(subjects, idHash);
  const v = getWord(pastVerbs, Math.floor(idHash / subjects.length));
  const o = getWord(objects, Math.floor(idHash / (subjects.length * verbs.length)));
  const a = getWord(adverbs, Math.floor(idHash / (subjects.length * verbs.length * objects.length)));
  
  const passiveSubject = o.charAt(0).toUpperCase() + o.slice(1);
  return `${passiveSubject} is ${v} by ${s.toLowerCase()} ${a}.`;
}

function generateOptions(baseIndex) {
  const ops = [];
  for(let i=0; i<4; i++) {
    ops.push(getWord(objects, baseIndex + i * 7));
  }
  return ops;
}

const interactionFixers = {
  "Voice Toggle": (q, idHash) => {
    q.sentence = generateSentence(idHash);
    q.correctAnswer = generatePassiveAnswer(idHash);
  },
  "Spatial Radar": (q, idHash) => {
    q.textToSpeak = `Attention passengers, the flight to ${getWord(['New York', 'London', 'Tokyo', 'Paris', 'Berlin'], idHash)} is boarding at gate ${idHash % 100}.`;
    q.options = ["Train Station", "Airport", "Library", "Shopping Mall"];
    q.correctAnswerIndex = 1;
    q.location = "Airport";
  },
  "Dialog Tree": (q, idHash) => {
    q.scene = `Meeting ${idHash % 100}`;
    q.roleName = `Colleague ${idHash % 50}`;
    q.options = [
      `Hello, I am fine ${idHash}.`,
      `I disagree with this plan.`,
      `Let's proceed carefully.`
    ];
    q.correctAnswerIndex = idHash % 3;
    q.instruction = "Choose the best response";
  },
  "Echo Translate": (q, idHash) => {
    q.textToSpeak = generateSentence(idHash);
    q.sentence = generateSentence(idHash);
    q.translation = generatePassiveAnswer(idHash);
  },
  // Default text replacements for anything missing
  "DEFAULT": (q, idHash) => {
    if (q.textToSpeak) q.textToSpeak = generateSentence(idHash);
    if (q.sentence) q.sentence = generateSentence(idHash);
    if (q.passage) q.passage = `This is passage number ${idHash}. ${generateSentence(idHash)}`;
    if (q.story) q.story = `Story ${idHash}. ${generateSentence(idHash)}`;
    if (q.prompt) q.prompt = `Prompt ${idHash}: ${generateSentence(idHash)}`;
    if (q.idiom) q.idiom = `Idiom ${idHash}`;
    if (q.meaning) q.meaning = `Meaning ${idHash}`;
    if (q.options && q.options.length > 0) {
      const len = q.options.length;
      q.options = [];
      for(let i=0; i<len; i++) q.options.push(`Option ${idHash}_${i}`);
    }
    if (q.correctAnswer) q.correctAnswer = `Correct ${idHash}`;
    if (q.sampleAnswer) q.sampleAnswer = `Sample ${idHash}`;
    if (q.shuffledWords) q.shuffledWords = generateSentence(idHash).split(' ');
  }
};

const categories = ['accent', 'elite_mastery', 'grammar', 'listening', 'reading', 'roleplay', 'speaking', 'writing'];
const basePath = 'assets/curriculum';

function hashCode(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash |= 0;
  }
  return Math.abs(hash);
}

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
            if (idx === 0 && quests.length > 1) return; // Leave the first one as template maybe, actually no let's fix all to make them unique
            const idHash = hashCode(q.id);
            const fixer = interactionFixers[q.interactionType] || interactionFixers["DEFAULT"];
            fixer(q, idHash);
            modified = true;
          });
          
          if (modified) {
            fs.writeFileSync(filePath, JSON.stringify(data, null, 4));
          }
        } catch(e) {
          console.log(e);
        }
      } else if (fs.statSync(filePath).isDirectory()) {
        walkSync(filePath);
      }
    });
  }
  walkSync(catPath);
});

console.log("Procedural Generation Complete.");
