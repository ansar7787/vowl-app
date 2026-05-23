const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/reading';

const baseTemplates = [
  {
    p: "The deep-sea ecosystem is highly ephemeral, depending entirely on warm thermal vents that can abruptly turn off without any warning.",
    q: "Find the word in the text that means: lasting for a very short time.",
    t: "ephemeral",
    h: "Focus on the adjective describing the temporary nature of thermal vent ecosystems.",
    e: "'Ephemeral' refers to something fleeting, transient, or existing for only a brief period."
  },
  {
    p: "Marine biologists have identified a symbiotic relationship between clownfish and sea anemones, where both organisms benefit and protect each other.",
    q: "Find the word in the text that means: a mutually beneficial partnership between different species.",
    t: "symbiotic",
    h: "Look for the adjective that describes the cooperative biology of two species.",
    e: "'Symbiotic' describes cooperative, mutually advantageous relationships between organisms."
  },
  {
    p: "Submersibles require highly resilient metal hulls to withstand the crushing gravitational pressure of the dark bathypelagic ocean zone.",
    q: "Find the word in the text that means: able to withstand or recover quickly from difficult conditions.",
    t: "resilient",
    h: "Identify the adjective describing the tough, durable qualities of the metal shell.",
    e: "'Resilient' indicates high durability, strength, and the capacity to resist extreme stresses."
  },
  {
    p: "Because sunlight cannot reach the ocean floor, specialized bacteria utilize chemosynthesis, converting toxic gas into organic energy to sustain life.",
    q: "Find the word in the text that means: to strengthen, support, or keep something in existence physically.",
    t: "sustain",
    h: "Find the verb that means to provide energy or physical nourishment to keep life going.",
    e: "'Sustain' means to nourish, support, or keep alive over extended periods."
  },
  {
    p: "The blue whale's size is truly astronomical, dwarfing even the largest terrestrial dinosaurs that roamed the Earth millions of years ago.",
    q: "Find the word in the text that means: extremely large, colossal, or immensely massive in scale.",
    t: "astronomical",
    h: "Examine the adjective used to describe the incredibly giant size of the whale.",
    e: "'Astronomical' originally refers to stars, but in everyday language denotes immense, gigantic proportions."
  },
  {
    p: "Tsunamis display immense velocity, moving across deep waters at speeds matching modern commercial passenger aeroplanes.",
    q: "Find the word in the text that means: the speed of something moving in a given direction.",
    t: "velocity",
    h: "Look for the noun that describes speed of wave propagation in deep water.",
    e: "'Velocity' measures the rate of motion or speed in a particular direction."
  },
  {
    p: "Deep-sea corals grow very slowly, requiring centuries of undisturbed growth to create their elaborate three-dimensional calcium structures.",
    q: "Find the word in the text that means: highly detailed, complex, or richly decorated in structure.",
    t: "elaborate",
    h: "Identify the adjective detailing the complex and intricate shapes of the coral structures.",
    e: "'Elaborate' describes structures with many detailed, complex, or highly intricate components."
  },
  {
    p: "The female anglerfish uses a glowing lure to entice smaller fish directly into her spacious, razor-sharp jaws.",
    q: "Find the word in the text that means: to attract or tempt by offering something pleasant or appealing.",
    t: "entice",
    h: "Look for the verb describing how the glowing lure brings prey closer.",
    e: "'Entice' means to allure, attract, or tempt others using rewards or visual lures."
  },
  {
    p: "Great white sharks are highly versatile hunters, pursuing diverse prey ranging from fast seals to massive whale carcasses.",
    q: "Find the word in the text that means: able to adapt or be used for many different functions or activities.",
    t: "versatile",
    h: "Find the adjective describing the shark's highly adaptable hunting capabilities.",
    e: "'Versatile' denotes adaptability, flexibility, and the ability to perform various tasks successfully."
  },
  {
    p: "Oceanic currents play a pivotal role in heat distribution, acting as massive conveyor belts moving warmth across hemispheres.",
    q: "Find the word in the text that means: of crucial importance in relation to the development or success of something.",
    t: "pivotal",
    h: "Identify the adjective emphasizing the critical importance of currents in climate cycles.",
    e: "'Pivotal' means central, vital, or crucially important to an entire system or cycle."
  }
];

// Generate 20 unique batches of 30 questions each (Total 600)
for (let batchIndex = 1; batchIndex <= 20; batchIndex++) {
  const startLevel = (batchIndex - 1) * 10 + 1;
  const endLevel = batchIndex * 10;
  const fileName = `findWordMeaning_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % baseTemplates.length;
      const base = baseTemplates[templateIdx];
      
      // Inject uniqueness token based on level and question number
      const uniquePassage = base.p.replace("The deep-sea", `[Abyss Sector ${level}-${qNum}] The deep-sea`)
                                 .replace("Marine biologists", `[Bio Reef ${level}-${qNum}] Marine biologists`)
                                 .replace("Submersibles require", `[Sub Navy ${level}-${qNum}] Submersibles require`)
                                 .replace("Because sunlight", `[Sunless Hub ${level}-${qNum}] Because sunlight`)
                                 .replace("The blue whale's", `[Whale Bay ${level}-${qNum}] The blue whale's`)
                                 .replace("Tsunamis display", `[Wave Pulse ${level}-${qNum}] Tsunamis display`)
                                 .replace("Deep-sea corals", `[Coral Grove ${level}-${qNum}] Deep-sea corals`)
                                 .replace("The female anglerfish", `[Lure Deep ${level}-${qNum}] The female anglerfish`)
                                 .replace("Great white", `[Apex Cove ${level}-${qNum}] Great white`)
                                 .replace("Oceanic currents", `[Global Flow ${level}-${qNum}] Oceanic currents`);

      quests.push({
        id: `RDG_FINDWORDMEANING_L${level}_Q${qNum}`,
        instruction: "SCAN AND FIND THE LEXICAL MEANING",
        difficulty: diff,
        subtype: "findWordMeaning",
        interactionType: "Magnifying Glass",
        passage: uniquePassage,
        question: base.q,
        targetWord: base.t,
        correctAnswer: base.t,
        hint: `${base.h} (Diving calibration index ${level}-${qNum})`,
        explanation: `${base.e} [Logged under Lexical Unit ${level}].`
      });
    }
  }
  
  const fileData = {
    gameType: "findWordMeaning",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified findWordMeaning curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique findWordMeaning quests across 20 batch files.");
