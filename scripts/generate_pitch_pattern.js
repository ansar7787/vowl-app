const fs = require('fs');
const path = require('path');

const curriculumDir = path.join(__dirname, '..', 'assets', 'curriculum', 'accent');

// Sentence pools mapping pitch patterns to arrays of sentences
const pools = {
  'Rising ↗': [
    'Are you coming?', 'Is it raining?', 'Do you like coffee?', 'Can you help me?',
    'Should we leave now?', 'Will it work?', 'Did you see that?', 'Are they ready?',
    'Have you finished?', 'Is this yours?', 'May I come in?', 'Would you mind?',
    'Could she do it?', 'Does he know?', 'Are we there yet?', 'Has it started?',
    'Do they understand?', 'Is she asleep?', 'Can he drive?', 'Will you join us?',
    'Are you sure?', 'Is that true?', 'Do we have time?', 'Can they see us?',
    'Should I wait?', 'Will she be late?', 'Did he call?', 'Are you okay?',
    'Have we met?', 'Is it possible?'
  ],
  'Falling ↘': [
    'I finished the report.', 'She is coming home.', 'They won the game.', 'It is raining outside.',
    'He bought a new car.', 'We are going to sleep.', 'The book is on the table.', 'I like apples.',
    'She sings beautifully.', 'He runs fast.', 'They walked to the park.', 'I need some rest.',
    'The sky is blue.', 'She read a novel.', 'He wrote a letter.', 'We ate dinner.',
    'The dog is barking.', 'I saw a movie.', 'She opened the window.', 'He closed the door.',
    'They painted the wall.', 'I found my keys.', 'She lost her phone.', 'He fixed the bike.',
    'We watched TV.', 'The sun is shining.', 'I drank water.', 'She cooked lunch.',
    'He drove carefully.', 'They left early.'
  ],
  'Flat →': [
    'I don\\'t know.', 'Whatever you say.', 'It doesn\\'t matter.', 'I suppose so.',
    'Maybe later.', 'If you want.', 'I guess it\\'s fine.', 'We will see.',
    'Just leave it there.', 'Nothing special.', 'As you wish.', 'It is what it is.',
    'Let it be.', 'Who cares.', 'Same old story.', 'Just another day.',
    'Not really sure.', 'Either way is fine.', 'Takes time.', 'In a minute.',
    'Just around the corner.', 'Somewhere out there.', 'Now and then.', 'Off and on.',
    'Back and forth.', 'Here and there.', 'More or less.', 'So so.',
    'Kind of.', 'Sort of.'
  ],
  'Rise-fall ↗↘': [
    'That was amazing!', 'What a surprise!', 'I can\\'t believe it!', 'How wonderful!',
    'That is absolutely incredible!', 'You did a great job!', 'What a fantastic idea!', 'I am so happy for you!',
    'That hurts!', 'Watch out!', 'Stop doing that!', 'How dare you!',
    'What a beautiful day!', 'This is the best!', 'I am completely shocked!', 'That is so funny!',
    'You are kidding me!', 'What a relief!', 'That is a disaster!', 'I am so excited!',
    'How terrifying!', 'That is brilliant!', 'What a mess!', 'I am incredibly tired!',
    'That is outrageous!', 'What a tragedy!', 'I am so proud!', 'That is fabulous!',
    'How interesting!', 'That is unbelievable!'
  ]
};

const hints = {
  'Rising ↗': 'Questions usually end with a rising pitch.',
  'Falling ↘': 'Statements usually end with a falling pitch.',
  'Flat →': 'Neutral or uncertain phrases often have a flat pitch.',
  'Rise-fall ↗↘': 'Excitement or strong emotion often rises then falls.'
};

const options = ['Rising ↗', 'Falling ↘', 'Flat →', 'Rise-fall ↗↘'];

// Helper to get random item from array
function getRandomItem(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function generatePitchPatternMatchFiles() {
  const numFiles = 20;
  const questionsPerFile = 30; // 600 total / 20 files
  
  for (let fileNum = 1; fileNum <= numFiles; fileNum++) {
    const quests = [];
    
    for (let i = 1; i <= questionsPerFile; i++) {
      // Determine correct answer pattern randomly
      const correctIndex = Math.floor(Math.random() * options.length);
      const correctPatternLabel = options[correctIndex];
      
      const sentence = getRandomItem(pools[correctPatternLabel]);
      const hint = hints[correctPatternLabel];
      
      const diff = Math.ceil(i / 3);
      
      const q = {
        id: `pitchPatternMatch_b${fileNum}_q${i}`,
        instruction: 'Match the pitch pattern.',
        difficulty: diff > 10 ? 10 : diff,
        subtype: 'pitchPatternMatch',
        interactionType: 'choice',
        textToSpeak: sentence,
        pitchPattern: correctPatternLabel,
        options: options,
        correctAnswerIndex: correctIndex,
        hint: hint,
        xpReward: 5,
        coinReward: 10
      };
      quests.push(q);
    }
    
    const data = {
      gameType: 'pitchPatternMatch',
      batchIndex: fileNum,
      levels: '1-10',
      quests: quests
    };
    
    const fileName = fileNum === 1 ? 'pitchPatternMatch_1_10.json' : `pitchPatternMatch_1_10_b${fileNum}.json`;
    const filePath = path.join(curriculumDir, fileName);
    
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
    console.log(`Generated ${fileName}`);
  }
}

// Clean old files first
const files = fs.readdirSync(curriculumDir).filter(f => f.startsWith('pitchPatternMatch_'));
for (const file of files) {
   fs.unlinkSync(path.join(curriculumDir, file));
}

generatePitchPatternMatchFiles();
