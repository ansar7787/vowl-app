
const fs = require('fs');

const IRREGULAR_VERBS = {
    "bind": "bound", "build": "built", "make": "made", "feed": "fed", "find": "found",
    "write": "written", "buy": "bought", "sell": "sold", "take": "taken", "give": "given",
    "send": "sent", "bring": "brought", "catch": "caught", "choose": "chosen", "draw": "drawn",
    "drink": "drunk", "drive": "driven", "eat": "eaten", "fall": "fallen", "forget": "forgotten",
    "freeze": "frozen", "grow": "grown", "hide": "hidden", "know": "known", "ride": "ridden",
    "see": "seen", "shake": "shaken", "speak": "spoken", "steal": "stolen", "throw": "thrown",
    "wake": "woken", "wear": "worn", "win": "won"
};

const SUBJECTS = ["The technician", "The explorer", "The pilot", "The scientist", "The commander", "The droid", "The analyst", "The engineer"];
const OBJECTS = ["the data", "the circuit", "the portal", "the reactor", "the signal", "the system", "the module", "the archive"];
const ADVERBS = ["quickly", "silently", "efficiently", "carefully", "immediately", "successfully"];

function getPastParticiple(verb) {
    if (IRREGULAR_VERBS[verb]) return IRREGULAR_VERBS[verb];
    if (verb.endsWith('e')) return verb + 'd';
    return verb + 'ed';
}

function generateVoiceSwap() {
    const quests = [];
    const verbs = ["build", "analyze", "create", "protect", "send", "receive", "observe", "repair", "activate", "monitor"];
    
    for (let i = 0; i < 600; i++) {
        const sub = SUBJECTS[i % SUBJECTS.length];
        const obj = OBJECTS[(i + 1) % OBJECTS.length];
        const verb = verbs[i % verbs.length];
        const adv = ADVERBS[i % ADVERBS.length];
        const tier = i < 200 ? 1 : (i < 400 ? 2 : 3);
        
        let active, passive;
        if (tier === 1) { // Present Simple
            active = `${sub} ${verb}s ${obj} ${adv}.`;
            passive = `${obj.charAt(0).toUpperCase() + obj.slice(1)} is ${getPastParticiple(verb)} by ${sub.toLowerCase()} ${adv}.`;
        } else if (tier === 2) { // Past Simple
            active = `${sub} ${getPastParticiple(verb)} ${obj} ${adv}.`;
            passive = `${obj.charAt(0).toUpperCase() + obj.slice(1)} was ${getPastParticiple(verb)} by ${sub.toLowerCase()} ${adv}.`;
        } else { // Future
            active = `${sub} will ${verb} ${obj} ${adv}.`;
            passive = `${obj.charAt(0).toUpperCase() + obj.slice(1)} will be ${getPastParticiple(verb)} by ${sub.toLowerCase()} ${adv}.`;
        }

        quests.push({
            id: `GRM_VOICESWAP_L${Math.floor(i/3)+1}_Q${(i%3)+1}`,
            instruction: "TRANSMUTE VOICE",
            difficulty: tier,
            subtype: "voiceSwap",
            interactionType: "speaking",
            sentence: active,
            correctAnswer: passive,
            hint: "Focus on who or what receives the action.",
            explanation: "In passive voice, the object of the active sentence becomes the subject.",
            visual_config: { 
                painter_type: "BlueprintGridSync", 
                primary_color: "0xFF03A9F4",
                pulse_intensity: 1.0
            }
        });
    }
    return quests;
}

const data = generateVoiceSwap();
for (let b = 1; b <= 20; b++) {
    const start = (b - 1) * 10 + 1;
    const end = b * 10;
    const batch = data.filter(q => {
        const level = parseInt(q.id.split('_L')[1].split('_Q')[0]);
        return level >= start && level <= end;
    });
    fs.writeFileSync(`c:/Users/asus/Documents/App Projects/vowl/assets/curriculum/grammar/voiceSwap_${start}_${end}.json`, JSON.stringify({ gameType: "voiceSwap", batchIndex: b, levels: `${start}-${end}`, quests: batch }, null, 2));
}

console.log("VOICE SWAP PURIFICATION COMPLETE: 600 accurate active/passive missions created.");
