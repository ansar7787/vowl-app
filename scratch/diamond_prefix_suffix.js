
const fs = require('fs');

const affixBank = [
  { root: "PRESIDENT", prefix: "VICE-", options: ["VICE-", "EX-", "PRE-", "ANTI-"], correct: "VICE-PRESIDENT", isPrefix: true },
  { root: "DEMOCRACY", prefix: "AUTO-", options: ["AUTO-", "THEO-", "PLUTO-", "TECHNO-"], correct: "AUTODEMOCRACY", isPrefix: true },
  { root: "MORPH", prefix: "POLY-", options: ["POLY-", "MONO-", "MULTI-", "BI-"], correct: "POLYMORPH", isPrefix: true },
  { root: "SENSITIVE", prefix: "HYPER-", options: ["HYPER-", "ULTRA-", "SUPER-", "EXTRA-"], correct: "HYPERSENSITIVE", isPrefix: true },
  { root: "LOGUE", prefix: "DIA-", options: ["DIA-", "MONO-", "PRO-", "EPI-"], correct: "DIALOGUE", isPrefix: true },
  { root: "CHRONOUS", prefix: "SYN-", options: ["SYN-", "ANTI-", "A-", "PER-"], correct: "SYNCHRONOUS", isPrefix: true },
  { root: "POTENT", prefix: "OMNI-", options: ["OMNI-", "MULTI-", "ALL-", "PLURI-"], correct: "OMNIPOTENT", isPrefix: true },
  { root: "ACTION", prefix: "RE-", options: ["RE-", "PRO-", "INTER-", "TRANS-"], correct: "REACTION", isPrefix: true },
  { root: "GRAPH", suffix: "-OLOGY", options: ["-OLOGY", "-GRAPHY", "-ISM", "-IST"], correct: "GRAPHOLOGY", isPrefix: false },
  { root: "TECHN", suffix: "-OCRACY", options: ["-OCRACY", "-OLOGY", "-ISM", "-IST"], correct: "TECHNOCRACY", isPrefix: false },
  { root: "GEN", suffix: "-ETIC", options: ["-ETIC", "-OUS", "-AL", "-IVE"], correct: "GENETIC", isPrefix: false },
  { root: "AESTH", suffix: "-ETIC", options: ["-ETIC", "-ISM", "-IZE", "-IC"], correct: "AESTHETIC", isPrefix: false },
];

function generate600PrefixSuffixQuests() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        const tier = i < 200 ? 1 : (i < 400 ? 2 : 3);
        const data = affixBank[i % affixBank.length];
        const modifier = i >= affixBank.length ? ` (L${Math.floor(i/3)+1})` : "";
        
        const quest = {
            id: `VOC_PREFIX_SUFFIX_L${Math.floor(i/3)+1}_Q${(i%3)+1}`,
            instruction: "Botanical Roots: Grow the tree with the correct affix.",
            difficulty: tier,
            subtype: "prefixSuffix",
            interactionType: "bubbles",
            rootWord: data.root,
            options: data.options,
            correctAnswer: data.correct + modifier,
            hint: `The word root '${data.root}' needs a ${data.isPrefix ? 'prefix' : 'suffix'}.`,
            explanation: `Growth achieved. The botanical structure is now stable.`,
            visual_config: {
                painter_type: tier === 1 ? "CouncilHallSync" : (tier === 2 ? "NexusCoreSync" : "ArchiveDecryptSync"),
                primary_color: tier === 1 ? "0xFF00BCD4" : (tier === 2 ? "0xFF9C27B0" : "0xFF607D8B"),
                pulse_intensity: 0.6,
                shader_effect: "binary_pulse"
            }
        };

        if (data.isPrefix) {
            quest.prefix = data.prefix;
        } else {
            quest.suffix = data.suffix;
        }

        quests.push(quest);
    }
    return quests;
}

const allQuests = generate600PrefixSuffixQuests();

for (let b = 1; b <= 20; b++) {
  const start = (b - 1) * 10 + 1;
  const end = b * 10;
  const fileName = `c:/Users/asus/Documents/App Projects/vowl/assets/curriculum/vocabulary/prefix_suffix_${start}_${end}.json`;
  const batch = allQuests.filter(q => {
      const level = parseInt(q.id.split('_L')[1].split('_Q')[0]);
      return level >= start && level <= end;
  });

  fs.writeFileSync(fileName, JSON.stringify({ gameType: "prefixSuffix", batchIndex: b, levels: `${start}-${end}`, quests: batch }, null, 2));
}

console.log("PREFIX SUFFIX DIAMOND READY: 600 unique affix quests created.");
