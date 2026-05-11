/**
 * Speaking Content Pools for VoxAI Quest
 * Each entry is a high-quality, non-professional speaking scenario.
 */

const dailyExpression = [
  { phrase: "Let's call it a day.", context: "Finishing work", meaning: "To stop working on something." },
  { phrase: "Keep me in the loop.", context: "Business communication", meaning: "Keep me informed." },
  { phrase: "I'm on the fence about it.", context: "Making a decision", meaning: "Undecided." },
  { phrase: "Piece of cake!", context: "Task difficulty", meaning: "Very easy." },
  { phrase: "Break a leg!", context: "Performance", meaning: "Good luck." },
  { phrase: "Better late than never.", context: "Arrival", meaning: "It's better to arrive late than not at all." },
  { phrase: "Bite the bullet.", context: "Difficult situation", meaning: "To endure a painful situation." },
  { phrase: "Call it a night.", context: "Ending an evening", meaning: "Go to bed or stop an activity." },
  { phrase: "Cutting corners.", context: "Quality", meaning: "Doing something poorly to save time or money." },
  { phrase: "Get out of hand.", context: "Control", meaning: "Get out of control." },
  { phrase: "Hit the sack.", context: "Sleep", meaning: "Go to sleep." },
  { phrase: "It's not rocket science.", context: "Complexity", meaning: "It's not complicated." },
  { phrase: "Make a long story short.", context: "Storytelling", meaning: "Summarize." },
  { phrase: "On the ball.", context: "Competence", meaning: "Alert and efficient." },
  { phrase: "Pull yourself together.", context: "Emotions", meaning: "Calm down." },
  { phrase: "So far so good.", context: "Progress", meaning: "Things are going well up to now." },
  { phrase: "The best of both worlds.", context: "Choices", meaning: "An ideal situation." },
  { phrase: "Under the weather.", context: "Health", meaning: "Feeling sick." },
  { phrase: "Wrap your head around it.", context: "Understanding", meaning: "Understand something complex." },
  { phrase: "Your guess is as good as mine.", context: "Uncertainty", meaning: "I don't know either." },
  { phrase: "Actions speak louder than words.", context: "Integrity", meaning: "What you do is more important than what you say." },
  { phrase: "Back to the drawing board.", context: "Failure", meaning: "Start over after a failed attempt." },
  { phrase: "Comparing apples to oranges.", context: "Logic", meaning: "Comparing two things that are completely different." },
  { phrase: "Don't cry over spilled milk.", context: "Mistakes", meaning: "Don't worry about things that have already happened." },
  { phrase: "Every cloud has a silver lining.", context: "Optimism", meaning: "Every bad situation has a positive side." },
  { phrase: "Get a taste of your own medicine.", context: "Justice", meaning: "Being treated the same way you treat others." },
  { phrase: "Give someone the cold shoulder.", context: "Social", meaning: "Intentionally ignore someone." },
  { phrase: "Hit the nail on the head.", context: "Accuracy", meaning: "Describe exactly what is causing a situation." },
  { phrase: "Kill two birds with one stone.", context: "Efficiency", meaning: "Accomplish two things at once." },
  { phrase: "Let the cat out of the bag.", context: "Secrets", meaning: "Accidentally reveal a secret." }
];

const pronunciationFocus = [
  { word: "Anemone", phonetic: "/əˈnɛməni/", focus: "Vowel shifting" },
  { word: "Otorhinolaryngologist", phonetic: "/ˌoʊtoʊˌraɪnoʊˌlærənˈɡɒlədʒɪst/", focus: "Multi-syllabic stress" },
  { word: "Squirrel", phonetic: "/ˈskwɪrəl/", focus: "Rhotic 'r' sound" },
  { word: "Worcestershire", phonetic: "/ˈwʊstərʃɪər/", focus: "Silent letters" },
  { word: "Phenomenon", phonetic: "/fəˈnɒmɪnən/", focus: "Nasal transitions" },
  { word: "Rural", phonetic: "/ˈrʊərəl/", focus: "Double 'r' clarity" },
  { word: "Mischievous", phonetic: "/ˈmɪstʃɪvəs/", focus: "Correct syllable count" },
  { word: "Colonel", phonetic: "/ˈkɜːrnəl/", focus: "Spelling-sound mismatch" },
  { word: "Sixth", phonetic: "/sɪksθ/", focus: "Consonant cluster" },
  { word: "Isthmus", phonetic: "/ˈɪsməs/", focus: "Sibilant clarity" },
  { word: "Library", phonetic: "/ˈlaɪbrɛri/", focus: "R-vowel combo" },
  { word: "Regularly", phonetic: "/ˈrɛɡjʊlərli/", focus: "Rapid syllable transitions" },
  { word: "Specific", phonetic: "/spəˈsɪfɪk/", focus: "S-P cluster" },
  { word: "Hierarchy", phonetic: "/ˈhaɪərɑːrki/", focus: "Diphthongs" },
  { word: "Antarctic", phonetic: "/ænˈtɑːrktɪk/", focus: "Internal 'c' sound" },
  { word: "Subtle", phonetic: "/ˈsʌtəl/", focus: "Silent 'b'" },
  { word: "Cache", phonetic: "/kæʃ/", focus: "French loanword" },
  { word: "Entrepreneur", phonetic: "/ˌɒntrəprəˈnɜːr/", focus: "Nasalized vowels" },
  { word: "Queue", phonetic: "/kjuː/", focus: "Monophthong" },
  { word: "Draught", phonetic: "/drɑːft/", focus: "Old English 'gh' sound" }
];

const repeatSentence = [
  { text: "The economic forecast suggests a period of significant growth in the tech sector.", difficulty: 1 },
  { text: "Scientific research indicates that bioluminescence is more common in deep-sea organisms than previously thought.", difficulty: 2 },
  { text: "Archaeologists in {{location}} discovered a hidden chamber containing ancient {{item}}s from the Bronze Age.", difficulty: 2 },
  { text: "Quantum computing has the potential to revolutionize how {{business}} handles complex data encryption.", difficulty: 3 },
  { text: "Environmental policies must balance industrial development with the conservation of natural habitats in {{location}}.", difficulty: 2 },
  { text: "The architectural design of the new {{business}} headquarters emphasizes sustainability and natural light.", difficulty: 1 },
  { text: "Philosophical debates often center on the intersection of human ethics and artificial intelligence.", difficulty: 3 },
  { text: "Linguistic studies show that immersion is the most effective method for mastering the {{item}} language.", difficulty: 2 },
  { text: "The rapid expansion of urban centers in {{location}} has led to a surge in demand for smart infrastructure.", difficulty: 2 },
  { text: "Medical breakthroughs in gene editing are providing new hope for patients with {{symptom}} related conditions.", difficulty: 3 },
  { text: "The global supply chain for {{item}}s has been significantly impacted by the recent events in {{location}}.", difficulty: 2 },
  { text: "Neuroscience research explores how the brain processes complex {{item}} patterns in the {{business}} lab.", difficulty: 3 },
  { text: "Sustainable agriculture in {{location}} relies on the integration of traditional methods and modern tech.", difficulty: 2 },
  { text: "The development of reusable rockets at {{business}} has drastically reduced the cost of space exploration.", difficulty: 1 },
  { text: "Urban planning in {{location}} must prioritize pedestrian safety and the expansion of green spaces.", difficulty: 2 }
];

const situationSpeaking = [
  { scenario: "You are at {{business}} and need to ask {{name}} for help with the {{item}}.", prompt: "How do you ask politely?" },
  { scenario: "You missed a meeting with the team in {{location}} this {{time}}.", prompt: "How do you apologize?" },
  { scenario: "A colleague at {{business}} won an award for their work on the {{item}}.", prompt: "How do you congratulate them?" },
  { scenario: "You are at a cafe in {{location}} and they brought you the wrong {{item}}.", prompt: "How do you tell the waiter?" },
  { scenario: "You need to leave the {{time}} party early because of an emergency.", prompt: "How do you tell the host, {{name}}?" },
  { scenario: "You are asking a stranger in {{location}} for the direction to the {{business}} office.", prompt: "What is your opening line?" },
  { scenario: "Your friend {{name}} is feeling {{feeling}} about their new {{item}}.", prompt: "How do you comfort them?" },
  { scenario: "You want to invite the CEO of {{business}} to lunch this {{time}}.", prompt: "How do you phrase the invitation?" },
  { scenario: "A customer in {{location}} is complaining that their {{item}} is defective.", prompt: "How do you handle the complaint?" },
  { scenario: "You are being introduced to a famous scientist at the {{business}} gala.", prompt: "What is your first sentence?" }
];

const speakMissingWord = [
  { sentence: "The sun rises in the ______.", answer: "east" },
  { sentence: "Please turn ______ the lights before you leave.", answer: "off" },
  { sentence: "I'm looking forward ______ meeting you in {{location}}.", answer: "to" },
  { sentence: "She is very good ______ playing the {{item}}.", answer: "at" },
  { sentence: "We need to discuss the {{item}} ______ the meeting.", answer: "during" },
  { sentence: "He arrived ______ {{location}} yesterday morning.", answer: "in" },
  { sentence: "I prefer coffee ______ tea.", answer: "to" },
  { sentence: "The cat is hiding ______ the table.", answer: "under" },
  { sentence: "Wait ______ me at the {{business}} entrance.", answer: "for" },
  { sentence: "This {{item}} belongs ______ {{name}}.", answer: "to" },
  { sentence: "They are planning to travel ______ Japan next {{time}}.", answer: "to" },
  { sentence: "I cannot wait ______ see the new {{item}} at {{business}}.", answer: "to" },
  { sentence: "The book was written ______ a famous author in {{location}}.", answer: "by" },
  { sentence: "She was surprised ______ the news about the {{item}}.", answer: "by" },
  { sentence: "We should go ______ a walk in the {{location}} park.", answer: "for" }
];

const speakOpposite = [
  { word: "Hot", opposite: "Cold" },
  { word: "Fast", opposite: "Slow" },
  { word: "Happy", opposite: "Sad" },
  { word: "Big", opposite: "Small" },
  { word: "Rich", opposite: "Poor" },
  { word: "Old", opposite: "Young" },
  { word: "Strong", opposite: "Weak" },
  { word: "Hard", opposite: "Soft" },
  { word: "Beautiful", opposite: "Ugly" },
  { word: "Expensive", opposite: "Cheap" },
  { word: "Dark", opposite: "Light" },
  { word: "Victory", opposite: "Defeat" },
  { word: "Friend", opposite: "Enemy" },
  { word: "Arrive", opposite: "Depart" },
  { word: "Increase", opposite: "Decrease" },
  { word: "Success", opposite: "Failure" },
  { word: "Public", opposite: "Private" },
  { word: "Ancient", opposite: "Modern" },
  { word: "Bold", opposite: "Timid" },
  { word: "Complex", opposite: "Simple" }
];

const speakSynonym = [
  { word: "Happy", synonym: "Joyful" },
  { word: "Smart", synonym: "Intelligent" },
  { word: "Fast", synonym: "Quick" },
  { word: "Angry", synonym: "Furious" },
  { word: "Big", synonym: "Enormous" },
  { word: "Beautiful", synonym: "Gorgeous" },
  { word: "Small", synonym: "Tiny" },
  { word: "Difficult", synonym: "Challenging" },
  { word: "Funny", synonym: "Hilarious" },
  { word: "Scared", synonym: "Terrified" },
  { word: "Tired", synonym: "Exhausted" },
  { word: "Interesting", synonym: "Fascinating" },
  { word: "Start", synonym: "Begin" },
  { word: "Stop", synonym: "Cease" },
  { word: "Help", synonym: "Assist" },
  { word: "Brief", synonym: "Short" },
  { word: "Brave", synonym: "Courageous" },
  { word: "Calm", synonym: "Peaceful" },
  { word: "Wealthy", synonym: "Prosperous" },
  { word: "Reliable", synonym: "Dependable" }
];

const yesNoSpeaking = [
  { question: "Is the capital of France London?", answer: "No" },
  { question: "Do humans need water to survive?", answer: "Yes" },
  { question: "Is the sun a planet?", answer: "No" },
  { question: "Can birds fly?", answer: "Yes" },
  { question: "Is 10 greater than 5?", answer: "Yes" },
  { question: "Does ice melt when heated?", answer: "Yes" },
  { question: "Is the ocean made of fresh water?", answer: "No" },
  { question: "Do apples grow on trees?", answer: "Yes" },
  { question: "Is blue a primary color?", answer: "Yes" },
  { question: "Can humans breathe underwater without equipment?", answer: "No" },
  { question: "Is Mars the closest planet to the Sun?", answer: "No" },
  { question: "Do snakes have legs?", answer: "No" },
  { question: "Is the Great Wall of China in Asia?", answer: "Yes" },
  { question: "Can computers process data faster than humans?", answer: "Yes" },
  { question: "Is diamond the hardest natural substance?", answer: "Yes" }
];

const sceneDescriptionSpeaking = [
  { scene: "A busy market in {{location}} with people buying colorful fruits.", description: "People are shopping for fruits in a busy {{location}} market." },
  { scene: "A futuristic office at {{business}} with robots and holograms.", description: "The office of {{business}} is filled with robots and holograms." },
  { scene: "A quiet snowy evening in {{location}} with glowing street lamps.", description: "Snow is falling in {{location}} under the street lamps." },
  { scene: "A chef at {{business}} preparing a complex {{item}} dish.", description: "A chef is carefully preparing a meal at {{business}}." },
  { scene: "A group of hikers reaching the summit of a mountain in {{location}}.", description: "Hikers have reached the top of the mountain." },
  { scene: "A vibrant street festival in {{location}} with dancers and musicians.", description: "Musicians and dancers are performing at a festival in {{location}}." },
  { scene: "A high-tech lab at {{business}} where scientists are testing a new {{item}}.", description: "Scientists are conducting experiments with a {{item}}." },
  { scene: "A serene sunset over the ocean in {{location}} with a single sailboat.", description: "A sailboat is drifting on the ocean under a golden sunset." },
  { scene: "A crowded train station in {{location}} during the morning rush.", description: "Commuters are rushing to catch their trains in {{location}}." },
  { scene: "A peaceful library in {{location}} with students studying quietly.", description: "Students are reading and studying in the quiet library." }
];

const dialogueRoleplay = [
  {
    role: "Customer",
    partner: "Waiter",
    context: "Ordering at a restaurant",
    script: [
      { speaker: "Customer", text: "I'd like to order the {{item}}, please." },
      { speaker: "Waiter", text: "Would you like any drinks with that?" },
      { speaker: "Customer", text: "Just a glass of water, thank you." }
    ]
  },
  {
    role: "Candidate",
    partner: "Interviewer",
    context: "Job interview at {{business}}",
    script: [
      { speaker: "Interviewer", text: "Why do you want to work for {{business}}?" },
      { speaker: "Candidate", text: "I admire your work in the {{location}} market." }
    ]
  },
  {
    role: "Patient",
    partner: "Doctor",
    context: "Discussing symptoms in {{location}}",
    script: [
      { speaker: "Doctor", text: "How long have you been feeling this {{symptom}}?" },
      { speaker: "Patient", text: "It started around {{time}} yesterday." },
      { speaker: "Doctor", text: "I'll prescribe some {{item}} for you." }
    ]
  },
  {
    role: "Traveler",
    partner: "Desk Agent",
    context: "Booking a flight to {{location}}",
    script: [
      { speaker: "Traveler", text: "Are there any seats left for the {{time}} flight?" },
      { speaker: "Desk Agent", text: "Yes, we have one window seat in business class." },
      { speaker: "Traveler", text: "I'll take it! Do you accept credit cards?" }
    ]
  }
];

module.exports = {
  dailyExpression,
  pronunciationFocus,
  repeatSentence,
  situationSpeaking,
  speakMissingWord,
  speakOpposite,
  speakSynonym,
  yesNoSpeaking,
  sceneDescriptionSpeaking,
  dialogueRoleplay
};
