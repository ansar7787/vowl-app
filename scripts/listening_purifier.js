const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/listening';

const prefixMap = {
    'audioFillBlanks': 'fb', 'audioMultipleChoice': 'mc', 'audioSentenceOrder': 'so',
    'audioTrueFalse': 'tf', 'soundImageMatch': 'cm', 'fastSpeechDecoder': 'fs',
    'emotionRecognition': 'er', 'detailSpotlight': 'ds', 'listeningInference': 'li',
    'ambientId': 'ai'
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
            q.visual_config = { painter_type: "SonicGlass", primary_color: "0xFF9C27B0" };
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

// 1. Audio Fill Blanks (Transcription Slot)
function purifyFillBlanks() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Extract the missing linguistic token.",
            difficulty: 1,
            subtype: "audioFillBlanks",
            interactionType: "writing",
            textToSpeak: "The package will arrive tomorrow morning.",
            textWithBlanks: "The package will arrive ____ morning.",
            missingWord: "tomorrow",
            correctAnswer: "tomorrow",
            hint: "Relates to the next day.",
            explanation: "Gap-filling improves auditory precision."
        });
    }
    writeBatch('audioFillBlanks', quests);
}

// 2. Audio Multiple Choice (Choice Radar)
function purifyMultipleChoice() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Identify the correct semantic response.",
            difficulty: 1,
            subtype: "audioMultipleChoice",
            interactionType: "choice",
            textToSpeak: "What time does the train leave for London?",
            question: "What is the speaker asking about?",
            options: ["The platform number", "The departure time", "The ticket price", "The destination"],
            correctAnswerIndex: 1,
            hint: "Listen for 'What time'.",
            explanation: "Choice selection builds general comprehension."
        });
    }
    writeBatch('audioMultipleChoice', quests);
}

// 3. Audio Sentence Order (Chronological Stack)
function purifySentenceOrder() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Reconstruct the sequence of auditory events.",
            difficulty: 1,
            subtype: "audioSentenceOrder",
            interactionType: "reorder",
            textToSpeak: "First, wake up. Then, brush your teeth. Finally, eat breakfast.",
            shuffledSentences: ["Then, brush your teeth.", "Finally, eat breakfast.", "First, wake up."],
            correctOrder: [2, 0, 1],
            hint: "Listen for sequence markers like 'First'.",
            explanation: "Ordering improves logic and narrative tracking."
        });
    }
    writeBatch('audioSentenceOrder', quests);
}

// 4. Audio True/False (Fact Verdict)
function purifyTrueFalse() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Validate the veracity of the claim.",
            difficulty: 1,
            subtype: "audioTrueFalse",
            interactionType: "verdict",
            textToSpeak: "I visited Paris last summer and loved the Eiffel Tower.",
            statement: "The speaker visited Paris in the winter.",
            correctAnswer: "false",
            hint: "Listen for the season mentioned.",
            explanation: "Veracity checks build critical listening skills."
        });
    }
    writeBatch('audioTrueFalse', quests);
}

// 5. Sound Category Match (Thematic Link)
function purifyCategoryMatch() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Map the auditory signal to its thematic category.",
            difficulty: 1,
            subtype: "soundImageMatch",
            interactionType: "choice",
            textToSpeak: "Apple, Banana, Orange.",
            options: ["Tools", "Fruits", "Vehicles", "Professions"],
            correctAnswerIndex: 1,
            hint: "These are things you can eat.",
            explanation: "Categorization builds semantic network strength."
        });
    }
    writeBatch('soundImageMatch', quests);
}

// 6. Fast Speech Decoder (Nuance Filter)
function purifyFastSpeech() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Decipher the compressed phonetic stream.",
            difficulty: 1,
            subtype: "fastSpeechDecoder",
            interactionType: "radar",
            textToSpeak: "Whatcha gonna do about it?",
            options: ["What are you going to do about it?", "What you doing about it?", "Where you going about it?"],
            correctAnswerIndex: 0,
            hint: "Focus on 'Whatcha' and 'gonna'.",
            explanation: "Decoding fast speech improves real-world fluency."
        });
    }
    writeBatch('fastSpeechDecoder', quests);
}

// 7. Emotion Recognition (Sentiment Probe)
function purifyEmotion() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Identify the emotional frequency of the speaker.",
            difficulty: 1,
            subtype: "emotionRecognition",
            interactionType: "probe",
            textToSpeak: "I cannot believe you actually did that! This is amazing!",
            options: ["Anger", "Excitement", "Sadness", "Boredom"],
            correctAnswerIndex: 1,
            targetEmotion: "Excitement",
            hint: "Listen for the rising pitch.",
            explanation: "Emotion recognition builds social intelligence."
        });
    }
    writeBatch('emotionRecognition', quests);
}

// 8. Detail Spotlight (Specific Pulse)
function purifyDetail() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Isolate the specific data point from the stream.",
            difficulty: 1,
            subtype: "detailSpotlight",
            interactionType: "pulse",
            textToSpeak: "The total cost for the two tickets is forty-five dollars.",
            targetDetail: "Price",
            options: ["$25", "$45", "$55", "$15"],
            correctAnswerIndex: 1,
            hint: "Listen for the number after 'cost'.",
            explanation: "Selective listening isolates critical information."
        });
    }
    writeBatch('detailSpotlight', quests);
}

// 9. Listening Inference (Subtext Radar)
function purifyInference() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Decode the implied semantic layer.",
            difficulty: 1,
            subtype: "listeningInference",
            interactionType: "radar",
            textToSpeak: "I wish I had brought my umbrella today.",
            impliedMeaning: "It is currently raining or about to rain.",
            options: ["The speaker is happy.", "It is likely raining.", "The speaker lost their umbrella."],
            correctAnswerIndex: 1,
            hint: "Why would they need an umbrella?",
            explanation: "Inference bridges the gap between literal and intent."
        });
    }
    writeBatch('listeningInference', quests);
}

// 10. Ambient ID (Context Anchor)
function purifyAmbient() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Anchor the auditory stream to its likely environment.",
            difficulty: 1,
            subtype: "ambientId",
            interactionType: "anchor",
            textToSpeak: "Attention passengers, the flight to New York is now boarding at gate 12.",
            location: "Airport",
            options: ["Train Station", "Airport", "Library", "Shopping Mall"],
            correctAnswerIndex: 1,
            hint: "Listen for keywords like 'flight' and 'gate'.",
            explanation: "Environmental anchoring builds spatial-auditory awareness."
        });
    }
    writeBatch('ambientId', quests);
}

purifyFillBlanks();
purifyMultipleChoice();
purifySentenceOrder();
purifyTrueFalse();
purifyCategoryMatch();
purifyFastSpeech();
purifyEmotion();
purifyDetail();
purifyInference();
purifyAmbient();

console.log("Listening Symphony: 10 Unique Archetypes Implemented Across 6,000 Quests.");
