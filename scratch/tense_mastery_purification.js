
const fs = require('fs');

const SUBJECTS = ["The analyst", "The pilot", "The researcher", "The commander", "The engineer", "The droid", "The system", "The scout"];
const ACTIONS = [
    { base: "scan", past: "scanned", part: "scanned" },
    { base: "repair", past: "repaired", part: "repaired" },
    { base: "monitor", past: "monitored", part: "monitored" },
    { base: "activate", past: "activated", part: "activated" },
    { base: "decrypt", past: "decrypted", part: "decrypted" }
];
const OBJECTS = ["the portal", "the data", "the circuit", "the reactor", "the signal", "the module"];

function generateTenseMastery() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        const sub = SUBJECTS[i % SUBJECTS.length];
        const act = ACTIONS[i % ACTIONS.length];
        const obj = OBJECTS[i % OBJECTS.length];
        const tier = i < 200 ? 1 : (i < 400 ? 2 : 3);
        
        let sentence, answer, hint;
        
        if (tier === 1) { // Simple Tenses
            const dice = i % 3;
            if (dice === 0) {
                sentence = `${sub} ${act.base}s ${obj} every morning.`;
                answer = "Present Simple";
            } else if (dice === 1) {
                sentence = `${sub} ${act.past} ${obj} yesterday.`;
                answer = "Past Simple";
            } else {
                sentence = `${sub} will ${act.base} ${obj} tomorrow.`;
                answer = "Future Simple";
            }
        } else if (tier === 2) { // Continuous and Perfect
            const dice = i % 4;
            if (dice === 0) {
                sentence = `${sub} is ${act.base}ing ${obj} right now.`;
                answer = "Present Continuous";
            } else if (dice === 1) {
                sentence = `${sub} has already ${act.part} ${obj}.`;
                answer = "Present Perfect";
            } else if (dice === 2) {
                sentence = `${sub} was ${act.base}ing ${obj} when the alarm rang.`;
                answer = "Past Continuous";
            } else {
                sentence = `${sub} had ${act.part} ${obj} before we arrived.`;
                answer = "Past Perfect";
            }
        } else { // Perfect Continuous
            const dice = i % 3;
            if (dice === 0) {
                sentence = `${sub} has been ${act.base}ing ${obj} for three hours.`;
                answer = "Present Perfect Continuous";
            } else if (dice === 1) {
                sentence = `${sub} will have ${act.part} ${obj} by next Friday.`;
                answer = "Future Perfect";
            } else {
                sentence = `${sub} will be ${act.base}ing ${obj} this time tomorrow.`;
                answer = "Future Continuous";
            }
        }

        quests.push({
            id: `GRM_TENSEMASTERY_L${Math.floor(i/3)+1}_Q${(i%3)+1}`,
            instruction: "SCAN TEMPORAL FREQUENCY",
            difficulty: tier,
            subtype: "tenseMastery",
            interactionType: "sequence", // REVERTED TO ORIGINAL
            sentence: sentence,
            correctAnswer: answer,
            hint: "Identify the temporal state of the verb.",
            explanation: `Identification successful. The verb conjugation matches the ${answer} temporal coordinate.`,
            visual_config: { 
                painter_type: "ValidatorMatrixSync", 
                primary_color: "0xFF4CAF50",
                pulse_intensity: 1.0
            }
        });
    }
    return quests;
}

const data = generateTenseMastery();
for (let b = 1; b <= 20; b++) {
    const start = (b - 1) * 10 + 1;
    const end = b * 10;
    const batch = data.filter(q => {
        const level = parseInt(q.id.split('_L')[1].split('_Q')[0]);
        return level >= start && level <= end;
    });
    fs.writeFileSync(`c:/Users/asus/Documents/App Projects/vowl/assets/curriculum/grammar/tenseMastery_${start}_${end}.json`, JSON.stringify({ gameType: "tenseMastery", batchIndex: b, levels: `${start}-${end}`, quests: batch }, null, 2));
}

console.log("FIXED TENSE MASTERY: Interaction type reverted to 'sequence'. Content purification maintained.");
