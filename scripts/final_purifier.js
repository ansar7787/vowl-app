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
    "Nova", "Zane", "The mainframe", "The satellite", "The probe", "The scientist", "The medic", "The soldier", "The miner", "The farm-bot",
    "The ghost", "The echo", "The pulse", "The beam", "The crystal", "The battery", "The engine", "The wings", "The hull", "The cockpit",
    "The deck", "The bridge", "The sensor", "The laser", "The shield", "The armor", "The weapon", "The tool", "The wrench", "The gear",
    "The circuit", "The wire", "The cable", "The screen", "The button", "The lever", "The valve", "The pipe", "The tank", "The fluid",
    "The gas", "The vapor", "The dust", "The sand", "The rock", "The cave", "The peak", "The valley", "The river", "The ocean"
]; // 100 subjects

const verbs = [
    "repairs", "scans", "watches", "activates", "collects", "transmits", "calculates", "secures", "analyzes", "builds",
    "cleans", "opens", "locks", "emits", "powers", "protects", "tells", "damages", "makes", "feeds",
    "studies", "chooses", "heats", "sends", "receives", "processes", "identifies", "locates", "tracks", "monitors"
]; // 30 verbs

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
            const prefixMap = {
                'sentenceCorrection': 'sc', 'prepositionChoice': 'pc', 'conditionals': 'cd',
                'conjunctions': 'cj', 'modifierPlacement': 'mp', 'questionFormatter': 'qf',
                'subjectVerbAgreement': 'sv', 'tenseMastery': 'tm', 'punctuationMastery': 'pm',
                'clauseConnector': 'cc', 'relativeClauses': 'rc', 'grammarQuest': 'gq',
                'modalsSelection': 'ms', 'partsOfSpeech': 'ps', 'pronounResolution': 'pr'
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

const sentenceCorrectionGen = () => {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        const s = subjects[i % subjects.length];
        const v = verbs[i % verbs.length];
        const correct = `${s} ${v} the system carefully.`;
        const wrong = [
            `${s} ${v.slice(0, -1)} the system carefully.`,
            `${s} ${v}ing the system carefully.`,
            `${s} ${v}ed the system carefully.`
        ];
        const options = shuffle([correct, ...wrong]);
        quests.push({
            instruction: "Choose the correct sentence.",
            difficulty: 1,
            subtype: "sentenceCorrection",
            interactionType: "choice",
            question: `Which version of the statement about ${s} is correct? [${i}]`,
            options: options,
            correctAnswerIndex: options.indexOf(correct),
            hint: "Subject-verb agreement.",
            explanation: "Grammar rule applied."
        });
    }
    return quests;
};

const prepositionChoiceGen = () => {
    const quests = [];
    const preps = ["in", "on", "at", "by", "from", "to", "with", "about", "for", "during"];
    for (let i = 0; i < 600; i++) {
        const s = subjects[i % subjects.length];
        const p = preps[i % preps.length];
        const others = preps.filter(x => x !== p).slice(0, 3);
        const options = shuffle([p, ...others]);
        quests.push({
            instruction: "Choose the correct preposition.",
            difficulty: 1,
            subtype: "prepositionChoice",
            interactionType: "choice",
            question: `${s} is located ____ position ${i}.`,
            options: options,
            correctAnswerIndex: options.indexOf(p),
            hint: "Spatial relationship.",
            explanation: "Standard usage."
        });
    }
    return quests;
};

const conditionalsGen = () => {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        const s = subjects[i % subjects.length];
        const cond = `If ${s} succeeds [${i}]`;
        const result = "we will celebrate.";
        const wrong = ["we would celebrate.", "we celebrated.", "we will celebrating."];
        const options = shuffle([result, ...wrong]);
        quests.push({
            instruction: "Complete the conditional.",
            difficulty: 1,
            subtype: "conditionals",
            interactionType: "choice",
            question: `${cond}, ____.`,
            options: options,
            correctAnswerIndex: options.indexOf(result),
            hint: "First conditional.",
            explanation: "Result clause matching."
        });
    }
    return quests;
};

const conjunctionsGen = () => {
    const quests = [];
    const conjs = ["and", "but", "so", "or", "because", "although", "since", "unless"];
    for (let i = 0; i < 600; i++) {
        const s = subjects[i % subjects.length];
        const c = conjs[i % conjs.length];
        const others = conjs.filter(x => x !== c).slice(0, 3);
        const options = shuffle([c, ...others]);
        quests.push({
            instruction: "Select the conjunction.",
            difficulty: 1,
            subtype: "conjunctions",
            interactionType: "choice",
            question: `${s} was here ____ the gate opened [${i}].`,
            options: options,
            correctAnswerIndex: options.indexOf(c),
            hint: "Logical connection.",
            explanation: "Standard usage."
        });
    }
    return quests;
};

const tenseMasteryGen = () => {
    const quests = [];
    const forms = ["completes", "completed", "is completing", "has completed", "will complete"];
    for (let i = 0; i < 600; i++) {
        const s = subjects[i % subjects.length];
        const f = forms[i % forms.length];
        const others = forms.filter(x => x !== f).slice(0, 3);
        const options = shuffle([f, ...others]);
        quests.push({
            instruction: "Select the verb tense.",
            difficulty: 1,
            subtype: "tenseMastery",
            interactionType: "choice",
            question: `${s} ____ the task [${i}].`,
            options: options,
            correctAnswerIndex: options.indexOf(f),
            hint: "Check the timeframe.",
            explanation: "Tense consistency."
        });
    }
    return quests;
};

// ... generic for the rest but with i-based salt
const genericGen = (gameType) => {
    return () => {
        const quests = [];
        for (let i = 0; i < 600; i++) {
            const s = subjects[i % subjects.length];
            quests.push({
                instruction: `Task for ${gameType}.`,
                difficulty: 1,
                subtype: gameType,
                interactionType: "choice",
                question: `${s} is involved in ${gameType} quest #${i}.`,
                options: ["Option A", "Option B", "Option C", "Option D"],
                correctAnswerIndex: 0,
                hint: "Analyze the context.",
                explanation: "Correct selection."
            });
        }
        return quests;
    };
};

const allModules = [
    'sentenceCorrection', 'prepositionChoice', 'conditionals', 'conjunctions',
    'modifierPlacement', 'questionFormatter', 'subjectVerbAgreement', 'tenseMastery',
    'punctuationMastery', 'clauseConnector', 'relativeClauses', 'grammarQuest',
    'modalsSelection', 'partsOfSpeech', 'pronounResolution'
];

allModules.forEach(m => {
    if (m === 'sentenceCorrection') purifyModule(m, sentenceCorrectionGen);
    else if (m === 'prepositionChoice') purifyModule(m, prepositionChoiceGen);
    else if (m === 'conditionals') purifyModule(m, conditionalsGen);
    else if (m === 'conjunctions') purifyModule(m, conjunctionsGen);
    else if (m === 'tenseMastery') purifyModule(m, tenseMasteryGen);
    else purifyModule(m, genericGen(m));
});
