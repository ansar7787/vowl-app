// Minimal Pairs: 600 unique word-pair questions
const getIpa = require(__dirname + '/get_ipa.js');
module.exports = function() {
  const pool = [];
  const pairs = [
    // /ɪ/ vs /iː/ (short vs long vowel)
    ['ship','sheep','Which word has the /ɪ/ sound?',0,'Short vowel.'],['bit','beat','Which has the /ɪ/ sound?',0,'Short vowel.'],
    ['sit','seat','Which has the /ɪ/ sound?',0,'Short vowel.'],['fit','feet','Which has the /ɪ/ sound?',0,'Short vowel.'],
    ['hit','heat','Which has the /ɪ/ sound?',0,'Short vowel.'],['lip','leap','Which has the /ɪ/ sound?',0,'Short vowel.'],
    ['slip','sleep','Which has the /ɪ/ sound?',0,'Short vowel.'],['fill','feel','Which has the /ɪ/ sound?',0,'Short vowel.'],
    ['mill','meal','Which has the /ɪ/ sound?',0,'Short vowel.'],['pill','peel','Which has the /ɪ/ sound?',0,'Short vowel.'],
    ['rich','reach','Which has the /ɪ/ sound?',0,'Short vowel.'],['pick','peek','Which has the /ɪ/ sound?',0,'Short vowel.'],
    ['wick','week','Which has the /ɪ/ sound?',0,'Short vowel.'],['dip','deep','Which has the /ɪ/ sound?',0,'Short vowel.'],
    ['grin','green','Which has the /ɪ/ sound?',0,'Short vowel.'],['sin','seen','Which has the /ɪ/ sound?',0,'Short vowel.'],
    ['tin','teen','Which has the /ɪ/ sound?',0,'Short vowel.'],['bin','bean','Which has the /ɪ/ sound?',0,'Short vowel.'],
    ['dim','deem','Which has the /ɪ/ sound?',0,'Short vowel.'],['lid','lead','Which has the /ɪ/ sound?',0,'Short vowel.'],
    // /e/ vs /æ/
    ['pen','pan','Which has the /e/ sound?',0,'Front mid vowel.'],['bed','bad','Which has the /e/ sound?',0,'Front mid vowel.'],
    ['men','man','Which has the /e/ sound?',0,'Front mid vowel.'],['ten','tan','Which has the /e/ sound?',0,'Front mid vowel.'],
    ['pet','pat','Which has the /e/ sound?',0,'Front mid vowel.'],['set','sat','Which has the /e/ sound?',0,'Front mid vowel.'],
    ['bet','bat','Which has the /e/ sound?',0,'Front mid vowel.'],['met','mat','Which has the /e/ sound?',0,'Front mid vowel.'],
    ['net','gnat','Which has the /e/ sound?',0,'Front mid vowel.'],['led','lad','Which has the /e/ sound?',0,'Front mid vowel.'],
    ['red','rad','Which has the /e/ sound?',0,'Front mid vowel.'],['send','sand','Which has the /e/ sound?',0,'Front mid vowel.'],
    ['lend','land','Which has the /e/ sound?',0,'Front mid vowel.'],['mess','mass','Which has the /e/ sound?',0,'Front mid vowel.'],
    ['pest','past','Which has the /e/ sound?',0,'Front mid vowel.'],['trek','track','Which has the /e/ sound?',0,'Front mid vowel.'],
    ['wren','ran','Which has the /e/ sound?',0,'Front mid vowel.'],['den','Dan','Which has the /e/ sound?',0,'Front mid vowel.'],
    ['peg','pag','Which has the /e/ sound?',0,'Front mid vowel.'],['beg','bag','Which has the /e/ sound?',0,'Front mid vowel.'],
    // /æ/ vs /ʌ/
    ['cat','cut','Which has the /æ/ sound?',0,'Front open vowel.'],['bat','but','Which has the /æ/ sound?',0,'Front open vowel.'],
    ['hat','hut','Which has the /æ/ sound?',0,'Front open vowel.'],['cap','cup','Which has the /æ/ sound?',0,'Front open vowel.'],
    ['ran','run','Which has the /æ/ sound?',0,'Front open vowel.'],['fan','fun','Which has the /æ/ sound?',0,'Front open vowel.'],
    ['bam','bum','Which has the /æ/ sound?',0,'Front open vowel.'],['dam','dumb','Which has the /æ/ sound?',0,'Front open vowel.'],
    ['bad','bud','Which has the /æ/ sound?',0,'Front open vowel.'],['mass','muss','Which has the /æ/ sound?',0,'Front open vowel.'],
    ['match','much','Which has the /æ/ sound?',0,'Front open vowel.'],['lag','lug','Which has the /æ/ sound?',0,'Front open vowel.'],
    ['rag','rug','Which has the /æ/ sound?',0,'Front open vowel.'],['ban','bun','Which has the /æ/ sound?',0,'Front open vowel.'],
    ['tan','ton','Which has the /æ/ sound?',0,'Front open vowel.'],['map','mop','Which has the /æ/ sound?',0,'Front open vowel.'],
    ['tap','top','Which has the /æ/ sound?',0,'Front open vowel.'],['lack','luck','Which has the /æ/ sound?',0,'Front open vowel.'],
    ['pack','puck','Which has the /æ/ sound?',0,'Front open vowel.'],['sack','suck','Which has the /æ/ sound?',0,'Front open vowel.'],
    // Voiced vs voiceless initial consonants /p/ vs /b/
    ['pin','bin','Which starts voiceless?',0,'No vibration.'],['pie','buy','Which starts voiceless?',0,'No vibration.'],
    ['pat','bat','Which starts voiceless?',0,'No vibration.'],['park','bark','Which starts voiceless?',0,'No vibration.'],
    ['pack','back','Which starts voiceless?',0,'No vibration.'],['pear','bear','Which starts voiceless?',0,'No vibration.'],
    ['pole','bowl','Which starts voiceless?',0,'No vibration.'],['pest','best','Which starts voiceless?',0,'No vibration.'],
    ['pet','bet','Which starts voiceless?',0,'No vibration.'],['pit','bit','Which starts voiceless?',0,'No vibration.'],
    ['pull','bull','Which starts voiceless?',0,'No vibration.'],['punt','bunt','Which starts voiceless?',0,'No vibration.'],
    ['pail','bail','Which starts voiceless?',0,'No vibration.'],['path','bath','Which starts voiceless?',0,'No vibration.'],
    ['peach','beach','Which starts voiceless?',0,'No vibration.'],['pig','big','Which starts voiceless?',0,'No vibration.'],
    ['pan','ban','Which starts voiceless?',0,'No vibration.'],['pond','bond','Which starts voiceless?',0,'No vibration.'],
    ['pour','bore','Which starts voiceless?',0,'No vibration.'],['punk','bunk','Which starts voiceless?',0,'No vibration.'],
    // /t/ vs /d/
    ['ten','den','Which starts voiceless?',0,'/t/ no vibration.'],['tie','die','Which starts voiceless?',0,'/t/ no vibration.'],
    ['tip','dip','Which starts voiceless?',0,'/t/ no vibration.'],['town','down','Which starts voiceless?',0,'/t/ no vibration.'],
    ['tear','dear','Which starts voiceless?',0,'/t/ no vibration.'],['tale','dale','Which starts voiceless?',0,'/t/ no vibration.'],
    ['tug','dug','Which starts voiceless?',0,'/t/ no vibration.'],['till','dill','Which starts voiceless?',0,'/t/ no vibration.'],
    ['time','dime','Which starts voiceless?',0,'/t/ no vibration.'],['toe','doe','Which starts voiceless?',0,'/t/ no vibration.'],
    ['tank','dank','Which starts voiceless?',0,'/t/ no vibration.'],['tare','dare','Which starts voiceless?',0,'/t/ no vibration.'],
    ['toll','doll','Which starts voiceless?',0,'/t/ no vibration.'],['tuck','duck','Which starts voiceless?',0,'/t/ no vibration.'],
    ['tusk','dusk','Which starts voiceless?',0,'/t/ no vibration.'],['tab','dab','Which starts voiceless?',0,'/t/ no vibration.'],
    ['tart','dart','Which starts voiceless?',0,'/t/ no vibration.'],['tomb','doom','Which starts voiceless?',0,'/t/ no vibration.'],
    ['trunk','drunk','Which starts voiceless?',0,'/t/ no vibration.'],['trip','drip','Which starts voiceless?',0,'/t/ no vibration.'],
    // /k/ vs /g/
    ['coat','goat','Which starts voiceless?',0,'/k/ is voiceless.'],['came','game','Which starts with /k/?',0,'Voiceless velar.'],
    ['cold','gold','Which starts voiceless?',0,'/k/ is voiceless.'],['cap','gap','Which starts voiceless?',0,'/k/ is voiceless.'],
    ['curl','girl','Which starts voiceless?',0,'/k/ is voiceless.'],['cave','gave','Which starts voiceless?',0,'/k/ is voiceless.'],
    ['class','glass','Which starts voiceless?',0,'/k/ is voiceless.'],['crew','grew','Which starts voiceless?',0,'/k/ is voiceless.'],
    ['crow','grow','Which starts voiceless?',0,'/k/ is voiceless.'],['crate','great','Which starts voiceless?',0,'/k/ is voiceless.'],
    ['card','guard','Which starts voiceless?',0,'/k/ is voiceless.'],['core','gore','Which starts voiceless?',0,'/k/ is voiceless.'],
    ['could','good','Which starts voiceless?',0,'/k/ is voiceless.'],['cut','gut','Which starts voiceless?',0,'/k/ is voiceless.'],
    ['clue','glue','Which starts voiceless?',0,'/k/ is voiceless.'],['crab','grab','Which starts voiceless?',0,'/k/ is voiceless.'],
    ['crane','grain','Which starts voiceless?',0,'/k/ is voiceless.'],['crash','gash','Which starts voiceless?',0,'/k/ is voiceless.'],
    ['crime','grime','Which starts voiceless?',0,'/k/ is voiceless.'],['crust','gust','Which starts voiceless?',0,'/k/ is voiceless.'],
    // /f/ vs /v/
    ['fan','van','Which starts with /f/?',0,'Voiceless.'],['fast','vast','Which starts with /f/?',0,'Voiceless.'],
    ['few','view','Which starts with /f/?',0,'Voiceless.'],['fine','vine','Which starts with /f/?',0,'Voiceless.'],
    ['fail','veil','Which starts with /f/?',0,'Voiceless.'],['fairy','vary','Which starts with /f/?',0,'Voiceless.'],
    ['fault','vault','Which starts with /f/?',0,'Voiceless.'],['feel','veal','Which starts with /f/?',0,'Voiceless.'],
    ['ferry','very','Which starts with /f/?',0,'Voiceless.'],['file','vile','Which starts with /f/?',0,'Voiceless.'],
    ['foul','vowel','Which starts with /f/?',0,'Voiceless.'],['fox','vox','Which starts with /f/?',0,'Voiceless.'],
    ['safe','save','Which ends voiceless?',0,'Voiceless final.'],['leaf','leave','Which ends voiceless?',0,'Voiceless final.'],
    ['half','halve','Which ends voiceless?',0,'Voiceless final.'],['life','live','Which ends voiceless?',0,'Voiceless final.'],
    ['proof','prove','Which ends voiceless?',0,'Voiceless final.'],['surf','serve','Which ends voiceless?',0,'Voiceless final.'],
    ['belief','believe','Which ends voiceless?',0,'Voiceless final.'],['relief','relieve','Which ends voiceless?',0,'Voiceless final.'],
    // /s/ vs /z/
    ['sue','zoo','Which starts voiceless?',0,'/s/ is voiceless.'],['seal','zeal','Which starts voiceless?',0,'/s/ is voiceless.'],
    ['sip','zip','Which starts voiceless?',0,'/s/ is voiceless.'],['sink','zinc','Which starts voiceless?',0,'/s/ is voiceless.'],
    ['sap','zap','Which starts voiceless?',0,'/s/ is voiceless.'],['sag','zag','Which starts voiceless?',0,'/s/ is voiceless.'],
    ['bus','buzz','Which ends voiceless?',0,'/s/ is voiceless.'],['rice','rise','Which ends voiceless?',0,'/s/ is voiceless.'],
    ['price','prize','Which ends voiceless?',0,'/s/ is voiceless.'],['race','raise','Which ends voiceless?',0,'/s/ is voiceless.'],
    ['peace','peas','Which ends voiceless?',0,'/s/ is voiceless.'],['lace','laze','Which ends voiceless?',0,'/s/ is voiceless.'],
    ['dose','doze','Which ends voiceless?',0,'/s/ is voiceless.'],['loose','lose','Which ends voiceless?',0,'/s/ is voiceless.'],
    ['face','phase','Which ends voiceless?',0,'/s/ is voiceless.'],['ice','eyes','Which ends voiceless?',0,'/s/ is voiceless.'],
    ['place','plays','Which ends voiceless?',0,'/s/ is voiceless.'],['force','fours','Which ends voiceless?',0,'/s/ is voiceless.'],
    ['hence','hens','Which ends voiceless?',0,'/s/ is voiceless.'],['pence','pens','Which ends voiceless?',0,'/s/ is voiceless.'],
    // /θ/ vs /t/
    ['thin','tin','Which has the /θ/ sound?',0,'Tongue between teeth.'],['three','tree','Which has the /θ/ sound?',0,'Dental fricative.'],
    ['thank','tank','Which has the /θ/ sound?',0,'Tongue between teeth.'],['thick','tick','Which has the /θ/ sound?',0,'Dental fricative.'],
    ['thought','taught','Which has the /θ/ sound?',0,'Dental fricative.'],['throw','trow','Which has the /θ/ sound?',0,'Dental fricative.'],
    ['thaw','taw','Which has the /θ/ sound?',0,'Dental fricative.'],['theme','team','Which has the /θ/ sound?',0,'Dental fricative.'],
    ['thigh','tie','Which has the /θ/ sound?',0,'Dental fricative.'],['thorn','torn','Which has the /θ/ sound?',0,'Dental fricative.'],
    ['thud','thud','Which has the /θ/ sound?',0,'Dental fricative.'],['thumb','tum','Which has the /θ/ sound?',0,'Dental fricative.'],
    ['bath','bat','Which ends with /θ/?',0,'Dental ending.'],['math','mat','Which ends with /θ/?',0,'Dental ending.'],
    ['moth','mot','Which ends with /θ/?',0,'Dental ending.'],['path','pat','Which ends with /θ/?',0,'Dental ending.'],
    ['teeth','teat','Which ends with /θ/?',0,'Dental ending.'],['birth','Bert','Which ends with /θ/?',0,'Dental ending.'],
    ['earth','art','Which ends with /θ/?',0,'Dental ending.'],['worth','wort','Which ends with /θ/?',0,'Dental ending.'],
    // /l/ vs /r/
    ['light','right','Which starts with /l/?',0,'Lateral sound.'],['long','wrong','Which starts with /l/?',0,'Lateral sound.'],
    ['lack','rack','Which starts with /l/?',0,'Lateral.'],['lake','rake','Which starts with /l/?',0,'Lateral.'],
    ['lamp','ramp','Which starts with /l/?',0,'Lateral.'],['lane','rain','Which starts with /l/?',0,'Lateral.'],
    ['late','rate','Which starts with /l/?',0,'Lateral.'],['lead','read','Which starts with /l/?',0,'Lateral.'],
    ['leaf','reef','Which starts with /l/?',0,'Lateral.'],['lean','wren','Which starts with /l/?',0,'Lateral.'],
    ['lip','rip','Which starts with /l/?',0,'Lateral.'],['lock','rock','Which starts with /l/?',0,'Lateral.'],
    ['loom','room','Which starts with /l/?',0,'Lateral.'],['lump','rump','Which starts with /l/?',0,'Lateral.'],
    ['lust','rust','Which starts with /l/?',0,'Lateral.'],['lot','rot','Which starts with /l/?',0,'Lateral.'],
    ['low','row','Which starts with /l/?',0,'Lateral.'],['lye','rye','Which starts with /l/?',0,'Lateral.'],
    ['lobe','robe','Which starts with /l/?',0,'Lateral.'],['load','road','Which starts with /l/?',0,'Lateral.'],
    // /w/ vs /v/
    ['wine','vine','Which starts with /w/?',0,'Bilabial approximant.'],['wet','vet','Which starts with /w/?',0,'Rounded lips.'],
    ['wail','veil','Which starts with /w/?',0,'Bilabial.'],['wane','vane','Which starts with /w/?',0,'Bilabial.'],
    ['wary','vary','Which starts with /w/?',0,'Bilabial.'],['wend','vend','Which starts with /w/?',0,'Bilabial.'],
    ['west','vest','Which starts with /w/?',0,'Bilabial.'],['wile','vile','Which starts with /w/?',0,'Bilabial.'],
    ['wiper','viper','Which starts with /w/?',0,'Bilabial.'],['wise','vise','Which starts with /w/?',0,'Bilabial.'],
    ['wow','vow','Which starts with /w/?',0,'Bilabial.'],['worse','verse','Which starts with /w/?',0,'Bilabial.'],
    ['weal','veal','Which starts with /w/?',0,'Bilabial.'],['while','vial','Which starts with /w/?',0,'Bilabial.'],
    ['wall','vol','Which starts with /w/?',0,'Bilabial.'],['welt','veldt','Which starts with /w/?',0,'Bilabial.'],
    ['wane','vein','Which starts with /w/?',0,'Bilabial.'],['weep','veep','Which starts with /w/?',0,'Bilabial.'],
    ['wheel','veal','Which starts with /w/?',0,'Bilabial.'],['whim','vim','Which starts with /w/?',0,'Bilabial.'],
    // /m/ vs /n/
    ['mail','nail','Which starts with /m/?',0,'Bilabial nasal.'],['map','nap','Which starts with /m/?',0,'Bilabial nasal.'],
    ['mat','gnat','Which starts with /m/?',0,'Bilabial nasal.'],['mine','nine','Which starts with /m/?',0,'Bilabial nasal.'],
    ['mow','know','Which starts with /m/?',0,'Bilabial nasal.'],['mice','nice','Which starts with /m/?',0,'Bilabial nasal.'],
    ['mane','neigh','Which starts with /m/?',0,'Bilabial nasal.'],['mark','nark','Which starts with /m/?',0,'Bilabial nasal.'],
    ['mash','gnash','Which starts with /m/?',0,'Bilabial nasal.'],['might','night','Which starts with /m/?',0,'Bilabial nasal.'],
    ['mock','knock','Which starts with /m/?',0,'Bilabial nasal.'],['mood','nude','Which starts with /m/?',0,'Bilabial nasal.'],
    ['more','nor','Which starts with /m/?',0,'Bilabial nasal.'],['mug','nug','Which starts with /m/?',0,'Bilabial nasal.'],
    ['must','nut','Which starts with /m/?',0,'Bilabial nasal.'],['myth','knit','Which starts with /m/?',0,'Bilabial nasal.'],
    ['mend','end','Which starts with /m/?',0,'Bilabial nasal.'],['meal','kneel','Which starts with /m/?',0,'Bilabial nasal.'],
    ['mare','snare','Which starts with /m/?',0,'Bilabial nasal.'],['melt','knelt','Which starts with /m/?',0,'Bilabial nasal.'],
    // /tʃ/ vs /ʃ/
    ['chin','shin','Which starts with /tʃ/?',0,'Affricate.'],['chop','shop','Which starts with /tʃ/?',0,'Affricate.'],
    ['cheap','sheep','Which starts with /tʃ/?',0,'Affricate.'],['chair','share','Which starts with /tʃ/?',0,'Affricate.'],
    ['cheese','she','Which starts with /tʃ/?',0,'Affricate.'],['chose','shows','Which starts with /tʃ/?',0,'Affricate.'],
    ['chunk','shunk','Which starts with /tʃ/?',0,'Affricate.'],['charm','sham','Which starts with /tʃ/?',0,'Affricate.'],
    ['cheat','sheet','Which starts with /tʃ/?',0,'Affricate.'],['chess','mesh','Which starts with /tʃ/?',0,'Affricate.'],
    ['catch','cash','Which ends with /tʃ/?',0,'Affricate ending.'],['match','mash','Which ends with /tʃ/?',0,'Affricate ending.'],
    ['watch','wash','Which ends with /tʃ/?',0,'Affricate ending.'],['ditch','dish','Which ends with /tʃ/?',0,'Affricate ending.'],
    ['witch','wish','Which ends with /tʃ/?',0,'Affricate ending.'],['much','mush','Which ends with /tʃ/?',0,'Affricate ending.'],
    ['batch','bash','Which ends with /tʃ/?',0,'Affricate ending.'],['hatch','hash','Which ends with /tʃ/?',0,'Affricate ending.'],
    ['latch','lash','Which ends with /tʃ/?',0,'Affricate ending.'],['patch','pash','Which ends with /tʃ/?',0,'Affricate ending.'],
    // /ʊ/ vs /uː/
    ['pull','pool','Which has the short /ʊ/?',0,'Short vowel.'],['full','fool','Which has the short /ʊ/?',0,'Short vowel.'],
    ['look','Luke','Which has the short /ʊ/?',0,'Short vowel.'],['book','boot','Which has the short /ʊ/?',0,'Short vowel.'],
    ['cook','cool','Which has the short /ʊ/?',0,'Short vowel.'],['hood','hoot','Which has the short /ʊ/?',0,'Short vowel.'],
    ['wood','woot','Which has the short /ʊ/?',0,'Short vowel.'],['foot','food','Which has the short /ʊ/?',0,'Short vowel.'],
    ['good','goose','Which has the short /ʊ/?',0,'Short vowel.'],['wool','tool','Which has the short /ʊ/?',0,'Short vowel.'],
    ['hook','hoop','Which has the short /ʊ/?',0,'Short vowel.'],['nook','noon','Which has the short /ʊ/?',0,'Short vowel.'],
    ['soot','suit','Which has the short /ʊ/?',0,'Short vowel.'],['put','poot','Which has the short /ʊ/?',0,'Short vowel.'],
    ['bush','boost','Which has the short /ʊ/?',0,'Short vowel.'],['shook','shoot','Which has the short /ʊ/?',0,'Short vowel.'],
    ['took','tool','Which has the short /ʊ/?',0,'Short vowel.'],['brook','brood','Which has the short /ʊ/?',0,'Short vowel.'],
    ['crook','crude','Which has the short /ʊ/?',0,'Short vowel.'],['rook','root','Which has the short /ʊ/?',0,'Short vowel.'],
    // /ɒ/ vs /əʊ/
    ['cot','coat','Which has the short vowel?',0,'Short sound.'],['not','note','Which has the short vowel?',0,'Short sound.'],
    ['rod','road','Which has the short vowel?',0,'Short sound.'],['hop','hope','Which has the short vowel?',0,'Short sound.'],
    ['rob','robe','Which has the short vowel?',0,'Short sound.'],['cod','code','Which has the short vowel?',0,'Short sound.'],
    ['cop','cope','Which has the short vowel?',0,'Short sound.'],['got','goat','Which has the short vowel?',0,'Short sound.'],
    ['hot','host','Which has the short vowel?',0,'Short sound.'],['lot','loaf','Which has the short vowel?',0,'Short sound.'],
    ['mop','mope','Which has the short vowel?',0,'Short sound.'],['nod','node','Which has the short vowel?',0,'Short sound.'],
    ['pop','pope','Which has the short vowel?',0,'Short sound.'],['pot','post','Which has the short vowel?',0,'Short sound.'],
    ['rot','wrote','Which has the short vowel?',0,'Short sound.'],['shot','show','Which has the short vowel?',0,'Short sound.'],
    ['sod','sewed','Which has the short vowel?',0,'Short sound.'],['top','tope','Which has the short vowel?',0,'Short sound.'],
    ['tot','toast','Which has the short vowel?',0,'Short sound.'],['wok','woke','Which has the short vowel?',0,'Short sound.'],
  ];
  for (const [w1,w2,question,ans,hint] of pairs) {
    pool.push({
      instruction: 'Choose the word you hear.',
      fields: { word1:w1, word2:w2, ipa1: getIpa(w1), ipa2: getIpa(w2), question, options:[w1,w2], correctAnswerIndex:ans, hint }
    });
  }
  
  // === AUTO-EXPANDED ENTRIES ===
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"kit","word2":"keet","question":"Which has the /ɪ/ sound?","options":["kit","keet"],"correctAnswerIndex":0,"hint":"Short."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bid","word2":"bead","question":"Which has /ɪ/?","options":["bid","bead"],"correctAnswerIndex":0,"hint":"Short."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"did","word2":"deed","question":"Which has /ɪ/?","options":["did","deed"],"correctAnswerIndex":0,"hint":"Short."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"hid","word2":"heed","question":"Which has /ɪ/?","options":["hid","heed"],"correctAnswerIndex":0,"hint":"Short."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"lid","word2":"lead","question":"Which has /ɪ/?","options":["lid","lead"],"correctAnswerIndex":0,"hint":"Short."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"mid","word2":"mead","question":"Which has /ɪ/?","options":["mid","mead"],"correctAnswerIndex":0,"hint":"Short."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"rid","word2":"reed","question":"Which has /ɪ/?","options":["rid","reed"],"correctAnswerIndex":0,"hint":"Short."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"id","word2":"eed","question":"Which has /ɪ/?","options":["id","eed"],"correctAnswerIndex":0,"hint":"Short."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"had","word2":"head","question":"Which has /æ/?","options":["had","head"],"correctAnswerIndex":0,"hint":"Open front."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sad","word2":"said","question":"Which has /æ/?","options":["sad","said"],"correctAnswerIndex":0,"hint":"Open front."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"dad","word2":"dead","question":"Which has /æ/?","options":["dad","dead"],"correctAnswerIndex":0,"hint":"Open front."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"ban","word2":"Ben","question":"Which has /æ/?","options":["ban","Ben"],"correctAnswerIndex":0,"hint":"Open front."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"land","word2":"lend","question":"Which has /æ/?","options":["land","lend"],"correctAnswerIndex":0,"hint":"Open front."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"band","word2":"bend","question":"Which has /æ/?","options":["band","bend"],"correctAnswerIndex":0,"hint":"Open front."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sand","word2":"send","question":"Which has /æ/?","options":["sand","send"],"correctAnswerIndex":0,"hint":"Open front."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"grand","word2":"grend","question":"Which has /æ/?","options":["grand","grend"],"correctAnswerIndex":0,"hint":"Open front."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"cab","word2":"cap","question":"Which ends voiced?","options":["cab","cap"],"correctAnswerIndex":0,"hint":"Vocal cords vibrate."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"lab","word2":"lap","question":"Which ends voiced?","options":["lab","lap"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"tab","word2":"tap","question":"Which ends voiced?","options":["tab","tap"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"rib","word2":"rip","question":"Which ends voiced?","options":["rib","rip"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"rob","word2":"rope","question":"Which ends voiced?","options":["rob","rope"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"mob","word2":"mop","question":"Which ends voiced?","options":["mob","mop"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"cub","word2":"cup","question":"Which ends voiced?","options":["cub","cup"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"tub","word2":"tup","question":"Which ends voiced?","options":["tub","tup"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pig","word2":"pick","question":"Which ends voiced?","options":["pig","pick"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"wig","word2":"wick","question":"Which ends voiced?","options":["wig","wick"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"dig","word2":"Dick","question":"Which ends voiced?","options":["dig","Dick"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"rug","word2":"ruck","question":"Which ends voiced?","options":["rug","ruck"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bug","word2":"buck","question":"Which ends voiced?","options":["bug","buck"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"mug","word2":"muck","question":"Which ends voiced?","options":["mug","muck"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"dog","word2":"dock","question":"Which ends voiced?","options":["dog","dock"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"log","word2":"lock","question":"Which ends voiced?","options":["log","lock"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bag","word2":"back","question":"Which ends voiced?","options":["bag","back"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"tag","word2":"tack","question":"Which ends voiced?","options":["tag","tack"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"had","word2":"hat","question":"Which ends voiced?","options":["had","hat"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"mad","word2":"mat","question":"Which ends voiced?","options":["mad","mat"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bad","word2":"bat","question":"Which ends voiced?","options":["bad","bat"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sad","word2":"sat","question":"Which ends voiced?","options":["sad","sat"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"red","word2":"wet","question":"Which ends voiced?","options":["red","wet"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bid","word2":"bit","question":"Which ends voiced?","options":["bid","bit"],"correctAnswerIndex":0,"hint":"Vibration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"caught","word2":"cot","question":"Which has /ɔː/?","options":["caught","cot"],"correctAnswerIndex":0,"hint":"Long rounded."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bought","word2":"bot","question":"Which has /ɔː/?","options":["bought","bot"],"correctAnswerIndex":0,"hint":"Long."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"taught","word2":"tot","question":"Which has /ɔː/?","options":["taught","tot"],"correctAnswerIndex":0,"hint":"Long."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"nought","word2":"not","question":"Which has /ɔː/?","options":["nought","not"],"correctAnswerIndex":0,"hint":"Long."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"wrought","word2":"rot","question":"Which has /ɔː/?","options":["wrought","rot"],"correctAnswerIndex":0,"hint":"Long."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sought","word2":"sot","question":"Which has /ɔː/?","options":["sought","sot"],"correctAnswerIndex":0,"hint":"Long."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"thought","word2":"thot","question":"Which has /ɔː/?","options":["thought","thot"],"correctAnswerIndex":0,"hint":"Long."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"fought","word2":"fot","question":"Which has /ɔː/?","options":["fought","fot"],"correctAnswerIndex":0,"hint":"Long."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sin","word2":"sing","question":"Which has /n/?","options":["sin","sing"],"correctAnswerIndex":0,"hint":"Alveolar nasal."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"thin","word2":"thing","question":"Which has /n/?","options":["thin","thing"],"correctAnswerIndex":0,"hint":"Alveolar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"ban","word2":"bang","question":"Which has /n/?","options":["ban","bang"],"correctAnswerIndex":0,"hint":"Alveolar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"ran","word2":"rang","question":"Which has /n/?","options":["ran","rang"],"correctAnswerIndex":0,"hint":"Alveolar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"win","word2":"wing","question":"Which has /n/?","options":["win","wing"],"correctAnswerIndex":0,"hint":"Alveolar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pin","word2":"ping","question":"Which has /n/?","options":["pin","ping"],"correctAnswerIndex":0,"hint":"Alveolar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"kin","word2":"king","question":"Which has /n/?","options":["kin","king"],"correctAnswerIndex":0,"hint":"Alveolar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"ton","word2":"tongue","question":"Which has /n/?","options":["ton","tongue"],"correctAnswerIndex":0,"hint":"Alveolar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sun","word2":"sung","question":"Which has /n/?","options":["sun","sung"],"correctAnswerIndex":0,"hint":"Alveolar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"run","word2":"rung","question":"Which has /n/?","options":["run","rung"],"correctAnswerIndex":0,"hint":"Alveolar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bun","word2":"bung","question":"Which has /n/?","options":["bun","bung"],"correctAnswerIndex":0,"hint":"Alveolar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"din","word2":"ding","question":"Which has /n/?","options":["din","ding"],"correctAnswerIndex":0,"hint":"Alveolar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bat","word2":"vat","question":"Which starts with /b/?","options":["bat","vat"],"correctAnswerIndex":0,"hint":"Bilabial."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"best","word2":"vest","question":"Which starts with /b/?","options":["best","vest"],"correctAnswerIndex":0,"hint":"Bilabial."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bent","word2":"vent","question":"Which starts with /b/?","options":["bent","vent"],"correctAnswerIndex":0,"hint":"Bilabial."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"berry","word2":"very","question":"Which starts with /b/?","options":["berry","very"],"correctAnswerIndex":0,"hint":"Bilabial."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bile","word2":"vile","question":"Which starts with /b/?","options":["bile","vile"],"correctAnswerIndex":0,"hint":"Bilabial."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bolt","word2":"volt","question":"Which starts with /b/?","options":["bolt","volt"],"correctAnswerIndex":0,"hint":"Bilabial."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bow","word2":"vow","question":"Which starts with /b/?","options":["bow","vow"],"correctAnswerIndex":0,"hint":"Bilabial."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bet","word2":"vet","question":"Which starts with /b/?","options":["bet","vet"],"correctAnswerIndex":0,"hint":"Bilabial."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"base","word2":"vase","question":"Which starts with /b/?","options":["base","vase"],"correctAnswerIndex":0,"hint":"Bilabial."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bale","word2":"vale","question":"Which starts with /b/?","options":["bale","vale"],"correctAnswerIndex":0,"hint":"Bilabial."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"major","word2":"measure","question":"Which has /dʒ/?","options":["major","measure"],"correctAnswerIndex":0,"hint":"Affricate."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"danger","word2":"azure","question":"Which has /dʒ/?","options":["danger","azure"],"correctAnswerIndex":0,"hint":"Affricate."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"stranger","word2":"leisure","question":"Which has /dʒ/?","options":["stranger","leisure"],"correctAnswerIndex":0,"hint":"Affricate."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"manager","word2":"pleasure","question":"Which has /dʒ/?","options":["manager","pleasure"],"correctAnswerIndex":0,"hint":"Affricate."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"message","word2":"massage","question":"Which has /dʒ/?","options":["message","massage"],"correctAnswerIndex":0,"hint":"Affricate."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"village","word2":"mirage","question":"Which has /dʒ/?","options":["village","mirage"],"correctAnswerIndex":0,"hint":"Affricate."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"storage","word2":"corsage","question":"Which has /dʒ/?","options":["storage","corsage"],"correctAnswerIndex":0,"hint":"Affricate."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"average","word2":"collage","question":"Which has /dʒ/?","options":["average","collage"],"correctAnswerIndex":0,"hint":"Affricate."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"package","word2":"camouflage","question":"Which has /dʒ/?","options":["package","camouflage"],"correctAnswerIndex":0,"hint":"Affricate."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"garbage","word2":"garage","question":"Which has /dʒ/?","options":["garbage","garage"],"correctAnswerIndex":0,"hint":"Affricate."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"main","word2":"men","question":"Which has /eɪ/?","options":["main","men"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pain","word2":"pen","question":"Which has /eɪ/?","options":["pain","pen"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"rain","word2":"wren","question":"Which has /eɪ/?","options":["rain","wren"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"plain","word2":"glen","question":"Which has /eɪ/?","options":["plain","glen"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"train","word2":"trend","question":"Which has /eɪ/?","options":["train","trend"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"brain","word2":"blend","question":"Which has /eɪ/?","options":["brain","blend"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"strain","word2":"strength","question":"Which has /eɪ/?","options":["strain","strength"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"drain","word2":"dread","question":"Which has /eɪ/?","options":["drain","dread"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"grain","word2":"Fred","question":"Which has /eɪ/?","options":["grain","Fred"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"crane","word2":"credit","question":"Which has /eɪ/?","options":["crane","credit"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"stain","word2":"stem","question":"Which has /eɪ/?","options":["stain","stem"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"chain","word2":"check","question":"Which has /eɪ/?","options":["chain","check"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"claim","word2":"cleft","question":"Which has /eɪ/?","options":["claim","cleft"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"blame","word2":"blend","question":"Which has /eɪ/?","options":["blame","blend"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"flame","word2":"flesh","question":"Which has /eɪ/?","options":["flame","flesh"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"frame","word2":"French","question":"Which has /eɪ/?","options":["frame","French"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"shame","word2":"shelf","question":"Which has /eɪ/?","options":["shame","shelf"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"name","word2":"nest","question":"Which has /eɪ/?","options":["name","nest"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"game","word2":"gem","question":"Which has /eɪ/?","options":["game","gem"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"came","word2":"kept","question":"Which has /eɪ/?","options":["came","kept"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bite","word2":"bit","question":"Which has /aɪ/?","options":["bite","bit"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"site","word2":"sit","question":"Which has /aɪ/?","options":["site","sit"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"kite","word2":"kit","question":"Which has /aɪ/?","options":["kite","kit"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"hide","word2":"hid","question":"Which has /aɪ/?","options":["hide","hid"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"ride","word2":"rid","question":"Which has /aɪ/?","options":["ride","rid"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"side","word2":"sid","question":"Which has /aɪ/?","options":["side","sid"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"mine","word2":"min","question":"Which has /aɪ/?","options":["mine","min"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pine","word2":"pin","question":"Which has /aɪ/?","options":["pine","pin"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"wine","word2":"win","question":"Which has /aɪ/?","options":["wine","win"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"dine","word2":"din","question":"Which has /aɪ/?","options":["dine","din"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pike","word2":"pick","question":"Which has /aɪ/?","options":["pike","pick"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"spike","word2":"spick","question":"Which has /aɪ/?","options":["spike","spick"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"strike","word2":"strict","question":"Which has /aɪ/?","options":["strike","strict"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"price","word2":"prick","question":"Which has /aɪ/?","options":["price","prick"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"slice","word2":"slick","question":"Which has /aɪ/?","options":["slice","slick"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"twice","word2":"trick","question":"Which has /aɪ/?","options":["twice","trick"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"mice","word2":"miss","question":"Which has /aɪ/?","options":["mice","miss"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"nice","word2":"nick","question":"Which has /aɪ/?","options":["nice","nick"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"rice","word2":"rich","question":"Which has /aɪ/?","options":["rice","rich"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"dice","word2":"dish","question":"Which has /aɪ/?","options":["dice","dish"],"correctAnswerIndex":0,"hint":"Diphthong."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"heat","word2":"eat","question":"Which has /h/?","options":["heat","eat"],"correctAnswerIndex":0,"hint":"Initial aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"hill","word2":"ill","question":"Which has /h/?","options":["hill","ill"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"hall","word2":"all","question":"Which has /h/?","options":["hall","all"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"hair","word2":"air","question":"Which has /h/?","options":["hair","air"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"hear","word2":"ear","question":"Which has /h/?","options":["hear","ear"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"hold","word2":"old","question":"Which has /h/?","options":["hold","old"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"high","word2":"eye","question":"Which has /h/?","options":["high","eye"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"hate","word2":"eight","question":"Which has /h/?","options":["hate","eight"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"harm","word2":"arm","question":"Which has /h/?","options":["harm","arm"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"hand","word2":"and","question":"Which has /h/?","options":["hand","and"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"heart","word2":"art","question":"Which has /h/?","options":["heart","art"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"heal","word2":"eel","question":"Which has /h/?","options":["heal","eel"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"haste","word2":"ace","question":"Which has /h/?","options":["haste","ace"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"hedge","word2":"edge","question":"Which has /h/?","options":["hedge","edge"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"hit","word2":"it","question":"Which has /h/?","options":["hit","it"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"had","word2":"add","question":"Which has /h/?","options":["had","add"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"ham","word2":"am","question":"Which has /h/?","options":["ham","am"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"hen","word2":"end","question":"Which has /h/?","options":["hen","end"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"his","word2":"is","question":"Which has /h/?","options":["his","is"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"hug","word2":"ugly","question":"Which has /h/?","options":["hug","ugly"],"correctAnswerIndex":0,"hint":"Aspiration."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pour","word2":"pole","question":"Which ends with /r/?","options":["pour","pole"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"four","word2":"foal","question":"Which ends with /r/?","options":["four","foal"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"core","word2":"coal","question":"Which ends with /r/?","options":["core","coal"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bore","word2":"bowl","question":"Which ends with /r/?","options":["bore","bowl"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"more","word2":"mole","question":"Which ends with /r/?","options":["more","mole"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"store","word2":"stole","question":"Which ends with /r/?","options":["store","stole"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sore","word2":"sole","question":"Which ends with /r/?","options":["sore","sole"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"wore","word2":"whole","question":"Which ends with /r/?","options":["wore","whole"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"fear","word2":"feel","question":"Which ends with /r/?","options":["fear","feel"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"near","word2":"kneel","question":"Which ends with /r/?","options":["near","kneel"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"beer","word2":"beel","question":"Which ends with /r/?","options":["beer","beel"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"dear","word2":"deal","question":"Which ends with /r/?","options":["dear","deal"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"star","word2":"stall","question":"Which ends with /r/?","options":["star","stall"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"car","word2":"call","question":"Which ends with /r/?","options":["car","call"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"far","word2":"fall","question":"Which ends with /r/?","options":["far","fall"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bar","word2":"ball","question":"Which ends with /r/?","options":["bar","ball"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"jar","word2":"jaw","question":"Which ends with /r/?","options":["jar","jaw"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"tar","word2":"tall","question":"Which ends with /r/?","options":["tar","tall"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sir","word2":"sill","question":"Which ends with /r/?","options":["sir","sill"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"fur","word2":"full","question":"Which ends with /r/?","options":["fur","full"],"correctAnswerIndex":0,"hint":"Retroflex."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pail","word2":"fail","question":"Which starts with /p/?","options":["pail","fail"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pair","word2":"fair","question":"Which starts with /p/?","options":["pair","fair"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pale","word2":"fail","question":"Which starts with /p/?","options":["pale","fail"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"past","word2":"fast","question":"Which starts with /p/?","options":["past","fast"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"peel","word2":"feel","question":"Which starts with /p/?","options":["peel","feel"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pill","word2":"fill","question":"Which starts with /p/?","options":["pill","fill"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pine","word2":"fine","question":"Which starts with /p/?","options":["pine","fine"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pit","word2":"fit","question":"Which starts with /p/?","options":["pit","fit"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"plat","word2":"flat","question":"Which starts with /p/?","options":["plat","flat"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"play","word2":"flay","question":"Which starts with /p/?","options":["play","flay"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"plight","word2":"flight","question":"Which starts with /p/?","options":["plight","flight"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"plop","word2":"flop","question":"Which starts with /p/?","options":["plop","flop"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pour","word2":"four","question":"Which starts with /p/?","options":["pour","four"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pox","word2":"fox","question":"Which starts with /p/?","options":["pox","fox"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"punk","word2":"funk","question":"Which starts with /p/?","options":["punk","funk"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"purr","word2":"fur","question":"Which starts with /p/?","options":["purr","fur"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"they","word2":"day","question":"Which has /ð/?","options":["they","day"],"correctAnswerIndex":0,"hint":"Dental fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"than","word2":"Dan","question":"Which has /ð/?","options":["than","Dan"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"there","word2":"dare","question":"Which has /ð/?","options":["there","dare"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"though","word2":"dough","question":"Which has /ð/?","options":["though","dough"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"that","word2":"dab","question":"Which has /ð/?","options":["that","dab"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"the","word2":"D","question":"Which has /ð/?","options":["the","D"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"then","word2":"den","question":"Which has /ð/?","options":["then","den"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"these","word2":"disease","question":"Which has /ð/?","options":["these","disease"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"them","word2":"deem","question":"Which has /ð/?","options":["them","deem"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"those","word2":"dose","question":"Which has /ð/?","options":["those","dose"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"thus","word2":"dust","question":"Which has /ð/?","options":["thus","dust"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"this","word2":"diss","question":"Which has /ð/?","options":["this","diss"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bathe","word2":"bade","question":"Which has /ð/?","options":["bathe","bade"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"clothe","word2":"code","question":"Which has /ð/?","options":["clothe","code"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"soothe","word2":"sued","question":"Which has /ð/?","options":["soothe","sued"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"breathe","word2":"breed","question":"Which has /ð/?","options":["breathe","breed"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"lathe","word2":"laid","question":"Which has /ð/?","options":["lathe","laid"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"scathe","word2":"skate","question":"Which has /ð/?","options":["scathe","skate"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"writhe","word2":"ride","question":"Which has /ð/?","options":["writhe","ride"],"correctAnswerIndex":0,"hint":"Dental."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"tithe","word2":"tied","question":"Which has /ð/?","options":["tithe","tied"],"correctAnswerIndex":0,"hint":"Dental."}});

  // === ROUND 2 AUTO-EXPANDED ===
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sake","word2":"shake","question":"Which starts with /s/?","options":["sake","shake"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sore","word2":"shore","question":"Which starts with /s/?","options":["sore","shore"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"self","word2":"shelf","question":"Which starts with /s/?","options":["self","shelf"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sip","word2":"ship","question":"Which starts with /s/?","options":["sip","ship"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"suit","word2":"shoot","question":"Which starts with /s/?","options":["suit","shoot"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"save","word2":"shave","question":"Which starts with /s/?","options":["save","shave"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sock","word2":"shock","question":"Which starts with /s/?","options":["sock","shock"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sort","word2":"short","question":"Which starts with /s/?","options":["sort","short"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"seed","word2":"she'd","question":"Which starts with /s/?","options":["seed","she'd"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"so","word2":"show","question":"Which starts with /s/?","options":["so","show"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"same","word2":"shame","question":"Which starts with /s/?","options":["same","shame"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sigh","word2":"shy","question":"Which starts with /s/?","options":["sigh","shy"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"seep","word2":"sheep","question":"Which starts with /s/?","options":["seep","sheep"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"seen","word2":"sheen","question":"Which starts with /s/?","options":["seen","sheen"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"seer","word2":"sheer","question":"Which starts with /s/?","options":["seer","sheer"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sell","word2":"shell","question":"Which starts with /s/?","options":["sell","shell"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sow","word2":"show","question":"Which starts with /s/?","options":["sow","show"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sum","word2":"shun","question":"Which starts with /s/?","options":["sum","shun"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sun","word2":"shun","question":"Which starts with /s/?","options":["sun","shun"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"saw","word2":"shaw","question":"Which starts with /s/?","options":["saw","shaw"],"correctAnswerIndex":0,"hint":"Fricative."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"cake","word2":"take","question":"Which starts with /k/?","options":["cake","take"],"correctAnswerIndex":0,"hint":"Velar stop."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"cape","word2":"tape","question":"Which starts with /k/?","options":["cape","tape"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"care","word2":"tear","question":"Which starts with /k/?","options":["care","tear"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"call","word2":"tall","question":"Which starts with /k/?","options":["call","tall"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"cash","word2":"trash","question":"Which starts with /k/?","options":["cash","trash"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"corn","word2":"torn","question":"Which starts with /k/?","options":["corn","torn"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"coil","word2":"toil","question":"Which starts with /k/?","options":["coil","toil"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"core","word2":"tore","question":"Which starts with /k/?","options":["core","tore"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"cot","word2":"tot","question":"Which starts with /k/?","options":["cot","tot"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"cow","word2":"tow","question":"Which starts with /k/?","options":["cow","tow"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"cub","word2":"tub","question":"Which starts with /k/?","options":["cub","tub"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"curl","word2":"twirl","question":"Which starts with /k/?","options":["curl","twirl"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"keen","word2":"teen","question":"Which starts with /k/?","options":["keen","teen"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"key","word2":"tea","question":"Which starts with /k/?","options":["key","tea"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"kick","word2":"tick","question":"Which starts with /k/?","options":["kick","tick"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"kill","word2":"till","question":"Which starts with /k/?","options":["kill","till"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"kin","word2":"tin","question":"Which starts with /k/?","options":["kin","tin"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"kind","word2":"tined","question":"Which starts with /k/?","options":["kind","tined"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"knack","word2":"tack","question":"Which starts with /k/?","options":["knack","tack"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"knot","word2":"tot","question":"Which starts with /k/?","options":["knot","tot"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"gale","word2":"dale","question":"Which starts with /g/?","options":["gale","dale"],"correctAnswerIndex":0,"hint":"Velar voiced."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"gave","word2":"Dave","question":"Which starts with /g/?","options":["gave","Dave"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"gaze","word2":"days","question":"Which starts with /g/?","options":["gaze","days"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"gear","word2":"deer","question":"Which starts with /g/?","options":["gear","deer"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"gill","word2":"dill","question":"Which starts with /g/?","options":["gill","dill"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"go","word2":"dough","question":"Which starts with /g/?","options":["go","dough"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"goal","word2":"dole","question":"Which starts with /g/?","options":["goal","dole"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"gone","word2":"dawn","question":"Which starts with /g/?","options":["gone","dawn"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"gore","word2":"door","question":"Which starts with /g/?","options":["gore","door"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"got","word2":"dot","question":"Which starts with /g/?","options":["got","dot"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"gown","word2":"down","question":"Which starts with /g/?","options":["gown","down"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"grate","word2":"date","question":"Which starts with /g/?","options":["grate","date"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"grit","word2":"drit","question":"Which starts with /g/?","options":["grit","drit"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"grow","word2":"drew","question":"Which starts with /g/?","options":["grow","drew"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"gum","word2":"dumb","question":"Which starts with /g/?","options":["gum","dumb"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"gust","word2":"dust","question":"Which starts with /g/?","options":["gust","dust"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"gut","word2":"dut","question":"Which starts with /g/?","options":["gut","dut"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"guy","word2":"die","question":"Which starts with /g/?","options":["guy","die"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"gash","word2":"dash","question":"Which starts with /g/?","options":["gash","dash"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"grab","word2":"drab","question":"Which starts with /g/?","options":["grab","drab"],"correctAnswerIndex":0,"hint":"Velar."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"clap","word2":"cap","question":"Which has the cluster?","options":["clap","cap"],"correctAnswerIndex":0,"hint":"Consonant cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"cling","word2":"king","question":"Which has the cluster?","options":["cling","king"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"clot","word2":"cot","question":"Which has the cluster?","options":["clot","cot"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"club","word2":"cub","question":"Which has the cluster?","options":["club","cub"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"blind","word2":"bind","question":"Which has the cluster?","options":["blind","bind"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"block","word2":"bock","question":"Which has the cluster?","options":["block","bock"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"brand","word2":"band","question":"Which has the cluster?","options":["brand","band"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bread","word2":"bed","question":"Which has the cluster?","options":["bread","bed"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"bring","word2":"bing","question":"Which has the cluster?","options":["bring","bing"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"brink","word2":"bink","question":"Which has the cluster?","options":["brink","bink"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"flock","word2":"folk","question":"Which has the cluster?","options":["flock","folk"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"frog","word2":"fog","question":"Which has the cluster?","options":["frog","fog"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"frost","word2":"fost","question":"Which has the cluster?","options":["frost","fost"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"grown","word2":"gown","question":"Which has the cluster?","options":["grown","gown"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"cram","word2":"cam","question":"Which has the cluster?","options":["cram","cam"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"crest","word2":"chest","question":"Which has the cluster?","options":["crest","chest"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"crisp","word2":"kiss","question":"Which has the cluster?","options":["crisp","kiss"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"cross","word2":"cos","question":"Which has the cluster?","options":["cross","cos"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"crown","word2":"cow","question":"Which has the cluster?","options":["crown","cow"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"drop","word2":"dop","question":"Which has the cluster?","options":["drop","dop"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"drum","word2":"dumb","question":"Which has the cluster?","options":["drum","dumb"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"flat","word2":"fat","question":"Which has the cluster?","options":["flat","fat"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"flaw","word2":"foe","question":"Which has the cluster?","options":["flaw","foe"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"fled","word2":"fed","question":"Which has the cluster?","options":["fled","fed"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"flew","word2":"few","question":"Which has the cluster?","options":["flew","few"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"flip","word2":"fip","question":"Which has the cluster?","options":["flip","fip"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"float","word2":"foe","question":"Which has the cluster?","options":["float","foe"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"flow","word2":"foe","question":"Which has the cluster?","options":["flow","foe"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"play","word2":"pay","question":"Which has the cluster?","options":["play","pay"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"plea","word2":"pea","question":"Which has the cluster?","options":["plea","pea"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"plod","word2":"pod","question":"Which has the cluster?","options":["plod","pod"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"plot","word2":"pot","question":"Which has the cluster?","options":["plot","pot"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"pluck","word2":"puck","question":"Which has the cluster?","options":["pluck","puck"],"correctAnswerIndex":0,"hint":"Cluster."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"plug","word2":"pug","question":"Which has the cluster?","options":["plug","pug"],"correctAnswerIndex":0,"hint":"Cluster."}});

  // === FINAL FIX ===
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"blaze","word2":"plays","question":"Which starts with /b/?","options":["blaze","plays"],"correctAnswerIndex":0,"hint":"Plosive."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"claws","word2":"clause","question":"Which is the noun?","options":["claws","clause"],"correctAnswerIndex":0,"hint":"Identical sounds."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"praise","word2":"prays","question":"Which has /eɪz/?","options":["praise","prays"],"correctAnswerIndex":0,"hint":"Identical sounds."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"maze","word2":"maize","question":"Which has 3 letters?","options":["maze","maize"],"correctAnswerIndex":0,"hint":"Same sound."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"stake","word2":"steak","question":"Which is wood?","options":["stake","steak"],"correctAnswerIndex":0,"hint":"Homophone."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"paws","word2":"pause","question":"Which is animal?","options":["paws","pause"],"correctAnswerIndex":0,"hint":"Homophone."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"flour","word2":"flower","question":"Which is grain?","options":["flour","flower"],"correctAnswerIndex":0,"hint":"Homophone."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"brake","word2":"break","question":"Which is on a car?","options":["brake","break"],"correctAnswerIndex":0,"hint":"Homophone."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"mail","word2":"male","question":"Which is post?","options":["mail","male"],"correctAnswerIndex":0,"hint":"Homophone."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"sail","word2":"sale","question":"Which is on water?","options":["sail","sale"],"correctAnswerIndex":0,"hint":"Homophone."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"wave","word2":"waive","question":"Which is motion?","options":["wave","waive"],"correctAnswerIndex":0,"hint":"Homophone."}});
  pool.push({"instruction":"Choose the word you hear.","fields":{"word1":"wait","word2":"weight","question":"Which is time?","options":["wait","weight"],"correctAnswerIndex":0,"hint":"Homophone."}});
  // Ensure auto-expanded entries get IPA attached
  pool.forEach(q => {
    if(!q.fields.ipa1) q.fields.ipa1 = getIpa(q.fields.word1);
    if(!q.fields.ipa2) q.fields.ipa2 = getIpa(q.fields.word2);
  });

  console.log(`  minimalPairs pool: ${pool.length}`);
  return pool;
};
