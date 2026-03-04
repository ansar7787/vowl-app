// Accent category pools - 10 games × 30 templates
const { generateUniqueShadowingQuestions } = require('./shadowing_data_gen.js');

const C = (inst,fields,it) => ({instruction:inst,interactionType:it||'choice',fields});

const consonantClarity = [
  C("Is 'th' voiced or unvoiced?",{word:"THINK",options:["Voiced","Unvoiced"],correctAnswerIndex:1,hint:"No throat vibration."}),
  C("Is 'th' voiced or unvoiced?",{word:"THIS",options:["Voiced","Unvoiced"],correctAnswerIndex:0,hint:"Throat vibrates."}),
  C("Is 'th' voiced or unvoiced?",{word:"THREE",options:["Voiced","Unvoiced"],correctAnswerIndex:1,hint:"No vibration."}),
  C("Is 'th' voiced or unvoiced?",{word:"THAT",options:["Voiced","Unvoiced"],correctAnswerIndex:0,hint:"Vibrates."}),
  C("Is 'th' voiced or unvoiced?",{word:"THROUGH",options:["Voiced","Unvoiced"],correctAnswerIndex:1,hint:"No vibration."}),
  C("Is 'th' voiced or unvoiced?",{word:"THEM",options:["Voiced","Unvoiced"],correctAnswerIndex:0,hint:"Throat vibrates."}),
  C("Is 'th' voiced or unvoiced?",{word:"THROW",options:["Voiced","Unvoiced"],correctAnswerIndex:1,hint:"No vibration."}),
  C("Is 'th' voiced or unvoiced?",{word:"THEN",options:["Voiced","Unvoiced"],correctAnswerIndex:0,hint:"Vibrates."}),
  C("Is 'th' voiced or unvoiced?",{word:"THANK",options:["Voiced","Unvoiced"],correctAnswerIndex:1,hint:"No vibration."}),
  C("Is 'th' voiced or unvoiced?",{word:"THOSE",options:["Voiced","Unvoiced"],correctAnswerIndex:0,hint:"Vibrates."}),
  C("Which consonant sound?",{word:"SHIP",options:["/ʃ/ (sh)","/s/ (s)"],correctAnswerIndex:0,hint:"Wider mouth."}),
  C("Which consonant sound?",{word:"CHIP",options:["/tʃ/ (ch)","/ʃ/ (sh)"],correctAnswerIndex:0,hint:"Starts with a stop."}),
  C("Which consonant sound?",{word:"JOB",options:["/dʒ/ (j)","/ʒ/ (zh)"],correctAnswerIndex:0,hint:"Voiced with a stop."}),
  C("Which consonant sound?",{word:"VISION",options:["/ʒ/ (zh)","/dʒ/ (j)"],correctAnswerIndex:0,hint:"No stop, continuous sound."}),
  C("Which consonant sound?",{word:"RING",options:["/ŋ/ (ng)","/n/ (n)"],correctAnswerIndex:0,hint:"Nasal at back of mouth."}),
  C("Which consonant cluster?",{word:"STRENGTH",options:["str-","st-"],correctAnswerIndex:0,hint:"Three consonants at start."}),
  C("Which consonant cluster?",{word:"SPLASH",options:["spl-","sp-"],correctAnswerIndex:0,hint:"Three consonants."}),
  C("Which consonant cluster?",{word:"SCRIPT",options:["scr-","sc-"],correctAnswerIndex:0,hint:"Three consonants."}),
  C("Which consonant is silent?",{word:"KNIGHT",options:["K","N"],correctAnswerIndex:0,hint:"The K is not pronounced."}),
  C("Which consonant is silent?",{word:"WRITE",options:["W","R"],correctAnswerIndex:0,hint:"W is silent before R."}),
  C("Which consonant is silent?",{word:"LISTEN",options:["T","L"],correctAnswerIndex:0,hint:"The T is silent."}),
  C("Which consonant is silent?",{word:"CASTLE",options:["T","C"],correctAnswerIndex:0,hint:"T is silent."}),
  C("Which consonant is silent?",{word:"COMB",options:["B","C"],correctAnswerIndex:0,hint:"B is silent at end."}),
  C("Which consonant is silent?",{word:"DOUBT",options:["B","D"],correctAnswerIndex:0,hint:"B is silent."}),
  C("Which consonant is silent?",{word:"PSALM",options:["P","S"],correctAnswerIndex:0,hint:"P is silent."}),
  C("Which consonant is silent?",{word:"GNAW",options:["G","N"],correctAnswerIndex:0,hint:"G is silent before N."}),
  C("Which consonant is silent?",{word:"HOUR",options:["H","R"],correctAnswerIndex:0,hint:"H is silent."}),
  C("Which consonant is silent?",{word:"WRAP",options:["W","R"],correctAnswerIndex:0,hint:"W is silent."}),
  C("Which consonant is silent?",{word:"ISLAND",options:["S","L"],correctAnswerIndex:0,hint:"S is silent."}),
  C("Which consonant is silent?",{word:"SUBTLE",options:["B","T"],correctAnswerIndex:0,hint:"B is silent."}),
];

const minimalPairs = [
  C("Choose the word you hear.",{word1:"ship",word2:"sheep",question:"Which word has the /ɪ/ sound?",options:["ship","sheep"],correctAnswerIndex:0,hint:"Short vowel."}),
  C("Choose the word you hear.",{word1:"bit",word2:"beat",question:"Which word has the /ɪ/ sound?",options:["bit","beat"],correctAnswerIndex:0,hint:"Short vowel."}),
  C("Choose the word you hear.",{word1:"pen",word2:"pan",question:"Which word has the /e/ sound?",options:["pen","pan"],correctAnswerIndex:0,hint:"Front vowel."}),
  C("Choose the word you hear.",{word1:"cat",word2:"cut",question:"Which word has the /æ/ sound?",options:["cat","cut"],correctAnswerIndex:0,hint:"Front open vowel."}),
  C("Choose the word you hear.",{word1:"fan",word2:"van",question:"Which word starts with /f/?",options:["fan","van"],correctAnswerIndex:0,hint:"Voiceless."}),
  C("Choose the word you hear.",{word1:"thin",word2:"tin",question:"Which word has the /θ/ sound?",options:["thin","tin"],correctAnswerIndex:0,hint:"Tongue between teeth."}),
  C("Choose the word you hear.",{word1:"light",word2:"right",question:"Which word starts with /l/?",options:["light","right"],correctAnswerIndex:0,hint:"Lateral sound."}),
  C("Choose the word you hear.",{word1:"three",word2:"tree",question:"Which has the /θ/ sound?",options:["three","tree"],correctAnswerIndex:0,hint:"Dental fricative."}),
  C("Choose the word you hear.",{word1:"bat",word2:"pat",question:"Which starts with a voiced sound?",options:["bat","pat"],correctAnswerIndex:0,hint:"Vocal cords vibrate."}),
  C("Choose the word you hear.",{word1:"sink",word2:"think",question:"Which starts with /s/?",options:["sink","think"],correctAnswerIndex:0,hint:"Alveolar fricative."}),
  C("Choose the word you hear.",{word1:"pull",word2:"pool",question:"Which has the short /ʊ/?",options:["pull","pool"],correctAnswerIndex:0,hint:"Short vowel."}),
  C("Choose the word you hear.",{word1:"bad",word2:"bed",question:"Which has the /æ/ sound?",options:["bad","bed"],correctAnswerIndex:0,hint:"Open front vowel."}),
  C("Choose the word you hear.",{word1:"hat",word2:"hot",question:"Which has the /æ/ sound?",options:["hat","hot"],correctAnswerIndex:0,hint:"Front vowel."}),
  C("Choose the word you hear.",{word1:"wet",word2:"vet",question:"Which starts with /w/?",options:["wet","vet"],correctAnswerIndex:0,hint:"Rounded lips."}),
  C("Choose the word you hear.",{word1:"coat",word2:"goat",question:"Which starts voiceless?",options:["coat","goat"],correctAnswerIndex:0,hint:"/k/ is voiceless."}),
  C("Choose the word you hear.",{word1:"came",word2:"game",question:"Which starts with /k/?",options:["came","game"],correctAnswerIndex:0,hint:"Voiceless velar."}),
  C("Choose the word you hear.",{word1:"sue",word2:"zoo",question:"Which starts voiceless?",options:["sue","zoo"],correctAnswerIndex:0,hint:"/s/ is voiceless."}),
  C("Choose the word you hear.",{word1:"map",word2:"nap",question:"Which starts with /m/?",options:["map","nap"],correctAnswerIndex:0,hint:"Bilabial nasal."}),
  C("Choose the word you hear.",{word1:"ten",word2:"den",question:"Which starts voiceless?",options:["ten","den"],correctAnswerIndex:0,hint:"/t/ no vibration."}),
  C("Choose the word you hear.",{word1:"chin",word2:"shin",question:"Which starts with /tʃ/?",options:["chin","shin"],correctAnswerIndex:0,hint:"Affricate."}),
  C("Choose the word you hear.",{word1:"path",word2:"bath",question:"Which starts with /p/?",options:["path","bath"],correctAnswerIndex:0,hint:"Voiceless bilabial."}),
  C("Choose the word you hear.",{word1:"fast",word2:"vast",question:"Which starts with /f/?",options:["fast","vast"],correctAnswerIndex:0,hint:"Voiceless labiodental."}),
  C("Choose the word you hear.",{word1:"pit",word2:"bit",question:"Which starts voiceless?",options:["pit","bit"],correctAnswerIndex:0,hint:"Aspirated /p/."}),
  C("Choose the word you hear.",{word1:"few",word2:"view",question:"Which starts with /f/?",options:["few","view"],correctAnswerIndex:0,hint:"Voiceless."}),
  C("Choose the word you hear.",{word1:"rice",word2:"lice",question:"Which starts with /r/?",options:["rice","lice"],correctAnswerIndex:0,hint:"Retroflex sound."}),
  C("Choose the word you hear.",{word1:"seal",word2:"zeal",question:"Which starts voiceless?",options:["seal","zeal"],correctAnswerIndex:0,hint:"/s/ is voiceless."}),
  C("Choose the word you hear.",{word1:"cap",word2:"gap",question:"Which starts voiceless?",options:["cap","gap"],correctAnswerIndex:0,hint:"/k/ is voiceless."}),
  C("Choose the word you hear.",{word1:"wine",word2:"vine",question:"Which starts with /w/?",options:["wine","vine"],correctAnswerIndex:0,hint:"Bilabial approximant."}),
  C("Choose the word you hear.",{word1:"lack",word2:"rack",question:"Which starts with /l/?",options:["lack","rack"],correctAnswerIndex:0,hint:"Lateral."}),
  C("Choose the word you hear.",{word1:"mail",word2:"nail",question:"Which starts with /m/?",options:["mail","nail"],correctAnswerIndex:0,hint:"Bilabial nasal."}),
];

// Other accent games reuse patterns
const dialectDrill = consonantClarity.map(q => ({...q, instruction:'Identify the dialect feature.'}));
const intonationMimic = consonantClarity.map(q => ({...q, instruction:'Mimic the intonation.', interactionType:'speaking'}));
const pitchPatternMatch = minimalPairs.map(q => ({...q, instruction:'Match the pitch pattern.'}));
const shadowingChallenge = generateUniqueShadowingQuestions().map(q => ({
  instruction: q.instruction,
  interactionType: q.interactionType,
  fields: {
    sentence: q.sentence,
    stressPattern: q.stressPattern,
    hint: q.hint
  }
}));
const speedVariance = consonantClarity.map(q => ({...q, instruction:'Identify the speed change.'}));
const syllableStress = [
  C("Where is the stress?",{word:"HOTEL",options:["ho-TEL","HO-tel"],correctAnswerIndex:0,hint:"Stress on second syllable."}),
  C("Where is the stress?",{word:"BANANA",options:["ba-NA-na","BA-na-na"],correctAnswerIndex:0,hint:"Middle syllable."}),
  C("Where is the stress?",{word:"COMPUTER",options:["com-PU-ter","COM-pu-ter"],correctAnswerIndex:0,hint:"Second syllable."}),
  C("Where is the stress?",{word:"IMPORTANT",options:["im-POR-tant","IM-por-tant"],correctAnswerIndex:0,hint:"Second syllable."}),
  C("Where is the stress?",{word:"BEAUTIFUL",options:["BEAU-ti-ful","beau-TI-ful"],correctAnswerIndex:0,hint:"First syllable."}),
  C("Where is the stress?",{word:"EDUCATION",options:["ed-u-CA-tion","ED-u-ca-tion"],correctAnswerIndex:0,hint:"Third syllable."}),
  C("Where is the stress?",{word:"UNDERSTAND",options:["un-der-STAND","UN-der-stand"],correctAnswerIndex:0,hint:"Last syllable."}),
  C("Where is the stress?",{word:"PHOTOGRAPH",options:["PHO-to-graph","pho-TO-graph"],correctAnswerIndex:0,hint:"First syllable."}),
  C("Where is the stress?",{word:"PHOTOGRAPHY",options:["pho-TOG-ra-phy","PHO-tog-ra-phy"],correctAnswerIndex:0,hint:"Second syllable."}),
  C("Where is the stress?",{word:"TELEPHONE",options:["TEL-e-phone","tel-E-phone"],correctAnswerIndex:0,hint:"First syllable."}),
  C("Where is the stress?",{word:"INFORMATION",options:["in-for-MA-tion","IN-for-ma-tion"],correctAnswerIndex:0,hint:"Third syllable."}),
  C("Where is the stress?",{word:"RESTAURANT",options:["RES-tau-rant","res-TAU-rant"],correctAnswerIndex:0,hint:"First syllable."}),
  C("Where is the stress?",{word:"DEVELOPMENT",options:["de-VEL-op-ment","DEV-el-op-ment"],correctAnswerIndex:0,hint:"Second syllable."}),
  C("Where is the stress?",{word:"VOLUNTEER",options:["vol-un-TEER","VOL-un-teer"],correctAnswerIndex:0,hint:"Last syllable."}),
  C("Where is the stress?",{word:"ADVERTISEMENT",options:["ad-VER-tise-ment","AD-ver-tise-ment"],correctAnswerIndex:0,hint:"Second syllable."}),
  C("Where is the stress?",{word:"EMPLOYEE",options:["em-PLOY-ee","EM-ploy-ee"],correctAnswerIndex:0,hint:"Second syllable."}),
  C("Where is the stress?",{word:"ATMOSPHERE",options:["AT-mos-phere","at-MOS-phere"],correctAnswerIndex:0,hint:"First syllable."}),
  C("Where is the stress?",{word:"CERTIFICATE",options:["cer-TIF-i-cate","CER-tif-i-cate"],correctAnswerIndex:0,hint:"Second syllable."}),
  C("Where is the stress?",{word:"CALENDAR",options:["CAL-en-dar","cal-EN-dar"],correctAnswerIndex:0,hint:"First syllable."}),
  C("Where is the stress?",{word:"TOMORROW",options:["to-MOR-row","TOM-or-row"],correctAnswerIndex:0,hint:"Second syllable."}),
  C("Where is the stress?",{word:"HELICOPTER",options:["HEL-i-cop-ter","hel-I-cop-ter"],correctAnswerIndex:0,hint:"First syllable."}),
  C("Where is the stress?",{word:"PERSONALITY",options:["per-son-AL-i-ty","PER-son-al-i-ty"],correctAnswerIndex:0,hint:"Third syllable."}),
  C("Where is the stress?",{word:"EXPERIMENT",options:["ex-PER-i-ment","EX-per-i-ment"],correctAnswerIndex:0,hint:"Second syllable."}),
  C("Where is the stress?",{word:"ECONOMY",options:["e-CON-o-my","EC-on-o-my"],correctAnswerIndex:0,hint:"Second syllable."}),
  C("Where is the stress?",{word:"UNIVERSITY",options:["u-ni-VER-si-ty","UN-i-ver-si-ty"],correctAnswerIndex:0,hint:"Third syllable."}),
  C("Where is the stress?",{word:"PARTICIPATE",options:["par-TIC-i-pate","PAR-tic-i-pate"],correctAnswerIndex:0,hint:"Second syllable."}),
  C("Where is the stress?",{word:"OPPORTUNITY",options:["op-por-TU-ni-ty","OP-por-tu-ni-ty"],correctAnswerIndex:0,hint:"Third syllable."}),
  C("Where is the stress?",{word:"COMMUNICATE",options:["com-MU-ni-cate","COM-mu-ni-cate"],correctAnswerIndex:0,hint:"Second syllable."}),
  C("Where is the stress?",{word:"ENVIRONMENT",options:["en-VI-ron-ment","EN-vi-ron-ment"],correctAnswerIndex:0,hint:"Second syllable."}),
  C("Where is the stress?",{word:"APPRECIATE",options:["ap-PRE-ci-ate","AP-pre-ci-ate"],correctAnswerIndex:0,hint:"Second syllable."}),
];
const vowelDistinction = minimalPairs.map(q => ({...q, instruction:'Distinguish the vowel sounds.'}));
const wordLinking = [
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Did you eat",
      "options": [
        "Did | you",
        "Didju",
        "Did | ju"
      ],
      "correctAnswerIndex": 1,
      "hint": "d + y becomes /dʒ/."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Want to go",
      "options": [
        "Want | to",
        "Wanna",
        "Wan | to"
      ],
      "correctAnswerIndex": 1,
      "hint": "Want to becomes 'Wanna'."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick it up",
      "options": [
        "Pick | it",
        "Pickit",
        "Pick | it | up"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn off the light",
      "options": [
        "Turn | off",
        "Tur | noff",
        "Turnoff"
      ],
      "correctAnswerIndex": 2,
      "hint": "n links to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Going to stay",
      "options": [
        "Going | to",
        "Gonna",
        "Go | to"
      ],
      "correctAnswerIndex": 1,
      "hint": "Going to becomes 'Gonna'."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Got to go",
      "options": [
        "Got | to",
        "Gotta",
        "Got | go"
      ],
      "correctAnswerIndex": 1,
      "hint": "Got to becomes 'Gotta'."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Let you know",
      "options": [
        "Let | you",
        "Letchu",
        "Let | ju"
      ],
      "correctAnswerIndex": 1,
      "hint": "t + y becomes /tʃ/."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick it",
      "options": [
        "Pick | it",
        "pickit",
        "Pick i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick on",
      "options": [
        "Pick | on",
        "pickon",
        "Pick o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick up",
      "options": [
        "Pick | up",
        "pickup",
        "Pick u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick at",
      "options": [
        "Pick | at",
        "pickat",
        "Pick a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick in",
      "options": [
        "Pick | in",
        "pickin",
        "Pick i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick off",
      "options": [
        "Pick | off",
        "pickoff",
        "Pick o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick out",
      "options": [
        "Pick | out",
        "pickout",
        "Pick o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick about",
      "options": [
        "Pick | about",
        "pickabout",
        "Pick a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick around",
      "options": [
        "Pick | around",
        "pickaround",
        "Pick a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick away",
      "options": [
        "Pick | away",
        "pickaway",
        "Pick a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick over",
      "options": [
        "Pick | over",
        "pickover",
        "Pick o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick under",
      "options": [
        "Pick | under",
        "pickunder",
        "Pick u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick across",
      "options": [
        "Pick | across",
        "pickacross",
        "Pick a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pick along",
      "options": [
        "Pick | along",
        "pickalong",
        "Pick a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold it",
      "options": [
        "Hold | it",
        "holdit",
        "Hold i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold on",
      "options": [
        "Hold | on",
        "holdon",
        "Hold o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold up",
      "options": [
        "Hold | up",
        "holdup",
        "Hold u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold at",
      "options": [
        "Hold | at",
        "holdat",
        "Hold a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold in",
      "options": [
        "Hold | in",
        "holdin",
        "Hold i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold off",
      "options": [
        "Hold | off",
        "holdoff",
        "Hold o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold out",
      "options": [
        "Hold | out",
        "holdout",
        "Hold o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold about",
      "options": [
        "Hold | about",
        "holdabout",
        "Hold a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold around",
      "options": [
        "Hold | around",
        "holdaround",
        "Hold a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold away",
      "options": [
        "Hold | away",
        "holdaway",
        "Hold a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold over",
      "options": [
        "Hold | over",
        "holdover",
        "Hold o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold under",
      "options": [
        "Hold | under",
        "holdunder",
        "Hold u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold across",
      "options": [
        "Hold | across",
        "holdacross",
        "Hold a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hold along",
      "options": [
        "Hold | along",
        "holdalong",
        "Hold a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep it",
      "options": [
        "Keep | it",
        "keepit",
        "Keep i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep on",
      "options": [
        "Keep | on",
        "keepon",
        "Keep o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep up",
      "options": [
        "Keep | up",
        "keepup",
        "Keep u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep at",
      "options": [
        "Keep | at",
        "keepat",
        "Keep a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep in",
      "options": [
        "Keep | in",
        "keepin",
        "Keep i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep off",
      "options": [
        "Keep | off",
        "keepoff",
        "Keep o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep out",
      "options": [
        "Keep | out",
        "keepout",
        "Keep o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep about",
      "options": [
        "Keep | about",
        "keepabout",
        "Keep a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep around",
      "options": [
        "Keep | around",
        "keeparound",
        "Keep a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep away",
      "options": [
        "Keep | away",
        "keepaway",
        "Keep a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep over",
      "options": [
        "Keep | over",
        "keepover",
        "Keep o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep under",
      "options": [
        "Keep | under",
        "keepunder",
        "Keep u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep across",
      "options": [
        "Keep | across",
        "keepacross",
        "Keep a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Keep along",
      "options": [
        "Keep | along",
        "keepalong",
        "Keep a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look it",
      "options": [
        "Look | it",
        "lookit",
        "Look i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look on",
      "options": [
        "Look | on",
        "lookon",
        "Look o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look up",
      "options": [
        "Look | up",
        "lookup",
        "Look u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look at",
      "options": [
        "Look | at",
        "lookat",
        "Look a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look in",
      "options": [
        "Look | in",
        "lookin",
        "Look i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look off",
      "options": [
        "Look | off",
        "lookoff",
        "Look o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look out",
      "options": [
        "Look | out",
        "lookout",
        "Look o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look about",
      "options": [
        "Look | about",
        "lookabout",
        "Look a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look around",
      "options": [
        "Look | around",
        "lookaround",
        "Look a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look away",
      "options": [
        "Look | away",
        "lookaway",
        "Look a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look over",
      "options": [
        "Look | over",
        "lookover",
        "Look o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look under",
      "options": [
        "Look | under",
        "lookunder",
        "Look u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look across",
      "options": [
        "Look | across",
        "lookacross",
        "Look a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Look along",
      "options": [
        "Look | along",
        "lookalong",
        "Look a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn it",
      "options": [
        "Turn | it",
        "turnit",
        "Turn i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn on",
      "options": [
        "Turn | on",
        "turnon",
        "Turn o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn up",
      "options": [
        "Turn | up",
        "turnup",
        "Turn u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn at",
      "options": [
        "Turn | at",
        "turnat",
        "Turn a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn in",
      "options": [
        "Turn | in",
        "turnin",
        "Turn i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn off",
      "options": [
        "Turn | off",
        "turnoff",
        "Turn o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn out",
      "options": [
        "Turn | out",
        "turnout",
        "Turn o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn about",
      "options": [
        "Turn | about",
        "turnabout",
        "Turn a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn around",
      "options": [
        "Turn | around",
        "turnaround",
        "Turn a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn away",
      "options": [
        "Turn | away",
        "turnaway",
        "Turn a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn over",
      "options": [
        "Turn | over",
        "turnover",
        "Turn o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn under",
      "options": [
        "Turn | under",
        "turnunder",
        "Turn u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn across",
      "options": [
        "Turn | across",
        "turnacross",
        "Turn a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Turn along",
      "options": [
        "Turn | along",
        "turnalong",
        "Turn a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check it",
      "options": [
        "Check | it",
        "checkit",
        "Check i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check on",
      "options": [
        "Check | on",
        "checkon",
        "Check o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check up",
      "options": [
        "Check | up",
        "checkup",
        "Check u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check at",
      "options": [
        "Check | at",
        "checkat",
        "Check a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check in",
      "options": [
        "Check | in",
        "checkin",
        "Check i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check off",
      "options": [
        "Check | off",
        "checkoff",
        "Check o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check out",
      "options": [
        "Check | out",
        "checkout",
        "Check o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check about",
      "options": [
        "Check | about",
        "checkabout",
        "Check a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check around",
      "options": [
        "Check | around",
        "checkaround",
        "Check a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check away",
      "options": [
        "Check | away",
        "checkaway",
        "Check a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check over",
      "options": [
        "Check | over",
        "checkover",
        "Check o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check under",
      "options": [
        "Check | under",
        "checkunder",
        "Check u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check across",
      "options": [
        "Check | across",
        "checkacross",
        "Check a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Check along",
      "options": [
        "Check | along",
        "checkalong",
        "Check a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find it",
      "options": [
        "Find | it",
        "findit",
        "Find i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find on",
      "options": [
        "Find | on",
        "findon",
        "Find o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find up",
      "options": [
        "Find | up",
        "findup",
        "Find u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find at",
      "options": [
        "Find | at",
        "findat",
        "Find a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find in",
      "options": [
        "Find | in",
        "findin",
        "Find i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find off",
      "options": [
        "Find | off",
        "findoff",
        "Find o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find out",
      "options": [
        "Find | out",
        "findout",
        "Find o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find about",
      "options": [
        "Find | about",
        "findabout",
        "Find a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find around",
      "options": [
        "Find | around",
        "findaround",
        "Find a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find away",
      "options": [
        "Find | away",
        "findaway",
        "Find a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find over",
      "options": [
        "Find | over",
        "findover",
        "Find o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find under",
      "options": [
        "Find | under",
        "findunder",
        "Find u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find across",
      "options": [
        "Find | across",
        "findacross",
        "Find a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Find along",
      "options": [
        "Find | along",
        "findalong",
        "Find a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log it",
      "options": [
        "Log | it",
        "logit",
        "Log i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log on",
      "options": [
        "Log | on",
        "logon",
        "Log o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log up",
      "options": [
        "Log | up",
        "logup",
        "Log u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log at",
      "options": [
        "Log | at",
        "logat",
        "Log a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log in",
      "options": [
        "Log | in",
        "login",
        "Log i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log off",
      "options": [
        "Log | off",
        "logoff",
        "Log o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log out",
      "options": [
        "Log | out",
        "logout",
        "Log o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log about",
      "options": [
        "Log | about",
        "logabout",
        "Log a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log around",
      "options": [
        "Log | around",
        "logaround",
        "Log a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log away",
      "options": [
        "Log | away",
        "logaway",
        "Log a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log over",
      "options": [
        "Log | over",
        "logover",
        "Log o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log under",
      "options": [
        "Log | under",
        "logunder",
        "Log u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log across",
      "options": [
        "Log | across",
        "logacross",
        "Log a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Log along",
      "options": [
        "Log | along",
        "logalong",
        "Log a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass it",
      "options": [
        "Pass | it",
        "passit",
        "Pass i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass on",
      "options": [
        "Pass | on",
        "passon",
        "Pass o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass up",
      "options": [
        "Pass | up",
        "passup",
        "Pass u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass at",
      "options": [
        "Pass | at",
        "passat",
        "Pass a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass in",
      "options": [
        "Pass | in",
        "passin",
        "Pass i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass off",
      "options": [
        "Pass | off",
        "passoff",
        "Pass o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass out",
      "options": [
        "Pass | out",
        "passout",
        "Pass o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass about",
      "options": [
        "Pass | about",
        "passabout",
        "Pass a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass around",
      "options": [
        "Pass | around",
        "passaround",
        "Pass a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass away",
      "options": [
        "Pass | away",
        "passaway",
        "Pass a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass over",
      "options": [
        "Pass | over",
        "passover",
        "Pass o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass under",
      "options": [
        "Pass | under",
        "passunder",
        "Pass u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass across",
      "options": [
        "Pass | across",
        "passacross",
        "Pass a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pass along",
      "options": [
        "Pass | along",
        "passalong",
        "Pass a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "S connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put it",
      "options": [
        "Put | it",
        "putit",
        "Put i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put on",
      "options": [
        "Put | on",
        "puton",
        "Put o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put up",
      "options": [
        "Put | up",
        "putup",
        "Put u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put at",
      "options": [
        "Put | at",
        "putat",
        "Put a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put in",
      "options": [
        "Put | in",
        "putin",
        "Put i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put off",
      "options": [
        "Put | off",
        "putoff",
        "Put o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put out",
      "options": [
        "Put | out",
        "putout",
        "Put o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put about",
      "options": [
        "Put | about",
        "putabout",
        "Put a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put around",
      "options": [
        "Put | around",
        "putaround",
        "Put a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put away",
      "options": [
        "Put | away",
        "putaway",
        "Put a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put over",
      "options": [
        "Put | over",
        "putover",
        "Put o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put under",
      "options": [
        "Put | under",
        "putunder",
        "Put u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put across",
      "options": [
        "Put | across",
        "putacross",
        "Put a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Put along",
      "options": [
        "Put | along",
        "putalong",
        "Put a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit it",
      "options": [
        "Sit | it",
        "sitit",
        "Sit i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit on",
      "options": [
        "Sit | on",
        "siton",
        "Sit o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit up",
      "options": [
        "Sit | up",
        "situp",
        "Sit u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit at",
      "options": [
        "Sit | at",
        "sitat",
        "Sit a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit in",
      "options": [
        "Sit | in",
        "sitin",
        "Sit i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit off",
      "options": [
        "Sit | off",
        "sitoff",
        "Sit o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit out",
      "options": [
        "Sit | out",
        "sitout",
        "Sit o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit about",
      "options": [
        "Sit | about",
        "sitabout",
        "Sit a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit around",
      "options": [
        "Sit | around",
        "sitaround",
        "Sit a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit away",
      "options": [
        "Sit | away",
        "sitaway",
        "Sit a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit over",
      "options": [
        "Sit | over",
        "sitover",
        "Sit o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit under",
      "options": [
        "Sit | under",
        "situnder",
        "Sit u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit across",
      "options": [
        "Sit | across",
        "sitacross",
        "Sit a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Sit along",
      "options": [
        "Sit | along",
        "sitalong",
        "Sit a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand it",
      "options": [
        "Stand | it",
        "standit",
        "Stand i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand on",
      "options": [
        "Stand | on",
        "standon",
        "Stand o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand up",
      "options": [
        "Stand | up",
        "standup",
        "Stand u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand at",
      "options": [
        "Stand | at",
        "standat",
        "Stand a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand in",
      "options": [
        "Stand | in",
        "standin",
        "Stand i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand off",
      "options": [
        "Stand | off",
        "standoff",
        "Stand o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand out",
      "options": [
        "Stand | out",
        "standout",
        "Stand o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand about",
      "options": [
        "Stand | about",
        "standabout",
        "Stand a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand around",
      "options": [
        "Stand | around",
        "standaround",
        "Stand a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand away",
      "options": [
        "Stand | away",
        "standaway",
        "Stand a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand over",
      "options": [
        "Stand | over",
        "standover",
        "Stand o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand under",
      "options": [
        "Stand | under",
        "standunder",
        "Stand u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand across",
      "options": [
        "Stand | across",
        "standacross",
        "Stand a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stand along",
      "options": [
        "Stand | along",
        "standalong",
        "Stand a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think it",
      "options": [
        "Think | it",
        "thinkit",
        "Think i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think on",
      "options": [
        "Think | on",
        "thinkon",
        "Think o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think up",
      "options": [
        "Think | up",
        "thinkup",
        "Think u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think at",
      "options": [
        "Think | at",
        "thinkat",
        "Think a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think in",
      "options": [
        "Think | in",
        "thinkin",
        "Think i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think off",
      "options": [
        "Think | off",
        "thinkoff",
        "Think o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think out",
      "options": [
        "Think | out",
        "thinkout",
        "Think o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think about",
      "options": [
        "Think | about",
        "thinkabout",
        "Think a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think around",
      "options": [
        "Think | around",
        "thinkaround",
        "Think a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think away",
      "options": [
        "Think | away",
        "thinkaway",
        "Think a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think over",
      "options": [
        "Think | over",
        "thinkover",
        "Think o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think under",
      "options": [
        "Think | under",
        "thinkunder",
        "Think u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think across",
      "options": [
        "Think | across",
        "thinkacross",
        "Think a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Think along",
      "options": [
        "Think | along",
        "thinkalong",
        "Think a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read it",
      "options": [
        "Read | it",
        "readit",
        "Read i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read on",
      "options": [
        "Read | on",
        "readon",
        "Read o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read up",
      "options": [
        "Read | up",
        "readup",
        "Read u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read at",
      "options": [
        "Read | at",
        "readat",
        "Read a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read in",
      "options": [
        "Read | in",
        "readin",
        "Read i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read off",
      "options": [
        "Read | off",
        "readoff",
        "Read o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read out",
      "options": [
        "Read | out",
        "readout",
        "Read o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read about",
      "options": [
        "Read | about",
        "readabout",
        "Read a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read around",
      "options": [
        "Read | around",
        "readaround",
        "Read a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read away",
      "options": [
        "Read | away",
        "readaway",
        "Read a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read over",
      "options": [
        "Read | over",
        "readover",
        "Read o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read under",
      "options": [
        "Read | under",
        "readunder",
        "Read u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read across",
      "options": [
        "Read | across",
        "readacross",
        "Read a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Read along",
      "options": [
        "Read | along",
        "readalong",
        "Read a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call it",
      "options": [
        "Call | it",
        "callit",
        "Call i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call on",
      "options": [
        "Call | on",
        "callon",
        "Call o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call up",
      "options": [
        "Call | up",
        "callup",
        "Call u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call at",
      "options": [
        "Call | at",
        "callat",
        "Call a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call in",
      "options": [
        "Call | in",
        "callin",
        "Call i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call off",
      "options": [
        "Call | off",
        "calloff",
        "Call o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call out",
      "options": [
        "Call | out",
        "callout",
        "Call o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call about",
      "options": [
        "Call | about",
        "callabout",
        "Call a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call around",
      "options": [
        "Call | around",
        "callaround",
        "Call a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call away",
      "options": [
        "Call | away",
        "callaway",
        "Call a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call over",
      "options": [
        "Call | over",
        "callover",
        "Call o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call under",
      "options": [
        "Call | under",
        "callunder",
        "Call u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call across",
      "options": [
        "Call | across",
        "callacross",
        "Call a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Call along",
      "options": [
        "Call | along",
        "callalong",
        "Call a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean it",
      "options": [
        "Clean | it",
        "cleanit",
        "Clean i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean on",
      "options": [
        "Clean | on",
        "cleanon",
        "Clean o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean up",
      "options": [
        "Clean | up",
        "cleanup",
        "Clean u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean at",
      "options": [
        "Clean | at",
        "cleanat",
        "Clean a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean in",
      "options": [
        "Clean | in",
        "cleanin",
        "Clean i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean off",
      "options": [
        "Clean | off",
        "cleanoff",
        "Clean o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean out",
      "options": [
        "Clean | out",
        "cleanout",
        "Clean o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean about",
      "options": [
        "Clean | about",
        "cleanabout",
        "Clean a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean around",
      "options": [
        "Clean | around",
        "cleanaround",
        "Clean a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean away",
      "options": [
        "Clean | away",
        "cleanaway",
        "Clean a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean over",
      "options": [
        "Clean | over",
        "cleanover",
        "Clean o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean under",
      "options": [
        "Clean | under",
        "cleanunder",
        "Clean u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean across",
      "options": [
        "Clean | across",
        "cleanacross",
        "Clean a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Clean along",
      "options": [
        "Clean | along",
        "cleanalong",
        "Clean a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream it",
      "options": [
        "Dream | it",
        "dreamit",
        "Dream i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream on",
      "options": [
        "Dream | on",
        "dreamon",
        "Dream o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream up",
      "options": [
        "Dream | up",
        "dreamup",
        "Dream u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream at",
      "options": [
        "Dream | at",
        "dreamat",
        "Dream a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream in",
      "options": [
        "Dream | in",
        "dreamin",
        "Dream i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream off",
      "options": [
        "Dream | off",
        "dreamoff",
        "Dream o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream out",
      "options": [
        "Dream | out",
        "dreamout",
        "Dream o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream about",
      "options": [
        "Dream | about",
        "dreamabout",
        "Dream a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream around",
      "options": [
        "Dream | around",
        "dreamaround",
        "Dream a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream away",
      "options": [
        "Dream | away",
        "dreamaway",
        "Dream a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream over",
      "options": [
        "Dream | over",
        "dreamover",
        "Dream o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream under",
      "options": [
        "Dream | under",
        "dreamunder",
        "Dream u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream across",
      "options": [
        "Dream | across",
        "dreamacross",
        "Dream a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Dream along",
      "options": [
        "Dream | along",
        "dreamalong",
        "Dream a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "M connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed it",
      "options": [
        "Feed | it",
        "feedit",
        "Feed i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed on",
      "options": [
        "Feed | on",
        "feedon",
        "Feed o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed up",
      "options": [
        "Feed | up",
        "feedup",
        "Feed u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed at",
      "options": [
        "Feed | at",
        "feedat",
        "Feed a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed in",
      "options": [
        "Feed | in",
        "feedin",
        "Feed i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed off",
      "options": [
        "Feed | off",
        "feedoff",
        "Feed o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed out",
      "options": [
        "Feed | out",
        "feedout",
        "Feed o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed about",
      "options": [
        "Feed | about",
        "feedabout",
        "Feed a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed around",
      "options": [
        "Feed | around",
        "feedaround",
        "Feed a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed away",
      "options": [
        "Feed | away",
        "feedaway",
        "Feed a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed over",
      "options": [
        "Feed | over",
        "feedover",
        "Feed o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed under",
      "options": [
        "Feed | under",
        "feedunder",
        "Feed u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed across",
      "options": [
        "Feed | across",
        "feedacross",
        "Feed a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Feed along",
      "options": [
        "Feed | along",
        "feedalong",
        "Feed a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get it",
      "options": [
        "Get | it",
        "getit",
        "Get i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get on",
      "options": [
        "Get | on",
        "geton",
        "Get o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get up",
      "options": [
        "Get | up",
        "getup",
        "Get u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get at",
      "options": [
        "Get | at",
        "getat",
        "Get a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get in",
      "options": [
        "Get | in",
        "getin",
        "Get i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get off",
      "options": [
        "Get | off",
        "getoff",
        "Get o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get out",
      "options": [
        "Get | out",
        "getout",
        "Get o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get about",
      "options": [
        "Get | about",
        "getabout",
        "Get a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get around",
      "options": [
        "Get | around",
        "getaround",
        "Get a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get away",
      "options": [
        "Get | away",
        "getaway",
        "Get a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get over",
      "options": [
        "Get | over",
        "getover",
        "Get o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get under",
      "options": [
        "Get | under",
        "getunder",
        "Get u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get across",
      "options": [
        "Get | across",
        "getacross",
        "Get a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Get along",
      "options": [
        "Get | along",
        "getalong",
        "Get a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand it",
      "options": [
        "Hand | it",
        "handit",
        "Hand i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand on",
      "options": [
        "Hand | on",
        "handon",
        "Hand o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand up",
      "options": [
        "Hand | up",
        "handup",
        "Hand u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand at",
      "options": [
        "Hand | at",
        "handat",
        "Hand a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand in",
      "options": [
        "Hand | in",
        "handin",
        "Hand i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand off",
      "options": [
        "Hand | off",
        "handoff",
        "Hand o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand out",
      "options": [
        "Hand | out",
        "handout",
        "Hand o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand about",
      "options": [
        "Hand | about",
        "handabout",
        "Hand a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand around",
      "options": [
        "Hand | around",
        "handaround",
        "Hand a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand away",
      "options": [
        "Hand | away",
        "handaway",
        "Hand a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand over",
      "options": [
        "Hand | over",
        "handover",
        "Hand o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand under",
      "options": [
        "Hand | under",
        "handunder",
        "Hand u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand across",
      "options": [
        "Hand | across",
        "handacross",
        "Hand a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Hand along",
      "options": [
        "Hand | along",
        "handalong",
        "Hand a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "D connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump it",
      "options": [
        "Jump | it",
        "jumpit",
        "Jump i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump on",
      "options": [
        "Jump | on",
        "jumpon",
        "Jump o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump up",
      "options": [
        "Jump | up",
        "jumpup",
        "Jump u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump at",
      "options": [
        "Jump | at",
        "jumpat",
        "Jump a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump in",
      "options": [
        "Jump | in",
        "jumpin",
        "Jump i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump off",
      "options": [
        "Jump | off",
        "jumpoff",
        "Jump o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump out",
      "options": [
        "Jump | out",
        "jumpout",
        "Jump o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump about",
      "options": [
        "Jump | about",
        "jumpabout",
        "Jump a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump around",
      "options": [
        "Jump | around",
        "jumparound",
        "Jump a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump away",
      "options": [
        "Jump | away",
        "jumpaway",
        "Jump a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump over",
      "options": [
        "Jump | over",
        "jumpover",
        "Jump o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump under",
      "options": [
        "Jump | under",
        "jumpunder",
        "Jump u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump across",
      "options": [
        "Jump | across",
        "jumpacross",
        "Jump a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Jump along",
      "options": [
        "Jump | along",
        "jumpalong",
        "Jump a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick it",
      "options": [
        "Kick | it",
        "kickit",
        "Kick i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick on",
      "options": [
        "Kick | on",
        "kickon",
        "Kick o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick up",
      "options": [
        "Kick | up",
        "kickup",
        "Kick u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick at",
      "options": [
        "Kick | at",
        "kickat",
        "Kick a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick in",
      "options": [
        "Kick | in",
        "kickin",
        "Kick i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick off",
      "options": [
        "Kick | off",
        "kickoff",
        "Kick o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick out",
      "options": [
        "Kick | out",
        "kickout",
        "Kick o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick about",
      "options": [
        "Kick | about",
        "kickabout",
        "Kick a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick around",
      "options": [
        "Kick | around",
        "kickaround",
        "Kick a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick away",
      "options": [
        "Kick | away",
        "kickaway",
        "Kick a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick over",
      "options": [
        "Kick | over",
        "kickover",
        "Kick o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick under",
      "options": [
        "Kick | under",
        "kickunder",
        "Kick u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick across",
      "options": [
        "Kick | across",
        "kickacross",
        "Kick a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Kick along",
      "options": [
        "Kick | along",
        "kickalong",
        "Kick a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull it",
      "options": [
        "Pull | it",
        "pullit",
        "Pull i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull on",
      "options": [
        "Pull | on",
        "pullon",
        "Pull o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull up",
      "options": [
        "Pull | up",
        "pullup",
        "Pull u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull at",
      "options": [
        "Pull | at",
        "pullat",
        "Pull a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull in",
      "options": [
        "Pull | in",
        "pullin",
        "Pull i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull off",
      "options": [
        "Pull | off",
        "pulloff",
        "Pull o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull out",
      "options": [
        "Pull | out",
        "pullout",
        "Pull o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull about",
      "options": [
        "Pull | about",
        "pullabout",
        "Pull a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull around",
      "options": [
        "Pull | around",
        "pullaround",
        "Pull a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull away",
      "options": [
        "Pull | away",
        "pullaway",
        "Pull a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull over",
      "options": [
        "Pull | over",
        "pullover",
        "Pull o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull under",
      "options": [
        "Pull | under",
        "pullunder",
        "Pull u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull across",
      "options": [
        "Pull | across",
        "pullacross",
        "Pull a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Pull along",
      "options": [
        "Pull | along",
        "pullalong",
        "Pull a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push it",
      "options": [
        "Push | it",
        "pushit",
        "Push i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push on",
      "options": [
        "Push | on",
        "pushon",
        "Push o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push up",
      "options": [
        "Push | up",
        "pushup",
        "Push u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push at",
      "options": [
        "Push | at",
        "pushat",
        "Push a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push in",
      "options": [
        "Push | in",
        "pushin",
        "Push i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push off",
      "options": [
        "Push | off",
        "pushoff",
        "Push o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push out",
      "options": [
        "Push | out",
        "pushout",
        "Push o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push about",
      "options": [
        "Push | about",
        "pushabout",
        "Push a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push around",
      "options": [
        "Push | around",
        "pusharound",
        "Push a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push away",
      "options": [
        "Push | away",
        "pushaway",
        "Push a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push over",
      "options": [
        "Push | over",
        "pushover",
        "Push o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push under",
      "options": [
        "Push | under",
        "pushunder",
        "Push u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push across",
      "options": [
        "Push | across",
        "pushacross",
        "Push a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Push along",
      "options": [
        "Push | along",
        "pushalong",
        "Push a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run it",
      "options": [
        "Run | it",
        "runit",
        "Run i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run on",
      "options": [
        "Run | on",
        "runon",
        "Run o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run up",
      "options": [
        "Run | up",
        "runup",
        "Run u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run at",
      "options": [
        "Run | at",
        "runat",
        "Run a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run in",
      "options": [
        "Run | in",
        "runin",
        "Run i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run off",
      "options": [
        "Run | off",
        "runoff",
        "Run o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run out",
      "options": [
        "Run | out",
        "runout",
        "Run o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run about",
      "options": [
        "Run | about",
        "runabout",
        "Run a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run around",
      "options": [
        "Run | around",
        "runaround",
        "Run a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run away",
      "options": [
        "Run | away",
        "runaway",
        "Run a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run over",
      "options": [
        "Run | over",
        "runover",
        "Run o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run under",
      "options": [
        "Run | under",
        "rununder",
        "Run u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run across",
      "options": [
        "Run | across",
        "runacross",
        "Run a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Run along",
      "options": [
        "Run | along",
        "runalong",
        "Run a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "N connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay it",
      "options": [
        "Stay | it",
        "stayit",
        "Stay i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay on",
      "options": [
        "Stay | on",
        "stayon",
        "Stay o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay up",
      "options": [
        "Stay | up",
        "stayup",
        "Stay u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay at",
      "options": [
        "Stay | at",
        "stayat",
        "Stay a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay in",
      "options": [
        "Stay | in",
        "stayin",
        "Stay i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay off",
      "options": [
        "Stay | off",
        "stayoff",
        "Stay o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay out",
      "options": [
        "Stay | out",
        "stayout",
        "Stay o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay about",
      "options": [
        "Stay | about",
        "stayabout",
        "Stay a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay around",
      "options": [
        "Stay | around",
        "stayaround",
        "Stay a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay away",
      "options": [
        "Stay | away",
        "stayaway",
        "Stay a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay over",
      "options": [
        "Stay | over",
        "stayover",
        "Stay o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay under",
      "options": [
        "Stay | under",
        "stayunder",
        "Stay u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay across",
      "options": [
        "Stay | across",
        "stayacross",
        "Stay a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Stay along",
      "options": [
        "Stay | along",
        "stayalong",
        "Stay a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step it",
      "options": [
        "Step | it",
        "stepit",
        "Step i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step on",
      "options": [
        "Step | on",
        "stepon",
        "Step o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step up",
      "options": [
        "Step | up",
        "stepup",
        "Step u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step at",
      "options": [
        "Step | at",
        "stepat",
        "Step a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step in",
      "options": [
        "Step | in",
        "stepin",
        "Step i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step off",
      "options": [
        "Step | off",
        "stepoff",
        "Step o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step out",
      "options": [
        "Step | out",
        "stepout",
        "Step o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step about",
      "options": [
        "Step | about",
        "stepabout",
        "Step a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step around",
      "options": [
        "Step | around",
        "steparound",
        "Step a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step away",
      "options": [
        "Step | away",
        "stepaway",
        "Step a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step over",
      "options": [
        "Step | over",
        "stepover",
        "Step o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step under",
      "options": [
        "Step | under",
        "stepunder",
        "Step u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step across",
      "options": [
        "Step | across",
        "stepacross",
        "Step a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Step along",
      "options": [
        "Step | along",
        "stepalong",
        "Step a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait it",
      "options": [
        "Wait | it",
        "waitit",
        "Wait i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait on",
      "options": [
        "Wait | on",
        "waiton",
        "Wait o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait up",
      "options": [
        "Wait | up",
        "waitup",
        "Wait u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait at",
      "options": [
        "Wait | at",
        "waitat",
        "Wait a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait in",
      "options": [
        "Wait | in",
        "waitin",
        "Wait i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait off",
      "options": [
        "Wait | off",
        "waitoff",
        "Wait o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait out",
      "options": [
        "Wait | out",
        "waitout",
        "Wait o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait about",
      "options": [
        "Wait | about",
        "waitabout",
        "Wait a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait around",
      "options": [
        "Wait | around",
        "waitaround",
        "Wait a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait away",
      "options": [
        "Wait | away",
        "waitaway",
        "Wait a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait over",
      "options": [
        "Wait | over",
        "waitover",
        "Wait o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait under",
      "options": [
        "Wait | under",
        "waitunder",
        "Wait u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait across",
      "options": [
        "Wait | across",
        "waitacross",
        "Wait a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wait along",
      "options": [
        "Wait | along",
        "waitalong",
        "Wait a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk it",
      "options": [
        "Walk | it",
        "walkit",
        "Walk i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk on",
      "options": [
        "Walk | on",
        "walkon",
        "Walk o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk up",
      "options": [
        "Walk | up",
        "walkup",
        "Walk u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk at",
      "options": [
        "Walk | at",
        "walkat",
        "Walk a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk in",
      "options": [
        "Walk | in",
        "walkin",
        "Walk i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk off",
      "options": [
        "Walk | off",
        "walkoff",
        "Walk o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk out",
      "options": [
        "Walk | out",
        "walkout",
        "Walk o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk about",
      "options": [
        "Walk | about",
        "walkabout",
        "Walk a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk around",
      "options": [
        "Walk | around",
        "walkaround",
        "Walk a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk away",
      "options": [
        "Walk | away",
        "walkaway",
        "Walk a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk over",
      "options": [
        "Walk | over",
        "walkover",
        "Walk o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk under",
      "options": [
        "Walk | under",
        "walkunder",
        "Walk u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk across",
      "options": [
        "Walk | across",
        "walkacross",
        "Walk a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Walk along",
      "options": [
        "Walk | along",
        "walkalong",
        "Walk a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash it",
      "options": [
        "Wash | it",
        "washit",
        "Wash i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash on",
      "options": [
        "Wash | on",
        "washon",
        "Wash o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash up",
      "options": [
        "Wash | up",
        "washup",
        "Wash u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash at",
      "options": [
        "Wash | at",
        "washat",
        "Wash a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash in",
      "options": [
        "Wash | in",
        "washin",
        "Wash i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash off",
      "options": [
        "Wash | off",
        "washoff",
        "Wash o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash out",
      "options": [
        "Wash | out",
        "washout",
        "Wash o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash about",
      "options": [
        "Wash | about",
        "washabout",
        "Wash a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash around",
      "options": [
        "Wash | around",
        "washaround",
        "Wash a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash away",
      "options": [
        "Wash | away",
        "washaway",
        "Wash a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash over",
      "options": [
        "Wash | over",
        "washover",
        "Wash o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash under",
      "options": [
        "Wash | under",
        "washunder",
        "Wash u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash across",
      "options": [
        "Wash | across",
        "washacross",
        "Wash a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Wash along",
      "options": [
        "Wash | along",
        "washalong",
        "Wash a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch it",
      "options": [
        "Watch | it",
        "watchit",
        "Watch i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch on",
      "options": [
        "Watch | on",
        "watchon",
        "Watch o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch up",
      "options": [
        "Watch | up",
        "watchup",
        "Watch u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch at",
      "options": [
        "Watch | at",
        "watchat",
        "Watch a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch in",
      "options": [
        "Watch | in",
        "watchin",
        "Watch i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch off",
      "options": [
        "Watch | off",
        "watchoff",
        "Watch o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch out",
      "options": [
        "Watch | out",
        "watchout",
        "Watch o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch about",
      "options": [
        "Watch | about",
        "watchabout",
        "Watch a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch around",
      "options": [
        "Watch | around",
        "watcharound",
        "Watch a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch away",
      "options": [
        "Watch | away",
        "watchaway",
        "Watch a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch over",
      "options": [
        "Watch | over",
        "watchover",
        "Watch o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch under",
      "options": [
        "Watch | under",
        "watchunder",
        "Watch u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch across",
      "options": [
        "Watch | across",
        "watchacross",
        "Watch a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Watch along",
      "options": [
        "Watch | along",
        "watchalong",
        "Watch a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work it",
      "options": [
        "Work | it",
        "workit",
        "Work i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work on",
      "options": [
        "Work | on",
        "workon",
        "Work o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work up",
      "options": [
        "Work | up",
        "workup",
        "Work u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work at",
      "options": [
        "Work | at",
        "workat",
        "Work a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work in",
      "options": [
        "Work | in",
        "workin",
        "Work i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work off",
      "options": [
        "Work | off",
        "workoff",
        "Work o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work out",
      "options": [
        "Work | out",
        "workout",
        "Work o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work about",
      "options": [
        "Work | about",
        "workabout",
        "Work a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work around",
      "options": [
        "Work | around",
        "workaround",
        "Work a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work away",
      "options": [
        "Work | away",
        "workaway",
        "Work a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work over",
      "options": [
        "Work | over",
        "workover",
        "Work o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work under",
      "options": [
        "Work | under",
        "workunder",
        "Work u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work across",
      "options": [
        "Work | across",
        "workacross",
        "Work a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Work along",
      "options": [
        "Work | along",
        "workalong",
        "Work a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask it",
      "options": [
        "Ask | it",
        "askit",
        "Ask i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask on",
      "options": [
        "Ask | on",
        "askon",
        "Ask o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask up",
      "options": [
        "Ask | up",
        "askup",
        "Ask u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask at",
      "options": [
        "Ask | at",
        "askat",
        "Ask a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask in",
      "options": [
        "Ask | in",
        "askin",
        "Ask i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask off",
      "options": [
        "Ask | off",
        "askoff",
        "Ask o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask out",
      "options": [
        "Ask | out",
        "askout",
        "Ask o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask about",
      "options": [
        "Ask | about",
        "askabout",
        "Ask a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask around",
      "options": [
        "Ask | around",
        "askaround",
        "Ask a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask away",
      "options": [
        "Ask | away",
        "askaway",
        "Ask a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask over",
      "options": [
        "Ask | over",
        "askover",
        "Ask o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask under",
      "options": [
        "Ask | under",
        "askunder",
        "Ask u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask across",
      "options": [
        "Ask | across",
        "askacross",
        "Ask a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Ask along",
      "options": [
        "Ask | along",
        "askalong",
        "Ask a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring it",
      "options": [
        "Bring | it",
        "bringit",
        "Bring i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring on",
      "options": [
        "Bring | on",
        "bringon",
        "Bring o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring up",
      "options": [
        "Bring | up",
        "bringup",
        "Bring u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring at",
      "options": [
        "Bring | at",
        "bringat",
        "Bring a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring in",
      "options": [
        "Bring | in",
        "bringin",
        "Bring i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring off",
      "options": [
        "Bring | off",
        "bringoff",
        "Bring o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring out",
      "options": [
        "Bring | out",
        "bringout",
        "Bring o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring about",
      "options": [
        "Bring | about",
        "bringabout",
        "Bring a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring around",
      "options": [
        "Bring | around",
        "bringaround",
        "Bring a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring away",
      "options": [
        "Bring | away",
        "bringaway",
        "Bring a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring over",
      "options": [
        "Bring | over",
        "bringover",
        "Bring o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring under",
      "options": [
        "Bring | under",
        "bringunder",
        "Bring u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring across",
      "options": [
        "Bring | across",
        "bringacross",
        "Bring a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Bring along",
      "options": [
        "Bring | along",
        "bringalong",
        "Bring a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "G connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy it",
      "options": [
        "Buy | it",
        "buyit",
        "Buy i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy on",
      "options": [
        "Buy | on",
        "buyon",
        "Buy o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy up",
      "options": [
        "Buy | up",
        "buyup",
        "Buy u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy at",
      "options": [
        "Buy | at",
        "buyat",
        "Buy a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy in",
      "options": [
        "Buy | in",
        "buyin",
        "Buy i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy off",
      "options": [
        "Buy | off",
        "buyoff",
        "Buy o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy out",
      "options": [
        "Buy | out",
        "buyout",
        "Buy o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy about",
      "options": [
        "Buy | about",
        "buyabout",
        "Buy a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy around",
      "options": [
        "Buy | around",
        "buyaround",
        "Buy a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy away",
      "options": [
        "Buy | away",
        "buyaway",
        "Buy a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy over",
      "options": [
        "Buy | over",
        "buyover",
        "Buy o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy under",
      "options": [
        "Buy | under",
        "buyunder",
        "Buy u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy across",
      "options": [
        "Buy | across",
        "buyacross",
        "Buy a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Buy along",
      "options": [
        "Buy | along",
        "buyalong",
        "Buy a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "Y connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch it",
      "options": [
        "Catch | it",
        "catchit",
        "Catch i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch on",
      "options": [
        "Catch | on",
        "catchon",
        "Catch o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch up",
      "options": [
        "Catch | up",
        "catchup",
        "Catch u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch at",
      "options": [
        "Catch | at",
        "catchat",
        "Catch a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch in",
      "options": [
        "Catch | in",
        "catchin",
        "Catch i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch off",
      "options": [
        "Catch | off",
        "catchoff",
        "Catch o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch out",
      "options": [
        "Catch | out",
        "catchout",
        "Catch o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch about",
      "options": [
        "Catch | about",
        "catchabout",
        "Catch a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch around",
      "options": [
        "Catch | around",
        "catcharound",
        "Catch a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch away",
      "options": [
        "Catch | away",
        "catchaway",
        "Catch a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch over",
      "options": [
        "Catch | over",
        "catchover",
        "Catch o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch under",
      "options": [
        "Catch | under",
        "catchunder",
        "Catch u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch across",
      "options": [
        "Catch | across",
        "catchacross",
        "Catch a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Catch along",
      "options": [
        "Catch | along",
        "catchalong",
        "Catch a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "H connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut it",
      "options": [
        "Cut | it",
        "cutit",
        "Cut i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut on",
      "options": [
        "Cut | on",
        "cuton",
        "Cut o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut up",
      "options": [
        "Cut | up",
        "cutup",
        "Cut u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut at",
      "options": [
        "Cut | at",
        "cutat",
        "Cut a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut in",
      "options": [
        "Cut | in",
        "cutin",
        "Cut i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut off",
      "options": [
        "Cut | off",
        "cutoff",
        "Cut o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut out",
      "options": [
        "Cut | out",
        "cutout",
        "Cut o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut about",
      "options": [
        "Cut | about",
        "cutabout",
        "Cut a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut around",
      "options": [
        "Cut | around",
        "cutaround",
        "Cut a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut away",
      "options": [
        "Cut | away",
        "cutaway",
        "Cut a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut over",
      "options": [
        "Cut | over",
        "cutover",
        "Cut o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut under",
      "options": [
        "Cut | under",
        "cutunder",
        "Cut u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut across",
      "options": [
        "Cut | across",
        "cutacross",
        "Cut a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Cut along",
      "options": [
        "Cut | along",
        "cutalong",
        "Cut a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink it",
      "options": [
        "Drink | it",
        "drinkit",
        "Drink i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink on",
      "options": [
        "Drink | on",
        "drinkon",
        "Drink o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink up",
      "options": [
        "Drink | up",
        "drinkup",
        "Drink u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink at",
      "options": [
        "Drink | at",
        "drinkat",
        "Drink a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink in",
      "options": [
        "Drink | in",
        "drinkin",
        "Drink i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink off",
      "options": [
        "Drink | off",
        "drinkoff",
        "Drink o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink out",
      "options": [
        "Drink | out",
        "drinkout",
        "Drink o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink about",
      "options": [
        "Drink | about",
        "drinkabout",
        "Drink a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink around",
      "options": [
        "Drink | around",
        "drinkaround",
        "Drink a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink away",
      "options": [
        "Drink | away",
        "drinkaway",
        "Drink a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink over",
      "options": [
        "Drink | over",
        "drinkover",
        "Drink o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink under",
      "options": [
        "Drink | under",
        "drinkunder",
        "Drink u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink across",
      "options": [
        "Drink | across",
        "drinkacross",
        "Drink a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Drink along",
      "options": [
        "Drink | along",
        "drinkalong",
        "Drink a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "K connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat it",
      "options": [
        "Eat | it",
        "eatit",
        "Eat i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat on",
      "options": [
        "Eat | on",
        "eaton",
        "Eat o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat up",
      "options": [
        "Eat | up",
        "eatup",
        "Eat u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat at",
      "options": [
        "Eat | at",
        "eatat",
        "Eat a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat in",
      "options": [
        "Eat | in",
        "eatin",
        "Eat i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat off",
      "options": [
        "Eat | off",
        "eatoff",
        "Eat o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat out",
      "options": [
        "Eat | out",
        "eatout",
        "Eat o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat about",
      "options": [
        "Eat | about",
        "eatabout",
        "Eat a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat around",
      "options": [
        "Eat | around",
        "eataround",
        "Eat a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat away",
      "options": [
        "Eat | away",
        "eataway",
        "Eat a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat over",
      "options": [
        "Eat | over",
        "eatover",
        "Eat o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat under",
      "options": [
        "Eat | under",
        "eatunder",
        "Eat u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat across",
      "options": [
        "Eat | across",
        "eatacross",
        "Eat a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Eat along",
      "options": [
        "Eat | along",
        "eatalong",
        "Eat a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "T connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall it",
      "options": [
        "Fall | it",
        "fallit",
        "Fall i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall on",
      "options": [
        "Fall | on",
        "fallon",
        "Fall o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall up",
      "options": [
        "Fall | up",
        "fallup",
        "Fall u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall at",
      "options": [
        "Fall | at",
        "fallat",
        "Fall a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall in",
      "options": [
        "Fall | in",
        "fallin",
        "Fall i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall off",
      "options": [
        "Fall | off",
        "falloff",
        "Fall o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall out",
      "options": [
        "Fall | out",
        "fallout",
        "Fall o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall about",
      "options": [
        "Fall | about",
        "fallabout",
        "Fall a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall around",
      "options": [
        "Fall | around",
        "fallaround",
        "Fall a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall away",
      "options": [
        "Fall | away",
        "fallaway",
        "Fall a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall over",
      "options": [
        "Fall | over",
        "fallover",
        "Fall o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall under",
      "options": [
        "Fall | under",
        "fallunder",
        "Fall u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall across",
      "options": [
        "Fall | across",
        "fallacross",
        "Fall a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Fall along",
      "options": [
        "Fall | along",
        "fallalong",
        "Fall a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "L connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow it",
      "options": [
        "Grow | it",
        "growit",
        "Grow i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow on",
      "options": [
        "Grow | on",
        "growon",
        "Grow o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow up",
      "options": [
        "Grow | up",
        "growup",
        "Grow u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow at",
      "options": [
        "Grow | at",
        "growat",
        "Grow a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow in",
      "options": [
        "Grow | in",
        "growin",
        "Grow i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow off",
      "options": [
        "Grow | off",
        "growoff",
        "Grow o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow out",
      "options": [
        "Grow | out",
        "growout",
        "Grow o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow about",
      "options": [
        "Grow | about",
        "growabout",
        "Grow a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow around",
      "options": [
        "Grow | around",
        "growaround",
        "Grow a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow away",
      "options": [
        "Grow | away",
        "growaway",
        "Grow a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow over",
      "options": [
        "Grow | over",
        "growover",
        "Grow o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow under",
      "options": [
        "Grow | under",
        "growunder",
        "Grow u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow across",
      "options": [
        "Grow | across",
        "growacross",
        "Grow a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Grow along",
      "options": [
        "Grow | along",
        "growalong",
        "Grow a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help it",
      "options": [
        "Help | it",
        "helpit",
        "Help i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help on",
      "options": [
        "Help | on",
        "helpon",
        "Help o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help up",
      "options": [
        "Help | up",
        "helpup",
        "Help u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help at",
      "options": [
        "Help | at",
        "helpat",
        "Help a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help in",
      "options": [
        "Help | in",
        "helpin",
        "Help i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help off",
      "options": [
        "Help | off",
        "helpoff",
        "Help o | ff"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help out",
      "options": [
        "Help | out",
        "helpout",
        "Help o | ut"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help about",
      "options": [
        "Help | about",
        "helpabout",
        "Help a | bout"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help around",
      "options": [
        "Help | around",
        "helparound",
        "Help a | round"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help away",
      "options": [
        "Help | away",
        "helpaway",
        "Help a | way"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help over",
      "options": [
        "Help | over",
        "helpover",
        "Help o | ver"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help under",
      "options": [
        "Help | under",
        "helpunder",
        "Help u | nder"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help across",
      "options": [
        "Help | across",
        "helpacross",
        "Help a | cross"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Help along",
      "options": [
        "Help | along",
        "helpalong",
        "Help a | long"
      ],
      "correctAnswerIndex": 1,
      "hint": "P connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Know it",
      "options": [
        "Know | it",
        "knowit",
        "Know i | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Know on",
      "options": [
        "Know | on",
        "knowon",
        "Know o | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Know up",
      "options": [
        "Know | up",
        "knowup",
        "Know u | p"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Know at",
      "options": [
        "Know | at",
        "knowat",
        "Know a | t"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  },
  {
    "instruction": "Identify the linked sounds.",
    "interactionType": "choice",
    "fields": {
      "word": "Know in",
      "options": [
        "Know | in",
        "knowin",
        "Know i | n"
      ],
      "correctAnswerIndex": 1,
      "hint": "W connects to vowel."
    }
  }
];

module.exports = {
  consonantClarity, dialectDrill, intonationMimic, minimalPairs,
  pitchPatternMatch, shadowingChallenge, speedVariance, syllableStress,
  vowelDistinction, wordLinking,
};
