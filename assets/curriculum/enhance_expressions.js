const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'speaking', 'dailyExpression_1_10.json');

const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));

const expressionMapping = [
  {
    expression: "Bite the bullet",
    meaning: "To face a difficult situation with courage and force yourself to do something unpleasant.",
    sampleUsage: "I decided to bite the bullet and go to the dentist today.",
    hint: "Think of an idiom related to chewing a lead ammunition.",
    explanation: "'Bite the bullet' originates from military surgery before anesthesia."
  },
  {
    expression: "Break a leg",
    meaning: "A superstitious way to wish someone good luck, especially before a performance.",
    sampleUsage: "Go out there and break a leg tonight!",
    hint: "An theatrical way to wish someone good luck.",
    explanation: "'Break a leg' is a classic theatrical superstition wishing for a great show."
  },
  {
    expression: "Under the weather",
    meaning: "Feeling slightly sick, tired, or unwell.",
    sampleUsage: "I'm feeling a bit under the weather, so I might stay home.",
    hint: "Think of feeling sick under meteorological conditions.",
    explanation: "'Under the weather' dates back to maritime travel where sick sailors stayed below deck."
  },
  {
    expression: "Spill the beans",
    meaning: "To reveal secret information prematurely or unintentionally.",
    sampleUsage: "Don't spill the beans about the surprise party!",
    hint: "Think of releasing small legumes from a container.",
    explanation: "'Spill the beans' means to accidentally leak confidential info."
  },
  {
    expression: "Piece of cake",
    meaning: "Something that is very easy to do or accomplish.",
    sampleUsage: "Don't worry, this coding challenge is a piece of cake.",
    hint: "An idiom referring to a sweet slice of dessert.",
    explanation: "'Piece of cake' refers to tasks that require minimal effort."
  },
  {
    expression: "Cost an arm and a leg",
    meaning: "Something that is extremely expensive.",
    sampleUsage: "That new smart holographic interface costs an arm and a leg.",
    hint: "Think of paying with two major human limbs.",
    explanation: "'Cost an arm and a leg' denotes an extremely high monetary value."
  },
  {
    expression: "Once in a blue moon",
    meaning: "Something that happens very rarely or almost never.",
    sampleUsage: "He visits his home town only once in a blue moon.",
    hint: "A rare lunar occurrence.",
    explanation: "A 'blue moon' is a second full moon in a month, happening rarely."
  },
  {
    expression: "Burn the midnight oil",
    meaning: "To work or study late into the night.",
    sampleUsage: "I had to burn the midnight oil to prepare for the product launch.",
    hint: "Igniting illumination late at night.",
    explanation: "'Burn the midnight oil' means working late after standard hours."
  },
  {
    expression: "Let the cat out of the bag",
    meaning: "To accidentally reveal a secret.",
    sampleUsage: "She let the cat out of the bag about the promotion.",
    hint: "Allowing a feline to escape a sack.",
    explanation: "Releasing the cat out of the bag means exposing hidden secrets."
  },
  {
    expression: "Hit the nail on the head",
    meaning: "To describe exactly what is causing a situation or problem.",
    sampleUsage: "You hit the nail on the head when you identified the server leak.",
    hint: "Strikng a metallic fastener perfectly.",
    explanation: "'Hit the nail on the head' means pinpointing the absolute truth."
  },
  {
    expression: "Barking up the wrong tree",
    meaning: "Pursuing a mistaken line of thought or course of action.",
    sampleUsage: "If you think I took the blueprints, you're barking up the wrong tree.",
    hint: "An animal calling at the incorrect trunk.",
    explanation: "Originates from hunting dogs barking at trees when prey has already left."
  },
  {
    expression: "Beat around the bush",
    meaning: "To delay talking about the most important point of a subject.",
    sampleUsage: "Stop beating around the bush and tell me what went wrong.",
    hint: "Striking around a shrub instead of direct action.",
    explanation: "Avoids direct confrontation by speaking in circles."
  },
  {
    expression: "Cry over spilled milk",
    meaning: "To worry or complain about past mistakes that cannot be undone.",
    sampleUsage: "The system crashed, but crying over spilled milk won't fix it.",
    hint: "Weeping about a spilt dairy liquid.",
    explanation: "Lamenting past failures that are unalterable is unproductive."
  },
  {
    expression: "Cut corners",
    meaning: "To do something in the easiest, cheapest, or fastest way, often compromising quality.",
    sampleUsage: "Never cut corners when designing the security layers.",
    hint: "Taking direct straight shortcuts on borders.",
    explanation: "'Cut corners' indicates bypassing rules or safety measures."
  },
  {
    expression: "Devil's advocate",
    meaning: "To present an opposing view for the sake of exploring an argument.",
    sampleUsage: "Let me play devil's advocate and look at the risks.",
    hint: "An attorney representing the dark adversary.",
    explanation: "Argues the opposing side to robustly evaluate arguments."
  },
  {
    expression: "Blessing in disguise",
    meaning: "A misfortune that eventually results in a good outcome.",
    sampleUsage: "Losing my flight was a blessing in disguise because I met my co-founder.",
    hint: "A fortunate turn cloaked in bad luck.",
    explanation: "An initially adverse situation that brings positive developments later."
  },
  {
    expression: "The best of both worlds",
    meaning: "A situation in which you can enjoy the advantages of two very different things.",
    sampleUsage: "Living in the countryside and working remotely is the best of both worlds.",
    hint: "Enjoying positive traits from two planets.",
    explanation: "Refers to maximizing benefits from disparate circumstances."
  },
  {
    expression: "Don't put all your eggs in one basket",
    meaning: "Do not depend entirely on one venture or single path for success.",
    sampleUsage: "Invest in multiple startups, don't put all your eggs in one basket.",
    hint: "Carrying all fragile shells in a single carrier.",
    explanation: "Diversification avoids total loss if a single path fails."
  },
  {
    expression: "Add insult to injury",
    meaning: "To make a bad situation even worse with further hostile actions.",
    sampleUsage: "They lost the match, and to add insult to injury, it started to rain.",
    hint: "Verbal offense joined to physical harm.",
    explanation: "Aggravating an already bad circumstance with additional offenses."
  },
  {
    expression: "At the drop of a hat",
    meaning: "To do something immediately without any hesitation or delay.",
    sampleUsage: "He is ready to travel and explore new ruins at the drop of a hat.",
    hint: "Reacting when headwear falls.",
    explanation: "Performing tasks instantaneously without planning."
  },
  {
    expression: "Burn bridges",
    meaning: "To destroy professional relationships or connections permanently.",
    sampleUsage: "Even if you resign, do not burn bridges with the team.",
    hint: "Destroying crossings by fire.",
    explanation: "Eliminating retreat paths or ending key network connections."
  },
  {
    expression: "Call it a day",
    meaning: "To stop working on something for the rest of the day.",
    sampleUsage: "We've fixed the major bugs, let's call it a day.",
    hint: "Labeling a 24-hour period complete.",
    explanation: "Deciding to halt ongoing operations for the night."
  },
  {
    expression: "Get out of hand",
    meaning: "To become chaotic and out of control.",
    sampleUsage: "The discussions got out of hand during the emergency meeting.",
    hint: "Escaping the control of a hand.",
    explanation: "Refers to situations that escalate beyond regulation."
  },
  {
    expression: "Go the extra mile",
    meaning: "To make a special effort to achieve something or help others.",
    sampleUsage: "She always goes the extra mile to support her clients.",
    hint: "Walking one more unit of distance.",
    explanation: "Providing support beyond the minimum requirement."
  },
  {
    expression: "Hit the sack",
    meaning: "To go to bed in order to sleep.",
    sampleUsage: "I'm extremely exhausted, I think it's time to hit the sack.",
    hint: "Striking a large bag.",
    explanation: "Slang expression for going to bed for rest."
  },
  {
    expression: "Keep an eye on",
    meaning: "To watch or monitor something closely and carefully.",
    sampleUsage: "Please keep an eye on the database telemetry while I'm away.",
    hint: "Maintaining an ocular focus.",
    explanation: "Supervising or observing events closely."
  },
  {
    expression: "Lose your touch",
    meaning: "To lose an ability or talent that you once possessed.",
    sampleUsage: "The chef hasn't lost his touch; this meal is delicious.",
    hint: "Misplacing your tactile sense.",
    explanation: "Degradation of previously high-quality skills."
  },
  {
    expression: "On the ball",
    meaning: "To be quick to understand and react to things efficiently.",
    sampleUsage: "He is really on the ball and anticipated all the client's demands.",
    hint: "Balancing on a spherical object.",
    explanation: "Being alert, active, and fully competent."
  },
  {
    expression: "Rule of thumb",
    meaning: "A broad, general principle derived from practical experience.",
    sampleUsage: "As a rule of thumb, always backup your source files weekly.",
    hint: "A guideline based on the first digit.",
    explanation: "A practical guide that is not mathematically exact."
  },
  {
    expression: "Through thick and thin",
    meaning: "Supporting or staying with someone through all kinds of difficult times.",
    sampleUsage: "They have been best friends through thick and thin since childhood.",
    hint: "Navigating deep and sparse areas.",
    explanation: "Unconditional loyalty under pleasant and adverse conditions."
  }
];

// Iterate through the quests and map the correct properties
data.quests.forEach((quest, index) => {
  const match = expressionMapping[index % expressionMapping.length];
  if (match) {
    quest.expression = match.expression;
    quest.textToSpeak = match.expression; // The user will speak the expression to reveal!
    quest.meaning = match.meaning;
    quest.sampleUsage = match.sampleUsage;
    quest.hint = match.hint;
    quest.explanation = match.explanation;
    quest.correctAnswer = match.expression;
  }
});

fs.writeFileSync(filePath, JSON.stringify(data, null, 4), 'utf8');
console.log("Successfully enhanced 30 Daily Expression curriculum quests!");
