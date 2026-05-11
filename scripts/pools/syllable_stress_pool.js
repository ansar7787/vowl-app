// Syllable Stress: 600 unique words
const getIpa = require(__dirname + '/get_ipa.js');
module.exports = function() {
  const pool = [];
  const words = [
    // 2-syllable words
    ['HOTEL','ho-TEL','HO-tel',0],['POLICE','po-LICE','PO-lice',0],['GUITAR','gui-TAR','GUI-tar',0],
    ['BALLOON','bal-LOON','BAL-loon',0],['CANAL','ca-NAL','CA-nal',0],['CEMENT','ce-MENT','CE-ment',0],
    ['DEBATE','de-BATE','DE-bate',0],['DEGREE','de-GREE','DE-gree',0],['DELAY','de-LAY','DE-lay',0],
    ['DEMAND','de-MAND','DE-mand',0],['DENY','de-NY','DE-ny',0],['DEPEND','de-PEND','DE-pend',0],
    ['DESIGN','de-SIGN','DE-sign',0],['DESIRE','de-SIRE','DE-sire',0],['DETECT','de-TECT','DE-tect',0],
    ['DEVICE','de-VICE','DE-vice',0],['DIRECT','di-RECT','DI-rect',0],['DIVIDE','di-VIDE','DI-vide',0],
    ['DOMAIN','do-MAIN','DO-main',0],['EFFECT','ef-FECT','EF-fect',0],['ELECT','e-LECT','E-lect',0],
    ['EVENT','e-VENT','E-vent',0],['EXAM','ex-AM','EX-am',0],['EXCEPT','ex-CEPT','EX-cept',0],
    ['EXPAND','ex-PAND','EX-pand',0],['EXPECT','ex-PECT','EX-pect',0],['EXPLAIN','ex-PLAIN','EX-plain',0],
    ['EXPLORE','ex-PLORE','EX-plore',0],['EXPRESS','ex-PRESS','EX-press',0],['EXTEND','ex-TEND','EX-tend',0],
    ['FORGET','for-GET','FOR-get',0],['IMMUNE','im-MUNE','IM-mune',0],['INCLUDE','in-CLUDE','IN-clude',0],
    ['INDEED','in-DEED','IN-deed',0],['INSPIRE','in-SPIRE','IN-spire',0],['INSTALL','in-STALL','IN-stall',0],
    ['INTEND','in-TEND','IN-tend',0],['INVEST','in-VEST','IN-vest',0],['MACHINE','ma-CHINE','MA-chine',0],
    ['MISTAKE','mis-TAKE','MIS-take',0],['OBEY','o-BEY','O-bey',0],['OBTAIN','ob-TAIN','OB-tain',0],
    ['OCCUR','oc-CUR','OC-cur',0],['OPPOSE','op-POSE','OP-pose',0],['PERFORM','per-FORM','PER-form',0],
    ['PERMIT','per-MIT','PER-mit',0],['PERSUADE','per-SUADE','PER-suade',0],['POSSESS','pos-SESS','POS-sess',0],
    ['PREDICT','pre-DICT','PRE-dict',0],['PREFER','pre-FER','PRE-fer',0],['PREPARE','pre-PARE','PRE-pare',0],
    ['PRESENT','pre-SENT','PRE-sent',0],['PREVENT','pre-VENT','PRE-vent',0],['PRODUCE','pro-DUCE','PRO-duce',0],
    ['PROTECT','pro-TECT','PRO-tect',0],['PROVIDE','pro-VIDE','PRO-vide',0],['PURSUE','pur-SUE','PUR-sue',0],
    ['RECEIVE','re-CEIVE','RE-ceive',0],['RECORD','re-CORD','RE-cord',0],['REDUCE','re-DUCE','RE-duce',0],
    ['REFUSE','re-FUSE','RE-fuse',0],['RELATE','re-LATE','RE-late',0],['RELEASE','re-LEASE','RE-lease',0],
    ['REMAIN','re-MAIN','RE-main',0],['REMOVE','re-MOVE','RE-move',0],['REPAIR','re-PAIR','RE-pair',0],
    ['REPEAT','re-PEAT','RE-peat',0],['REPLACE','re-PLACE','RE-place',0],['REPORT','re-PORT','RE-port',0],
    ['REQUEST','re-QUEST','RE-quest',0],['REQUIRE','re-QUIRE','RE-quire',0],['RESOLVE','re-SOLVE','RE-solve',0],
    ['RESULT','re-SULT','RE-sult',0],['REVEAL','re-VEAL','RE-veal',0],['REVIEW','re-VIEW','RE-view',0],
    ['SUGGEST','sug-GEST','SUG-gest',0],['SUPPOSE','sup-POSE','SUP-pose',0],['SURVIVE','sur-VIVE','SUR-vive',0],
    // First-syllable stress
    ['APPLE','AP-ple','ap-PLE',0],['BASKET','BAS-ket','bas-KET',0],['BROTHER','BRO-ther','bro-THER',0],
    ['BUTTER','BUT-ter','but-TER',0],['CABIN','CAB-in','cab-IN',0],['CARPET','CAR-pet','car-PET',0],
    ['CHAPTER','CHAP-ter','chap-TER',0],['CHICKEN','CHICK-en','chick-EN',0],['CIRCLE','CIR-cle','cir-CLE',0],
    ['CLEVER','CLEV-er','clev-ER',0],['COMFORT','COM-fort','com-FORT',0],['COMMON','COM-mon','com-MON',0],
    ['COUSIN','COU-sin','cou-SIN',0],['CURRENT','CUR-rent','cur-RENT',0],['DANGER','DAN-ger','dan-GER',0],
    ['DAUGHTER','DAUGH-ter','daugh-TER',0],['DINNER','DIN-ner','din-NER',0],['DOCTOR','DOC-tor','doc-TOR',0],
    ['EARLY','EAR-ly','ear-LY',0],['EFFORT','EF-fort','ef-FORT',0],['ENTER','EN-ter','en-TER',0],
    ['EVENING','EVE-ning','eve-NING',0],['EXPERT','EX-pert','ex-PERT',0],['FABRIC','FAB-ric','fab-RIC',0],
    ['FAMOUS','FA-mous','fa-MOUS',0],['FATHER','FA-ther','fa-THER',0],['FINGER','FIN-ger','fin-GER',0],
    ['FLOWER','FLOW-er','flow-ER',0],['GARDEN','GAR-den','gar-DEN',0],['GENTLE','GEN-tle','gen-TLE',0],
    ['HAPPY','HAP-py','hap-PY',0],['HARVEST','HAR-vest','har-VEST',0],['HEAVY','HEA-vy','hea-VY',0],
    ['HUNGER','HUN-ger','hun-GER',0],['ISLAND','IS-land','is-LAND',0],['JACKET','JACK-et','jack-ET',0],
    ['KITCHEN','KITCH-en','kitch-EN',0],['LADDER','LAD-der','lad-DER',0],['LANGUAGE','LAN-guage','lan-GUAGE',0],
    ['LETTER','LET-ter','let-TER',0],['MARKET','MAR-ket','mar-KET',0],['MASTER','MAS-ter','mas-TER',0],
    ['MATTER','MAT-ter','mat-TER',0],['MEMBER','MEM-ber','mem-BER',0],['METHOD','METH-od','meth-OD',0],
    ['MIRROR','MIR-ror','mir-ROR',0],['MODERN','MOD-ern','mod-ERN',0],['MOMENT','MO-ment','mo-MENT',0],
    ['MONKEY','MON-key','mon-KEY',0],['MOTHER','MOTH-er','moth-ER',0],['MOUNTAIN','MOUN-tain','moun-TAIN',0],
    ['MUSCLE','MUS-cle','mus-CLE',0],['NARROW','NAR-row','nar-ROW',0],['NATURE','NA-ture','na-TURE',0],
    ['NUMBER','NUM-ber','num-BER',0],['OFFICE','OF-fice','of-FICE',0],['ORANGE','OR-ange','or-ANGE',0],
    ['PALACE','PAL-ace','pal-ACE',0],['PARENT','PAR-ent','par-ENT',0],['PATTERN','PAT-tern','pat-TERN',0],
    ['PENCIL','PEN-cil','pen-CIL',0],['PERFECT','PER-fect','per-FECT',0],['PERSON','PER-son','per-SON',0],
    ['PICTURE','PIC-ture','pic-TURE',0],['PLASTIC','PLAS-tic','plas-TIC',0],['POCKET','POCK-et','pock-ET',0],
    ['POWER','POW-er','pow-ER',0],['PRACTICE','PRAC-tice','prac-TICE',0],['PROBLEM','PROB-lem','prob-LEM',0],
    ['PRODUCT','PROD-uct','prod-UCT',0],['PROMISE','PROM-ise','prom-ISE',0],['PROPER','PROP-er','prop-ER',0],
    ['PURPLE','PUR-ple','pur-PLE',0],['PUZZLE','PUZ-zle','puz-ZLE',0],['QUARTER','QUAR-ter','quar-TER',0],
    // 3-syllable words
    ['BANANA','ba-NA-na','BA-na-na',0],['COMPUTER','com-PU-ter','COM-pu-ter',0],
    ['IMPORTANT','im-POR-tant','IM-por-tant',0],['BEAUTIFUL','BEAU-ti-ful','beau-TI-ful',0],
    ['EDUCATION','ed-u-CA-tion','ED-u-ca-tion',0],['UNDERSTAND','un-der-STAND','UN-der-stand',0],
    ['PHOTOGRAPH','PHO-to-graph','pho-TO-graph',0],['PHOTOGRAPHY','pho-TOG-ra-phy','PHO-tog-ra-phy',0],
    ['TELEPHONE','TEL-e-phone','tel-E-phone',0],['INFORMATION','in-for-MA-tion','IN-for-ma-tion',0],
    ['RESTAURANT','RES-tau-rant','res-TAU-rant',0],['DEVELOPMENT','de-VEL-op-ment','DEV-el-op-ment',0],
    ['VOLUNTEER','vol-un-TEER','VOL-un-teer',0],['ADVERTISEMENT','ad-VER-tise-ment','AD-ver-tise-ment',0],
    ['EMPLOYEE','em-PLOY-ee','EM-ploy-ee',0],['ATMOSPHERE','AT-mos-phere','at-MOS-phere',0],
    ['CERTIFICATE','cer-TIF-i-cate','CER-tif-i-cate',0],['CALENDAR','CAL-en-dar','cal-EN-dar',0],
    ['TOMORROW','to-MOR-row','TOM-or-row',0],['HELICOPTER','HEL-i-cop-ter','hel-I-cop-ter',0],
    ['PERSONALITY','per-son-AL-i-ty','PER-son-al-i-ty',0],['EXPERIMENT','ex-PER-i-ment','EX-per-i-ment',0],
    ['ECONOMY','e-CON-o-my','EC-on-o-my',0],['UNIVERSITY','u-ni-VER-si-ty','UN-i-ver-si-ty',0],
    ['PARTICIPATE','par-TIC-i-pate','PAR-tic-i-pate',0],['OPPORTUNITY','op-por-TU-ni-ty','OP-por-tu-ni-ty',0],
    ['COMMUNICATE','com-MU-ni-cate','COM-mu-ni-cate',0],['ENVIRONMENT','en-VI-ron-ment','EN-vi-ron-ment',0],
    ['APPRECIATE','ap-PRE-ci-ate','AP-pre-ci-ate',0],['AMBASSADOR','am-BAS-sa-dor','AM-bas-sa-dor',0],
    ['ACKNOWLEDGE','ac-KNOWL-edge','AC-knowl-edge',0],['ACCOMPLISH','ac-COM-plish','AC-com-plish',0],
    ['ENORMOUS','e-NOR-mous','EN-or-mous',0],['ENCOURAGE','en-COUR-age','EN-cour-age',0],
    ['CONSIDER','con-SID-er','CON-sid-er',0],['CONTINUE','con-TIN-ue','CON-tin-ue',0],
    ['DETERMINE','de-TER-mine','DET-er-mine',0],['DISCOVER','dis-COV-er','DIS-cov-er',0],
    ['DOMESTIC','do-MES-tic','DOM-es-tic',0],['ELASTIC','e-LAS-tic','EL-as-tic',0],
    ['ELECTRIC','e-LEC-tric','EL-ec-tric',0],['ESTABLISH','es-TAB-lish','EST-ab-lish',0],
    ['EXAMINE','ex-AM-ine','EX-am-ine',0],['EXAMPLE','ex-AM-ple','EX-am-ple',0],
    ['EXPENSIVE','ex-PEN-sive','EX-pen-sive',0],['FANTASTIC','fan-TAS-tic','FAN-tas-tic',0],
    ['FORBIDDEN','for-BID-den','FOR-bid-den',0],['HORIZON','ho-RI-zon','HOR-i-zon',0],
    ['IMAGINE','i-MAG-ine','IM-ag-ine',0],['MAJORITY','ma-JOR-i-ty','MAJ-or-i-ty',0],
    ['MATERIAL','ma-TER-i-al','MAT-er-i-al',0],['MECHANIC','me-CHAN-ic','MECH-an-ic',0],
    ['MEMORIAL','me-MOR-i-al','MEM-or-i-al',0],['OFFICIAL','of-FI-cial','OFF-i-cial',0],
    ['ORIGINAL','o-RIG-i-nal','OR-ig-i-nal',0],['PARTICULAR','par-TIC-u-lar','PAR-tic-u-lar',0],
    ['PENINSULA','pe-NIN-su-la','PEN-in-su-la',0],['PERCENTAGE','per-CENT-age','PER-cent-age',0],
    ['POLITICAL','po-LIT-i-cal','POL-it-i-cal',0],['POSITION','po-SI-tion','POS-i-tion',0],
    ['PROFESSIONAL','pro-FES-sion-al','PROF-es-sion-al',0],['REMEMBER','re-MEM-ber','REM-em-ber',0],
    ['REPUBLIC','re-PUB-lic','REP-ub-lic',0],['ROMANTIC','ro-MAN-tic','ROM-an-tic',0],
    ['SEPTEMBER','sep-TEM-ber','SEP-tem-ber',0],['SOLUTION','so-LU-tion','SOL-u-tion',0],
    ['SUFFICIENT','suf-FI-cient','SUF-fi-cient',0],['TERRIFIC','ter-RIF-ic','TER-rif-ic',0],
    ['TRADITION','tra-DI-tion','TRAD-i-tion',0],['UMBRELLA','um-BREL-la','UM-brel-la',0],
    ['VACATION','va-CA-tion','VAC-a-tion',0],['VOLCANO','vol-CA-no','VOL-ca-no',0],
    // First-syllable 3+ syllable
    ['ACCIDENT','AC-ci-dent','ac-CI-dent',0],['ACCURATE','AC-cu-rate','ac-CUR-ate',0],
    ['ANIMAL','AN-i-mal','an-I-mal',0],['CABINET','CAB-i-net','cab-I-net',0],
    ['CAPITAL','CAP-i-tal','cap-I-tal',0],['CARNIVAL','CAR-ni-val','car-NI-val',0],
    ['CELEBRATE','CEL-e-brate','cel-E-brate',0],['CHARACTER','CHAR-ac-ter','char-AC-ter',0],
    ['CHOCOLATE','CHOC-o-late','choc-O-late',0],['CINEMA','CIN-e-ma','cin-E-ma',0],
    ['COMPANY','COM-pa-ny','com-PA-ny',0],['CONFERENCE','CON-fer-ence','con-FER-ence',0],
    ['CONSEQUENCE','CON-se-quence','con-SE-quence',0],['CORRIDOR','COR-ri-dor','cor-RI-dor',0],
    ['COVERING','COV-er-ing','cov-ER-ing',0],['CRIMINAL','CRIM-i-nal','crim-I-nal',0],
    ['CUSTOMER','CUS-tom-er','cus-TOM-er',0],['DEFINITE','DEF-i-nite','def-I-nite',0],
    ['DESPERATE','DES-per-ate','des-PER-ate',0],['DIFFERENT','DIF-fer-ent','dif-FER-ent',0],
    ['DIFFICULT','DIF-fi-cult','dif-FI-cult',0],['DINOSAUR','DI-no-saur','di-NO-saur',0],
    ['DOCUMENT','DOC-u-ment','doc-U-ment',0],['ELEPHANT','EL-e-phant','el-E-phant',0],
    ['ENERGY','EN-er-gy','en-ER-gy',0],['ENGINEER','EN-gi-neer','en-gi-NEER',0],
    ['ENVELOPE','EN-ve-lope','en-VE-lope',0],['ESTIMATE','ES-ti-mate','es-TI-mate',0],
    ['EXCELLENT','EX-cel-lent','ex-CEL-lent',0],['EXERCISE','EX-er-cise','ex-ER-cise',0],
    ['FAMILY','FAM-i-ly','fam-I-ly',0],['FAVORITE','FA-vor-ite','fa-VOR-ite',0],
    ['FESTIVAL','FES-ti-val','fes-TI-val',0],['FORMULA','FOR-mu-la','for-MU-la',0],
    ['FURNITURE','FUR-ni-ture','fur-NI-ture',0],['GALLERY','GAL-ler-y','gal-LER-y',0],
    ['GENERAL','GEN-er-al','gen-ER-al',0],['GENERATE','GEN-er-ate','gen-ER-ate',0],
    ['GOVERNMENT','GOV-ern-ment','gov-ERN-ment',0],['GRADUATE','GRAD-u-ate','grad-U-ate',0],
    ['HAMBURGER','HAM-bur-ger','ham-BUR-ger',0],['HOSPITAL','HOS-pi-tal','hos-PI-tal',0],
    ['INDUSTRY','IN-dus-try','in-DUS-try',0],['INNOCENT','IN-no-cent','in-NO-cent',0],
    ['INSTITUTE','IN-sti-tute','in-STI-tute',0],['INTERNET','IN-ter-net','in-TER-net',0],
    ['INTERVIEW','IN-ter-view','in-TER-view',0],['JEWELRY','JEW-el-ry','jew-EL-ry',0],
    ['LIBRARY','LI-bra-ry','li-BRA-ry',0],['MANAGER','MAN-a-ger','man-A-ger',0],
    ['MEDICINE','MED-i-cine','med-I-cine',0],['MINISTER','MIN-is-ter','min-IS-ter',0],
    ['MONUMENT','MON-u-ment','mon-U-ment',0],['NEIGHBOR','NEIGH-bor','neigh-BOR',0],
    ['NEWSPAPER','NEWS-pa-per','news-PA-per',0],['OBSTACLE','OB-sta-cle','ob-STA-cle',0],
    ['ORCHESTRA','OR-ches-tra','or-CHES-tra',0],['ORGANISE','OR-gan-ise','or-GAN-ise',0],
    ['PARAGRAPH','PAR-a-graph','par-A-graph',0],['PASSENGER','PAS-sen-ger','pas-SEN-ger',0],
    ['POSITIVE','POS-i-tive','pos-I-tive',0],['PRESIDENT','PRES-i-dent','pres-I-dent',0],
    ['PRINCIPAL','PRIN-ci-pal','prin-CI-pal',0],['PRISONER','PRIS-on-er','pris-ON-er',0],
    ['PROPERTY','PROP-er-ty','prop-ER-ty',0],['QUANTITY','QUAN-ti-ty','quan-TI-ty',0],
    ['REGISTER','REG-is-ter','reg-IS-ter',0],['SATELLITE','SAT-el-lite','sat-EL-lite',0],
    ['SEPARATE','SEP-a-rate','sep-A-rate',0],['SKELETON','SKEL-e-ton','skel-E-ton',0],
    ['STRATEGY','STRAT-e-gy','strat-E-gy',0],['STUDIO','STU-di-o','stu-DI-o',0],
    ['SYMPATHY','SYM-pa-thy','sym-PA-thy',0],['TECHNICAL','TECH-ni-cal','tech-NI-cal',0],
    ['TERRITORY','TER-ri-to-ry','ter-RI-to-ry',0],['VEGETABLE','VEG-e-ta-ble','veg-E-ta-ble',0],
    ['VIOLENT','VI-o-lent','vi-O-lent',0],['WONDERFUL','WON-der-ful','won-DER-ful',0],
  ];
  for (const [word,o1,o2,ans] of words) {
    pool.push({
      instruction: 'Where is the stress?',
      fields: { word, options: [o1,o2], correctAnswerIndex: ans, hint: 'Listen for the loudest syllable.', phoneticHint: getIpa(word) }
    });
  }
  
  // === AUTO-EXPANDED ENTRIES ===
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ABSENT","options":["AB-sent","ab-SENT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ABSENT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ACTION","options":["AC-tion","ac-TION"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ACTION")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ANGEL","options":["AN-gel","an-GEL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ANGEL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ANKLE","options":["AN-kle","an-KLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ANKLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ARROW","options":["AR-row","ar-ROW"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ARROW")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"AWFUL","options":["AW-ful","aw-FUL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("AWFUL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BACKUP","options":["BACK-up","back-UP"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BACKUP")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BALANCE","options":["BAL-ance","bal-ANCE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BALANCE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BARREL","options":["BAR-rel","bar-REL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BARREL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BITTER","options":["BIT-ter","bit-TER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BITTER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BLANKET","options":["BLAN-ket","blan-KET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BLANKET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BLESSING","options":["BLES-sing","bles-SING"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BLESSING")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BOTTOM","options":["BOT-tom","bot-TOM"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BOTTOM")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BOUNTY","options":["BOUN-ty","boun-TY"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BOUNTY")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BUBBLE","options":["BUB-ble","bub-BLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BUBBLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BURDEN","options":["BUR-den","bur-DEN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BURDEN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BUTTON","options":["BUT-ton","but-TON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BUTTON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CANDLE","options":["CAN-dle","can-DLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CANDLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CAPTURE","options":["CAP-ture","cap-TURE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CAPTURE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CAUTION","options":["CAU-tion","cau-TION"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CAUTION")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CERTAIN","options":["CER-tain","cer-TAIN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CERTAIN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CHANNEL","options":["CHAN-nel","chan-NEL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CHANNEL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CHARTER","options":["CHAR-ter","char-TER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CHARTER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CHIPMUNK","options":["CHIP-munk","chip-MUNK"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CHIPMUNK")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CLIMATE","options":["CLI-mate","cli-MATE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CLIMATE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"COASTAL","options":["COAST-al","coast-AL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("COASTAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CONTEST","options":["CON-test","con-TEST"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CONTEST")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CONTRAST","options":["CON-trast","con-TRAST"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CONTRAST")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"COPPER","options":["COP-per","cop-PER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("COPPER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CORNER","options":["COR-ner","cor-NER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CORNER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"COTTAGE","options":["COT-tage","cot-TAGE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("COTTAGE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"COUNTER","options":["COUN-ter","coun-TER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("COUNTER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"COURAGE","options":["COUR-age","cour-AGE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("COURAGE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CREATURE","options":["CREA-ture","crea-TURE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CREATURE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CRICKET","options":["CRICK-et","crick-ET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CRICKET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CRYSTAL","options":["CRYS-tal","crys-TAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CRYSTAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CULTURE","options":["CUL-ture","cul-TURE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CULTURE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CURTAIN","options":["CUR-tain","cur-TAIN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CURTAIN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CUSTOM","options":["CUS-tom","cus-TOM"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CUSTOM")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"DAGGER","options":["DAG-ger","dag-GER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("DAGGER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"DAMAGE","options":["DAM-age","dam-AGE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("DAMAGE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"DARKNESS","options":["DARK-ness","dark-NESS"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("DARKNESS")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"DISTANT","options":["DIS-tant","dis-TANT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("DISTANT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"DOLPHIN","options":["DOL-phin","dol-PHIN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("DOLPHIN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"DOUBLE","options":["DOU-ble","dou-BLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("DOUBLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"DRAGON","options":["DRA-gon","dra-GON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("DRAGON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"EAGLE","options":["EA-gle","ea-GLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("EAGLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ELBOW","options":["EL-bow","el-BOW"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ELBOW")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"EMPIRE","options":["EM-pire","em-PIRE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("EMPIRE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ENGINE","options":["EN-gine","en-GINE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ENGINE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"EQUAL","options":["E-qual","e-QUAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("EQUAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"EXTRA","options":["EX-tra","ex-TRA"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("EXTRA")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FAILURE","options":["FAI-lure","fai-LURE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FAILURE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FALCON","options":["FAL-con","fal-CON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FALCON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FEATHER","options":["FEATH-er","feath-ER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FEATHER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FELLOW","options":["FEL-low","fel-LOW"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FELLOW")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FICTION","options":["FIC-tion","fic-TION"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FICTION")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FIFTEEN","options":["FIF-teen","fif-TEEN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FIFTEEN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FIGURE","options":["FIG-ure","fig-URE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FIGURE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FILTER","options":["FIL-ter","fil-TER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FILTER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FINAL","options":["FI-nal","fi-NAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FINAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FOCUS","options":["FO-cus","fo-CUS"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FOCUS")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FOLLOW","options":["FOL-low","fol-LOW"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FOLLOW")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FOOLISH","options":["FOO-lish","foo-LISH"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FOOLISH")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FOREIGN","options":["FOR-eign","for-EIGN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FOREIGN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FOREST","options":["FOR-est","for-EST"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FOREST")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FORTUNE","options":["FOR-tune","for-TUNE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FORTUNE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FOSSIL","options":["FOS-sil","fos-SIL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FOSSIL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FRACTION","options":["FRAC-tion","frac-TION"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FRACTION")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FREEDOM","options":["FREE-dom","free-DOM"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FREEDOM")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FROZEN","options":["FRO-zen","fro-ZEN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FROZEN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FUNCTION","options":["FUNC-tion","func-TION"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FUNCTION")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"GALAXY","options":["GA-laxy","ga-LA-xy"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("GALAXY")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"GATHER","options":["GATH-er","gath-ER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("GATHER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"GLACIER","options":["GLA-cier","gla-CIER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("GLACIER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"GLOBAL","options":["GLO-bal","glo-BAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("GLOBAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"GOLDEN","options":["GOL-den","gol-DEN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("GOLDEN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"GOSSIP","options":["GOS-sip","gos-SIP"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("GOSSIP")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"GRAMMAR","options":["GRAM-mar","gram-MAR"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("GRAMMAR")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"GRATEFUL","options":["GRATE-ful","grate-FUL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("GRATEFUL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"GRAVEL","options":["GRA-vel","gra-VEL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("GRAVEL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"GUILTY","options":["GUIL-ty","guil-TY"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("GUILTY")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HABIT","options":["HA-bit","ha-BIT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HABIT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HAMMER","options":["HAM-mer","ham-MER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HAMMER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HANDLE","options":["HAN-dle","han-DLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HANDLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HARBOR","options":["HAR-bor","har-BOR"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HARBOR")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HELMET","options":["HEL-met","hel-MET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HELMET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HIDDEN","options":["HID-den","hid-DEN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HIDDEN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HOLLOW","options":["HOL-low","hol-LOW"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HOLLOW")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HONEST","options":["HON-est","hon-EST"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HONEST")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HONOR","options":["HON-or","hon-OR"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HONOR")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HORROR","options":["HOR-ror","hor-ROR"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HORROR")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HOSTAGE","options":["HOS-tage","hos-TAGE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HOSTAGE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HUMBLE","options":["HUM-ble","hum-BLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HUMBLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HURDLE","options":["HUR-dle","hur-DLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HURDLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ICON","options":["I-con","i-CON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ICON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"IMPACT","options":["IM-pact","im-PACT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("IMPACT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"INCOME","options":["IN-come","in-COME"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("INCOME")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"INFANT","options":["IN-fant","in-FANT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("INFANT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"INSECT","options":["IN-sect","in-SECT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("INSECT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"INSTANT","options":["IN-stant","in-STANT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("INSTANT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"IRON","options":["I-ron","i-RON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("IRON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ITEM","options":["I-tem","i-TEM"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ITEM")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"JOURNEY","options":["JOUR-ney","jour-NEY"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("JOURNEY")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"JOYFUL","options":["JOY-ful","joy-FUL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("JOYFUL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"JUNGLE","options":["JUN-gle","jun-GLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("JUNGLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"JUSTICE","options":["JUS-tice","jus-TICE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("JUSTICE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"KENNEL","options":["KEN-nel","ken-NEL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("KENNEL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"KINGDOM","options":["KING-dom","king-DOM"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("KINGDOM")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"KITTEN","options":["KIT-ten","kit-TEN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("KITTEN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"LABEL","options":["LA-bel","la-BEL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("LABEL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"LEGEND","options":["LE-gend","le-GEND"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("LEGEND")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"LESSON","options":["LES-son","les-SON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("LESSON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"LEVEL","options":["LE-vel","le-VEL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("LEVEL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"LEMON","options":["LE-mon","le-MON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("LEMON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"LIMIT","options":["LI-mit","li-MIT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("LIMIT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"LIQUID","options":["LI-quid","li-QUID"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("LIQUID")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"LOGIC","options":["LO-gic","lo-GIC"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("LOGIC")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"LOYAL","options":["LOY-al","loy-AL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("LOYAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"LUMBER","options":["LUM-ber","lum-BER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("LUMBER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MADNESS","options":["MAD-ness","mad-NESS"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MADNESS")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MAGIC","options":["MA-gic","ma-GIC"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MAGIC")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MAIDEN","options":["MAI-den","mai-DEN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MAIDEN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MAMMAL","options":["MAM-mal","mam-MAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MAMMAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MANNER","options":["MAN-ner","man-NER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MANNER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MARGIN","options":["MAR-gin","mar-GIN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MARGIN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MEDAL","options":["ME-dal","me-DAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MEDAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MELON","options":["ME-lon","me-LON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MELON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MENTAL","options":["MEN-tal","men-TAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MENTAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MERCY","options":["MER-cy","mer-CY"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MERCY")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"METAL","options":["ME-tal","me-TAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("METAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MINOR","options":["MI-nor","mi-NOR"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MINOR")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MISSION","options":["MIS-sion","mis-SION"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MISSION")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MOBILE","options":["MO-bile","mo-BILE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MOBILE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MORAL","options":["MO-ral","mo-RAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MORAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MORTAL","options":["MOR-tal","mor-TAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MORTAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MUFFIN","options":["MUF-fin","muf-FIN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MUFFIN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"MUSTARD","options":["MUS-tard","mus-TARD"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("MUSTARD")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"NAPKIN","options":["NAP-kin","nap-KIN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("NAPKIN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"NATIVE","options":["NA-tive","na-TIVE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("NATIVE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"NEEDLE","options":["NEE-dle","nee-DLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("NEEDLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"NOBLE","options":["NO-ble","no-BLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("NOBLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"NONSENSE","options":["NON-sense","non-SENSE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("NONSENSE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"NOVEL","options":["NO-vel","no-VEL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("NOVEL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"NUTMEG","options":["NUT-meg","nut-MEG"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("NUTMEG")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"OCEAN","options":["O-cean","o-CEAN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("OCEAN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"OMEN","options":["O-men","o-MEN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("OMEN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ORBIT","options":["OR-bit","or-BIT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ORBIT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ORDER","options":["OR-der","or-DER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ORDER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ORPHAN","options":["OR-phan","or-PHAN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ORPHAN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"OTTER","options":["OT-ter","ot-TER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("OTTER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"OUTER","options":["OU-ter","ou-TER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("OUTER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"OUTLET","options":["OUT-let","out-LET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("OUTLET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"OVEN","options":["O-ven","o-VEN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("OVEN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"OVER","options":["O-ver","o-VER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("OVER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PACKAGE","options":["PACK-age","pack-AGE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PACKAGE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PADDLE","options":["PAD-dle","pad-DLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PADDLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PANTHER","options":["PAN-ther","pan-THER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PANTHER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PARCEL","options":["PAR-cel","par-CEL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PARCEL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PARTNER","options":["PART-ner","part-NER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PARTNER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PASSION","options":["PAS-sion","pas-SION"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PASSION")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PASTURE","options":["PAS-ture","pas-TURE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PASTURE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PATENT","options":["PA-tent","pa-TENT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PATENT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PEACEFUL","options":["PEACE-ful","peace-FUL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PEACEFUL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PEBBLE","options":["PEB-ble","peb-BLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PEBBLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PEDAL","options":["PE-dal","pe-DAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PEDAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PENGUIN","options":["PEN-guin","pen-GUIN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PENGUIN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PEPPER","options":["PEP-per","pep-PER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PEPPER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PHANTOM","options":["PHAN-tom","phan-TOM"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PHANTOM")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PILLOW","options":["PIL-low","pil-LOW"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PILLOW")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PIRATE","options":["PI-rate","pi-RATE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PIRATE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PITCHER","options":["PITCH-er","pitch-ER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PITCHER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PLANET","options":["PLA-net","pla-NET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PLANET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PLASTER","options":["PLAS-ter","plas-TER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PLASTER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PLEASANT","options":["PLEA-sant","plea-SANT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PLEASANT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PLUMBER","options":["PLUM-ber","plum-BER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PLUMBER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"POISON","options":["POI-son","poi-SON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("POISON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HARVEST","options":["HAR-vest","har-VEST"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HARVEST")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PUMPKIN","options":["PUMP-kin","pump-KIN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PUMPKIN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"PUPPET","options":["PUP-pet","pup-PET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("PUPPET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"RABBIT","options":["RAB-bit","rab-BIT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("RABBIT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"RANDOM","options":["RAN-dom","ran-DOM"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("RANDOM")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"RANSOM","options":["RAN-som","ran-SOM"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("RANSOM")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"RAPID","options":["RA-pid","ra-PID"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("RAPID")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"RASCAL","options":["RAS-cal","ras-CAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("RASCAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"RAVEN","options":["RA-ven","ra-VEN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("RAVEN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"REASON","options":["REA-son","rea-SON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("REASON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"RESCUE","options":["RES-cue","res-CUE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("RESCUE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"RIBBON","options":["RIB-bon","rib-BON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("RIBBON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"RIDDLE","options":["RID-dle","rid-DLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("RIDDLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"RIVER","options":["RI-ver","ri-VER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("RIVER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ROBBER","options":["ROB-ber","rob-BER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ROBBER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ROCKET","options":["ROC-ket","roc-KET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ROCKET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ROSTER","options":["ROS-ter","ros-TER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ROSTER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"RUBBER","options":["RUB-ber","rub-BER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("RUBBER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"RUSTIC","options":["RUS-tic","rus-TIC"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("RUSTIC")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SADDLE","options":["SAD-dle","sad-DLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SADDLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SAFETY","options":["SAFE-ty","safe-TY"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SAFETY")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SALMON","options":["SAL-mon","sal-MON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SALMON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SAMPLE","options":["SAM-ple","sam-PLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SAMPLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SANDAL","options":["SAN-dal","san-DAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SANDAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SATIN","options":["SA-tin","sa-TIN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SATIN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SAVAGE","options":["SAV-age","sav-AGE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SAVAGE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SCATTER","options":["SCAT-ter","scat-TER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SCATTER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SECRET","options":["SE-cret","se-CRET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SECRET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SELDOM","options":["SEL-dom","sel-DOM"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SELDOM")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SETTLE","options":["SET-tle","set-TLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SETTLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SHADOW","options":["SHA-dow","sha-DOW"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SHADOW")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SHALLOW","options":["SHAL-low","shal-LOW"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SHALLOW")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SHELTER","options":["SHEL-ter","shel-TER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SHELTER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SIGNAL","options":["SIG-nal","sig-NAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SIGNAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SILVER","options":["SIL-ver","sil-VER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SILVER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SIMPLE","options":["SIM-ple","sim-PLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SIMPLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SINGLE","options":["SIN-gle","sin-GLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SINGLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SISTER","options":["SIS-ter","sis-TER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SISTER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SLENDER","options":["SLEN-der","slen-DER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SLENDER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SLIPPER","options":["SLIP-per","slip-PER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SLIPPER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SOCCER","options":["SOC-cer","soc-CER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SOCCER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SOLDIER","options":["SOL-dier","sol-DIER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SOLDIER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SOLEMN","options":["SOL-emn","sol-EMN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SOLEMN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SPIRAL","options":["SPI-ral","spi-RAL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SPIRAL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"STANDARD","options":["STAND-ard","stand-ARD"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("STANDARD")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"STAPLE","options":["STA-ple","sta-PLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("STAPLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"STEEPLE","options":["STEE-ple","stee-PLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("STEEPLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"STOMACH","options":["STO-mach","sto-MACH"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("STOMACH")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"STORY","options":["STO-ry","sto-RY"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("STORY")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"STRUGGLE","options":["STRUG-gle","strug-GLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("STRUGGLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SUBJECT","options":["SUB-ject","sub-JECT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SUBJECT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SUDDEN","options":["SUD-den","sud-DEN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SUDDEN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SUGAR","options":["SU-gar","su-GAR"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SUGAR")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SUMMON","options":["SUM-mon","sum-MON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SUMMON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SUMMER","options":["SUM-mer","sum-MER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SUMMER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SURFACE","options":["SUR-face","sur-FACE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SURFACE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SURPLUS","options":["SUR-plus","sur-PLUS"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SURPLUS")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SWALLOW","options":["SWAL-low","swal-LOW"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SWALLOW")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SYMBOL","options":["SYM-bol","sym-BOL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SYMBOL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"SYSTEM","options":["SYS-tem","sys-TEM"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("SYSTEM")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TALENT","options":["TA-lent","ta-LENT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TALENT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TARGET","options":["TAR-get","tar-GET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TARGET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TEMPLE","options":["TEM-ple","tem-PLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TEMPLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TENDER","options":["TEN-der","ten-DER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TENDER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"THUNDER","options":["THUN-der","thun-DER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("THUNDER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TICKET","options":["TICK-et","tick-ET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TICKET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TIMBER","options":["TIM-ber","tim-BER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TIMBER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TITLE","options":["TI-tle","ti-TLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TITLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TOKEN","options":["TO-ken","to-KEN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TOKEN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TOPIC","options":["TO-pic","to-PIC"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TOPIC")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TOWER","options":["TOW-er","tow-ER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TOWER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TRAVEL","options":["TRA-vel","tra-VEL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TRAVEL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TRIGGER","options":["TRIG-ger","trig-GER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TRIGGER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TROUBLE","options":["TROU-ble","trou-BLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TROUBLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TRUMPET","options":["TRUM-pet","trum-PET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TRUMPET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TUNNEL","options":["TUN-nel","tun-NEL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TUNNEL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"TURTLE","options":["TUR-tle","tur-TLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("TURTLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"UNCLE","options":["UN-cle","un-CLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("UNCLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"UPPER","options":["UP-per","up-PER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("UPPER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"VALLEY","options":["VAL-ley","val-LEY"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("VALLEY")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"VALUE","options":["VA-lue","va-LUE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("VALUE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"VELVET","options":["VEL-vet","vel-VET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("VELVET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"VESSEL","options":["VES-sel","ves-SEL"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("VESSEL")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"VICTIM","options":["VIC-tim","vic-TIM"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("VICTIM")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"VILLAGE","options":["VIL-lage","vil-LAGE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("VILLAGE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"VINTAGE","options":["VIN-tage","vin-TAGE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("VINTAGE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"VIRTUE","options":["VIR-tue","vir-TUE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("VIRTUE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"VOLUME","options":["VOL-ume","vol-UME"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("VOLUME")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"VULTURE","options":["VUL-ture","vul-TURE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("VULTURE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"WAFFLE","options":["WAF-fle","waf-FLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("WAFFLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"WANDER","options":["WAN-der","wan-DER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("WANDER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"WEAPON","options":["WEA-pon","wea-PON"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("WEAPON")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"WEATHER","options":["WEATH-er","weath-ER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("WEATHER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"WHISPER","options":["WHIS-per","whis-PER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("WHISPER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"WICKED","options":["WICK-ed","wick-ED"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("WICKED")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"WIDOW","options":["WI-dow","wi-DOW"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("WIDOW")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"WINDOW","options":["WIN-dow","win-DOW"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("WINDOW")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"WINTER","options":["WIN-ter","win-TER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("WINTER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"WITNESS","options":["WIT-ness","wit-NESS"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("WITNESS")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"WONDER","options":["WON-der","won-DER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("WONDER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"WORSHIP","options":["WOR-ship","wor-SHIP"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("WORSHIP")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"WRINKLE","options":["WRIN-kle","wrin-KLE"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("WRINKLE")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"YELLOW","options":["YEL-low","yel-LOW"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("YELLOW")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ZEALOUS","options":["ZEA-lous","zea-LOUS"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ZEALOUS")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ZIGZAG","options":["ZIG-zag","zig-ZAG"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ZIGZAG")}});

  // === ROUND 2 AUTO-EXPANDED ===
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ANCHOR","options":["AN-chor","an-CHOR"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ANCHOR")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"ANTLER","options":["ANT-ler","ant-LER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("ANTLER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BARLEY","options":["BAR-ley","bar-LEY"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BARLEY")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BISCUIT","options":["BIS-cuit","bis-CUIT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BISCUIT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BLANKET","options":["BLAN-ket","blan-KET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BLANKET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BOULDER","options":["BOUL-der","boul-DER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BOULDER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BRACELET","options":["BRACE-let","brace-LET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BRACELET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"BUCKET","options":["BUCK-et","buck-ET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("BUCKET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CANVAS","options":["CAN-vas","can-VAS"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CANVAS")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CARPET","options":["CAR-pet","car-PET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CARPET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"CIRCUIT","options":["CIR-cuit","cir-CUIT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("CIRCUIT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"COUSIN","options":["COU-sin","cou-SIN"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("COUSIN")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"DESERT","options":["DES-ert","des-ERT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("DESERT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"DONKEY","options":["DON-key","don-KEY"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("DONKEY")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"EMBER","options":["EM-ber","em-BER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("EMBER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"FAUCET","options":["FAU-cet","fau-CET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("FAUCET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"GOBLET","options":["GOB-let","gob-LET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("GOBLET")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"HAMSTER","options":["HAM-ster","ham-STER"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("HAMSTER")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"INSECT","options":["IN-sect","in-SECT"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("INSECT")}});
  pool.push({"instruction":"Where is the stress?","fields":{"word":"JACKET","options":["JACK-et","jack-ET"],"correctAnswerIndex":0,"hint":"Listen for the loudest syllable.","phoneticHint":getIpa("JACKET")}});
console.log(`  syllableStress pool: ${pool.length}`);
  return pool;
};

