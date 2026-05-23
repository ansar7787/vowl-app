const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, '..', 'assets', 'curriculum', 'kids');

// Define beautiful painters for kids variety
const kidsPainters = [
  "KidsWorldBackground",
  "KidsSafariBackground",
  "KidsGalaxyBackground",
  "KidsCandyBackground",
  "KidsOceanBackground",
  "KidsForestBackground"
];

// Helper to get random item
function getRandomItem(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

// Distractors generator
function getDistractors(correct, pool, count = 2) {
  const filtered = pool.filter(x => x.toLowerCase() !== correct.toLowerCase());
  const shuffled = [...filtered].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count);
}

// 22 unique generators for Kids Category
const generators = {
  alphabet: (level, qIdx) => {
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("");
    const index = (level * 3 + qIdx) % letters.length;
    const isUpper = (level % 2 === 0);
    const letter = letters[index];
    const displayLetter = isUpper ? letter : letter.toLowerCase();
    const alphabetPool = letters.map(l => isUpper ? l : l.toLowerCase());
    
    const distractors = getDistractors(displayLetter, alphabetPool, 2);
    const options = [displayLetter, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Find the ${isUpper ? 'uppercase' : 'lowercase'} letter ${displayLetter}!`,
      question: displayLetter,
      correctAnswer: displayLetter,
      options: options,
      hint: `It looks like the letter ${displayLetter.toUpperCase()}.`
    };
  },

  animals: (level, qIdx) => {
    const animalData = [
      { name: "Dog", sound: "Woof Woof", desc: "keeps your home safe" },
      { name: "Cat", sound: "Meow", desc: "loves to chase mice" },
      { name: "Cow", sound: "Moo", desc: "gives us fresh milk" },
      { name: "Sheep", sound: "Baa", desc: "gives us warm wool" },
      { name: "Lion", sound: "Roar", desc: "is the king of the jungle" },
      { name: "Duck", sound: "Quack", desc: "loves swimming in the pond" },
      { name: "Elephant", sound: "Trumpet", desc: "has a very long trunk" },
      { name: "Monkey", sound: "Chatter", desc: "loves to climb and eat bananas" },
      { name: "Frog", sound: "Ribbit", desc: "jumps high near the water" },
      { name: "Rooster", sound: "Cock-a-doodle-doo", desc: "wakes us up in the morning" }
    ];
    const index = (level * 3 + qIdx) % animalData.length;
    const animal = animalData[index];
    const animalPool = animalData.map(a => a.name);
    
    const distractors = getDistractors(animal.name, animalPool, 2);
    const options = [animal.name, ...distractors].sort(() => 0.5 - Math.random());
    
    const type = qIdx % 2 === 0;
    return {
      instruction: type ? `Which animal says "${animal.sound}"?` : `Which animal ${animal.desc}?`,
      question: type ? animal.sound : animal.name,
      correctAnswer: animal.name,
      options: options,
      hint: `This is a friendly ${animal.name.toLowerCase()}!`
    };
  },

  body_parts: (level, qIdx) => {
    const parts = [
      { name: "Eyes", action: "see colorful flowers" },
      { name: "Ears", action: "hear birds singing" },
      { name: "Nose", action: "smell tasty cookies" },
      { name: "Mouth", action: "taste delicious ice cream" },
      { name: "Hands", action: "clap and hold toys" },
      { name: "Feet", action: "run and kick a soccer ball" }
    ];
    const index = (level * 3 + qIdx) % parts.length;
    const part = parts[index];
    const partPool = parts.map(p => p.name);
    
    const distractors = getDistractors(part.name, partPool, 2);
    const options = [part.name, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Touch the body part we use to ${part.action}!`,
      question: part.name,
      correctAnswer: part.name,
      options: options,
      hint: `We use our ${part.name.toLowerCase()} for this!`
    };
  },

  clothing: (level, qIdx) => {
    const clothes = [
      { name: "Hat", part: "head on a sunny day" },
      { name: "Socks", part: "feet under our shoes" },
      { name: "Gloves", part: "hands when it is cold" },
      { name: "Shoes", part: "feet when we walk outside" },
      { name: "Scarf", part: "neck to keep cozy and warm" },
      { name: "Jacket", part: "body to protect from chilly wind" }
    ];
    const index = (level * 3 + qIdx) % clothes.length;
    const item = clothes[index];
    const clothingPool = clothes.map(c => c.name);
    
    const distractors = getDistractors(item.name, clothingPool, 2);
    const options = [item.name, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `What item do we wear on our ${item.part}?`,
      question: item.name,
      correctAnswer: item.name,
      options: options,
      hint: `Choose the ${item.name.toLowerCase()} for protection.`
    };
  },

  colors: (level, qIdx) => {
    const colorData = [
      { color: "Red", item: "ripe strawberries" },
      { color: "Yellow", item: "sweet bananas" },
      { color: "Blue", item: "the clear summer sky" },
      { color: "Green", item: "fresh grass in the park" },
      { color: "Orange", item: "juicy orange fruits" },
      { color: "Purple", item: "sweet juicy grapes" },
      { color: "Pink", item: "beautiful rose flowers" }
    ];
    const index = (level * 3 + qIdx) % colorData.length;
    const item = colorData[index];
    const colorPool = colorData.map(c => c.color);
    
    const distractors = getDistractors(item.color, colorPool, 2);
    const options = [item.color, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `What color is ${item.item}?`,
      question: item.color,
      correctAnswer: item.color,
      options: options,
      hint: `It looks like bright ${item.color.toLowerCase()}!`
    };
  },

  day_night: (level, qIdx) => {
    const times = [
      { item: "Sun shining brightly", answer: "Daytime" },
      { item: "Stars twinkling in the sky", answer: "Nighttime" },
      { item: "Sleeping cozy in our beds", answer: "Nighttime" },
      { item: "Going to school with our teacher", answer: "Daytime" },
      { item: "Eating yummy breakfast", answer: "Daytime" },
      { item: "Seeing the big white moon", answer: "Nighttime" }
    ];
    const index = (level * 3 + qIdx) % times.length;
    const element = times[index];
    const timePool = ["Daytime", "Nighttime"];
    
    const options = [...timePool];
    
    return {
      instruction: `When do we see or do this: "${element.item}"?`,
      question: element.item,
      correctAnswer: element.answer,
      options: options,
      hint: `Think if this happens when it is bright or dark outside.`
    };
  },

  emotions: (level, qIdx) => {
    const moods = [
      { emotion: "Happy", clue: "we smile and laugh out loud" },
      { emotion: "Sad", clue: "we have tears when we are hurt" },
      { emotion: "Scared", clue: "we hear a loud sound in the dark" },
      { emotion: "Excited", clue: "we are going to the amusement park" },
      { emotion: "Angry", clue: "things do not go our way" }
    ];
    const index = (level * 3 + qIdx) % moods.length;
    const item = moods[index];
    const emotionPool = moods.map(m => m.emotion);
    
    const distractors = getDistractors(item.emotion, emotionPool, 2);
    const options = [item.emotion, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Which emotion do we feel when ${item.clue}?`,
      question: item.emotion,
      correctAnswer: item.emotion,
      options: options,
      hint: `This is a feeling of being ${item.emotion.toLowerCase()}.`
    };
  },

  family: (level, qIdx) => {
    const members = [
      { role: "Mother", desc: "loves to hug you and cooks yummy meals" },
      { role: "Father", desc: "plays outdoor games and protects the family" },
      { role: "Grandfather", desc: "tells beautiful stories from long ago" },
      { role: "Grandmother", desc: "bakes delicious pies with love" },
      { role: "Brother", desc: "shares his toy cars and runs with you" },
      { role: "Sister", desc: "helps you color drawings and laughs together" }
    ];
    const index = (level * 3 + qIdx) % members.length;
    const item = members[index];
    const memberPool = members.map(m => m.role);
    
    const distractors = getDistractors(item.role, memberPool, 2);
    const options = [item.role, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Identify the family member who ${item.desc}!`,
      question: item.role,
      correctAnswer: item.role,
      options: options,
      hint: `Choose ${item.role.toLowerCase()} from the options.`
    };
  },

  food_kids: (level, qIdx) => {
    const items = [
      { name: "Pizza", desc: "flat round bread with melted cheese" },
      { name: "Ice Cream", desc: "cold sweet dessert in a cone" },
      { name: "Soup", desc: "warm healthy liquid bowl when cold" },
      { name: "Bread", desc: "soft slice used to make sandwiches" },
      { name: "Cake", desc: "sweet baked dessert with candles for birthdays" }
    ];
    const index = (level * 3 + qIdx) % items.length;
    const item = items[index];
    const foodPool = items.map(f => f.name);
    
    const distractors = getDistractors(item.name, foodPool, 2);
    const options = [item.name, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Which delicious food is a ${item.desc}?`,
      question: item.name,
      correctAnswer: item.name,
      options: options,
      hint: `It tastes like delicious ${item.name.toLowerCase()}!`
    };
  },

  fruits: (level, qIdx) => {
    const fruits = [
      { name: "Apple", clue: "sweet red round fruit growing on trees" },
      { name: "Banana", clue: "long yellow fruit monkeys love to peel" },
      { name: "Orange", clue: "round juicy citrus fruit named after its color" },
      { name: "Lemon", clue: "sour yellow fruit we squeeze to make lemonade" },
      { name: "Grapes", clue: "small round sweet berries growing in bunches" }
    ];
    const index = (level * 3 + qIdx) % fruits.length;
    const item = fruits[index];
    const fruitPool = fruits.map(f => f.name);
    
    const distractors = getDistractors(item.name, fruitPool, 2);
    const options = [item.name, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Identify the fruit that is a ${item.clue}!`,
      question: item.name,
      correctAnswer: item.name,
      options: options,
      hint: `Choose ${item.name.toLowerCase()} for the answer.`
    };
  },

  home_kids: (level, qIdx) => {
    const rooms = [
      { room: "Bedroom", item: "comfortable bed to sleep cozy at night" },
      { room: "Kitchen", item: "hot stove and oven where mom cooks dinners" },
      { room: "Bathroom", item: "clean shower and sink to brush your teeth" },
      { room: "Living Room", item: "soft sofa and TV where the family watches shows" }
    ];
    const index = (level * 3 + qIdx) % rooms.length;
    const item = rooms[index];
    const roomPool = rooms.map(r => r.room);
    
    const distractors = getDistractors(item.room, roomPool, 2);
    const options = [item.room, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `In which room do we find the ${item.item}?`,
      question: item.room,
      correctAnswer: item.room,
      options: options,
      hint: `This is the ${item.room.toLowerCase()} in your home.`
    };
  },

  nature: (level, qIdx) => {
    const items = [
      { name: "Tree", desc: "tall green plant with thick wooden trunk and branches" },
      { name: "Flower", desc: "beautiful sweet-smelling colorful plant with petals" },
      { name: "Cloud", desc: "fluffy white cotton shape floating in the blue sky" },
      { name: "River", desc: "flowing stream of cool fresh water carrying fish" },
      { name: "Mountain", desc: "giant rocky peak reaching high above the clouds" }
    ];
    const index = (level * 3 + qIdx) % items.length;
    const item = items[index];
    const naturePool = items.map(n => n.name);
    
    const distractors = getDistractors(item.name, naturePool, 2);
    const options = [item.name, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Identify the nature element that is a ${item.desc}!`,
      question: item.name,
      correctAnswer: item.name,
      options: options,
      hint: `Choose ${item.name.toLowerCase()} from the green nature elements.`
    };
  },

  numbers: (level, qIdx) => {
    // Dynamic math matching for children
    const number = (level + qIdx) % 15 + 1;
    const englishWords = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen"];
    const word = englishWords[number - 1];
    
    const optionNumbers = [number.toString(), ...getDistractors(number.toString(), Array.from({length: 16}, (_, i) => (i + 1).toString()), 2)];
    const options = optionNumbers.sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Touch the number digit matching: "${word}"!`,
      question: word,
      correctAnswer: number.toString(),
      options: options,
      hint: `Count the items up to ${number}.`
    };
  },

  opposites: (level, qIdx) => {
    const pairs = [
      { word: "Hot", opposite: "Cold", clue: "sun or burning steam vs cold ice cream" },
      { word: "Big", opposite: "Small", clue: "huge elephant vs tiny busy ant" },
      { word: "Tall", opposite: "Short", clue: "high giraffe vs tiny sweet mouse" },
      { word: "Fast", opposite: "Slow", clue: "quick racing cheetah vs slow crawling turtle" },
      { word: "Up", opposite: "Down", clue: "climbing high sky vs descending ground levels" }
    ];
    const index = (level * 3 + qIdx) % pairs.length;
    const pair = pairs[index];
    const oppositePool = pairs.map(p => p.opposite);
    
    const distractors = getDistractors(pair.opposite, oppositePool, 2);
    const options = [pair.opposite, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `What is the opposite of "${pair.word}"? (${pair.clue})`,
      question: pair.word,
      correctAnswer: pair.opposite,
      options: options,
      hint: `The correct opposite is ${pair.opposite.toLowerCase()}.`
    };
  },

  phonics: (level, qIdx) => {
    const pairs = [
      { letter: "B", sound: "/b/ as in Ball", word: "Ball" },
      { letter: "C", sound: "/k/ as in Cat", word: "Cat" },
      { letter: "D", sound: "/d/ as in Dog", word: "Dog" },
      { letter: "F", sound: "/f/ as in Fish", word: "Fish" },
      { letter: "M", sound: "/m/ as in Monkey", word: "Monkey" }
    ];
    const index = (level * 3 + qIdx) % pairs.length;
    const pair = pairs[index];
    const letterPool = "BCDFGHJKLMNOPQRSTUVW".split("");
    
    const distractors = getDistractors(pair.letter, letterPool, 2);
    const options = [pair.letter, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Which letter makes the phonic sound: "${pair.sound}"?`,
      question: pair.sound,
      correctAnswer: pair.letter,
      options: options,
      hint: `This is the starting letter of the word "${pair.word}".`
    };
  },

  prepositions: (level, qIdx) => {
    const preps = [
      { name: "On", desc: "sitting active right on top of a comfortable chair" },
      { name: "Under", desc: "hidden safely beneath a wooden table out of sight" },
      { name: "In", desc: "nestled cozy inside a colorful toy chest basket" },
      { name: "Behind", desc: "hidden directly back of a flowery window curtain" }
    ];
    const index = (level * 3 + qIdx) % preps.length;
    const item = preps[index];
    const prepPool = preps.map(p => p.name);
    
    const distractors = getDistractors(item.name, prepPool, 2);
    const options = [item.name, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Where is the teddy bear if he is ${item.desc}?`,
      question: item.name,
      correctAnswer: item.name,
      options: options,
      hint: `Choose ${item.name.toLowerCase()} as the positional place.`
    };
  },

  routine: (level, qIdx) => {
    const tasks = [
      { name: "Brush Teeth", time: "Morning and Night to keep teeth white and clean" },
      { name: "Eat Breakfast", time: "Morning to get strong energy to study and play" },
      { name: "Wash Face", time: "Morning to wake up fresh and happy" },
      { name: "Go to Bed", time: "Night to sleep cozy and dream beautiful dreams" }
    ];
    const index = (level * 3 + qIdx) % tasks.length;
    const item = tasks[index];
    const taskPool = tasks.map(t => t.name);
    
    const distractors = getDistractors(item.name, taskPool, 2);
    const options = [item.name, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Which routine task is done during: "${item.time}"?`,
      question: item.name,
      correctAnswer: item.name,
      options: options,
      hint: `Politely select ${item.name.toLowerCase()} to complete.`
    };
  },

  school: (level, qIdx) => {
    const tools = [
      { name: "Pencil", use: "write words and draw beautiful houses" },
      { name: "Eraser", use: "rub out mistakes completely from our papers" },
      { name: "Ruler", use: "draw straight neat line margins on sheets" },
      { name: "Backpack", use: "carry our storybooks and lunchboxes safely" }
    ];
    const index = (level * 3 + qIdx) % tools.length;
    const item = tools[index];
    const toolPool = tools.map(t => t.name);
    
    const distractors = getDistractors(item.name, toolPool, 2);
    const options = [item.name, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Touch the classroom object we use to ${item.use}!`,
      question: item.name,
      correctAnswer: item.name,
      options: options,
      hint: `This is the classroom ${item.name.toLowerCase()}.`
    };
  },

  shapes: (level, qIdx) => {
    const shapes = [
      { shape: "Circle", item: "round wall clock or sweet round donut" },
      { shape: "Triangle", item: "slice of cheesy pizza or small clothes hanger" },
      { shape: "Rectangle", item: "flat entry door or wide classroom writing board" },
      { shape: "Square", item: "symmetrical window pane or cardboard gift box" }
    ];
    const index = (level * 3 + qIdx) % shapes.length;
    const item = shapes[index];
    const shapePool = shapes.map(s => s.shape);
    
    const distractors = getDistractors(item.shape, shapePool, 2);
    const options = [item.shape, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Touch the shape that matches a ${item.item}!`,
      question: item.shape,
      correctAnswer: item.shape,
      options: options,
      hint: `It looks like a perfect ${item.shape.toLowerCase()}!`
    };
  },

  time: (level, qIdx) => {
    const hours = [
      { hour: "8:00 AM", desc: "time to wake up and eat yummy breakfast" },
      { hour: "12:00 PM", desc: "noon time when we eat our lunch at school" },
      { hour: "4:00 PM", desc: "afternoon time to play in the green park" },
      { hour: "9:00 PM", desc: "nighttime when we sleep cozy in our warm beds" }
    ];
    const index = (level * 3 + qIdx) % hours.length;
    const item = hours[index];
    const hourPool = hours.map(h => h.hour);
    
    const distractors = getDistractors(item.hour, hourPool, 2);
    const options = [item.hour, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Which clock time matches: "${item.desc}"?`,
      question: item.hour,
      correctAnswer: item.hour,
      options: options,
      hint: `Select the correct hour: ${item.hour}.`
    };
  },

  transport: (level, qIdx) => {
    const vehicles = [
      { name: "Car", track: "road carrying families to the supermarket" },
      { name: "Train", track: "steel tracks click-clacking carrying hundreds" },
      { name: "Airplane", track: "sky flying high like a giant metal bird" },
      { name: "Boat", track: "cool blue lake floating with sails up" }
    ];
    const index = (level * 3 + qIdx) % vehicles.length;
    const item = vehicles[index];
    const vehiclePool = vehicles.map(v => v.name);
    
    const distractors = getDistractors(item.name, vehiclePool, 2);
    const options = [item.name, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `Which vehicle travels along the ${item.track}?`,
      question: item.name,
      correctAnswer: item.name,
      options: options,
      hint: `This transport is a ${item.name.toLowerCase()}.`
    };
  },

  verbs: (level, qIdx) => {
    const actions = [
      { name: "Run", desc: "moving our feet very quickly to chase a balloon" },
      { name: "Jump", desc: "springing high up in the air off the trampoline" },
      { name: "Sing", desc: "making beautiful happy musical voice songs" },
      { name: "Read", desc: "looking at words in a colorful storybook" },
      { name: "Dance", desc: "swaying and jumping happily to sweet melodies" }
    ];
    const index = (level * 3 + qIdx) % actions.length;
    const item = actions[index];
    const actionPool = actions.map(a => a.name);
    
    const distractors = getDistractors(item.name, actionPool, 2);
    const options = [item.name, ...distractors].sort(() => 0.5 - Math.random());
    
    return {
      instruction: `What is the action word for ${item.desc}?`,
      question: item.name,
      correctAnswer: item.name,
      options: options,
      hint: `The active verb is to ${item.name.toLowerCase()}.`
    };
  }
};

// Main generation loop
const allGameTypes = Object.keys(generators);

allGameTypes.forEach(gameType => {
  const gameTypeFolder = path.join(baseDir, gameType === "food_kids" ? "food_kids" : (gameType === "home_kids" ? "home_kids" : gameType));
  
  if (!fs.existsSync(gameTypeFolder)) {
    fs.mkdirSync(gameTypeFolder, { recursive: true });
  }

  // 20 batches of 10 levels each (covering 200 levels)
  for (let batchIdx = 1; batchIdx <= 20; batchIdx++) {
    const batchLevels = [];
    
    for (let l = 1; l <= 10; l++) {
      const level = (batchIdx - 1) * 10 + l;
      const quests = [];
      
      for (let qIdx = 0; qIdx < 3; qIdx++) {
        const questData = generators[gameType](level, qIdx);
        
        quests.push({
          id: `KIDS_${gameType.toUpperCase()}_L${level}_Q${qIdx + 1}`,
          gameType: gameType,
          level: level,
          instruction: questData.instruction,
          question: questData.question,
          correctAnswer: questData.correctAnswer,
          options: questData.options,
          imageUrl: "",
          audioUrl: "",
          painter: getRandomItem(kidsPainters),
          shader: "",
          hint: questData.hint,
          metadata: {
            difficulty: Math.ceil(level / 20),
            xpReward: 10,
            coinReward: 5
          }
        });
      }

      batchLevels.push({
        level: level,
        quests: quests
      });
    }

    const filePath = path.join(gameTypeFolder, `${gameType}_batch_${batchIdx}.json`);
    fs.writeFileSync(filePath, JSON.stringify(batchLevels, null, 2), 'utf8');
  }
  
  console.log(`Generated all 20 batch JSON files for Kids game: ${gameType}`);
});

console.log("=== SUCCESSFULLY GENERATED ALL 440 KIDS CURRICULUM JSON FILES! ===");
