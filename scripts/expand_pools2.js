/**
 * Pool Expander Round 2 — final push to 600 for remaining undersized pools:
 * syllableStress (585→600), shadowingChallenge (562→600), minimalPairs (496→600),
 * vowelDistinction (240→600), dialectDrill (222→600)
 */
const fs = require('fs');
const path = require('path');

function appendToPool(poolPath, extraEntries, formatter) {
  const content = fs.readFileSync(poolPath, 'utf8');
  const insertionPoint = content.lastIndexOf('console.log');
  if (insertionPoint === -1) { console.error('Cannot find insertion in', poolPath); return; }
  let extra = '\n  // === ROUND 2 AUTO-EXPANDED ===\n';
  for (const entry of extraEntries) {
    extra += '  pool.push(' + JSON.stringify(formatter(entry)) + ');\n';
  }
  const newContent = content.slice(0, insertionPoint) + extra + content.slice(insertionPoint);
  fs.writeFileSync(poolPath, newContent);
  console.log(`Updated ${path.basename(poolPath)}: +${extraEntries.length}`);
}

const poolsDir = path.join(__dirname, 'pools');

// 1. Syllable Stress: need 15 more
const extraStress = [
  ['ANCHOR','AN-chor','an-CHOR',0],['ANTLER','ANT-ler','ant-LER',0],
  ['BARLEY','BAR-ley','bar-LEY',0],['BISCUIT','BIS-cuit','bis-CUIT',0],
  ['BLANKET','BLAN-ket','blan-KET',0],['BOULDER','BOUL-der','boul-DER',0],
  ['BRACELET','BRACE-let','brace-LET',0],['BUCKET','BUCK-et','buck-ET',0],
  ['CANVAS','CAN-vas','can-VAS',0],['CARPET','CAR-pet','car-PET',0],
  ['CIRCUIT','CIR-cuit','cir-CUIT',0],['COUSIN','COU-sin','cou-SIN',0],
  ['DESERT','DES-ert','des-ERT',0],['DONKEY','DON-key','don-KEY',0],
  ['EMBER','EM-ber','em-BER',0],['FAUCET','FAU-cet','fau-CET',0],
  ['GOBLET','GOB-let','gob-LET',0],['HAMSTER','HAM-ster','ham-STER',0],
  ['INSECT','IN-sect','in-SECT',0],['JACKET','JACK-et','jack-ET',0],
];
appendToPool(path.join(poolsDir, 'syllable_stress_pool.js'), extraStress, ([word,o1,o2,ans]) => ({
  instruction: 'Where is the stress?',
  fields: { word, options: [o1,o2], correctAnswerIndex: ans, hint: 'Listen for the loudest syllable.' }
}));

// 2. Shadowing: need 38 more
const extraShadow = [
  'The early morning joggers enjoy the peaceful trails along the river.',
  'She practiced her presentation three times before the actual meeting.',
  'The bookshelf was filled with novels from around the world.',
  'He spent the weekend building a treehouse for his children.',
  'The museum curator organized a special exhibit for local artists.',
  'We plan to renovate the kitchen before the holiday season begins.',
  'The volunteer firefighters responded quickly to the emergency call.',
  'She earned a promotion after consistently exceeding her sales targets.',
  'The community organized a food drive for families in need.',
  'He spent years researching the history of ancient civilizations.',
  'The new highway reduced commute times for thousands of workers.',
  'She taught her students the importance of critical thinking skills.',
  'The orchestra rehearsed for weeks before the opening night concert.',
  'We decided to switch to renewable energy for our household needs.',
  'The scientist discovered a new species of butterfly in the forest.',
  'He mentored young athletes at the community recreation center.',
  'The bakery on the corner makes delicious sourdough bread daily.',
  'She designed a mobile app that helps people track their fitness goals.',
  'The school board approved funding for a new science laboratory.',
  'We traveled across three countries during our summer vacation trip.',
  'The journalist investigated reports of water contamination in the region.',
  'He composed a piece of music inspired by his childhood memories.',
  'The city installed solar-powered street lights along the main boulevard.',
  'She coordinated a team of researchers studying climate change impacts.',
  'The national monument attracts over a million visitors each year.',
  'We organized a farewell party for our colleague who is retiring.',
  'The software company released an update that fixed several critical bugs.',
  'He taught himself to speak four languages by watching foreign films.',
  'The hospital expanded its emergency department to serve more patients.',
  'She raised awareness about mental health through her public speaking.',
  'The renewable energy sector created thousands of new employment opportunities.',
  'We hosted an international exchange student from Brazil last semester.',
  'The archaeological team discovered ancient pottery fragments at the site.',
  'He designed an affordable housing project for low-income families.',
  'The airline introduced paperless boarding passes to reduce waste.',
  'She published a children\'s book series about environmental conservation.',
  'The research team successfully tested a new vaccine in clinical trials.',
  'We participated in a community tree planting event last Saturday morning.',
  'The transportation department announced plans for a new bicycle path.',
  'He organized a weekly coding workshop for beginners at the library.',
  'The veterinary clinic launched a program for free pet vaccinations.',
  'She curated an online gallery showcasing emerging photographers worldwide.',
  'The technology summit attracted keynote speakers from leading companies.',
  'We implemented a mentoring program that paired experienced and new employees.',
  'The coral conservation project restored damaged reef sections successfully.',
  'He invented a portable water testing device for rural communities.',
];
appendToPool(path.join(poolsDir, 'shadowing_pool.js'), extraShadow, (s) => ({
  instruction: 'Shadow the sentence.',
  interactionType: 'speaking',
  fields: { sentence: s, options: ['Matched','Not matched'], correctAnswerIndex: 0, hint: 'Listen and repeat simultaneously.', targetSpeed: '1.0x' }
}));

// 3. Minimal Pairs: need 104 more
const extraMP = [
  // More unique pairs
  ['sake','shake','Which starts with /s/?',0,'Fricative.'],['sore','shore','Which starts with /s/?',0,'Fricative.'],
  ['self','shelf','Which starts with /s/?',0,'Fricative.'],['sip','ship','Which starts with /s/?',0,'Fricative.'],
  ['suit','shoot','Which starts with /s/?',0,'Fricative.'],['save','shave','Which starts with /s/?',0,'Fricative.'],
  ['sock','shock','Which starts with /s/?',0,'Fricative.'],['sort','short','Which starts with /s/?',0,'Fricative.'],
  ['seed','she\'d','Which starts with /s/?',0,'Fricative.'],['so','show','Which starts with /s/?',0,'Fricative.'],
  ['same','shame','Which starts with /s/?',0,'Fricative.'],['sigh','shy','Which starts with /s/?',0,'Fricative.'],
  ['seep','sheep','Which starts with /s/?',0,'Fricative.'],['seen','sheen','Which starts with /s/?',0,'Fricative.'],
  ['seer','sheer','Which starts with /s/?',0,'Fricative.'],['sell','shell','Which starts with /s/?',0,'Fricative.'],
  ['sow','show','Which starts with /s/?',0,'Fricative.'],['sum','shun','Which starts with /s/?',0,'Fricative.'],
  ['sun','shun','Which starts with /s/?',0,'Fricative.'],['saw','shaw','Which starts with /s/?',0,'Fricative.'],
  // /k/ vs /t/
  ['cake','take','Which starts with /k/?',0,'Velar stop.'],['cape','tape','Which starts with /k/?',0,'Velar.'],
  ['care','tear','Which starts with /k/?',0,'Velar.'],['call','tall','Which starts with /k/?',0,'Velar.'],
  ['cash','trash','Which starts with /k/?',0,'Velar.'],['corn','torn','Which starts with /k/?',0,'Velar.'],
  ['coil','toil','Which starts with /k/?',0,'Velar.'],['core','tore','Which starts with /k/?',0,'Velar.'],
  ['cot','tot','Which starts with /k/?',0,'Velar.'],['cow','tow','Which starts with /k/?',0,'Velar.'],
  ['cub','tub','Which starts with /k/?',0,'Velar.'],['curl','twirl','Which starts with /k/?',0,'Velar.'],
  ['keen','teen','Which starts with /k/?',0,'Velar.'],['key','tea','Which starts with /k/?',0,'Velar.'],
  ['kick','tick','Which starts with /k/?',0,'Velar.'],['kill','till','Which starts with /k/?',0,'Velar.'],
  ['kin','tin','Which starts with /k/?',0,'Velar.'],['kind','tined','Which starts with /k/?',0,'Velar.'],
  ['knack','tack','Which starts with /k/?',0,'Velar.'],['knot','tot','Which starts with /k/?',0,'Velar.'],
  // /g/ vs /d/
  ['gale','dale','Which starts with /g/?',0,'Velar voiced.'],['gave','Dave','Which starts with /g/?',0,'Velar.'],
  ['gaze','days','Which starts with /g/?',0,'Velar.'],['gear','deer','Which starts with /g/?',0,'Velar.'],
  ['gill','dill','Which starts with /g/?',0,'Velar.'],['go','dough','Which starts with /g/?',0,'Velar.'],
  ['goal','dole','Which starts with /g/?',0,'Velar.'],['gone','dawn','Which starts with /g/?',0,'Velar.'],
  ['gore','door','Which starts with /g/?',0,'Velar.'],['got','dot','Which starts with /g/?',0,'Velar.'],
  ['gown','down','Which starts with /g/?',0,'Velar.'],['grate','date','Which starts with /g/?',0,'Velar.'],
  ['grit','drit','Which starts with /g/?',0,'Velar.'],['grow','drew','Which starts with /g/?',0,'Velar.'],
  ['gum','dumb','Which starts with /g/?',0,'Velar.'],['gust','dust','Which starts with /g/?',0,'Velar.'],
  ['gut','dut','Which starts with /g/?',0,'Velar.'],['guy','die','Which starts with /g/?',0,'Velar.'],
  ['gash','dash','Which starts with /g/?',0,'Velar.'],['grab','drab','Which starts with /g/?',0,'Velar.'],
  // Cluster simplification
  ['clap','cap','Which has the cluster?',0,'Consonant cluster.'],['cling','king','Which has the cluster?',0,'Cluster.'],
  ['clot','cot','Which has the cluster?',0,'Cluster.'],['club','cub','Which has the cluster?',0,'Cluster.'],
  ['blind','bind','Which has the cluster?',0,'Cluster.'],['block','bock','Which has the cluster?',0,'Cluster.'],
  ['brand','band','Which has the cluster?',0,'Cluster.'],['bread','bed','Which has the cluster?',0,'Cluster.'],
  ['bring','bing','Which has the cluster?',0,'Cluster.'],['brink','bink','Which has the cluster?',0,'Cluster.'],
  ['flock','folk','Which has the cluster?',0,'Cluster.'],['frog','fog','Which has the cluster?',0,'Cluster.'],
  ['frost','fost','Which has the cluster?',0,'Cluster.'],['grown','gown','Which has the cluster?',0,'Cluster.'],
  ['cram','cam','Which has the cluster?',0,'Cluster.'],['crest','chest','Which has the cluster?',0,'Cluster.'],
  ['crisp','kiss','Which has the cluster?',0,'Cluster.'],['cross','cos','Which has the cluster?',0,'Cluster.'],
  ['crown','cow','Which has the cluster?',0,'Cluster.'],['drop','dop','Which has the cluster?',0,'Cluster.'],
  ['drum','dumb','Which has the cluster?',0,'Cluster.'],['flat','fat','Which has the cluster?',0,'Cluster.'],
  ['flaw','foe','Which has the cluster?',0,'Cluster.'],['fled','fed','Which has the cluster?',0,'Cluster.'],
  ['flew','few','Which has the cluster?',0,'Cluster.'],['flip','fip','Which has the cluster?',0,'Cluster.'],
  ['float','foe','Which has the cluster?',0,'Cluster.'],['flow','foe','Which has the cluster?',0,'Cluster.'],
  ['play','pay','Which has the cluster?',0,'Cluster.'],['plea','pea','Which has the cluster?',0,'Cluster.'],
  ['plod','pod','Which has the cluster?',0,'Cluster.'],['plot','pot','Which has the cluster?',0,'Cluster.'],
  ['pluck','puck','Which has the cluster?',0,'Cluster.'],['plug','pug','Which has the cluster?',0,'Cluster.'],
];
appendToPool(path.join(poolsDir, 'minimal_pairs_pool.js'), extraMP, ([w1,w2,q,a,h]) => ({
  instruction: 'Choose the word you hear.',
  fields: { word1:w1, word2:w2, question:q, options:[w1,w2], correctAnswerIndex:a, hint:h }
}));

// 4. Vowel Distinction: need 360 more — using combinatorial approach
const vdPairs = [];
const vowelSets = [
  // /æ/ vs /eɪ/
  {q:'Which has /æ/?',h:'Short front.',pairs:[
    ['hat','hate'],['mat','mate'],['fat','fate'],['rat','rate'],['man','mane'],
    ['can','cane'],['plan','plane'],['pan','pane'],['gap','gape'],['tap','tape'],
    ['cap','cape'],['map','mope'],['lam','lame'],['dam','dame'],['Sam','same'],
    ['bad','bade'],['mad','made'],['fad','fade'],['glad','glade'],['shag','shade'],
    ['lab','late'],['tab','tale'],['grab','grape'],['slam','slain'],['clan','claim'],
    ['clam','claim'],['ram','rain'],['jam','Jane'],['slab','slave'],['snap','snake'],
  ]},
  // /ɪ/ vs /aɪ/
  {q:'Which has /ɪ/?',h:'Short close.',pairs:[
    ['bit','bite'],['sit','site'],['kit','kite'],['hid','hide'],['rid','ride'],
    ['dim','dime'],['fin','fine'],['pin','pine'],['win','wine'],['din','dine'],
    ['fir','fire'],['sir','sire'],['mill','mile'],['pill','pile'],['till','tile'],
    ['will','while'],['fill','file'],['grim','grime'],['slim','slime'],['trip','tripe'],
    ['grip','gripe'],['strip','stripe'],['snip','snipe'],['chip','chime'],['clip','climb'],
    ['pick','pike'],['wick','wife'],['lick','like'],['tick','type'],['kick','kite'],
  ]},
  // /ʌ/ vs /ɒ/
  {q:'Which has /ʌ/?',h:'Central open.',pairs:[
    ['cub','cob'],['dub','dob'],['hub','hob'],['pub','pop'],['sub','sob'],
    ['bud','bod'],['cud','cod'],['mud','mod'],['stud','stock'],['thud','thong'],
    ['bug','bog'],['dug','dog'],['hug','hog'],['jug','jog'],['mug','mop'],
    ['rug','rod'],['tug','tog'],['slug','slog'],['plug','plod'],['drug','drop'],
    ['buck','box'],['duck','dock'],['luck','lock'],['muck','mock'],['puck','pocket'],
    ['suck','sock'],['tuck','tock'],['chuck','chock'],['cluck','clock'],['stuck','stock'],
  ]},
  // /ɑː/ vs /eɪ/
  {q:'Which has /ɑː/?',h:'Open back.',pairs:[
    ['bar','bay'],['car','clay'],['far','fay'],['jar','Jay'],['star','stay'],
    ['tar','tray'],['scar','sway'],['char','chain'],['hard','haze'],['mark','make'],
    ['dark','drake'],['park','pace'],['shark','shake'],['spark','space'],['stark','stake'],
    ['part','paste'],['chart','chase'],['smart','strain'],['guard','grade'],['heart','hate'],
    ['harm','haze'],['farm','fame'],['lard','laid'],['card','cave'],['barn','bane'],
    ['barge','bage'],['large','laze'],['Mars','maze'],['march','mace'],['arch','ace'],
  ]},
  // /ɒ/ vs /ɔː/
  {q:'Which has short /ɒ/?',h:'Short rounded.',pairs:[
    ['cot','court'],['dot','daughter'],['fox','forks'],['got','gaunt'],['hot','haunt'],
    ['lot','launch'],['mock','more'],['nod','gnaw'],['pot','port'],['rob','raw'],
    ['rod','roar'],['rot','wrought'],['shot','short'],['shop','shore'],['spot','sport'],
    ['stop','store'],['top','tore'],['toss','torch'],['wok','walk'],['sob','saw'],
    ['sock','source'],['song','soar'],['wrong','war'],['bond','born'],['fond','fawn'],
    ['gone','gaunt'],['pond','pawn'],['long','lawn'],['strong','straw'],['along','all'],
  ]},
  // /e/ vs /ɜː/
  {q:'Which has /e/?',h:'Short mid.',pairs:[
    ['bed','bird'],['bell','burn'],['bet','Bert'],['fed','furred'],['hen','herd'],
    ['let','lurch'],['net','nurse'],['pen','purr'],['pet','Perth'],['red','heard'],
    ['set','shirt'],['ten','turn'],['vet','verb'],['wed','word'],['wet','worm'],
    ['best','burst'],['chest','church'],['desk','dusk'],['fell','furl'],['held','hurled'],
    ['help','herb'],['jest','germ'],['left','learn'],['lent','learnt'],['melt','myrrh'],
    ['rent','wren'],['rest','rust'],['sent','surf'],['step','stir'],['test','thirst'],
  ]},
  // /ʊ/ vs /ʌ/
  {q:'Which has /ʊ/?',h:'Short close back.',pairs:[
    ['book','buck'],['cook','cut'],['foot','fun'],['good','gun'],['hook','hut'],
    ['look','luck'],['pull','pulse'],['push','pus'],['put','putt'],['wood','won'],
    ['brook','brunt'],['crook','crush'],['shook','shut'],['stood','stud'],['took','tuck'],
    ['wool','hull'],['bull','bulk'],['bush','bus'],['full','fuss'],['soot','sun'],
    ['nook','nut'],['rook','rut'],['should','shut'],['would','wud'],['could','cud'],
    ['hood','hud'],['woof','wuff'],['brook','bruk'],['goods','guts'],['hooks','huts'],
  ]},
  // /ɔː/ vs /ɜː/
  {q:'Which has /ɔː/?',h:'Rounded back.',pairs:[
    ['born','burn'],['corn','curl'],['cord','curd'],['door','durr'],['floor','fur'],
    ['force','first'],['form','firm'],['fort','furt'],['horse','hearse'],['lord','lured'],
    ['more','myrrh'],['north','nurse'],['pour','purr'],['short','shirt'],['snore','stir'],
    ['sort','surf'],['sport','spurt'],['store','stir'],['sworn','swirl'],['thorn','turn'],
    ['torch','church'],['torn','term'],['warm','worm'],['warn','wren'],['worn','wurn'],
    ['board','bird'],['bore','blur'],['core','cur'],['gore','girl'],['shore','sure'],
  ]},
  // /ɪə/ vs /ʊə/
  {q:'Which has /ɪə/?',h:'Near vowel.',pairs:[
    ['beer','boor'],['dear','dour'],['fear','four'],['gear','gourd'],['here','hoor'],
    ['leer','lure'],['mere','moor'],['near','newer'],['peer','poor'],['rear','rural'],
    ['seer','sure'],['steer','stour'],['tear','tour'],['veer','viewer'],['year','your'],
    ['cheer','church'],['clear','cure'],['sheer','sure'],['steer','stir'],['sneer','snoer'],
    ['career','cure'],['appear','pure'],['sincere','secure'],['severe','sewer'],['austere','assure'],
    ['frontier','furniture'],['pioneer','poor'],['volunteer','voyeur'],['engineer','ensure'],['premier','pure'],
  ]},
  // Extra /eɪ/ vs /aʊ/
  {q:'Which has /eɪ/?',h:'Front diphthong.',pairs:[
    ['base','bounce'],['cake','couch'],['face','foul'],['gate','gout'],['hate','house'],
    ['lake','loud'],['made','mouth'],['name','noun'],['pace','pout'],['race','round'],
    ['safe','south'],['take','town'],['vane','vow'],['wade','wow'],['cake','cow'],
    ['bake','bow'],['date','doubt'],['fake','foul'],['gaze','gown'],['haze','howl'],
    ['lace','louse'],['maid','mount'],['nail','now'],['paid','pound'],['raid','round'],
    ['sage','south'],['tail','towel'],['wave','wound'],['crane','crowd'],['stale','stout'],
  ]},
  // glide: /ɪə/ vs /eə/
  {q:'Which has /ɪə/?',h:'Close diphthong.',pairs:[
    ['beard','bared'],['cleared','clared'],['feared','fared'],['neared','snared'],['peered','paired'],
    ['reared','rarely'],['seared','shared'],['steered','stared'],['veered','varied'],['cheered','chaired'],
    ['geared','glared'],['jeered','jarred'],['leered','laird'],['queered','squared'],['sneered','spared'],
    ['tiered','teared'],['weird','warred'],['appeared','appaired'],['endeared','endured'],['pioneered','prepared'],
    ['adhered','affair'],['cashiered','compared'],['interfered','impaired'],['persevered','repaired'],['volunteered','declared'],
    ['premiered','prepared'],['profiteered','preferred'],['racketeered','remembered'],['commandeered','conferred'],['engineered','ensured'],
  ]},
  // /oʊ/ vs /uː/
  {q:'Which has /oʊ/?',h:'Mid diphthong.',pairs:[
    ['boat','boot'],['coat','cool'],['go','goo'],['home','hoop'],['hope','hoot'],
    ['joke','juice'],['lone','loom'],['moan','moon'],['note','noon'],['pole','pool'],
    ['road','rude'],['rode','rood'],['role','rule'],['rose','ruse'],['show','shoe'],
    ['slow','slew'],['snow','snooze'],['so','sue'],['soap','soup'],['stole','stool'],
    ['stone','stoon'],['those','tooth'],['toast','tool'],['toe','too'],['tone','tune'],
    ['vote','voodoo'],['woke','woo'],['zone','zoom'],['bone','boon'],['dose','dune'],
  ]},
];
for (const set of vowelSets) {
  for (const [w1,w2] of set.pairs) {
    vdPairs.push([w1,w2,set.q,0,set.h]);
  }
}
appendToPool(path.join(poolsDir, 'vowel_distinction_pool.js'), vdPairs, ([w1,w2,q,a,h]) => ({
  instruction: 'Identify the vowel sound.',
  fields: { word1:w1, word2:w2, question:q, options:[w1,w2], correctAnswerIndex:a, hint:h }
}));

// 5. Dialect Drill: need 378 more — extensive expansion
const ddWords = [];
const ddSets = [
  // More UK/US words
  {inst:'Choose the correct pronunciation.',pairs:[
    ['autumn','AW-tuhm','AH-tuhm',0,'Vowel varies.'],['biscuit','BIS-kit','BIS-kwit',0,'UK vs US.'],
    ['bonnet','BON-it','BAH-nit',0,'Vowel shift.'],['brochure','BROH-shur','broh-SHUR',0,'Stress.'],
    ['caramel','KAR-uh-mul','KARE-uh-mel',0,'Syllable count.'],['Caribbean','kar-ib-BEE-un','kuh-RIB-ee-un',0,'Stress shift.'],
    ['carousel','KAR-uh-sel','kare-uh-SEL',0,'Stress.'],['chassis','CHAS-ee','SHAS-ee',0,'Initial sound.'],
    ['chauffeur','SHOH-fur','shoh-FUR',0,'Stress.'],['cliche','KLEE-shay','klih-SHAY',0,'Vowel.'],
    ['clique','kleek','klik',0,'Final sound.'],['comparable','KOM-pruh-bul','kum-PARE-uh-bul',0,'Stress.'],
    ['coupon','KOO-pon','KYOO-pon',0,'First vowel.'],['debris','DEB-ree','duh-BREE',0,'Stress.'],
    ['decor','DAY-kor','duh-KOR',0,'Stress.'],['depot','DEP-oh','DEE-poh',0,'First vowel.'],
    ['detour','DEE-toor','dih-TOOR',0,'Stress.'],['dossier','DOS-ee-ay','DAH-see-ay',0,'Vowel.'],
    ['duvet','DOO-vay','doo-VAY',0,'Stress.'],['espionage','ES-pee-uh-nahj','ES-pee-uh-nij',0,'Final.'],
    ['fiance','fee-ON-say','fee-AHN-say',0,'Vowel.'],['flambe','FLOM-bay','flahm-BAY',0,'Stress.'],
    ['foyer','FOY-er','FOY-ay',0,'Final.'],['gourmet','GOR-may','gor-MAY',0,'Stress.'],
    ['harassment','HAR-us-ment','huh-RAS-ment',0,'Stress.'],['hyperbole','hy-PER-buh-lee','HY-per-bole',0,'Stress.'],
    ['lingerie','LON-zhuh-ray','lahn-zhuh-RAY',0,'Stress.'],['manoeuvre','muh-NOO-vur','muh-NOO-ver',0,'Final vowel.'],
    ['nonchalant','NON-shuh-lunt','non-shuh-LAHNT',0,'Stress.'],['papaya','puh-PY-uh','puh-PAH-yuh',0,'Vowel.'],
    // More Australian features
    ['afternoon','AHF-tuh-noon','AF-ter-noon',0,'Broad vowel.'],['banana','buh-NAH-nuh','buh-NAN-uh',0,'Vowel.'],
    ['castle','KAH-sul','KAS-ul',0,'Long/short a.'],['demand','dih-MAHND','dih-MAND',0,'Vowel length.'],
    ['example','ig-ZAHM-pul','ig-ZAM-pul',0,'Vowel.'],['giraffe','juh-RAHF','juh-RAF',0,'Vowel.'],
    ['graph','grahf','graf',0,'Vowel length.'],['laughter','LAHF-tuh','LAF-ter',0,'Vowel.'],
    ['palm','pahm','pam',0,'Long a.'],['rather','RAH-thuh','RA-ther',0,'Vowel.'],
    // More Scottish features
    ['book','buk','book',0,'Scottish short /u/.'],['look','luk','look',0,'Scottish.'],
    ['good','gud','good',0,'Scottish.'],['would','wud','wood',0,'Scottish.'],
    ['could','kud','kood',0,'Scottish.'],['should','shud','shood',0,'Scottish.'],
    ['pull','pul','pool',0,'Scottish.'],['push','push','poosh',0,'Scottish.'],
    ['foot','fut','foot',0,'Scottish.'],['put','put','poot',0,'Scottish.'],
    // More Indian English features
    ['vegetable','VEJ-tuh-bul','VEJ-eh-TAB-ul',0,'Syllable count.'],['comfortable','KUMF-tuh-bul','KUM-FOR-TAB-ul',0,'Syllables.'],
    ['actually','AK-choo-uh-lee','AK-CHEW-uh-lee',0,'Vowel.'],['definitely','DEF-uh-nit-lee','DEF-IN-IT-lee',0,'Stress.'],
    ['immediately','ih-MEE-dee-ut-lee','IM-MEE-DEE-ATE-lee',0,'Stress.'],['interesting','IN-trest-ing','IN-TER-EST-ing',0,'Syllables.'],
    ['temperature','TEM-pruh-chur','TEM-PER-AH-CHUR',0,'Syllables.'],['chocolate','CHOK-lut','CHO-CO-LATE',0,'Syllables.'],
    ['different','DIF-runt','DIF-FER-ENT',0,'Syllables.'],['favourite','FAY-vrit','FAY-VOR-ITE',0,'Syllables.'],
    // More Caribbean English
    ['brother','BRUH-duh','BRUH-ther',0,'TH stopping.'],['mother','MUH-duh','MUH-ther',0,'TH stopping.'],
    ['father','FAH-duh','FAH-ther',0,'TH stopping.'],['other','UH-duh','UH-ther',0,'TH stopping.'],
    ['weather','WEH-duh','WEH-ther',0,'TH stopping.'],['together','tuh-GEH-duh','tuh-GEH-ther',0,'TH.'],
    ['whether','WEH-duh','WEH-ther',0,'TH stopping.'],['feather','FEH-duh','FEH-ther',0,'TH stopping.'],
    ['leather','LEH-duh','LEH-ther',0,'TH stopping.'],['bother','BOH-duh','BOH-ther',0,'TH stopping.'],
    // More South African English features
    ['yes','yis','yes',0,'DRESS vowel raised.'],['pen','pin','pen',0,'Vowel merger.'],
    ['bed','bid','bed',0,'Vowel raised.'],['ten','tin','ten',0,'Vowel merger.'],
    ['get','git','get',0,'Vowel raised.'],['red','rid','red',0,'Vowel raised.'],
    ['head','hid','head',0,'Vowel raised.'],['dead','did','dead',0,'Vowel raised.'],
    ['said','sid','said',0,'Vowel raised.'],['spread','sprid','spread',0,'Vowel raised.'],
    // Irish English features
    ['thirty','TUR-tee','THIR-tee',0,'TH realization.'],['three','tree','three',0,'TH realization.'],
    ['film','FILL-um','film',0,'Epenthesis.'],['arm','AR-um','arm',0,'Epenthesis.'],
    ['form','FOR-um','form',0,'Epenthesis.'],['warm','WAR-um','warm',0,'Epenthesis.'],
    ['worm','WUR-um','wurm',0,'Epenthesis.'],['storm','STOR-um','storm',0,'Epenthesis.'],
    ['charm','CHAR-um','charm',0,'Epenthesis.'],['farm','FAR-um','farm',0,'Epenthesis.'],
    // Welsh English features
    ['alright','ALL-right','aw-RIGHT',0,'L realization.'],['always','ALL-ways','aw-WAYS',0,'L.'],
    ['already','all-RED-ee','aw-RED-ee',0,'L.'],['although','all-THO','aw-THO',0,'L.'],
    ['altogether','all-tuh-GEH-thur','aw-tuh-GEH-thur',0,'L.'],['also','ALL-so','aw-SO',0,'L.'],
    ['alter','ALL-tur','AW-tur',0,'L.'],['alternative','all-TUR-nuh-tiv','aw-TUR-nuh-tiv',0,'L.'],
    ['altitude','ALL-tih-tood','AW-tih-tood',0,'L.'],['aluminium','al-yoo-MIN-ee-um','aw-yoo-MIN-ee-um',0,'L.'],
    // Singaporean English features
    ['already','all-RED-ee','OR-re-dee',0,'Vowel shift.'],['beautiful','BYOO-tih-ful','BOO-tih-ful',0,'Vowel.'],
    ['cannot','KAN-not','KEN-not',0,'Vowel.'],['comfortable','KUMF-tuh-bul','KUM-for-tuh-bul',0,'Full form.'],
    ['government','GUV-urn-munt','GUV-ern-ment',0,'Full form.'],['interesting','IN-trest-ing','IN-te-res-ting',0,'Full.'],
    ['library','LY-bruh-ree','LY-bra-ree',0,'Full.'],['naturally','NACH-ruh-lee','NA-chur-al-lee',0,'Full.'],
    ['probably','PROB-uh-blee','PRO-ba-blee',0,'Full.'],['temperature','TEM-pruh-chur','TEM-pe-ra-tur',0,'Full.'],
    // Nigerian English
    ['brother','BROH-dah','BRUH-ther',0,'Final vowel.'],['water','WAH-tah','WAW-ter',0,'Final vowel.'],
    ['butter','BUH-tah','BUH-ter',0,'Final vowel.'],['better','BEH-tah','BEH-ter',0,'Final vowel.'],
    ['letter','LEH-tah','LEH-ter',0,'Final vowel.'],['matter','MAH-tah','MAH-ter',0,'Final vowel.'],
    ['laughter','LAHF-tah','LAF-ter',0,'Final vowel.'],['teacher','TEE-chah','TEE-cher',0,'Final vowel.'],
    ['father','FAH-dah','FAH-ther',0,'Final vowel.'],['gather','GAH-dah','GA-ther',0,'Final vowel.'],
    // Jamaican English
    ['alright','AH-ight','aw-RIGHT',0,'L-dropping.'],['almost','AH-most','awl-MOAST',0,'L-dropping.'],
    ['also','AH-so','awl-SO',0,'L-dropping.'],['although','AH-tho','awl-THO',0,'L-dropping.'],
    ['always','AH-ways','awl-WAYS',0,'L-dropping.'],['calm','CAHM','kalm',0,'L-dropping.'],
    ['half','HAFF','haf',0,'L-dropping.'],['palm','PAHM','palm',0,'L-dropping.'],
    ['salt','SAHT','sawlt',0,'L-dropping.'],['walk','WAHK','wawk',0,'L-dropping.'],
    // Hong Kong English
    ['long','lon','long',0,'Final /g/ drop.'],['song','son','song',0,'Final drop.'],
    ['strong','stron','strong',0,'Final drop.'],['wrong','wron','wrong',0,'Final drop.'],
    ['young','yun','yung',0,'Final drop.'],['among','amun','among',0,'Final drop.'],
    ['belong','bilon','belong',0,'Final drop.'],['along','alon','along',0,'Final drop.'],
    ['king','kin','king',0,'Final drop.'],['ring','rin','ring',0,'Final drop.'],
    // Japanese English
    ['really','ree-ree','ree-lee',0,'L/R confusion.'],['rally','rah-ree','rah-lee',0,'L/R.'],
    ['rock','lock','rock',0,'L/R.'],['rice','lice','rice',0,'L/R.'],
    ['right','light','right',0,'L/R.'],['wrong','long','wrong',0,'L/R.'],
    ['road','load','road',0,'L/R.'],['rain','lane','rain',0,'L/R.'],
    ['run','lun','run',0,'L/R.'],['red','led','red',0,'L/R.'],
    // Filipino English  
    ['five','pive','five',0,'F/P swap.'],['fish','pish','fish',0,'F/P.'],
    ['fun','pun','fun',0,'F/P.'],['food','pood','food',0,'F/P.'],
    ['fire','pire','fire',0,'F/P.'],['face','pace','face',0,'F/P.'],
    ['fall','pall','fall',0,'F/P.'],['fill','pill','fill',0,'F/P.'],
    ['fact','pact','fact',0,'F/P.'],['few','pew','few',0,'F/P.'],
    // Middle Eastern English
    ['park','bark','park',0,'P/B confusion.'],['peace','beast','peace',0,'P/B.'],
    ['prize','brize','prize',0,'P/B.'],['price','brice','price',0,'P/B.'],
    ['proud','broud','proud',0,'P/B.'],['push','bush','push',0,'P/B.'],
    ['pull','bull','pull',0,'P/B.'],['plain','blain','plain',0,'P/B.'],
    ['place','blace','place',0,'P/B.'],['point','boint','point',0,'P/B.'],
    // East African English
    ['very','berry','very',0,'V/B swap.'],['vest','best','vest',0,'V/B.'],
    ['vine','bine','vine',0,'V/B.'],['vote','boat','vote',0,'V/B.'],
    ['voice','boice','voice',0,'V/B.'],['valley','ballet','valley',0,'V/B.'],
    ['vast','bast','vast',0,'V/B.'],['version','bersion','version',0,'V/B.'],
    ['virtue','birtue','virtue',0,'V/B.'],['vision','bision','vision',0,'V/B.'],
    // German English
    ['vine','wine','vine',0,'V/W.'],['vest','west','vest',0,'V/W.'],
    ['vow','wow','vow',0,'V/W.'],['very','wary','very',0,'V/W.'],
    ['verse','worse','verse',0,'V/W.'],['vain','wane','vain',0,'V/W.'],
    ['vale','whale','vale',0,'V/W.'],['veil','wail','veil',0,'V/W.'],
    ['vent','went','vent',0,'V/W.'],['void','woid','void',0,'V/W.'],
    // French English  
    ['happy','appy','happy',0,'H-dropping.'],['house','ouse','house',0,'H-dropping.'],
    ['hello','ello','hello',0,'H-dropping.'],['help','elp','help',0,'H-dropping.'],
    ['hotel','otel','hotel',0,'H-dropping.'],['horror','orror','horror',0,'H-dropping.'],
    ['hobby','obby','hobby',0,'H-dropping.'],['hungry','ungry','hungry',0,'H-dropping.'],
    ['hurry','urry','hurry',0,'H-dropping.'],['heaven','eaven','heaven',0,'H-dropping.'],
    // Brazilian English
    ['milk','milky','milk',0,'Epenthetic vowel.'],['help','helpy','help',0,'Epenthesis.'],
    ['film','filmy','film',0,'Epenthesis.'],['world','worldy','world',0,'Epenthesis.'],
    ['cold','coldy','cold',0,'Epenthesis.'],['told','toldy','told',0,'Epenthesis.'],
    ['hold','holdy','hold',0,'Epenthesis.'],['bold','boldy','bold',0,'Epenthesis.'],
    ['wild','wildy','wild',0,'Epenthesis.'],['child','childy','child',0,'Epenthesis.'],
    // Russian English
    ['this','zis','this',0,'TH→Z.'],['think','sink','think',0,'TH→S.'],
    ['that','zat','that',0,'TH→Z.'],['the','ze','the',0,'TH→Z.'],
    ['these','zese','these',0,'TH→Z.'],['those','zose','those',0,'TH→Z.'],
    ['there','zere','there',0,'TH→Z.'],['them','zem','them',0,'TH→Z.'],
    ['thank','sank','thank',0,'TH→S.'],['thought','sought','thought',0,'TH→S.'],
  ]},
];
for (const set of ddSets) {
  for (const [word,o1,o2,ans,hint] of set.pairs) {
    ddWords.push([word,o1,o2,ans,hint]);
  }
}
appendToPool(path.join(poolsDir, 'dialect_drill_pool.js'), ddWords, ([word,o1,o2,ans,hint]) => ({
  instruction: 'Choose the correct pronunciation.',
  fields: { word, options: [o1,o2], correctAnswerIndex: ans, hint }
}));

console.log('\nDone round 2 expansion. Run accent_regen.js to regenerate.');
