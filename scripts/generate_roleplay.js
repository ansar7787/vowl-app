const fs = require('fs');
const path = require('path');
const pools = require('./roleplay_pools');

const TOTAL_LEVELS = 200;
const QUESTIONS_PER_LEVEL = 3;
const BATCH_SIZE = 10;

const VOCAB = {
    name: ["Alex", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Jamie", "Peyton", "Quinn", "Avery", "Blake", "Charlie", "Dakota", "Emerson", "Finley", "Hayden", "Kai", "Logan", "Parker", "Reese", "Skyler", "Rowan", "Sawyer", "Phoenix", "River", "Sage", "Winter", "Robin", "Noel", "Jude", "Cameron", "Jesse", "Lee", "Micah", "Noa", "Remy", "Sasha", "Teagan", "Kit", "Bryn", "Ariel", "Brooklyn", "Dallas", "Eden", "Harley", "Indigo", "Justice", "Kennedy", "Marlowe", "North", "Oakley", "Paris", "Rain", "Sky", "Tatum", "Umber", "Vale", "Wren", "Xavier", "Yael", "Zion"],
    location: ["New York", "London", "Tokyo", "Paris", "Berlin", "Sydney", "Toronto", "Dubai", "Singapore", "Rome", "Hong Kong", "Mumbai", "Seoul", "Madrid", "Chicago", "Amsterdam", "Vienna", "Bangkok", "Istanbul", "Stockholm", "San Francisco", "Barcelona", "Mexico City", "Cape Town", "Prague", "Lisbon", "Copenhagen", "Zurich", "Dublin", "Oslo", "Brussels", "Helsinki", "Warsaw", "Budapest", "Athens", "Munich", "Milan", "Venice", "Kyoto", "Taipei", "Rio de Janeiro", "Buenos Aires", "Lagos", "Nairobi", "Cairo", "Tel Aviv", "Moscow", "Beijing", "Shanghai", "Vancouver", "Montreal", "Los Angeles", "Seattle", "Miami", "Denver", "Austin", "Portland", "Boston", "San Diego", "Phoenix"],
    item: ["laptop", "smartphone", "package", "document", "briefcase", "umbrella", "camera", "tablet", "projector", "headset", "microphone", "passport", "ticket", "wallet", "keys", "calculator", "backpack", "charger", "notebook", "adapter", "watch", "glasses", "pen", "folder", "hard drive", "router", "scanner", "printer", "keyboard", "mouse", "monitor", "speaker", "coffee mug", "water bottle", "lunchbox", "badge", "diploma", "contract", "magazine", "flashlight", "easel", "compass", "thermometer", "microscope", "telescope", "stapler", "whiteboard", "calendar", "joystick", "headphones", "drone", "smartwatch", "fitness tracker", "e-reader", "console", "server", "switch", "webcam"],
    business: ["TechNova", "GlobalReach", "EcoSystems", "Stellar Solutions", "Apex Corp", "Prime Industries", "FutureWorks", "CoreVision", "SkyNet", "OmniCorp", "Cyberdyne", "WayneEnt", "StarkInd", "UmbrellaCorp", "WeylandYutani", "Hooli", "AcmeCorp", "Virtucon", "GloboGym", "Initech", "MassiveDynamic", "Soyuz", "Aperture", "BlackMesa", "Vault-Tec", "Abstergo", "Sinner", "Gringotts", "Wonka", "Duff", "Oceanic", "Cybercore", "DataStream", "InfiniTech", "AeroSystems", "BioGenedix", "NanoScale", "Terraform", "NovaSphere", "PulseDynamics", "QuantumFoundry", "Hyperion", "TitanIndustries", "Elysium", "Xenon", "Vertex", "Solstice", "Zenith", "Nadir", "Apex"],
    time: ["morning", "afternoon", "evening", "night", "lunchtime", "midnight", "dawn", "dusk", "noon"],
    feeling: ["anxious", "excited", "worried", "happy", "frustrated", "confused", "curious", "tired", "nervous", "confident", "surprised", "optimistic", "pessimistic", "calm", "impatient"],
    symptom: ["headache", "fever", "cough", "fatigue", "dizziness", "nausea", "back pain", "chest pain", "rash", "sore throat"]
};

const VISUAL_CONFIGS = [
    { painter: "NeuralNegotiationSync", shader: "brain_bloom", color: "0xFF00FFCC" },
    { painter: "EchoChamberSync", shader: "plasma_drift", color: "0xFF4CAF50" },
    { painter: "NexusCoreSync", shader: "neon_pulse", color: "0xFFE91E63" },
    { painter: "PurgeGridSync", shader: "void_ripple", color: "0xFFF44336" },
    { painter: "SanctumFlowSync", shader: "glitch_jitter", color: "0xFF9C27B0" },
    { painter: "VoidStasisSync", shader: "signal_ghosting", color: "0xFF00BCD4" },
    { painter: "ZenithBufferSync", shader: "data_cascade", color: "0xFFFF9800" },
    { painter: "ArchiveDecryptSync", shader: "terminal_flicker", color: "0xFF607D8B" },
    { painter: "CouncilHallSync", shader: "binary_pulse", color: "0xFF2196F3" }
];

function generateQuests(gameType, startLevel, endLevel) {
    const quests = [];
    const pool = pools[gameType];

    for (let level = startLevel; level <= endLevel; level++) {
        for (let q = 1; q <= QUESTIONS_PER_LEVEL; q++) {
            const seed = (level * 100) + q;
            const data = pool[(level + q) % pool.length];
            const visual = VISUAL_CONFIGS[level % VISUAL_CONFIGS.length];
            
            const context = {
                name: VOCAB.name[seed % VOCAB.name.length],
                location: VOCAB.location[(seed + 1) % VOCAB.location.length],
                item: VOCAB.item[(seed + 2) % VOCAB.item.length],
                business: VOCAB.business[(seed + 3) % VOCAB.business.length],
                time: VOCAB.time[(seed + 4) % VOCAB.time.length],
                feeling: VOCAB.feeling[(seed + 5) % VOCAB.feeling.length],
                symptom: VOCAB.symptom[(seed + 6) % VOCAB.symptom.length]
            };

            const replace = (str) => {
                if (!str) return str;
                return str.replace(/{{name}}/g, context.name)
                          .replace(/{{location}}/g, context.location)
                          .replace(/{{item}}/g, context.item)
                          .replace(/{{business}}/g, context.business)
                          .replace(/{{time}}/g, context.time)
                          .replace(/{{feeling}}/g, context.feeling)
                          .replace(/{{symptom}}/g, context.symptom);
            };

            const quest = {
                id: `${gameType}_l${level}_q${q}`,
                instruction: data.instruction,
                difficulty: Math.min(3, Math.floor(level / 70) + 1),
                subtype: gameType,
                interactionType: gameType === 'branchingDialogue' ? 'branching' : 'choice',
                xpReward: level,
                coinReward: level * 2,
                visual_config: {
                    painter_type: visual.painter,
                    primary_color: visual.color,
                    pulse_intensity: 0.5 + (level % 5) * 0.1,
                    shader_effect: visual.shader
                }
            };

            if (gameType === 'branchingDialogue') {
                quest.scene = replace(data.scene);
                quest.dialogues = data.nodes ? [
                    {
                        id: 'start',
                        speaker: replace(data.speaker),
                        text: replace(data.startText),
                        choices: data.choices.map(c => ({ text: replace(c.text), next: c.next }))
                    },
                    ...Object.entries(data.nodes).map(([id, node]) => ({
                        id: id,
                        speaker: replace(data.speaker),
                        text: replace(node.text),
                        choices: node.choices ? node.choices.map(c => ({ text: replace(c.text), next: c.next })) : null,
                        end: node.end || false
                    }))
                ] : [];
            } else {
                quest.situation = replace(data.scenario);
                quest.question = replace(data.question);
                quest.options = data.options.map(o => replace(o));
                quest.correctAnswerIndex = data.correctIndex;
                quest.hint = replace(data.hint);
            }

            quests.push(quest);
        }
    }
    return quests;
}

const modules = [
    'branchingDialogue', 'conflictResolver', 'elevatorPitch', 'emergencyHub',
    'gourmetOrder', 'jobInterview', 'medicalConsult', 'situationalResponse',
    'socialSpark', 'travelDesk'
];

const outBase = path.join(__dirname, '..', 'assets', 'curriculum', 'roleplay');
if (!fs.existsSync(outBase)) fs.mkdirSync(outBase, { recursive: true });

modules.forEach(gameType => {
    for (let batch = 0; batch < TOTAL_LEVELS / BATCH_SIZE; batch++) {
        const startLevel = batch * BATCH_SIZE + 1;
        const endLevel = (batch + 1) * BATCH_SIZE;
        const quests = generateQuests(gameType, startLevel, endLevel);

        const fileData = {
            gameType: gameType,
            batchIndex: batch + 1,
            levels: `${startLevel}-${endLevel}`,
            quests: quests
        };

        const fileName = `${gameType}_${startLevel}_${endLevel}.json`;
        fs.writeFileSync(path.join(outBase, fileName), JSON.stringify(fileData, null, 2));
    }
    console.log(`Generated all batches for ${gameType}`);
});

console.log("Roleplay Curriculum Generation Complete!");
