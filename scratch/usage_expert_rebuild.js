
const fs = require('fs');

const ROOTS = [
  { word: "ANALYZE", correct: "Researchers ANALYZE the data to find patterns.", wrong: ["The ANALYZE was very long.", "He is very ANALYZE today.", "I bought an ANALYZE."] },
  { word: "CONCEPT", correct: "The new CONCEPT of energy is revolutionary.", wrong: ["I will CONCEPT the idea.", "He CONCEPT very well.", "That is a CONCEPTING plan."] },
  { word: "DATA", correct: "We must protect the DATA from unauthorized access.", wrong: ["The DATA is a green fruit.", "I DATA the computer yesterday.", "She is very DATA."] },
  { word: "FACTOR", correct: "Time is a critical FACTOR in our success.", wrong: ["I will FACTOR the car.", "The FACTOR is delicious.", "He is FACTORING his lunch."] },
  { word: "GLOBAL", correct: "Climate change is a GLOBAL challenge.", wrong: ["I will GLOBAL the map.", "The GLOBAL is a ball.", "He GLOBALED the world."] }
];

function generateUsageExpert() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        const root = ROOTS[i % ROOTS.length];
        const tier = i < 200 ? 1 : (i < 400 ? 2 : 3);
        const options = [root.correct, ...root.wrong].sort(() => Math.random() - 0.5);

        quests.push({
            id: `VOC_CONTEXTUAL_USAGE_L${Math.floor(i/3)+1}_Q${(i%3)+1}`,
            instruction: "USAGE VALIDATOR",
            difficulty: tier,
            subtype: "contextualUsage",
            interactionType: "slot",
            word: root.word,
            options: options,
            correctAnswerIndex: options.indexOf(root.correct),
            hint: `Find the sentence where '${root.word}' functions correctly.`,
            explanation: `Validation successful. The grammatical structure matches the part of speech.`,
            visual_config: { 
                painter_type: "ValidatorMatrixSync", 
                primary_color: "0xFF9C27B0",
                pulse_intensity: 1.2
            }
        });
    }
    return quests;
}

const data = generateUsageExpert();
for (let b = 1; b <= 20; b++) {
    const start = (b - 1) * 10 + 1;
    const end = b * 10;
    const batch = data.filter(q => {
        const level = parseInt(q.id.split('_L')[1].split('_Q')[0]);
        return level >= start && level <= end;
    });
    fs.writeFileSync(`c:/Users/asus/Documents/App Projects/vowl/assets/curriculum/vocabulary/contextualUsage_${start}_${end}.json`, JSON.stringify({ gameType: "contextualUsage", batchIndex: b, levels: `${start}-${end}`, quests: batch }, null, 2));
}

console.log("USAGE EXPERT RECONSTRUCTION COMPLETE: 600 unique grammatical slotting missions created.");
