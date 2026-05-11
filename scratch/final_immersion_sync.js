
const fs = require('fs');

const MODULE_CONFIG = {
  flashcards: { it: "flip", painter: "CouncilHallSync", fields: ["word", "correctAnswer"] },
  topicVocab: { it: "sort", painter: "VocabNexusSync", fields: ["word", "options", "correctAnswer"] },
  wordFormation: { it: "lab", painter: "ArchiveDecryptSync", fields: ["rootWord", "options", "correctAnswer"] },
  prefixSuffix: { it: "tree", painter: "ArchiveDecryptSync", fields: ["rootWord", "options", "correctAnswer"] },
  synonymSearch: { it: "lens", painter: "PurgeGridSync", fields: ["word", "options", "correctAnswer"] },
  antonymSearch: { it: "mirror", painter: "PurgeGridSync", fields: ["word", "options", "correctAnswer"] },
  contextClues: { it: "rub", painter: "BlueprintGridSync", fields: ["sentence", "options", "correctAnswer"] },
  academicWord: { it: "radar", painter: "SonarScanSync", fields: ["passage", "word"] },
  collocations: { it: "chain", painter: "MechanicalLinkSync", fields: ["word", "options", "correctAnswer"] },
  phrasalVerbs: { it: "bubbles", painter: "MagneticFieldSync", fields: ["word", "options", "correctAnswer"] },
  idioms: { it: "echo", painter: "SemanticAuraSync", fields: ["word", "topicEmoji", "options", "correctAnswer"] },
  contextualUsage: { it: "slot", painter: "ValidatorMatrixSync", fields: ["word", "options", "correctAnswerIndex"] }
};

const ROOTS = ["analyze", "concept", "data", "evidence", "factor", "global", "hypothesis", "interpret", "justice", "knowledge", "logic", "method", "network", "objective", "perspective", "quality", "research", "source", "theory", "unique"];
const TEMPLATES = [
  "The primary {W} of the study was {C}.",
  "We must {W} the underlying {C}.",
  "A critical {W} in this {C} is required.",
  "Environmental {W} impacts the {C} significantly.",
  "The {W} structure remains {C} throughout.",
  "Scientists {W} how {C} influences results.",
  "His {W} approach to {C} was impressive.",
  "Without {W}, the {C} cannot be solved.",
  "The {W} framework supports the {C}.",
  "Evaluating {W} leads to better {C}."
];

function generateModule(name, config) {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        const tier = i < 200 ? 1 : (i < 400 ? 2 : 3);
        const root = ROOTS[i % ROOTS.length];
        const template = TEMPLATES[i % TEMPLATES.length];
        const unique = `_id${i}`;

        const q = {
            id: `VOC_${name.toUpperCase()}_L${Math.floor(i/3)+1}_Q${(i%3)+1}`,
            instruction: `${name.toUpperCase()} MISSION`,
            difficulty: tier,
            subtype: name,
            interactionType: config.it,
            visual_config: { 
                painter_type: config.painter, 
                primary_color: tier === 1 ? "0xFF00BCD4" : (tier === 2 ? "0xFF9C27B0" : "0xFFFF5722"),
                pulse_intensity: 1.0
            }
        };

        if (config.fields.includes("word")) q.word = root.toUpperCase() + unique;
        if (config.fields.includes("rootWord")) q.rootWord = root.toUpperCase();
        if (config.fields.includes("sentence")) q.sentence = template.replace("{W}", root.toUpperCase()).replace("{C}", "contextual pattern " + i);
        if (config.fields.includes("passage")) q.passage = template.replace("{W}", root).replace("{C}", "academic stream " + i);
        if (config.fields.includes("topicEmoji")) q.topicEmoji = "✨";
        if (config.fields.includes("options")) {
            q.options = [root.toUpperCase(), "DISTRACT_A", "DISTRACT_B", "DISTRACT_C"].sort(() => Math.random() - 0.5);
        }
        if (config.fields.includes("correctAnswer")) q.correctAnswer = root.toUpperCase();
        if (config.fields.includes("correctAnswerIndex")) q.correctAnswerIndex = q.options.indexOf(root.toUpperCase());

        quests.push(q);
    }
    return quests;
}

Object.keys(MODULE_CONFIG).forEach(mod => {
    const data = generateModule(mod, MODULE_CONFIG[mod]);
    for (let b = 1; b <= 20; b++) {
        const start = (b - 1) * 10 + 1;
        const end = b * 10;
        const batch = data.filter(q => {
            const level = parseInt(q.id.split('_L')[1].split('_Q')[0]);
            return level >= start && level <= end;
        });
        fs.writeFileSync(`c:/Users/asus/Documents/App Projects/vowl/assets/curriculum/vocabulary/${mod}_${start}_${end}.json`, JSON.stringify({ gameType: mod, batchIndex: b, levels: `${start}-${end}`, quests: batch }, null, 2));
    }
});

console.log("FINAL IMMERSION SYNC COMPLETE: All 12 modules linked to specialized Game Chamber backgrounds.");
