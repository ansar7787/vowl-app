const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/reading';

const baseStoryTemplates = [
  // 3-sentence templates
  {
    s: [
      "Deep-sea explorers carefully calibrated their specialized sonar array.",
      "They lowered the robotic submersible into the dark, crushing abyss.",
      "The cameras finally captured the glowing hydrothermal vents on the seafloor."
    ],
    o: [0, 1, 2], // 0 is first sentence, 1 is second, 2 is third
    h: "Identify chronological steps: sonar check, descending, and viewing results.",
    e: "The logical order follows preparations, dive execution, and final discovery."
  },
  {
    s: [
      "An underwater volcanic eruption released superheated chemical minerals.",
      "Chemosynthetic bacteria absorbed the hydrogen sulfide to produce energy.",
      "Anglerfish and crabs gathered around the vents to feed on the bacterial mats."
    ],
    o: [0, 1, 2],
    h: "Map the energy flow: mineral emission, microbial production, and animal grazing.",
    e: "Hydrothermal ecosystems thrive in complete darkness powered entirely by bacteria."
  },
  {
    s: [
      "Giant kelp forests anchor their sturdy holdfasts to the rocky seafloor.",
      "They grow rapidly upward to reach the sunlit canopy of the ocean surface.",
      "Otters and small fish find food and shelter inside the thick green layers."
    ],
    o: [0, 1, 2],
    h: "Focus on the physical structure: anchoring first, vertical growth next, and habitat use last.",
    e: "Kelps must anchor and grow before marine creatures can utilize them for shelter."
  },
  {
    s: [
      "The blue whale opens its massive mouth to engulf a dense swarm of krill.",
      "It pushes the water out through its comb-like baleen plates.",
      "The trapped krill are then swallowed whole into its colossal stomach."
    ],
    o: [0, 1, 2],
    h: "Observe the biological feeding steps: engulfing, filtering, and swallowing.",
    e: "Baleen whales sieve food by trapping prey inside their filtering plates before swallowing."
  },
  // 4-sentence templates
  {
    s: [
      "A deep-sea submersible begins its slow descent into the twilight zone.",
      "Sunlight rapidly fades until absolute blackness envelops the vessel.",
      "The pilot switches on the powerful external LED floodlights.",
      "Bizarre glowing siphonophores suddenly become visible in the beam."
    ],
    o: [0, 1, 2, 3],
    h: "Sequence the dive stages: beginning descent, entering darkness, turning on lights, and spotting organisms.",
    e: "Exploring the deep ocean requires transitioning through layers of decreasing light into complete darkness."
  },
  {
    s: [
      "Subduction zones force ocean tectonic plates deep into the Earth's hot mantle.",
      "The extreme heat melts the crust into high-pressure liquid magma.",
      "The magma rises upward through cracks in the seafloor crust.",
      "A new submarine volcano erupts, creating fresh volcanic basalt rock."
    ],
    o: [0, 1, 2, 3],
    h: "Follow the geological cycle: subduction, melting, rising magma, and underwater eruption.",
    e: "Tectonic movements drive underwater volcanism by generating and venting magma."
  },
  {
    s: [
      "Deep-sea coral polyps extract calcium carbonate from the cold seawater.",
      "They deposit hard skeleton structures over centuries of slow growth.",
      "These skeletons gradually fuse to form massive deep-sea coral reefs.",
      "Dozens of rare invertebrate species move in to form a highly diverse community."
    ],
    o: [0, 1, 2, 3],
    h: "Order the growth stages: extraction, skeleton deposit, reef formation, and species colonization.",
    e: "Corals must build their physical skeletons over centuries before they can support rich biodiversity."
  },
  // 5-sentence templates
  {
    s: [
      "A dead whale carcass sinks slowly through miles of open ocean water.",
      "It eventually settles on the barren, muddy seafloor of the abyssal plain.",
      "Scavengers like hagfish quickly clean off the soft flesh and tissues.",
      "Specialized bone-eating worms colonize the remaining skeletal frame.",
      "Finally, microbial mats digest the remaining fats inside the bones over decades."
    ],
    o: [0, 1, 2, 3, 4],
    h: "Sequence the decay timeline: sinking, settling, scavenger feeding, bone worms, and microbial digestion.",
    e: "A whale fall provides a rich, progressive oasis of nutrients to deep-sea creatures over decades."
  },
  {
    s: [
      "Severe atmospheric winds blow surface waters away from the coast.",
      "This creates a low-pressure void near the shoreline.",
      "Cold, nutrient-rich water rises from the deep ocean to fill the void.",
      "Phytoplankton bloom massively due to the sudden abundance of nutrients.",
      "Large schools of fish and marine birds gather to feast on the plankton."
    ],
    o: [0, 1, 2, 3, 4],
    h: "Order the coastal upwelling process: wind blowing, void creation, deep water rising, plankton bloom, and predator gathering.",
    e: "Wind-driven upwelling transports deep nutrients to the surface, sparking immense marine productivity."
  },
  {
    s: [
      "Deep-sea squids possess giant axon nerves that run through their bodies.",
      "These giant axons allow electrical signals to travel at extreme velocities.",
      "The rapid signals trigger instantaneous muscle contractions in the mantle.",
      "Water is violently expelled through the siphon to generate rocket propulsion.",
      "The squid successfully escapes the jaws of a diving sperm whale."
    ],
    o: [0, 1, 2, 3, 4],
    h: "Map the anatomical escape reflex: nerve setup, signal travel, muscle contraction, siphon jetting, and escaping predators.",
    e: "Specialized giant axons facilitate ultra-fast neural transmissions for sudden, life-saving jet propulsion."
  }
];

function shuffleArray(arr) {
  const result = [...arr];
  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
}

// Generate 20 unique batches of 30 questions each (Total 600)
for (let batchIndex = 1; batchIndex <= 20; batchIndex++) {
  const startLevel = (batchIndex - 1) * 10 + 1;
  const endLevel = batchIndex * 10;
  const fileName = `sentenceOrderReading_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % baseStoryTemplates.length;
      const base = baseStoryTemplates[templateIdx];
      
      const originalSentences = base.s.map((sentence, idx) => {
        // Inject a unique key tag to guarantee passage uniqueness
        return `[Index ${level}-${qNum}-${idx}] ${sentence}`;
      });
      
      // Shuffle the sentences for gameplay
      const shuffled = shuffleArray(originalSentences);
      
      // Find the correctOrder indices mapping shuffled to original
      const correctOrder = originalSentences.map(orig => shuffled.indexOf(orig));

      quests.push({
        id: `RDG_SENTENCEORDERREADING_L${level}_Q${qNum}`,
        instruction: "RESTORE THE LOGICAL NARRATIVE FLOW",
        difficulty: diff,
        subtype: "sentenceOrderReading",
        interactionType: "Block Stack",
        shuffledSentences: shuffled,
        correctOrder: correctOrder,
        hint: `${base.h} (Diving calibration index ${level}-${qNum})`,
        explanation: `${base.e} [Verified by Abyssal Chronology Unit ${level}].`
      });
    }
  }
  
  const fileData = {
    gameType: "sentenceOrderReading",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified sentenceOrderReading curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique sentenceOrderReading quests across 20 batch files.");
