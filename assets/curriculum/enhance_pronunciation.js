const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'speaking', 'pronunciationFocus_1_10.json');

const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));

const phonemeMapping = [
  {
    textToSpeak: "A doctor launches the sensor cleverly.",
    targetPhoneme: "[r]",
    phoneticHint: "Accent the liquid sound [r] when saying 'doctor', 'sensor', and 'cleverly'.",
    hint: "Accent the liquid [r] sound.",
    explanation: "Vibrate your vocal cords and pull the tongue body back without touching the palate."
  },
  {
    textToSpeak: "The traveler launches the sensor cleverly.",
    targetPhoneme: "[v]",
    phoneticHint: "Vibrate your lower lip against upper teeth to produce the [v] sound in 'traveler' and 'cleverly'.",
    hint: "Focus on the [v] sound in traveler and cleverly.",
    explanation: "Vibrate your lower lip softly against your upper front teeth."
  },
  {
    textToSpeak: "A robot launches the sensor cleverly.",
    targetPhoneme: "[b]",
    phoneticHint: "Release a quick puff of air with both lips closed for the [b] in 'robot'.",
    hint: "Focus on the initial [b] in robot.",
    explanation: "Press both lips together tightly and release with a voice pulse."
  },
  {
    textToSpeak: "The commander receives a reactor flawlessly.",
    targetPhoneme: "[s]",
    phoneticHint: "Focus on the [s] sound in 'receives' and 'flawlessly'.",
    hint: "Focus on the [s] sound in receives and flawlessly.",
    explanation: "Direct a thin stream of air over the tongue tip held close to the front gum ridge."
  },
  {
    textToSpeak: "A scientist receives a reactor flawlessly.",
    targetPhoneme: "[t]",
    phoneticHint: "Focus on the sharp [t] sound in 'scientist' and 'reactor'.",
    hint: "Focus on the sharp [t] sound in scientist and reactor.",
    explanation: "Stop airflow by touching the tip of the tongue to the gum ridge, then release sharply."
  },
  {
    textToSpeak: "The engineer receives a reactor flawlessly.",
    targetPhoneme: "[i:]",
    phoneticHint: "Spread your lips wide for the long [i:] sound in 'engineer' and 'receives'.",
    hint: "Accentuate the long [i:] sound in engineer and receives.",
    explanation: "Spread your lips wide as if smiling, keeping the tongue high in the mouth."
  },
  {
    textToSpeak: "A robot configures a drone rapidly.",
    targetPhoneme: "[d]",
    phoneticHint: "Vocalize a quick buzz behind your upper teeth for the [d] in 'drone' and 'rapidly'.",
    hint: "Focus on the [d] sound in configures, drone, and rapidly.",
    explanation: "Tap your tongue tip against the alveolar ridge behind your upper teeth with a vocal buzz."
  },
  {
    textToSpeak: "The hero configures a drone rapidly.",
    targetPhoneme: "[h]",
    phoneticHint: "Exhale a soft puff of air through an open glottis without vibrating vocal cords for the [h] in 'hero'.",
    hint: "Focus on the initial breathy [h] in hero.",
    explanation: "Exhale a soft puff of air through an open glottis without vibrating vocal cords."
  },
  {
    textToSpeak: "A manager configures a drone rapidly.",
    targetPhoneme: "[dʒ]",
    phoneticHint: "Press the tongue tip against the front ridge, then release with friction for [dʒ] in 'manager'.",
    hint: "Focus on the soft [dʒ] sound in manager.",
    explanation: "Press the tongue tip against the front ridge, then release with a buzzing friction."
  },
  {
    textToSpeak: "The engineer sends the network immediately.",
    targetPhoneme: "[n]",
    phoneticHint: "Direct air through your nose for the resonant [n] sound in 'engineer', 'sends', and 'network'.",
    hint: "Focus on the resonant [n] sound in engineer, sends, and network.",
    explanation: "Let the air pass out of your nose while pressing the tongue tip against the top teeth ridge."
  },
  {
    textToSpeak: "A chef receives the network immediately.",
    targetPhoneme: "[ʃ]",
    phoneticHint: "Round your lips slightly and push air over the tongue for the voiceless [ʃ] sound in 'chef'.",
    hint: "Focus on the voiceless [ʃ] sound in chef.",
    explanation: "Round your lips slightly and push air through a wide channel over the tongue."
  },
  {
    textToSpeak: "The driver receives the network immediately.",
    targetPhoneme: "[v]",
    phoneticHint: "Vibrate your lower lip softly for the [v] sound in 'driver'.",
    hint: "Vibrate your lower lip for the [v] sound in driver.",
    explanation: "Friction sound made by touching top teeth to lower lip with vocal cord vibration."
  },
  {
    textToSpeak: "A manager tests the battery carefully.",
    targetPhoneme: "[æ]",
    phoneticHint: "Open your mouth wide and keep the tongue low for the short [æ] sound in 'manager' and 'battery'.",
    hint: "Focus on the flat short [æ] sound in manager and battery.",
    explanation: "Open your mouth wide and keep the tongue low in the front of your mouth."
  },
  {
    textToSpeak: "The analyst tests the battery carefully.",
    targetPhoneme: "[l]",
    phoneticHint: "Let air flow laterally around your tongue for the [l] sound in 'analyst' and 'carefully'.",
    hint: "Focus on the clear [l] sound in analyst and carefully.",
    explanation: "Place the tip of the tongue on the top teeth ridge, letting air flow out the sides."
  },
  {
    textToSpeak: "A student tests the battery carefully.",
    targetPhoneme: "[u:]",
    phoneticHint: "Pucker your lips tightly into a circle for the tense rounded [u:] in 'student'.",
    hint: "Accentuate the tense rounded [u:] in student.",
    explanation: "Pucker your lips tightly into a small circle, keeping the tongue high and back."
  },
  {
    textToSpeak: "The driver sends the portal wisely.",
    targetPhoneme: "[p]",
    phoneticHint: "Close both lips tightly and release a puff of silent air for the [p] in 'portal'.",
    hint: "Accent the voiceless plosive [p] in portal.",
    explanation: "Close both lips tightly, stop air completely, then release with a silent puff."
  },
  {
    textToSpeak: "A spy sends the portal wisely.",
    targetPhoneme: "[aɪ]",
    phoneticHint: "Glide your mouth smoothly from [a] to [ɪ] for the diphthong [aɪ] in 'spy' and 'wisely'.",
    hint: "Accentuate the gliding diphthong [aɪ] in spy and wisely.",
    explanation: "Glide your mouth smoothly from an open sound [a] to a high-front vowel [ɪ]."
  },
  {
    textToSpeak: "The detective sends the portal wisely.",
    targetPhoneme: "[e]",
    phoneticHint: "Keep your mouth halfway open for the short neutral [e] sound in 'detective' and 'sends'.",
    hint: "Focus on the short [e] sound in detective and sends.",
    explanation: "Keep your mouth halfway open and tongue forward to make a short neutral vowel."
  },
  {
    textToSpeak: "A student builds a spaceship swiftly.",
    targetPhoneme: "[ɪ]",
    phoneticHint: "Produce a quick, relaxed short [ɪ] sound in 'builds', 'spaceship', and 'swiftly'.",
    hint: "Focus on the crisp short [ɪ] sound in builds, spaceship, and swiftly.",
    explanation: "Keep the mouth slightly open and lips relaxed, producing a quick, clean sound."
  },
  {
    textToSpeak: "The droid builds a spaceship swiftly.",
    targetPhoneme: "[z]",
    phoneticHint: "Vibrate your vocal cords to produce a high buzz for [z] in 'builds'.",
    hint: "Focus on the buzzing [z] sound in builds.",
    explanation: "Produce a high-pitch friction buzz by passing air over the tongue tip held near top teeth."
  },
  {
    textToSpeak: "An explorer builds a spaceship swiftly.",
    targetPhoneme: "[ks]",
    phoneticHint: "Release a quick back [k] stop immediately sliding into [s] for the [ks] in 'explorer'.",
    hint: "Crisply release the double sound [ks] in explorer.",
    explanation: "Make a quick [k] stop in the back of the mouth, immediately sliding into a sharp [s]."
  },
  {
    textToSpeak: "The detective discovers a satellite steadily.",
    targetPhoneme: "[ʌ]",
    phoneticHint: "Drop your jaw slightly for the short central [ʌ] in 'discovers'.",
    hint: "Focus on the short central [ʌ] sound in discovers.",
    explanation: "Keep your jaw dropped slightly and tongue resting flat in the center of the mouth."
  },
  {
    textToSpeak: "A researcher discovers a satellite steadily.",
    targetPhoneme: "[ɜ:]",
    phoneticHint: "Accentuate the r-colored central vowel [ɜ:] in 'researcher'.",
    hint: "Accentuate the colored central [ɜ:] sound in researcher.",
    explanation: "Keep your tongue in a neutral center position, curled slightly up for r-coloring."
  },
  {
    textToSpeak: "The teacher discovers a satellite steadily.",
    targetPhoneme: "[tʃ]",
    phoneticHint: "Release a quiet alveolar stop into fricative postalveolar air for [tʃ] in 'teacher'.",
    hint: "Focus on the quick stop-friction [tʃ] in teacher.",
    explanation: "Start with a quiet [t] sound behind top teeth, immediately exploding into a soft [ʃ]."
  },
  {
    textToSpeak: "An explorer monitors the data cautiously.",
    targetPhoneme: "[ɔ:]",
    phoneticHint: "Round your lips slightly for the deep back vowel [ɔ:] in 'cautiously'.",
    hint: "Vocalize the deep long vowel [ɔ:] in cautiously.",
    explanation: "Slightly round your lips and draw the tongue back and down in the throat."
  },
  {
    textToSpeak: "The technician monitors the data cautiously.",
    targetPhoneme: "[ʃ]",
    phoneticHint: "Direct broad friction air over the tongue for the [ʃ] in 'technician' and 'cautiously'.",
    hint: "Hiss air softly for the [ʃ] sound in technician and cautiously.",
    explanation: "Direct a broad stream of air through rounded lips over the front-middle tongue."
  },
  {
    textToSpeak: "A pilot monitors the data cautiously.",
    targetPhoneme: "[ɒ]",
    phoneticHint: "Drop your jaw wide for the short open back vowel [ɒ] in 'monitors'.",
    hint: "Focus on the short open back vowel [ɒ] in monitors.",
    explanation: "Drop your jaw wide, keeping lips very slightly rounded and tongue low."
  },
  {
    textToSpeak: "A student repairs the database gently.",
    targetPhoneme: "[dʒ]",
    phoneticHint: "Release a quick alveolar stop into a buzzing fricative postalveolar sound for [dʒ] in 'gently'.",
    hint: "Vibrate your vocal cords for the [dʒ] sound in gently.",
    explanation: "Stop airflow with tongue tip on upper ridge, releasing into a buzzy friction."
  },
  {
    textToSpeak: "The analyst repairs the database gently.",
    targetPhoneme: "[eɪ]",
    phoneticHint: "Slide from [e] to [ɪ] in one smooth breath for the long diphthong [eɪ] in 'database'.",
    hint: "Accentuate the long gliding [eɪ] in database.",
    explanation: "Slide the vowel sound from a mid-front [e] to a high relaxed [ɪ] in one smooth breath."
  },
  {
    textToSpeak: "A manager repairs the database gently.",
    targetPhoneme: "[eə]",
    phoneticHint: "Slide from [e] smoothly into a neutral schwa [ə] for the centering diphthong [eə] in 'repairs'.",
    hint: "Vocalize the open gliding diphthong [eə] in repairs.",
    explanation: "Slide the front vowel [e] smoothly down into a neutral central unstressed schwa [ə]."
  }
];

// Iterate through the quests and map the correct properties based on textToSpeak
data.quests.forEach((quest, index) => {
  const match = phonemeMapping.find(m => m.textToSpeak.trim().toLowerCase() === quest.textToSpeak.trim().toLowerCase());
  if (match) {
    quest.targetPhoneme = match.targetPhoneme;
    quest.phoneticHint = match.phoneticHint;
    quest.hint = match.hint;
    quest.explanation = match.explanation;
  }
});

fs.writeFileSync(filePath, JSON.stringify(data, null, 4), 'utf8');
console.log("Successfully enhanced 30 Pronunciation Focus curriculum quests!");
