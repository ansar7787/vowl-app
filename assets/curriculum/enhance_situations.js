const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'speaking', 'situationSpeaking_1_10.json');

const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));

const situationMapping = [
  {
    situationText: "You are ordering a latte at a coffee shop and want to ask for extra sugar.",
    acceptedSubstrings: ["extra sugar", "some sugar", "sugar please", "add sugar"],
    sampleAnswer: "Could I please get a latte with some extra sugar?",
    hint: "Request a warm drink with sweetening added.",
    explanation: "Requesting a warm drink politely with extra sugar ensures clear hospitality service."
  },
  {
    situationText: "You want to congratulate your coworker on an outstanding product demo.",
    acceptedSubstrings: ["congratulations", "great job", "amazing work", "well done", "awesome demo"],
    sampleAnswer: "Congratulations on the demo, you did an amazing job!",
    hint: "Express congratulations and highlight their demo quality.",
    explanation: "Congratulating peers on key milestones fosters team trust and bonding."
  },
  {
    situationText: "You need to ask a stranger politely for the current time because your phone died.",
    acceptedSubstrings: ["excuse me", "have the time", "what time", "what time is it"],
    sampleAnswer: "Excuse me, do you happen to have the time?",
    hint: "Approach a stranger with 'Excuse me' and query the hour.",
    explanation: "Standard polite request opening with 'Excuse me' before asking the time."
  },
  {
    situationText: "You want to order a slice of chocolate cake at a bakery.",
    acceptedSubstrings: ["chocolate cake", "slice of cake", "cake please", "have a slice"],
    sampleAnswer: "I would like to have a slice of chocolate cake, please.",
    hint: "State your request for a slice of cocoa dessert.",
    explanation: "Clear and direct ordering statements are essential for bakery retail interaction."
  },
  {
    situationText: "You are at a clothing store and need to ask the clerk where the fitting rooms are.",
    acceptedSubstrings: ["fitting rooms", "changing rooms", "try this on", "where are"],
    sampleAnswer: "Excuse me, could you tell me where the fitting rooms are?",
    hint: "Ask the clerk about fitting or changing booths.",
    explanation: "Fitting rooms are standard vocabulary for fashion retail navigation."
  },
  {
    situationText: "You want to invite a friend to have lunch with you this weekend.",
    acceptedSubstrings: ["have lunch", "lunch this weekend", "grab a bite", "grab lunch"],
    sampleAnswer: "Are you free to grab some lunch together this weekend?",
    hint: "Ask if they are free to grab a bite or lunch.",
    explanation: "Friendly casual invitations typically use phrases like 'grab a bite' or 'have lunch'."
  },
  {
    situationText: "You are checking in at a hotel and want to ask if breakfast is included.",
    acceptedSubstrings: ["breakfast included", "is breakfast", "free breakfast", "morning breakfast"],
    sampleAnswer: "Hi, I'm checking in. Is breakfast included in my stay?",
    hint: "Query if morning meal service is included in your stay.",
    explanation: "Checking breakfast inclusion is a standard request during hospitality check-ins."
  },
  {
    situationText: "You want to apologize politely to your team for arriving late to the meeting.",
    acceptedSubstrings: ["sorry for being late", "sorry i am late", "apologize for the delay"],
    sampleAnswer: "I sincerely apologize for being late to the meeting.",
    hint: "Express regret for delayed entry.",
    explanation: "Polite meeting apologies help diffuse tension from delay."
  },
  {
    situationText: "You need to ask a server at a restaurant for the bill.",
    acceptedSubstrings: ["the bill please", "check please", "can we get the bill", "bring the check"],
    sampleAnswer: "Excuse me, could we please get the bill when you have a moment?",
    hint: "Signal the server and ask for the final check or bill.",
    explanation: "Asking for the check or bill completes dining transactions."
  },
  {
    situationText: "You are introducing yourself to a new colleague on your first day of work.",
    acceptedSubstrings: ["nice to meet you", "pleasure meeting you", "glad to meet you", "my name is"],
    sampleAnswer: "Hi there! I'm the new developer, it's a pleasure meeting you.",
    hint: "Introduce yourself by name and say nice to meet you.",
    explanation: "First-day introductions establishing warm connection set up future collaboration."
  },
  {
    situationText: "You are requesting a glass of water from a flight attendant.",
    acceptedSubstrings: ["glass of water", "some water", "cup of water", "water please"],
    sampleAnswer: "Excuse me, could I please have a glass of water?",
    hint: "Ask for a cold cup or glass of water.",
    explanation: "Polite hydration requests are useful travel expressions."
  },
  {
    situationText: "You want to ask your teacher to repeat the last explanation because you didn't hear it.",
    acceptedSubstrings: ["repeat that", "say that again", "missed that", "one more time"],
    sampleAnswer: "Could you please repeat that last part one more time?",
    hint: "Ask if they can repeat or say the last part again.",
    explanation: "Requesting explanations gracefully ensures optimal learning progress."
  },
  {
    situationText: "You want to thank a friend who helped you move all your boxes to your new apartment.",
    acceptedSubstrings: ["thank you", "thanks for helping", "appreciate your help", "so grateful"],
    sampleAnswer: "Thank you so much for helping me move, I really appreciate it.",
    hint: "Express gratitude for their moving assistance.",
    explanation: "Gratitude reinforcement strengthens friendship connections."
  },
  {
    situationText: "You want to ask a library receptionist if they have books on astronomy.",
    acceptedSubstrings: ["astronomy", "books on space", "study space", "astronomy books"],
    sampleAnswer: "Excuse me, do you have any books on astronomy in this section?",
    hint: "Inquire about scientific astronomy literature.",
    explanation: "Astronomy search is a standard educational query in libraries."
  },
  {
    situationText: "You are ordering a pizza and want to ask for gluten-free crust.",
    acceptedSubstrings: ["gluten free", "gluten-free", "without gluten", "no gluten"],
    sampleAnswer: "Could I order a vegetarian pizza with a gluten-free crust?",
    hint: "Request pizza dough made without gluten content.",
    explanation: "Dietary restrictions vocabulary is essential for healthy dining out."
  },
  {
    situationText: "You want to ask a passerby for directions to the nearest subway station.",
    acceptedSubstrings: ["subway station", "subway please", "nearest station", "how to get to"],
    sampleAnswer: "Excuse me, could you point me toward the nearest subway station?",
    hint: "Query the coordinates to a subway or transit depot.",
    explanation: "Transit directions queries are essential survival expressions in foreign cities."
  },
  {
    situationText: "You are declining a slice of pizza politely because you are already completely full.",
    acceptedSubstrings: ["no thank you", "no thanks", "full", "already ate", "good for now"],
    sampleAnswer: "No thank you, it looks delicious but I'm completely full.",
    hint: "Politely decline and state you are full.",
    explanation: "Decline food offerings gracefully using polite negatives."
  },
  {
    situationText: "You need to schedule an appointment with your dentist next Tuesday morning.",
    acceptedSubstrings: ["tuesday morning", "schedule appointment", "dentist appointment", "next tuesday"],
    sampleAnswer: "I would like to schedule a dental checkup for next Tuesday morning.",
    hint: "Mention scheduling an appointment for next Tuesday.",
    explanation: "Booking calendar events requires concrete day and time parameters."
  },
  {
    situationText: "You are asking a store assistant if a particular jacket comes in a larger size.",
    acceptedSubstrings: ["larger size", "bigger size", "size medium", "size large"],
    sampleAnswer: "Excuse me, does this brown jacket come in a larger size?",
    hint: "Query size availability of the apparel.",
    explanation: "Size queries form the backbone of fashion retail transactions."
  },
  {
    situationText: "You want to suggest watching a comedy movie to your friend tonight.",
    acceptedSubstrings: ["comedy movie", "watch a comedy", "funny movie", "comedy tonight"],
    sampleAnswer: "How about we watch a lighthearted comedy movie tonight?",
    hint: "Suggest a lighthearted funny or comedy film.",
    explanation: "Shared entertainment suggestions use warm casual structures."
  },
  {
    situationText: "You want to borrow your sibling's laptop for a quick video call.",
    acceptedSubstrings: ["borrow your laptop", "use your laptop", "use your computer", "borrow your computer"],
    sampleAnswer: "Is it okay if I borrow your laptop for a quick video call?",
    hint: "Politely request laptop borrowing for a chat.",
    explanation: "Requesting personal property requires highly respectful phrasing."
  },
  {
    situationText: "You are recommending a great Italian restaurant to a visiting tourist.",
    acceptedSubstrings: ["italian restaurant", "italian food", "try this place", "pasta place"],
    sampleAnswer: "You should absolutely try the Italian restaurant down the street.",
    hint: "Suggest Italian dining spots down the lane.",
    explanation: "Touristic culinary recommendations use descriptive positive modifiers."
  },
  {
    situationText: "You want to ask your boss for feedback on your quarterly performance.",
    acceptedSubstrings: ["feedback", "performance review", "my performance", "how am i doing"],
    sampleAnswer: "Could we schedule a brief chat to discuss my performance feedback?",
    hint: "Ask for a quarterly review or feedback session.",
    explanation: "Feedback requests show proactive professional development initiative."
  },
  {
    situationText: "You want to ask a salesperson if a smartphone comes with a warranty.",
    acceptedSubstrings: ["warranty", "guarantee", "covered", "insured"],
    sampleAnswer: "Does this new smartphone model come with a manufacturer's warranty?",
    hint: "Ask about product coverage or warranty details.",
    explanation: "Device protection inquiry is critical for electronic retail purchases."
  },
  {
    situationText: "You are complimenting a friend's stylish new haircut.",
    acceptedSubstrings: ["haircut", "hair looks", "great hair", "love your hair", "stylish haircut"],
    sampleAnswer: "Wow, I absolutely love your new haircut! It looks so stylish.",
    hint: "Compliment their haircut structure and style.",
    explanation: "Cosmetic compliments build positive social rapport."
  },
  {
    situationText: "You want to ask your roommate to turn down the music volume because you are studying.",
    acceptedSubstrings: ["turn down", "music down", "volume down", "a bit quieter"],
    sampleAnswer: "Could you please turn down the music a bit? I'm trying to study.",
    hint: "Politely request reducing music volume for studying.",
    explanation: "Domestic cohabitation requires polite requests for noise reduction."
  },
  {
    situationText: "You are booking a window seat for a flight to Tokyo.",
    acceptedSubstrings: ["window seat", "next to window", "by the window", "seat window"],
    sampleAnswer: "I would like to request a window seat for my flight to Tokyo, please.",
    hint: "Request airline ticket assignment next to a window pane.",
    explanation: "Window seating is high-priority vocabulary for comfortable air travel."
  },
  {
    situationText: "You want to ask your neighbor politely to water your plants while you are on vacation.",
    acceptedSubstrings: ["water my plants", "water the plants", "plants please", "my garden"],
    sampleAnswer: "Could you do me a huge favor and water my plants while I'm on vacation?",
    hint: "Ask if they can water your foliage while you are away.",
    explanation: "Neighborly favor requests are vital social competence indicators."
  },
  {
    situationText: "You are asking a shoe salesman if they have sneakers in size ten.",
    acceptedSubstrings: ["size ten", "size 10", "shoes ten", "sneakers ten"],
    sampleAnswer: "Excuse me, do you have these blue sneakers in a size ten?",
    hint: "Inquire about size ten athletic sneakers.",
    explanation: "Buying sportswear necessitates footwear measurements vocabulary."
  },
  {
    situationText: "You are wishing your friend a relaxing and peaceful weekend.",
    acceptedSubstrings: ["relaxing weekend", "have a great weekend", "good weekend", "nice weekend"],
    sampleAnswer: "I hope you have an incredibly relaxing and peaceful weekend!",
    hint: "Wish them a relaxing or great weekend.",
    explanation: "Weekend warm wishes are positive conversational closers."
  }
];

// Iterate through the quests and map the correct properties
data.quests.forEach((quest, index) => {
  const match = situationMapping[index % situationMapping.length];
  if (match) {
    quest.situationText = match.situationText;
    quest.sampleAnswer = match.sampleAnswer;
    // Store accepted substrings inside acceptedSynonyms (standard field in quest model)
    quest.acceptedSynonyms = match.acceptedSubstrings;
    quest.hint = match.hint;
    quest.explanation = match.explanation;
    quest.correctAnswer = match.acceptedSubstrings[0];
  }
});

fs.writeFileSync(filePath, JSON.stringify(data, null, 4), 'utf8');
console.log("Successfully enhanced 30 Situation Speaking curriculum quests!");
