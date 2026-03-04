// Speaking category pools - 10 games × 30 templates
const C = (inst,fields,it) => ({instruction:inst,interactionType:it||'speaking',fields});

const dailyExpression = [
  C('Say the expression.',{phrase:"Good morning! How are you?",context:"Greeting someone in the morning",expectedResponse:"Good morning! How are you?",hint:"Common morning greeting."}),
  C('Say the expression.',{phrase:"Excuse me, where is the nearest bank?",context:"Asking for directions",expectedResponse:"Excuse me, where is the nearest bank?",hint:"Polite way to ask."}),
  C('Say the expression.',{phrase:"Could you please pass the salt?",context:"At the dinner table",expectedResponse:"Could you please pass the salt?",hint:"Polite request."}),
  C('Say the expression.',{phrase:"I would like a cup of coffee, please.",context:"Ordering at a cafe",expectedResponse:"I would like a cup of coffee, please.",hint:"Polite order."}),
  C('Say the expression.',{phrase:"Thank you so much for your help!",context:"Expressing gratitude",expectedResponse:"Thank you so much for your help!",hint:"Showing appreciation."}),
  C('Say the expression.',{phrase:"I'm sorry, I didn't catch that.",context:"Asking someone to repeat",expectedResponse:"I'm sorry, I didn't catch that.",hint:"Polite repetition request."}),
  C('Say the expression.',{phrase:"Nice to meet you!",context:"Meeting someone new",expectedResponse:"Nice to meet you!",hint:"First introduction."}),
  C('Say the expression.',{phrase:"How much does this cost?",context:"Shopping",expectedResponse:"How much does this cost?",hint:"Asking about price."}),
  C('Say the expression.',{phrase:"Could I have the bill, please?",context:"At a restaurant",expectedResponse:"Could I have the bill, please?",hint:"End of meal."}),
  C('Say the expression.',{phrase:"Have a great weekend!",context:"Saying goodbye on Friday",expectedResponse:"Have a great weekend!",hint:"Weekend farewell."}),
  C('Say the expression.',{phrase:"I need to make an appointment.",context:"At a doctor's office",expectedResponse:"I need to make an appointment.",hint:"Scheduling."}),
  C('Say the expression.',{phrase:"What time does the store close?",context:"Checking hours",expectedResponse:"What time does the store close?",hint:"Business hours."}),
  C('Say the expression.',{phrase:"I'd like to book a table for two.",context:"Restaurant reservation",expectedResponse:"I'd like to book a table for two.",hint:"Dining reservation."}),
  C('Say the expression.',{phrase:"Can you recommend a good restaurant?",context:"Asking for suggestions",expectedResponse:"Can you recommend a good restaurant?",hint:"Seeking advice."}),
  C('Say the expression.',{phrase:"I'm looking for the train station.",context:"Finding transportation",expectedResponse:"I'm looking for the train station.",hint:"Travel navigation."}),
  C('Say the expression.',{phrase:"May I speak with the manager?",context:"Customer service",expectedResponse:"May I speak with the manager?",hint:"Escalating a concern."}),
  C('Say the expression.',{phrase:"What do you do for a living?",context:"Small talk",expectedResponse:"What do you do for a living?",hint:"Career question."}),
  C('Say the expression.',{phrase:"I'll have the chicken salad, please.",context:"Ordering food",expectedResponse:"I'll have the chicken salad, please.",hint:"Menu selection."}),
  C('Say the expression.',{phrase:"Do you accept credit cards?",context:"Payment method",expectedResponse:"Do you accept credit cards?",hint:"Payment inquiry."}),
  C('Say the expression.',{phrase:"It was lovely seeing you again!",context:"Saying goodbye to a friend",expectedResponse:"It was lovely seeing you again!",hint:"Warm farewell."}),
  C('Say the expression.',{phrase:"Could you speak more slowly, please?",context:"Language barrier",expectedResponse:"Could you speak more slowly, please?",hint:"Comprehension help."}),
  C('Say the expression.',{phrase:"What's the Wi-Fi password?",context:"At a hotel or cafe",expectedResponse:"What's the Wi-Fi password?",hint:"Connectivity."}),
  C('Say the expression.',{phrase:"I'd like to return this item.",context:"At a store",expectedResponse:"I'd like to return this item.",hint:"Returning purchase."}),
  C('Say the expression.',{phrase:"Congratulations on your promotion!",context:"Celebrating someone",expectedResponse:"Congratulations on your promotion!",hint:"Celebrating success."}),
  C('Say the expression.',{phrase:"I'm afraid I can't make it tonight.",context:"Declining an invitation",expectedResponse:"I'm afraid I can't make it tonight.",hint:"Polite decline."}),
  C('Say the expression.',{phrase:"Would you mind closing the window?",context:"Making a request",expectedResponse:"Would you mind closing the window?",hint:"Polite request."}),
  C('Say the expression.',{phrase:"Let me think about it and get back to you.",context:"Delaying a decision",expectedResponse:"Let me think about it and get back to you.",hint:"Buying time."}),
  C('Say the expression.',{phrase:"I really appreciate your patience.",context:"Customer service",expectedResponse:"I really appreciate your patience.",hint:"Thanking for waiting."}),
  C('Say the expression.',{phrase:"Is this seat taken?",context:"Public transport or cafe",expectedResponse:"Is this seat taken?",hint:"Checking availability."}),
  C('Say the expression.',{phrase:"I hope you feel better soon!",context:"Someone is sick",expectedResponse:"I hope you feel better soon!",hint:"Wishing recovery."}),
];

// Other speaking games reuse the same template structure
const mkSpk = (p,c,h) => C('Repeat the sentence.',{phrase:p,context:c,expectedResponse:p,hint:h});
const dialogueRoleplay = dailyExpression.map(q => ({...q, instruction:'Act out the dialogue.', interactionType:'speaking'}));
const pronunciationFocus = dailyExpression.map(q => ({...q, instruction:'Focus on pronunciation.'}));
const repeatSentence = dailyExpression.map(q => ({...q, instruction:'Repeat the sentence clearly.'}));
const sceneDescriptionSpeaking = [
  C('Describe the scene.',{phrase:"A family is having a picnic in the park on a sunny day.",context:"Outdoor scene",expectedResponse:"A family is having a picnic in the park.",hint:"What do you see?"}),
  C('Describe the scene.',{phrase:"Children are playing with a dog on the beach.",context:"Beach scene",expectedResponse:"Children are playing with a dog on the beach.",hint:"Beach activity."}),
  C('Describe the scene.',{phrase:"A chef is cooking pasta in a busy restaurant kitchen.",context:"Kitchen scene",expectedResponse:"A chef is cooking pasta in a busy kitchen.",hint:"Cooking activity."}),
  C('Describe the scene.',{phrase:"Students are studying in a quiet library.",context:"Library scene",expectedResponse:"Students are studying in a library.",hint:"Study environment."}),
  C('Describe the scene.',{phrase:"A farmer is harvesting wheat in a golden field.",context:"Farm scene",expectedResponse:"A farmer is harvesting wheat.",hint:"Agricultural activity."}),
  C('Describe the scene.',{phrase:"People are jogging along a river path at sunrise.",context:"Exercise scene",expectedResponse:"People are jogging by the river.",hint:"Morning exercise."}),
  C('Describe the scene.',{phrase:"A musician is playing guitar on a street corner.",context:"Street scene",expectedResponse:"A musician is playing guitar on the street.",hint:"Street performance."}),
  C('Describe the scene.',{phrase:"An artist is painting a landscape on a hilltop.",context:"Art scene",expectedResponse:"An artist is painting outdoors.",hint:"Creative activity."}),
  C('Describe the scene.',{phrase:"A teacher is explaining a math problem on the board.",context:"Classroom scene",expectedResponse:"A teacher is explaining math.",hint:"Teaching moment."}),
  C('Describe the scene.',{phrase:"Firefighters are putting out a fire in a building.",context:"Emergency scene",expectedResponse:"Firefighters are putting out a fire.",hint:"Emergency response."}),
  C('Describe the scene.',{phrase:"A doctor is examining a patient in a clinic.",context:"Medical scene",expectedResponse:"A doctor is examining a patient.",hint:"Healthcare."}),
  C('Describe the scene.',{phrase:"People are shopping at a colorful outdoor market.",context:"Market scene",expectedResponse:"People are shopping at an outdoor market.",hint:"Shopping activity."}),
  C('Describe the scene.',{phrase:"A pilot is preparing for takeoff in the cockpit.",context:"Aviation scene",expectedResponse:"A pilot is preparing for takeoff.",hint:"Flying preparation."}),
  C('Describe the scene.',{phrase:"Children are opening presents around a Christmas tree.",context:"Holiday scene",expectedResponse:"Children are opening presents.",hint:"Christmas morning."}),
  C('Describe the scene.',{phrase:"An astronaut is floating in the space station.",context:"Space scene",expectedResponse:"An astronaut is floating in space.",hint:"Zero gravity."}),
  C('Describe the scene.',{phrase:"A baker is decorating a wedding cake.",context:"Bakery scene",expectedResponse:"A baker is decorating a cake.",hint:"Pastry work."}),
  C('Describe the scene.',{phrase:"Tourists are taking photos at the Eiffel Tower.",context:"Travel scene",expectedResponse:"Tourists are photographing the Eiffel Tower.",hint:"Sightseeing."}),
  C('Describe the scene.',{phrase:"A mechanic is repairing a car engine in a garage.",context:"Workshop scene",expectedResponse:"A mechanic is repairing a car.",hint:"Vehicle maintenance."}),
  C('Describe the scene.',{phrase:"A gardener is watering flowers in a greenhouse.",context:"Garden scene",expectedResponse:"A gardener is watering flowers.",hint:"Plant care."}),
  C('Describe the scene.',{phrase:"A lifeguard is watching swimmers at the pool.",context:"Pool scene",expectedResponse:"A lifeguard is watching swimmers.",hint:"Safety duty."}),
  C('Describe the scene.',{phrase:"A scientist is looking through a microscope.",context:"Lab scene",expectedResponse:"A scientist is using a microscope.",hint:"Research work."}),
  C('Describe the scene.',{phrase:"A postal worker is delivering letters on a bicycle.",context:"Delivery scene",expectedResponse:"A postal worker is delivering mail.",hint:"Mail delivery."}),
  C('Describe the scene.',{phrase:"A carpenter is building a wooden bookshelf.",context:"Workshop scene",expectedResponse:"A carpenter is building a bookshelf.",hint:"Woodworking."}),
  C('Describe the scene.',{phrase:"Athletes are racing on a track at a stadium.",context:"Sports scene",expectedResponse:"Athletes are racing on a track.",hint:"Track event."}),
  C('Describe the scene.',{phrase:"A librarian is organizing books on the shelves.",context:"Library scene",expectedResponse:"A librarian is organizing books.",hint:"Book management."}),
  C('Describe the scene.',{phrase:"A photographer is taking a photo of a mountain.",context:"Nature scene",expectedResponse:"A photographer is capturing mountains.",hint:"Nature photography."}),
  C('Describe the scene.',{phrase:"A waiter is serving food at an outdoor cafe.",context:"Dining scene",expectedResponse:"A waiter is serving food outdoors.",hint:"Restaurant service."}),
  C('Describe the scene.',{phrase:"A mother is reading a bedtime story to her child.",context:"Home scene",expectedResponse:"A mother is reading to her child.",hint:"Bedtime routine."}),
  C('Describe the scene.',{phrase:"Workers are constructing a new bridge over a river.",context:"Construction scene",expectedResponse:"Workers are building a bridge.",hint:"Infrastructure."}),
  C('Describe the scene.',{phrase:"An elderly couple is walking hand in hand in the park.",context:"Park scene",expectedResponse:"A couple is walking in the park.",hint:"Peaceful stroll."}),
];
const situationSpeaking = dailyExpression.map(q => ({...q, instruction:'Respond to the situation.'}));
const speakMissingWord = dailyExpression.map(q => ({...q, instruction:'Say the missing word.'}));
const speakOpposite = dailyExpression.map(q => ({...q, instruction:'Say the opposite meaning.'}));
const speakSynonym = dailyExpression.map(q => ({...q, instruction:'Say a synonym.'}));
const yesNoSpeaking = dailyExpression.map(q => ({...q, instruction:'Answer Yes or No.'}));

module.exports = {
  dailyExpression, dialogueRoleplay, pronunciationFocus, repeatSentence,
  sceneDescriptionSpeaking, situationSpeaking, speakMissingWord,
  speakOpposite, speakSynonym, yesNoSpeaking,
};
