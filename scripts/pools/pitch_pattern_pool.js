// Pitch Pattern Match: 600 unique phrases for pitch pattern identification
const getIpa = require(__dirname + '/get_ipa.js');
module.exports = function() {
  const pool = [];
  const subjects = ['I','You','She','He','We','They','Tom','Mary','The cat','The dog','My friend','Our team','The children','Her mother','His father','The teacher','A student','The doctor','The pilot','A stranger','My sister','Your brother','The baby','An artist','The mayor','A worker','The captain','My cousin','Her uncle','The winner'];
  const midVerbs = ['really','always','never','often','sometimes','usually','already','finally','quickly','slowly','carefully','happily','quietly','proudly','gently','eagerly','bravely','calmly','clearly','simply'];
  const actions = [
    'loves chocolate cake','wants a new car','reads every morning','plays the piano','sings in the shower',
    'runs through the park','writes beautiful poems','cooks Italian food','draws lovely pictures','dances at parties',
    'studies every night','works very hard','sleeps until noon','talks on the phone','walks to school',
    'watches the sunset','listens to music','eats fresh fruit','drinks green tea','builds model planes',
    'climbs tall mountains','swims in the ocean','flies across the world','drives to the coast','paints watercolors',
    'teaches young children','fixes old machines','grows organic food','sells handmade crafts','keeps tropical fish',
  ];
  const patterns = [
    {name:'Statement ↘',opt:['Falling ↘','Rising ↗'],ans:0,hint:'Statements fall at the end.'},
    {name:'Yes/No question ↗',opt:['Rising ↗','Falling ↘'],ans:0,hint:'Yes/no questions rise.'},
    {name:'Wh-question ↘',opt:['Falling ↘','Rising ↗'],ans:0,hint:'Wh-questions fall.'},
  ];
  let idx = 0;
  for (const subj of subjects) {
    for (const adv of midVerbs) {
      const act = actions[idx % actions.length];
      const pat = patterns[idx % patterns.length];
      let text;
      if (pat.name.startsWith('Yes/No')) text = `Does ${subj.toLowerCase()} ${adv} ${act}?`;
      else if (pat.name.startsWith('Wh')) text = `Why does ${subj.toLowerCase()} ${adv} ${act}?`;
      else text = `${subj} ${adv} ${act}.`;
      pool.push({
        instruction: 'Match the pitch pattern.',
        fields: { textToSpeak: text, options: pat.opt, correctAnswerIndex: pat.ans, hint: pat.hint, pitchPattern: pat.name, phoneticHint: getIpa(text) }
      });
      idx++;
      if (pool.length >= 600) break;
    }
    if (pool.length >= 600) break;
  }
  console.log(`  pitchPatternMatch pool: ${pool.length}`);
  return pool;
};

