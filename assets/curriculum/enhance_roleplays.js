const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'speaking', 'dialogueRoleplay_1_10.json');

const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));

const roleplayMapping = [
  {
    partnerDialogue: "Welcome to Organic Bistro! Are you ready to order, or do you need a few more minutes with the menu?",
    sampleAnswer: "I am ready! I would like to order a fresh avocado salad and a glass of sparkling water, please.",
    acceptedSynonyms: [
      "avocado salad",
      "sparkling water",
      "order a salad",
      "fresh salad"
    ],
    hint: "Politely request the avocado salad and a sparkling water.",
    explanation: "Ordering food politely with detailed preferences prepares you for smooth real-world dining scenarios."
  },
  {
    partnerDialogue: "Hello! Welcome to the Grand Horizon Hotel. How can I assist you with your stay today?",
    sampleAnswer: "Hi! I would like to check in under the name of John Smith. I have a reservation for three nights.",
    acceptedSynonyms: [
      "check in",
      "john smith",
      "have a reservation",
      "reservation"
    ],
    hint: "State that you want to check in under John Smith.",
    explanation: "Confirming check-in details confidently at a front desk ensures a hassle-free lodging experience."
  },
  {
    partnerDialogue: "Next customer please! Hi, where are you travelling to today and would you like a one-way or round-trip ticket?",
    sampleAnswer: "I would like a round-trip ticket to London, please. I am returning tomorrow evening.",
    acceptedSynonyms: [
      "round trip",
      "to london",
      "ticket to london",
      "round-trip ticket"
    ],
    hint: "Request a round-trip ticket to London.",
    explanation: "Buying transport tickets with clear destination and return parameters helps navigate foreign transit."
  },
  {
    partnerDialogue: "Good morning. What seems to be the problem today, and how long have you felt this way?",
    sampleAnswer: "I have a really bad sore throat and a mild headache. It started two days ago.",
    acceptedSynonyms: [
      "sore throat",
      "headache",
      "bad throat",
      "mild headache"
    ],
    hint: "Explain your throat irritation and headache timeline.",
    explanation: "Describing medical symptoms precisely enables doctors to provide accurate diagnostic treatment."
  },
  {
    partnerDialogue: "Luggage claims office, how can I help you? Did you arrive on the flight from Paris?",
    sampleAnswer: "Yes, I was on the Paris flight. My black leather suitcase is missing and has not arrived on the belt.",
    acceptedSynonyms: [
      "suitcase is missing",
      "suitcase has not arrived",
      "black suitcase",
      "leather suitcase"
    ],
    hint: "Confirm you were on the Paris flight and report the missing suitcase.",
    explanation: "Filing luggage complaints with color and material descriptions guarantees faster baggage tracing."
  },
  {
    partnerDialogue: "Hi! Thanks for dropping by my office. What did you want to discuss regarding the upcoming semester syllabus?",
    sampleAnswer: "I wanted to ask if we could schedule a short extension for the research paper deadline.",
    acceptedSynonyms: [
      "extension",
      "research paper",
      "paper deadline",
      "schedule an extension"
    ],
    hint: "Ask if you can get a brief extension on the research paper.",
    explanation: "Negotiating academic deadlines politely with professors highlights professional communication skills."
  },
  {
    partnerDialogue: "Wow, I cannot believe we finally finished this massive software migration project on time!",
    sampleAnswer: "Congratulations to the whole team! You all did an incredible job coordinating the server nodes.",
    acceptedSynonyms: [
      "congratulations",
      "incredible job",
      "great job",
      "congratulate"
    ],
    hint: "Express warm congratulations and highlight the team's coordination.",
    explanation: "Praising coworkers on key business achievements strengthens corporate team bonds."
  },
  {
    partnerDialogue: "Excuse me, I seem to be completely lost. Could you point me towards the nearest subway station entrance?",
    sampleAnswer: "Sure! Just walk straight down this street for two blocks, and the station will be on your left.",
    acceptedSynonyms: [
      "walk straight",
      "two blocks",
      "on your left",
      "station is on"
    ],
    hint: "Direct them to walk straight for two blocks, indicating the station is on the left.",
    explanation: "Giving clear spatial directions using landmarks helps build confident leadership speech."
  },
  {
    partnerDialogue: "Vogue Apparel returns counter. Do you have the original receipt for this purchase?",
    sampleAnswer: "Yes, here is the receipt. I would like to return this shirt because it has a small tear near the collar.",
    acceptedSynonyms: [
      "return this shirt",
      "return shirt",
      "small tear",
      "here is the receipt"
    ],
    hint: "Present the receipt and explain you want to return the shirt due to a tear.",
    explanation: "Executing retail returns with clear product defect explanations ensures quick store refunds."
  },
  {
    partnerDialogue: "Golden Dragon Reservations. How many people will be dining, and what time should we hold the table?",
    sampleAnswer: "We need a table for four people tonight at eight o'clock. Could we get a table by the window?",
    acceptedSynonyms: [
      "table for four",
      "at eight",
      "by the window",
      "window table"
    ],
    hint: "Request a table for four at 8:00 PM and specify you want it next to the window.",
    explanation: "Securing restaurant bookings with concrete time and window seating requests refines daily social planning."
  }
];

// Iterate through the quests and map the correct properties
data.quests.forEach((quest, index) => {
  const match = roleplayMapping[index % roleplayMapping.length];
  if (match) {
    quest.partnerDialogue = match.partnerDialogue;
    quest.sampleAnswer = match.sampleAnswer;
    quest.acceptedSynonyms = match.acceptedSynonyms;
    quest.hint = match.hint;
    quest.explanation = match.explanation;
    quest.correctAnswer = match.sampleAnswer;
  }
});

fs.writeFileSync(filePath, JSON.stringify(data, null, 4), 'utf8');
console.log("Successfully enhanced 30 Dialogue Roleplay curriculum quests!");
