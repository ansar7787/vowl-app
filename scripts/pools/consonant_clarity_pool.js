// Each entry: { instruction, fields: { word, options, correctAnswerIndex, hint, mouthPosition? } }
const getIpa = require(__dirname + '/get_ipa.js');
module.exports = function() {
  const pool = [];
  
  // Category 1: Voiced vs Unvoiced TH (120 words)
  const thWords = [
    // Unvoiced /θ/
    ['[TH]INK',1],['[TH]REE',1],['[TH]ROW',1],['[TH]ANK',1],['[TH]ROUGH',1],
    ['[TH]UMB',1],['[TH]IN',1],['[TH]ICK',1],['[TH]IRST',1],['[TH]RONE',1],
    ['[TH]READ',1],['[TH]REAT',1],['[TH]RILL',1],['[TH]RIVE',1],['[TH]RUST',1],
    ['[TH]UNDER',1],['[TH]ERAPY',1],['[TH]EORY',1],['[TH]ERMAL',1],['[TH]ESIS',1],
    ['[TH]ORN',1],['[TH]OUSAND',1],['[TH]EFT',1],['[TH]IRTEEN',1],['[TH]IRTY',1],
    ['[TH]EATRE',1],['[TH]ANKSGIVING',1],['[TH]ERMOMETER',1],['[TH]RESHOLD',1],['[TH]ROTTLE',1],
    ['MA[TH]',1],['PA[TH]',1],['BA[TH]',1],['GROW[TH]',1],['HEAL[TH]',1],
    ['WEAL[TH]',1],['STEAL[TH]',1],['TROU[TH]',1],['YOU[TH]',1],['MOU[TH]',1],
    ['NOR[TH]',1],['SOU[TH]',1],['BIR[TH]',1],['EAR[TH]',1],['WOR[TH]',1],
    ['LENG[TH]',1],['STRENG[TH]',1],['DEP[TH]',1],['WID[TH]',1],['TOO[TH]',1],
    ['BOO[TH]',1],['SMOO[TH]',1],['BRO[TH]',1],['CLO[TH]',1],['FRI[TH]',1],
    ['[TH]ATCH',1],['[TH]WART',1],['[TH]ERAPIST',1],['[TH]EOREM',1],['[TH]EMATIC',1],
    // Voiced /ð/
    ['[TH]IS',0],['[TH]AT',0],['[TH]EM',0],['[TH]EN',0],['[TH]OSE',0],
    ['[TH]ERE',0],['[TH]EY',0],['[TH]EIR',0],['[TH]OUGH',0],['[TH]US',0],
    ['[TH]AN',0],['[TH]ESE',0],['WI[TH]',0],['BREA[TH]E',0],['SMO[TH]E',0],
    ['BA[TH]E',0],['CLO[TH]E',0],['LOA[TH]E',0],['SWOO[TH]E',0],['TEE[TH]E',0],
    ['MO[TH]ER',0],['FA[TH]ER',0],['BRO[TH]ER',0],['WEA[TH]ER',0],['FEA[TH]ER',0],
    ['LEA[TH]ER',0],['GA[TH]ER',0],['TO-GE[TH]ER',0],['WI[TH]IN',0],['WI[TH]OUT',0],
    ['FUR[TH]ER',0],['EI[TH]ER',0],['NEI[TH]ER',0],['AL[TH]OUGH',0],['BO[TH]ER',0],
    ['ANO[TH]ER',0],['RA[TH]ER',0],['SMOO[TH]ER',0],['WI[TH]DRAW',0],['[TH]EREBY',0],
    ['[TH]EREFORE',0],['[TH]EREAFTER',0],['WOR[TH]Y',0],['NEV-ER-[TH]ELESS',0],
    ['[TH]EREUPON',0],['[TH]ENCEFOR[TH]',0],['WI[TH]STAND',0],['[TH]EIRS',0],
    ['[TH]EMSELVES',0],['[TH]EREIN',0],['CALA[TH]EA',0],['SWAR[TH]Y',0],
    ['SLEE[TH]E',0],['SCOO[TH]E',0],['TEE[TH]ING',0],['SOO[TH]ING',0],
    ['SHEA[TH]E',0],['UNSCA[TH]ED',0],['SERAPH[TH]E',0],['ALBE[TH]A',0],
  ];
  for (const [word, ans] of thWords) {
    const cleanWord = word.replace(/\[|\]/g, '');
    pool.push({
      instruction: "Is 'th' voiced or unvoiced?",
      fields: { 
        word, 
        options: ['Voiced','Unvoiced'], 
        correctAnswerIndex: ans, 
        hint: ans===1?'No throat vibration.':'Throat vibrates.', 
        mouthPosition: 'Put your tongue between your teeth and blow air gently.',
        phoneticHint: getIpa(cleanWord)
      }
    });
  }

  // Category 2: Consonant identification sh/ch/j/zh (120 words)
  const conId = [
    ['[SH]IP','/ʃ/ (sh)','/s/ (s)',0],['[SH]OW','/ʃ/ (sh)','/s/ (s)',0],['[SH]APE','/ʃ/ (sh)','/s/ (s)',0],
    ['[SH]ARE','/ʃ/ (sh)','/s/ (s)',0],['[SH]ELL','/ʃ/ (sh)','/s/ (s)',0],['[SH]INE','/ʃ/ (sh)','/s/ (s)',0],
    ['[SH]OOT','/ʃ/ (sh)','/s/ (s)',0],['[SH]ORE','/ʃ/ (sh)','/s/ (s)',0],['[SH]ORT','/ʃ/ (sh)','/s/ (s)',0],
    ['[SH]OUL-DER','/ʃ/ (sh)','/s/ (s)',0],['[SH]OUT','/ʃ/ (sh)','/s/ (s)',0],['[SH]UT','/ʃ/ (sh)','/s/ (s)',0],
    ['[SH]IFT','/ʃ/ (sh)','/s/ (s)',0],['[SH]IELD','/ʃ/ (sh)','/s/ (s)',0],['[SH]IVER','/ʃ/ (sh)','/s/ (s)',0],
    ['WA[SH]','/ʃ/ (sh)','/s/ (s)',0],['FI[SH]','/ʃ/ (sh)','/s/ (s)',0],['WI[SH]','/ʃ/ (sh)','/s/ (s)',0],
    ['CRU[SH]','/ʃ/ (sh)','/s/ (s)',0],['BRU[SH]','/ʃ/ (sh)','/s/ (s)',0],['FLA[SH]','/ʃ/ (sh)','/s/ (s)',0],
    ['PU[SH]','/ʃ/ (sh)','/s/ (s)',0],['RU[SH]','/ʃ/ (sh)','/s/ (s)',0],['FRE[SH]','/ʃ/ (sh)','/s/ (s)',0],
    ['PL[SH]','/ʃ/ (sh)','/s/ (s)',0],['TRA[SH]','/ʃ/ (sh)','/s/ (s)',0],['SMA[SH]','/ʃ/ (sh)','/s/ (s)',0],
    ['CLA[SH]','/ʃ/ (sh)','/s/ (s)',0],['GNA[SH]','/ʃ/ (sh)','/s/ (s)',0],['SLA[SH]','/ʃ/ (sh)','/s/ (s)',0],
    ['[CH]IP','/tʃ/ (ch)','/ʃ/ (sh)',0],['[CH]ANGE','/tʃ/ (ch)','/ʃ/ (sh)',0],['[CH]OOSE','/tʃ/ (ch)','/ʃ/ (sh)',0],
    ['[CH]AIN','/tʃ/ (ch)','/ʃ/ (sh)',0],['[CH]AIR','/tʃ/ (ch)','/ʃ/ (sh)',0],['[CH]ANCE','/tʃ/ (ch)','/ʃ/ (sh)',0],
    ['[CH]ARM','/tʃ/ (ch)','/ʃ/ (sh)',0],['[CH]ASE','/tʃ/ (ch)','/ʃ/ (sh)',0],['[CH]EAP','/tʃ/ (ch)','/ʃ/ (sh)',0],
    ['[CH]ECK','/tʃ/ (ch)','/ʃ/ (sh)',0],['[CH]EER','/tʃ/ (ch)','/ʃ/ (sh)',0],['[CH]EST','/tʃ/ (ch)','/ʃ/ (sh)',0],
    ['[CH]ILD','/tʃ/ (ch)','/ʃ/ (sh)',0],['[CH]ILL','/tʃ/ (ch)','/ʃ/ (sh)',0],['[CH]INA','/tʃ/ (ch)','/ʃ/ (sh)',0],
    ['MAT[CH]','/tʃ/ (ch)','/ʃ/ (sh)',0],['CAT[CH]','/tʃ/ (ch)','/ʃ/ (sh)',0],['WAT[CH]','/tʃ/ (ch)','/ʃ/ (sh)',0],
    ['TEA[CH]','/tʃ/ (ch)','/ʃ/ (sh)',0],['REA[CH]','/tʃ/ (ch)','/ʃ/ (sh)',0],['BEA[CH]','/tʃ/ (ch)','/ʃ/ (sh)',0],
    ['MU[CH]','/tʃ/ (ch)','/ʃ/ (sh)',0],['RAN[CH]','/tʃ/ (ch)','/ʃ/ (sh)',0],['BEN[CH]','/tʃ/ (ch)','/ʃ/ (sh)',0],
    ['LUN[CH]','/tʃ/ (ch)','/ʃ/ (sh)',0],['SEAR[CH]','/tʃ/ (ch)','/ʃ/ (sh)',0],['PREA[CH]','/tʃ/ (ch)','/ʃ/ (sh)',0],
    ['JOB','/dʒ/ (j)','/ʒ/ (zh)',0],['JUMP','/dʒ/ (j)','/ʒ/ (zh)',0],['JUNGLE','/dʒ/ (j)','/ʒ/ (zh)',0],
    ['JUDGE','/dʒ/ (j)','/ʒ/ (zh)',0],['JUICE','/dʒ/ (j)','/ʒ/ (zh)',0],['JACKET','/dʒ/ (j)','/ʒ/ (zh)',0],
    ['JAM','/dʒ/ (j)','/ʒ/ (zh)',0],['JAR','/dʒ/ (j)','/ʒ/ (zh)',0],['JOURNEY','/dʒ/ (j)','/ʒ/ (zh)',0],
    ['JOY','/dʒ/ (j)','/ʒ/ (zh)',0],['JOKE','/dʒ/ (j)','/ʒ/ (zh)',0],['JOIN','/dʒ/ (j)','/ʒ/ (zh)',0],
    ['GENTLE','/dʒ/ (j)','/ʒ/ (zh)',0],['GIANT','/dʒ/ (j)','/ʒ/ (zh)',0],['GINGER','/dʒ/ (j)','/ʒ/ (zh)',0],
    ['BADGE','/dʒ/ (j)','/ʒ/ (zh)',0],['BRIDGE','/dʒ/ (j)','/ʒ/ (zh)',0],['EDGE','/dʒ/ (j)','/ʒ/ (zh)',0],
    ['HEDGE','/dʒ/ (j)','/ʒ/ (zh)',0],['LEDGE','/dʒ/ (j)','/ʒ/ (zh)',0],['RIDGE','/dʒ/ (j)','/ʒ/ (zh)',0],
    ['VISION','/ʒ/ (zh)','/dʒ/ (j)',0],['MEASURE','/ʒ/ (zh)','/dʒ/ (j)',0],['TREASURE','/ʒ/ (zh)','/dʒ/ (j)',0],
    ['PLEASURE','/ʒ/ (zh)','/dʒ/ (j)',0],['LEISURE','/ʒ/ (zh)','/dʒ/ (j)',0],['DECISION','/ʒ/ (zh)','/dʒ/ (j)',0],
    ['TELEVISION','/ʒ/ (zh)','/dʒ/ (j)',0],['OCCASION','/ʒ/ (zh)','/dʒ/ (j)',0],['EXPLOSION','/ʒ/ (zh)','/dʒ/ (j)',0],
    ['CONFUSION','/ʒ/ (zh)','/dʒ/ (j)',0],['EROSION','/ʒ/ (zh)','/dʒ/ (j)',0],['ILLUSION','/ʒ/ (zh)','/dʒ/ (j)',0],
    ['RING','/ŋ/ (ng)','/n/ (n)',0],['SING','/ŋ/ (ng)','/n/ (n)',0],['BRING','/ŋ/ (ng)','/n/ (n)',0],
    ['KING','/ŋ/ (ng)','/n/ (n)',0],['THING','/ŋ/ (ng)','/n/ (n)',0],['LONG','/ŋ/ (ng)','/n/ (n)',0],
    ['SONG','/ŋ/ (ng)','/n/ (n)',0],['WRONG','/ŋ/ (ng)','/n/ (n)',0],['STRONG','/ŋ/ (ng)','/n/ (n)',0],
    ['YOUNG','/ŋ/ (ng)','/n/ (n)',0],['AMONG','/ŋ/ (ng)','/n/ (n)',0],['LUNG','/ŋ/ (ng)','/n/ (n)',0],
    ['TONGUE','/ŋ/ (ng)','/n/ (n)',0],['SPRING','/ŋ/ (ng)','/n/ (n)',0],['STRING','/ŋ/ (ng)','/n/ (n)',0],
    ['SWING','/ŋ/ (ng)','/n/ (n)',0],['CLING','/ŋ/ (ng)','/n/ (n)',0],['FLING','/ŋ/ (ng)','/n/ (n)',0],
  ];
  for (const [word,o1,o2,ans] of conId) {
    const cleanWord = word.replace(/\[|\]/g, '');
    pool.push({
      instruction: 'Which consonant sound?',
      fields: { 
        word, 
        options: [o1,o2], 
        correctAnswerIndex: ans, 
        hint: 'Listen to the consonant carefully.',
        phoneticHint: getIpa(cleanWord)
      }
    });
  }

  // Category 3: Consonant clusters (120 words)
  const clusters = [
    ['STRENGTH','str-','st-',0],['SPLASH','spl-','sp-',0],['SCRIPT','scr-','sc-',0],
    ['SPRAY','spr-','sp-',0],['STRAP','str-','st-',0],['STREAM','str-','st-',0],
    ['STREET','str-','st-',0],['STRETCH','str-','st-',0],['STRIKE','str-','st-',0],
    ['STRIPE','str-','st-',0],['STRIVE','str-','st-',0],['STROKE','str-','st-',0],
    ['SPRING','spr-','sp-',0],['SPREAD','spr-','sp-',0],['SPRINT','spr-','sp-',0],
    ['SPROUT','spr-','sp-',0],['SPRUCE','spr-','sp-',0],['SPRINKLE','spr-','sp-',0],
    ['SPLIT','spl-','sp-',0],['SPLENDID','spl-','sp-',0],['SPLICE','spl-','sp-',0],
    ['SPLINT','spl-','sp-',0],['SPLURGE','spl-','sp-',0],['SPLOTCH','spl-','sp-',0],
    ['SCREAM','scr-','sc-',0],['SCREEN','scr-','sc-',0],['SCREW','scr-','sc-',0],
    ['SCROLL','scr-','sc-',0],['SCRUB','scr-','sc-',0],['SCRATCH','scr-','sc-',0],
    ['SQUASH','squ-','sq-',0],['SQUARE','squ-','sq-',0],['SQUEEZE','squ-','sq-',0],
    ['SQUID','squ-','sq-',0],['SQUINT','squ-','sq-',0],['SQUIRREL','squ-','sq-',0],
    ['BLEND','bl-','b-',0],['BLANK','bl-','b-',0],['BLAST','bl-','b-',0],
    ['BLAZE','bl-','b-',0],['BLEED','bl-','b-',0],['BLESS','bl-','b-',0],
    ['BLIND','bl-','b-',0],['BLOCK','bl-','b-',0],['BLOOM','bl-','b-',0],
    ['CLAP','cl-','c-',0],['CLAIM','cl-','c-',0],['CLASH','cl-','c-',0],
    ['CLEAN','cl-','c-',0],['CLEAR','cl-','c-',0],['CLIMB','cl-','c-',0],
    ['CLOSE','cl-','c-',0],['CLOUD','cl-','c-',0],['CLOWN','cl-','c-',0],
    ['FLAIR','fl-','f-',0],['FLAME','fl-','f-',0],['FLASH','fl-','f-',0],
    ['FLAT','fl-','f-',0],['FLEET','fl-','f-',0],['FLIGHT','fl-','f-',0],
    ['FLOAT','fl-','f-',0],['FLOOR','fl-','f-',0],['FLOW','fl-','f-',0],
    ['GLAD','gl-','g-',0],['GLANCE','gl-','g-',0],['GLARE','gl-','g-',0],
    ['GLASS','gl-','g-',0],['GLEAM','gl-','g-',0],['GLOBE','gl-','g-',0],
    ['GLOW','gl-','g-',0],['GLUE','gl-','g-',0],['GLIDE','gl-','g-',0],
    ['PLAIT','pl-','p-',0],['PLAN','pl-','p-',0],['PLANT','pl-','p-',0],
    ['PLATE','pl-','p-',0],['PLAY','pl-','p-',0],['PLEASE','pl-','p-',0],
    ['PLOT','pl-','p-',0],['PLUCK','pl-','p-',0],['PLUG','pl-','p-',0],
    ['SLIP','sl-','s-',0],['SLIDE','sl-','s-',0],['SLIM','sl-','s-',0],
    ['SLOPE','sl-','s-',0],['SLOW','sl-','s-',0],['SLAP','sl-','s-',0],
    ['TRAY','tr-','t-',0],['TRACK','tr-','t-',0],['TRADE','tr-','t-',0],
    ['TRAIL','tr-','t-',0],['TRAIN','tr-','t-',0],['TRAP','tr-','t-',0],
    ['TREAT','tr-','t-',0],['TREE','tr-','t-',0],['TREND','tr-','t-',0],
    ['TRICK','tr-','t-',0],['TRIP','tr-','t-',0],['TRIUMPH','tr-','t-',0],
    ['DRAFT','dr-','d-',0],['DRAIN','dr-','d-',0],['DRAMA','dr-','d-',0],
    ['DRAPE','dr-','d-',0],['DRAW','dr-','d-',0],['DREAM','dr-','d-',0],
    ['DRESS','dr-','d-',0],['DRIFT','dr-','d-',0],['DRINK','dr-','d-',0],
    ['DRIVE','dr-','d-',0],['DROP','dr-','d-',0],['DRUM','dr-','d-',0],
    ['GRAB','gr-','g-',0],['GRACE','gr-','g-',0],['GRADE','gr-','g-',0],
    ['GRAIN','gr-','g-',0],['GRAND','gr-','g-',0],['GRANT','gr-','g-',0],
    ['GRAPE','gr-','g-',0],['GRAPH','gr-','g-',0],['GRASP','gr-','g-',0],
    ['GRASS','gr-','g-',0],['GRAVE','gr-','g-',0],['GREAT','gr-','g-',0],
    ['GREEN','gr-','g-',0],['GREET','gr-','g-',0],['GRID','gr-','g-',0],
    ['GRILL','gr-','g-',0],['GRIN','gr-','g-',0],['GRIP','gr-','g-',0],
    ['GROUND','gr-','g-',0],['GROUP','gr-','g-',0],['GROW','gr-','g-',0],
  ];
  for (const [word,o1,o2,ans] of clusters) {
    const cleanWord = word.replace(/\[|\]/g, '');
    pool.push({
      instruction: 'Which consonant cluster?',
      fields: { 
        word, 
        options: [o1,o2], 
        correctAnswerIndex: ans, 
        hint: 'Count the consonants at the start.',
        phoneticHint: getIpa(cleanWord)
      }
    });
  }

  // Category 4: Silent consonants (120 words)
  const silent = [
    ['KNIGHT','K','N',0],['WRITE','W','R',0],['LISTEN','T','L',0],['CASTLE','T','C',0],
    ['COMB','B','C',0],['DOUBT','B','D',0],['PSALM','P','S',0],['GNAW','G','N',0],
    ['HOUR','H','R',0],['WRAP','W','R',0],['ISLAND','S','L',0],['SUBTLE','B','T',0],
    ['KNOW','K','N',0],['KNOCK','K','N',0],['KNEEL','K','N',0],['KNIFE','K','N',0],
    ['KNIT','K','N',0],['KNOB','K','N',0],['KNOT','K','N',0],['KNEE','K','N',0],
    ['WRONG','W','R',0],['WRIST','W','R',0],['WRECK','W','R',0],['WRESTLE','W','R',0],
    ['WRING','W','R',0],['WRINKLE','W','R',0],['WRATH','W','R',0],['WREATH','W','R',0],
    ['CLIMB','B','C',0],['LAMB','B','L',0],['BOMB','B','O',0],['TOMB','B','T',0],
    ['PLUMB','B','P',0],['CRUMB','B','C',0],['DUMB','B','D',0],['NUMB','B','N',0],
    ['THUMB','B','T',0],['LIMB','B','L',0],['DEBT','B','D',0],['RECEIPT','P','R',0],
    ['COLUMN','N','C',0],['AUTUMN','N','A',0],['HYMN','N','H',0],['CONDEMN','N','C',0],
    ['SOLEMN','N','S',0],['DAMN','N','D',0],['FOREIGN','G','F',0],['REIGN','G','R',0],
    ['SIGN','G','S',0],['DESIGN','G','D',0],['RESIGN','G','R',0],['ASSIGN','G','A',0],
    ['ALIGN','G','A',0],['MALIGN','G','M',0],['GNOME','G','N',0],['GNAT','G','N',0],
    ['GNASH','G','N',0],['GNU','G','N',0],['HONEST','H','O',0],['HONOR','H','O',0],
    ['HEIR','H','E',0],['HERB','H','E',0],['GHOST','H','G',0],['RHYME','H','R',0],
    ['RHYTHM','H','R',0],['RHINOCEROS','H','R',0],['RHETORICAL','H','R',0],['RHUBARB','H','R',0],
    ['MUSCLE','C','M',0],['SCENE','C','S',0],['SCIENCE','C','S',0],['SCISSORS','C','S',0],
    ['FASCINATE','C','F',0],['CRESCENT','C','R',0],['ASCEND','C','A',0],['DESCEND','C','D',0],
    ['WHISTLE','T','W',0],['THISTLE','T','H',0],['APOSTLE','T','A',0],['HUSTLE','T','H',0],
    ['BRISTLE','T','B',0],['RUSTLE','T','R',0],['JOSTLE','T','J',0],['NESTLE','T','N',0],
    ['FASTEN','T','F',0],['HASTEN','T','H',0],['MOISTEN','T','M',0],['GLISTEN','T','G',0],
    ['SOFTEN','T','S',0],['OFTEN','T','O',0],['CHRISTMAS','T','C',0],['MORTGAGE','T','M',0],
    ['CUPBOARD','P','C',0],['RASPBERRY','P','R',0],['PNEUMONIA','P','N',0],['PSYCHOLOGY','P','S',0],
    ['PTERODACTYL','P','T',0],['PSEUDONYM','P','S',0],['TALK','L','T',0],['WALK','L','W',0],
    ['CHALK','L','C',0],['FOLK','L','F',0],['YOLK','L','Y',0],['CALM','L','C',0],
    ['PALM','L','P',0],['BALM','L','B',0],['SALMON','L','S',0],['HALF','L','H',0],
    ['CALF','L','C',0],['COULD','L','C',0],['WOULD','L','W',0],['SHOULD','L','S',0],
    ['SWORD','W','S',0],['ANSWER','W','A',0],['TWO','W','T',0],['WHOLE','W','H',0],
    ['WHO','W','H',0],['WHOM','W','H',0],['WHOSE','W','H',0],['AISLE','S','A',0],
    ['DEBRIS','S','D',0],['BOURGEOIS','S','B',0],['CORPS','S','C',0],['COUP','P','C',0],
    ['BALLET','T','B',0],['BOUQUET','T','B',0],['DEPOT','T','D',0],['RAPPORT','T','R',0],
  ];
  for (const [word,ans1,ans2,ci] of silent) {
    const cleanWord = word.replace(/\[|\]/g, '');
    pool.push({
      instruction: 'Which consonant is silent?',
      fields: { 
        word, 
        options: [ans1,ans2], 
        correctAnswerIndex: ci, 
        hint: `The ${ans1} is not pronounced.`,
        phoneticHint: getIpa(cleanWord)
      }
    });
  }

  // Category 5: Aspiration & release (fill to 600)
  const asp = [
    ['PEN','Aspirated /p/','Unaspirated /p/',0],['PIN','Aspirated /p/','Unaspirated /p/',0],
    ['PIG','Aspirated /p/','Unaspirated /p/',0],['POT','Aspirated /p/','Unaspirated /p/',0],
    ['PAD','Aspirated /p/','Unaspirated /p/',0],['PARK','Aspirated /p/','Unaspirated /p/',0],
    ['PAIR','Aspirated /p/','Unaspirated /p/',0],['PACE','Aspirated /p/','Unaspirated /p/',0],
    ['PACK','Aspirated /p/','Unaspirated /p/',0],['PAGE','Aspirated /p/','Unaspirated /p/',0],
    ['PAIN','Aspirated /p/','Unaspirated /p/',0],['PALE','Aspirated /p/','Unaspirated /p/',0],
    ['SPAN','Unaspirated /p/','Aspirated /p/',0],['SPIN','Unaspirated /p/','Aspirated /p/',0],
    ['SPIT','Unaspirated /p/','Aspirated /p/',0],['SPOT','Unaspirated /p/','Aspirated /p/',0],
    ['SPADE','Unaspirated /p/','Aspirated /p/',0],['SPARE','Unaspirated /p/','Aspirated /p/',0],
    ['SPEAK','Unaspirated /p/','Aspirated /p/',0],['SPEED','Unaspirated /p/','Aspirated /p/',0],
    ['SPELL','Unaspirated /p/','Aspirated /p/',0],['SPEND','Unaspirated /p/','Aspirated /p/',0],
    ['SPILL','Unaspirated /p/','Aspirated /p/',0],['SPIRIT','Unaspirated /p/','Aspirated /p/',0],
    ['TEN','Aspirated /t/','Unaspirated /t/',0],['TIN','Aspirated /t/','Unaspirated /t/',0],
    ['TIP','Aspirated /t/','Unaspirated /t/',0],['TOP','Aspirated /t/','Unaspirated /t/',0],
    ['TAP','Aspirated /t/','Unaspirated /t/',0],['TAPE','Aspirated /t/','Unaspirated /t/',0],
    ['TAKE','Aspirated /t/','Unaspirated /t/',0],['TAIL','Aspirated /t/','Unaspirated /t/',0],
    ['TALK','Aspirated /t/','Unaspirated /t/',0],['TANK','Aspirated /t/','Unaspirated /t/',0],
    ['TASK','Aspirated /t/','Unaspirated /t/',0],['TEAM','Aspirated /t/','Unaspirated /t/',0],
    ['STEM','Unaspirated /t/','Aspirated /t/',0],['STEP','Unaspirated /t/','Aspirated /t/',0],
    ['STICK','Unaspirated /t/','Aspirated /t/',0],['STILL','Unaspirated /t/','Aspirated /t/',0],
    ['STOCK','Unaspirated /t/','Aspirated /t/',0],['STONE','Unaspirated /t/','Aspirated /t/',0],
    ['STOP','Unaspirated /t/','Aspirated /t/',0],['STORE','Unaspirated /t/','Aspirated /t/',0],
    ['STORM','Unaspirated /t/','Aspirated /t/',0],['STORY','Unaspirated /t/','Aspirated /t/',0],
    ['STOVE','Unaspirated /t/','Aspirated /t/',0],['STUB','Unaspirated /t/','Aspirated /t/',0],
    ['KIT','Aspirated /k/','Unaspirated /k/',0],['KEY','Aspirated /k/','Unaspirated /k/',0],
    ['KITE','Aspirated /k/','Unaspirated /k/',0],['KEEN','Aspirated /k/','Unaspirated /k/',0],
    ['KEEP','Aspirated /k/','Unaspirated /k/',0],['KICK','Aspirated /k/','Unaspirated /k/',0],
    ['KILL','Aspirated /k/','Unaspirated /k/',0],['KIND','Aspirated /k/','Unaspirated /k/',0],
    ['CAPE','Aspirated /k/','Unaspirated /k/',0],['CAKE','Aspirated /k/','Unaspirated /k/',0],
    ['CALL','Aspirated /k/','Unaspirated /k/',0],['CAMP','Aspirated /k/','Unaspirated /k/',0],
    ['SKIP','Unaspirated /k/','Aspirated /k/',0],['SKILL','Unaspirated /k/','Aspirated /k/',0],
    ['SKIN','Unaspirated /k/','Aspirated /k/',0],['SKIT','Unaspirated /k/','Aspirated /k/',0],
    ['SKULL','Unaspirated /k/','Aspirated /k/',0],['SKI','Unaspirated /k/','Aspirated /k/',0],
    ['SKATE','Unaspirated /k/','Aspirated /k/',0],['SCOPE','Unaspirated /k/','Aspirated /k/',0],
    ['SCORE','Unaspirated /k/','Aspirated /k/',0],['SCOUT','Unaspirated /k/','Aspirated /k/',0],
    ['SCAR','Unaspirated /k/','Aspirated /k/',0],['SCALE','Unaspirated /k/','Aspirated /k/',0],
  ];
  for (const [word,o1,o2,ans] of asp) {
    const cleanWord = word.replace(/\[|\]/g, '');
    pool.push({
      instruction: 'Identify the consonant type.',
      fields: { 
        word, 
        options: [o1,o2], 
        correctAnswerIndex: ans, 
        hint: 'After s, stops lose aspiration.',
        phoneticHint: getIpa(cleanWord)
      }
    });
  }

  
  // === AUTO-EXPANDED ENTRIES ===
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"PRISM","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("PRISM")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"WISDOM","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("WISDOM")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"HUSBAND","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("HUSBAND")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"PRISON","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("PRISON")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"COUSIN","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("COUSIN")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"DESERT","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("DESERT")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"PRESENT","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("PRESENT")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"MUSEUM","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("MUSEUM")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"MUSIC","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("MUSIC")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"REASON","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("REASON")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"SEASON","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("SEASON")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"POISON","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("POISON")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"DOZEN","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("DOZEN")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"FROZEN","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("FROZEN")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"CHOSEN","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("CHOSEN")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"RESIGN","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("RESIGN")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"DESIGN","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("DESIGN")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"OBSERVE","options":["/z/ (z)","/s/ (s)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("OBSERVE")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"ABSORB","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("ABSORB")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"DESCRIBE","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("DESCRIBE")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"DISTURB","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("DISTURB")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"GLOBE","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("GLOBE")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"PROBE","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("PROBE")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"ROBE","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("ROBE")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"TUBE","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("TUBE")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"CUBE","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("CUBE")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"VERB","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("VERB")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"HERB","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("HERB")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"CURB","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("CURB")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"SUBURB","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("SUBURB")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"BLEND","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("BLEND")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"BRAND","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("BRAND")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"BREED","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("BREED")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"BRIEF","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("BRIEF")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"BROAD","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("BROAD")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"BRONZE","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("BRONZE")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"BROTH","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("BROTH")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"BRUISE","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("BRUISE")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"BURDEN","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("BURDEN")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"BURST","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("BURST")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"BUSTLE","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("BUSTLE")}});
  pool.push({"instruction":"Which consonant sound?","fields":{"word":"BLISTER","options":["/b/ (b)","/p/ (p)"],"correctAnswerIndex":0,"hint":"Listen to the consonant carefully.","phoneticHint":getIpa("BLISTER")}});
console.log(`  consonantClarity pool: ${pool.length}`);
  return pool;
};
