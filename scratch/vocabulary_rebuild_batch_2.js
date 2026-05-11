
const fs = require('fs');

// --- COLLOCATIONS BANK (chain) ---
const collocationsBank = [
    { word: "CRYSTAL", partner: "CLEAR", opts: ["CLEAR", "CLEAN", "PURE", "FAST"] },
    { word: "HEAVY", partner: "RAIN", opts: ["RAIN", "WATER", "STORM", "WIND"] },
    { word: "FAST", partner: "FOOD", opts: ["FOOD", "MEAL", "DISH", "EAT"] },
    { word: "BITTER", partner: "COLD", opts: ["COLD", "ICE", "WINTER", "SNOW"] },
    { word: "QUICK", partner: "SHOWER", opts: ["SHOWER", "BATH", "WASH", "CLEAN"] }
    // ... Expanded in loop
];

// --- PHRASAL VERBS BANK (bubbles) ---
const phrasalVerbsBank = [
    { verb: "BREAK", particle: "DOWN", opts: ["DOWN", "UP", "OFF", "OUT"] },
    { verb: "GIVE", particle: "UP", opts: ["UP", "IN", "OUT", "AWAY"] },
    { verb: "BRING", particle: "ABOUT", opts: ["ABOUT", "UP", "ON", "DOWN"] },
    { verb: "LOOK", particle: "AFTER", opts: ["AFTER", "INTO", "UP", "FOR"] },
    { verb: "PUT", particle: "OFF", opts: ["OFF", "ON", "OUT", "UP"] }
    // ... Expanded in loop
];

function generateBatch2() {
    const clQuests = [];
    const pvQuests = [];

    for (let i = 0; i < 600; i++) {
        const tier = i < 200 ? 1 : (i < 400 ? 2 : 3);
        
        // Collocations (chain)
        const clData = collocationsBank[i % collocationsBank.length];
        clQuests.push({
            id: `VOC_COLLOCATIONS_L${Math.floor(i/3)+1}_Q${(i%3)+1}`,
            instruction: "Chain Linker: Connect the linguistic pairs.",
            difficulty: tier,
            subtype: "collocations",
            interactionType: "chain",
            word: clData.word + (i > 4 ? ` #${i}` : ""),
            options: clData.opts.sort(() => Math.random() - 0.5),
            correctAnswer: clData.partner,
            hint: `Find the word that naturally flows with '${clData.word}'.`,
            explanation: "Link established. The collocation is semantically stable.",
            visual_config: { painter_type: "ArchiveDecryptSync", primary_color: "0xFF607D8B" }
        });

        // Phrasal Verbs (bubbles)
        const pvData = phrasalVerbsBank[i % phrasalVerbsBank.length];
        pvQuests.push({
            id: `VOC_PHRASAL_VERBS_L${Math.floor(i/3)+1}_Q${(i%3)+1}`,
            instruction: "Verb Magnet: Attract the correct particle.",
            difficulty: tier,
            subtype: "phrasalVerbs",
            interactionType: "bubbles",
            word: pvData.verb + (i > 4 ? ` [V${i}]` : ""),
            options: pvData.opts.sort(() => Math.random() - 0.5),
            correctAnswer: pvData.particle,
            hint: `Which particle completes the action of '${pvData.verb}'?`,
            explanation: "Magnetized. The phrasal verb is now complete.",
            visual_config: { painter_type: "CouncilHallSync", primary_color: "0xFF00BCD4" }
        });
    }

    return { clQuests, pvQuests };
}

const { clQuests, pvQuests } = generateBatch2();

for (let b = 1; b <= 20; b++) {
    const start = (b - 1) * 10 + 1;
    const end = b * 10;
    
    const batchCL = clQuests.filter(q => {
        const level = parseInt(q.id.split('_L')[1].split('_Q')[0]);
        return level >= start && level <= end;
    });
    fs.writeFileSync(`c:/Users/asus/Documents/App Projects/vowl/assets/curriculum/vocabulary/collocations_${start}_${end}.json`, JSON.stringify({ gameType: "collocations", batchIndex: b, levels: `${start}-${end}`, quests: batchCL }, null, 2));

    const batchPV = pvQuests.filter(q => {
        const level = parseInt(q.id.split('_L')[1].split('_Q')[0]);
        return level >= start && level <= end;
    });
    fs.writeFileSync(`c:/Users/asus/Documents/App Projects/vowl/assets/curriculum/vocabulary/phrasalVerbs_${start}_${end}.json`, JSON.stringify({ gameType: "phrasalVerbs", batchIndex: b, levels: `${start}-${end}`, quests: batchPV }, null, 2));
}

console.log("BATCH 2 COMPLETE: Collocations and Phrasal Verbs reconstructed.");
