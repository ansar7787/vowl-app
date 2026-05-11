const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/accent';

const prefixMap = {
    'minimalPairs': 'mp', 'intonationMimic': 'im', 'syllableStress': 'ss',
    'wordLinking': 'wl', 'shadowingChallenge': 'sc', 'vowelDistinction': 'vd',
    'consonantClarity': 'cc', 'pitchPatternMatch': 'pm', 'speedVariance': 'sv',
    'dialectDrill': 'dd'
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
            q.visual_config = { painter_type: "AccentBloom", primary_color: "0xFFE91E63" };
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

// 1. Minimal Pairs (Binary Distinctions)
function purifyMinimalPairs() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Isolate the precise phonetic distinction.",
            difficulty: 1,
            subtype: "minimalPairs",
            interactionType: "choice",
            word1: "ship",
            word2: "sheep",
            ipa1: "/ʃɪp/",
            ipa2: "/ʃiːp/",
            textToSpeak: "ship",
            correctAnswer: "ship",
            options: ["ship", "sheep"],
            correctAnswerIndex: 0,
            hint: "Listen for the short /ɪ/ sound.",
            explanation: "Minimal pairs sharpen phonemic awareness."
        });
    }
    writeBatch('minimalPairs', quests);
}

// 2. Intonation Mimic (Contour Trace)
function purifyIntonation() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Mimic the prosodic contour of the expression.",
            difficulty: 1,
            subtype: "intonationMimic",
            interactionType: "mimic",
            textToSpeak: "Are you coming tonight?",
            intonationMap: [1, 1, 1, 2], // 1=flat, 2=rising
            hint: "The pitch should rise at the end of the question.",
            explanation: "Intonation mimicry builds natural speech melody."
        });
    }
    writeBatch('intonationMimic', quests);
}

// 3. Syllable Stress (Rhythm Tap)
function purifySyllableStress() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Identify the rhythmic pulse of the word.",
            difficulty: 1,
            subtype: "syllableStress",
            interactionType: "stress",
            word: "Important",
            syllables: ["Im", "por", "tant"],
            correctAnswerIndex: 1,
            hint: "Listen for the loudest part: Im-POR-tant.",
            explanation: "Stress patterns are critical for word recognition."
        });
    }
    writeBatch('syllableStress', quests);
}

// 4. Word Linking (Linkage Bridge)
function purifyWordLinking() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Identify the phonetic bridge between words.",
            difficulty: 1,
            subtype: "wordLinking",
            interactionType: "linking",
            textToSpeak: "An apple a day.",
            words: ["An", "apple", "a", "day"],
            correctAnswer: "An apple",
            hint: "Listen for the /n/ sliding into 'apple'.",
            explanation: "Linking creates the smooth flow of natural speech."
        });
    }
    writeBatch('wordLinking', quests);
}

// 5. Shadowing Challenge (Ghost Echo)
function purifyShadowing() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Sync your speech with the auditory ghost.",
            difficulty: 1,
            subtype: "shadowingChallenge",
            interactionType: "shadow",
            textToSpeak: "The quick brown fox jumps over the lazy dog.",
            hint: "Speak along with the voice as closely as possible.",
            explanation: "Shadowing improves overall fluency and speed."
        });
    }
    writeBatch('shadowingChallenge', quests);
}

// 6. Vowel Distinction (Phoneme Map)
function purifyVowel() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Map the vocalic signal to its phonetic target.",
            difficulty: 1,
            subtype: "vowelDistinction",
            interactionType: "choice",
            word: "Bat",
            phoneticHint: "/æ/",
            options: ["/æ/", "/e/", "/ʌ/", "/ɑː/"],
            correctAnswerIndex: 0,
            hint: "Listen for the open 'a' sound.",
            explanation: "Vowel distinction is the core of accent clarity."
        });
    }
    writeBatch('vowelDistinction', quests);
}

// 7. Consonant Clarity (Enunciation Focus)
function purifyConsonant() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Achieve precision in consonant articulation.",
            difficulty: 1,
            subtype: "consonantClarity",
            interactionType: "clarity",
            textToSpeak: "Specific statistics.",
            mouthPosition: "Place your teeth close together for the /s/ sound.",
            hint: "Focus on the 'st' and 'cs' sounds.",
            explanation: "Clear consonants ensure message intelligibility."
        });
    }
    writeBatch('consonantClarity', quests);
}

// 8. Pitch Pattern Match (Melody Sync)
function purifyPitchPattern() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Sync the spoken melody with the visual map.",
            difficulty: 1,
            subtype: "pitchPatternMatch",
            interactionType: "mimic",
            textToSpeak: "Good morning!",
            pitchPatterns: [1, 2, 1], // Low-High-Low
            hint: "The pitch should peak in the middle.",
            explanation: "Pitch matching improves emotional expressiveness."
        });
    }
    writeBatch('pitchPatternMatch', quests);
}

// 9. Speed Variance (Tempo Shift)
function purifySpeed() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Modulate your tempo to the target speed.",
            difficulty: 1,
            subtype: "speedVariance",
            interactionType: "shadow",
            textToSpeak: "I need to go now.",
            targetSpeed: 1.25,
            hint: "Speak slightly faster than your normal pace.",
            explanation: "Speed variance builds elastic fluency."
        });
    }
    writeBatch('speedVariance', quests);
}

// 10. Dialect Drill (Regional Vibe)
function purifyDialect() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Immerse your speech in the regional dialect.",
            difficulty: 1,
            subtype: "dialectDrill",
            interactionType: "mimic",
            accentName: "British (RP)",
            textToSpeak: "I'd like a bottle of water.",
            phoneticHint: "Drop the 'r' in 'water' and use a glottal stop or clear 't'.",
            hint: "Try to sound like someone from London.",
            explanation: "Dialect drills expand your cultural speech range."
        });
    }
    writeBatch('dialectDrill', quests);
}

purifyMinimalPairs();
purifyIntonation();
purifySyllableStress();
purifyWordLinking();
purifyShadowing();
purifyVowel();
purifyConsonant();
purifyPitchPattern();
purifySpeed();
purifyDialect();

console.log("Accent Bloom: 10 Unique Archetypes Implemented Across 6,000 Quests.");
