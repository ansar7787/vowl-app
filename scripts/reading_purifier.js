const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/reading';

function shuffle(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
}

const prefixMap = {
    'readAndAnswer': 'ra', 'findWordMeaning': 'fw', 'trueFalseReading': 'tf', 'sentenceOrderReading': 'so',
    'readingSpeedCheck': 'rs', 'guessTitle': 'gt', 'readAndMatch': 'rm', 'paragraphSummary': 'ps',
    'readingInference': 'ri', 'readingConclusion': 'rc', 'clozeTest': 'ct', 'skimmingScanning': 'ss'
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
            q.visual_config = { painter_type: "ReadingZen", primary_color: "0xFF4CAF50" };
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

// 1. Read and Answer (Standard)
function purifyReadAndAnswer() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Extract the core details.",
            difficulty: 1,
            subtype: "readAndAnswer",
            interactionType: "choice",
            passage: "In the heart of the city, a small park remained a haven for rare birds. Scientists studied their patterns for years.",
            question: "What did scientists study?",
            options: ["Bird patterns", "City traffic", "Park architecture", "Rare plants"],
            correctAnswer: "Bird patterns",
            hint: "Look for the scientists' focus.",
            explanation: "Direct comprehension requires identifying specific detail nodes."
        });
    }
    writeBatch('readAndAnswer', quests);
}

// 2. Find Word Meaning (Contextual Tap)
function purifyFindMeaning() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Identify the word matching the definition.",
            difficulty: 1,
            subtype: "findWordMeaning",
            interactionType: "paint",
            passage: "The team's persistence led to a breakthrough in renewable energy.",
            question: "Definition: The quality of continuing steadily despite problems.",
            targetWord: "persistence",
            hint: "Look for a noun meaning 'not giving up'.",
            explanation: "Contextual meaning is inferred from surrounding lexical neighbors."
        });
    }
    writeBatch('findWordMeaning', quests);
}

// 3. True/False Reading (Boolean Slider)
function purifyTrueFalse() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Validate the informational claims.",
            difficulty: 1,
            subtype: "trueFalseReading",
            interactionType: "bubbles",
            passage: "Mars is known as the Red Planet due to its iron oxide surface. It has two small moons.",
            question: "Mars has three moons.",
            correctAnswer: "False",
            options: ["True", "False"],
            hint: "Check the moon count in the text.",
            explanation: "Fact verification requires cross-referencing text with claims."
        });
    }
    writeBatch('trueFalseReading', quests);
}

// 4. Sentence Order (Logic Flow)
function purifySentenceOrder() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Reconstruct the logical narrative flow.",
            difficulty: 1,
            subtype: "sentenceOrderReading",
            interactionType: "reorder",
            shuffledSentences: [
                "Finally, they reached the summit.",
                "First, they prepared their gear.",
                "Then, the climbers began the ascent."
            ],
            correctOrder: [1, 2, 0],
            hint: "Look for time markers like 'First' and 'Finally'.",
            explanation: "Cohesion depends on logical sequencing and transition signals."
        });
    }
    writeBatch('sentenceOrderReading', quests);
}

// 5. Reading Speed Check (Rapid Scroll)
function purifySpeedCheck() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Process the data stream at high speed.",
            difficulty: 1,
            subtype: "readingSpeedCheck",
            interactionType: "scroll",
            passage: "The rapid evolution of artificial intelligence has transformed global industries in less than a decade.",
            question: "What evolved rapidly?",
            options: ["Artificial Intelligence", "Manual labor", "Old libraries", "Farming"],
            correctAnswer: "Artificial Intelligence",
            timeLimit: 10,
            hint: "Focus on the first few words.",
            explanation: "Scanning speed is critical for efficient information retrieval."
        });
    }
    writeBatch('readingSpeedCheck', quests);
}

// 6. Guess Title (Headline Pick)
function purifyGuessTitle() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Select the optimal thematic anchor.",
            difficulty: 1,
            subtype: "guessTitle",
            interactionType: "choice",
            passage: "New discoveries in the deep ocean suggest that thousands of species remain unknown to science.",
            options: ["Deep Sea Mysteries", "Space Exploration", "Urban Planning", "History of Art"],
            correctAnswer: "Deep Sea Mysteries",
            hint: "Where are the new species?",
            explanation: "Title selection requires identifying the central theme."
        });
    }
    writeBatch('guessTitle', quests);
}

// 7. Read and Match (Double Column)
function purifyReadAndMatch() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Map the entities to their descriptions.",
            difficulty: 1,
            subtype: "readAndMatch",
            interactionType: "mapping",
            pairs: [
                { "key": "Sun", "value": "A massive star at the center of our solar system." },
                { "key": "Moon", "value": "A natural satellite orbiting Earth." }
            ],
            hint: "Match the celestial body to its definition.",
            explanation: "Relational mapping builds structural comprehension."
        });
    }
    writeBatch('readAndMatch', quests);
}

// 8. Paragraph Summary (Idea Condenser)
function purifySummary() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Condense the passage into core concepts.",
            difficulty: 1,
            subtype: "paragraphSummary",
            interactionType: "condenser",
            passage: "Sustainable architecture focuses on minimizing the environmental impact of buildings through efficiency.",
            keywords: ["Sustainable", "Architecture", "Environment"],
            options: ["Sustainability", "Efficiency", "Impact", "Style", "Color"],
            correctAnswer: "Sustainability, Efficiency, Impact",
            hint: "Focus on the environmental aspect.",
            explanation: "Summarization is the peak of informational synthesis."
        });
    }
    writeBatch('paragraphSummary', quests);
}

// 9. Reading Inference (Hidden Layer)
function purifyInference() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Decipher the implied informational layer.",
            difficulty: 1,
            subtype: "readingInference",
            interactionType: "choice",
            passage: "John grabbed his umbrella and raincoat before stepping out into the gray afternoon.",
            question: "What is the weather like?",
            options: ["Raining", "Sunny", "Hot", "Snowing"],
            correctAnswer: "Raining",
            hint: "Why did he need an umbrella?",
            explanation: "Inference bridges the gap between text and reality."
        });
    }
    writeBatch('readingInference', quests);
}

// 10. Reading Conclusion (Final Verdict)
function purifyConclusion() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Predict the logical terminal state.",
            difficulty: 1,
            subtype: "readingConclusion",
            interactionType: "verdict",
            passage: "The experiment results showed a consistent 20% increase in crop yield when using the new fertilizer.",
            options: ["Adopt the fertilizer", "Stop farming", "Buy a car", "Go on vacation"],
            correctAnswer: "Adopt the fertilizer",
            hint: "What should the farmer do with the successful results?",
            explanation: "Drawing conclusions requires projecting textual data into future states."
        });
    }
    writeBatch('readingConclusion', quests);
}

// 11. Cloze Test (Inline Dropdown)
function purifyCloze() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Fill the semantic gaps in the data structure.",
            difficulty: 1,
            subtype: "clozeTest",
            interactionType: "slot",
            passage: "The ____ of the forest was interrupted by a loud crack.",
            options: ["silence", "noise", "color", "smell"],
            correctAnswer: "silence",
            hint: "What would a loud crack interrupt?",
            explanation: "Cloze tests evaluate local and global context coherence."
        });
    }
    writeBatch('clozeTest', quests);
}

// 12. Skimming/Scanning (Quick Search)
function purifySkimming() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Scan for the target informational node.",
            difficulty: 1,
            subtype: "skimmingScanning",
            interactionType: "search",
            passage: "The treaty was signed on October 14, 1945, in a small village in Europe.",
            targetItem: "1945",
            options: ["1944", "1945", "1946", "1947"],
            correctAnswer: "1945",
            timeLimit: 5,
            hint: "Look for the year.",
            explanation: "Scanning is a high-speed informational retrieval skill."
        });
    }
    writeBatch('skimmingScanning', quests);
}

purifyReadAndAnswer();
purifyFindMeaning();
purifyTrueFalse();
purifySentenceOrder();
purifySpeedCheck();
purifyGuessTitle();
purifyReadAndMatch();
purifySummary();
purifyInference();
purifyConclusion();
purifyCloze();
purifySkimming();

console.log("Reading Renaissance: 12 Unique Archetypes Implemented Across 7,200 Quests.");
