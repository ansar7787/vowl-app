const getIpa = require(__dirname + '/get_ipa.js');
// Vowel Distinction: 600 unique word-pair questions — DIFFERENT from minimalPairs
module.exports = function() {
  const pool = [];
  const pairs = [
    // /ɑː/ vs /ɔː/ (father vs caught)
    ['cart','court','Which has /ɑː/?',0,'Open back.'],['far','four','Which has /ɑː/?',0,'Open back.'],
    ['barn','born','Which has /ɑː/?',0,'Open back.'],['star','store','Which has /ɑː/?',0,'Open back.'],
    ['heart','horse','Which has /ɑː/?',0,'Open back.'],['marsh','porch','Which has /ɑː/?',0,'Open back.'],
    ['dark','fork','Which has /ɑː/?',0,'Open back.'],['large','forge','Which has /ɑː/?',0,'Open back.'],
    ['arch','torch','Which has /ɑː/?',0,'Open back.'],['charm','form','Which has /ɑː/?',0,'Open back.'],
    ['park','pork','Which has /ɑː/?',0,'Open back.'],['sharp','short','Which has /ɑː/?',0,'Open back.'],
    ['hard','hoard','Which has /ɑː/?',0,'Open back.'],['march','scorch','Which has /ɑː/?',0,'Open back.'],
    ['shark','stork','Which has /ɑː/?',0,'Open back.'],['spark','sport','Which has /ɑː/?',0,'Open back.'],
    ['carve','course','Which has /ɑː/?',0,'Open back.'],['garden','gorge','Which has /ɑː/?',0,'Open back.'],
    ['harvest','horses','Which has /ɑː/?',0,'Open back.'],['marble','mortar','Which has /ɑː/?',0,'Open back.'],
    // /ɜː/ vs /ɒ/ (bird vs box)
    ['burn','bond','Which has /ɜː/?',0,'Mid central.'],['turn','torn','Which has /ɜː/?',0,'Mid central.'],
    ['firm','farm','Which has /ɜː/?',0,'Mid central.'],['work','walk','Which has /ɜː/?',0,'Mid central.'],
    ['word','ward','Which has /ɜː/?',0,'Mid central.'],['first','frost','Which has /ɜː/?',0,'Mid central.'],
    ['nurse','north','Which has /ɜː/?',0,'Mid central.'],['hurt','hot','Which has /ɜː/?',0,'Mid central.'],
    ['bird','board','Which has /ɜː/?',0,'Mid central.'],['curl','coral','Which has /ɜː/?',0,'Mid central.'],
    ['purse','pause','Which has /ɜː/?',0,'Mid central.'],['stir','star','Which has /ɜː/?',0,'Mid central.'],
    ['fur','far','Which has /ɜː/?',0,'Mid central.'],['dirt','dart','Which has /ɜː/?',0,'Mid central.'],
    ['shirt','shot','Which has /ɜː/?',0,'Mid central.'],['skirt','sort','Which has /ɜː/?',0,'Mid central.'],
    ['third','thought','Which has /ɜː/?',0,'Mid central.'],['church','choice','Which has /ɜː/?',0,'Mid central.'],
    ['nerve','knave','Which has /ɜː/?',0,'Mid central.'],['curve','carve','Which has /ɜː/?',0,'Mid central.'],
    // /eɪ/ vs /aɪ/ (diphthongs)
    ['late','light','Which has /eɪ/?',0,'Mouth glides to /ɪ/.'],['made','mind','Which has /eɪ/?',0,'Diphthong /eɪ/.'],
    ['rain','Rhine','Which has /eɪ/?',0,'Diphthong /eɪ/.'],['tail','tile','Which has /eɪ/?',0,'Diphthong /eɪ/.'],
    ['mate','might','Which has /eɪ/?',0,'Diphthong /eɪ/.'],['lake','like','Which has /eɪ/?',0,'Diphthong /eɪ/.'],
    ['bake','bike','Which has /eɪ/?',0,'Diphthong /eɪ/.'],['cake','kite','Which has /eɪ/?',0,'Diphthong /eɪ/.'],
    ['date','dine','Which has /eɪ/?',0,'Diphthong /eɪ/.'],['fate','fight','Which has /eɪ/?',0,'Diphthong /eɪ/.'],
    ['gate','guide','Which has /eɪ/?',0,'Diphthong /eɪ/.'],['hate','height','Which has /eɪ/?',0,'Diphthong /eɪ/.'],
    ['lane','line','Which has /eɪ/?',0,'Diphthong /eɪ/.'],['name','nine','Which has /eɪ/?',0,'Diphthong /eɪ/.'],
    ['pace','price','Which has /eɪ/?',0,'Diphthong /eɪ/.'],['sale','sigh','Which has /eɪ/?',0,'Diphthong /eɪ/.'],
    ['tale','time','Which has /eɪ/?',0,'Diphthong /eɪ/.'],['vane','vine','Which has /eɪ/?',0,'Diphthong /eɪ/.'],
    ['wade','wide','Which has /eɪ/?',0,'Diphthong /eɪ/.'],['wave','wipe','Which has /eɪ/?',0,'Diphthong /eɪ/.'],
    // /aʊ/ vs /əʊ/ (diphthongs)
    ['down','dome','Which has /aʊ/?',0,'Open diphthong.'],['town','tone','Which has /aʊ/?',0,'Open diphthong.'],
    ['found','phone','Which has /aʊ/?',0,'Open diphthong.'],['ground','groan','Which has /aʊ/?',0,'Open diphthong.'],
    ['round','road','Which has /aʊ/?',0,'Open diphthong.'],['sound','sown','Which has /aʊ/?',0,'Open diphthong.'],
    ['count','coat','Which has /aʊ/?',0,'Open diphthong.'],['loud','load','Which has /aʊ/?',0,'Open diphthong.'],
    ['mount','moat','Which has /aʊ/?',0,'Open diphthong.'],['pound','pole','Which has /aʊ/?',0,'Open diphthong.'],
    ['crowd','crow','Which has /aʊ/?',0,'Open diphthong.'],['frown','flow','Which has /aʊ/?',0,'Open diphthong.'],
    ['shout','show','Which has /aʊ/?',0,'Open diphthong.'],['mouth','moth','Which has /aʊ/?',0,'Open diphthong.'],
    ['scout','scope','Which has /aʊ/?',0,'Open diphthong.'],['couch','coach','Which has /aʊ/?',0,'Open diphthong.'],
    ['trout','throat','Which has /aʊ/?',0,'Open diphthong.'],['pout','post','Which has /aʊ/?',0,'Open diphthong.'],
    ['bout','boat','Which has /aʊ/?',0,'Open diphthong.'],['noun','known','Which has /aʊ/?',0,'Open diphthong.'],
    // /ɪə/ vs /eə/ (near vs square)
    ['beer','bear','Which has /ɪə/?',0,'Near diphthong.'],['deer','dare','Which has /ɪə/?',0,'Near diphthong.'],
    ['fear','fair','Which has /ɪə/?',0,'Near diphthong.'],['hear','hair','Which has /ɪə/?',0,'Near diphthong.'],
    ['near','snare','Which has /ɪə/?',0,'Near diphthong.'],['peer','pair','Which has /ɪə/?',0,'Near diphthong.'],
    ['rear','rare','Which has /ɪə/?',0,'Near diphthong.'],['sheer','share','Which has /ɪə/?',0,'Near diphthong.'],
    ['steer','stare','Which has /ɪə/?',0,'Near diphthong.'],['tear','tare','Which has /ɪə/?',0,'Near diphthong.'],
    ['cheer','chair','Which has /ɪə/?',0,'Near diphthong.'],['clear','Clare','Which has /ɪə/?',0,'Near diphthong.'],
    ['gear','glare','Which has /ɪə/?',0,'Near diphthong.'],['leer','lair','Which has /ɪə/?',0,'Near diphthong.'],
    ['mere','mare','Which has /ɪə/?',0,'Near diphthong.'],['pier','pear','Which has /ɪə/?',0,'Near diphthong.'],
    ['seer','swear','Which has /ɪə/?',0,'Near diphthong.'],['sphere','spare','Which has /ɪə/?',0,'Near diphthong.'],
    ['tier','their','Which has /ɪə/?',0,'Near diphthong.'],['veer','vary','Which has /ɪə/?',0,'Near diphthong.'],
    // /ʌ/ vs /ɑː/
    ['duck','dark','Which has /ʌ/?',0,'Short central.'],['luck','lark','Which has /ʌ/?',0,'Short central.'],
    ['muck','mark','Which has /ʌ/?',0,'Short central.'],['pup','park','Which has /ʌ/?',0,'Short central.'],
    ['cup','carp','Which has /ʌ/?',0,'Short central.'],['rub','rob','Which has /ʌ/?',0,'Short central.'],
    ['bug','bog','Which has /ʌ/?',0,'Short central.'],['dug','dog','Which has /ʌ/?',0,'Short central.'],
    ['hug','hog','Which has /ʌ/?',0,'Short central.'],['jug','jog','Which has /ʌ/?',0,'Short central.'],
    ['tug','tog','Which has /ʌ/?',0,'Short central.'],['mud','mod','Which has /ʌ/?',0,'Short central.'],
    ['stud','star','Which has /ʌ/?',0,'Short central.'],['thud','thought','Which has /ʌ/?',0,'Short central.'],
    ['gust','gasp','Which has /ʌ/?',0,'Short central.'],['dust','dusk','Which has /ʌ/?',0,'Short central.'],
    ['must','mast','Which has /ʌ/?',0,'Short central.'],['rust','rash','Which has /ʌ/?',0,'Short central.'],
    ['cuff','calf','Which has /ʌ/?',0,'Short central.'],['stuff','staff','Which has /ʌ/?',0,'Short central.'],
    // /ɔɪ/ vs /aɪ/
    ['boy','buy','Which has /ɔɪ/?',0,'Rounded diphthong.'],['toy','tie','Which has /ɔɪ/?',0,'Rounded diphthong.'],
    ['joy','jive','Which has /ɔɪ/?',0,'Rounded diphthong.'],['coil','Kyle','Which has /ɔɪ/?',0,'Rounded diphthong.'],
    ['foil','file','Which has /ɔɪ/?',0,'Rounded diphthong.'],['oil','aisle','Which has /ɔɪ/?',0,'Rounded diphthong.'],
    ['soil','sigh','Which has /ɔɪ/?',0,'Rounded diphthong.'],['toil','tile','Which has /ɔɪ/?',0,'Rounded diphthong.'],
    ['boil','bile','Which has /ɔɪ/?',0,'Rounded diphthong.'],['coin','kind','Which has /ɔɪ/?',0,'Rounded diphthong.'],
    ['join','jibe','Which has /ɔɪ/?',0,'Rounded diphthong.'],['noise','nice','Which has /ɔɪ/?',0,'Rounded diphthong.'],
    ['point','pint','Which has /ɔɪ/?',0,'Rounded diphthong.'],['voice','vice','Which has /ɔɪ/?',0,'Rounded diphthong.'],
    ['choice','chime','Which has /ɔɪ/?',0,'Rounded diphthong.'],['moist','mice','Which has /ɔɪ/?',0,'Rounded diphthong.'],
    ['hoist','height','Which has /ɔɪ/?',0,'Rounded diphthong.'],['joist','jive','Which has /ɔɪ/?',0,'Rounded diphthong.'],
    ['royal','rival','Which has /ɔɪ/?',0,'Rounded diphthong.'],['loyal','lion','Which has /ɔɪ/?',0,'Rounded diphthong.'],
    // /æ/ vs /ɑː/
    ['cap','carp','Which has /æ/?',0,'Front vowel.'],['hat','heart','Which has /æ/?',0,'Front vowel.'],
    ['cat','cart','Which has /æ/?',0,'Front vowel.'],['bat','bark','Which has /æ/?',0,'Front vowel.'],
    ['pan','park','Which has /æ/?',0,'Front vowel.'],['ram','arm','Which has /æ/?',0,'Front vowel.'],
    ['jam','jar','Which has /æ/?',0,'Front vowel.'],['ham','harm','Which has /æ/?',0,'Front vowel.'],
    ['lamp','lard','Which has /æ/?',0,'Front vowel.'],['stamp','start','Which has /æ/?',0,'Front vowel.'],
    ['camp','calm','Which has /æ/?',0,'Front vowel.'],['damp','dark','Which has /æ/?',0,'Front vowel.'],
    ['track','trunk','Which has /æ/?',0,'Front vowel.'],['flat','flair','Which has /æ/?',0,'Front vowel.'],
    ['gram','graph','Which has /æ/?',0,'Front vowel.'],['snap','snare','Which has /æ/?',0,'Front vowel.'],
    ['strap','star','Which has /æ/?',0,'Front vowel.'],['trap','tarp','Which has /æ/?',0,'Front vowel.'],
    ['clap','clasp','Which has /æ/?',0,'Front vowel.'],['wrap','warp','Which has /æ/?',0,'Front vowel.'],
    // /e/ vs /ɪ/
    ['bed','bid','Which has /e/?',0,'Mid front vowel.'],['pen','pin','Which has /e/?',0,'Mid front vowel.'],
    ['set','sit','Which has /e/?',0,'Mid front vowel.'],['red','rid','Which has /e/?',0,'Mid front vowel.'],
    ['hex','hicks','Which has /e/?',0,'Mid front vowel.'],['sell','sill','Which has /e/?',0,'Mid front vowel.'],
    ['tell','till','Which has /e/?',0,'Mid front vowel.'],['bell','bill','Which has /e/?',0,'Mid front vowel.'],
    ['fell','fill','Which has /e/?',0,'Mid front vowel.'],['well','will','Which has /e/?',0,'Mid front vowel.'],
    ['west','wist','Which has /e/?',0,'Mid front vowel.'],['best','bist','Which has /e/?',0,'Mid front vowel.'],
    ['rest','wrist','Which has /e/?',0,'Mid front vowel.'],['test','fist','Which has /e/?',0,'Mid front vowel.'],
    ['vest','vist','Which has /e/?',0,'Mid front vowel.'],['pest','piss','Which has /e/?',0,'Mid front vowel.'],
    ['nest','nip','Which has /e/?',0,'Mid front vowel.'],['mess','miss','Which has /e/?',0,'Mid front vowel.'],
    ['beg','big','Which has /e/?',0,'Mid front vowel.'],['leg','lid','Which has /e/?',0,'Mid front vowel.'],
    // /iː/ vs /eɪ/
    ['seen','sane','Which has /iː/?',0,'Long close front.'],['keen','cane','Which has /iː/?',0,'Long close front.'],
    ['teen','train','Which has /iː/?',0,'Long close front.'],['lean','lane','Which has /iː/?',0,'Long close front.'],
    ['mean','main','Which has /iː/?',0,'Long close front.'],['cheap','chain','Which has /iː/?',0,'Long close front.'],
    ['dear','day','Which has /iː/?',0,'Long close front.'],['feed','fade','Which has /iː/?',0,'Long close front.'],
    ['peak','pace','Which has /iː/?',0,'Long close front.'],['reed','raid','Which has /iː/?',0,'Long close front.'],
    ['seal','sail','Which has /iː/?',0,'Long close front.'],['steel','stake','Which has /iː/?',0,'Long close front.'],
    ['sweet','sway','Which has /iː/?',0,'Long close front.'],['teeth','taste','Which has /iː/?',0,'Long close front.'],
    ['wheel','whale','Which has /iː/?',0,'Long close front.'],['scene','same','Which has /iː/?',0,'Long close front.'],
    ['breeze','brave','Which has /iː/?',0,'Long close front.'],['cheese','chase','Which has /iː/?',0,'Long close front.'],
    ['freeze','frame','Which has /iː/?',0,'Long close front.'],['sleeve','slave','Which has /iː/?',0,'Long close front.'],
    // /uː/ vs /ɔː/
    ['boot','bought','Which has /uː/?',0,'Close back rounded.'],['food','ford','Which has /uː/?',0,'Close back.'],
    ['moon','morn','Which has /uː/?',0,'Close back.'],['pool','Paul','Which has /uː/?',0,'Close back.'],
    ['cool','call','Which has /uː/?',0,'Close back.'],['room','roar','Which has /uː/?',0,'Close back.'],
    ['tool','tall','Which has /uː/?',0,'Close back.'],['zoom','zone','Which has /uː/?',0,'Close back.'],
    ['bloom','born','Which has /uː/?',0,'Close back.'],['goose','gauze','Which has /uː/?',0,'Close back.'],
    ['loose','loss','Which has /uː/?',0,'Close back.'],['mood','more','Which has /uː/?',0,'Close back.'],
    ['noon','nor','Which has /uː/?',0,'Close back.'],['proof','pork','Which has /uː/?',0,'Close back.'],
    ['roof','raw','Which has /uː/?',0,'Close back.'],['smooth','small','Which has /uː/?',0,'Close back.'],
    ['spoon','spawn','Which has /uː/?',0,'Close back.'],['tooth','thought','Which has /uː/?',0,'Close back.'],
    ['troop','trawl','Which has /uː/?',0,'Close back.'],['fruit','freight','Which has /uː/?',0,'Close back.'],
    // Schwa /ə/ pairs
    ['about','abbot','Which has the schwa /ə/?',0,'Unstressed.'],['ago','Agra','Which has the schwa /ə/?',0,'Unstressed.'],
    ['alone','almost','Which has the schwa /ə/?',0,'Unstressed.'],['aware','awkward','Which has the schwa /ə/?',0,'Unstressed.'],
    ['banana','bandana','Which has the schwa /ə/?',0,'Unstressed.'],['china','chime','Which has the schwa /ə/?',0,'Unstressed.'],
    ['sofa','soft','Which has the schwa /ə/?',0,'Unstressed.'],['data','date','Which has the schwa /ə/?',0,'Unstressed.'],
    ['extra','exit','Which has the schwa /ə/?',0,'Unstressed.'],['fatal','fact','Which has the schwa /ə/?',0,'Unstressed.'],
    ['final','find','Which has the schwa /ə/?',0,'Unstressed.'],['global','globe','Which has the schwa /ə/?',0,'Unstressed.'],
    ['legal','league','Which has the schwa /ə/?',0,'Unstressed.'],['local','lock','Which has the schwa /ə/?',0,'Unstressed.'],
    ['mental','mint','Which has the schwa /ə/?',0,'Unstressed.'],['moral','more','Which has the schwa /ə/?',0,'Unstressed.'],
    ['normal','norm','Which has the schwa /ə/?',0,'Unstressed.'],['total','toll','Which has the schwa /ə/?',0,'Unstressed.'],
    ['vital','vibe','Which has the schwa /ə/?',0,'Unstressed.'],['vocal','vote','Which has the schwa /ə/?',0,'Unstressed.'],
  ];
  for (const [w1,w2,question,ans,hint] of pairs) {
    pool.push({
      instruction: 'Identify the vowel sound.',
      fields: { word1:w1, word2:w2, ipa1: typeof w1 === 'string' ? getIpa(w1.split(' ')[0]) : '', ipa2: typeof w2 === 'string' ? getIpa(w2.split(' ')[0]) : '', question, options:[w1,w2], correctAnswerIndex:ans, hint }
    });
  }
  
  // === ROUND 2 AUTO-EXPANDED ===
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"hat","word2":"hate","question":"Which has /æ/?","options":["hat","hate"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"mat","word2":"mate","question":"Which has /æ/?","options":["mat","mate"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"fat","word2":"fate","question":"Which has /æ/?","options":["fat","fate"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"rat","word2":"rate","question":"Which has /æ/?","options":["rat","rate"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"man","word2":"mane","question":"Which has /æ/?","options":["man","mane"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"can","word2":"cane","question":"Which has /æ/?","options":["can","cane"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"plan","word2":"plane","question":"Which has /æ/?","options":["plan","plane"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pan","word2":"pane","question":"Which has /æ/?","options":["pan","pane"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"gap","word2":"gape","question":"Which has /æ/?","options":["gap","gape"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"tap","word2":"tape","question":"Which has /æ/?","options":["tap","tape"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"cap","word2":"cape","question":"Which has /æ/?","options":["cap","cape"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"map","word2":"mope","question":"Which has /æ/?","options":["map","mope"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"lam","word2":"lame","question":"Which has /æ/?","options":["lam","lame"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"dam","word2":"dame","question":"Which has /æ/?","options":["dam","dame"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"Sam","word2":"same","question":"Which has /æ/?","options":["Sam","same"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bad","word2":"bade","question":"Which has /æ/?","options":["bad","bade"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"mad","word2":"made","question":"Which has /æ/?","options":["mad","made"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"fad","word2":"fade","question":"Which has /æ/?","options":["fad","fade"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"glad","word2":"glade","question":"Which has /æ/?","options":["glad","glade"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"shag","word2":"shade","question":"Which has /æ/?","options":["shag","shade"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"lab","word2":"late","question":"Which has /æ/?","options":["lab","late"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"tab","word2":"tale","question":"Which has /æ/?","options":["tab","tale"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"grab","word2":"grape","question":"Which has /æ/?","options":["grab","grape"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"slam","word2":"slain","question":"Which has /æ/?","options":["slam","slain"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"clan","word2":"claim","question":"Which has /æ/?","options":["clan","claim"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"clam","word2":"claim","question":"Which has /æ/?","options":["clam","claim"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"ram","word2":"rain","question":"Which has /æ/?","options":["ram","rain"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"jam","word2":"Jane","question":"Which has /æ/?","options":["jam","Jane"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"slab","word2":"slave","question":"Which has /æ/?","options":["slab","slave"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"snap","word2":"snake","question":"Which has /æ/?","options":["snap","snake"],"correctAnswerIndex":0,"hint":"Short front."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bit","word2":"bite","question":"Which has /ɪ/?","options":["bit","bite"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sit","word2":"site","question":"Which has /ɪ/?","options":["sit","site"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"kit","word2":"kite","question":"Which has /ɪ/?","options":["kit","kite"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"hid","word2":"hide","question":"Which has /ɪ/?","options":["hid","hide"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"rid","word2":"ride","question":"Which has /ɪ/?","options":["rid","ride"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"dim","word2":"dime","question":"Which has /ɪ/?","options":["dim","dime"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"fin","word2":"fine","question":"Which has /ɪ/?","options":["fin","fine"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pin","word2":"pine","question":"Which has /ɪ/?","options":["pin","pine"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"win","word2":"wine","question":"Which has /ɪ/?","options":["win","wine"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"din","word2":"dine","question":"Which has /ɪ/?","options":["din","dine"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"fir","word2":"fire","question":"Which has /ɪ/?","options":["fir","fire"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sir","word2":"sire","question":"Which has /ɪ/?","options":["sir","sire"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"mill","word2":"mile","question":"Which has /ɪ/?","options":["mill","mile"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pill","word2":"pile","question":"Which has /ɪ/?","options":["pill","pile"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"till","word2":"tile","question":"Which has /ɪ/?","options":["till","tile"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"will","word2":"while","question":"Which has /ɪ/?","options":["will","while"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"fill","word2":"file","question":"Which has /ɪ/?","options":["fill","file"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"grim","word2":"grime","question":"Which has /ɪ/?","options":["grim","grime"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"slim","word2":"slime","question":"Which has /ɪ/?","options":["slim","slime"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"trip","word2":"tripe","question":"Which has /ɪ/?","options":["trip","tripe"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"grip","word2":"gripe","question":"Which has /ɪ/?","options":["grip","gripe"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"strip","word2":"stripe","question":"Which has /ɪ/?","options":["strip","stripe"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"snip","word2":"snipe","question":"Which has /ɪ/?","options":["snip","snipe"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"chip","word2":"chime","question":"Which has /ɪ/?","options":["chip","chime"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"clip","word2":"climb","question":"Which has /ɪ/?","options":["clip","climb"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pick","word2":"pike","question":"Which has /ɪ/?","options":["pick","pike"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"wick","word2":"wife","question":"Which has /ɪ/?","options":["wick","wife"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"lick","word2":"like","question":"Which has /ɪ/?","options":["lick","like"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"tick","word2":"type","question":"Which has /ɪ/?","options":["tick","type"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"kick","word2":"kite","question":"Which has /ɪ/?","options":["kick","kite"],"correctAnswerIndex":0,"hint":"Short close."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"cub","word2":"cob","question":"Which has /ʌ/?","options":["cub","cob"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"dub","word2":"dob","question":"Which has /ʌ/?","options":["dub","dob"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"hub","word2":"hob","question":"Which has /ʌ/?","options":["hub","hob"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pub","word2":"pop","question":"Which has /ʌ/?","options":["pub","pop"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sub","word2":"sob","question":"Which has /ʌ/?","options":["sub","sob"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bud","word2":"bod","question":"Which has /ʌ/?","options":["bud","bod"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"cud","word2":"cod","question":"Which has /ʌ/?","options":["cud","cod"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"mud","word2":"mod","question":"Which has /ʌ/?","options":["mud","mod"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"stud","word2":"stock","question":"Which has /ʌ/?","options":["stud","stock"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"thud","word2":"thong","question":"Which has /ʌ/?","options":["thud","thong"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bug","word2":"bog","question":"Which has /ʌ/?","options":["bug","bog"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"dug","word2":"dog","question":"Which has /ʌ/?","options":["dug","dog"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"hug","word2":"hog","question":"Which has /ʌ/?","options":["hug","hog"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"jug","word2":"jog","question":"Which has /ʌ/?","options":["jug","jog"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"mug","word2":"mop","question":"Which has /ʌ/?","options":["mug","mop"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"rug","word2":"rod","question":"Which has /ʌ/?","options":["rug","rod"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"tug","word2":"tog","question":"Which has /ʌ/?","options":["tug","tog"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"slug","word2":"slog","question":"Which has /ʌ/?","options":["slug","slog"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"plug","word2":"plod","question":"Which has /ʌ/?","options":["plug","plod"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"drug","word2":"drop","question":"Which has /ʌ/?","options":["drug","drop"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"buck","word2":"box","question":"Which has /ʌ/?","options":["buck","box"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"duck","word2":"dock","question":"Which has /ʌ/?","options":["duck","dock"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"luck","word2":"lock","question":"Which has /ʌ/?","options":["luck","lock"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"muck","word2":"mock","question":"Which has /ʌ/?","options":["muck","mock"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"puck","word2":"pocket","question":"Which has /ʌ/?","options":["puck","pocket"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"suck","word2":"sock","question":"Which has /ʌ/?","options":["suck","sock"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"tuck","word2":"tock","question":"Which has /ʌ/?","options":["tuck","tock"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"chuck","word2":"chock","question":"Which has /ʌ/?","options":["chuck","chock"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"cluck","word2":"clock","question":"Which has /ʌ/?","options":["cluck","clock"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"stuck","word2":"stock","question":"Which has /ʌ/?","options":["stuck","stock"],"correctAnswerIndex":0,"hint":"Central open."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bar","word2":"bay","question":"Which has /ɑː/?","options":["bar","bay"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"car","word2":"clay","question":"Which has /ɑː/?","options":["car","clay"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"far","word2":"fay","question":"Which has /ɑː/?","options":["far","fay"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"jar","word2":"Jay","question":"Which has /ɑː/?","options":["jar","Jay"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"star","word2":"stay","question":"Which has /ɑː/?","options":["star","stay"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"tar","word2":"tray","question":"Which has /ɑː/?","options":["tar","tray"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"scar","word2":"sway","question":"Which has /ɑː/?","options":["scar","sway"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"char","word2":"chain","question":"Which has /ɑː/?","options":["char","chain"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"hard","word2":"haze","question":"Which has /ɑː/?","options":["hard","haze"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"mark","word2":"make","question":"Which has /ɑː/?","options":["mark","make"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"dark","word2":"drake","question":"Which has /ɑː/?","options":["dark","drake"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"park","word2":"pace","question":"Which has /ɑː/?","options":["park","pace"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"shark","word2":"shake","question":"Which has /ɑː/?","options":["shark","shake"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"spark","word2":"space","question":"Which has /ɑː/?","options":["spark","space"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"stark","word2":"stake","question":"Which has /ɑː/?","options":["stark","stake"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"part","word2":"paste","question":"Which has /ɑː/?","options":["part","paste"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"chart","word2":"chase","question":"Which has /ɑː/?","options":["chart","chase"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"smart","word2":"strain","question":"Which has /ɑː/?","options":["smart","strain"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"guard","word2":"grade","question":"Which has /ɑː/?","options":["guard","grade"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"heart","word2":"hate","question":"Which has /ɑː/?","options":["heart","hate"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"harm","word2":"haze","question":"Which has /ɑː/?","options":["harm","haze"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"farm","word2":"fame","question":"Which has /ɑː/?","options":["farm","fame"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"lard","word2":"laid","question":"Which has /ɑː/?","options":["lard","laid"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"card","word2":"cave","question":"Which has /ɑː/?","options":["card","cave"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"barn","word2":"bane","question":"Which has /ɑː/?","options":["barn","bane"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"barge","word2":"bage","question":"Which has /ɑː/?","options":["barge","bage"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"large","word2":"laze","question":"Which has /ɑː/?","options":["large","laze"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"Mars","word2":"maze","question":"Which has /ɑː/?","options":["Mars","maze"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"march","word2":"mace","question":"Which has /ɑː/?","options":["march","mace"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"arch","word2":"ace","question":"Which has /ɑː/?","options":["arch","ace"],"correctAnswerIndex":0,"hint":"Open back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"cot","word2":"court","question":"Which has short /ɒ/?","options":["cot","court"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"dot","word2":"daughter","question":"Which has short /ɒ/?","options":["dot","daughter"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"fox","word2":"forks","question":"Which has short /ɒ/?","options":["fox","forks"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"got","word2":"gaunt","question":"Which has short /ɒ/?","options":["got","gaunt"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"hot","word2":"haunt","question":"Which has short /ɒ/?","options":["hot","haunt"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"lot","word2":"launch","question":"Which has short /ɒ/?","options":["lot","launch"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"mock","word2":"more","question":"Which has short /ɒ/?","options":["mock","more"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"nod","word2":"gnaw","question":"Which has short /ɒ/?","options":["nod","gnaw"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pot","word2":"port","question":"Which has short /ɒ/?","options":["pot","port"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"rob","word2":"raw","question":"Which has short /ɒ/?","options":["rob","raw"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"rod","word2":"roar","question":"Which has short /ɒ/?","options":["rod","roar"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"rot","word2":"wrought","question":"Which has short /ɒ/?","options":["rot","wrought"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"shot","word2":"short","question":"Which has short /ɒ/?","options":["shot","short"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"shop","word2":"shore","question":"Which has short /ɒ/?","options":["shop","shore"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"spot","word2":"sport","question":"Which has short /ɒ/?","options":["spot","sport"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"stop","word2":"store","question":"Which has short /ɒ/?","options":["stop","store"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"top","word2":"tore","question":"Which has short /ɒ/?","options":["top","tore"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"toss","word2":"torch","question":"Which has short /ɒ/?","options":["toss","torch"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"wok","word2":"walk","question":"Which has short /ɒ/?","options":["wok","walk"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sob","word2":"saw","question":"Which has short /ɒ/?","options":["sob","saw"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sock","word2":"source","question":"Which has short /ɒ/?","options":["sock","source"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"song","word2":"soar","question":"Which has short /ɒ/?","options":["song","soar"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"wrong","word2":"war","question":"Which has short /ɒ/?","options":["wrong","war"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bond","word2":"born","question":"Which has short /ɒ/?","options":["bond","born"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"fond","word2":"fawn","question":"Which has short /ɒ/?","options":["fond","fawn"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"gone","word2":"gaunt","question":"Which has short /ɒ/?","options":["gone","gaunt"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pond","word2":"pawn","question":"Which has short /ɒ/?","options":["pond","pawn"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"long","word2":"lawn","question":"Which has short /ɒ/?","options":["long","lawn"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"strong","word2":"straw","question":"Which has short /ɒ/?","options":["strong","straw"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"along","word2":"all","question":"Which has short /ɒ/?","options":["along","all"],"correctAnswerIndex":0,"hint":"Short rounded."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bed","word2":"bird","question":"Which has /e/?","options":["bed","bird"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bell","word2":"burn","question":"Which has /e/?","options":["bell","burn"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bet","word2":"Bert","question":"Which has /e/?","options":["bet","Bert"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"fed","word2":"furred","question":"Which has /e/?","options":["fed","furred"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"hen","word2":"herd","question":"Which has /e/?","options":["hen","herd"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"let","word2":"lurch","question":"Which has /e/?","options":["let","lurch"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"net","word2":"nurse","question":"Which has /e/?","options":["net","nurse"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pen","word2":"purr","question":"Which has /e/?","options":["pen","purr"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pet","word2":"Perth","question":"Which has /e/?","options":["pet","Perth"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"red","word2":"heard","question":"Which has /e/?","options":["red","heard"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"set","word2":"shirt","question":"Which has /e/?","options":["set","shirt"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"ten","word2":"turn","question":"Which has /e/?","options":["ten","turn"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"vet","word2":"verb","question":"Which has /e/?","options":["vet","verb"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"wed","word2":"word","question":"Which has /e/?","options":["wed","word"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"wet","word2":"worm","question":"Which has /e/?","options":["wet","worm"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"best","word2":"burst","question":"Which has /e/?","options":["best","burst"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"chest","word2":"church","question":"Which has /e/?","options":["chest","church"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"desk","word2":"dusk","question":"Which has /e/?","options":["desk","dusk"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"fell","word2":"furl","question":"Which has /e/?","options":["fell","furl"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"held","word2":"hurled","question":"Which has /e/?","options":["held","hurled"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"help","word2":"herb","question":"Which has /e/?","options":["help","herb"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"jest","word2":"germ","question":"Which has /e/?","options":["jest","germ"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"left","word2":"learn","question":"Which has /e/?","options":["left","learn"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"lent","word2":"learnt","question":"Which has /e/?","options":["lent","learnt"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"melt","word2":"myrrh","question":"Which has /e/?","options":["melt","myrrh"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"rent","word2":"wren","question":"Which has /e/?","options":["rent","wren"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"rest","word2":"rust","question":"Which has /e/?","options":["rest","rust"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sent","word2":"surf","question":"Which has /e/?","options":["sent","surf"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"step","word2":"stir","question":"Which has /e/?","options":["step","stir"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"test","word2":"thirst","question":"Which has /e/?","options":["test","thirst"],"correctAnswerIndex":0,"hint":"Short mid."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"book","word2":"buck","question":"Which has /ʊ/?","options":["book","buck"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"cook","word2":"cut","question":"Which has /ʊ/?","options":["cook","cut"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"foot","word2":"fun","question":"Which has /ʊ/?","options":["foot","fun"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"good","word2":"gun","question":"Which has /ʊ/?","options":["good","gun"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"hook","word2":"hut","question":"Which has /ʊ/?","options":["hook","hut"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"look","word2":"luck","question":"Which has /ʊ/?","options":["look","luck"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pull","word2":"pulse","question":"Which has /ʊ/?","options":["pull","pulse"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"push","word2":"pus","question":"Which has /ʊ/?","options":["push","pus"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"put","word2":"putt","question":"Which has /ʊ/?","options":["put","putt"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"wood","word2":"won","question":"Which has /ʊ/?","options":["wood","won"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"brook","word2":"brunt","question":"Which has /ʊ/?","options":["brook","brunt"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"crook","word2":"crush","question":"Which has /ʊ/?","options":["crook","crush"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"shook","word2":"shut","question":"Which has /ʊ/?","options":["shook","shut"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"stood","word2":"stud","question":"Which has /ʊ/?","options":["stood","stud"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"took","word2":"tuck","question":"Which has /ʊ/?","options":["took","tuck"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"wool","word2":"hull","question":"Which has /ʊ/?","options":["wool","hull"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bull","word2":"bulk","question":"Which has /ʊ/?","options":["bull","bulk"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bush","word2":"bus","question":"Which has /ʊ/?","options":["bush","bus"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"full","word2":"fuss","question":"Which has /ʊ/?","options":["full","fuss"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"soot","word2":"sun","question":"Which has /ʊ/?","options":["soot","sun"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"nook","word2":"nut","question":"Which has /ʊ/?","options":["nook","nut"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"rook","word2":"rut","question":"Which has /ʊ/?","options":["rook","rut"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"should","word2":"shut","question":"Which has /ʊ/?","options":["should","shut"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"would","word2":"wud","question":"Which has /ʊ/?","options":["would","wud"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"could","word2":"cud","question":"Which has /ʊ/?","options":["could","cud"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"hood","word2":"hud","question":"Which has /ʊ/?","options":["hood","hud"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"woof","word2":"wuff","question":"Which has /ʊ/?","options":["woof","wuff"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"brook","word2":"bruk","question":"Which has /ʊ/?","options":["brook","bruk"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"goods","word2":"guts","question":"Which has /ʊ/?","options":["goods","guts"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"hooks","word2":"huts","question":"Which has /ʊ/?","options":["hooks","huts"],"correctAnswerIndex":0,"hint":"Short close back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"born","word2":"burn","question":"Which has /ɔː/?","options":["born","burn"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"corn","word2":"curl","question":"Which has /ɔː/?","options":["corn","curl"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"cord","word2":"curd","question":"Which has /ɔː/?","options":["cord","curd"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"door","word2":"durr","question":"Which has /ɔː/?","options":["door","durr"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"floor","word2":"fur","question":"Which has /ɔː/?","options":["floor","fur"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"force","word2":"first","question":"Which has /ɔː/?","options":["force","first"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"form","word2":"firm","question":"Which has /ɔː/?","options":["form","firm"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"fort","word2":"furt","question":"Which has /ɔː/?","options":["fort","furt"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"horse","word2":"hearse","question":"Which has /ɔː/?","options":["horse","hearse"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"lord","word2":"lured","question":"Which has /ɔː/?","options":["lord","lured"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"more","word2":"myrrh","question":"Which has /ɔː/?","options":["more","myrrh"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"north","word2":"nurse","question":"Which has /ɔː/?","options":["north","nurse"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pour","word2":"purr","question":"Which has /ɔː/?","options":["pour","purr"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"short","word2":"shirt","question":"Which has /ɔː/?","options":["short","shirt"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"snore","word2":"stir","question":"Which has /ɔː/?","options":["snore","stir"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sort","word2":"surf","question":"Which has /ɔː/?","options":["sort","surf"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sport","word2":"spurt","question":"Which has /ɔː/?","options":["sport","spurt"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"store","word2":"stir","question":"Which has /ɔː/?","options":["store","stir"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sworn","word2":"swirl","question":"Which has /ɔː/?","options":["sworn","swirl"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"thorn","word2":"turn","question":"Which has /ɔː/?","options":["thorn","turn"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"torch","word2":"church","question":"Which has /ɔː/?","options":["torch","church"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"torn","word2":"term","question":"Which has /ɔː/?","options":["torn","term"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"warm","word2":"worm","question":"Which has /ɔː/?","options":["warm","worm"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"warn","word2":"wren","question":"Which has /ɔː/?","options":["warn","wren"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"worn","word2":"wurn","question":"Which has /ɔː/?","options":["worn","wurn"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"board","word2":"bird","question":"Which has /ɔː/?","options":["board","bird"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bore","word2":"blur","question":"Which has /ɔː/?","options":["bore","blur"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"core","word2":"cur","question":"Which has /ɔː/?","options":["core","cur"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"gore","word2":"girl","question":"Which has /ɔː/?","options":["gore","girl"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"shore","word2":"sure","question":"Which has /ɔː/?","options":["shore","sure"],"correctAnswerIndex":0,"hint":"Rounded back."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"beer","word2":"boor","question":"Which has /ɪə/?","options":["beer","boor"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"dear","word2":"dour","question":"Which has /ɪə/?","options":["dear","dour"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"fear","word2":"four","question":"Which has /ɪə/?","options":["fear","four"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"gear","word2":"gourd","question":"Which has /ɪə/?","options":["gear","gourd"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"here","word2":"hoor","question":"Which has /ɪə/?","options":["here","hoor"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"leer","word2":"lure","question":"Which has /ɪə/?","options":["leer","lure"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"mere","word2":"moor","question":"Which has /ɪə/?","options":["mere","moor"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"near","word2":"newer","question":"Which has /ɪə/?","options":["near","newer"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"peer","word2":"poor","question":"Which has /ɪə/?","options":["peer","poor"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"rear","word2":"rural","question":"Which has /ɪə/?","options":["rear","rural"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"seer","word2":"sure","question":"Which has /ɪə/?","options":["seer","sure"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"steer","word2":"stour","question":"Which has /ɪə/?","options":["steer","stour"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"tear","word2":"tour","question":"Which has /ɪə/?","options":["tear","tour"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"veer","word2":"viewer","question":"Which has /ɪə/?","options":["veer","viewer"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"year","word2":"your","question":"Which has /ɪə/?","options":["year","your"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"cheer","word2":"church","question":"Which has /ɪə/?","options":["cheer","church"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"clear","word2":"cure","question":"Which has /ɪə/?","options":["clear","cure"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sheer","word2":"sure","question":"Which has /ɪə/?","options":["sheer","sure"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"steer","word2":"stir","question":"Which has /ɪə/?","options":["steer","stir"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sneer","word2":"snoer","question":"Which has /ɪə/?","options":["sneer","snoer"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"career","word2":"cure","question":"Which has /ɪə/?","options":["career","cure"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"appear","word2":"pure","question":"Which has /ɪə/?","options":["appear","pure"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sincere","word2":"secure","question":"Which has /ɪə/?","options":["sincere","secure"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"severe","word2":"sewer","question":"Which has /ɪə/?","options":["severe","sewer"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"austere","word2":"assure","question":"Which has /ɪə/?","options":["austere","assure"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"frontier","word2":"furniture","question":"Which has /ɪə/?","options":["frontier","furniture"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pioneer","word2":"poor","question":"Which has /ɪə/?","options":["pioneer","poor"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"volunteer","word2":"voyeur","question":"Which has /ɪə/?","options":["volunteer","voyeur"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"engineer","word2":"ensure","question":"Which has /ɪə/?","options":["engineer","ensure"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"premier","word2":"pure","question":"Which has /ɪə/?","options":["premier","pure"],"correctAnswerIndex":0,"hint":"Near vowel."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"base","word2":"bounce","question":"Which has /eɪ/?","options":["base","bounce"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"cake","word2":"couch","question":"Which has /eɪ/?","options":["cake","couch"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"face","word2":"foul","question":"Which has /eɪ/?","options":["face","foul"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"gate","word2":"gout","question":"Which has /eɪ/?","options":["gate","gout"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"hate","word2":"house","question":"Which has /eɪ/?","options":["hate","house"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"lake","word2":"loud","question":"Which has /eɪ/?","options":["lake","loud"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"made","word2":"mouth","question":"Which has /eɪ/?","options":["made","mouth"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"name","word2":"noun","question":"Which has /eɪ/?","options":["name","noun"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pace","word2":"pout","question":"Which has /eɪ/?","options":["pace","pout"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"race","word2":"round","question":"Which has /eɪ/?","options":["race","round"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"safe","word2":"south","question":"Which has /eɪ/?","options":["safe","south"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"take","word2":"town","question":"Which has /eɪ/?","options":["take","town"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"vane","word2":"vow","question":"Which has /eɪ/?","options":["vane","vow"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"wade","word2":"wow","question":"Which has /eɪ/?","options":["wade","wow"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"cake","word2":"cow","question":"Which has /eɪ/?","options":["cake","cow"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bake","word2":"bow","question":"Which has /eɪ/?","options":["bake","bow"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"date","word2":"doubt","question":"Which has /eɪ/?","options":["date","doubt"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"fake","word2":"foul","question":"Which has /eɪ/?","options":["fake","foul"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"gaze","word2":"gown","question":"Which has /eɪ/?","options":["gaze","gown"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"haze","word2":"howl","question":"Which has /eɪ/?","options":["haze","howl"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"lace","word2":"louse","question":"Which has /eɪ/?","options":["lace","louse"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"maid","word2":"mount","question":"Which has /eɪ/?","options":["maid","mount"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"nail","word2":"now","question":"Which has /eɪ/?","options":["nail","now"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"paid","word2":"pound","question":"Which has /eɪ/?","options":["paid","pound"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"raid","word2":"round","question":"Which has /eɪ/?","options":["raid","round"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sage","word2":"south","question":"Which has /eɪ/?","options":["sage","south"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"tail","word2":"towel","question":"Which has /eɪ/?","options":["tail","towel"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"wave","word2":"wound","question":"Which has /eɪ/?","options":["wave","wound"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"crane","word2":"crowd","question":"Which has /eɪ/?","options":["crane","crowd"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"stale","word2":"stout","question":"Which has /eɪ/?","options":["stale","stout"],"correctAnswerIndex":0,"hint":"Front diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"beard","word2":"bared","question":"Which has /ɪə/?","options":["beard","bared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"cleared","word2":"clared","question":"Which has /ɪə/?","options":["cleared","clared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"feared","word2":"fared","question":"Which has /ɪə/?","options":["feared","fared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"neared","word2":"snared","question":"Which has /ɪə/?","options":["neared","snared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"peered","word2":"paired","question":"Which has /ɪə/?","options":["peered","paired"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"reared","word2":"rarely","question":"Which has /ɪə/?","options":["reared","rarely"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"seared","word2":"shared","question":"Which has /ɪə/?","options":["seared","shared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"steered","word2":"stared","question":"Which has /ɪə/?","options":["steered","stared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"veered","word2":"varied","question":"Which has /ɪə/?","options":["veered","varied"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"cheered","word2":"chaired","question":"Which has /ɪə/?","options":["cheered","chaired"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"geared","word2":"glared","question":"Which has /ɪə/?","options":["geared","glared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"jeered","word2":"jarred","question":"Which has /ɪə/?","options":["jeered","jarred"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"leered","word2":"laird","question":"Which has /ɪə/?","options":["leered","laird"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"queered","word2":"squared","question":"Which has /ɪə/?","options":["queered","squared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"sneered","word2":"spared","question":"Which has /ɪə/?","options":["sneered","spared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"tiered","word2":"teared","question":"Which has /ɪə/?","options":["tiered","teared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"weird","word2":"warred","question":"Which has /ɪə/?","options":["weird","warred"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"appeared","word2":"appaired","question":"Which has /ɪə/?","options":["appeared","appaired"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"endeared","word2":"endured","question":"Which has /ɪə/?","options":["endeared","endured"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pioneered","word2":"prepared","question":"Which has /ɪə/?","options":["pioneered","prepared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"adhered","word2":"affair","question":"Which has /ɪə/?","options":["adhered","affair"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"cashiered","word2":"compared","question":"Which has /ɪə/?","options":["cashiered","compared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"interfered","word2":"impaired","question":"Which has /ɪə/?","options":["interfered","impaired"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"persevered","word2":"repaired","question":"Which has /ɪə/?","options":["persevered","repaired"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"volunteered","word2":"declared","question":"Which has /ɪə/?","options":["volunteered","declared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"premiered","word2":"prepared","question":"Which has /ɪə/?","options":["premiered","prepared"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"profiteered","word2":"preferred","question":"Which has /ɪə/?","options":["profiteered","preferred"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"racketeered","word2":"remembered","question":"Which has /ɪə/?","options":["racketeered","remembered"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"commandeered","word2":"conferred","question":"Which has /ɪə/?","options":["commandeered","conferred"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"engineered","word2":"ensured","question":"Which has /ɪə/?","options":["engineered","ensured"],"correctAnswerIndex":0,"hint":"Close diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"boat","word2":"boot","question":"Which has /oʊ/?","options":["boat","boot"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"coat","word2":"cool","question":"Which has /oʊ/?","options":["coat","cool"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"go","word2":"goo","question":"Which has /oʊ/?","options":["go","goo"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"home","word2":"hoop","question":"Which has /oʊ/?","options":["home","hoop"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"hope","word2":"hoot","question":"Which has /oʊ/?","options":["hope","hoot"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"joke","word2":"juice","question":"Which has /oʊ/?","options":["joke","juice"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"lone","word2":"loom","question":"Which has /oʊ/?","options":["lone","loom"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"moan","word2":"moon","question":"Which has /oʊ/?","options":["moan","moon"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"note","word2":"noon","question":"Which has /oʊ/?","options":["note","noon"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"pole","word2":"pool","question":"Which has /oʊ/?","options":["pole","pool"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"road","word2":"rude","question":"Which has /oʊ/?","options":["road","rude"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"rode","word2":"rood","question":"Which has /oʊ/?","options":["rode","rood"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"role","word2":"rule","question":"Which has /oʊ/?","options":["role","rule"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"rose","word2":"ruse","question":"Which has /oʊ/?","options":["rose","ruse"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"show","word2":"shoe","question":"Which has /oʊ/?","options":["show","shoe"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"slow","word2":"slew","question":"Which has /oʊ/?","options":["slow","slew"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"snow","word2":"snooze","question":"Which has /oʊ/?","options":["snow","snooze"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"so","word2":"sue","question":"Which has /oʊ/?","options":["so","sue"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"soap","word2":"soup","question":"Which has /oʊ/?","options":["soap","soup"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"stole","word2":"stool","question":"Which has /oʊ/?","options":["stole","stool"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"stone","word2":"stoon","question":"Which has /oʊ/?","options":["stone","stoon"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"those","word2":"tooth","question":"Which has /oʊ/?","options":["those","tooth"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"toast","word2":"tool","question":"Which has /oʊ/?","options":["toast","tool"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"toe","word2":"too","question":"Which has /oʊ/?","options":["toe","too"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"tone","word2":"tune","question":"Which has /oʊ/?","options":["tone","tune"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"vote","word2":"voodoo","question":"Which has /oʊ/?","options":["vote","voodoo"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"woke","word2":"woo","question":"Which has /oʊ/?","options":["woke","woo"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"zone","word2":"zoom","question":"Which has /oʊ/?","options":["zone","zoom"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"bone","word2":"boon","question":"Which has /oʊ/?","options":["bone","boon"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
  pool.push({"instruction":"Identify the vowel sound.","fields":{"word1":"dose","word2":"dune","question":"Which has /oʊ/?","options":["dose","dune"],"correctAnswerIndex":0,"hint":"Mid diphthong."}});
console.log(`  vowelDistinction pool: ${pool.length}`);
  pool.forEach(q => { if(!q.fields.ipa1) q.fields.ipa1 = getIpa(q.fields.word1); if(!q.fields.ipa2) q.fields.ipa2 = getIpa(q.fields.word2); });
  return pool;
};
