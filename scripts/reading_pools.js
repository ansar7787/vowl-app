/**
 * Reading Content Pools for VoxAI Quest
 * Each entry is a high-quality, non-placeholder reading task.
 * format: [main_content, sub_content/extra, hint, additional_meta]
 */

const readAndAnswerData = [
  [
    "The Amazon Rainforest is the largest tropical rainforest in the world. It is home to millions of species of insects, plants, and birds. Many of these species are still undiscovered by scientists.",
    "Which of the following is true about the Amazon Rainforest?",
    ["It is the smallest rainforest.", "It has very few insects.", "It houses millions of species.", "It is mostly undiscovered by birds."],
    2,
    "Focus on the second sentence."
  ],
  [
    "Mount Everest is the highest mountain on Earth, reaching 8,848 meters above sea level. It is located in the Himalayas on the border between Nepal and China.",
    "Where is Mount Everest located?",
    ["The Alps", "The Andes", "The Himalayas", "The Rockies."],
    2,
    "Check the location mentioned in the second sentence."
  ],
  [
    "Marie Curie was the first woman to win a Nobel Prize. She was a physicist and chemist who conducted pioneering research on radioactivity.",
    "What field of study did Marie Curie focus on?",
    ["Astronomy", "Radioactivity", "Biology", "Literature"],
    1,
    "Look at the end of the second sentence."
  ],
  [
    "The Great Wall of China was built over many centuries to protect the Chinese states from invasions. It is thousands of miles long and visible from low Earth orbit.",
    "Why was the Great Wall of China built?",
    ["For decoration", "To protect against invasions", "To mark the border of India", "For tourism."],
    1,
    "The answer is in the first sentence."
  ],
  [
    "Photosynthesis is the process used by plants to convert light energy into chemical energy. This energy is stored in the form of sugar.",
    "What do plants convert light energy into?",
    ["Heat", "Chemical energy", "Oxygen", "Water"],
    1,
    "Look for the phrase 'convert light energy into'."
  ],
  [
    "The Renaissance was a period of intense artistic and intellectual activity, originating in Italy in the 14th century and spreading throughout Europe.",
    "Where did the Renaissance originate?",
    ["France", "Germany", "Italy", "Spain"],
    2,
    "Check the first sentence for the location."
  ],
  [
    "The theory of relativity, developed by Albert Einstein, revolutionized our understanding of space, time, and gravity.",
    "Who developed the theory of relativity?",
    ["Isaac Newton", "Albert Einstein", "Stephen Hawking", "Galileo Galilei"],
    1,
    "The name is in the first half of the sentence."
  ],
  [
    "Antarctica is the coldest, driest, and windiest continent on Earth. It is almost entirely covered by ice and contains about 70% of the world's fresh water.",
    "What percentage of the world's fresh water is found in Antarctica?",
    ["10%", "50%", "70%", "90%"],
    2,
    "Look for the number in the second sentence."
  ],
  [
    "The Rosetta Stone is an ancient Egyptian artifact that allowed historians to finally decipher hieroglyphic writing.",
    "What did the Rosetta Stone help historians do?",
    ["Build pyramids", "Decipher hieroglyphs", "Paint murals", "Sail the Nile"],
    1,
    "Look at the end of the sentence."
  ],
  [
    "Jupiter is the largest planet in our solar system and is known for its Great Red Spot, a giant storm that has lasted for centuries.",
    "What is the Great Red Spot on Jupiter?",
    ["A volcano", "A mountain", "A giant storm", "An ocean"],
    2,
    "Check the description after the comma."
  ],
  [
    "DNA, or deoxyribonucleic acid, is the molecule that carries genetic information for the development and functioning of all known living organisms.",
    "What does DNA carry?",
    ["Light energy", "Genetic information", "Oxygen", "Blood"],
    1,
    "The answer follows 'molecule that carries'."
  ],
  [
    "The Magna Carta, signed in 1215, was a document that limited the power of the English king and established certain legal rights for citizens.",
    "When was the Magna Carta signed?",
    ["1066", "1215", "1492", "1776"],
    1,
    "The date is near the beginning."
  ],
  [
    "Bioluminescence is the production and emission of light by a living organism, common in deep-sea creatures like the anglerfish.",
    "What is bioluminescence?",
    ["A type of ocean current", "The production of light by organisms", "A deep-sea plant", "A method of underwater breathing"],
    1,
    "Define based on the first part of the sentence."
  ],
  [
    "The Silk Road was an ancient network of trade routes that connected the East and West, facilitating the exchange of goods, culture, and ideas.",
    "What was the main purpose of the Silk Road?",
    ["Military conquest", "Trade and cultural exchange", "Religious pilgrimage", "Scientific exploration"],
    1,
    "Think about 'network of trade routes'."
  ],
  [
    "Virtual reality is a simulated experience that can be similar to or completely different from the real world, often used in gaming and medical training.",
    "Which field uses virtual reality according to the text?",
    ["Agriculture", "Mining", "Medical training", "Cooking"],
    2,
    "Look at the end of the sentence."
  ]
];

const findWordMeaningData = [
  [
    "The explorers were undeterred by the harsh weather and continued their journey into the mountains.",
    "undeterred",
    ["Discouraged", "Motivated", "Stopped", "Not discouraged"],
    3,
    "Think about the context of 'continued their journey'."
  ],
  [
    "The old mansion was dilapidated, with broken windows and a sagging roof.",
    "dilapidated",
    ["In good condition", "Very small", "In a state of disrepair", "Extremely expensive"],
    2,
    "Notice the description of broken windows and a sagging roof."
  ],
  [
    "She was very frugal, always looking for sales and avoiding unnecessary expenses.",
    "frugal",
    ["Generous", "Wasteful", "Economical", "Greedy"],
    2,
    "Someone who looks for sales is saving money."
  ],
  [
    "The lecture was quite monotonous, and several students began to fall asleep.",
    "monotonous",
    ["Exciting", "Dull and repetitive", "Very loud", "Educational"],
    1,
    "Students falling asleep suggests it was boring."
  ],
  [
    "The scientist's claims were verified by several independent studies.",
    "verified",
    ["Rejected", "Confused", "Confirmed", "Ignored"],
    2,
    "Independent studies usually check if something is true."
  ],
  [
    "His ephemeral fame lasted only a few weeks before the public moved on to the next trend.",
    "ephemeral",
    ["Eternal", "Short-lived", "Loud", "Famous"],
    1,
    "The fame 'lasted only a few weeks'."
  ],
  [
    "The lawyer provided a concise summary of the case, covering all main points in just two minutes.",
    "concise",
    ["Brief and clear", "Long and detailed", "Confusing", "Legal"],
    0,
    "He covered 'all main points in just two minutes'."
  ],
  [
    "The water in the lake was so pellucid that you could see the fish swimming at the bottom.",
    "pellucid",
    ["Murky", "Deep", "Crystal clear", "Freezing"],
    2,
    "You could 'see the fish at the bottom'."
  ],
  [
    "After the storm, the atmosphere was serene, with no wind and a clear sky.",
    "serene",
    ["Violent", "Cloudy", "Peaceful", "Humid"],
    2,
    "No wind and a clear sky suggest peace."
  ],
  [
    "He had a gregarious personality and loved attending large social gatherings.",
    "gregarious",
    ["Shy", "Sociable", "Aggressive", "Bored"],
    1,
    "He 'loved large social gatherings'."
  ],
  [
    "The path was precarious, with loose rocks and a steep drop on one side.",
    "precarious",
    ["Safe", "Beautiful", "Unstable and dangerous", "Wide"],
    2,
    "Loose rocks and a steep drop make it dangerous."
  ],
  [
    "Her decision to quit was arbitrary, based on a whim rather than logic.",
    "arbitrary",
    ["Planned", "Random", "Difficult", "Wise"],
    1,
    "It was based 'on a whim'."
  ]
];

const trueFalseReadingData = [
  [
    "Whales are mammals, which means they breathe air and nurse their young with milk. Unlike fish, they do not have gills.",
    "Whales have gills to breathe underwater.",
    ["True", "False"],
    1,
    "The text says they do NOT have gills."
  ],
  [
    "The Eiffel Tower was completed in 1889 for the World's Fair in Paris. It was originally intended to be a temporary structure.",
    "The Eiffel Tower was built to be a permanent monument from the start.",
    ["True", "False"],
    1,
    "The text says it was originally intended to be temporary."
  ],
  [
    "Bees are essential for pollinating many of the crops we eat. Without them, food production would significantly decrease.",
    "Bees play a minor role in food production.",
    ["True", "False"],
    1,
    "The text says they are essential."
  ],
  [
    "The moon does not produce its own light; it reflects the light of the sun.",
    "The moon is a source of its own light.",
    ["True", "False"],
    1,
    "The text says it reflects the sun's light."
  ],
  [
    "Venus is the hottest planet in our solar system, even though Mercury is closer to the sun.",
    "Mercury is the hottest planet in the solar system.",
    ["True", "False"],
    1,
    "The text says Venus is the hottest."
  ],
  [
    "Diamonds are formed deep within the Earth's mantle under conditions of high pressure and temperature.",
    "Diamonds are formed on the Earth's surface.",
    ["True", "False"],
    1,
    "Text says 'deep within the Earth's mantle'."
  ],
  [
    "The human heart is roughly the size of a fist and pumps blood throughout the entire body.",
    "The heart is about the size of a football.",
    ["True", "False"],
    1,
    "Text says it is the size of a fist."
  ],
  [
    "Sound travels faster through water than it does through air.",
    "Sound travels slower in water than in air.",
    ["True", "False"],
    1,
    "The statement is the opposite of the fact in the text."
  ]
];

const sentenceOrderReadingData = [
  [
    "I woke up early this morning. First, I made some coffee. Then, I read the newspaper for an hour. Finally, I got ready for work.",
    ["First, I made some coffee.", "Finally, I got ready for work.", "I woke up early this morning.", "Then, I read the newspaper for an hour."],
    [2, 0, 3, 1],
    "Look for time markers like 'First', 'Then', and 'Finally'."
  ],
  [
    "To make a sandwich, get two slices of bread. Spread some peanut butter on one slice. Put some jelly on the other slice. Press the two slices together.",
    ["Put some jelly on the other slice.", "Press the two slices together.", "To make a sandwich, get two slices of bread.", "Spread some peanut butter on one slice."],
    [2, 3, 0, 1],
    "Follow the logical steps of making a sandwich."
  ],
  [
    "The sun rose over the horizon. The birds started singing in the trees. The dew on the grass began to evaporate. A new day had officially begun.",
    ["The birds started singing in the trees.", "A new day had officially begun.", "The sun rose over the horizon.", "The dew on the grass began to evaporate."],
    [2, 0, 3, 1],
    "The sun rising is usually the first event."
  ],
  [
    "He opened the door cautiously. The room inside was pitch black. He reached for the light switch on the wall. The light revealed a surprising mess.",
    ["The room inside was pitch black.", "The light revealed a surprising mess.", "He opened the door cautiously.", "He reached for the light switch on the wall."],
    [2, 0, 3, 1],
    "Logical flow: Open -> Observe -> Act -> Reveal."
  ]
];

const readingSpeedCheckData = [
  ["A fast-paced story about a race across the desert.", 30, "Read as quickly as you can while understanding the plot."],
  ["A technical manual for a new piece of software.", 60, "Focus on scanning for keywords and main ideas."],
  ["A news article about a recent scientific discovery.", 45, "Try to grasp the main findings in one go."],
  ["A short poem about the changing seasons.", 20, "Read for rhythm as well as meaning."],
  ["A recipe for a complex chocolate cake.", 40, "Scan for ingredients and key temperatures."],
  ["A travel brochure for a tropical island.", 25, "Look for activities and best times to visit."]
];

const guessTitleData = [
  [
    "In the heart of the city, there is a hidden park where time seems to slow down. Tall trees block out the noise of traffic, and a small pond reflects the blue sky. It's a sanctuary for those looking to escape the hustle and bustle.",
    ["Traffic Troubles", "The Hidden Sanctuary", "City Life", "A Busy Day"],
    1,
    "Think about the main theme of the park being a peaceful escape."
  ],
  [
    "Deep in the ocean, strange creatures with glowing bodies live in total darkness. They have adapted to the high pressure and cold temperatures of the abyss. This mysterious world remains mostly unexplored by humans.",
    ["Life in the Abyss", "Sunny Beaches", "The Forest Floor", "Exploring Mars"],
    0,
    "The text is about life deep in the ocean."
  ],
  [
    "The ancient library was filled with scrolls from empires long gone. Historians spend their lives trying to translate the mysterious symbols. Every page tells a story of a time before recorded history.",
    ["Modern Tech", "Cooking Secrets", "Whispers of the Past", "Digital Future"],
    2,
    "The focus is on ancient history and scrolls."
  ],
  [
    "Wolves are highly social animals that live in packs. Each pack has a strict hierarchy, led by an alpha pair. They communicate through howls, scent marking, and body language to coordinate hunts.",
    ["The Solitary Hunter", "The Social World of Wolves", "How to Hunt Deer", "The History of Dogs"],
    1,
    "Focus on the 'social' and 'pack' aspect."
  ]
];

const readAndMatchData = [
  [
    "Match the animal to its typical habitat.",
    {"Lion": "Savannah", "Penguin": "Antarctica", "Camel": "Desert", "Shark": "Ocean"},
    "Think about where each animal lives."
  ],
  [
    "Match the inventor to their invention.",
    {"Thomas Edison": "Light Bulb", "Alexander Bell": "Telephone", "Wright Brothers": "Airplane", "James Watt": "Steam Engine"},
    "Common historical facts."
  ],
  [
    "Match the planet to a key characteristic.",
    {"Mars": "The Red Planet", "Jupiter": "Largest Planet", "Saturn": "Rings", "Venus": "Hottest Planet"},
    "Astronomy basics."
  ],
  [
    "Match the country to its famous landmark.",
    {"France": "Eiffel Tower", "India": "Taj Mahal", "USA": "Statue of Liberty", "China": "Great Wall"},
    "World landmarks."
  ]
];

const paragraphSummaryData = [
  [
    "Global warming is causing the polar ice caps to melt at an alarming rate. This leads to rising sea levels, which threaten coastal cities around the world. Scientists are working on ways to reduce carbon emissions to slow down this process.",
    ["The ice caps are fine.", "Melting ice caps cause sea level rise and need emission cuts.", "Cities are safe from the ocean.", "Carbon emissions are good for the environment."],
    1,
    "Which option covers both the problem and the proposed solution?"
  ],
  [
    "The internet has revolutionized the way we access information. We can now find the answer to almost any question in seconds. However, this ease of access has also led to the spread of misinformation, making critical thinking more important than ever.",
    ["The internet is always right.", "Misinformation is not a problem.", "The internet changed info access but needs critical thinking.", "Books are better than the internet."],
    2,
    "Look for a balance between the benefits and the drawbacks."
  ],
  [
    "Sleep is essential for cognitive function and physical health. During sleep, the brain processes information from the day and the body repairs tissues. Chronic lack of sleep can lead to serious health issues like heart disease and weakened immunity.",
    ["Sleep is a waste of time.", "Lack of sleep is harmless.", "Sleep is crucial for brain and body health.", "repairing tissues is easy."],
    2,
    "Focus on 'essential' and the consequences of lacking it."
  ]
];

const readingInferenceData = [
  [
    "Sarah looked at her umbrella, then at the dark clouds gathering in the sky. She let out a long sigh and went back inside to grab her raincoat.",
    "What can we infer about Sarah's thoughts?",
    ["She is happy about the weather.", "She expects it to rain soon.", "She forgot her keys.", "She wants to go for a swim."],
    1,
    "Why would she grab a raincoat after seeing dark clouds?"
  ],
  [
    "The waiter brought the bill, and Tom's eyes widened. He reached for his wallet and then slowly put his hand back on the table, looking nervous.",
    "What can we infer about Tom's situation?",
    ["He loved the food.", "He doesn't have enough money.", "He is waiting for a friend.", "He is ready to leave."],
    1,
    "Widened eyes and nervousness usually relate to the cost."
  ],
  [
    "The dog stood by the front door, wagging its tail furiously and holding its leash in its mouth, looking up at its owner.",
    "What does the dog want?",
    ["To take a nap", "To go for a walk", "To eat dinner", "To hide under the couch"],
    1,
    "Tail wagging and leash in mouth are clear signs."
  ]
];

const readingConclusionData = [
  [
    "The team had practiced for months. They had analyzed their opponents' strategies and improved their own physical fitness. As the whistle blew for the start of the final match, they felt ready.",
    "What is the most likely conclusion?",
    ["They will give up immediately.", "They are well-prepared for the match.", "They forgot the rules of the game.", "The match was cancelled."],
    1,
    "Practice and analysis lead to preparedness."
  ],
  [
    "The plant had yellow leaves and dry soil. It had been sitting in a dark corner for weeks without any attention.",
    "What is the best conclusion for the plant's health?",
    ["It is thriving.", "It needs water and sunlight.", "It is a plastic plant.", "It was recently repotted."],
    1,
    "Yellow leaves and dry soil are signs of neglect."
  ],
  [
    "The movie ended, and the audience remained in their seats, silently watching the credits roll as many wiped away tears.",
    "What was the likely tone of the movie?",
    ["Hilarious", "Terrifying", "Emotionally moving", "Boring"],
    2,
    "Tears and silence suggest a deep emotional impact."
  ]
];

const clozeTestData = [
  [
    "The sun is a star located at the ___ of our solar system. It provides the energy necessary for ___ on Earth.",
    ["center", "life"],
    ["edge", "rocks", "center", "life", "back", "water"],
    [2, 3],
    "Think about the sun's position and its role for living things."
  ],
  [
    "Regular exercise is ___ for maintaining a healthy body. It helps to strengthen muscles and improve ___ health.",
    ["essential", "cardiovascular"],
    ["optional", "cardiovascular", "essential", "harmful", "fast", "bad"],
    [2, 1],
    "Benefits of exercise."
  ],
  [
    "History is the study of the ___. It helps us understand how ___ events shaped our world today.",
    ["past", "previous"],
    ["future", "past", "modern", "previous", "unimportant", "boring"],
    [1, 3],
    "History deals with what happened before."
  ]
];

const skimmingScanningData = [
  [
    "Event: Summer Festival. Date: July 15. Location: Riverside Park. Time: 10 AM - 8 PM. Activities: Music, Food, Games.",
    "What time does the festival end?",
    ["10 AM", "5 PM", "8 PM", "Midnight"],
    2,
    "Scan for the 'Time' section."
  ],
  [
    "Product: SuperJuice. Ingredients: Apple, Orange, Kale, Ginger. Price: $4.99. Calories: 120.",
    "How much does the juice cost?",
    ["$1.99", "$4.99", "$120", "Free"],
    1,
    "Scan for the '$' symbol."
  ],
  [
    "Flight 202 to New York: Status: Delayed. New Time: 4:30 PM. Gate: B12.",
    "Which gate is the flight at?",
    ["A1", "B12", "C5", "Main Lobby"],
    1,
    "Scan for 'Gate'."
  ]
];

module.exports = {
  readAndAnswer: readAndAnswerData.map(d => ({
    instruction: "Read the passage and answer the question.",
    fields: { main: d[0], extra: d[1], options: d[2], correctIndex: d[3], hint: d[4] }
  })),
  findWordMeaning: findWordMeaningData.map(d => ({
    instruction: "Read the passage and find the meaning of the highlighted word.",
    fields: { main: d[0], extra: d[1], options: d[2], correctIndex: d[3], hint: d[4] }
  })),
  trueFalseReading: trueFalseReadingData.map(d => ({
    instruction: "Read the passage and determine if the statement is True or False.",
    fields: { main: d[0], extra: d[1], options: d[2], correctIndex: d[3], hint: d[4] }
  })),
  sentenceOrderReading: sentenceOrderReadingData.map(d => ({
    instruction: "Reorder the sentences to form a logical paragraph.",
    fields: { main: d[0], sentences: d[1], correctOrder: d[2], hint: d[3] }
  })),
  readingSpeedCheck: readingSpeedCheckData.map(d => ({
    instruction: "Read the following as quickly as possible.",
    fields: { main: d[0], timeGoal: d[1], hint: d[2] }
  })),
  guessTitle: guessTitleData.map(d => ({
    instruction: "Read the passage and choose the best title.",
    fields: { main: d[0], options: d[1], correctIndex: d[2], hint: d[3] }
  })),
  readAndMatch: readAndMatchData.map(d => ({
    instruction: "Match the following related items.",
    fields: { main: d[0], pairs: d[1], hint: d[2] }
  })),
  paragraphSummary: paragraphSummaryData.map(d => ({
    instruction: "Read the paragraph and choose the best summary.",
    fields: { main: d[0], options: d[1], correctIndex: d[2], hint: d[3] }
  })),
  readingInference: readingInferenceData.map(d => ({
    instruction: "Read the passage and infer the answer to the question.",
    fields: { main: d[0], extra: d[1], options: d[2], correctIndex: d[3], hint: d[4] }
  })),
  readingConclusion: readingConclusionData.map(d => ({
    instruction: "Read the passage and choose the most logical conclusion.",
    fields: { main: d[0], options: d[1], correctIndex: d[2], hint: d[3] }
  })),
  clozeTest: clozeTestData.map(d => ({
    instruction: "Fill in the blanks with the correct words.",
    fields: { main: d[0], answers: d[1], options: d[2], correctIndices: d[3], hint: d[4] }
  })),
  skimmingScanning: skimmingScanningData.map(d => ({
    instruction: "Scan the text to find the specific detail requested.",
    fields: { main: d[0], extra: d[1], options: d[2], correctIndex: d[3], hint: d[4] }
  })),
};
