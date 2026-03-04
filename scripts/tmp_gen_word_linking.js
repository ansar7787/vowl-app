
const fs = require('fs');

const verbs = [
  "Pick", "Hold", "Keep", "Take", "Wake", "Look", "Turn", "Come", "Check", "Find",
  "Log", "Pass", "Put", "Sit", "Stand", "Think", "Write", "Read", "Call", "Clean",
  "Dream", "Feed", "Get", "Hand", "Jump", "Kick", "Live", "Move", "Note", "Pull",
  "Push", "Run", "Stay", "Step", "Wait", "Walk", "Wash", "Watch", "Work", "Ask",
  "Bring", "Buy", "Catch", "Cut", "Drink", "Eat", "Fall", "Give", "Grow", "Help",
  "Know", "Leave", "Let", "Make", "Pay", "Play", "Say", "See", "Send", "Set", 
  "Show", "Start", "Tell", "Try", "Use"
];

const particles = [
  "it", "on", "up", "at", "in", "off", "out", "about", "around", "away", "over",
  "under", "across", "along", "back", "down", "forward", "through"
];

const pool = [];
const seen = new Set();

const addQuest = (p, options, ci, h) => {
  if (seen.has(p)) return;
  seen.add(p);
  pool.push({
    instruction: "Identify the linked sounds.",
    word: p,
    options,
    correctAnswerIndex: ci,
    hint: h
  });
};

// 1. Manual Golden Examples
addQuest("Did you eat", ["Did | you", "Didju", "Did | ju"], 1, "d + y becomes /dʒ/.");
addQuest("Want to go", ["Want | to", "Wanna", "Wan | to"], 1, "Want to becomes 'Wanna'.");
addQuest("Pick it up", ["Pick | it", "Pickit", "Pick | it | up"], 1, "K connects to vowel.");
addQuest("Turn off the light", ["Turn | off", "Tur | noff", "Turnoff"], 2, "n links to vowel.");
addQuest("Going to stay", ["Going | to", "Gonna", "Go | to"], 1, "Going to becomes 'Gonna'.");
addQuest("Got to go", ["Got | to", "Gotta", "Got | go"], 1, "Got to becomes 'Gotta'.");
addQuest("Let you know", ["Let | you", "Letchu", "Let | ju"], 1, "t + y becomes /tʃ/.");

// 2. CV Linking (Consonant + Vowel)
for (const v of verbs) {
  for (const p of particles) {
    if (pool.length >= 600) break;
    const phrase = `${v} ${p}`;
    const lastChar = v.slice(-1).toLowerCase();
    const firstChar = p[0].toLowerCase();
    
    if ("aeiou".indexOf(firstChar) !== -1 && "aeiou".indexOf(lastChar) === -1) {
      addQuest(
        phrase,
        [`${v} | ${p}`, `${v}${p}`.toLowerCase(), `${v} ${p[0]} | ${p.slice(1)}`],
        1,
        `${lastChar.toUpperCase()} connects to vowel.`
      );
    }
  }
}

// 3. VV Linking (Vowel + Vowel)
const vvVerbs = ["Go", "Do", "See", "He", "She", "You", "Two", "Three", "Me", "We"];
const vvStarts = ["away", "in", "on", "around", "up", "out", "always", "often", "even", "under"];

for (const v of vvVerbs) {
  for (const s of vvStarts) {
    if (pool.length >= 600) break;
    const phrase = `${v} ${s}`;
    const lastVowel = v.slice(-1).toLowerCase();
    let intrusive = "";
    if ("ou".indexOf(lastVowel) !== -1) intrusive = "w";
    else if ("ei".indexOf(lastVowel) !== -1) intrusive = "y";
    
    if (intrusive) {
      addQuest(
        phrase,
        [`${v} | ${s}`, `${v}-${intrusive}${s}`, `${v} | ${intrusive}${s}`],
        1,
        `Intrusive /${intrusive}/ sound connects vowels.`
      );
    }
  }
}

// 4. Assimilation
const assimVerbs = ["Could", "Would", "Should", "Don't", "Can't", "Won't", "Meet", "Hate", "Beat"];
const assimFollow = ["you", "your", "yours"];

for (const v of assimVerbs) {
  for (const f of assimFollow) {
    const phrase = `${v} ${f}`;
    const lastChar = v.slice(-1).toLowerCase();
    const result = (lastChar === 'd') ? "ju" : "chu";
    const phonetic = (lastChar === 'd') ? "/dʒ/" : "/tʃ/";
    
    addQuest(
      phrase,
      [`${v} | ${f}`, `${v.slice(0,-1)}${result}`, `${v} | ${result}`],
      1,
      `${lastChar} + y becomes ${phonetic}.`
    );
  }
}

// 5. Gemination
const gemStarts = ["Red", "Big", "Good", "Bad", "Hot", "Top", "Small", "Tall", "Ten"];
const gemNouns = ["door", "garden", "day", "dog", "tea", "table", "lamp", "lane", "night"];

for (const s of gemStarts) {
  for (const n of gemNouns) {
    if (s.slice(-1).toLowerCase() === n[0].toLowerCase()) {
      const phrase = `${s} ${n}`;
      addQuest(
        phrase,
        [`${s} | ${n}`, `${s.toLowerCase()}${n.toLowerCase()}`, `${s} | ${n[0]} | ${n.slice(1)}`],
        1,
        "Consonants merge into one long sound."
      );
    }
  }
}

// Extra Phrases
const extraPhrases = [
  "Not at all", "I have it", "Get it out", "Stand in line", "Stop it", "Keep it up",
  "Think of it", "Most of all", "Fill it up", "Wait a minute", "Shut up", "Fix it",
  "Mix it up", "Bless you", "Miss you", "Guess what", "Nice to meet you",
  "Take an apple", "Pick a card", "Hold a pen", "Keep an eye", "Look at him",
  "Turn an egg", "Come at home", "Check an email", "Find an exit", "Pass an exam"
];

for (const p of extraPhrases) {
  addQuest(p, [p.replace(" ", " | "), p.replace(" ", "").toLowerCase(), p], 1, "Linking words for natural flow.");
}

// Verify count
if (pool.length < 600) {
  console.error(`Only generated ${pool.length} items.`);
}

fs.writeFileSync('/tmp/word_linking_pool.json', JSON.stringify(pool.slice(0, 600), null, 2));
console.log(`Successfully generated ${pool.length} word linking templates.`);
