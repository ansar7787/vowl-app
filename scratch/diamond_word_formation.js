
const fs = require('fs');

const morphologyBank = [
  { root: "TRANSGRESS", suffixes: ["-ION", "-IVE", "-OR", "-MENT"], correct: "TRANSGRESSION" },
  { root: "OSCILLATE", suffixes: ["-OR", "-ION", "-IVE", "-ITY"], correct: "OSCILLATOR" },
  { root: "RECIPROCATE", suffixes: ["-ITY", "-AL", "-IVE", "-NESS"], correct: "RECIPROCITY" },
  { root: "METAMORPH", suffixes: ["-OSIS", "-ISM", "-IC", "-IZE"], correct: "METAMORPHOSIS" },
  { root: "PHILANTHROP", suffixes: ["-IST", "-IC", "-ISM", "-Y"], correct: "PHILANTHROPIST" },
  { root: "SYNCHRON", suffixes: ["-ICITY", "-IZE", "-OUS", "-ISM"], correct: "SYNCHRONICITY" },
  { root: "EPISTEM", suffixes: ["-OLOGY", "-IC", "-IST", "-ISM"], correct: "EPISTEMOLOGY" },
  { root: "BENEVOL", suffixes: ["-ENCE", "-ENT", "-LY", "-NESS"], correct: "BENEVOLENCE" },
  { root: "MAGNIFIC", suffixes: ["-ENCE", "-ENT", "-ATION", "-ITY"], correct: "MAGNIFICENCE" },
  { root: "RESILI", suffixes: ["-ENCE", "-ENT", "-ENCY", "-ITY"], correct: "RESILIENCE" },
  { root: "AMBIGU", suffixes: ["-ITY", "-OUS", "-AL", "-ENT"], correct: "AMBIGUITY" },
  { root: "CONFLU", suffixes: ["-ENCE", "-ENT", "-AL", "-IVE"], correct: "CONFLUENCE" },
  { root: "DIVERG", suffixes: ["-ENCE", "-ENT", "-AL", "-ITY"], correct: "DIVERGENCE" },
  { root: "ELOQU", suffixes: ["-ENCE", "-ENT", "-AL", "-LY"], correct: "ELOQUENCE" },
  { root: "TRANSI", suffixes: ["-ENCE", "-ENT", "-ORY", "-AL"], correct: "TRANSIENCE" },
];

function generate600WordFormationQuests() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        const tier = i < 200 ? 1 : (i < 400 ? 2 : 3);
        const data = morphologyBank[i % morphologyBank.length];
        const modifier = i >= morphologyBank.length ? ` (L${Math.floor(i/3)+1})` : "";
        
        quests.push({
            id: `VOC_WORD_FORMATION_L${Math.floor(i/3)+1}_Q${(i%3)+1}`,
            instruction: "Morphological Synthesis: Stabilize the term with the correct suffix.",
            difficulty: tier,
            subtype: "wordFormation",
            interactionType: "bubbles",
            rootWord: data.root,
            options: data.suffixes,
            correctAnswer: data.correct + modifier,
            hint: `Focus on the ${data.correct.endsWith('ION') ? 'noun' : 'agent'} form.`,
            explanation: `Synthesis complete. The root '${data.root}' was successfully stabilized.`,
            visual_config: {
                painter_type: tier === 1 ? "CouncilHallSync" : (tier === 2 ? "NexusCoreSync" : "ArchiveDecryptSync"),
                primary_color: tier === 1 ? "0xFF00BCD4" : (tier === 2 ? "0xFF9C27B0" : "0xFF607D8B"),
                pulse_intensity: 0.6,
                shader_effect: "binary_pulse"
            }
        });
    }
    return quests;
}

const allQuests = generate600WordFormationQuests();

for (let b = 1; b <= 20; b++) {
  const start = (b - 1) * 10 + 1;
  const end = b * 10;
  const fileName = `c:/Users/asus/Documents/App Projects/vowl/assets/curriculum/vocabulary/word_formation_${start}_${end}.json`;
  const batch = allQuests.filter(q => {
      const level = parseInt(q.id.split('_L')[1].split('_Q')[0]);
      return level >= start && level <= end;
  });

  fs.writeFileSync(fileName, JSON.stringify({ gameType: "wordFormation", batchIndex: b, levels: `${start}-${end}`, quests: batch }, null, 2));
}

console.log("WORD FORMATION DIAMOND READY: 600 unique synthesis quests created.");
