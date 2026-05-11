const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/grammar';

function shuffle(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
}

const subjects = [
    "Lex", "Mira", "The Archivist", "The droid", "The scouts", "The council", "The signal", "The core", "The Void", "The Hub",
    "A sentinel", "The pilot", "The engineer", "The traveler", "The merchant", "The guard", "The leader", "The team", "The group", "Everyone",
    "Someone", "No one", "Each scout", "Neither droid", "Both pilots", "The assembly", "The technician", "The bot", "The relay", "The reactor",
    "The commander", "The citizen", "The explorer", "The scholar", "The builder", "The hunter", "The observer", "The keeper", "The shadow", "The light",
    "The storm", "The wind", "The energy", "The resource", "The data", "The record", "The map", "The key", "The relic", "The artifact",
    "The bridge", "The tower", "The gate", "The station", "The port", "The lab", "The foundry", "The mine", "The forest", "The desert"
];

const contexts = [
    "in the Hub", "near the Void", "inside the station", "at the foundry", "during the storm", "before the dawn", "after the breach", "across the bridge", "under the stars", "within the sector",
    "on the relay", "past the gate", "through the portal", "behind the console", "between the cores", "among the droids", "against the wind", "by the reactor", "into the deep", "out of the shadows",
    "for the council", "with the team", "without the map", "about the anomaly", "like a sentinel", "as a leader", "toward the light", "from the archive", "onto the platform", "along the path"
];

function purifyModule(gameType, generatorFn) {
    const allQuests = generatorFn();
    for (let batch = 0; batch < 20; batch++) {
        const startLevel = batch * 10 + 1;
        const endLevel = (batch + 1) * 10;
        const fileName = `${gameType}_${startLevel}_${endLevel}.json`;
        const filePath = path.join(basePath, fileName);
        
        const batchQuests = allQuests.slice(batch * 30, (batch + 1) * 30);
        batchQuests.forEach((q, idx) => {
            const level = startLevel + Math.floor(idx / 3);
            const qNum = (idx % 3) + 1;
            q.id = `${gameType.charAt(0)}${gameType.charAt(gameType.length-1)}_l${level}_q${qNum}`.toLowerCase().replace('ee', 'wr').replace('tn', 'tm').replace('sn', 'sc'); 
            // Manual prefix mapping for better ID consistency
            const prefixMap = {
                'sentenceCorrection': 'sc',
                'prepositionChoice': 'pc',
                'conditionals': 'cd',
                'conjunctions': 'cj',
                'modifierPlacement': 'mp',
                'questionFormatter': 'qf',
                'subjectVerbAgreement': 'sv',
                'tenseMastery': 'tm',
                'punctuationMastery': 'pm',
                'prepositionChoice': 'pc'
            };
            q.id = `${prefixMap[gameType] || 'g'}_l${level}_q${qNum}`;
            q.xpReward = level * 2;
            q.coinReward = level * 4;
            const visuals = ["SentinelGridSync", "CommandTerminalSync", "VoidPunctuationSync"];
            q.visual_config = { painter_type: visuals[idx % 3], primary_color: "0xFFFFFFFF" };
        });

        const fileData = {
            gameType: gameType,
            batchIndex: batch + 1,
            levels: `${startLevel}-${endLevel}`,
            quests: batchQuests
        };
        fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
    }
    console.log(`Successfully purified ${gameType}`);
}

// Generators
const sentenceCorrectionGen = () => {
    const quests = [];
    let count = 0;
    const rules = [
        { c: (s, ctx) => `${s} finds the key ${ctx}.`, w: (s, ctx) => [`${s} find the key ${ctx}.`, `${s} finding the key ${ctx}.`, `${s} finded the key ${ctx}.`], h: "Third-person singular." },
        { c: (s, ctx) => `${s} is ready ${ctx}.`, w: (s, ctx) => [`${s} are ready ${ctx}.`, `${s} am ready ${ctx}.`, `${s} be ready ${ctx}.`], h: "Subject-verb agreement." },
        { c: (s, ctx) => `${s} hasn't seen the data ${ctx}.`, w: (s, ctx) => [`${s} haven't seen the data ${ctx}.`, `${s} no see the data ${ctx}.`, `${s} hasn't see the data ${ctx}.`], h: "Present perfect negative." },
        { c: (s, ctx) => `${s} went ${ctx} yesterday.`, w: (s, ctx) => [`${s} goes ${ctx} yesterday.`, `${s} have gone ${ctx} yesterday.`, `${s} go ${ctx} yesterday.`], h: "Past tense." },
        { c: (s, ctx) => `${s} will arrive ${ctx} soon.`, w: (s, ctx) => [`${s} arrived ${ctx} soon.`, `${s} arrives ${ctx} soon.`, `${s} arriving ${ctx} soon.`], h: "Future tense." }
    ];

    for (let i = 0; i < 60; i++) {
        for (let j = 0; j < 10; j++) {
            const rule = rules[count % rules.length];
            const s = subjects[i % subjects.length];
            const ctx = contexts[j % contexts.length];
            const options = shuffle([rule.c(s, ctx), ...rule.w(s, ctx)]);
            quests.push({
                instruction: "Correct the sentence.",
                difficulty: 1,
                subtype: "sentenceCorrection",
                interactionType: "choice",
                question: "Which sentence is grammatically correct?",
                options: options,
                correctAnswerIndex: options.indexOf(rule.c(s, ctx)),
                hint: rule.h,
                explanation: "Correct grammar application."
            });
            count++;
        }
    }
    return quests;
};

const prepositionChoiceGen = () => {
    const quests = [];
    const preps = ["in", "on", "at", "by", "from", "to", "with", "about", "for", "during"];
    for (let i = 0; i < 60; i++) {
        for (let j = 0; j < 10; j++) {
            const s = subjects[i % subjects.length];
            const ctx = contexts[j % contexts.length].split(' ')[0]; // use as verb/action context
            const correctPrep = preps[(i + j) % preps.length];
            const others = preps.filter(p => p !== correctPrep).slice(0, 3);
            const sentence = `${s} is working [____] the sector ${j}.`.replace('[____]', correctPrep); // placeholder
            
            const options = shuffle([correctPrep, ...others]);
            quests.push({
                instruction: "Choose the correct preposition.",
                difficulty: 1,
                subtype: "prepositionChoice",
                interactionType: "choice",
                question: `${s} is working ____ the sector.`,
                options: options,
                correctAnswerIndex: options.indexOf(correctPrep),
                hint: "Think about the spatial relationship.",
                explanation: "Standard preposition usage."
            });
        }
    }
    return quests;
};

const conditionalsGen = () => {
    const quests = [];
    for (let i = 0; i < 60; i++) {
        for (let j = 0; j < 10; j++) {
            const s = subjects[i % subjects.length];
            const types = [
                { if: `If ${s} finds the key`, then: "he will open the gate.", w: ["he would open the gate.", "he opens the gate.", "he will opening the gate."], h: "First conditional." },
                { if: `If ${s} found the key`, then: "he would open the gate.", w: ["he will open the gate.", "he would opened the gate.", "he opens the gate."], h: "Second conditional." },
                { if: `If ${s} had found the key`, then: "he would have opened the gate.", w: ["he would open the gate.", "he will have opened the gate.", "he would opened the gate."], h: "Third conditional." }
            ];
            const t = types[(i + j) % types.length];
            const options = shuffle([t.then, ...t.w]);
            quests.push({
                instruction: "Complete the conditional sentence.",
                difficulty: 1,
                subtype: "conditionals",
                interactionType: "choice",
                question: `${t.if}, ____.`,
                options: options,
                correctAnswerIndex: options.indexOf(t.then),
                hint: t.h,
                explanation: "Conditional structure agreement."
            });
        }
    }
    return quests;
};

// Run
purifyModule('sentenceCorrection', sentenceCorrectionGen);
purifyModule('prepositionChoice', prepositionChoiceGen);
purifyModule('conditionals', conditionalsGen);
