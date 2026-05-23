const fs = require('fs');
const path = require('path');

// 1. Unique data for Elevator Pitch game (30 Quests, 3 per level for Levels 1-10)
const elevatorPitchQuests = [
  // Level 1: Foundations
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 1,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a smart water bottle that tracks cellular hydration dynamically.",
    correctAnswer: "It monitors cellular hydration to optimize daily vitality.",
    hint: "Focus on the vital health aspect.",
    explanation: "Emphasizing cell-level health creates high consumer interest.",
    id: "ep_l1_q1"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 1,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch an AI calendar that schedules meetings based on brain wave fatigue.",
    correctAnswer: "It syncs calendar invites to match natural mental energy peaks.",
    hint: "Mention productivity and cognitive efficiency.",
    explanation: "Productivity based on energy is a highly premium concept.",
    id: "ep_l1_q2"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 1,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a biodegradable sneaker made fully out of recycled coffee grounds.",
    correctAnswer: "Our sneakers transform daily coffee waste into stylish durable footwear.",
    hint: "Highlight circular sustainability and fashion.",
    explanation: "Unique organic materials create immediate brand distinctiveness.",
    id: "ep_l1_q3"
  },
  // Level 2: Fintech & Commerce
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 2,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a micro-lending app for local organic rooftop farmers.",
    correctAnswer: "It connects urban farmers directly with neighborhood capital instantly.",
    hint: "Focus on local community growth.",
    explanation: "Connecting micro-capital directly empowers urban development.",
    id: "ep_l2_q1"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 2,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a zero-fee contactless payment smart ring.",
    correctAnswer: "A sleek smart ring that replaces bulky wallets forever securely.",
    hint: "Emphasize security and convenience.",
    explanation: "Simplifying physical hardware drives massive payment adoption.",
    id: "ep_l2_q2"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 2,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch an automated tool that cancels unused digital trials.",
    correctAnswer: "It audits active subscriptions to save you hundreds monthly automatically.",
    hint: "Highlight direct consumer savings.",
    explanation: "Automated wallet management solves real everyday leakage.",
    id: "ep_l2_q3"
  },
  // Level 3: Healthtech & Wellbeing
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 3,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch an ergonomic office chair that corrects sitting posture dynamically.",
    correctAnswer: "It micro-adjusts back supports to prevent chronic spine pain.",
    hint: "State physical benefits clearly.",
    explanation: "Pre-empting back pain appeals to millions of remote workers.",
    id: "ep_l3_q1"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 3,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch an ambient sleep mask that guides breathing using soft light.",
    correctAnswer: "Our mask aligns breath rates to induce deep sleep swiftly.",
    hint: "Connect sensory light with deep relaxation.",
    explanation: "Guiding biometric sleep patterns offers pure relaxation without medication.",
    id: "ep_l3_q2"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 3,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a sensor patch that monitors key mineral deficiencies.",
    correctAnswer: "A wearable patch providing immediate insights into nutrient intake.",
    hint: "Stress continuous nutrition tracking.",
    explanation: "Continuous tracking replaces painful blood tests with active diagnostics.",
    id: "ep_l3_q3"
  },
  // Level 4: Clean Energy & Environment
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 4,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a decorative home wind turbine that blends with gardens.",
    correctAnswer: "It harvests clean wind energy through beautiful silent sculpture.",
    hint: "Merge aesthetics with sustainable power.",
    explanation: "Aesthetic wind energy overcomes noisy industrial grid issues.",
    id: "ep_l4_q1"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 4,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a portable solar phone case built from ocean plastics.",
    correctAnswer: "It cleans marine waste while charging your device anywhere sustainably.",
    hint: "Emphasize environmental cleanup.",
    explanation: "Clearing waste while offering utility constructs powerful emotional value.",
    id: "ep_l4_q2"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 4,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch an indoor home composter that yields rich soil in three hours.",
    correctAnswer: "It processes household waste into pristine fertilizer in hours.",
    hint: "Focus on speed and organic output.",
    explanation: "Rapid home composting minimizes global landfill emission output.",
    id: "ep_l4_q3"
  },
  // Level 5: EdTech & Learning
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 5,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch an immersive VR platform for interactive science lab tests.",
    correctAnswer: "Students perform dangerous chemistry tests inside safe virtual reality.",
    hint: "Highlight safety and spatial immersion.",
    explanation: "Virtual laboratories democratize expensive experiments globally.",
    id: "ep_l5_q1"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 5,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a gamified language app dedicated to elderly cognitive health.",
    correctAnswer: "It combines grammar lessons with games to prevent cognitive decline.",
    hint: "Link brain exercises with learning.",
    explanation: "Mental wellness through learning forms a compelling brand message.",
    id: "ep_l5_q2"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 5,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a smart writing tutor providing stylistic feedback.",
    correctAnswer: "It gives real-time creative recommendations as you pen novels.",
    hint: "Stress creative enhancements.",
    explanation: "Guiding styling choices expands writer capabilities.",
    id: "ep_l5_q3"
  },
  // Level 6: Travel & Hospitality
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 6,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch autonomous luggage that follows travelers safely.",
    correctAnswer: "Smart bags that navigate busy terminals by following you.",
    hint: "Highlight hands-free travel experience.",
    explanation: "Hands-free navigation reduces travel anxiety completely.",
    id: "ep_l6_q1"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 6,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a collaborative platform for renting off-grid vans.",
    correctAnswer: "It lets owners lease custom campers to wilderness explorers.",
    hint: "Connect owners with adventure seeking users.",
    explanation: "Peer camper models offer unique wilderness tours at fair margins.",
    id: "ep_l6_q2"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 6,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch an augmented reality headset mapping mountain hiking trails.",
    correctAnswer: "It overlays real-time maps and safety details directly onto trails.",
    hint: "Focus on safety and exploration maps.",
    explanation: "Mapping routes keeps users safe during extreme off-grid ventures.",
    id: "ep_l6_q3"
  },
  // Level 7: Developer Tools & Productivity
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 7,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a voice-activated IDE for hands-free software development.",
    correctAnswer: "It enables programmers to speak clean code lines completely hands-free.",
    hint: "Connect natural voice speech with syntax compilation.",
    explanation: "Hands-free coding expands digital access for differently-abled engineers.",
    id: "ep_l7_q1"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 7,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a deep learning bot reviewing pull request safety.",
    correctAnswer: "It identifies hidden logical bugs before code hits production.",
    hint: "Promote stable releases.",
    explanation: "Automated reviews accelerate engineering delivery speeds exponentially.",
    id: "ep_l7_q2"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 7,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a collaborative digital blackboard with layout auto-snaps.",
    correctAnswer: "It structures messy hand-drawn scribbles into pristine system charts.",
    hint: "Focus on design speed.",
    explanation: "Auto-structuring sketches saves design hours during brainstorming.",
    id: "ep_l7_q3"
  },
  // Level 8: Food Tech & Nutrition
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 8,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a personalized 3D printer for dietary organic nutrient bars.",
    correctAnswer: "It prints protein snacks customized to your active biometrics.",
    hint: "Target customized athlete fueling.",
    explanation: "Biometric customization fuels performance better than standard foods.",
    id: "ep_l8_q1"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 8,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a local food box sourced entirely from urban building roofs.",
    correctAnswer: "Fresh vegetables harvested hours ago on your neighborhood roofs.",
    hint: "Focus on freshness and micro-proximity.",
    explanation: "Rooftop harvesting cuts transportation carbon to absolute zero.",
    id: "ep_l8_q2"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 8,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch an allergen testing device that checks food in 5 seconds.",
    correctAnswer: "A pocket sensor detecting hidden food allergens instantly.",
    hint: "Highlight rapid safety assurances.",
    explanation: "Instant safety checks protect kids from severe allergic reactions.",
    id: "ep_l8_q3"
  },
  // Level 9: Smart Home & IoT
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 9,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch transparent home windows that function as solar collectors.",
    correctAnswer: "They turn ordinary glass panels into clean power sources.",
    hint: "Promote self-sustaining buildings.",
    explanation: "Solar windows convert high-rise glass spaces into sustainable power grids.",
    id: "ep_l9_q1"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 9,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a smart feeder tracking pet nutritional health indicators.",
    correctAnswer: "It monitors eating habits to alert owners to potential illnesses.",
    hint: "Highlight preventive animal care.",
    explanation: "Early habit alerts let owners resolve health issues before they escalate.",
    id: "ep_l9_q2"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 9,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch an ambient speaker that adjusts volume to room echoes.",
    correctAnswer: "It micro-tunes sound levels to always deliver crystal audio.",
    hint: "Promote acoustical clarity.",
    explanation: "Self-tuning audio ensures clear listening in noisy rooms.",
    id: "ep_l9_q3"
  },
  // Level 10: Space & Advanced Tech
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 10,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a modular lunar greenhouse container for space colonists.",
    correctAnswer: "It enables astronauts to harvest organic fresh salads on the moon.",
    hint: "Promote interplanetary self-sufficiency.",
    explanation: "Lunar crops sustain astronauts on long exploration voyages.",
    id: "ep_l10_q1"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 10,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a home hydrogen battery that stores power for six months.",
    correctAnswer: "It stores clean excess summer power to warm homes during winter.",
    hint: "Stress long term storage capabilities.",
    explanation: "Hydrogen tech overcomes seasonal solar drops completely.",
    id: "ep_l10_q2"
  },
  {
    instruction: "Deliver the pitch before the lift opens.",
    difficulty: 10,
    subtype: "elevatorPitch",
    interactionType: "voice",
    prompt: "Pitch a sub-orbital parcel drone delivery network.",
    correctAnswer: "Drones delivering critical emergency packages globally in an hour.",
    hint: "Promote extreme delivery speeds.",
    explanation: "Sub-orbital flight delivers medical cargo anywhere globally in record speeds.",
    id: "ep_l10_q3"
  }
];

// 2. Unique data for Emergency Hub game (30 Quests, 3 per level for Levels 1-10)
const emergencyHubQuests = [
  // Level 1: Fire & Chemical Risks
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 1,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Coolant leak detected in core reactor tank 4. Input emergency routing code now!",
    correctAnswer: "LEAK CONTAINMENT LOCKER ALPHA",
    hint: "Use containment locker alpha.",
    explanation: "Containing leak areas rapidly protects nearby team personnel.",
    id: "eh_l1_q1"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 1,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Lithium batteries thermal runaway in storage bay 3. Input safety code!",
    correctAnswer: "POWER TERMINATION SEQUENCE 4",
    hint: "Sequence number four is required.",
    explanation: "Shutting battery loops blocks dangerous current spread.",
    id: "eh_l1_q2"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 1,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Gas cylinder pressure overload in laboratory level 2. Input routing code!",
    correctAnswer: "PRESSURE VENT SYSTEM ACTIVE",
    hint: "Trigger active pressure vent.",
    explanation: "Venting gases keeps tank pressure in safe levels.",
    id: "eh_l1_q3"
  },
  // Level 2: Medical Emergencies
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 2,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Team member touched toxic solvent in chamber 2. Input treatment room code!",
    correctAnswer: "CHEMICAL SHOWER ROOM 3",
    hint: "Direct to chemical shower room three.",
    explanation: "Shower decontamination prevents chemical skin absorption.",
    id: "eh_l2_q1"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 2,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Critical airlock trauma reported in landing dock. Input recovery code!",
    correctAnswer: "PRESSURE EQUALIZATION MODE",
    hint: "Initiate pressure equalization mode.",
    explanation: "Equalizing airlock pressure preserves patient oxygen balance.",
    id: "eh_l2_q2"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 2,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Severe cardiac event on sector assembly floor. Input aid unit code!",
    correctAnswer: "DEFIBRILLATOR UNIT DISPATCHED",
    hint: "Send the defibrillator unit.",
    explanation: "Shocking hearts in minutes dramatically boosts survival rates.",
    id: "eh_l2_q3"
  },
  // Level 3: Geological & Public Safety
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 3,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Ground tremor shaking underground sector 7. Input shaft protocol code!",
    correctAnswer: "DRILL LOCKDOWN PROTOCOL 7",
    hint: "Trigger drill protocol seven.",
    explanation: "Locking heavy machinery protects crews from collapse risks.",
    id: "eh_l3_q1"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 3,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Water levels rising in deep drainage ducts. Input bypass code!",
    correctAnswer: "DRAINAGE VALVE OPEN PHASE 2",
    hint: "Enter drainage valve open phase two.",
    explanation: "Opening extra gates prevents main elevator flooding.",
    id: "eh_l3_q2"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 3,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Heavy rocks blocking main entry passage. Input clearing bot code!",
    correctAnswer: "EXCAVATOR ROBOT DISPATCHED",
    hint: "Send the excavator robot unit.",
    explanation: "Robotic loaders clear blockages safely without endangering teams.",
    id: "eh_l3_q3"
  },
  // Level 4: Grid & Power Safety
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 4,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Overload sparks on primary transformer grid. Input cutout code!",
    correctAnswer: "GRID SHUTDOWN SWITCH BETA",
    hint: "Select grid shutdown switch beta.",
    explanation: "Cutting off grids prevents fires in nearby cables.",
    id: "eh_l4_q1"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 4,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "High-voltage flash near turbine generator. Input standby code!",
    correctAnswer: "AUXILIARY GENERATOR SWITCH",
    hint: "Flip the auxiliary generator switch.",
    explanation: "Secondary switches protect local grids from blackouts.",
    id: "eh_l4_q2"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 4,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Solar electromagnetic storm warning. Input protection shielding code!",
    correctAnswer: "EM SHIELD DEPLOYED NOW",
    hint: "Deploy EM shield now.",
    explanation: "Magnetic shields protect digital servers from solar shocks.",
    id: "eh_l4_q3"
  },
  // Level 5: Maritime & Aquatic Rescue
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 5,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Sea water breach reported in bilge 12. Input recovery code!",
    correctAnswer: "AUTOMATIC BILGE COMPARTMENT",
    hint: "Engage automatic bilge compartment.",
    explanation: "Sealing bilge zones keeps vessels floating steadily.",
    id: "eh_l5_q1"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 5,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Oil separator tank high pressure alarm. Input relief code!",
    correctAnswer: "SAFETY RELIEF VALVE RELEASE",
    hint: "Initiate safety relief valve release.",
    explanation: "Releasing trapped oil prevents separator pipe ruptures.",
    id: "eh_l5_q2"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 5,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Deep sea diver lost radio link. Input search tracker code!",
    correctAnswer: "SONAR LOCATOR FREQUENCY 4",
    hint: "Use sonar locator frequency four.",
    explanation: "Active sonar tracks locations using water sound waves.",
    id: "eh_l5_q3"
  },
  // Level 6: Aviation & Flight Systems
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 6,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Hydraulics lost on passenger transport. Input reserve gear code!",
    correctAnswer: "EMERGENCY GEAR RELEASE",
    hint: "Initiate emergency gear release.",
    explanation: "Manual gear releases allow emergency belly landings.",
    id: "eh_l6_q1"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 6,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Engine fire light active on jet airliner. Input fire suppression code!",
    correctAnswer: "HALON EXTINGUISHER ACTIVE",
    hint: "Activate the halon extinguisher.",
    explanation: "Halon gas stops jet engine fires in seconds.",
    id: "eh_l6_q2"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 6,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Cabin decompression at 30,000 feet. Input mask deploy code!",
    correctAnswer: "DECOMPRESSION SHIELD SYSTEM",
    hint: "Trigger decompression shield system.",
    explanation: "Oxygen shield deployments preserve passenger consciousness during drops.",
    id: "eh_l6_q3"
  },
  // Level 7: Cyber & Security Breach
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 7,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Cyber attack on water treatment controls. Input isolation code!",
    correctAnswer: "ISOLATION SYSTEM SHIELD",
    hint: "Engage isolation system shield.",
    explanation: "Isolating networks blocks remote attackers from cutting water.",
    id: "eh_l7_q1"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 7,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "DDOS attack overloading communications tower. Input filter code!",
    correctAnswer: "TRAFFIC DIVERTER PROTOCOL",
    hint: "Initiate traffic diverter protocol.",
    explanation: "Diverting traffic keeps essential emergency lines active.",
    id: "eh_l7_q2"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 7,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Intruder detected in central server room. Input lockdown code!",
    correctAnswer: "SERVER AREA CONTAINMENT",
    hint: "Activate server area containment.",
    explanation: "Sealing physical server doors prevents direct network sabotage.",
    id: "eh_l7_q3"
  },
  // Level 8: Nuclear & Radiation Safeguards
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 8,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Shield door open in radiography chamber. Input block code!",
    correctAnswer: "RADIATION CONTAINMENT DOOR",
    hint: "Seal the radiation containment door.",
    explanation: "Heavy lead doors block high exposure leaks completely.",
    id: "eh_l8_q1"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 8,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Heavy isotope temperatures rising. Input coolant dump code!",
    correctAnswer: "COOLANT DUMP VALVE OPEN",
    hint: "Open the coolant dump valve.",
    explanation: "Flooding chambers absorbs radiation heat quickly.",
    id: "eh_l8_q2"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 8,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Particle accelerator beam misalignment. Input backup code!",
    correctAnswer: "BEAM SHUTDOWN SIGNAL",
    hint: "Trigger the beam shutdown signal.",
    explanation: "Killing power immediately prevents steel pipe meltdown disasters.",
    id: "eh_l8_q3"
  },
  // Level 9: severe climate & Transport
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 9,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Avalanche warning on mountain rail tracks. Input divert signal code!",
    correctAnswer: "TRACK DIVERT SIGNAL ACTIVE",
    hint: "Activate track divert signal.",
    explanation: "Diverting paths protects passenger trains from heavy snow blockage.",
    id: "eh_l9_q1"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 9,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Maglev train speed governor failure. Input stop backup code!",
    correctAnswer: "BRAKING SYSTEM INITIATE",
    hint: "Trigger the braking system initiate.",
    explanation: "Auxiliary magnetic brakes decelerate coaches safely.",
    id: "eh_l9_q2"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 9,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Landing gear stuck on cargo transport. Input foam spray code!",
    correctAnswer: "FOAM SHIELD DEPLOYED RUNWAY",
    hint: "Select foam shield deployed runway.",
    explanation: "Spraying foam cuts sparks during metal landing scrapings.",
    id: "eh_l9_q3"
  },
  // Level 10: Space Station & Cosmic Risks
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 10,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Severe space radiation storm detected. Input shielding code!",
    correctAnswer: "SHIELD DEFLECTOR BATTERY",
    hint: "Activate shield deflector battery.",
    explanation: "Magnetic deflectors protect crews from cosmic heavy ions.",
    id: "eh_l10_q1"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 10,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "Micrometeoroid hull breach in greenhouse modules. Input lock code!",
    correctAnswer: "AIRLOCK CONSOLE SECURE",
    hint: "Engage airlock console secure.",
    explanation: "Emergency airlock sealing preserves oxygen in adjacent modules.",
    id: "eh_l10_q2"
  },
  {
    instruction: "Dispatch the response unit immediately!",
    difficulty: 10,
    subtype: "emergencyHub",
    interactionType: "typing",
    dispatcherQuestion: "High fuel line pressure in lunar propulsion system. Input vent code!",
    correctAnswer: "VENT VALVE INITIATED NOW",
    hint: "Use vent valve initiated now.",
    explanation: "Venting volatile gases prevents launch pad combustion risks.",
    id: "eh_l10_q3"
  }
];

// Helper to write enhanced JSON files
function enhanceCurriculumFile(relativeFilePath, newQuests, gameTypeName) {
  const absolutePath = path.join(__dirname, relativeFilePath);
  
  if (!fs.existsSync(absolutePath)) {
    console.error(`File not found: ${absolutePath}`);
    return;
  }

  const fileContent = JSON.parse(fs.readFileSync(absolutePath, 'utf8'));
  
  // Replace quests
  fileContent.quests = newQuests.map((q, index) => {
    // Keep baseline structures but inject beautiful, unique educational content
    return {
      ...q,
      xpReward: (Math.floor(index / 3) + 1) * 3,
      coinReward: (Math.floor(index / 3) + 1) * 5,
      visual_config: {
        painter_type: "RoleplayPulseSync",
        primary_color: "0xFF00D2FF"
      }
    };
  });

  fs.writeFileSync(absolutePath, JSON.stringify(fileContent, null, 2), 'utf8');
  console.log(`Successfully enhanced curriculum: ${gameTypeName} at ${relativeFilePath}`);
}

// Enhance both files!
enhanceCurriculumFile('roleplay/elevatorPitch_1_10.json', elevatorPitchQuests, 'Elevator Pitch');
enhanceCurriculumFile('roleplay/emergencyHub_1_10.json', emergencyHubQuests, 'Emergency Hub');
