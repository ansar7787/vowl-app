/**
 * Accent Content Pools for VoxAI Quest
 * 12 Modules × High Quality Scenarios
 */

const C = (inst, fields, it) => ({ instruction: inst, interactionType: it || 'choice', fields });

const consonantClarity = [
  C("Is 'th' voiced or unvoiced?", { word: "THINK", options: ["Voiced", "Unvoiced"], correctAnswerIndex: 1, hint: "No throat vibration." }),
  C("Is 'th' voiced or unvoiced?", { word: "THIS", options: ["Voiced", "Unvoiced"], correctAnswerIndex: 0, hint: "Throat vibrates." }),
  C("Which consonant sound?", { word: "SHIP", options: ["/ʃ/ (sh)", "/s/ (s)"], correctAnswerIndex: 0, hint: "Wider mouth." }),
  C("Which consonant is silent?", { word: "KNIGHT", options: ["K", "N"], correctAnswerIndex: 0, hint: "The K is not pronounced." }),
  C("Which consonant is silent?", { word: "SUBTLE", options: ["B", "T"], correctAnswerIndex: 0, hint: "B is silent." }),
  C("Which consonant sound?", { word: "VISION", options: ["/ʒ/ (zh)", "/dʒ/ (j)"], correctAnswerIndex: 0, hint: "No stop, continuous sound." }),
  C("Identify the final sound.", { word: "WATCHED", options: ["/t/", "/d/", "/ɪd/"], correctAnswerIndex: 0, hint: "Voiceless /tʃ/ leads to voiceless /t/." }),
  C("Identify the final sound.", { word: "PLAYED", options: ["/d/", "/t/", "/ɪd/"], correctAnswerIndex: 0, hint: "Voiced /eɪ/ leads to voiced /d/." }),
  C("Identify the final sound.", { word: "WANTED", options: ["/ɪd/", "/t/", "/d/"], correctAnswerIndex: 0, hint: "Ends in /t/, needs extra syllable." }),
  C("Which cluster is hardest?", { word: "STRENGTHS", options: ["/ŋθs/", "/ŋs/"], correctAnswerIndex: 0, hint: "Three consonants at the end." })
];

const minimalPairs = [
  C("Choose the word you hear.", { word1: "ship", word2: "sheep", question: "Which word has the /ɪ/ sound?", options: ["ship", "sheep"], correctAnswerIndex: 0, hint: "Short vowel." }),
  C("Choose the word you hear.", { word1: "bit", word2: "beat", question: "Which word has the /ɪ/ sound?", options: ["bit", "beat"], correctAnswerIndex: 0, hint: "Short vowel." }),
  C("Choose the word you hear.", { word1: "fan", word2: "van", question: "Which word starts with /f/?", options: ["fan", "van"], correctAnswerIndex: 0, hint: "Voiceless." }),
  C("Choose the word you hear.", { word1: "light", word2: "right", question: "Which word starts with /l/?", options: ["light", "right"], correctAnswerIndex: 0, hint: "Lateral sound." }),
  C("Choose the word you hear.", { word1: "rice", word2: "lice", question: "Which starts with /r/?", options: ["rice", "lice"], correctAnswerIndex: 0, hint: "Retroflex sound." }),
  C("Choose the word you hear.", { word1: "wet", word2: "vet", question: "Which starts with /w/?", options: ["wet", "vet"], correctAnswerIndex: 0, hint: "Rounded lips." }),
  C("Choose the word you hear.", { word1: "coat", word2: "goat", question: "Which starts voiceless?", options: ["coat", "goat"], correctAnswerIndex: 0, hint: "/k/ is voiceless." }),
  C("Choose the word you hear.", { word1: "sue", word2: "zoo", question: "Which starts voiceless?", options: ["sue", "zoo"], correctAnswerIndex: 0, hint: "/s/ is voiceless." }),
  C("Choose the word you hear.", { word1: "pat", word2: "bat", question: "Which starts voiceless?", options: ["pat", "bat"], correctAnswerIndex: 0, hint: "/p/ is voiceless." }),
  C("Choose the word you hear.", { word1: "chin", word2: "shin", question: "Which starts with /tʃ/?", options: ["chin", "shin"], correctAnswerIndex: 0, hint: "Affricate stop." })
];

const syllableStress = [
  C("Where is the stress?", { word: "HOTEL", options: ["ho-TEL", "HO-tel"], correctAnswerIndex: 0, hint: "Stress on second syllable." }),
  C("Where is the stress?", { word: "BANANA", options: ["ba-NA-na", "BA-na-na"], correctAnswerIndex: 0, hint: "Middle syllable." }),
  C("Where is the stress?", { word: "EDUCATION", options: ["ed-u-CA-tion", "ED-u-ca-tion"], correctAnswerIndex: 0, hint: "Third syllable." }),
  C("Where is the stress?", { word: "PHOTOGRAPH", options: ["PHO-to-graph", "pho-TO-graph"], correctAnswerIndex: 0, hint: "First syllable." }),
  C("Where is the stress?", { word: "PHOTOGRAPHY", options: ["pho-TOG-ra-phy", "PHO-tog-ra-phy"], correctAnswerIndex: 0, hint: "Second syllable." }),
  C("Where is the stress?", { word: "RECORD (Noun)", options: ["RE-cord", "re-CORD"], correctAnswerIndex: 0, hint: "Nouns often have first-syllable stress." }),
  C("Where is the stress?", { word: "RECORD (Verb)", options: ["re-CORD", "RE-cord"], correctAnswerIndex: 0, hint: "Verbs often have second-syllable stress." }),
  C("Where is the stress?", { word: "PRESENT (Noun)", options: ["PRE-sent", "pre-SENT"], correctAnswerIndex: 0, hint: "First syllable for noun." }),
  C("Where is the stress?", { word: "PRESENT (Verb)", options: ["pre-SENT", "PRE-sent"], correctAnswerIndex: 0, hint: "Second syllable for verb." }),
  C("Where is the stress?", { word: "OBJECT (Verb)", options: ["ob-JECT", "OB-ject"], correctAnswerIndex: 0, hint: "Second syllable." })
];

const dialectDrill = [
  C("Identify the Rhotic 'R'.", { sentence: "THE CAR IS FAR.", options: ["Pronounced (American)", "Silent (British RP)"], correctAnswerIndex: 0, hint: "Rhotic dialects pronounce the final 'R'." }),
  C("Identify the Glottal Stop.", { sentence: "BOTTLE OF WATER.", options: ["Bo'ul (Estuary/Cockney)", "Bottle (Standard)"], correctAnswerIndex: 0, hint: "Replacing /t/ with a glottal stop." }),
  C("Identify the 'Flat A'.", { sentence: "I CAN'T DANCE.", options: ["/æ/ (Northern/US)", "/ɑː/ (Southern UK)"], correctAnswerIndex: 0, hint: "Short 'a' vs long 'ah'." }),
  C("Identify 'Yod-Dropping'.", { sentence: "NEW TUESDAY.", options: ["Noo (US)", "Nyew (UK)"], correctAnswerIndex: 0, hint: "Dropping the /j/ sound." }),
  C("Identify 'H-Dropping'.", { sentence: "HAPPY HOLIDAY.", options: ["'appy 'oliday", "Happy Holiday"], correctAnswerIndex: 0, hint: "Dropping the initial /h/." })
];

const intonationMimic = [
  C("Mimic the rising intonation.", { question: "Are you coming?", prompt: "Is your pitch going UP at the end?", options: ["Yes (Rising)", "No (Falling)"], correctAnswerIndex: 0 }, "speaking"),
  C("Mimic the falling intonation.", { statement: "I am going home.", prompt: "Is your pitch going DOWN at the end?", options: ["Yes (Falling)", "No (Rising)"], correctAnswerIndex: 0 }, "speaking"),
  C("Mimic the surprise intonation.", { exclamation: "Really?!", prompt: "Use a high jump in pitch.", options: ["Success", "Failure"], correctAnswerIndex: 0 }, "speaking")
];

const pitchPatternMatch = [
  C("Match the pitch of a list.", { sentence: "Apples, oranges, and pears.", options: ["Rise-Rise-Fall", "Fall-Fall-Rise"], correctAnswerIndex: 0, hint: "Rising on items, falling on the last." }),
  C("Match the pitch of a tag question.", { sentence: "It's cold, isn't it?", options: ["Falling (Seeking agreement)", "Rising (Real question)"], correctAnswerIndex: 0, hint: "Falling tag implies agreement." })
];

const shadowingChallenge = [
  C("Shadow the stress rhythm.", { sentence: "I'd LOVE to go to the PARK today.", stressPattern: "DA-da-da-da-da-DA-da", hint: "Focus on content words." }, "speaking"),
  C("Shadow the rapid link.", { sentence: "Pick it up and put it away.", stressPattern: "Pi-ki-tu-pan-pu-ti-ta-way", hint: "Link final consonants to vowels." }, "speaking")
];

const speedVariance = [
  C("Identify the compression.", { sentence: "I am going to -> I'm gonna", options: ["Compressed (Fast)", "Full (Slow)"], correctAnswerIndex: 0, hint: "Informal contractions increase speed." }),
  C("Identify the emphasis slowing.", { sentence: "I said STOP.", options: ["Slower (Emphasis)", "Faster"], correctAnswerIndex: 0, hint: "Important words are stretched." })
];

const wordLinking = [
  C("Identify Catenation (Consonant to Vowel).", { phrase: "An apple", options: ["A-napple", "An | apple"], correctAnswerIndex: 0, hint: "The /n/ moves to the next word." }),
  C("Identify Intrusion (Vowel to Vowel).", { phrase: "Go away", options: ["Go-w-away", "Go | away"], correctAnswerIndex: 0, hint: "A 'w' sound is inserted to bridge vowels." }),
  C("Identify Elision (Deletion).", { phrase: "Next door", options: ["Nex-door", "Next-door"], correctAnswerIndex: 0, hint: "The /t/ is often dropped between consonants." })
];

const vowelDistinction = [
  C("Distinguish /æ/ vs /ʌ/.", { word1: "Cap", word2: "Cup", options: ["Cap (/æ/)", "Cup (/ʌ/)"], correctAnswerIndex: 0, hint: "Cap is wider." }),
  C("Distinguish /ʊ/ vs /uː/.", { word1: "Pull", word2: "Pool", options: ["Pull (/ʊ/)", "Pool (/uː/)"], correctAnswerIndex: 0, hint: "Pool is long." })
];

const pitchModulation = [
  C("Identify the stress shift.", { sentence: "I didn't say SHE stole it.", meaning: ["Someone else said it", "Someone else stole it"], correctAnswerIndex: 1, hint: "Stressing 'SHE' contrasts her with someone else." }),
  C("Identify the stress shift.", { sentence: "I DIDN'T say she stole it.", meaning: ["Denial of saying it", "She stole it"], correctAnswerIndex: 0, hint: "Stressing 'DIDN'T' emphasizes the denial." })
];

const connectedSpeech = [
  C("Identify Assimilation.", { phrase: "Good boy", options: ["Goob-boy", "Good-boy"], correctAnswerIndex: 0, hint: "The /d/ changes to /b/ to match 'boy'." }),
  C("Identify Gemination.", { phrase: "Social life", options: ["Socia-life (single L)", "Social-life (double L)"], correctAnswerIndex: 1, hint: "Double length 'L' when two 'L's meet." })
];

module.exports = {
  consonantClarity,
  minimalPairs,
  syllableStress,
  dialectDrill,
  intonationMimic,
  pitchPatternMatch,
  shadowingChallenge,
  speedVariance,
  wordLinking,
  vowelDistinction,
  pitchModulation,
  connectedSpeech
};
