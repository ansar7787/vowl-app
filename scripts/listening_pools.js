// Listening category pools - 10 games × 30 templates each
const C = (inst,fields,it) => ({instruction:inst,interactionType:it||'choice',fields});

// ambientId: identify sounds
const ambientId = [
  C('Identify the sound.',{question:"You hear chirping in the morning. What is the source?",options:["Birds","Cars","Wind","Rain"],correctAnswerIndex:0,hint:"Animals at dawn.",soundDescription:"Chirping at dawn"}),
  C('Identify the sound.',{question:"You hear a siren getting louder. What is it?",options:["Ambulance","Bird","Music","Thunder"],correctAnswerIndex:0,hint:"Emergency vehicle.",soundDescription:"Approaching siren"}),
  C('Identify the sound.',{question:"You hear splashing in a park. What could it be?",options:["Fountain","Car engine","Doorbell","Alarm"],correctAnswerIndex:0,hint:"Water feature.",soundDescription:"Splashing water"}),
  C('Identify the sound.',{question:"You hear a rhythmic ticking. What is the source?",options:["Clock","Dog","Phone","Wind"],correctAnswerIndex:0,hint:"Timekeeping device.",soundDescription:"Rhythmic ticking"}),
  C('Identify the sound.',{question:"You hear thunder rumbling. What weather follows?",options:["Storm","Sunshine","Snow","Fog"],correctAnswerIndex:0,hint:"Before rain.",soundDescription:"Rumbling thunder"}),
  C('Identify the sound.',{question:"You hear a whistle blowing at a field. Who uses it?",options:["Referee","Chef","Teacher","Doctor"],correctAnswerIndex:0,hint:"Sports context.",soundDescription:"Whistle at field"}),
  C('Identify the sound.',{question:"You hear crunching underfoot in autumn. What is it?",options:["Dry leaves","Glass","Ice","Sand"],correctAnswerIndex:0,hint:"Fall season.",soundDescription:"Crunching leaves"}),
  C('Identify the sound.',{question:"You hear a buzzing near flowers. What is it?",options:["Bee","Car","Phone","Fan"],correctAnswerIndex:0,hint:"Pollinator.",soundDescription:"Buzzing near flowers"}),
  C('Identify the sound.',{question:"You hear waves crashing. Where are you?",options:["Beach","Mountain","Forest","City"],correctAnswerIndex:0,hint:"Coastal area.",soundDescription:"Crashing waves"}),
  C('Identify the sound.',{question:"You hear a dog barking at night. What's happening?",options:["Dog alerting","Music playing","Rain falling","Wind blowing"],correctAnswerIndex:0,hint:"Animal reaction.",soundDescription:"Dog barking"}),
  C('Identify the sound.',{question:"You hear a kettle whistling. Where are you?",options:["Kitchen","Garden","Office","Gym"],correctAnswerIndex:0,hint:"Where water is boiled.",soundDescription:"Kettle whistling"}),
  C('Identify the sound.',{question:"You hear typing sounds. What is someone doing?",options:["Using a keyboard","Cooking","Painting","Running"],correctAnswerIndex:0,hint:"Computer work.",soundDescription:"Keyboard typing"}),
  C('Identify the sound.',{question:"You hear a rooster crowing. What time is it?",options:["Early morning","Midnight","Afternoon","Evening"],correctAnswerIndex:0,hint:"Dawn time.",soundDescription:"Rooster crowing"}),
  C('Identify the sound.',{question:"You hear glass breaking. What happened?",options:["Something was dropped","Music playing","Rain falling","Bird singing"],correctAnswerIndex:0,hint:"An accident.",soundDescription:"Glass breaking"}),
  C('Identify the sound.',{question:"You hear a train horn. Where are you?",options:["Near railway tracks","In a park","At the beach","In a library"],correctAnswerIndex:0,hint:"Railway.",soundDescription:"Train horn"}),
  C('Identify the sound.',{question:"You hear rain pattering on a window. What's the weather?",options:["Rainy","Sunny","Snowy","Windy"],correctAnswerIndex:0,hint:"Water on glass.",soundDescription:"Rain on window"}),
  C('Identify the sound.',{question:"You hear a school bell ringing. What does it signal?",options:["Class change","Fire alarm","Lunch time","Morning assembly"],correctAnswerIndex:0,hint:"Academic schedule.",soundDescription:"School bell"}),
  C('Identify the sound.',{question:"You hear pages turning. Where might you be?",options:["Library","Kitchen","Gym","Pool"],correctAnswerIndex:0,hint:"Reading space.",soundDescription:"Pages turning"}),
  C('Identify the sound.',{question:"You hear coins jingling. What is someone doing?",options:["Counting money","Cooking","Painting","Swimming"],correctAnswerIndex:0,hint:"Currency handling.",soundDescription:"Coins jingling"}),
  C('Identify the sound.',{question:"You hear a doorbell. What should you do?",options:["Open the door","Turn off lights","Start cooking","Go to sleep"],correctAnswerIndex:0,hint:"Someone is visiting.",soundDescription:"Doorbell ring"}),
  C('Identify the sound.',{question:"You hear birds singing in a forest. How does it feel?",options:["Peaceful","Scary","Noisy","Hot"],correctAnswerIndex:0,hint:"Nature ambiance.",soundDescription:"Forest birds"}),
  C('Identify the sound.',{question:"You hear an airplane overhead. Where is it?",options:["In the sky","Underground","In water","In a building"],correctAnswerIndex:0,hint:"Air travel.",soundDescription:"Airplane overhead"}),
  C('Identify the sound.',{question:"You hear a baby crying. What might it need?",options:["Attention","A book","A pen","A computer"],correctAnswerIndex:0,hint:"Infant needs.",soundDescription:"Baby crying"}),
  C('Identify the sound.',{question:"You hear popcorn popping. Where are you?",options:["Cinema or kitchen","Library","Office","Hospital"],correctAnswerIndex:0,hint:"Snack preparation.",soundDescription:"Popcorn popping"}),
  C('Identify the sound.',{question:"You hear applause. What just happened?",options:["A performance ended","A class started","Rain began","Lights went out"],correctAnswerIndex:0,hint:"Audience reaction.",soundDescription:"Applause"}),
  C('Identify the sound.',{question:"You hear a car honking in traffic. Why?",options:["To signal other drivers","To play music","To cool down","To park"],correctAnswerIndex:0,hint:"Road communication.",soundDescription:"Car horn"}),
  C('Identify the sound.',{question:"You hear crickets chirping. What time is it?",options:["Night","Morning","Noon","Dawn"],correctAnswerIndex:0,hint:"Nocturnal insects.",soundDescription:"Crickets at night"}),
  C('Identify the sound.',{question:"You hear a camera shutter clicking. What is happening?",options:["Taking a photo","Cooking","Cleaning","Sleeping"],correctAnswerIndex:0,hint:"Photography.",soundDescription:"Camera shutter"}),
  C('Identify the sound.',{question:"You hear hammering. What is someone doing?",options:["Building something","Reading","Swimming","Singing"],correctAnswerIndex:0,hint:"Construction work.",soundDescription:"Hammering"}),
  C('Identify the sound.',{question:"You hear a microwave beeping. What does it mean?",options:["Food is ready","Phone ringing","Alarm going off","Doorbell"],correctAnswerIndex:0,hint:"Kitchen appliance.",soundDescription:"Microwave beep"}),
];

// For the other 9 listening games, use passage-based MCQ format
const mkL = (passage,q,opts,ci,hint) => C('Listen and answer.',{passage,question:q,options:opts,correctAnswerIndex:ci,hint});

const audioFillBlanks = [
  C('Fill in the blank.',{passage:"The weather today is ___ and warm.",question:"Choose the missing word.",options:["sunny","rainy","snowy","foggy"],correctAnswerIndex:0,hint:"Warm weather.",missingWord:"sunny"}),
  C('Fill in the blank.',{passage:"She went to the ___ to buy groceries.",question:"Choose the missing word.",options:["store","library","gym","park"],correctAnswerIndex:0,hint:"Shopping place.",missingWord:"store"}),
  C('Fill in the blank.',{passage:"The children were playing in the ___ after school.",question:"Choose the missing word.",options:["park","office","hospital","bank"],correctAnswerIndex:0,hint:"Play area.",missingWord:"park"}),
  C('Fill in the blank.',{passage:"He ___ his homework before dinner every day.",question:"Choose the missing word.",options:["finishes","ignores","burns","plants"],correctAnswerIndex:0,hint:"Completing tasks.",missingWord:"finishes"}),
  C('Fill in the blank.',{passage:"The cat sat on the ___ and watched the birds.",question:"Choose the missing word.",options:["windowsill","roof","street","cloud"],correctAnswerIndex:0,hint:"Inside the house.",missingWord:"windowsill"}),
  C('Fill in the blank.',{passage:"Please ___ the door when you leave the room.",question:"Choose the missing word.",options:["close","paint","break","eat"],correctAnswerIndex:0,hint:"Action with a door.",missingWord:"close"}),
  C('Fill in the blank.',{passage:"The ___ rises in the east every morning.",question:"Choose the missing word.",options:["sun","moon","star","cloud"],correctAnswerIndex:0,hint:"Morning sky.",missingWord:"sun"}),
  C('Fill in the blank.',{passage:"She ___ a beautiful song at the concert last night.",question:"Choose the missing word.",options:["sang","wrote","painted","built"],correctAnswerIndex:0,hint:"Musical performance.",missingWord:"sang"}),
  C('Fill in the blank.',{passage:"We need to ___ the train at 8 AM sharp.",question:"Choose the missing word.",options:["catch","throw","kick","drop"],correctAnswerIndex:0,hint:"Board transportation.",missingWord:"catch"}),
  C('Fill in the blank.',{passage:"The flowers in the ___ bloom every spring.",question:"Choose the missing word.",options:["garden","kitchen","bedroom","garage"],correctAnswerIndex:0,hint:"Where plants grow.",missingWord:"garden"}),
  C('Fill in the blank.',{passage:"He wore a thick ___ because it was very cold outside.",question:"Choose the missing word.",options:["jacket","hat","ring","watch"],correctAnswerIndex:0,hint:"Winter clothing.",missingWord:"jacket"}),
  C('Fill in the blank.',{passage:"The teacher asked the students to open their ___.",question:"Choose the missing word.",options:["books","windows","bags","mouths"],correctAnswerIndex:0,hint:"Learning materials.",missingWord:"books"}),
  C('Fill in the blank.',{passage:"They traveled by ___ to reach the island.",question:"Choose the missing word.",options:["boat","car","train","bicycle"],correctAnswerIndex:0,hint:"Water transport.",missingWord:"boat"}),
  C('Fill in the blank.',{passage:"She ___ her grandmother every weekend.",question:"Choose the missing word.",options:["visits","avoids","forgets","scolds"],correctAnswerIndex:0,hint:"Family time.",missingWord:"visits"}),
  C('Fill in the blank.',{passage:"The library is the quietest ___ in the school.",question:"Choose the missing word.",options:["place","sport","food","color"],correctAnswerIndex:0,hint:"Location descriptor.",missingWord:"place"}),
  C('Fill in the blank.',{passage:"He ___ the ball over the fence during the game.",question:"Choose the missing word.",options:["kicked","ate","read","slept"],correctAnswerIndex:0,hint:"Sports action.",missingWord:"kicked"}),
  C('Fill in the blank.',{passage:"The movie was so ___ that everyone laughed.",question:"Choose the missing word.",options:["funny","scary","boring","long"],correctAnswerIndex:0,hint:"Caused laughter.",missingWord:"funny"}),
  C('Fill in the blank.',{passage:"She ___ a letter to her friend who lives abroad.",question:"Choose the missing word.",options:["wrote","cooked","drove","swam"],correctAnswerIndex:0,hint:"Written communication.",missingWord:"wrote"}),
  C('Fill in the blank.',{passage:"The baby was sleeping ___ in the crib.",question:"Choose the missing word.",options:["peacefully","loudly","angrily","quickly"],correctAnswerIndex:0,hint:"Calm rest.",missingWord:"peacefully"}),
  C('Fill in the blank.',{passage:"They planted a ___ in the backyard last spring.",question:"Choose the missing word.",options:["tree","chair","television","computer"],correctAnswerIndex:0,hint:"Garden activity.",missingWord:"tree"}),
  C('Fill in the blank.',{passage:"The ___ was delicious and everyone asked for seconds.",question:"Choose the missing word.",options:["cake","chair","pencil","shoe"],correctAnswerIndex:0,hint:"Something you eat.",missingWord:"cake"}),
  C('Fill in the blank.',{passage:"He always ___ his teeth before going to bed.",question:"Choose the missing word.",options:["brushes","paints","throws","hides"],correctAnswerIndex:0,hint:"Dental hygiene.",missingWord:"brushes"}),
  C('Fill in the blank.',{passage:"The exam was very ___ and many students struggled.",question:"Choose the missing word.",options:["difficult","easy","short","fun"],correctAnswerIndex:0,hint:"Challenging test.",missingWord:"difficult"}),
  C('Fill in the blank.',{passage:"She lives in a small ___ near the mountains.",question:"Choose the missing word.",options:["village","ocean","desert","cloud"],correctAnswerIndex:0,hint:"Rural settlement.",missingWord:"village"}),
  C('Fill in the blank.',{passage:"The dog ___ its tail when it saw its owner.",question:"Choose the missing word.",options:["wagged","hid","bit","cooked"],correctAnswerIndex:0,hint:"Happy dog behavior.",missingWord:"wagged"}),
  C('Fill in the blank.',{passage:"We should always ___ water to stay hydrated.",question:"Choose the missing word.",options:["drink","throw","waste","boil"],correctAnswerIndex:0,hint:"Healthy habit.",missingWord:"drink"}),
  C('Fill in the blank.',{passage:"The artist ___ a stunning portrait of the queen.",question:"Choose the missing word.",options:["painted","deleted","erased","broke"],correctAnswerIndex:0,hint:"Creating art.",missingWord:"painted"}),
  C('Fill in the blank.',{passage:"She ___ the bus to work every morning at seven.",question:"Choose the missing word.",options:["takes","throws","eats","reads"],correctAnswerIndex:0,hint:"Daily commute.",missingWord:"takes"}),
  C('Fill in the blank.',{passage:"The stars ___ brightly in the clear night sky.",question:"Choose the missing word.",options:["shine","fall","sleep","grow"],correctAnswerIndex:0,hint:"Starlight.",missingWord:"shine"}),
  C('Fill in the blank.',{passage:"He ___ the trophy for winning first place.",question:"Choose the missing word.",options:["received","lost","broke","forgot"],correctAnswerIndex:0,hint:"Award ceremony.",missingWord:"received"}),
];

// Reuse patterns for remaining listening games
const audioMultipleChoice = ambientId.map(q => ({...q, instruction:'Listen and choose the correct answer.'}));
const audioSentenceOrder = audioFillBlanks.map(q => ({...q, instruction:'Put the sentences in order.'}));
const audioTrueFalse = ambientId.map(q => ({...q, instruction:'True or False?', fields:{...q.fields, options:['True','False'], correctAnswerIndex:0}}));
const detailSpotlight = audioFillBlanks.map(q => ({...q, instruction:'Spot the detail.'}));
const emotionRecognition = [
  C('Identify the emotion.',{passage:"I can't believe I won the competition!",question:"What emotion is expressed?",options:["Joy","Anger","Sadness","Fear"],correctAnswerIndex:0,hint:"Winning feeling."}),
  C('Identify the emotion.',{passage:"I'm so frustrated! Nothing is going right today.",question:"What emotion is expressed?",options:["Happiness","Frustration","Excitement","Calm"],correctAnswerIndex:1,hint:"Things going wrong."}),
  C('Identify the emotion.',{passage:"I miss my grandmother. She was the kindest person.",question:"What emotion is expressed?",options:["Anger","Joy","Sadness","Surprise"],correctAnswerIndex:2,hint:"Missing someone."}),
  C('Identify the emotion.',{passage:"Did you hear that noise? I think someone is outside.",question:"What emotion is expressed?",options:["Joy","Boredom","Fear","Pride"],correctAnswerIndex:2,hint:"Unknown noise at night."}),
  C('Identify the emotion.',{passage:"You got me a gift? I had no idea! Thank you!",question:"What emotion is expressed?",options:["Anger","Surprise","Sadness","Boredom"],correctAnswerIndex:1,hint:"Unexpected gift."}),
  C('Identify the emotion.',{passage:"I worked so hard and still failed the exam.",question:"What emotion is expressed?",options:["Joy","Pride","Disappointment","Excitement"],correctAnswerIndex:2,hint:"Effort without result."}),
  C('Identify the emotion.',{passage:"We're going on vacation tomorrow! I can't wait!",question:"What emotion is expressed?",options:["Excitement","Fear","Sadness","Anger"],correctAnswerIndex:0,hint:"Looking forward to something."}),
  C('Identify the emotion.',{passage:"Don't touch my things without asking. I'm serious.",question:"What emotion is expressed?",options:["Joy","Annoyance","Sadness","Surprise"],correctAnswerIndex:1,hint:"Boundary being crossed."}),
  C('Identify the emotion.',{passage:"I finally got the promotion I've been working toward!",question:"What emotion is expressed?",options:["Pride","Fear","Anger","Boredom"],correctAnswerIndex:0,hint:"Achievement after effort."}),
  C('Identify the emotion.',{passage:"There's nothing to do today. Everything is boring.",question:"What emotion is expressed?",options:["Excitement","Boredom","Fear","Gratitude"],correctAnswerIndex:1,hint:"Lack of stimulation."}),
  C('Identify the emotion.',{passage:"Thank you so much for helping me when I needed it most.",question:"What emotion is expressed?",options:["Anger","Gratitude","Fear","Jealousy"],correctAnswerIndex:1,hint:"Appreciation."}),
  C('Identify the emotion.',{passage:"Why did they get the award instead of me? It's not fair!",question:"What emotion is expressed?",options:["Joy","Gratitude","Jealousy","Calm"],correctAnswerIndex:2,hint:"Unfairness felt."}),
  C('Identify the emotion.',{passage:"I'm so proud of you for graduating with honors!",question:"What emotion is expressed?",options:["Envy","Pride","Sadness","Fear"],correctAnswerIndex:1,hint:"Celebrating achievement."}),
  C('Identify the emotion.',{passage:"I'm really sorry for what I said. I didn't mean it.",question:"What emotion is expressed?",options:["Pride","Regret","Joy","Excitement"],correctAnswerIndex:1,hint:"Apologizing."}),
  C('Identify the emotion.',{passage:"What a beautiful painting! It takes my breath away.",question:"What emotion is expressed?",options:["Admiration","Fear","Anger","Boredom"],correctAnswerIndex:0,hint:"Art appreciation."}),
  C('Identify the emotion.',{passage:"I'm nervous about the interview tomorrow morning.",question:"What emotion is expressed?",options:["Confidence","Anxiety","Joy","Anger"],correctAnswerIndex:1,hint:"Pre-event worry."}),
  C('Identify the emotion.',{passage:"You lied to me! How could you do that?",question:"What emotion is expressed?",options:["Happiness","Trust","Betrayal","Boredom"],correctAnswerIndex:2,hint:"Trust broken."}),
  C('Identify the emotion.',{passage:"I feel so calm sitting by the lake watching the sunset.",question:"What emotion is expressed?",options:["Anger","Anxiety","Serenity","Confusion"],correctAnswerIndex:2,hint:"Peaceful moment."}),
  C('Identify the emotion.',{passage:"This is the most confusing map I've ever seen.",question:"What emotion is expressed?",options:["Joy","Clarity","Confusion","Pride"],correctAnswerIndex:2,hint:"Hard to understand."}),
  C('Identify the emotion.',{passage:"Yes! The team scored in the last minute! We won!",question:"What emotion is expressed?",options:["Sadness","Elation","Fear","Boredom"],correctAnswerIndex:1,hint:"Last-minute victory."}),
  C('Identify the emotion.',{passage:"I wish I could travel the world someday.",question:"What emotion is expressed?",options:["Anger","Longing","Fear","Disgust"],correctAnswerIndex:1,hint:"Desire for something."}),
  C('Identify the emotion.',{passage:"Don't talk to me right now. I need some space.",question:"What emotion is expressed?",options:["Joy","Overwhelm","Excitement","Pride"],correctAnswerIndex:1,hint:"Needing distance."}),
  C('Identify the emotion.',{passage:"That spider is huge! Get it away from me!",question:"What emotion is expressed?",options:["Curiosity","Delight","Disgust","Pride"],correctAnswerIndex:2,hint:"Reaction to creepy crawlies."}),
  C('Identify the emotion.',{passage:"I love spending time with my family during holidays.",question:"What emotion is expressed?",options:["Contentment","Anger","Loneliness","Boredom"],correctAnswerIndex:0,hint:"Family warmth."}),
  C('Identify the emotion.',{passage:"The test results came back and everything is fine!",question:"What emotion is expressed?",options:["Relief","Panic","Sadness","Frustration"],correctAnswerIndex:0,hint:"Good news after worry."}),
  C('Identify the emotion.',{passage:"I can't believe she said that about me behind my back.",question:"What emotion is expressed?",options:["Joy","Hurt","Excitement","Calm"],correctAnswerIndex:1,hint:"Feeling wronged."}),
  C('Identify the emotion.',{passage:"Wow, this roller coaster is amazing! Let's go again!",question:"What emotion is expressed?",options:["Fear","Thrill","Sadness","Anger"],correctAnswerIndex:1,hint:"Amusement park fun."}),
  C('Identify the emotion.',{passage:"I feel so lonely since moving to a new city.",question:"What emotion is expressed?",options:["Joy","Pride","Loneliness","Excitement"],correctAnswerIndex:2,hint:"New place, no friends yet."}),
  C('Identify the emotion.',{passage:"How dare they cancel the event without telling us!",question:"What emotion is expressed?",options:["Gratitude","Outrage","Joy","Calm"],correctAnswerIndex:1,hint:"Unfair treatment."}),
  C('Identify the emotion.',{passage:"I'm so hopeful about the future. Great things are coming!",question:"What emotion is expressed?",options:["Despair","Hope","Anger","Boredom"],correctAnswerIndex:1,hint:"Positive outlook."}),
];
const fastSpeechDecoder = audioFillBlanks.map(q => ({...q, instruction:'Decode the fast speech.'}));
const listeningInference = emotionRecognition.map(q => ({...q, instruction:'What can you infer?'}));
const soundImageMatch = ambientId.map(q => ({...q, instruction:'Match the sound to the image.'}));

module.exports = {
  ambientId, audioFillBlanks, audioMultipleChoice, audioSentenceOrder,
  audioTrueFalse, detailSpotlight, emotionRecognition, fastSpeechDecoder,
  listeningInference, soundImageMatch,
};
