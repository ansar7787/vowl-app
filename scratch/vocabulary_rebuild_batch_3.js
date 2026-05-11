
const fs = require('fs');

// --- IDIOMS BANK (echo) ---
const idiomsBank = [
    { word: "BITE THE BULLET", emoji: "🦷", opts: ["Accept something difficult", "Eat something hard", "Fight a war", "Stay silent"], correct: "Accept something difficult" },
    { word: "BREAK THE ICE", emoji: "🧊", opts: ["Start a conversation", "Destroy a glacier", "Feel cold", "Stop a fight"], correct: "Start a conversation" },
    { word: "UNDER THE WEATHER", emoji: "🌧️", opts: ["Feeling ill", "Outside in rain", "Flying a plane", "Being sad"], correct: "Feeling ill" },
    { word: "PIECE OF CAKE", emoji: "🍰", opts: ["Very easy", "Hungry", "Baking a dessert", "Giving a gift"], correct: "Very easy" },
    { word: "SPILL THE BEANS", emoji: "🫘", opts: ["Reveal a secret", "Drop food", "Cook dinner", "Talk too much"], correct: "Reveal a secret" }
];

// --- CONTEXTUAL USAGE BANK (slot) ---
const usageBank = [
    { word: "ANALYZE", sentences: ["Scientists ANALYZE the data.", "The bird is ANALYZE.", "I like ANALYZE.", "ANALYZE is a fruit."], correctIdx: 0 },
    { word: "CONSISTENT", sentences: ["The results are CONSISTENT.", "He is a CONSISTENT.", "I CONSISTENT my homework.", "CONSISTENT is blue."], correctIdx: 0 },
    { word: "SIGNIFICANT", sentences: ["This is a SIGNIFICANT change.", "The cat is SIGNIFICANT.", "I SIGNIFICANT the door.", "SIGNIFICANT is a song."], correctIdx: 0 },
    { word: "ESTABLISH", sentences: ["They ESTABLISH a new rule.", "I ESTABLISH my lunch.", "The car is ESTABLISH.", "ESTABLISH is 5:00."], correctIdx: 0 },
    { word: "PRINCIPLE", sentences: ["It is a matter of PRINCIPLE.", "I PRINCIPLE the dog.", "The PRINCIPLE is delicious.", "PRINCIPLE is a color."], correctIdx: 0 }
];

function generateBatch3() {
    const idQuests = [];
    const cuQuests = [];

    for (let i = 0; i < 600; i++) {
        const tier = i < 200 ? 1 : (i < 400 ? 2 : 3);
        
        // Idioms (echo)
        const idData = idiomsBank[i % idiomsBank.length];
        idQuests.push({
            id: `VOC_IDIOMS_L${Math.floor(i/3)+1}_Q${(i%3)+1}`,
            instruction: "Idiom Echo: Identify the hidden meaning.",
            difficulty: tier,
            subtype: "idioms",
            interactionType: "echo",
            word: idData.word + (i > 4 ? ` [V${i}]` : ""),
            topicEmoji: idData.emoji,
            options: idData.opts.sort(() => Math.random() - 0.5),
            correctAnswer: idData.correct,
            hint: `Think about the figurative meaning of the emoji '${idData.emoji}'.`,
            explanation: "Echo received. The idiom's meaning is correctly identified.",
            visual_config: { painter_type: "CouncilHallSync", primary_color: "0xFF00BCD4" }
        });

        // Contextual Usage (slot)
        const cuData = usageBank[i % usageBank.length];
        cuQuests.push({
            id: `VOC_CONTEXTUAL_USAGE_L${Math.floor(i/3)+1}_Q${(i%3)+1}`,
            instruction: "Usage Expert: Pick the correct contextual sentence.",
            difficulty: tier,
            subtype: "contextualUsage",
            interactionType: "slot",
            word: cuData.word + (i > 4 ? ` #${i}` : ""),
            options: cuData.sentences,
            correctAnswerIndex: cuData.correctIdx,
            hint: `Which sentence uses '${cuData.word}' in its correct grammatical form?`,
            explanation: "Usage verified. The slot is perfectly filled.",
            visual_config: { painter_type: "NexusCoreSync", primary_color: "0xFF9C27B0" }
        });
    }

    return { idQuests, cuQuests };
}

const { idQuests, cuQuests } = generateBatch3();

for (let b = 1; b <= 20; b++) {
    const start = (b - 1) * 10 + 1;
    const end = b * 10;
    
    const batchID = idQuests.filter(q => {
        const level = parseInt(q.id.split('_L')[1].split('_Q')[0]);
        return level >= start && level <= end;
    });
    fs.writeFileSync(`c:/Users/asus/Documents/App Projects/vowl/assets/curriculum/vocabulary/idioms_${start}_${end}.json`, JSON.stringify({ gameType: "idioms", batchIndex: b, levels: `${start}-${end}`, quests: batchID }, null, 2));

    const batchCU = cuQuests.filter(q => {
        const level = parseInt(q.id.split('_L')[1].split('_Q')[0]);
        return level >= start && level <= end;
    });
    fs.writeFileSync(`c:/Users/asus/Documents/App Projects/vowl/assets/curriculum/vocabulary/contextualUsage_${start}_${end}.json`, JSON.stringify({ gameType: "contextualUsage", batchIndex: b, levels: `${start}-${end}`, quests: batchCU }, null, 2));
}

console.log("BATCH 3 COMPLETE: Idioms and Contextual Usage reconstructed.");
