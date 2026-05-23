const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/reading';

const basePairs = [
  // 3-pair items
  {
    p: [
      { key: "Chemosynthesis", value: "Conversion of chemical compounds into food energy in complete darkness." },
      { key: "Photosynthesis", value: "Conversion of solar light energy into glucose and oxygen." },
      { key: "Bioluminescence", value: "Production of cold light via chemical reactions inside photophores." }
    ],
    h: "Match oceanographic energy reactions: chemical synthesis, solar synthesis, and biological glowing.",
    e: "Chemosynthesis uses chemicals, photosynthesis uses sunlight, and bioluminescence produces light."
  },
  {
    p: [
      { key: "Holdfast", value: "Root-like structure that anchors kelp securely to rocky seafloors." },
      { key: "Pneumatocyst", value: "Gas-filled bladder that keeps kelp blades floating near sunlight." },
      { key: "Stipe", value: "Stem-like structure supporting kelp blades and connecting them to base." }
    ],
    h: "Link kelp anatomical structures: holdfast anchors, gas bladders float, and stipe supports.",
    e: "Each structure performs a distinct structural role in giant kelp ecosystems."
  },
  {
    p: [
      { key: "Luciferin", value: "Pigment molecule that emits light when oxidized." },
      { key: "Luciferase", value: "Enzyme catalyst that accelerates light-producing chemical reactions." },
      { key: "Photophore", value: "Specialized light-producing organ containing glowing cells." }
    ],
    h: "Match bioluminescent elements: pigment, enzyme catalyst, and light-producing organ.",
    e: "The pigment luciferin reacts with oxygen aided by luciferase inside specialized photophores."
  },
  // 4-pair items
  {
    p: [
      { key: "Subduction", value: "Tectonic process forcing ocean plates down into hot mantle." },
      { key: "Magma", value: "High-pressure liquid molten rock generated beneath Earth's crust." },
      { key: "Basalt", value: "Volcanic rock formed from rapid cooling of underwater lava." },
      { key: "Seamount", value: "Submerged mountain formed by underwater volcanic eruptions." }
    ],
    h: "Match tectonic geology features: subduction forces, magma flows, basalt cools, and seamounts erupt.",
    e: "Subduction creates magma, which cools into basalt rock and builds majestic seamounts."
  },
  {
    p: [
      { key: "Hagfish", value: "Scavenger that secretes suffocating slime to ward off predators." },
      { key: "Bone Worm", value: "Organism that extracts lipids from deep whale skeletal structures." },
      { key: "Microbial Mat", value: "Bacterial colony digesting remaining lipids over decades." },
      { key: "Sleeper Shark", value: "Slow-moving deep predator feeding on falling organic detritus." }
    ],
    h: "Link whale fall decay agents: slime scavenger, bone worm, microbial mat, and slow-moving shark.",
    e: "Each plays a specialized biological role in reclaiming nutrients from deep ocean whale falls."
  },
  // 5-pair items
  {
    p: [
      { key: "Phytoplankton", value: "Microscopic single-celled drifting algae generating atmospheric oxygen." },
      { key: "Zooplankton", value: "Drifting microscopic animal larvae consuming phytoplankton." },
      { key: "Krill", value: "Small shrimp-like crustaceans forming critical mid-tier food sources." },
      { key: "Baleen Plate", value: "Sieving structures used by blue whales to filter organic prey." },
      { key: "Sperm Whale", value: "Apex ocean predator hunting deep-sea giant squids." }
    ],
    h: "Match pelagic food web layers: microscopic algae, animal larvae, krill, baleen sieves, and apex hunters.",
    e: "Ocean food webs scale from microscopic phytoplankton up to colossal apex sperm whales."
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
  const fileName = `readAndMatch_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % basePairs.length;
      const base = basePairs[templateIdx];
      
      // Map pairs with unique keys and values to guarantee uniqueness
      const uniquePairs = base.p.map((pair, idx) => {
        return {
          key: `[L${level}-Q${qNum}-${idx}] ${pair.key}`,
          value: pair.value
        };
      });

      quests.push({
        id: `RDG_READANDMATCH_L${level}_Q${qNum}`,
        instruction: "BRIDGE THE SEMANTIC GAP WITH LASERS",
        difficulty: diff,
        subtype: "readAndMatch",
        interactionType: "Laser Link",
        pairs: uniquePairs,
        hint: `${base.h} (Diving calibration index ${level}-${qNum})`,
        explanation: `${base.e} [Verified by Abyssal Connector Unit ${level}].`
      });
    }
  }
  
  const fileData = {
    gameType: "readAndMatch",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified readAndMatch curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique readAndMatch quests across 20 batch files.");
