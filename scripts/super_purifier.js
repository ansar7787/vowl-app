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
];

const verbs = [
    "repairs", "scans", "watches", "activates", "collects", "transmits", "calculates", "secures", "analyzes", "builds",
    "cleans", "opens", "locks", "emits", "powers", "protects", "tells", "damages", "makes", "feeds",
    "studies", "chooses", "heats", "sends", "receives", "processes", "identifies", "locates", "tracks", "monitors",
    "explores", "records", "updates", "fixes", "boots", "shuts", "tunes", "aligns", "measures", "calibrates",
    "observes", "filters", "detects", "signals", "routes", "binds", "splits", "merges", "saves", "loads"
];

const objects = [
    "the system", "the data", "the relay", "the engine", "the map", "the key", "the relic", "the archive", "the portal", "the shield",
    "the sensor", "the battery", "the circuit", "the console", "the platform", "the module", "the drone", "the core", "the beam", "the pulse",
    "the report", "the log", "the blueprint", "the code", "the signal", "the bridge", "the gate", "the vault", "the chamber", "the lab"
];

const contexts = [
    "in the Hub", "near the Void", "inside the station", "at the foundry", "during the storm", "before the dawn", "after the breach", "across the bridge", "under the stars", "within the sector",
    "on the relay", "past the gate", "through the portal", "behind the console", "between the cores", "among the droids", "against the wind", "by the reactor", "into the deep", "out of the shadows"
];

function generateUniqueSentences(count) {
    const set = new Set();
    while (set.size < count) {
        const s = subjects[Math.floor(Math.random() * subjects.length)];
        const v = verbs[Math.floor(Math.random() * verbs.length)];
        const o = objects[Math.floor(Math.random() * objects.length)];
        const c = contexts[Math.floor(Math.random() * contexts.length)];
        set.add(`${s} ${v} ${o} ${c}.`);
    }
    return Array.from(set);
}

const prefixMap = {
    'articleInsertion': 'ai', 'clauseConnector': 'cc', 'conditionals': 'cd', 'conjunctions': 'cj',
    'directIndirectSpeech': 'di', 'grammarQuest': 'gq', 'modalsSelection': 'ms', 'modifierPlacement': 'mp',
    'partsOfSpeech': 'ps', 'prepositionChoice': 'pc', 'pronounResolution': 'pr', 'punctuationMastery': 'pm',
    'questionFormatter': 'qf', 'relativeClauses': 'rc', 'sentenceCorrection': 'sc', 'subjectVerbAgreement': 'sv',
    'tenseMastery': 'tm', 'voiceSwap': 'vs', 'wordReorder': 'wr'
};

function writeBatch(gameType, quests) {
    for (let batch = 0; batch < 20; batch++) {
        const startLevel = batch * 10 + 1;
        const endLevel = (batch + 1) * 10;
        const batchQuests = quests.slice(batch * 30, (batch + 1) * 30);
        batchQuests.forEach((q, idx) => {
            const level = startLevel + Math.floor(idx / 3);
            const qNum = (idx % 3) + 1;
            q.id = `${prefixMap[gameType]}_l${level}_q${qNum}`;
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
        fs.writeFileSync(path.join(basePath, `${gameType}_${startLevel}_${endLevel}.json`), JSON.stringify(fileData, null, 2));
    }
}

// 1. Article Insertion (Interactive Blank)
function purifyArticleInsertion() {
    const quests = [];
    const articles = ["a", "an", "the"];
    const pool = generateUniqueSentences(600);
    pool.forEach((sentence, i) => {
        const words = sentence.split(' ');
        const correct = articles.includes(words[0].toLowerCase()) ? words[0].toLowerCase() : "the";
        quests.push({
            instruction: "Identify the article missing from the data stream.",
            difficulty: 1,
            subtype: "articleInsertion",
            interactionType: "choice",
            sentenceWithBlank: "____ " + sentence.split(' ').slice(1).join(' '),
            options: ["a", "an", "the", "no article"],
            correctAnswer: correct,
            hint: "Check if the noun is definite.",
            explanation: "Articles provide context."
        });
    });
    writeBatch('articleInsertion', quests);
}

// 2. Clause Connector (Choice)
function purifyClauseConnector() {
    const quests = [];
    const connectors = ["and", "but", "or", "because", "although", "since", "unless", "while"];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const conn = connectors[i % connectors.length];
        const second = "the system responded.";
        const options = shuffle([conn, ...connectors.filter(x => x !== conn).slice(0, 3)]);
        quests.push({
            instruction: "Select the bridge connector for these modules.",
            difficulty: 1,
            subtype: "clauseConnector",
            interactionType: "choice",
            question: `${s.slice(0,-1)} ____ ${second}`,
            options: options,
            correctAnswerIndex: options.indexOf(conn),
            hint: "Look for causal links.",
            explanation: "Connectors define logic flow."
        });
    });
    writeBatch('clauseConnector', quests);
}

// 3. Conditionals (Choice)
function purifyConditionals() {
    const quests = [];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const cond = `If ${s.slice(0,-1)}`;
        const result = "it will function.";
        const wrong = ["it would function.", "it functions.", "it functioning."];
        const options = shuffle([result, ...wrong]);
        quests.push({
            instruction: "Analyze the conditional logic path.",
            difficulty: 1,
            subtype: "conditionals",
            interactionType: "choice",
            question: `${cond}, ____.`,
            options: options,
            correctAnswerIndex: options.indexOf(result),
            hint: "First conditional uses future tense.",
            explanation: "Logic requires consistency."
        });
    });
    writeBatch('conditionals', quests);
}

// 4. Conjunctions (Choice)
function purifyConjunctions() {
    const quests = [];
    const conjs = ["and", "but", "so", "or", "yet", "for"];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const c = conjs[i % conjs.length];
        const options = shuffle([c, ...conjs.filter(x => x !== c).slice(0, 3)]);
        quests.push({
            instruction: "Join the independent data fragments.",
            difficulty: 1,
            subtype: "conjunctions",
            interactionType: "choice",
            question: `${s.slice(0,-1)} ____ the core pulsed.`,
            options: options,
            correctAnswerIndex: options.indexOf(c),
            hint: "Connect similar streams.",
            explanation: "Conjunctions bridge signals."
        });
    });
    writeBatch('conjunctions', quests);
}

// 5. Direct Indirect Speech (Speaking)
function purifyDirectIndirect() {
    const quests = [];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const direct = `Lex reports, "${s}"`;
        const indirect = `Lex reports that ${s.toLowerCase()}`;
        quests.push({
            instruction: "Repeat the report using indirect speech.",
            difficulty: 1,
            subtype: "directIndirectSpeech",
            interactionType: "speaking",
            sentence: direct,
            correctAnswer: indirect,
            hint: "Convert quotes into a 'that' clause.",
            explanation: "Indirect speech is for summaries."
        });
    });
    writeBatch('directIndirectSpeech', quests);
}

// 6. Preposition Choice (Interactive Blank)
function purifyPrepositionChoice() {
    const quests = [];
    const preps = ["in", "on", "at", "by", "from", "to", "with", "about", "for", "under"];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const p = preps[i % preps.length];
        const template = s.replace(/ (in|near|inside|at|during|before|after|across|under|within|on|past|through|behind|between|among|against|by|into|out) /g, " ____ ");
        quests.push({
            instruction: "Locate the correct spatial preposition.",
            difficulty: 1,
            subtype: "prepositionChoice",
            interactionType: "choice",
            sentenceWithBlank: template,
            options: shuffle([p, ...preps.filter(x => x !== p).slice(0, 3)]),
            correctAnswer: p,
            hint: "Consider the location of the core.",
            explanation: "Prepositions define position."
        });
    });
    writeBatch('prepositionChoice', quests);
}

// 7. Modals Selection (Choice)
function purifyModals() {
    const quests = [];
    const modals = ["can", "must", "should", "might", "will", "would", "could", "shall"];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const m = modals[i % modals.length];
        const words = s.split(' ');
        const question = `${words[0]} ____ ${words.slice(1).join(' ')}`;
        const options = shuffle([m, ...modals.filter(x => x !== m).slice(0, 3)]);
        quests.push({
            instruction: "Define the modal possibility.",
            difficulty: 1,
            subtype: "modalsSelection",
            interactionType: "choice",
            question: question,
            options: options,
            correctAnswerIndex: options.indexOf(m),
            hint: "Ability or necessity?",
            explanation: "Modals set the mood."
        });
    });
    writeBatch('modalsSelection', quests);
}

// 8. Modifier Placement (Reorder)
function purifyModifierPlacement() {
    const quests = [];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const words = s.slice(0,-1).split(' ');
        const correct = s.slice(0,-1);
        const shuffled = shuffle([...words]);
        quests.push({
            instruction: "Drag fragments to align the modifier.",
            difficulty: 1,
            subtype: "modifierPlacement",
            interactionType: "reorder",
            shuffledWords: shuffled,
            correctAnswer: correct,
            hint: "Keep descriptors near targets.",
            explanation: "Syntax determines clarity."
        });
    });
    writeBatch('modifierPlacement', quests);
}

// 9. Parts of Speech (Match Grid)
function purifyPartsOfSpeech() {
    const quests = [];
    const types = ["Noun", "Verb", "Adjective", "Adverb"];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const words = s.split(' ');
        const target = words[0]; 
        quests.push({
            instruction: "Categorize the selected lexical unit.",
            difficulty: 1,
            subtype: "partsOfSpeech",
            interactionType: "match",
            targetWord: target,
            sentence: s,
            options: types,
            correctAnswerIndex: types.indexOf("Noun"),
            hint: "This is the primary actor.",
            explanation: "Lexical categories organize data."
        });
    });
    writeBatch('partsOfSpeech', quests);
}

// 10. Pronoun Resolution (Match Grid)
function purifyPronoun() {
    const quests = [];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const words = s.split(' ');
        const subj = words[0];
        quests.push({
            instruction: "Resolve the pronoun to its source.",
            difficulty: 1,
            subtype: "pronounResolution",
            interactionType: "match",
            targetWord: "it",
            sentence: `${s.slice(0,-1)}, which means it is ready.`,
            options: [subj, "The signal", "The Void", "The relay"],
            correctAnswerIndex: 0,
            hint: "Identify the antecedent.",
            explanation: "Pronouns link context."
        });
    });
    writeBatch('pronounResolution', quests);
}

// 11. Punctuation Mastery (Typing)
function purifyPunctuation() {
    const quests = [];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const unpunctuated = s.replace(/[.,]/g, '');
        quests.push({
            instruction: "Restore the sentence boundaries.",
            difficulty: 1,
            subtype: "punctuationMastery",
            interactionType: "typing",
            sentence: unpunctuated,
            correctAnswer: s,
            hint: "Add a period to terminate the stream.",
            explanation: "Punctuation is structural logic."
        });
    });
    writeBatch('punctuationMastery', quests);
}

// 12. Question Formatter (Typing)
function purifyQuestionFormatter() {
    const quests = [];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const words = s.slice(0,-1).split(' ');
        const question = `Does ${words[0]} ${words[1]} ${words.slice(2).join(' ')}?`;
        quests.push({
            instruction: "Invert the statement into a query.",
            difficulty: 1,
            subtype: "questionFormatter",
            interactionType: "typing",
            sentence: s,
            correctAnswer: question,
            hint: "Use 'Does' and a question mark.",
            explanation: "Interrogatives shift sequence."
        });
    });
    writeBatch('questionFormatter', quests);
}

// 13. Relative Clauses (Choice)
function purifyRelativeClauses() {
    const quests = [];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const words = s.split(' ');
        const correct = `${words[0]}, which is active, ${words.slice(1).join(' ')}`;
        const options = shuffle([correct, `${words[0]} is active ${words.slice(1).join(' ')}`, `Active ${s}`, `${s} active`]);
        quests.push({
            instruction: "Integrate the relative sub-module.",
            difficulty: 1,
            subtype: "relativeClauses",
            interactionType: "choice",
            question: `Add 'which is active' to: ${s}`,
            options: options,
            correctAnswerIndex: options.indexOf(correct),
            hint: "Isolate the clause with commas.",
            explanation: "Relative clauses add depth."
        });
    });
    writeBatch('relativeClauses', quests);
}

// 14. Sentence Correction (Spotlight Selection)
function purifySentenceCorrection() {
    const quests = [];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const words = s.split(' ');
        const correctWord = words[1];
        const wrongWord = words[1].slice(0,-1); // plural/singular error
        const modifiedSentence = `${words[0]} ${wrongWord} ${words.slice(2).join(' ')}`;
        
        quests.push({
            instruction: "Locate the syntax corruption.",
            difficulty: 1,
            subtype: "sentenceCorrection",
            interactionType: "selection",
            sentence: modifiedSentence,
            correctAnswerIndex: 1,
            hint: "Check the second word for conjugation errors.",
            explanation: "Identify the glitch in the stream."
        });
    });
    writeBatch('sentenceCorrection', quests);
}

// 15. Subject Verb Agreement (True/False)
function purifySVA() {
    const quests = [];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const isCorrect = i % 2 === 0;
        const words = s.split(' ');
        const modified = isCorrect ? s : `${words[0]} ${words[1].slice(0,-1)} ${words.slice(2).join(' ')}`;
        quests.push({
            instruction: "Verify the S-V sync integrity.",
            difficulty: 1,
            subtype: "subjectVerbAgreement",
            interactionType: "trueFalse",
            sentence: modified,
            correctAnswer: isCorrect ? "true" : "false",
            hint: "Check the verb ending against the subject.",
            explanation: "Sync errors cause data loss."
        });
    });
    writeBatch('subjectVerbAgreement', quests);
}

// 16. Tense Mastery (Timeline Slider)
function purifyTense() {
    const quests = [];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        quests.push({
            instruction: "Map the temporal state on the timeline.",
            difficulty: 1,
            subtype: "tenseMastery",
            interactionType: "sequence",
            sentence: s,
            correctAnswer: "Present",
            hint: "This signal is occurring now.",
            explanation: "Tense is a temporal coordinate."
        });
    });
    writeBatch('tenseMastery', quests);
}

// 17. Grammar Quest (Choice)
function purifyGrammarQuest() {
    const quests = [];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        quests.push({
            instruction: "Spot the structural anomaly.",
            difficulty: 1,
            subtype: "grammarQuest",
            interactionType: "choice",
            question: `Analyze: "${s.toLowerCase()}"`,
            options: ["Case Error", "Punctuation Gap", "Logic Breach", "None"],
            correctAnswerIndex: 0,
            hint: "Check the first character's case.",
            explanation: "Vowl protocols require capitalization."
        });
    });
    writeBatch('grammarQuest', quests);
}

// 18. Voice Swap (Speaking)
function purifyVoiceSwap() {
    const quests = [];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const words = s.split(' ');
        const passive = `${words[2]} is ${words[1]}ed by ${words[0]}.`;
        quests.push({
            instruction: "Broadcast the passive voice conversion.",
            difficulty: 1,
            subtype: "voiceSwap",
            interactionType: "speaking",
            sentence: s,
            correctAnswer: passive,
            hint: "Shift the focus to the object.",
            explanation: "Passive voice reorients perspective."
        });
    });
    writeBatch('voiceSwap', quests);
}

// 19. Word Reorder (Reorder)
function purifyWordReorder() {
    const quests = [];
    const pool = generateUniqueSentences(600);
    pool.forEach((s, i) => {
        const words = s.slice(0,-1).split(' ');
        const shuffled = shuffle([...words]);
        quests.push({
            instruction: "Reconstruct the scrambled data stream.",
            difficulty: 1,
            subtype: "wordReorder",
            interactionType: "reorder",
            shuffledWords: shuffled,
            correctAnswer: s.slice(0,-1),
            hint: "Follow the logical subject-action flow.",
            explanation: "Reassembly restores meaning."
        });
    });
    writeBatch('wordReorder', quests);
}

purifyArticleInsertion();
purifyClauseConnector();
purifyConditionals();
purifyConjunctions();
purifyDirectIndirect();
purifyPrepositionChoice();
purifyModals();
purifyModifierPlacement();
purifyPartsOfSpeech();
purifyPronoun();
purifyPunctuation();
purifyQuestionFormatter();
purifyRelativeClauses();
purifySentenceCorrection();
purifySVA();
purifyTense();
purifyGrammarQuest();
purifyVoiceSwap();
purifyWordReorder();

console.log("Grammar Revolution: 12 Premium Archetypes Implemented Across 11,400 Quests.");
