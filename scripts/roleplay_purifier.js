const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/roleplay';

function shuffle(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
}

const prefixMap = {
    'branchingDialogue': 'bd', 'conflictResolver': 'cr', 'elevatorPitch': 'ep', 'emergencyHub': 'eh',
    'gourmetOrder': 'go', 'jobInterview': 'ji', 'medicalConsult': 'mc', 'situationalResponse': 'sr',
    'socialSpark': 'ss', 'travelDesk': 'td'
};

const characters = [
    { name: "Captain Hektor", icon: "security" }, { name: "Dr. Elara", icon: "medical_services" },
    { name: "Chef O-Ring", icon: "restaurant" }, { name: "Pilot Jax", icon: "flight" },
    { name: "Merchant Kael", icon: "storefront" }, { name: "Agent Nyx", icon: "policy" }
];

const locations = ["The Command Bridge", "The Bio-Dome", "The Lower Foundry", "The Sky-Dock", "The Trade District", "The Med-Bay"];

function writeBatch(gameType, quests) {
    for (let batch = 0; batch < 20; batch++) {
        const startLevel = batch * 10 + 1;
        const endLevel = (batch + 1) * 10;
        const batchQuests = quests.slice(batch * 30, (batch + 1) * 30);
        batchQuests.forEach((q, idx) => {
            const level = startLevel + Math.floor(idx / 3);
            const qNum = (idx % 3) + 1;
            q.id = `${prefixMap[gameType]}_l${level}_q${qNum}`;
            q.xpReward = level * 3;
            q.coinReward = level * 5;
            q.visual_config = { painter_type: "RoleplayPulseSync", primary_color: "0xFF00D2FF" };
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

// 1. Branching Dialogue (Visual Storyboard)
function purifyBranching() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        const char = characters[i % characters.length];
        quests.push({
            instruction: "Navigate the social protocol.",
            difficulty: 1,
            subtype: "branchingDialogue",
            interactionType: "dialogue",
            persona: char.name,
            scene: `Location: ${locations[i % locations.length]}`,
            options: ["Request assistance", "Maintain silence", "Scan for data"],
            correctAnswerIndex: 0,
            hint: "Cooperation is key.",
            explanation: "Dialogue shapes the story."
        });
    }
    writeBatch('branchingDialogue', quests);
}

// 2. Conflict Resolver (Empathy Slider)
function purifyConflict() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Balance the emotional frequency.",
            difficulty: 1,
            subtype: "conflictResolver",
            interactionType: "slider",
            scene: "An argument breaks out over fuel rations.",
            empathyScore: 0.75, // Target value
            correctAnswer: "Empathy",
            hint: "Don't be too aggressive or too soft.",
            explanation: "Conflict requires calibration."
        });
    }
    writeBatch('conflictResolver', quests);
}

// 3. Elevator Pitch (Speech Countdown)
function purifyElevator() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Deliver the pitch before the lift opens.",
            difficulty: 1,
            subtype: "elevatorPitch",
            interactionType: "voice",
            prompt: "Explain the flux capacitor in 10 seconds.",
            correctAnswer: "The flux capacitor is the core of the engine.",
            hint: "Be concise and clear.",
            explanation: "Speed is essential."
        });
    }
    writeBatch('elevatorPitch', quests);
}

// 4. Emergency Hub (Urgency Typing)
function purifyEmergency() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Dispatch the response unit immediately!",
            difficulty: 1,
            subtype: "emergencyHub",
            interactionType: "typing",
            dispatcherQuestion: "What is the emergency code?",
            correctAnswer: "CODE RED 99",
            hint: "Type quickly and accurately.",
            explanation: "Seconds count."
        });
    }
    writeBatch('emergencyHub', quests);
}

// 5. Gourmet Order (Menu Card Tap)
function purifyGourmet() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Tap the items to fulfill the client's order.",
            difficulty: 1,
            subtype: "gourmetOrder",
            interactionType: "selection",
            prompt: "I'll have the space-soup and a lunar-cake.",
            options: ["Space-Soup", "Lunar-Cake", "Void-Tea", "Star-Fruit"],
            correctAnswer: "Space-Soup, Lunar-Cake",
            hint: "Select both items mentioned.",
            explanation: "Accuracy builds trust."
        });
    }
    writeBatch('gourmetOrder', quests);
}

// 6. Job Interview (Professionalism Rating)
function purifyJob() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Answer to maximize your professionalism score.",
            difficulty: 1,
            subtype: "jobInterview",
            interactionType: "rating",
            interviewerQuestion: "Where do you see yourself in 5 solar cycles?",
            options: ["Leading the fleet", "In the Void", "I don't know"],
            correctAnswerIndex: 0,
            professionalismRating: 5,
            hint: "Ambition is valued here.",
            explanation: "First impressions are vital."
        });
    }
    writeBatch('jobInterview', quests);
}

// 7. Medical Consult (Symptom Map)
function purifyMedical() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Identify the biological glitch locations.",
            difficulty: 1,
            subtype: "medicalConsult",
            interactionType: "mapping",
            prompt: "Patient reports pain in the left limb and central core.",
            symptoms: ["Left Limb", "Central Core", "Right Wing", "Head Sensor"],
            correctAnswer: "Left Limb, Central Core",
            hint: "Check the limb first.",
            explanation: "Diagnosis requires precision."
        });
    }
    writeBatch('medicalConsult', quests);
}

// 8. Situational Response (Reaction Bubbles)
function purifySituational() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Choose the bubble that fits the mood.",
            difficulty: 1,
            subtype: "situationalResponse",
            interactionType: "bubbles",
            scene: "You just found a lost data chip.",
            options: ["Excited!", "Curious", "Afraid", "Bored"],
            correctAnswerIndex: 1,
            hint: "Data is valuable knowledge.",
            explanation: "Emotion guides interaction."
        });
    }
    writeBatch('situationalResponse', quests);
}

// 9. Social Spark (Icebreaker Reorder)
function purifySocial() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Order the words to start a conversation.",
            difficulty: 1,
            subtype: "socialSpark",
            interactionType: "reorder",
            shuffledWords: ["Hello", "the", "how", "is", "weather", "?"],
            correctAnswer: "Hello how is the weather ?",
            hint: "Start with a greeting.",
            explanation: "Politeness opens doors."
        });
    }
    writeBatch('socialSpark', quests);
}

// 10. Travel Desk (Itinerary Match)
function purifyTravel() {
    const quests = [];
    for (let i = 0; i < 600; i++) {
        quests.push({
            instruction: "Match the destination to the client's request.",
            difficulty: 1,
            subtype: "travelDesk",
            interactionType: "match",
            prompt: "I want to see the stars up close.",
            itinerary: ["Star-Observatory", "Foundry", "Archive", "Void"],
            options: ["Observatory", "Factory", "Library", "Darkness"],
            correctAnswerIndex: 0,
            hint: "Stars are observed from specific points.",
            explanation: "Navigation is a skill."
        });
    }
    writeBatch('travelDesk', quests);
}

purifyBranching();
purifyConflict();
purifyElevator();
purifyEmergency();
purifyGourmet();
purifyJob();
purifyMedical();
purifySituational();
purifySocial();
purifyTravel();

console.log("Roleplay Revolution: 10 Unique Archetypes Implemented Across 6,000 Quests.");
