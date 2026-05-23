const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'speaking', 'speakSynonym_1_10.json');

const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));

const synonymMapping = [
  {
    plainText: "A scientist monitors the circuit accurately.",
    textToSpeak: "A scientist *monitors* the circuit accurately.",
    acceptedSynonyms: ["observes", "watches", "tracks", "supervises", "checks", "inspects"],
    hint: "Think of another word for watching or checking closely.",
    explanation: "'Observes' or 'tracks' fits contextually as a replacement for 'monitors'."
  },
  {
    plainText: "The commander monitors the circuit accurately.",
    textToSpeak: "The commander *monitors* the circuit accurately.",
    acceptedSynonyms: ["observes", "watches", "tracks", "supervises", "checks", "inspects"],
    hint: "Identify a word matching tracking or overseeing.",
    explanation: "'Supervises' or 'watches' are perfect synonyms for monitors in this context."
  },
  {
    plainText: "A pilot monitors the circuit accurately.",
    textToSpeak: "A pilot *monitors* the circuit accurately.",
    acceptedSynonyms: ["observes", "watches", "tracks", "supervises", "checks", "inspects"],
    hint: "What word describes tracking stats or gauges?",
    explanation: "'Checks' or 'inspects' can cleanly replace monitors here."
  },
  {
    plainText: "The traveler discovers the network rapidly.",
    textToSpeak: "The traveler *discovers* the network rapidly.",
    acceptedSynonyms: ["finds", "uncovers", "detects", "locates", "reveals", "spots"],
    hint: "Think of finding something hidden.",
    explanation: "'Finds' or 'detects' refers to discovering or uncovering new network access."
  },
  {
    plainText: "A doctor discovers the network rapidly.",
    textToSpeak: "A doctor *discovers* the network rapidly.",
    acceptedSynonyms: ["finds", "uncovers", "detects", "locates", "reveals", "spots"],
    hint: "Think of detecting or locating a network.",
    explanation: "'Locates' or 'detects' indicates finding the exact coordinates of the network."
  },
  {
    plainText: "The teacher discovers the network rapidly.",
    textToSpeak: "The teacher *discovers* the network rapidly.",
    acceptedSynonyms: ["finds", "uncovers", "detects", "locates", "reveals", "spots"],
    hint: "Think of revealing or locating new structures.",
    explanation: "'Finds' or 'uncovers' are contextually strong synonyms."
  },
  {
    plainText: "A pilot builds the database flawlessly.",
    textToSpeak: "A pilot *builds* the database flawlessly.",
    acceptedSynonyms: ["constructs", "creates", "assembles", "develops", "structures", "makes"],
    hint: "Think of constructing or developing a base.",
    explanation: "'Constructs' or 'assembles' means creating or putting the database structure together."
  },
  {
    plainText: "The technician builds the database flawlessly.",
    textToSpeak: "The technician *builds* the database flawlessly.",
    acceptedSynonyms: ["constructs", "creates", "assembles", "develops", "structures", "makes"],
    hint: "Think of developing or structuring software components.",
    explanation: "'Develops' or 'structures' are excellent alternatives to builds."
  },
  {
    plainText: "An explorer builds the database flawlessly.",
    textToSpeak: "An explorer *builds* the database flawlessly.",
    acceptedSynonyms: ["constructs", "creates", "assembles", "develops", "structures", "makes"],
    hint: "Think of creating or assembling something from scratch.",
    explanation: "'Creates' or 'makes' are simple, accurate synonyms for builds."
  },
  {
    plainText: "The teacher sends a reactor boldly.",
    textToSpeak: "The teacher sends a reactor *boldly*.",
    acceptedSynonyms: ["bravely", "fearlessly", "courageously", "daringly", "heroically"],
    hint: "Think of acting without any fear.",
    explanation: "'Bravely' or 'fearlessly' means acting with confidence and no hesitation."
  },
  {
    plainText: "A researcher sends a reactor boldly.",
    textToSpeak: "A researcher sends a reactor *boldly*.",
    acceptedSynonyms: ["bravely", "fearlessly", "courageously", "daringly", "heroically"],
    hint: "What is a synonym for daring actions?",
    explanation: "'Daringly' or 'courageously' denotes a bold approach to operations."
  },
  {
    plainText: "The detective sends a reactor boldly.",
    textToSpeak: "The detective sends a reactor *boldly*.",
    acceptedSynonyms: ["bravely", "fearlessly", "courageously", "daringly", "heroically"],
    hint: "Think of a heroic or fearless gesture.",
    explanation: "'Fearlessly' or 'bravely' fits as a replacement for boldly."
  },
  {
    plainText: "An explorer tests the sensor quickly.",
    textToSpeak: "An explorer tests the sensor *quickly*.",
    acceptedSynonyms: ["rapidly", "swiftly", "fast", "hastily", "speedily", "briskly"],
    hint: "Think of a rapid or high-speed action.",
    explanation: "'Swiftly' or 'rapidly' are high-quality synonyms for quickly."
  },
  {
    plainText: "The droid tests the sensor quickly.",
    textToSpeak: "The droid tests the sensor *quickly*.",
    acceptedSynonyms: ["rapidly", "swiftly", "fast", "hastily", "speedily", "briskly"],
    hint: "What describes a fast, brisk calibration?",
    explanation: "'Briskly' or 'fast' denotes quick processing of the test."
  },
  {
    plainText: "A student tests the sensor quickly.",
    textToSpeak: "A student tests the sensor *quickly*.",
    acceptedSynonyms: ["rapidly", "swiftly", "fast", "hastily", "speedily", "briskly"],
    hint: "Think of an urgent or speedy resolution.",
    explanation: "'Speedily' or 'rapidly' is perfectly suited here."
  },
  {
    plainText: "The detective receives the software successfully.",
    textToSpeak: "The detective receives the software *successfully*.",
    acceptedSynonyms: ["triumphantly", "victoriously", "prosperously", "effectively", "fruitfully"],
    hint: "Think of achieving a positive, triumphant outcome.",
    explanation: "'Effectively' or 'fruitfully' signifies successful transfer of software."
  },
  {
    plainText: "A spy receives the software successfully.",
    textToSpeak: "A spy receives the software *successfully*.",
    acceptedSynonyms: ["triumphantly", "victoriously", "prosperously", "effectively", "fruitfully"],
    hint: "Think of a triumphant spy delivery.",
    explanation: "'Triumphantly' or 'effectively' are great contextual choices."
  },
  {
    plainText: "The driver receives the software successfully.",
    textToSpeak: "The driver receives the software *successfully*.",
    acceptedSynonyms: ["triumphantly", "victoriously", "prosperously", "effectively", "fruitfully"],
    hint: "What describes a successful execution?",
    explanation: "'Effectively' or 'fruitfully' fits smoothly into the sentence structure."
  },
  {
    plainText: "A student configures the signal perfectly.",
    textToSpeak: "A student configures the signal *perfectly*.",
    acceptedSynonyms: ["flawlessly", "impeccably", "faultlessly", "ideally", "sublimely"],
    hint: "Think of something done without any mistakes or flaws.",
    explanation: "'Flawlessly' or 'impeccably' indicates a 100% correct calibration."
  },
  {
    plainText: "The analyst configures the signal perfectly.",
    textToSpeak: "The analyst configures the signal *perfectly*.",
    acceptedSynonyms: ["flawlessly", "impeccably", "faultlessly", "ideally", "sublimely"],
    hint: "What describes faultless alignment?",
    explanation: "'Impeccably' or 'faultlessly' are precise replacements for perfectly."
  },
  {
    plainText: "A manager configures the signal perfectly.",
    textToSpeak: "A manager configures the signal *perfectly*.",
    acceptedSynonyms: ["flawlessly", "impeccably", "faultlessly", "ideally", "sublimely"],
    hint: "Think of flawless structural balance.",
    explanation: "'Flawlessly' or 'ideally' are contextually matching alternatives."
  },
  {
    plainText: "The driver protects a system smoothly.",
    textToSpeak: "The driver protects a system *smoothly*.",
    acceptedSynonyms: ["effortlessly", "easily", "seamlessly", "fluidly", "gracefully"],
    hint: "Think of something executed effortlessly without friction.",
    explanation: "'Seamlessly' or 'effortlessly' denotes a frictionless protection routine."
  },
  {
    plainText: "A chef protects a system smoothly.",
    textToSpeak: "A chef protects a system *smoothly*.",
    acceptedSynonyms: ["effortlessly", "easily", "seamlessly", "fluidly", "gracefully"],
    hint: "What is an alternative for highly fluid action?",
    explanation: "'Fluidly' or 'seamlessly' are excellent synonym choices."
  },
  {
    plainText: "The engineer protects a system smoothly.",
    textToSpeak: "The engineer protects a system *smoothly*.",
    acceptedSynonyms: ["effortlessly", "easily", "seamlessly", "fluidly", "gracefully"],
    hint: "Think of an effortless security sweep.",
    explanation: "'Effortlessly' or 'easily' fits cleanly."
  },
  {
    plainText: "A manager launches the shield safely.",
    textToSpeak: "A manager launches the shield *safely*.",
    acceptedSynonyms: ["securely", "harmlessly", "soundly", "cautiously", "protectedly"],
    hint: "Think of a secure, protected launch.",
    explanation: "'Securely' or 'cautiously' refers to a secure shield deployment."
  },
  {
    plainText: "The hero launches the shield safely.",
    textToSpeak: "The hero launches the shield *safely*.",
    acceptedSynonyms: ["securely", "harmlessly", "soundly", "cautiously", "protectedly"],
    hint: "How do you deploy shields securely?",
    explanation: "'Securely' or 'protectedly' are excellent alternatives."
  },
  {
    plainText: "A robot launches the shield safely.",
    textToSpeak: "A robot launches the shield *safely*.",
    acceptedSynonyms: ["securely", "harmlessly", "soundly", "cautiously", "protectedly"],
    hint: "Think of a risk-free, protected initialization.",
    explanation: "'Securely' or 'soundly' matches perfectly."
  },
  {
    plainText: "A spy configures the circuit quietly.",
    textToSpeak: "A spy configures the circuit *quietly*.",
    acceptedSynonyms: ["silently", "softly", "noiselessly", "peacefully", "calmly", "hushedly"],
    hint: "Think of silent, noiseless movements.",
    explanation: "'Silently' or 'noiselessly' describes performing actions with no sound."
  },
  {
    plainText: "The driver configures the circuit quietly.",
    textToSpeak: "The driver configures the circuit *quietly*.",
    acceptedSynonyms: ["silently", "softly", "noiselessly", "peacefully", "calmly", "hushedly"],
    hint: "What describes a soft, noiseless ignition?",
    explanation: "'Softly' or 'noiselessly' are strong synonyms."
  },
  {
    plainText: "A chef configures the circuit quietly.",
    textToSpeak: "A chef configures the circuit *quietly*.",
    acceptedSynonyms: ["silently", "softly", "noiselessly", "peacefully", "calmly", "hushedly"],
    hint: "Think of silent and calm actions.",
    explanation: "'Silently' or 'hushedly' is suitable here."
  }
];

// Iterate through the quests and map the correct properties based on textToSpeak
data.quests.forEach((quest, index) => {
  const match = synonymMapping.find(m => m.plainText.trim().toLowerCase() === quest.textToSpeak.trim().toLowerCase() || m.plainText.trim().toLowerCase() === quest.correctAnswer.trim().toLowerCase());
  if (match) {
    quest.textToSpeak = match.textToSpeak;
    quest.acceptedSynonyms = match.acceptedSynonyms;
    quest.hint = match.hint;
    quest.explanation = match.explanation;
    // Set a dummy correctAnswer representing a valid synonym
    quest.correctAnswer = match.acceptedSynonyms[0];
  }
});

fs.writeFileSync(filePath, JSON.stringify(data, null, 4), 'utf8');
console.log("Successfully enhanced 30 Speak Synonym curriculum quests!");
