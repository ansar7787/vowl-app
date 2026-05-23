const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'speaking', 'sceneDescriptionSpeaking_1_10.json');

const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));

const sceneMapping = [
  {
    title: "Lunar Expedition Cabin",
    sceneText: "Lunar Expedition Cabin|Describe the gold-tinted protective helmet visor.|Describe the rugged drive wheels of the lunar rover.|Describe the shiny solar power arrays at the back.",
    options: ["Astronaut Visor", "Rover Wheels", "Solar Panel Grid"],
    acceptedSynonyms: [
      "visor,glass,helmet,gold,reflection",
      "wheel,rover,tyre,drive,dirt,rugged",
      "solar,panel,sun,power,energy,shining"
    ],
    hint: "Observe the visor, wheels, and solar panel.",
    explanation: "Describing technical equipment on celestial expeditions builds vocabulary specificity."
  },
  {
    title: "Rainforest Canopy Treehouse",
    sceneText: "Rainforest Canopy Treehouse|Describe the wooden rope bridge leading to the entrance.|Describe the brightly colored macaw bird on the branch.|Describe the glowing warm oil lantern hanging above.",
    options: ["Hanging Rope Bridge", "Tropical Macaw", "Warm Oil Lantern"],
    acceptedSynonyms: [
      "bridge,rope,wood,cross,swing,path",
      "bird,macaw,parrot,feather,color,beak",
      "lantern,light,glow,lamp,warm,shimmer"
    ],
    hint: "Identify the rope bridge, macaw, and lantern.",
    explanation: "Describing natural elements and lighting constructs vivid imagery."
  },
  {
    title: "Medieval Castle Library",
    sceneText: "Medieval Castle Library|Describe the antique glass hourglass counting the seconds.|Describe the massive open leather grimoire book on the stand.|Describe the gothic stained glass window depicting the moon.",
    options: ["Glass Hourglass", "Leather Grimoire", "Stained Window"],
    acceptedSynonyms: [
      "hourglass,sand,time,glass,clock,seconds",
      "book,cover,leather,pages,spell,grimoire",
      "glass,window,stained,colors,moon,gothic"
    ],
    hint: "Observe the hourglass, grimoire, and stained window.",
    explanation: "Describing historic antiques builds deep historical conversational contexts."
  },
  {
    title: "Cyberpunk Alleyway Cafe",
    sceneText: "Cyberpunk Alleyway Cafe|Describe the flashing purple neon sign over the diner.|Describe the rusty humanoid robot sweeping the pavement.|Describe the sleek levitating motorcycle parked nearby.",
    options: ["Neon Cafe Sign", "Sweeper Droid", "Hover Cycle"],
    acceptedSynonyms: [
      "sign,neon,purple,light,glow,cafe",
      "robot,sweep,humanoid,droid,metal,broom",
      "hover,motorcycle,bike,cycle,float,park"
    ],
    hint: "Focus on the neon sign, sweeper droid, and hover cycle.",
    explanation: "Describing technological sci-fi details improves spatial vocabulary bounds."
  },
  {
    title: "Deep Sea Submarine Cockpit",
    sceneText: "Deep Sea Submarine Cockpit|Describe the glowing green sonar screen monitoring depths.|Describe the steel pressure valve wheels locking the hatch.|Describe the massive oceanic creature passing the thick viewport.",
    options: ["Green Sonar Screen", "Pressure Hatch Valve", "Oceanic Viewport"],
    acceptedSynonyms: [
      "sonar,screen,green,radar,monitor,beep",
      "valve,wheel,hatch,pressure,steel,lock",
      "viewport,window,creature,fish,whale,water"
    ],
    hint: "Look closely at the sonar screen, valve wheel, and viewport.",
    explanation: "Describing aquatic and mechanical interfaces builds technical communication skills."
  },
  {
    title: "Vibrant Moroccan Bazaar",
    sceneText: "Vibrant Moroccan Bazaar|Describe the stacks of aromatic ground spices in conical piles.|Describe the polished brass hanging lanterns shimmering in sunlight.|Describe the rich hand-woven crimson tapestries on display.",
    options: ["Aromatic Spices", "Brass Lanterns", "Woven Tapestries"],
    acceptedSynonyms: [
      "spice,pile,powder,color,smell,aroma",
      "brass,lantern,metal,shine,sunlight,hang",
      "tapestry,woven,carpet,rug,crimson,pattern"
    ],
    hint: "Describe the spices, brass lamps, and rich carpets.",
    explanation: "Describing cultural artifacts and sensory smells builds native conversational depth."
  },
  {
    title: "Desert Oasis Sanctuary",
    sceneText: "Desert Oasis Sanctuary|Describe the crystal clear pool reflecting the palm leaves.|Describe the cluster of ripe dates hanging under the palm canopy.|Describe the nomadic white cloth tent pitched on the sand bank.",
    options: ["Reflecting Pool", "Palm Date Clusts", "Nomadic Sand Tent"],
    acceptedSynonyms: [
      "pool,water,reflect,clear,crystal,pond",
      "dates,fruit,hang,tree,palm,sweet",
      "tent,cloth,white,sand,dune,camp"
    ],
    hint: "Describe the water pool, palm dates, and desert tent.",
    explanation: "Describing geographical environments and botanical details enhances fluency."
  },
  {
    title: "Victorian Steampunk Workshop",
    sceneText: "Victorian Steampunk Workshop|Describe the copper steam pipes hissng with white pressure.|Describe the interlocking brass gear assemblies spinning steadily.|Describe the glowing electrical vacuum tubes on the workbench.",
    options: ["Copper Steam Pipes", "Brass Gear Set", "Vacuum Tube Set"],
    acceptedSynonyms: [
      "steam,pipe,copper,hiss,pressure,white",
      "gear,brass,wheel,spin,turn,rotate",
      "tube,vacuum,glow,glass,wire,light"
    ],
    hint: "Focus on the steam pipes, spinning gears, and glowing tubes.",
    explanation: "Describing industrial designs and physics elements builds descriptive precision."
  },
  {
    title: "Serene Alpine Ski Chalet",
    sceneText: "Serene Alpine Ski Chalet|Describe the crackling stone fireplace emitting warm embers.|Describe the heavy wooden snowshoes resting against the log wall.|Describe the frosty snow-capped mountain peak through the glass.",
    options: ["Stone Fireplace", "Wooden Snowshoes", "Mountain Viewport"],
    acceptedSynonyms: [
      "fireplace,fire,stone,warm,wood,burn",
      "snowshoes,boots,wood,wall,rest,ski",
      "mountain,peak,snow,ice,window,glass"
    ],
    hint: "Examine the fireplace, snowshoes, and mountain view.",
    explanation: "Describing winter activities and cozy atmospheres increases emotional expression."
  },
  {
    title: "Zen Rock Botanical Garden",
    sceneText: "Zen Rock Botanical Garden|Describe the carefully raked white gravel waves around rocks.|Describe the tiny stone pagoda statue beside the bamboo grove.|Describe the bright pink cherry blossom petals on the bridge.",
    options: ["Raked White Gravel", "Stone Pagoda", "Cherry Blossom Petals"],
    acceptedSynonyms: [
      "gravel,sand,wave,rake,white,stone",
      "pagoda,statue,stone,bamboo,shrine,garden",
      "blossom,cherry,pink,petal,bridge,flower"
    ],
    hint: "Look at the raked gravel, stone pagoda, and flower petals.",
    explanation: "Describing minimalist aesthetics and spiritual landscapes refines vocabulary choices."
  }
];

// Iterate through the quests and map the correct properties
data.quests.forEach((quest, index) => {
  const match = sceneMapping[index % sceneMapping.length];
  if (match) {
    quest.sceneText = match.sceneText;
    quest.options = match.options;
    quest.acceptedSynonyms = match.acceptedSynonyms;
    quest.hint = match.hint;
    quest.explanation = match.explanation;
    quest.correctAnswer = match.options[0];
  }
});

fs.writeFileSync(filePath, JSON.stringify(data, null, 4), 'utf8');
console.log("Successfully enhanced 30 Scene Description Speaking curriculum quests!");
