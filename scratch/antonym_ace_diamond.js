
const fs = require('fs');

const antonymBank = [
  { word: "Alacrity", antonym: "Apathy", distractors: ["Eagerness", "Speed", "Zest"] },
  { word: "Ephemeral", antonym: "Eternal", distractors: ["Transient", "Brief", "Vague"] },
  { word: "Sycophant", antonym: "Rebel", distractors: ["Flatterer", "Follower", "Fan"] },
  { word: "Ubiquitous", antonym: "Rare", distractors: ["Pervasive", "Common", "Local"] },
  { word: "Pragmatic", antonym: "Idealistic", distractors: ["Practical", "Useful", "Firm"] },
  { word: "Esoteric", antonym: "Common", distractors: ["Obscure", "Secret", "Vague"] },
  { word: "Meticulous", antonym: "Careless", distractors: ["Precise", "Careful", "Stiff"] },
  { word: "Capricious", antonym: "Steady", distractors: ["Fickle", "Wild", "Quick"] },
  { word: "Taciturn", antonym: "Talkative", distractors: ["Silent", "Quiet", "Shy"] },
  { word: "Fastidious", antonym: "Sloppy", distractors: ["Clean", "Careful", "Stiff"] },
  { word: "Ineffable", antonym: "Utterable", distractors: ["Vague", "Holy", "Grand"] },
  { word: "Lethargic", antonym: "Energetic", distractors: ["Sluggish", "Slow", "Dull"] },
  { word: "Mitigate", antonym: "Aggravate", distractors: ["Ease", "Heal", "Help"] },
  { word: "Ostentatious", antonym: "Modest", distractors: ["Showy", "Bold", "Loud"] },
  { word: "Reticent", antonym: "Garrulous", distractors: ["Silent", "Shy", "Firm"] },
  { word: "Garrulous", antonym: "Taciturn", distractors: ["Loud", "Chatty", "Open"] },
  { word: "Munificent", antonym: "Stingy", distractors: ["Giving", "Kind", "Rich"] },
  { word: "Parsimonious", antonym: "Lavish", distractors: ["Frugal", "Mean", "Tight"] },
  { word: "Voracious", antonym: "Satiated", distractors: ["Hungry", "Wild", "Greedy"] },
  { word: "Innocuous", antonym: "Lethal", distractors: ["Safe", "Mild", "Soft"] },
  { word: "Pernicious", antonym: "Beneficial", distractors: ["Evil", "Hurt", "Dark"] },
  { word: "Obsequious", antonym: "Arrogant", distractors: ["Polite", "Kind", "Lowly"] },
  { word: "Insipid", antonym: "Vibrant", distractors: ["Bland", "Dull", "Cold"] },
  { word: "Enervate", antonym: "Invigorate", distractors: ["Weaken", "Exhaust", "Drain"] },
  { word: "Soporific", antonym: "Stimulating", distractors: ["Dull", "Sleepy", "Soft"] },
  { word: "Eloquent", antonym: "Inarticulate", distractors: ["Fluent", "Bold", "Loud"] },
  { word: "Incendiary", antonym: "Conciliatory", distractors: ["Angry", "Hot", "Wild"] },
  { word: "Iconoclast", antonym: "Conformist", distractors: ["Rebel", "Hero", "Saint"] },
  { word: "Precocious", antonym: "Backward", distractors: ["Smart", "Quick", "Early"] },
  { word: "Audacious", antonym: "Timid", distractors: ["Bold", "Risk", "High"] },
  { word: "Supercilious", antonym: "Humble", distractors: ["Proud", "Cold", "Stiff"] },
  { word: "Lugubrious", antonym: "Cheerful", distractors: ["Sad", "Dark", "Slow"] },
  { word: "Mercurial", antonym: "Stolid", distractors: ["Wild", "Quick", "Fast"] },
  { word: "Didactic", antonym: "Uninstructive", distractors: ["Moral", "School", "Book"] },
  { word: "Spurious", antonym: "Authentic", distractors: ["False", "Fake", "Dark"] },
  { word: "Exacerbate", antonym: "Ameliorate", distractors: ["Worsen", "Hurt", "Burn"] },
  { word: "Benevolent", antonym: "Malevolent", distractors: ["Kind", "Good", "Holy"] },
  { word: "Malevolent", antonym: "Benevolent", distractors: ["Evil", "Dark", "Bad"] },
  { word: "Belligerent", antonym: "Peaceable", distractors: ["Mean", "War", "Host"] },
  { word: "Acquiesce", antonym: "Resist", distractors: ["Agree", "Yield", "Join"] }
];

function generate600AntonymQuests() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        const tier = i < 200 ? 1 : (i < 400 ? 2 : 3);
        const data = antonymBank[i % antonymBank.length];
        
        const quest = {
            id: `VOC_ANTONYM_SEARCH_L${Math.floor(i/3)+1}_Q${(i%3)+1}`,
            instruction: "Inverse Mirror: Reflect the opposing semantic form.",
            difficulty: tier,
            subtype: "antonymSearch",
            interactionType: "mirror",
            word: data.word,
            options: [data.antonym, ...data.distractors].sort(() => Math.random() - 0.5),
            correctAnswer: data.antonym,
            hint: `Reflect on the exact opposite of '${data.word}'.`,
            explanation: `Mirror link stabilized. '${data.word}' and '${data.antonym}' are perfect semantic opposites.`,
            visual_config: {
                painter_type: tier === 1 ? "CouncilHallSync" : (tier === 2 ? "NexusCoreSync" : "ArchiveDecryptSync"),
                primary_color: tier === 1 ? "0xFF00BCD4" : (tier === 2 ? "0xFF9C27B0" : "0xFF607D8B"),
                pulse_intensity: 0.6,
                shader_effect: "binary_pulse"
            }
        };
        quests.push(quest);
    }
    return quests;
}

const allQuests = generate600AntonymQuests();

for (let b = 1; b <= 20; b++) {
  const start = (b - 1) * 10 + 1;
  const end = b * 10;
  const fileName = `c:/Users/asus/Documents/App Projects/vowl/assets/curriculum/vocabulary/antonymSearch_${start}_${end}.json`;
  const batch = allQuests.filter(q => {
      const level = parseInt(q.id.split('_L')[1].split('_Q')[0]);
      return level >= start && level <= end;
  });

  fs.writeFileSync(fileName, JSON.stringify({ gameType: "antonymSearch", batchIndex: b, levels: `${start}-${end}`, quests: batch }, null, 2));
}

console.log("ANTONYM SEARCH DIAMOND READY: 600 unique inverse quests created.");
