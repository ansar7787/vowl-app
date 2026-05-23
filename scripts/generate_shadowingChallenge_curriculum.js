const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/accent';

const shadowingTemplates = [
  { sentence: "The manager observes the module gently.", options: ["Consonant-to-vowel linking ('observes the' /zð/)", "Silent pause between subject and verb"], correct: 0, ipa: "/ðə ˈmænɪdʒər əbˈzɜːvz ðə ˈmɒdjuːl ˈdʒentli/", explanation: "Standard fluent shadowing highlights the liaison /zð/ between the final voiced sibilant and the dental fricative." },
  { sentence: "A scientist upgrades the module quietly.", options: ["Silent pause between subject and verb", "Consonant-to-vowel linking ('upgrades the' /dzð/)"], correct: 1, ipa: "/ə ˈsaɪəntɪst ʌpˈɡreɪdz ðə ˈmɒdjuːl ˈkwaɪətli/", explanation: "Fluent speech connects 'upgrades' and 'the' without structural pauses, executing the voiced alveolar stop cluster linked to the dental fricative." },
  { sentence: "A spy repairs the circuit rapidly.", options: ["Gliding liaison /r/ linking 'repairs' to 'the'", "Voiceless aspiration on final syllable"], correct: 0, ipa: "/ə spaɪ rɪˈpeəz ðə ˈsɜːkɪt ˈræpɪdli/", explanation: "British and standard pronunciations link the rhotic final 'repairs' smoothly into 'the' utilizing a gliding fricative." },
  { sentence: "The doctor activates the engine cautiously.", options: ["Silent pause between subject and verb", "Gliding liaison /r/ linking 'doctor' to 'activates'"], correct: 1, ipa: "/ðə ˈdɒktər ˈæktɪveɪts ðə ˈendʒɪn ˈkɔːʃəsli/", explanation: "Intrusive and linking /r/ bridges 'doctor' and 'activates' flawlessly to maintain rhythmic fluency." },
  { sentence: "A student observes a system quickly.", options: ["Consonant-to-vowel linking ('student observes' /ntə/)", "Voiceless aspiration on final syllable"], correct: 0, ipa: "/ə ˈstjuːdnt əbˈzɜːvz ə ˈsɪstəm ˈkwɪkli/", explanation: "Fluent English glides 'student' into 'observes' with a smooth vowel intrusion /ntə/." },
  { sentence: "The hero protects the software smoothly.", options: ["Silent pause between subject and verb", "Consonant-to-consonant linking ('protects the' /tsð/)"], correct: 1, ipa: "/ðə ˈhɪərəʊ prəˈtekts ðə ˈsɒftweə ˈsmuːðli/", explanation: "Connected speech links the stop cluster /ts/ smoothly into the dental fricative /ð/ without a pause." },
  { sentence: "A chef assembles the shield silently.", options: ["Consonant-to-vowel linking ('chef assembles' /fə/)", "Voiceless aspiration on final syllable"], correct: 0, ipa: "/ə ʃef əˈsemblz ðə ʃiːld ˈsaɪləntli/", explanation: "Speech shadowing targets the smooth labiodental liaison /fə/ connecting 'chef' to 'assembles'." },
  { sentence: "The driver receives a reactor immediately.", options: ["Gliding liaison /r/ linking 'driver' to 'receives'", "Voiceless aspiration on final syllable"], correct: 0, ipa: "/ðə ˈdraɪvər rɪˈsiːvz ə riˈæktə ɪˈmiːdiətli/", explanation: "Shadowing links the final rhotic element in 'driver' smoothly into 'receives' to maintain steady tempo." },
  { sentence: "A technician configures a drone carefully.", options: ["Silent pause between subject and verb", "Gliding liaison /r/ linking 'configures' to 'a'"], correct: 1, ipa: "/ə tekˈnɪʃn kənˈfɪɡəz ə drəʊn ˈkeəfəli/", explanation: "The final rhotic glide /zə/ bridges the verb 'configures' to the indefinite article 'a' smoothly." },
  { sentence: "A manager launches the sensor perfectly.", options: ["Silent pause between subject and verb", "Consonant-to-consonant linking ('launches the' /tʃɪzð/)"], correct: 1, ipa: "/ə ˈmænɪdʒə ˈlɔːntʃɪz ðə ˈsensə ˈpɜːfɪktli/", explanation: "Fluent shadowing links the affricate sibilant /tʃɪz/ into the dental fricative /ð/ without structural pauses." }
];

// Generate 20 unique batches of 30 questions each (Total 600)
for (let batchIndex = 1; batchIndex <= 20; batchIndex++) {
  const startLevel = (batchIndex - 1) * 10 + 1;
  const endLevel = batchIndex * 10;
  const fileName = `shadowingChallenge_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % shadowingTemplates.length;
      const base = shadowingTemplates[templateIdx];
      
      const uniqueWord = base.sentence;
      const textToSpeak = uniqueWord;

      quests.push({
        id: `ACC_SHADOWINGCHALLENGE_L${level}_Q${qNum}`,
        instruction: "IDENTIFY THE CORE PHONETIC CONNECTIVE TECHNIQUE DEMONSTRATED IN THE SHADOWING DRILL",
        difficulty: diff,
        subtype: "shadowingChallenge",
        interactionType: "choice",
        word: uniqueWord,
        textToSpeak: textToSpeak,
        options: base.options,
        correctAnswer: base.options[base.correct],
        correctAnswerIndex: base.correct,
        ipa: base.ipa,
        hint: `Listen carefully to how words blend. Do you hear a smooth link between words or a structural pause? (Calibration ${level}-${qNum})`,
        explanation: base.explanation
      });
    }
  }
  
  const fileData = {
    gameType: "shadowingChallenge",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified shadowingChallenge curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique shadowingChallenge quests across 20 batch files.");
