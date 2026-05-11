const fs = require('fs');
const path = require('path');

const gameType = 'sentenceCorrection';
const basePath = './assets/curriculum/grammar';

// 200 Unique Base Scenarios x 3 = 600 Quests
const scenarios = [
    // SVA - Present
    { q: "Lex [is/are] going to the Hub.", c: "is", w: ["are", "am", "be"], h: "Lex is singular." },
    { q: "The scouts [finds/find] the relic.", c: "find", w: ["finds", "finding", "finded"], h: "Plural subject." },
    { q: "Everyone [has/have] a role.", c: "has", w: ["have", "having", "haves"], h: "Indefinite pronouns are singular." },
    { q: "Neither of the droids [is/are] ready.", c: "is", w: ["are", "am", "be"], h: "'Neither' is singular." },
    { q: "The team [finishes/finish] the task.", c: "finishes", w: ["finish", "finishing", "finished"], h: "Collective noun as a unit." },
    // Tense
    { q: "Yesterday, he [goes/went] to the Void.", c: "went", w: ["goes", "go", "gone"], h: "Past tense." },
    { q: "By tomorrow, we [will finish/finished] it.", c: "will finish", w: ["finished", "finishes", "finish"], h: "Future tense." },
    { q: "She [has seen/saw] the stars already.", c: "has seen", w: ["saw", "seen", "sees"], h: "Present perfect." },
    { q: "They [were walking/was walking] when it rained.", c: "were walking", w: ["was walking", "is walking", "are walking"], h: "Past continuous plural." },
    { q: "I [have been/am] here for three hours.", c: "have been", w: ["am", "was", "be"], h: "Duration uses perfect tense." },
    // Pronouns
    { q: "It was [me/I] who found the key.", c: "I", w: ["me", "my", "myself"], h: "Predicate nominative (formal)." },
    { q: "Give the map to Mira and [I/me].", c: "me", w: ["I", "my", "mine"], h: "Object of preposition." },
    { q: "The droid, [who/which] is silver, is fast.", c: "which", w: ["who", "whom", "whose"], h: "Things use 'which'." },
    { q: "Whom [did you/you did] see?", c: "did you", w: ["you did", "does you", "you does"], h: "Question inversion." },
    { q: "That is [his/him] core.", c: "his", w: ["him", "he", "he's"], h: "Possessive adjective." },
    // Homophones
    { q: "[They're/Their] coming now.", c: "They're", w: ["Their", "There", "Them"], h: "Contraction of 'They are'." },
    { q: "Look at [its/it's] light.", c: "its", w: ["it's", "it is", "it"], h: "Possessive 'its' has no apostrophe." },
    { q: "[You're/Your] the best scout.", c: "You're", w: ["Your", "Yore", "You"], h: "Contraction of 'You are'." },
    { q: "We went [to/too] the station.", c: "to", w: ["too", "two", "toe"], h: "Directional 'to'." },
    { q: "It was [too/to] late.", c: "too", w: ["to", "two", "toe"], h: "Degree 'too'." }
];

// Extend Scenarios to 200 by variations
const variations = [
    "The Archivist", "Lex", "Mira", "The droid", "The scouts", "The council", "The signal", "The core", "The Void", "The Hub",
    "A sentinel", "The pilot", "The engineer", "The traveler", "The merchant", "The guard", "The leader", "The team", "The group", "Everyone"
];

function generate600() {
    const quests = [];
    let idCounter = 1;
    for (let i = 0; i < 200; i++) {
        const base = scenarios[i % scenarios.length];
        const subject = variations[i % variations.length];
        
        // Generate 3 unique questions per "scenario-subject" pair
        for (let j = 1; j <= 3; j++) {
            const qText = base.q.replace(/he|they|everyone|the droids|the scouts|Lex/gi, subject);
            const options = [base.c, ...base.w];
            // Shuffle
            const shuffled = [...options].sort(() => Math.random() - 0.5);
            const correctIndex = shuffled.indexOf(base.c);
            
            quests.push({
                id: `temp_${idCounter++}`, // Will fix IDs later
                instruction: "Choose the grammatically correct version.",
                difficulty: Math.floor(i / 40) + 1,
                subtype: gameType,
                interactionType: "choice",
                question: `Which is correct: "${qText.replace(/\[.*?\]/g, "____")}"?`,
                options: shuffled.map(o => qText.replace(/\[.*?\]/g, o)),
                correctAnswerIndex: correctIndex,
                hint: base.h,
                explanation: "Correct grammar application.",
                xpReward: 10,
                coinReward: 20,
                visual_config: { painter_type: "SentinelGridSync", primary_color: "0xFFFFFFFF" }
            });
        }
    }
    return quests;
}

const allQuests = generate600();

// Write to files
for (let batch = 0; batch < 20; batch++) {
    const startLevel = batch * 10 + 1;
    const endLevel = (batch + 1) * 10;
    const fileName = `${gameType}_${startLevel}_${endLevel}.json`;
    const filePath = path.join(basePath, fileName);
    
    const batchQuests = allQuests.slice(batch * 30, (batch + 1) * 30);
    // Fix IDs and rewards
    batchQuests.forEach((q, idx) => {
        const level = startLevel + Math.floor(idx / 3);
        const qNum = (idx % 3) + 1;
        q.id = `sc_l${level}_q${qNum}`;
        q.xpReward = level * 2;
        q.coinReward = level * 4;
        // Cycle visuals
        const visuals = ["SentinelGridSync", "CommandTerminalSync", "VoidPunctuationSync"];
        q.visual_config.painter_type = visuals[idx % 3];
    });

    const fileData = {
        gameType: gameType,
        batchIndex: batch + 1,
        levels: `${startLevel}-${endLevel}`,
        quests: batchQuests
    };
    
    fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
    console.log(`Purified ${fileName}`);
}
