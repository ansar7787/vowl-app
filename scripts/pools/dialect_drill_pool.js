// Dialect Drill: 600 unique words with dialect pronunciation variations
const getIpa = require(__dirname + '/get_ipa.js');
module.exports = function() {
  const pool = [];
  const words = [
    // Schedule type words (UK vs US pronunciation)
    ['schedule','SHED-yool','SKED-yool',0,'British uses /ʃ/.'],['garage','GAR-ahzh','guh-RAHJ',0,'British stresses 1st syllable.'],
    ['tomato','tuh-MAH-toh','tuh-MAY-toh',0,'British uses /ɑː/.'],['either','EYE-thuh','EE-thuh',0,'Both are standard.'],
    ['neither','NYE-thuh','NEE-thuh',0,'Both are standard.'],['vase','vahz','vays',0,'British long a.'],
    ['route','root','rowt',0,'British uses /uː/.'],['privacy','PRIV-uh-see','PRY-vuh-see',0,'British short i.'],
    ['aluminum','al-yoo-MIN-ee-um','ah-LOO-min-um',0,'British adds extra syllable.'],
    ['advertisement','ad-VER-tis-muhnt','AD-ver-tize-muhnt',0,'Stress differs.'],
    ['leisure','LEZ-uh','LEE-zhur',0,'British uses /e/.'],['controversy','con-TROV-er-see','CON-truh-ver-see',0,'Stress shift.'],
    ['oregano','or-eh-GAH-noh','oh-REG-uh-noh',0,'Stress on different syllable.'],
    ['basil','BAZ-il','BAY-zil',0,'Vowel difference.'],['herb','herb','erb',0,'British keeps /h/.'],
    ['lieutenant','lef-TEN-uhnt','loo-TEN-uhnt',0,'British unique pronunciation.'],
    ['clerk','klark','klerk',0,'British uses /ɑː/.'],['derby','DAR-bee','DUR-bee',0,'Vowel shift.'],
    ['zebra','ZEB-ruh','ZEE-bruh',0,'First vowel differs.'],['beta','BEE-tuh','BAY-tuh',0,'Greek letter.'],
    ['data','DAH-tuh','DAY-tuh',0,'First vowel varies.'],['status','STAT-us','STAY-tus',0,'First vowel.'],
    ['mobile','MOH-bile','MOH-buhl',0,'Final syllable.'],['missile','MIS-aisle','MIS-ul',0,'Final syllable.'],
    ['agile','AJ-aisle','AJ-ul',0,'Final syllable.'],['fertile','FUR-taisle','FUR-tul',0,'Final syllable.'],
    ['hostile','HOS-taisle','HOS-tul',0,'Final syllable.'],['fragile','FRAJ-aisle','FRAJ-ul',0,'Final syllable.'],
    ['futile','FYOO-taisle','FYOO-tul',0,'Final syllable.'],['docile','DOH-saisle','DOS-ul',0,'Final syllable.'],
    ['semi','SEM-ee','SEM-eye',0,'Final vowel.'],['anti','AN-tee','AN-tie',0,'Final vowel.'],
    ['multi','MUL-tee','MUL-tie',0,'Final vowel.'],['vitamin','VIT-uh-min','VYE-tuh-min',0,'First vowel.'],
    ['premier','PREM-ee-uh','pruh-MEER',0,'Stress shift.'],['ballet','BAL-ay','ba-LAY',0,'French origin.'],
    ['filet','FIL-ay','fih-LAY',0,'French origin.'],['buffet','BUF-ay','buh-FAY',0,'French origin.'],
    ['croissant','KWAS-on','kruh-SONT',0,'French loan.'],['niche','neesh','nich',0,'French vs anglicized.'],
    ['renaissance','ruh-NAY-sons','REN-uh-sahns',0,'Stress and vowel.'],['envelope','EN-veh-lohp','ON-veh-lohp',0,'First vowel.'],
    // Australian/NZ variations
    ['dance','dahns','dans',0,'Broad vs general.'],['chance','chahns','chans',0,'Long vs short a.'],
    ['France','Frahns','Frans',0,'Long vs short a.'],['bath','bahth','bath',0,'Long vs short a.'],
    ['grass','grahs','gras',0,'Long vs short a.'],['class','klahs','klas',0,'Long vs short a.'],
    ['fast','fahst','fast',0,'Long vs short a.'],['last','lahst','last',0,'Long vs short a.'],
    ['past','pahst','past',0,'Long vs short a.'],['cast','kahst','kast',0,'Long vs short a.'],
    ['mask','mahsk','mask',0,'Long/short a.'],['task','tahsk','task',0,'Long/short a.'],
    ['ask','ahsk','ask',0,'Long/short a.'],['basket','BAH-skit','BAS-kit',0,'Long/short a.'],
    ['master','MAH-stuh','MAS-ter',0,'Long/short a.'],['disaster','dih-ZAH-stuh','dih-ZAS-ter',0,'Long/short a.'],
    ['castle','KAH-sul','KAS-ul',0,'Long/short a.'],['plaster','PLAH-stuh','PLAS-ter',0,'Long/short a.'],
    ['pastor','PAH-stuh','PAS-ter',0,'Long/short a.'],['rascal','RAH-skul','RAS-kul',0,'Long/short a.'],
    // R-dropping (rhotic vs non-rhotic)
    ['car','kah','kar',0,'Non-rhotic drops /r/.'],['far','fah','far',0,'Non-rhotic drops /r/.'],
    ['bar','bah','bar',0,'Non-rhotic drops /r/.'],['star','stah','star',0,'Non-rhotic drops /r/.'],
    ['park','pahk','park',0,'Non-rhotic drops /r/.'],['part','paht','part',0,'Non-rhotic drops /r/.'],
    ['heart','haht','hart',0,'Non-rhotic drops /r/.'],['start','staht','start',0,'Non-rhotic drops /r/.'],
    ['smart','smaht','smart',0,'Non-rhotic drops /r/.'],['chart','chaht','chart',0,'Non-rhotic drops /r/.'],
    ['turn','tuhn','turn',0,'Non-rhotic drops /r/.'],['burn','buhn','burn',0,'Non-rhotic drops /r/.'],
    ['learn','luhn','learn',0,'Non-rhotic drops /r/.'],['firm','fuhm','firm',0,'Non-rhotic drops /r/.'],
    ['word','wuhd','word',0,'Non-rhotic drops /r/.'],['bird','buhd','bird',0,'Non-rhotic drops /r/.'],
    ['third','thuhd','third',0,'Non-rhotic drops /r/.'],['world','wuhld','world',0,'Non-rhotic drops /r/.'],
    ['girl','guhl','girl',0,'Non-rhotic drops /r/.'],['hurt','huht','hurt',0,'Non-rhotic drops /r/.'],
    // T-flapping (American)
    ['water','WAW-tuh','WAH-dur',0,'T vs flapped D.'],['butter','BUH-tuh','BUH-dur',0,'T vs flap.'],
    ['better','BEH-tuh','BEH-dur',0,'T vs flap.'],['letter','LEH-tuh','LEH-dur',0,'T vs flap.'],
    ['matter','MAH-tuh','MAH-dur',0,'T vs flap.'],['city','SIH-tee','SIH-dee',0,'T vs flap.'],
    ['pity','PIH-tee','PIH-dee',0,'T vs flap.'],['pretty','PRIH-tee','PRIH-dee',0,'T vs flap.'],
    ['little','LIH-tul','LIH-dul',0,'T/flap.'],['bottle','BOH-tul','BAH-dul',0,'T/flap.'],
    ['total','TOH-tul','TOH-dul',0,'T/flap.'],['metal','MEH-tul','MEH-dul',0,'T/flap.'],
    ['petal','PEH-tul','PEH-dul',0,'T/flap.'],['fatal','FAY-tul','FAY-dul',0,'T/flap.'],
    ['vital','VYE-tul','VYE-dul',0,'T/flap.'],['getting','GEH-ting','GEH-ding',0,'T/flap.'],
    ['sitting','SIH-ting','SIH-ding',0,'T/flap.'],['putting','PUH-ting','PUH-ding',0,'T/flap.'],
    ['cutting','KUH-ting','KUH-ding',0,'T/flap.'],['meeting','MEE-ting','MEE-ding',0,'T/flap.'],
    // Glottal stop (Cockney/estuary)
    ['bottle','BOH?ul','BOT-ul',0,'Glottal replaces /t/.'],['butter','BUH?uh','BUT-uh',0,'Glottal stop.'],
    ['kitten','KIH?un','KIT-un',0,'Glottal stop.'],['mitten','MIH?un','MIT-un',0,'Glottal stop.'],
    ['button','BUH?un','BUT-un',0,'Glottal stop.'],['cotton','COH?un','COT-un',0,'Glottal stop.'],
    ['rotten','ROH?un','ROT-un',0,'Glottal stop.'],['written','RIH?un','RIT-un',0,'Glottal stop.'],
    ['lotta','LOH?uh','LOT-uh',0,'Glottal stop.'],['gotta','GOH?uh','GOT-uh',0,'Glottal stop.'],
    ['football','FOO?ball','FOOT-ball',0,'Glottal stop.'],['Scotland','SCOH?lund','SCOT-lund',0,'Glottal stop.'],
    ['Scotland','SCOH?lund','SCOT-lund',0,'Glottal stop.'],['hatful','HAH?ful','HAT-ful',0,'Glottal stop.'],
    ['outpost','OW?pohst','OWT-pohst',0,'Glottal stop.'],['outright','OW?ryt','OWT-ryt',0,'Glottal stop.'],
    ['nightmare','NY?mare','NYT-mare',0,'Glottal stop.'],['seatbelt','SEE?belt','SEET-belt',0,'Glottal stop.'],
    ['footprint','FOO?print','FOOT-print',0,'Glottal stop.'],['hotdog','HOH?dog','HOT-dog',0,'Glottal stop.'],
    // Vowel mergers (cot-caught, pin-pen, Mary-merry-marry)
    ['cot','kot','kawt',0,'Unmerged.'],['caught','kawt','kot',0,'Unmerged.'],
    ['don','don','dawn',0,'Unmerged.'],['dawn','dawn','don',0,'Unmerged.'],
    ['stock','stok','stawk',0,'Unmerged.'],['stalk','stawk','stok',0,'Unmerged.'],
    ['collar','KOL-ur','KAWL-ur',0,'Unmerged.'],['caller','KAWL-ur','KOL-ur',0,'Unmerged.'],
    ['pin','pin','pen',0,'Unmerged.'],['pen','pen','pin',0,'Unmerged.'],
    ['tin','tin','ten',0,'Unmerged.'],['ten','ten','tin',0,'Unmerged.'],
    ['sin','sin','sen',0,'Unmerged.'],['send','send','sind',0,'Unmerged.'],
    ['win','win','wen',0,'Unmerged.'],['when','wen','win',0,'Unmerged.'],
    ['him','him','hem',0,'Unmerged.'],['hem','hem','him',0,'Unmerged.'],
    ['Mary','MARE-ee','MERRY',0,'3-way split.'],['merry','MERRY','MARE-ee',0,'3-way split.'],
    // Scottish English features
    ['house','hoose','howse',0,'Scottish /uː/.'],['about','aboot','uhbowt',0,'Scottish /uː/.'],
    ['out','oot','owt',0,'Scottish /uː/.'],['mouth','mooth','mowth',0,'Scottish /uː/.'],
    ['round','roond','rownd',0,'Scottish /uː/.'],['down','doon','down',0,'Scottish /uː/.'],
    ['town','toon','town',0,'Scottish /uː/.'],['sound','soond','sownd',0,'Scottish /uː/.'],
    ['found','foond','fownd',0,'Scottish /uː/.'],['ground','groond','grownd',0,'Scottish /uː/.'],
    ['night','nicht','nyt',0,'Scottish /x/.'],['light','licht','lyt',0,'Scottish /x/.'],
    ['right','richt','ryt',0,'Scottish /x/.'],['might','micht','myt',0,'Scottish /x/.'],
    ['fight','ficht','fyt',0,'Scottish /x/.'],['sight','sicht','syt',0,'Scottish /x/.'],
    ['bright','bricht','bryt',0,'Scottish /x/.'],['tight','ticht','tyt',0,'Scottish /x/.'],
    ['knight','knicht','nyt',0,'Scottish /x/.'],['flight','flicht','flyt',0,'Scottish /x/.'],
    // Indian English features
    ['think','tink','think',0,'Dental stop.'],['that','dat','that',0,'Dental stop.'],
    ['three','tree','three',0,'Dental stop.'],['this','dis','this',0,'Dental stop.'],
    ['those','doze','those',0,'Dental stop.'],['them','dem','them',0,'Dental stop.'],
    ['there','dere','there',0,'Dental stop.'],['then','den','then',0,'Dental stop.'],
    ['with','wid','with',0,'Dental stop.'],['math','mat','math',0,'Dental stop.'],
    ['both','bot','both',0,'Dental stop.'],['truth','troot','truth',0,'Dental stop.'],
    ['youth','yoot','youth',0,'Dental stop.'],['faith','fait','faith',0,'Dental stop.'],
    ['health','helt','health',0,'Dental stop.'],['worth','wort','worth',0,'Dental stop.'],
    ['birth','birt','birth',0,'Dental stop.'],['earth','ert','earth',0,'Dental stop.'],
    ['growth','grot','growth',0,'Dental stop.'],['death','det','death',0,'Dental stop.'],
    // Caribbean English
    ['Monday','MON-dee','MON-day',0,'Final vowel.'],['Sunday','SUN-dee','SUN-day',0,'Final vowel.'],
    ['birthday','BIRT-dee','BIRTH-day',0,'Final vowel.'],['holiday','HOL-ih-dee','HOL-ih-day',0,'Final vowel.'],
    ['yesterday','YES-tuh-dee','YES-ter-day',0,'Final vowel.'],['today','tuh-DEE','tuh-DAY',0,'Final vowel.'],
    ['Friday','FRY-dee','FRY-day',0,'Final vowel.'],['Saturday','SAT-uh-dee','SAT-er-day',0,'Final vowel.'],
    ['Tuesday','TYOOZ-dee','TOOZ-day',0,'Final vowel.'],['Wednesday','WENZ-dee','WENZ-day',0,'Final vowel.'],
    ['Thursday','THURZ-dee','THURZ-day',0,'Final vowel.'],['away','uh-WEE','uh-WAY',0,'Final vowel.'],
    ['play','plee','play',0,'Vowel shift.'],['say','see','say',0,'Vowel shift.'],
    ['way','wee','way',0,'Vowel shift.'],['day','dee','day',0,'Vowel shift.'],
    ['may','mee','may',0,'Vowel shift.'],['pay','pee','pay',0,'Vowel shift.'],
    ['stay','stee','stay',0,'Vowel shift.'],['okay','oh-KEE','oh-KAY',0,'Vowel shift.'],
    // South African English
    ['kit','ket','kit',0,'Vowel centralization.'],['bit','bet','bit',0,'Vowel shift.'],
    ['sit','set','sit',0,'Vowel shift.'],['six','sex','six',0,'Vowel shift.'],
    ['fish','fesh','fish',0,'Vowel shift.'],['dish','desh','dish',0,'Vowel shift.'],
    ['wish','wesh','wish',0,'Vowel shift.'],['lip','lep','lip',0,'Vowel shift.'],
    ['hip','hep','hip',0,'Vowel shift.'],['tip','tep','tip',0,'Vowel shift.'],
    ['ship','shep','ship',0,'Vowel shift.'],['chip','chep','chip',0,'Vowel shift.'],
    ['grip','grep','grip',0,'Vowel shift.'],['trip','trep','trip',0,'Vowel shift.'],
    ['slip','slep','slip',0,'Vowel shift.'],['drip','drep','drip',0,'Vowel shift.'],
    ['strip','strep','strip',0,'Vowel shift.'],['whip','whep','whip',0,'Vowel shift.'],
    ['flip','flep','flip',0,'Vowel shift.'],['skip','skep','skip',0,'Vowel shift.'],
  ];
  for (const [word,o1,o2,ans,hint] of words) {
    pool.push({
      instruction: 'Choose the correct pronunciation.',
      fields: { word, options: [o1,o2], correctAnswerIndex: ans, hint, phoneticHint: getIpa(word) }
    });
  }
  
  // === ROUND 2 AUTO-EXPANDED ===
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"autumn","options":["AW-tuhm","AH-tuhm"],"correctAnswerIndex":0,"hint":"Vowel varies.","phoneticHint":getIpa("autumn")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"biscuit","options":["BIS-kit","BIS-kwit"],"correctAnswerIndex":0,"hint":"UK vs US.","phoneticHint":getIpa("biscuit")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"bonnet","options":["BON-it","BAH-nit"],"correctAnswerIndex":0,"hint":"Vowel shift.","phoneticHint":getIpa("bonnet")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"brochure","options":["BROH-shur","broh-SHUR"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("brochure")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"caramel","options":["KAR-uh-mul","KARE-uh-mel"],"correctAnswerIndex":0,"hint":"Syllable count.","phoneticHint":getIpa("caramel")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"Caribbean","options":["kar-ib-BEE-un","kuh-RIB-ee-un"],"correctAnswerIndex":0,"hint":"Stress shift.","phoneticHint":getIpa("Caribbean")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"carousel","options":["KAR-uh-sel","kare-uh-SEL"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("carousel")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"chassis","options":["CHAS-ee","SHAS-ee"],"correctAnswerIndex":0,"hint":"Initial sound.","phoneticHint":getIpa("chassis")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"chauffeur","options":["SHOH-fur","shoh-FUR"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("chauffeur")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"cliche","options":["KLEE-shay","klih-SHAY"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("cliche")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"clique","options":["kleek","klik"],"correctAnswerIndex":0,"hint":"Final sound.","phoneticHint":getIpa("clique")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"comparable","options":["KOM-pruh-bul","kum-PARE-uh-bul"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("comparable")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"coupon","options":["KOO-pon","KYOO-pon"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("coupon")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"debris","options":["DEB-ree","duh-BREE"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("debris")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"decor","options":["DAY-kor","duh-KOR"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("decor")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"depot","options":["DEP-oh","DEE-poh"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("depot")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"detour","options":["DEE-toor","dih-TOOR"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("detour")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"dossier","options":["DOS-ee-ay","DAH-see-ay"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("dossier")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"duvet","options":["DOO-vay","doo-VAY"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("duvet")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"espionage","options":["ES-pee-uh-nahj","ES-pee-uh-nij"],"correctAnswerIndex":0,"hint":"Final.","phoneticHint":getIpa("espionage")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"fiance","options":["fee-ON-say","fee-AHN-say"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("fiance")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"flambe","options":["FLOM-bay","flahm-BAY"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("flambe")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"foyer","options":["FOY-er","FOY-ay"],"correctAnswerIndex":0,"hint":"Final.","phoneticHint":getIpa("foyer")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"gourmet","options":["GOR-may","gor-MAY"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("gourmet")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"harassment","options":["HAR-us-ment","huh-RAS-ment"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("harassment")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hyperbole","options":["hy-PER-buh-lee","HY-per-bole"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("hyperbole")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"lingerie","options":["LON-zhuh-ray","lahn-zhuh-RAY"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("lingerie")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"manoeuvre","options":["muh-NOO-vur","muh-NOO-ver"],"correctAnswerIndex":0,"hint":"Final vowel.","phoneticHint":getIpa("manoeuvre")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"nonchalant","options":["NON-shuh-lunt","non-shuh-LAHNT"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("nonchalant")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"papaya","options":["puh-PY-uh","puh-PAH-yuh"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("papaya")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"afternoon","options":["AHF-tuh-noon","AF-ter-noon"],"correctAnswerIndex":0,"hint":"Broad vowel.","phoneticHint":getIpa("afternoon")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"banana","options":["buh-NAH-nuh","buh-NAN-uh"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("banana")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"castle","options":["KAH-sul","KAS-ul"],"correctAnswerIndex":0,"hint":"Long/short a.","phoneticHint":getIpa("castle")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"demand","options":["dih-MAHND","dih-MAND"],"correctAnswerIndex":0,"hint":"Vowel length.","phoneticHint":getIpa("demand")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"example","options":["ig-ZAHM-pul","ig-ZAM-pul"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("example")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"giraffe","options":["juh-RAHF","juh-RAF"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("giraffe")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"graph","options":["grahf","graf"],"correctAnswerIndex":0,"hint":"Vowel length.","phoneticHint":getIpa("graph")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"laughter","options":["LAHF-tuh","LAF-ter"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("laughter")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"palm","options":["pahm","pam"],"correctAnswerIndex":0,"hint":"Long a.","phoneticHint":getIpa("palm")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"rather","options":["RAH-thuh","RA-ther"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("rather")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"book","options":["buk","book"],"correctAnswerIndex":0,"hint":"Scottish short /u/.","phoneticHint":getIpa("book")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"look","options":["luk","look"],"correctAnswerIndex":0,"hint":"Scottish.","phoneticHint":getIpa("look")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"good","options":["gud","good"],"correctAnswerIndex":0,"hint":"Scottish.","phoneticHint":getIpa("good")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"would","options":["wud","wood"],"correctAnswerIndex":0,"hint":"Scottish.","phoneticHint":getIpa("would")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"could","options":["kud","kood"],"correctAnswerIndex":0,"hint":"Scottish.","phoneticHint":getIpa("could")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"should","options":["shud","shood"],"correctAnswerIndex":0,"hint":"Scottish.","phoneticHint":getIpa("should")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"pull","options":["pul","pool"],"correctAnswerIndex":0,"hint":"Scottish.","phoneticHint":getIpa("pull")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"push","options":["push","poosh"],"correctAnswerIndex":0,"hint":"Scottish.","phoneticHint":getIpa("push")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"foot","options":["fut","foot"],"correctAnswerIndex":0,"hint":"Scottish.","phoneticHint":getIpa("foot")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"put","options":["put","poot"],"correctAnswerIndex":0,"hint":"Scottish.","phoneticHint":getIpa("put")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"vegetable","options":["VEJ-tuh-bul","VEJ-eh-TAB-ul"],"correctAnswerIndex":0,"hint":"Syllable count.","phoneticHint":getIpa("vegetable")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"comfortable","options":["KUMF-tuh-bul","KUM-FOR-TAB-ul"],"correctAnswerIndex":0,"hint":"Syllables.","phoneticHint":getIpa("comfortable")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"actually","options":["AK-choo-uh-lee","AK-CHEW-uh-lee"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("actually")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"definitely","options":["DEF-uh-nit-lee","DEF-IN-IT-lee"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("definitely")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"immediately","options":["ih-MEE-dee-ut-lee","IM-MEE-DEE-ATE-lee"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("immediately")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"interesting","options":["IN-trest-ing","IN-TER-EST-ing"],"correctAnswerIndex":0,"hint":"Syllables.","phoneticHint":getIpa("interesting")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"temperature","options":["TEM-pruh-chur","TEM-PER-AH-CHUR"],"correctAnswerIndex":0,"hint":"Syllables.","phoneticHint":getIpa("temperature")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"chocolate","options":["CHOK-lut","CHO-CO-LATE"],"correctAnswerIndex":0,"hint":"Syllables.","phoneticHint":getIpa("chocolate")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"different","options":["DIF-runt","DIF-FER-ENT"],"correctAnswerIndex":0,"hint":"Syllables.","phoneticHint":getIpa("different")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"favourite","options":["FAY-vrit","FAY-VOR-ITE"],"correctAnswerIndex":0,"hint":"Syllables.","phoneticHint":getIpa("favourite")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"brother","options":["BRUH-duh","BRUH-ther"],"correctAnswerIndex":0,"hint":"TH stopping.","phoneticHint":getIpa("brother")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"mother","options":["MUH-duh","MUH-ther"],"correctAnswerIndex":0,"hint":"TH stopping.","phoneticHint":getIpa("mother")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"father","options":["FAH-duh","FAH-ther"],"correctAnswerIndex":0,"hint":"TH stopping.","phoneticHint":getIpa("father")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"other","options":["UH-duh","UH-ther"],"correctAnswerIndex":0,"hint":"TH stopping.","phoneticHint":getIpa("other")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"weather","options":["WEH-duh","WEH-ther"],"correctAnswerIndex":0,"hint":"TH stopping.","phoneticHint":getIpa("weather")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"together","options":["tuh-GEH-duh","tuh-GEH-ther"],"correctAnswerIndex":0,"hint":"TH.","phoneticHint":getIpa("together")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"whether","options":["WEH-duh","WEH-ther"],"correctAnswerIndex":0,"hint":"TH stopping.","phoneticHint":getIpa("whether")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"feather","options":["FEH-duh","FEH-ther"],"correctAnswerIndex":0,"hint":"TH stopping.","phoneticHint":getIpa("feather")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"leather","options":["LEH-duh","LEH-ther"],"correctAnswerIndex":0,"hint":"TH stopping.","phoneticHint":getIpa("leather")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"bother","options":["BOH-duh","BOH-ther"],"correctAnswerIndex":0,"hint":"TH stopping.","phoneticHint":getIpa("bother")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"yes","options":["yis","yes"],"correctAnswerIndex":0,"hint":"DRESS vowel raised.","phoneticHint":getIpa("yes")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"pen","options":["pin","pen"],"correctAnswerIndex":0,"hint":"Vowel merger.","phoneticHint":getIpa("pen")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"bed","options":["bid","bed"],"correctAnswerIndex":0,"hint":"Vowel raised.","phoneticHint":getIpa("bed")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"ten","options":["tin","ten"],"correctAnswerIndex":0,"hint":"Vowel merger.","phoneticHint":getIpa("ten")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"get","options":["git","get"],"correctAnswerIndex":0,"hint":"Vowel raised.","phoneticHint":getIpa("get")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"red","options":["rid","red"],"correctAnswerIndex":0,"hint":"Vowel raised.","phoneticHint":getIpa("red")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"head","options":["hid","head"],"correctAnswerIndex":0,"hint":"Vowel raised.","phoneticHint":getIpa("head")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"dead","options":["did","dead"],"correctAnswerIndex":0,"hint":"Vowel raised.","phoneticHint":getIpa("dead")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"said","options":["sid","said"],"correctAnswerIndex":0,"hint":"Vowel raised.","phoneticHint":getIpa("said")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"spread","options":["sprid","spread"],"correctAnswerIndex":0,"hint":"Vowel raised.","phoneticHint":getIpa("spread")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"thirty","options":["TUR-tee","THIR-tee"],"correctAnswerIndex":0,"hint":"TH realization.","phoneticHint":getIpa("thirty")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"three","options":["tree","three"],"correctAnswerIndex":0,"hint":"TH realization.","phoneticHint":getIpa("three")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"film","options":["FILL-um","film"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("film")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"arm","options":["AR-um","arm"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("arm")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"form","options":["FOR-um","form"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("form")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"warm","options":["WAR-um","warm"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("warm")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"worm","options":["WUR-um","wurm"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("worm")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"storm","options":["STOR-um","storm"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("storm")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"charm","options":["CHAR-um","charm"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("charm")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"farm","options":["FAR-um","farm"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("farm")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"alright","options":["ALL-right","aw-RIGHT"],"correctAnswerIndex":0,"hint":"L realization.","phoneticHint":getIpa("alright")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"always","options":["ALL-ways","aw-WAYS"],"correctAnswerIndex":0,"hint":"L.","phoneticHint":getIpa("always")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"already","options":["all-RED-ee","aw-RED-ee"],"correctAnswerIndex":0,"hint":"L.","phoneticHint":getIpa("already")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"although","options":["all-THO","aw-THO"],"correctAnswerIndex":0,"hint":"L.","phoneticHint":getIpa("although")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"altogether","options":["all-tuh-GEH-thur","aw-tuh-GEH-thur"],"correctAnswerIndex":0,"hint":"L.","phoneticHint":getIpa("altogether")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"also","options":["ALL-so","aw-SO"],"correctAnswerIndex":0,"hint":"L.","phoneticHint":getIpa("also")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"alter","options":["ALL-tur","AW-tur"],"correctAnswerIndex":0,"hint":"L.","phoneticHint":getIpa("alter")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"alternative","options":["all-TUR-nuh-tiv","aw-TUR-nuh-tiv"],"correctAnswerIndex":0,"hint":"L.","phoneticHint":getIpa("alternative")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"altitude","options":["ALL-tih-tood","AW-tih-tood"],"correctAnswerIndex":0,"hint":"L.","phoneticHint":getIpa("altitude")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"aluminium","options":["al-yoo-MIN-ee-um","aw-yoo-MIN-ee-um"],"correctAnswerIndex":0,"hint":"L.","phoneticHint":getIpa("aluminium")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"already","options":["all-RED-ee","OR-re-dee"],"correctAnswerIndex":0,"hint":"Vowel shift.","phoneticHint":getIpa("already")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"beautiful","options":["BYOO-tih-ful","BOO-tih-ful"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("beautiful")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"cannot","options":["KAN-not","KEN-not"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("cannot")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"comfortable","options":["KUMF-tuh-bul","KUM-for-tuh-bul"],"correctAnswerIndex":0,"hint":"Full form.","phoneticHint":getIpa("comfortable")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"government","options":["GUV-urn-munt","GUV-ern-ment"],"correctAnswerIndex":0,"hint":"Full form.","phoneticHint":getIpa("government")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"interesting","options":["IN-trest-ing","IN-te-res-ting"],"correctAnswerIndex":0,"hint":"Full.","phoneticHint":getIpa("interesting")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"library","options":["LY-bruh-ree","LY-bra-ree"],"correctAnswerIndex":0,"hint":"Full.","phoneticHint":getIpa("library")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"naturally","options":["NACH-ruh-lee","NA-chur-al-lee"],"correctAnswerIndex":0,"hint":"Full.","phoneticHint":getIpa("naturally")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"probably","options":["PROB-uh-blee","PRO-ba-blee"],"correctAnswerIndex":0,"hint":"Full.","phoneticHint":getIpa("probably")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"temperature","options":["TEM-pruh-chur","TEM-pe-ra-tur"],"correctAnswerIndex":0,"hint":"Full.","phoneticHint":getIpa("temperature")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"brother","options":["BROH-dah","BRUH-ther"],"correctAnswerIndex":0,"hint":"Final vowel.","phoneticHint":getIpa("brother")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"water","options":["WAH-tah","WAW-ter"],"correctAnswerIndex":0,"hint":"Final vowel.","phoneticHint":getIpa("water")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"butter","options":["BUH-tah","BUH-ter"],"correctAnswerIndex":0,"hint":"Final vowel.","phoneticHint":getIpa("butter")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"better","options":["BEH-tah","BEH-ter"],"correctAnswerIndex":0,"hint":"Final vowel.","phoneticHint":getIpa("better")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"letter","options":["LEH-tah","LEH-ter"],"correctAnswerIndex":0,"hint":"Final vowel.","phoneticHint":getIpa("letter")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"matter","options":["MAH-tah","MAH-ter"],"correctAnswerIndex":0,"hint":"Final vowel.","phoneticHint":getIpa("matter")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"laughter","options":["LAHF-tah","LAF-ter"],"correctAnswerIndex":0,"hint":"Final vowel.","phoneticHint":getIpa("laughter")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"teacher","options":["TEE-chah","TEE-cher"],"correctAnswerIndex":0,"hint":"Final vowel.","phoneticHint":getIpa("teacher")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"father","options":["FAH-dah","FAH-ther"],"correctAnswerIndex":0,"hint":"Final vowel.","phoneticHint":getIpa("father")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"gather","options":["GAH-dah","GA-ther"],"correctAnswerIndex":0,"hint":"Final vowel.","phoneticHint":getIpa("gather")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"alright","options":["AH-ight","aw-RIGHT"],"correctAnswerIndex":0,"hint":"L-dropping.","phoneticHint":getIpa("alright")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"almost","options":["AH-most","awl-MOAST"],"correctAnswerIndex":0,"hint":"L-dropping.","phoneticHint":getIpa("almost")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"also","options":["AH-so","awl-SO"],"correctAnswerIndex":0,"hint":"L-dropping.","phoneticHint":getIpa("also")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"although","options":["AH-tho","awl-THO"],"correctAnswerIndex":0,"hint":"L-dropping.","phoneticHint":getIpa("although")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"always","options":["AH-ways","awl-WAYS"],"correctAnswerIndex":0,"hint":"L-dropping.","phoneticHint":getIpa("always")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"calm","options":["CAHM","kalm"],"correctAnswerIndex":0,"hint":"L-dropping.","phoneticHint":getIpa("calm")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"half","options":["HAFF","haf"],"correctAnswerIndex":0,"hint":"L-dropping.","phoneticHint":getIpa("half")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"palm","options":["PAHM","palm"],"correctAnswerIndex":0,"hint":"L-dropping.","phoneticHint":getIpa("palm")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"salt","options":["SAHT","sawlt"],"correctAnswerIndex":0,"hint":"L-dropping.","phoneticHint":getIpa("salt")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"walk","options":["WAHK","wawk"],"correctAnswerIndex":0,"hint":"L-dropping.","phoneticHint":getIpa("walk")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"long","options":["lon","long"],"correctAnswerIndex":0,"hint":"Final /g/ drop.","phoneticHint":getIpa("long")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"song","options":["son","song"],"correctAnswerIndex":0,"hint":"Final drop.","phoneticHint":getIpa("song")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"strong","options":["stron","strong"],"correctAnswerIndex":0,"hint":"Final drop.","phoneticHint":getIpa("strong")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"wrong","options":["wron","wrong"],"correctAnswerIndex":0,"hint":"Final drop.","phoneticHint":getIpa("wrong")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"young","options":["yun","yung"],"correctAnswerIndex":0,"hint":"Final drop.","phoneticHint":getIpa("young")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"among","options":["amun","among"],"correctAnswerIndex":0,"hint":"Final drop.","phoneticHint":getIpa("among")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"belong","options":["bilon","belong"],"correctAnswerIndex":0,"hint":"Final drop.","phoneticHint":getIpa("belong")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"along","options":["alon","along"],"correctAnswerIndex":0,"hint":"Final drop.","phoneticHint":getIpa("along")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"king","options":["kin","king"],"correctAnswerIndex":0,"hint":"Final drop.","phoneticHint":getIpa("king")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"ring","options":["rin","ring"],"correctAnswerIndex":0,"hint":"Final drop.","phoneticHint":getIpa("ring")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"really","options":["ree-ree","ree-lee"],"correctAnswerIndex":0,"hint":"L/R confusion.","phoneticHint":getIpa("really")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"rally","options":["rah-ree","rah-lee"],"correctAnswerIndex":0,"hint":"L/R.","phoneticHint":getIpa("rally")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"rock","options":["lock","rock"],"correctAnswerIndex":0,"hint":"L/R.","phoneticHint":getIpa("rock")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"rice","options":["lice","rice"],"correctAnswerIndex":0,"hint":"L/R.","phoneticHint":getIpa("rice")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"right","options":["light","right"],"correctAnswerIndex":0,"hint":"L/R.","phoneticHint":getIpa("right")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"wrong","options":["long","wrong"],"correctAnswerIndex":0,"hint":"L/R.","phoneticHint":getIpa("wrong")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"road","options":["load","road"],"correctAnswerIndex":0,"hint":"L/R.","phoneticHint":getIpa("road")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"rain","options":["lane","rain"],"correctAnswerIndex":0,"hint":"L/R.","phoneticHint":getIpa("rain")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"run","options":["lun","run"],"correctAnswerIndex":0,"hint":"L/R.","phoneticHint":getIpa("run")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"red","options":["led","red"],"correctAnswerIndex":0,"hint":"L/R.","phoneticHint":getIpa("red")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"five","options":["pive","five"],"correctAnswerIndex":0,"hint":"F/P swap.","phoneticHint":getIpa("five")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"fish","options":["pish","fish"],"correctAnswerIndex":0,"hint":"F/P.","phoneticHint":getIpa("fish")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"fun","options":["pun","fun"],"correctAnswerIndex":0,"hint":"F/P.","phoneticHint":getIpa("fun")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"food","options":["pood","food"],"correctAnswerIndex":0,"hint":"F/P.","phoneticHint":getIpa("food")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"fire","options":["pire","fire"],"correctAnswerIndex":0,"hint":"F/P.","phoneticHint":getIpa("fire")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"face","options":["pace","face"],"correctAnswerIndex":0,"hint":"F/P.","phoneticHint":getIpa("face")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"fall","options":["pall","fall"],"correctAnswerIndex":0,"hint":"F/P.","phoneticHint":getIpa("fall")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"fill","options":["pill","fill"],"correctAnswerIndex":0,"hint":"F/P.","phoneticHint":getIpa("fill")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"fact","options":["pact","fact"],"correctAnswerIndex":0,"hint":"F/P.","phoneticHint":getIpa("fact")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"few","options":["pew","few"],"correctAnswerIndex":0,"hint":"F/P.","phoneticHint":getIpa("few")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"park","options":["bark","park"],"correctAnswerIndex":0,"hint":"P/B confusion.","phoneticHint":getIpa("park")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"peace","options":["beast","peace"],"correctAnswerIndex":0,"hint":"P/B.","phoneticHint":getIpa("peace")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"prize","options":["brize","prize"],"correctAnswerIndex":0,"hint":"P/B.","phoneticHint":getIpa("prize")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"price","options":["brice","price"],"correctAnswerIndex":0,"hint":"P/B.","phoneticHint":getIpa("price")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"proud","options":["broud","proud"],"correctAnswerIndex":0,"hint":"P/B.","phoneticHint":getIpa("proud")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"push","options":["bush","push"],"correctAnswerIndex":0,"hint":"P/B.","phoneticHint":getIpa("push")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"pull","options":["bull","pull"],"correctAnswerIndex":0,"hint":"P/B.","phoneticHint":getIpa("pull")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"plain","options":["blain","plain"],"correctAnswerIndex":0,"hint":"P/B.","phoneticHint":getIpa("plain")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"place","options":["blace","place"],"correctAnswerIndex":0,"hint":"P/B.","phoneticHint":getIpa("place")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"point","options":["boint","point"],"correctAnswerIndex":0,"hint":"P/B.","phoneticHint":getIpa("point")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"very","options":["berry","very"],"correctAnswerIndex":0,"hint":"V/B swap.","phoneticHint":getIpa("very")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"vest","options":["best","vest"],"correctAnswerIndex":0,"hint":"V/B.","phoneticHint":getIpa("vest")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"vine","options":["bine","vine"],"correctAnswerIndex":0,"hint":"V/B.","phoneticHint":getIpa("vine")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"vote","options":["boat","vote"],"correctAnswerIndex":0,"hint":"V/B.","phoneticHint":getIpa("vote")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"voice","options":["boice","voice"],"correctAnswerIndex":0,"hint":"V/B.","phoneticHint":getIpa("voice")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"valley","options":["ballet","valley"],"correctAnswerIndex":0,"hint":"V/B.","phoneticHint":getIpa("valley")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"vast","options":["bast","vast"],"correctAnswerIndex":0,"hint":"V/B.","phoneticHint":getIpa("vast")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"version","options":["bersion","version"],"correctAnswerIndex":0,"hint":"V/B.","phoneticHint":getIpa("version")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"virtue","options":["birtue","virtue"],"correctAnswerIndex":0,"hint":"V/B.","phoneticHint":getIpa("virtue")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"vision","options":["bision","vision"],"correctAnswerIndex":0,"hint":"V/B.","phoneticHint":getIpa("vision")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"vine","options":["wine","vine"],"correctAnswerIndex":0,"hint":"V/W.","phoneticHint":getIpa("vine")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"vest","options":["west","vest"],"correctAnswerIndex":0,"hint":"V/W.","phoneticHint":getIpa("vest")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"vow","options":["wow","vow"],"correctAnswerIndex":0,"hint":"V/W.","phoneticHint":getIpa("vow")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"very","options":["wary","very"],"correctAnswerIndex":0,"hint":"V/W.","phoneticHint":getIpa("very")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"verse","options":["worse","verse"],"correctAnswerIndex":0,"hint":"V/W.","phoneticHint":getIpa("verse")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"vain","options":["wane","vain"],"correctAnswerIndex":0,"hint":"V/W.","phoneticHint":getIpa("vain")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"vale","options":["whale","vale"],"correctAnswerIndex":0,"hint":"V/W.","phoneticHint":getIpa("vale")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"veil","options":["wail","veil"],"correctAnswerIndex":0,"hint":"V/W.","phoneticHint":getIpa("veil")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"vent","options":["went","vent"],"correctAnswerIndex":0,"hint":"V/W.","phoneticHint":getIpa("vent")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"void","options":["woid","void"],"correctAnswerIndex":0,"hint":"V/W.","phoneticHint":getIpa("void")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"happy","options":["appy","happy"],"correctAnswerIndex":0,"hint":"H-dropping.","phoneticHint":getIpa("happy")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"house","options":["ouse","house"],"correctAnswerIndex":0,"hint":"H-dropping.","phoneticHint":getIpa("house")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hello","options":["ello","hello"],"correctAnswerIndex":0,"hint":"H-dropping.","phoneticHint":getIpa("hello")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"help","options":["elp","help"],"correctAnswerIndex":0,"hint":"H-dropping.","phoneticHint":getIpa("help")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hotel","options":["otel","hotel"],"correctAnswerIndex":0,"hint":"H-dropping.","phoneticHint":getIpa("hotel")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"horror","options":["orror","horror"],"correctAnswerIndex":0,"hint":"H-dropping.","phoneticHint":getIpa("horror")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hobby","options":["obby","hobby"],"correctAnswerIndex":0,"hint":"H-dropping.","phoneticHint":getIpa("hobby")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hungry","options":["ungry","hungry"],"correctAnswerIndex":0,"hint":"H-dropping.","phoneticHint":getIpa("hungry")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hurry","options":["urry","hurry"],"correctAnswerIndex":0,"hint":"H-dropping.","phoneticHint":getIpa("hurry")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"heaven","options":["eaven","heaven"],"correctAnswerIndex":0,"hint":"H-dropping.","phoneticHint":getIpa("heaven")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"milk","options":["milky","milk"],"correctAnswerIndex":0,"hint":"Epenthetic vowel.","phoneticHint":getIpa("milk")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"help","options":["helpy","help"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("help")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"film","options":["filmy","film"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("film")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"world","options":["worldy","world"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("world")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"cold","options":["coldy","cold"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("cold")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"told","options":["toldy","told"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("told")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hold","options":["holdy","hold"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("hold")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"bold","options":["boldy","bold"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("bold")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"wild","options":["wildy","wild"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("wild")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"child","options":["childy","child"],"correctAnswerIndex":0,"hint":"Epenthesis.","phoneticHint":getIpa("child")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"this","options":["zis","this"],"correctAnswerIndex":0,"hint":"TH→Z.","phoneticHint":getIpa("this")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"think","options":["sink","think"],"correctAnswerIndex":0,"hint":"TH→S.","phoneticHint":getIpa("think")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"that","options":["zat","that"],"correctAnswerIndex":0,"hint":"TH→Z.","phoneticHint":getIpa("that")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"the","options":["ze","the"],"correctAnswerIndex":0,"hint":"TH→Z.","phoneticHint":getIpa("the")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"these","options":["zese","these"],"correctAnswerIndex":0,"hint":"TH→Z.","phoneticHint":getIpa("these")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"those","options":["zose","those"],"correctAnswerIndex":0,"hint":"TH→Z.","phoneticHint":getIpa("those")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"there","options":["zere","there"],"correctAnswerIndex":0,"hint":"TH→Z.","phoneticHint":getIpa("there")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"them","options":["zem","them"],"correctAnswerIndex":0,"hint":"TH→Z.","phoneticHint":getIpa("them")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"thank","options":["sank","thank"],"correctAnswerIndex":0,"hint":"TH→S.","phoneticHint":getIpa("thank")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"thought","options":["sought","thought"],"correctAnswerIndex":0,"hint":"TH→S.","phoneticHint":getIpa("thought")}});

  // === FINAL FIX ===
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"advertisement","options":["AD-ver-tize-ment","ad-VER-tis-ment"],"correctAnswerIndex":0,"hint":"American stress.","phoneticHint":getIpa("advertisement")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"address","options":["AD-ress","uh-DRESS"],"correctAnswerIndex":0,"hint":"Noun vs verb.","phoneticHint":getIpa("address")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"adult","options":["uh-DULT","AD-ult"],"correctAnswerIndex":0,"hint":"Stress varies.","phoneticHint":getIpa("adult")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"banana","options":["buh-NA-nuh","bah-NAH-nah"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("banana")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"caramel","options":["KAR-mul","KARE-uh-mel"],"correctAnswerIndex":0,"hint":"Syllable count.","phoneticHint":getIpa("caramel")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"crayon","options":["KRAN","KRAY-on"],"correctAnswerIndex":0,"hint":"Syllable count.","phoneticHint":getIpa("crayon")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"creek","options":["kreek","krik"],"correctAnswerIndex":0,"hint":"Vowel length.","phoneticHint":getIpa("creek")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"either","options":["EE-thur","EYE-thur"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("either")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"envelope","options":["EN-vuh-lope","ON-vuh-lope"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("envelope")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"february","options":["FEB-yoo-air-ee","FEB-roo-air-ee"],"correctAnswerIndex":0,"hint":"R deletion.","phoneticHint":getIpa("february")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"florida","options":["FLOR-ih-duh","FLAH-ruh-duh"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("florida")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"garage","options":["guh-RAHJ","GAR-ij"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("garage")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"genuine","options":["JEN-yoo-in","JEN-yoo-ine"],"correctAnswerIndex":0,"hint":"Final syllable.","phoneticHint":getIpa("genuine")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"grocery","options":["GROH-sree","GROH-sur-ee"],"correctAnswerIndex":0,"hint":"Syllable count.","phoneticHint":getIpa("grocery")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"insurance","options":["in-SHOOR-unse","IN-shur-unse"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("insurance")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"jewelry","options":["JOOL-ree","JEW-ul-ree"],"correctAnswerIndex":0,"hint":"Syllable count.","phoneticHint":getIpa("jewelry")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"kilometer","options":["kih-LAH-muh-tur","KIL-uh-mee-tur"],"correctAnswerIndex":0,"hint":"Stress.","phoneticHint":getIpa("kilometer")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"mayonnaise","options":["MAN-aze","MAY-uh-naze"],"correctAnswerIndex":0,"hint":"Syllables.","phoneticHint":getIpa("mayonnaise")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"nuclear","options":["NOO-klee-ur","NOO-kyuh-lur"],"correctAnswerIndex":0,"hint":"Metathesis.","phoneticHint":getIpa("nuclear")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"pajamas","options":["puh-JAH-muz","puh-JAM-uz"],"correctAnswerIndex":0,"hint":"Middle vowel.","phoneticHint":getIpa("pajamas")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"pecan","options":["pih-KAHN","PEE-kan"],"correctAnswerIndex":0,"hint":"Stress and vowel.","phoneticHint":getIpa("pecan")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"picture","options":["PIK-chur","PIK-tur"],"correctAnswerIndex":0,"hint":"Final consonant.","phoneticHint":getIpa("picture")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"potato","options":["puh-TAY-toh","puh-TAH-toh"],"correctAnswerIndex":0,"hint":"Second vowel.","phoneticHint":getIpa("potato")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"pumpkin","options":["PUMP-kin","PUNK-in"],"correctAnswerIndex":0,"hint":"Nasal.","phoneticHint":getIpa("pumpkin")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"realtor","options":["REEL-tur","REE-luh-tur"],"correctAnswerIndex":0,"hint":"Syllables.","phoneticHint":getIpa("realtor")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"roof","options":["roof","ruf"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("roof")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"salmon","options":["SAM-un","SAL-mun"],"correctAnswerIndex":0,"hint":"L silent or not.","phoneticHint":getIpa("salmon")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"sandwich","options":["SAND-wich","SAM-wich"],"correctAnswerIndex":0,"hint":"D assimilation.","phoneticHint":getIpa("sandwich")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"schedule","options":["SKED-yool","SHED-yool"],"correctAnswerIndex":0,"hint":"Initial cluster.","phoneticHint":getIpa("schedule")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"siren","options":["SY-run","SY-reen"],"correctAnswerIndex":0,"hint":"Second vowel.","phoneticHint":getIpa("siren")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"suppose","options":["suh-POZE","SPOZE"],"correctAnswerIndex":0,"hint":"Reduction.","phoneticHint":getIpa("suppose")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"syrup","options":["SUR-up","SEER-up"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("syrup")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"theater","options":["THEE-uh-tur","THEE-ay-tur"],"correctAnswerIndex":0,"hint":"Middle vowel.","phoneticHint":getIpa("theater")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"vehicle","options":["VEE-ih-kul","VEE-hik-ul"],"correctAnswerIndex":0,"hint":"Syllable stress.","phoneticHint":getIpa("vehicle")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"wednesday","options":["WENZ-day","WED-nez-day"],"correctAnswerIndex":0,"hint":"Reduction.","phoneticHint":getIpa("wednesday")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"bottle","options":["BOH-oh","BOT-ul"],"correctAnswerIndex":0,"hint":"Glottal stop + L vocalization.","phoneticHint":getIpa("bottle")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"beautiful","options":["BYOO-ih-ful","BYOO-tih-ful"],"correctAnswerIndex":0,"hint":"T glottaling.","phoneticHint":getIpa("beautiful")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"brother","options":["BRUH-vuh","BRUH-thur"],"correctAnswerIndex":0,"hint":"TH fronting.","phoneticHint":getIpa("brother")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"mother","options":["MUH-vuh","MUH-thur"],"correctAnswerIndex":0,"hint":"TH fronting.","phoneticHint":getIpa("mother")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"nothing","options":["NUH-fink","NUH-thing"],"correctAnswerIndex":0,"hint":"TH fronting.","phoneticHint":getIpa("nothing")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"something","options":["SUM-fink","SUM-thing"],"correctAnswerIndex":0,"hint":"TH fronting.","phoneticHint":getIpa("something")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"anything","options":["EN-ee-fink","EN-ee-thing"],"correctAnswerIndex":0,"hint":"TH fronting.","phoneticHint":getIpa("anything")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"everything","options":["EV-ree-fink","EV-ree-thing"],"correctAnswerIndex":0,"hint":"TH fronting.","phoneticHint":getIpa("everything")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"thousand","options":["FAHZ-und","THOW-zund"],"correctAnswerIndex":0,"hint":"TH fronting.","phoneticHint":getIpa("thousand")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"together","options":["tuh-GEV-uh","tuh-GEH-ther"],"correctAnswerIndex":0,"hint":"TH fronting.","phoneticHint":getIpa("together")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"weather","options":["WEV-uh","WEH-thur"],"correctAnswerIndex":0,"hint":"TH fronting.","phoneticHint":getIpa("weather")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"feather","options":["FEV-uh","FEH-thur"],"correctAnswerIndex":0,"hint":"TH fronting.","phoneticHint":getIpa("feather")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"leather","options":["LEV-uh","LEH-thur"],"correctAnswerIndex":0,"hint":"TH fronting.","phoneticHint":getIpa("leather")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"another","options":["uh-NUH-vuh","uh-NUH-thur"],"correctAnswerIndex":0,"hint":"TH fronting.","phoneticHint":getIpa("another")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"without","options":["wiv-AHT","with-OWT"],"correctAnswerIndex":0,"hint":"TH fronting.","phoneticHint":getIpa("without")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"coffee","options":["KAW-fee","KAH-fee"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("coffee")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"dog","options":["DAWG","DAHG"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("dog")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"talk","options":["TAWK","TAHK"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("talk")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"walk","options":["WAWK","WAHK"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("walk")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"water","options":["WAW-tuh","WAH-ter"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("water")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"thought","options":["THAWT","THAHT"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("thought")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"caught","options":["KAWT","KAHT"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("caught")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"brought","options":["BRAWT","BRAHT"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("brought")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"bought","options":["BAWT","BAHT"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("bought")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"daughter","options":["DAW-tuh","DAH-ter"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("daughter")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"all","options":["AWL","AHL"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("all")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"ball","options":["BAWL","BAHL"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("ball")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"call","options":["KAWL","KAHL"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("call")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"fall","options":["FAWL","FAHL"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("fall")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hall","options":["HAWL","HAHL"],"correctAnswerIndex":0,"hint":"Rounded vowel.","phoneticHint":getIpa("hall")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"car","options":["KAH","KAR"],"correctAnswerIndex":0,"hint":"R dropping.","phoneticHint":getIpa("car")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"far","options":["FAH","FAR"],"correctAnswerIndex":0,"hint":"R dropping.","phoneticHint":getIpa("far")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"star","options":["STAH","STAR"],"correctAnswerIndex":0,"hint":"R dropping.","phoneticHint":getIpa("star")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"bar","options":["BAH","BAR"],"correctAnswerIndex":0,"hint":"R dropping.","phoneticHint":getIpa("bar")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"park","options":["PAHK","PARK"],"correctAnswerIndex":0,"hint":"R dropping.","phoneticHint":getIpa("park")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"dark","options":["DAHK","DARK"],"correctAnswerIndex":0,"hint":"R dropping.","phoneticHint":getIpa("dark")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hard","options":["HAHD","HARD"],"correctAnswerIndex":0,"hint":"R dropping.","phoneticHint":getIpa("hard")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"yard","options":["YAHD","YARD"],"correctAnswerIndex":0,"hint":"R dropping.","phoneticHint":getIpa("yard")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"guard","options":["GAHD","GARD"],"correctAnswerIndex":0,"hint":"R dropping.","phoneticHint":getIpa("guard")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"card","options":["KAHD","KARD"],"correctAnswerIndex":0,"hint":"R dropping.","phoneticHint":getIpa("card")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"idea","options":["eye-DEER","eye-DEE-uh"],"correctAnswerIndex":0,"hint":"Intrusive R.","phoneticHint":getIpa("idea")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"pizza","options":["PEET-sur","PEET-suh"],"correctAnswerIndex":0,"hint":"Rhoticity.","phoneticHint":getIpa("pizza")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"sofa","options":["SOH-fur","SOH-fuh"],"correctAnswerIndex":0,"hint":"Intrusive R.","phoneticHint":getIpa("sofa")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"extra","options":["EK-strur","EK-struh"],"correctAnswerIndex":0,"hint":"Intrusive R.","phoneticHint":getIpa("extra")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"banana","options":["buh-NAN-ur","buh-NAN-uh"],"correctAnswerIndex":0,"hint":"Intrusive R.","phoneticHint":getIpa("banana")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"fire","options":["FAR","FY-er"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("fire")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"tire","options":["TAR","TY-er"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("tire")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"wire","options":["WAR","WY-er"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("wire")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hire","options":["HAR","HY-er"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("hire")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"dire","options":["DAR","DY-er"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("dire")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"mine","options":["MAHN","MYN"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("mine")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"fine","options":["FAHN","FYN"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("fine")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"nine","options":["NAHN","NYN"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("nine")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"time","options":["TAHM","TYM"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("time")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"line","options":["LAHN","LYN"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("line")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"ride","options":["RAHD","RYDE"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("ride")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hide","options":["HAHD","HYDE"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("hide")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"side","options":["SAHD","SYDE"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("side")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"wide","options":["WAHD","WYDE"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("wide")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"guide","options":["GAHD","GYDE"],"correctAnswerIndex":0,"hint":"Monophthong.","phoneticHint":getIpa("guide")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"about","options":["uh-BOAT","uh-BOWT"],"correctAnswerIndex":0,"hint":"Canadian raising.","phoneticHint":getIpa("about")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"out","options":["OAT","OWT"],"correctAnswerIndex":0,"hint":"Canadian raising.","phoneticHint":getIpa("out")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"house","options":["HOCE","HOWSE"],"correctAnswerIndex":0,"hint":"Canadian raising.","phoneticHint":getIpa("house")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"mouse","options":["MOCE","MOWSE"],"correctAnswerIndex":0,"hint":"Canadian raising.","phoneticHint":getIpa("mouse")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"shout","options":["SHOAT","SHOWT"],"correctAnswerIndex":0,"hint":"Canadian raising.","phoneticHint":getIpa("shout")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"doubt","options":["DOAT","DOWT"],"correctAnswerIndex":0,"hint":"Canadian raising.","phoneticHint":getIpa("doubt")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"scout","options":["SKOAT","SKOWT"],"correctAnswerIndex":0,"hint":"Canadian raising.","phoneticHint":getIpa("scout")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"mouth","options":["MOATH","MOWTH"],"correctAnswerIndex":0,"hint":"Canadian raising.","phoneticHint":getIpa("mouth")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"south","options":["SOATH","SOWTH"],"correctAnswerIndex":0,"hint":"Canadian raising.","phoneticHint":getIpa("south")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"loud","options":["LODE","LOWD"],"correctAnswerIndex":0,"hint":"Canadian raising.","phoneticHint":getIpa("loud")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"caught","options":["KAHT","KAWT"],"correctAnswerIndex":0,"hint":"Cot-caught merger.","phoneticHint":getIpa("caught")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"cot","options":["KAHT","KOT"],"correctAnswerIndex":0,"hint":"Merged vowel.","phoneticHint":getIpa("cot")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"dawn","options":["DAHN","DAWN"],"correctAnswerIndex":0,"hint":"Merged vowel.","phoneticHint":getIpa("dawn")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"don","options":["DAHN","DON"],"correctAnswerIndex":0,"hint":"Merged vowel.","phoneticHint":getIpa("don")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hawk","options":["HAHK","HAWK"],"correctAnswerIndex":0,"hint":"Merged vowel.","phoneticHint":getIpa("hawk")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hock","options":["HAHK","HOK"],"correctAnswerIndex":0,"hint":"Merged vowel.","phoneticHint":getIpa("hock")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"gnaw","options":["NAH","NAW"],"correctAnswerIndex":0,"hint":"Merged vowel.","phoneticHint":getIpa("gnaw")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"not","options":["NAHT","NOT"],"correctAnswerIndex":0,"hint":"Merged vowel.","phoneticHint":getIpa("not")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"paw","options":["PAH","PAW"],"correctAnswerIndex":0,"hint":"Merged vowel.","phoneticHint":getIpa("paw")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"pod","options":["PAHD","POD"],"correctAnswerIndex":0,"hint":"Merged vowel.","phoneticHint":getIpa("pod")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"sorry","options":["SOR-ee","SAH-ree"],"correctAnswerIndex":0,"hint":"Vowel.","phoneticHint":getIpa("sorry")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"process","options":["PROH-sess","PRAH-sess"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("process")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"progress","options":["PROH-gress","PRAH-gress"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("progress")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"project","options":["PROH-jekt","PRAH-jekt"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("project")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"produce","options":["PROH-dyoos","PRAH-doos"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("produce")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"drama","options":["DRAH-muh","DRA-muh"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("drama")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"pasta","options":["PAH-stuh","PAS-tuh"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("pasta")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"lava","options":["LAH-vuh","LA-vuh"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("lava")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"llama","options":["LAH-muh","LA-muh"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("llama")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"saga","options":["SAH-guh","SA-guh"],"correctAnswerIndex":0,"hint":"First vowel.","phoneticHint":getIpa("saga")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"often","options":["OFF-un","OFF-ten"],"correctAnswerIndex":0,"hint":"T silent or not.","phoneticHint":getIpa("often")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"almond","options":["AH-mund","AL-mund"],"correctAnswerIndex":0,"hint":"L silent or not.","phoneticHint":getIpa("almond")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"calm","options":["KAHM","KALM"],"correctAnswerIndex":0,"hint":"L silent or not.","phoneticHint":getIpa("calm")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"folk","options":["FOKE","FOLK"],"correctAnswerIndex":0,"hint":"L silent or not.","phoneticHint":getIpa("folk")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"palm","options":["PAHM","PALM"],"correctAnswerIndex":0,"hint":"L silent or not.","phoneticHint":getIpa("palm")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"psalm","options":["SAHM","PSALM"],"correctAnswerIndex":0,"hint":"L silent or not.","phoneticHint":getIpa("psalm")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"salmon","options":["SAM-un","SAL-mun"],"correctAnswerIndex":0,"hint":"L silent or not.","phoneticHint":getIpa("salmon")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"talk","options":["TAHK","TAWK"],"correctAnswerIndex":0,"hint":"L silent or not.","phoneticHint":getIpa("talk")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"walk","options":["WAHK","WAWK"],"correctAnswerIndex":0,"hint":"L silent or not.","phoneticHint":getIpa("walk")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"yolk","options":["YOKE","YOLK"],"correctAnswerIndex":0,"hint":"L silent or not.","phoneticHint":getIpa("yolk")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"herb","options":["ERB","HERB"],"correctAnswerIndex":0,"hint":"H silent or not.","phoneticHint":getIpa("herb")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"honest","options":["ON-ist","HON-ist"],"correctAnswerIndex":0,"hint":"H silent.","phoneticHint":getIpa("honest")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"honor","options":["ON-ur","HON-ur"],"correctAnswerIndex":0,"hint":"H silent.","phoneticHint":getIpa("honor")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"hour","options":["OWR","HOWR"],"correctAnswerIndex":0,"hint":"H silent.","phoneticHint":getIpa("hour")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"knight","options":["NITE","KNIGHT"],"correctAnswerIndex":0,"hint":"K silent.","phoneticHint":getIpa("knight")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"knife","options":["NIFE","KNIFE"],"correctAnswerIndex":0,"hint":"K silent.","phoneticHint":getIpa("knife")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"knee","options":["NEE","KNEE"],"correctAnswerIndex":0,"hint":"K silent.","phoneticHint":getIpa("knee")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"knot","options":["NOT","KNOT"],"correctAnswerIndex":0,"hint":"K silent.","phoneticHint":getIpa("knot")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"write","options":["RITE","WRITE"],"correctAnswerIndex":0,"hint":"W silent.","phoneticHint":getIpa("write")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"wrong","options":["RONG","WRONG"],"correctAnswerIndex":0,"hint":"W silent.","phoneticHint":getIpa("wrong")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"wrap","options":["RAP","WRAP"],"correctAnswerIndex":0,"hint":"W silent.","phoneticHint":getIpa("wrap")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"wreck","options":["REK","WREK"],"correctAnswerIndex":0,"hint":"W silent.","phoneticHint":getIpa("wreck")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"debt","options":["DET","DEBT"],"correctAnswerIndex":0,"hint":"B silent.","phoneticHint":getIpa("debt")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"doubt","options":["DOWT","DOUBT"],"correctAnswerIndex":0,"hint":"B silent.","phoneticHint":getIpa("doubt")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"subtle","options":["SUH-tul","SUB-tul"],"correctAnswerIndex":0,"hint":"B silent.","phoneticHint":getIpa("subtle")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"lamb","options":["LAM","LAMB"],"correctAnswerIndex":0,"hint":"B silent.","phoneticHint":getIpa("lamb")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"comb","options":["KOHM","COMB"],"correctAnswerIndex":0,"hint":"B silent.","phoneticHint":getIpa("comb")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"tomb","options":["TOOM","TOMB"],"correctAnswerIndex":0,"hint":"B silent.","phoneticHint":getIpa("tomb")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"plumber","options":["PLUM-ur","PLUMB-ur"],"correctAnswerIndex":0,"hint":"B silent.","phoneticHint":getIpa("plumber")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"dumb","options":["DUM","DUMB"],"correctAnswerIndex":0,"hint":"B silent.","phoneticHint":getIpa("dumb")}});

  // === FINAL PATCH ===
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"receipt","options":["rih-SEET","REE-sept"],"correctAnswerIndex":0,"hint":"P is silent.","phoneticHint":getIpa("receipt")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"island","options":["EYE-lund","IS-lund"],"correctAnswerIndex":0,"hint":"S is silent.","phoneticHint":getIpa("island")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"listen","options":["LIS-un","LIS-ten"],"correctAnswerIndex":0,"hint":"T is silent.","phoneticHint":getIpa("listen")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"muscle","options":["MUH-sul","MUS-kul"],"correctAnswerIndex":0,"hint":"C is silent.","phoneticHint":getIpa("muscle")}});
  pool.push({"instruction":"Choose the correct pronunciation.","fields":{"word":"sword","options":["SORD","SWORD"],"correctAnswerIndex":0,"hint":"W is silent.","phoneticHint":getIpa("sword")}});
console.log(`  dialectDrill pool: ${pool.length}`);
  return pool;
};
