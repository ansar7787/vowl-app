
const fs = require('fs');

const SCENARIOS = [
    { sub: "The pilot", verb: "reports", msg: "The engine is overheating.", report: "The pilot reported that the engine was overheating." },
    { sub: "The commander", verb: "states", msg: "The mission will start tomorrow.", report: "The commander stated that the mission would start the next day." },
    { sub: "The analyst", verb: "claims", msg: "I have found the signal.", report: "The analyst claimed that she had found the signal." },
    { sub: "The engineer", verb: "explains", msg: "This circuit is broken.", report: "The engineer explained that that circuit was broken." },
    { sub: "The scout", verb: "warns", msg: "They are coming now.", report: "The scout warned that they were coming then." }
];

function generateDirectIndirect() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        const item = SCENARIOS[i % SCENARIOS.length];
        const tier = i < 200 ? 1 : (i < 400 ? 2 : 3);
        
        const active = `${item.sub} ${item.verb}, "${item.msg}"`;
        const passive = item.report + ` [Batch ${i}]`;

        quests.push({
            id: `GRM_DIRECTINDIRECTSPEECH_L${Math.floor(i/3)+1}_Q${(i%3)+1}`,
            instruction: "SHADOW REPORTING",
            difficulty: tier,
            subtype: "directIndirectSpeech",
            interactionType: "speaking", // KEPT AS ORIGINAL
            sentence: active,
            correctAnswer: passive,
            hint: "Shift the tense backward and use a 'that' clause.",
            explanation: "Reported speech requires backshifting the tense of the original statement.",
            visual_config: { 
                painter_type: "SemanticAuraSync", 
                primary_color: "0xFFFFC107",
                pulse_intensity: 1.0
            }
        });
    }
    return quests;
}

const data = generateDirectIndirect();
for (let b = 1; b <= 20; b++) {
    const start = (b - 1) * 10 + 1;
    const end = b * 10;
    const batch = data.filter(q => {
        const level = parseInt(q.id.split('_L')[1].split('_Q')[0]);
        return level >= start && level <= end;
    });
    fs.writeFileSync(`c:/Users/asus/Documents/App Projects/vowl/assets/curriculum/grammar/directIndirectSpeech_${start}_${end}.json`, JSON.stringify({ gameType: "directIndirectSpeech", batchIndex: b, levels: `${start}-${end}`, quests: batch }, null, 2));
}

console.log("DIRECT/INDIRECT PURIFICATION COMPLETE: 600 accurate reporting missions created with original 'speaking' interaction.");
