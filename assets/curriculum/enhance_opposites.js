const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'speaking', 'speakOpposite_1_10.json');

const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));

const oppositeMapping = [
  {
    plainText: "A student protects the shield gently.",
    textToSpeak: "A student *protects* the shield gently.",
    acceptedOpposites: ["attacks", "destroys", "damages", "endangers", "harms", "threatens"],
    hint: "Think of an action that causes damage or harm.",
    explanation: "'Attacks' or 'destroys' functions as the polar opposite of 'protects'."
  },
  {
    plainText: "The analyst protects the shield gently.",
    textToSpeak: "The analyst *protects* the shield gently.",
    acceptedOpposites: ["attacks", "destroys", "damages", "endangers", "harms", "threatens"],
    hint: "What describes causing damage or threatening?",
    explanation: "'Damages' or 'harms' is the perfect antonym for protects."
  },
  {
    plainText: "A manager protects the shield gently.",
    textToSpeak: "A manager *protects* the shield gently.",
    acceptedOpposites: ["attacks", "destroys", "damages", "endangers", "harms", "threatens"],
    hint: "What is the opposite of safeguarding?",
    explanation: "'Endangers' or 'threatens' can cleanly replace protects as an opposite."
  },
  {
    plainText: "The driver assembles the database silently.",
    textToSpeak: "The driver assembles the database *silently*.",
    acceptedOpposites: ["loudly", "noisily", "boisterously", "audibly", "clamorously"],
    hint: "Think of making a lot of sound.",
    explanation: "'Loudly' or 'noisily' represents the opposite sound condition of 'silently'."
  },
  {
    plainText: "A chef assembles the database silently.",
    textToSpeak: "A chef assembles the database *silently*.",
    acceptedOpposites: ["loudly", "noisily", "boisterously", "audibly", "clamorously"],
    hint: "Think of a noisy or boisterous assembly.",
    explanation: "'Noisily' or 'loudly' indicates a high-sound output."
  },
  {
    plainText: "The engineer launches the database silently.",
    textToSpeak: "The engineer launches the database *silently*.",
    acceptedOpposites: ["loudly", "noisily", "boisterously", "audibly", "clamorously"],
    hint: "Think of an audible or loud deployment.",
    explanation: "'Audibly' or 'loudly' represents the polar opposite of silent."
  },
  {
    plainText: "A manager observes the module cautiously.",
    textToSpeak: "A manager observes the module *cautiously*.",
    acceptedOpposites: ["recklessly", "carelessly", "boldly", "rashly", "foolishly"],
    hint: "Think of acting without any care or regard for safety.",
    explanation: "'Recklessly' or 'carelessly' is the antonym of cautious observation."
  },
  {
    plainText: "The hero observes the module cautiously.",
    textToSpeak: "The hero observes the module *cautiously*.",
    acceptedOpposites: ["recklessly", "carelessly", "boldly", "rashly", "foolishly"],
    hint: "What describes a reckless or rash check?",
    explanation: "'Rashly' or 'carelessly' represents the direct opposite of cautiously."
  },
  {
    plainText: "A robot observes the module cautiously.",
    textToSpeak: "A robot observes the module *cautiously*.",
    acceptedOpposites: ["recklessly", "carelessly", "boldly", "rashly", "foolishly"],
    hint: "Think of a careless or bold observation.",
    explanation: "'Carelessly' or 'boldly' is a contextually strong opposite."
  },
  {
    plainText: "The engineer assembles a laser steadily.",
    textToSpeak: "The engineer assembles a laser *steadily*.",
    acceptedOpposites: ["shakily", "unsteadily", "erratically", "unreliably", "wobblily"],
    hint: "Think of a shaky, erratic, or unsteady motion.",
    explanation: "'Shakily' or 'unsteadily' represents a direct polar opposite of steadily."
  },
  {
    plainText: "A scientist assembles a laser steadily.",
    textToSpeak: "A scientist assembles a laser *steadily*.",
    acceptedOpposites: ["shakily", "unsteadily", "erratically", "unreliably", "wobblily"],
    hint: "What describes unreliable or erratic calibration?",
    explanation: "'Erratic' or 'unsteadily' represents unstable motion."
  },
  {
    plainText: "The commander assembles a laser steadily.",
    textToSpeak: "The commander assembles a laser *steadily*.",
    acceptedOpposites: ["shakily", "unsteadily", "erratically", "unreliably", "wobblily"],
    hint: "Think of shaky or wobbly engineering.",
    explanation: "'Shakily' or 'wobblily' are perfect antonyms."
  },
  {
    plainText: "A robot activates a machine swiftly.",
    textToSpeak: "A robot activates a machine *swiftly*.",
    acceptedOpposites: ["slowly", "sluggishly", "gradually", "leisurely", "tardily"],
    hint: "Think of a slow or sluggish response speed.",
    explanation: "'Slowly' or 'sluggishly' represents the polar opposite of swiftly."
  },
  {
    plainText: "The traveler activates a machine swiftly.",
    textToSpeak: "The traveler activates a machine *swiftly*.",
    acceptedOpposites: ["slowly", "sluggishly", "gradually", "leisurely", "tardily"],
    hint: "What describes a slow, gradual activation?",
    explanation: "'Gradually' or 'slowly' fits contextually."
  },
  {
    plainText: "A doctor activates a machine swiftly.",
    textToSpeak: "A doctor activates a machine *swiftly*.",
    acceptedOpposites: ["slowly", "sluggishly", "gradually", "leisurely", "tardily"],
    hint: "Think of a sluggish or delayed operation.",
    explanation: "'Sluggishly' or 'slowly' fits cleanly."
  },
  {
    plainText: "The commander upgrades the archive wisely.",
    textToSpeak: "The commander upgrades the archive *wisely*.",
    acceptedOpposites: ["foolishly", "unwisely", "stupidly", "recklessly", "senselessly"],
    hint: "Think of acting foolishly or stupidly.",
    explanation: "'Foolishly' or 'unwisely' is the direct antonym of wisely."
  },
  {
    plainText: "A pilot upgrades the archive wisely.",
    textToSpeak: "A pilot upgrades the archive *wisely*.",
    acceptedOpposites: ["foolishly", "unwisely", "stupidly", "recklessly", "senselessly"],
    hint: "What describes a reckless or foolish decision?",
    explanation: "'Recklessly' or 'unwisely' matches perfectly."
  },
  {
    plainText: "The technician upgrades the archive wisely.",
    textToSpeak: "The technician upgrades the archive *wisely*.",
    acceptedOpposites: ["foolishly", "unwisely", "stupidly", "recklessly", "senselessly"],
    hint: "Think of a senseless upgrade.",
    explanation: "'Senselessly' or 'foolishly' are great contextual choices."
  },
  {
    plainText: "A doctor creates the data efficiently.",
    textToSpeak: "A doctor creates the data *efficiently*.",
    acceptedOpposites: ["inefficiently", "wastefully", "clumsily", "unproductively", "carelessly"],
    hint: "Think of working wastefully or clumsily.",
    explanation: "'Inefficiently' or 'wastefully' stands as the opposite of efficiently."
  },
  {
    plainText: "The teacher creates the data efficiently.",
    textToSpeak: "The teacher creates the data *efficiently*.",
    acceptedOpposites: ["inefficiently", "wastefully", "clumsily", "unproductively", "carelessly"],
    hint: "What describes unproductive or clumsy work?",
    explanation: "'Clumsily' or 'inefficiently' represents the polar opposite."
  },
  {
    plainText: "A researcher creates the data efficiently.",
    textToSpeak: "A researcher creates the data *efficiently*.",
    acceptedOpposites: ["inefficiently", "wastefully", "clumsily", "unproductively", "carelessly"],
    hint: "Think of wasteful or unproductive creation.",
    explanation: "'Wastefully' or 'unproductively' are excellent antonyms."
  },
  {
    plainText: "The technician evaluates a satellite immediately.",
    textToSpeak: "The technician evaluates a satellite *immediately*.",
    acceptedOpposites: ["eventually", "later", "gradually", "delayed", "slowly", "afterwards"],
    hint: "Think of delaying something to a later time.",
    explanation: "'Eventually' or 'later' stands as the polar opposite of immediately."
  },
  {
    plainText: "An explorer evaluates a satellite immediately.",
    textToSpeak: "An explorer evaluates a satellite *immediately*.",
    acceptedOpposites: ["eventually", "later", "gradually", "delayed", "slowly", "afterwards"],
    hint: "What describes a delayed or slow evaluation?",
    explanation: "'Delayed' or 'gradually' represents a direct antonym."
  },
  {
    plainText: "The droid evaluates a satellite immediately.",
    textToSpeak: "The droid evaluates a satellite *immediately*.",
    acceptedOpposites: ["eventually", "later", "gradually", "delayed", "slowly", "afterwards"],
    hint: "Think of checking something later.",
    explanation: "'Later' or 'eventually' fits perfectly."
  },
  {
    plainText: "A researcher analyzes a spaceship rapidly.",
    textToSpeak: "A researcher analyzes a spaceship *rapidly*.",
    acceptedOpposites: ["slowly", "sluggishly", "gradually", "leisurely", "tardily"],
    hint: "Think of sluggish or slow movement.",
    explanation: "'Slowly' or 'sluggishly' is the direct polar opposite of rapidly."
  },
  {
    plainText: "The detective analyzes a spaceship rapidly.",
    textToSpeak: "The detective analyzes a spaceship *rapidly*.",
    acceptedOpposites: ["slowly", "sluggishly", "gradually", "leisurely", "tardily"],
    hint: "What describes gradual or leisurely pacing?",
    explanation: "'Gradually' or 'leisurely' is the direct antonym."
  },
  {
    plainText: "A spy analyzes a spaceship rapidly.",
    textToSpeak: "A spy analyzes a spaceship *rapidly*.",
    acceptedOpposites: ["slowly", "sluggishly", "gradually", "leisurely", "tardily"],
    hint: "Think of a slow, sluggish analysis.",
    explanation: "'Sluggishly' or 'slowly' represents a perfect opposite."
  },
  {
    plainText: "A doctor evaluates a machine cautiously.",
    textToSpeak: "A doctor evaluates a machine *cautiously*.",
    acceptedOpposites: ["recklessly", "carelessly", "boldly", "rashly", "foolishly"],
    hint: "Think of acting recklessly or carelessly.",
    explanation: "'Recklessly' or 'carelessly' is the direct polar opposite of cautiously."
  },
  {
    plainText: "The traveler evaluates a machine cautiously.",
    textToSpeak: "The traveler evaluates a machine *cautiously*.",
    acceptedOpposites: ["recklessly", "carelessly", "boldly", "rashly", "foolishly"],
    hint: "What describes a reckless or rash check?",
    explanation: "'Rashly' or 'carelessly' fits perfectly as an opposite."
  },
  {
    plainText: "A robot evaluates a machine cautiously.",
    textToSpeak: "A robot evaluates a machine *cautiously*.",
    acceptedOpposites: ["recklessly", "carelessly", "boldly", "rashly", "foolishly"],
    hint: "Think of a careless, bold, or rash evaluation.",
    explanation: "'Carelessly' or 'boldly' is a contextually strong antonym."
  }
];

// Iterate through the quests and map the correct properties based on textToSpeak
data.quests.forEach((quest, index) => {
  const match = oppositeMapping.find(m => m.plainText.trim().toLowerCase() === quest.textToSpeak.trim().toLowerCase() || m.plainText.trim().toLowerCase() === quest.correctAnswer.trim().toLowerCase());
  if (match) {
    quest.textToSpeak = match.textToSpeak;
    // Map acceptedSynonyms array to store accepted opposites (SpeakingQuest has acceptedSynonyms field)
    quest.acceptedSynonyms = match.acceptedOpposites;
    quest.hint = match.hint;
    quest.explanation = match.explanation;
    quest.correctAnswer = match.acceptedOpposites[0];
  }
});

fs.writeFileSync(filePath, JSON.stringify(data, null, 4), 'utf8');
console.log("Successfully enhanced 30 Speak Opposite curriculum quests!");
