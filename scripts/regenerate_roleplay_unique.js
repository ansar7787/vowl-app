const fs = require('fs');
const path = require('path');

const TOTAL_LEVELS = 200;
const QUESTIONS_PER_LEVEL = 3;
const BATCH_SIZE = 10;

const VOCAB = {
    name: ["Alex", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Jamie", "Peyton", "Quinn", "Avery", "Blake", "Charlie", "Dakota", "Emerson", "Finley", "Hayden", "Kai", "Logan", "Parker", "Reese", "Skyler", "Rowan", "Sawyer", "Phoenix", "River", "Sage", "Winter", "Robin", "Noel", "Jude", "Cameron", "Jesse", "Lee", "Micah", "Noa", "Remy", "Sasha", "Teagan", "Kit", "Bryn", "Ariel", "Brooklyn", "Dallas", "Eden", "Harley", "Indigo", "Justice", "Kennedy", "Marlowe", "North", "Oakley", "Paris", "Rain", "Sky", "Tatum", "Umber", "Vale", "Wren", "Xavier", "Yael", "Zion", "Sloan", "Parker", "Ellis", "Marlow", "Hollis"],
    location: ["New York", "London", "Tokyo", "Paris", "Berlin", "Sydney", "Toronto", "Dubai", "Singapore", "Rome", "Hong Kong", "Mumbai", "Seoul", "Madrid", "Chicago", "Amsterdam", "Vienna", "Bangkok", "Istanbul", "Stockholm", "San Francisco", "Barcelona", "Mexico City", "Cape Town", "Prague", "Lisbon", "Copenhagen", "Zurich", "Dublin", "Oslo", "Brussels", "Helsinki", "Warsaw", "Budapest", "Athens", "Munich", "Milan", "Venice", "Kyoto", "Taipei", "Rio de Janeiro", "Buenos Aires", "Lagos", "Nairobi", "Cairo", "Tel Aviv", "Moscow", "Beijing", "Shanghai", "Vancouver", "Montreal", "Los Angeles", "Seattle", "Miami", "Denver", "Austin", "Portland", "Boston", "San Diego", "Phoenix"],
    item: ["laptop", "smartphone", "package", "document", "briefcase", "umbrella", "camera", "tablet", "projector", "headset", "microphone", "passport", "ticket", "wallet", "keys", "calculator", "backpack", "charger", "notebook", "adapter", "watch", "glasses", "pen", "folder", "hard drive", "router", "scanner", "printer", "keyboard", "mouse", "monitor", "speaker", "coffee mug", "water bottle", "lunchbox", "badge", "diploma", "contract", "magazine", "flashlight", "microphone", "easel", "compass", "thermometer", "microscope", "telescope", "stapler", "whiteboard", "calendar", "joystick", "headphones", "drone", "smartwatch", "fitness tracker", "e-reader", "console", "server", "switch", "webcam"],
    business: ["TechNova", "GlobalReach", "EcoSystems", "Stellar Solutions", "Apex Corp", "Prime Industries", "FutureWorks", "CoreVision", "SkyNet", "OmniCorp", "Cyberdyne", "WayneEnt", "StarkInd", "UmbrellaCorp", "WeylandYutani", "Hooli", "AcmeCorp", "Virtucon", "GloboGym", "Initech", "MassiveDynamic", "Soyuz", "Aperture", "BlackMesa", "Vault-Tec", "Abstergo", "Sinner", "Gringotts", "Wonka", "Duff", "Oceanic", "Cybercore", "DataStream", "InfiniTech", "AeroSystems", "BioGenedix", "NanoScale", "Terraform", "NovaSphere", "PulseDynamics", "QuantumFoundry", "Hyperion", "TitanIndustries", "Elysium", "Xenon", "Vertex", "Solstice", "Zenith", "Nadir", "Apex"],
    time: ["morning", "afternoon", "evening", "night", "lunchtime", "midnight", "dawn", "dusk", "noon"],
    feeling: ["anxious", "excited", "worried", "happy", "frustrated", "confused", "curious", "tired", "nervous", "confident", "surprised", "optimistic", "pessimistic", "calm", "impatient"],
};

const SYMPTOMS = ["headache", "fever", "cough", "fatigue", "dizziness", "nausea", "back pain", "chest pain", "rash", "sore throat"];

const TEMPLATES = [
    {
        scene: "Salary Negotiation",
        instruction: "Negotiate a fair salary increase for your role.",
        speaker: "Manager ({{name}})",
        startText: "I've reviewed your performance at {{business}}. You've done well, but our budget for {{item}} projects is tight. What are your expectations for the next {{time}}?",
        choices: [
            { text: "I'm looking for a 15% increase given my recent contributions to the {{location}} office.", next: "justify_raise" },
            { text: "I'd like to discuss a promotion to a senior role.", next: "discuss_promotion" }
        ],
        nodes: {
            justify_raise: {
                text: "That's a significant jump. Can you justify that based on the {{item}} metrics?",
                choices: [
                    { text: "Absolutely, I've increased efficiency by 20% and handled the {{location}} expansion.", next: "end_success" },
                    { text: "I've taken on many extra responsibilities this {{time}}.", next: "end_neutral" }
                ]
            },
            discuss_promotion: {
                text: "A senior role requires more leadership. How would you handle the {{business}} team?",
                choices: [
                    { text: "I'd focus on mentoring and streamlining our {{item}} workflow.", next: "end_success" },
                    { text: "I'm ready for the challenge and have a clear vision.", next: "end_success" }
                ]
            },
            end_success: { text: "I'm impressed with your vision. Let's make it happen.", end: true },
            end_neutral: { text: "I'll need to run these numbers by HR. Let's talk next {{time}}.", end: true }
        }
    },
    {
        scene: "Crisis: Security Breach",
        instruction: "Handle a potential security breach at the office.",
        speaker: "Security Lead ({{name}})",
        startText: "We've detected a suspicious login attempt on the {{item}} server from a {{location}} IP address. What's our protocol?",
        choices: [
            { text: "Isolate the server immediately and reset all {{business}} credentials.", next: "isolate_server" },
            { text: "Monitor the traffic to see what they're after before acting.", next: "monitor_traffic" }
        ],
        nodes: {
            isolate_server: {
                text: "Server isolated. The {{business}} team is reporting downtime. Should we issue a statement?",
                choices: [
                    { text: "Yes, transparency is key. Tell them we're performing urgent maintenance.", next: "end_success" },
                    { text: "Not yet. Let's find the source of the {{location}} attack first.", next: "end_neutral" }
                ]
            },
            monitor_traffic: {
                text: "They're attempting to access the {{item}} database. This is getting {{feeling}}.",
                choices: [
                    { text: "That's enough. Cut the connection now!", next: "end_success" },
                    { text: "Can we trace the IP back to the {{location}} provider?", next: "end_success" }
                ]
            },
            end_success: { text: "Crisis averted for now. Let's run a full audit this {{time}}.", end: true },
            end_neutral: { text: "Understood. Keep me updated on any further developments.", end: true }
        }
    },
    {
        scene: "Travel: Flight Cancellation",
        instruction: "Negotiate a solution after your flight is cancelled.",
        speaker: "Gate Agent ({{name}})",
        startText: "I'm afraid the flight to {{location}} has been cancelled due to weather. I'm feeling {{feeling}} about the delay.",
        choices: [
            { text: "I have a vital {{item}} meeting at {{business}}! Can you put me on the next flight?", next: "request_priority" },
            { text: "That's unfortunate. Can I get a voucher for a hotel in the city?", next: "request_voucher" }
        ],
        nodes: {
            request_priority: {
                text: "The next flight is fully booked. I can put you on standby for the {{time}} departure.",
                choices: [
                    { text: "Please do. I'll wait near the gate.", next: "end_success" },
                    { text: "Is there any other airline flying to {{location}} today?", next: "end_neutral" }
                ]
            },
            request_voucher: {
                text: "Since it's weather-related, {{business}} policy doesn't cover hotels, but I can offer a discount.",
                choices: [
                    { text: "I appreciate that. I'll take the discount voucher.", next: "end_success" },
                    { text: "I'd like to speak with a manager about the {{item}} situation.", next: "end_neutral" }
                ]
            },
            end_success: { text: "Thank you for your patience during this {{time}}.", end: true },
            end_neutral: { text: "I'll see what I can do. Please wait here.", end: true }
        }
    },
    {
        scene: "Social: Neighborhood Noise",
        instruction: "Politely address a noise issue with your neighbor.",
        speaker: "Neighbor ({{name}})",
        startText: "Oh, hi! I didn't realize my music was so loud. Was it bothering your {{time}} study session?",
        choices: [
            { text: "Actually, yes. I'm working on a {{item}} project for {{business}}.", next: "explain_work" },
            { text: "It's okay, just a bit loud for the {{location}} evening.", next: "gentle_request" }
        ],
        nodes: {
            explain_work: {
                text: "I'm so sorry! I'll turn it down immediately. Is it okay now?",
                choices: [
                    { text: "Much better, thank you! I appreciate the {{feeling}} response.", next: "end_success" }
                ]
            },
            gentle_request: {
                text: "I'll lower the bass. Sometimes I get too carried away with my new {{item}} setup.",
                choices: [
                    { text: "I understand, it sounds like a great system!", next: "end_success" },
                    { text: "Thanks, I'd appreciate that. Have a good {{time}}.", next: "end_success" }
                ]
            },
            end_success: { text: "No worries at all. See you around the building!", end: true }
        }
    },
    {
        scene: "Professional: Difficult Feedback",
        instruction: "Give constructive feedback to a colleague.",
        speaker: "Colleague ({{name}})",
        startText: "I'm {{feeling}} about the feedback you gave on my {{item}} report for the {{location}} project.",
        choices: [
            { text: "I appreciate your hard work, but we need to refine the {{business}} strategy.", next: "refine_strategy" },
            { text: "It was just a draft! Let's work on the final version together this {{time}}.", next: "collaborate" }
        ],
        nodes: {
            refine_strategy: {
                text: "I see. What specifically should I change to meet {{business}} standards?",
                choices: [
                    { text: "Let's focus on the data from {{location}} and simplify the {{item}} specs.", next: "end_success" },
                    { text: "I think we need to rethink the whole approach to {{item}}.", next: "end_neutral" }
                ]
            },
            collaborate: {
                text: "That sounds much better. I'll bring the latest {{item}} data.",
                choices: [
                    { text: "Perfect. Let's meet in the lobby at {{time}}.", next: "end_success" }
                ]
            },
            end_success: { text: "I'm glad we're on the same page. Let's make this the best repo yet.", end: true },
            end_neutral: { text: "Okay, I'll take a look and get back to you later this {{time}}.", end: true }
        }
    },
    {
        scene: "Sales: Software Demo",
        instruction: "Convince a prospect to try your new software.",
        speaker: "Prospect ({{name}})",
        startText: "We already use a {{item}} system at {{business}}. Why should we switch to your {{location}} based app?",
        choices: [
            { text: "Our platform integrates AI to automate your {{item}} workflow, saving hours every {{time}}.", next: "highlight_ai" },
            { text: "We offer superior security and local support in {{location}}.", next: "highlight_support" }
        ],
        nodes: {
            highlight_ai: {
                text: "Automation sounds interesting. But is it easy for the {{business}} team to learn?",
                choices: [
                    { text: "It's designed with simplicity in mind. I can show you a 5-minute {{item}} demo.", next: "offer_demo" },
                    { text: "We provide full training for everyone in the {{location}} office.", next: "end_success" }
                ]
            },
            highlight_support: {
                text: "Security is vital. How do you handle {{item}} data encryption?",
                choices: [
                    { text: "We use end-to-end encryption compliant with all {{location}} regulations.", next: "end_success" }
                ]
            },
            offer_demo: {
                text: "Alright, let's see what this {{item}} tech can really do.",
                choices: [
                    { text: "Coming right up. You'll be impressed by the {{business}} integration.", next: "end_success" }
                ]
            },
            end_success: { text: "That was very impressive. Let's set up a trial period for next {{time}}.", end: true }
        }
    },
    {
        scene: "Crisis: Product Recall",
        instruction: "Manage a customer's concern about a product recall.",
        speaker: "Customer ({{name}})",
        startText: "I heard on the {{location}} news that my {{item}} has been recalled! I'm feeling very {{feeling}} about this.",
        choices: [
            { text: "I understand your concern. At {{business}}, safety is our top priority.", next: "explain_recall" },
            { text: "Is your {{item}} showing any of the reported issues?", next: "check_issues" }
        ],
        nodes: {
            explain_recall: {
                text: "We're offering a free replacement or a full refund. Which would you prefer?",
                choices: [
                    { text: "I'd like a refund. I'll buy a different model in {{location}}.", next: "end_success" },
                    { text: "Can you send the replacement to my office at {{business}}?", next: "end_success" }
                ]
            },
            check_issues: {
                text: "Not yet, but I don't want to take any risks with my {{item}}.",
                choices: [
                    { text: "Smart move. Let's get your {{item}} registered for the recall program right now.", next: "end_success" }
                ]
            },
            end_success: { text: "Thank you for handling this so quickly. I feel much better now.", end: true }
        }
    },
    {
        scene: "Technical: Server Upgrade",
        instruction: "Discuss the server upgrade strategy.",
        speaker: "CTO ({{name}})",
        startText: "The {{business}} servers in {{location}} are reaching capacity. Should we upgrade the {{item}} hardware or move to the cloud?",
        choices: [
            { text: "Moving to the cloud offers better scalability for our {{item}} projects.", next: "cloud_move" },
            { text: "Upgrading our own hardware in {{location}} gives us more control over the {{item}} data.", next: "hardware_upgrade" }
        ],
        nodes: {
            cloud_move: {
                text: "That will take significant time. How do we handle the transition this {{time}}?",
                choices: [
                    { text: "We can phase it out, starting with the {{item}} microservices.", next: "end_success" },
                    { text: "I'll lead a task force to ensure a smooth {{business}} migration.", next: "end_success" }
                ]
            },
            hardware_upgrade: {
                text: "It's a big investment. Is the {{location}} facility ready for the {{item}} expansion?",
                choices: [
                    { text: "Yes, we've already secured the space and power for the new {{item}} racks.", next: "end_success" }
                ]
            },
            end_success: { text: "Excellent. Prepare a detailed {{item}} proposal for the board by next {{time}}.", end: true }
        }
    },
    {
        scene: "Everyday: Gym Membership",
        instruction: "Discuss your gym membership options.",
        speaker: "Gym Manager ({{name}})",
        startText: "Thinking of cancelling your membership? We'd hate to see you leave the {{location}} branch.",
        choices: [
            { text: "I've been too busy with my {{item}} project at {{business}} lately.", next: "too_busy" },
            { text: "Is there a more affordable plan for the {{time}}?", next: "price_check" }
        ],
        nodes: {
            too_busy: {
                text: "What if you freeze your account for a few months? No {{item}} fees involved.",
                choices: [
                    { text: "That sounds perfect! I'll be back in the {{time}}.", next: "end_success" },
                    { text: "I'd still rather cancel for now. It's too {{feeling}} to coordinate.", next: "end_neutral" }
                ]
            },
            price_check: {
                text: "We have a basic plan that only includes the {{item}} zone. It's 30% cheaper.",
                choices: [
                    { text: "That works for me. I mainly use the {{item}} anyway.", next: "end_success" }
                ]
            },
            end_success: { text: "Great! We've updated your status. Enjoy your workout!", end: true },
            end_neutral: { text: "We understand. Your membership will end this {{time}}.", end: true }
        }
    },
    {
        scene: "Social: Lost Dog",
        instruction: "Help a neighbor find their lost pet.",
        speaker: "Neighbor ({{name}})",
        startText: "Have you seen a small dog running around the {{location}} park? He's wearing a blue {{item}} collar.",
        choices: [
            { text: "I haven't, but I'll keep an eye out while I'm on my {{item}} run.", next: "keep_lookout" },
            { text: "I'll post a picture on the {{business}} community board!", next: "post_social" }
        ],
        nodes: {
            keep_lookout: {
                text: "Thank you! I'm so {{feeling}}. He's never run off like this before.",
                choices: [
                    { text: "Don't worry, we'll find him. Have you checked the {{location}} station?", next: "end_success" }
                ]
            },
            post_social: {
                text: "That would be a huge help! Here's a photo on my {{item}}.",
                choices: [
                    { text: "Got it. I'll share it with the whole {{location}} group.", next: "end_success" }
                ]
            },
            end_success: { text: "I really appreciate the help. Let me know if you hear anything this {{time}}.", end: true }
        }
    }
];

// Procedural generation for more variety
function getMoreTemplates() {
    const roles = [
        "Mentor", "Intern", "CEO", "Partner", "Analyst", "Developer", 
        "Founder", "HR Manager", "Scrum Master", "Product Owner",
        "Lead Designer", "Security Analyst", "Marketing Director"
    ];
    const contexts = [
        "Project Review", "Feedback Session", "Launch Planning", 
        "Budget Discussion", "Quarterly Audit", "Strategy Meeting",
        "Town Hall", "Technical Sync", "Client Briefing", "Sprint Retrospective"
    ];
    const feelings = ["excited", "cautious", "optimistic", "anxious", "determined", "skeptical", "confident"];
    
    const more = [];
    
    contexts.forEach((ctx, cIdx) => {
        roles.forEach((role, rIdx) => {
            const tone = (cIdx + rIdx) % 2 === 0 ? "formal" : "collaborative";
            const focusItem = (cIdx + rIdx) % 3 === 0 ? "item" : ((cIdx + rIdx) % 3 === 1 ? "business" : "location");
            
            more.push({
                scene: `${ctx} with a ${role}`,
                instruction: `Discuss the ${ctx} with your ${role} in a ${tone} manner.`,
                speaker: `${role} ({{name}})`,
                startText: `I've been reviewing the {{item}} progress for {{business}}. I'm feeling ${feelings[(cIdx + rIdx) % feelings.length]} about our milestones in {{location}}.`,
                choices: [
                    { text: tone === "formal" ? `I agree, we've made significant gains this {{time}}.` : `Yeah, I think the {{location}} team really stepped up.`, next: "pos" },
                    { text: tone === "formal" ? `There are still some challenges with the {{item}} delivery.` : `I'm actually a bit worried about the {{item}} quality.`, next: "neg" }
                ],
                nodes: {
                    pos: { 
                        text: `Exactly. I think we should double down on our strategy for the next {{time}}.`, 
                        choices: [{ text: "Let's proceed as planned.", next: "end" }] 
                    },
                    neg: { 
                        text: `I understand. We'll allocate more {{item}} resources to the {{location}} team to fix this.`, 
                        choices: [{ text: "That would be a great help.", next: "end" }] 
                    },
                    end: { text: `Let's touch base again during the next {{time}} sync.`, end: true }
                }
            });
        });
    });
    return more;
}

const ALL_TEMPLATES = [...TEMPLATES, ...getMoreTemplates()];

function applyVariation(template, level, qIndex) {
    const seed = (level * 1000) + (qIndex * 15);
    let s = seed;
    const nextRand = () => {
        s = (s * 9301 + 49297) % 233280;
        return s / 233280;
    };

    const getVal = (key) => {
        const options = VOCAB[key];
        return options[Math.floor(nextRand() * options.length)];
    };

    // Pre-calculate values for this quest to ensure consistency
    const context = {
        name: getVal('name'),
        location: getVal('location'),
        item: getVal('item'),
        business: getVal('business'),
        time: getVal('time'),
        feeling: getVal('feeling'),
        symptom: SYMPTOMS[Math.floor(nextRand() * SYMPTOMS.length)]
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

    const dialogues = [
        {
            id: 'start',
            speaker: replace(template.speaker),
            text: replace(template.startText),
            choices: template.choices.map(c => ({
                text: replace(c.text),
                next: c.next
            }))
        }
    ];

    for (let nodeId in template.nodes) {
        const node = template.nodes[nodeId];
        dialogues.push({
            id: nodeId,
            speaker: replace(template.speaker),
            text: replace(node.text),
            choices: node.choices ? node.choices.map(c => ({
                text: replace(c.text),
                next: c.next
            })) : null,
            end: node.end || false
        });
    }

    return {
        id: `branchingDialogue_l${level}_q${qIndex}`,
        scene: replace(template.scene),
        instruction: replace(template.instruction),
        difficulty: Math.min(3, Math.floor(level / 70) + 1),
        dialogues: dialogues
    };
}

const outBase = path.join(__dirname, '..', 'assets', 'curriculum', 'roleplay');
if (!fs.existsSync(outBase)) fs.mkdirSync(outBase, { recursive: true });

for (let batch = 0; batch < TOTAL_LEVELS / BATCH_SIZE; batch++) {
    const startLevel = batch * BATCH_SIZE + 1;
    const endLevel = (batch + 1) * BATCH_SIZE;
    const quests = [];

    for (let level = startLevel; level <= endLevel; level++) {
        for (let q = 1; q <= QUESTIONS_PER_LEVEL; q++) {
            const templateIndex = ((level - 1) * QUESTIONS_PER_LEVEL + (q - 1)) % ALL_TEMPLATES.length;
            const template = ALL_TEMPLATES[templateIndex];
            quests.push(applyVariation(template, level, q));
        }
    }

    const fileData = {
        gameType: "branchingDialogue",
        batchIndex: batch + 1,
        levels: `${startLevel}-${endLevel}`,
        quests: quests
    };

    const fileName = `branchingDialogue_${startLevel}_${endLevel}.json`;
    fs.writeFileSync(path.join(outBase, fileName), JSON.stringify(fileData, null, 2));
    console.log(`Generated ${fileName} with ${quests.length} quests.`);
}

console.log("Regeneration Complete! 600 unique quests generated.");
