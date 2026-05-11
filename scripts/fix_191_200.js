const fs = require('fs');

const data = JSON.parse(fs.readFileSync('./assets/curriculum/grammar/voiceSwap_191_200.json', 'utf8'));

// If it's already an object with quests, don't wrap. But it's an array.
if (Array.isArray(data)) {
  const quests = data.map((item, index) => {
    const isActiveToPassive = !item.explanation.includes('impersonal') && !item.activeSentence.includes('say that'); // rough heuristic
    const instruction = "Convert to passive voice.";
    const correct = item.passiveSentence;
    
    // Generate distractors
    const active = item.activeSentence;
    let distractor1 = correct.replace(/is /g, "are ").replace(/was /g, "were ").replace(/has /g, "have ");
    if (distractor1 === correct) distractor1 = correct.replace(/are /g, "is ").replace(/were /g, "was ").replace(/have /g, "has ");
    if (distractor1 === correct) distractor1 = correct.replace(/been /g, "being ");
    if (distractor1 === correct) distractor1 = correct.replace(/being /g, "been ");
    if (distractor1 === correct) distractor1 = correct + " (incorrect)";

    let distractor2 = correct.replace(/by /g, "from ").replace(/for /g, "to ");
    if (distractor2 === correct) distractor2 = correct.replace(/ed /g, "ing ");
    if (distractor2 === correct) distractor2 = "It " + correct.toLowerCase();

    let distractor3 = active;

    const options = [correct, distractor1, distractor2, distractor3];
    // Shuffle options
    const shuffled = [...options].sort(() => Math.random() - 0.5);
    const correctIndex = shuffled.indexOf(correct);

    // Difficulty 5
    const qLevel = item.level || (191 + Math.floor(index / 3));
    const qNum = (index % 3) + 1;
    const qId = `vs_l${qLevel}_q${qNum}`;

    return {
      id: qId,
      instruction: instruction,
      difficulty: 5,
      subtype: "voiceSwap",
      interactionType: "choice",
      question: active,
      options: shuffled,
      correctAnswerIndex: correctIndex,
      hint: item.tense,
      explanation: item.explanation,
      xpReward: qLevel * 2 + 100,
      coinReward: qLevel * 4 + 200,
      visual_config: { painter_type: item.visual_config, primary_color: "0xFF00FFCC" }
    };
  });

  const finalObj = {
    gameType: "voiceSwap",
    batchIndex: 20,
    levels: "191-200",
    quests: quests
  };

  fs.writeFileSync('./assets/curriculum/grammar/voiceSwap_191_200.json', JSON.stringify(finalObj, null, 2));
  console.log("Fixed voiceSwap_191_200.json");
} else {
  console.log("Already an object.");
}
