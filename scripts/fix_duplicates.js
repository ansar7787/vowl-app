const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/grammar';
const files = fs.readdirSync(basePath).filter(f => f.startsWith('voiceSwap_') && !f.includes('191_200'));

const replacements = {
  "vs_l127_q3": {
    q: "If she bakes the cake, it will be eaten.",
    o: ["The cake will be eaten if it is baked by her.", "The cake is eaten if it baked by her.", "The cake will eat if she bakes it.", "If she is baked, the cake will be eaten."],
    c: 0,
    h: "Future conditional passive."
  },
  "vs_l127_q2": {
    q: "The documents had been being processed.",
    o: ["They had been processing the documents.", "They have been processing the documents.", "They processed the documents.", "They were processing the documents."],
    c: 0,
    h: "Past perfect continuous active."
  },
  "vs_l140_q1": {
    q: "If the lock hadn't been being picked, the alarm wouldn't have sounded.",
    o: ["If someone hadn't been picking the lock, the alarm wouldn't have sounded.", "If someone hasn't been picking the lock, the alarm wouldn't have sounded.", "If someone hadn't picked the lock, the alarm wouldn't have sounded.", "If someone wasn't picking the lock, the alarm wouldn't have sounded."],
    c: 0,
    h: "Third conditional continuous active."
  },
  "vs_l139_q1": {
    q: "I remember my mother teaching me to read.",
    o: ["I remember being taught to read by my mother.", "I remember to be taught to read by my mother.", "I remember been taught to read by my mother.", "I remember teaching to read by my mother."],
    c: 0,
    h: "Gerund passive."
  },
  "vs_l144_q2": {
    q: "They were seen painting the mural.",
    o: ["Someone saw them painting the mural.", "Someone was seeing them painting the mural.", "Someone has seen them painting the mural.", "Someone sees them painting the mural."],
    c: 0,
    h: "Active form of 'were seen'."
  },
  "vs_l149_q1": {
    q: "The vault must have been being guarded.",
    o: ["Someone must have been guarding the vault.", "Someone must be guarding the vault.", "Someone must have guarded the vault.", "Someone must guard the vault."],
    c: 0,
    h: "Active form of modal perfect continuous passive."
  },
  "vs_l189_q1": {
    q: "She hates people staring at her.",
    o: ["She hates being stared at.", "She hates been stared at.", "She hates to be stared at.", "She hates staring at."],
    c: 0,
    h: "Gerund passive."
  },
  "vs_l30_q1": {
    q: "The mechanics will fix the engine.",
    o: ["The engine will be fixed by the mechanics.", "The engine will be fix by the mechanics.", "The engine is fixed by the mechanics.", "The mechanics will be fixed by the engine."],
    c: 0,
    h: "Future passive."
  },
  "vs_l29_q2": {
    q: "I have submitted the report.",
    o: ["The report has been submitted by me.", "The report have been submitted by me.", "The report was submitted by me.", "The report is being submitted by me."],
    c: 0,
    h: "Present perfect passive."
  },
  "vs_l59_q2": {
    q: "She could have finished the painting.",
    o: ["The painting could have been finished by her.", "The painting could have finish by her.", "The painting could had been finished by her.", "The painting could be finished by her."],
    c: 0,
    h: "Modal perfect passive."
  },
  "vs_l98_q1": {
    q: "He expects to be chosen.",
    o: ["He expects someone to choose him.", "He expects someone choosing him.", "He expected someone to choose him.", "He expects someone to chose him."],
    c: 0,
    h: "Active form with infinitive."
  }
};

for (const f of files) {
  const filePath = path.join(basePath, f);
  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  let modified = false;

  for (let q of data.quests) {
    if (replacements[q.id]) {
      const rep = replacements[q.id];
      q.question = rep.q;
      q.options = rep.o;
      q.correctAnswerIndex = rep.c;
      q.hint = rep.h;
      modified = true;
      console.log(`Replaced ${q.id} in ${f}`);
    }
  }

  if (modified) {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
  }
}
console.log("Done fixing duplicates.");
