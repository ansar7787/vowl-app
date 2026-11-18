const fs = require('fs');
const path = require('path');

const curriculumDir = path.join(__dirname, '..', 'assets', 'curriculum', 'speaking');

console.log('Starting PronunciationFocus 3-phase curriculum generation...');

// Step 1: Process all 20 batches (levels 1-10 through 191-200)
for (let b = 1; b <= 20; b++) {
  const startLevel = (b - 1) * 10 + 1;
  const endLevel = b * 10;
  const legacyFile = path.join(curriculumDir, `pronunciationFocus_${startLevel}_${endLevel}.json`);

  if (!fs.existsSync(legacyFile)) {
    console.error(`Error: Legacy file missing: ${legacyFile}`);
    process.exit(1);
  }

  const legacyData = JSON.parse(fs.readFileSync(legacyFile, 'utf8'));
  const quests = legacyData.quests || [];

  // 1a. Generate Mastery file
  const masteryData = {
    gameType: 'pronunciationFocus',
    phase: 'mastery',
    batchIndex: b,
    levels: `${startLevel}-${endLevel}`,
    quests: quests.map(q => ({
      ...q,
      phase: 'mastery'
    }))
  };
  const masteryFile = path.join(curriculumDir, `pronunciationFocus_mastery_${startLevel}_${endLevel}.json`);
  fs.writeFileSync(masteryFile, JSON.stringify(masteryData, null, 2), 'utf8');

  // 1b. Generate Learn file
  const learnQuests = quests.map((q, idx) => {
    const levelMatch = (q.id || '').match(/_L(\d+)_Q(\d+)/);
    const lvl = levelMatch ? levelMatch[1] : `${startLevel + Math.floor(idx / 3)}`;
    const qnum = levelMatch ? levelMatch[2] : `${(idx % 3) + 1}`;
    const phoneme = (q.targetPhoneme || '[sound]').trim();

    return {
      id: `SPK_PRONUNCIATIONFOCUS_LEARN_L${lvl}_Q${qnum}`,
      phase: 'learn',
      instruction: 'Study the target sound, articulatory positioning, and acoustic distinction.',
      targetPhoneme: phoneme,
      textToSpeak: q.textToSpeak || '',
      phoneticHint: q.phoneticHint || '',
      articulatoryPlacement: q.explanation || '',
      hint: q.hint || '',
      commonMistakes: q.commonMistakes || [],
      phoneticGuide: `Articulate '${phoneme}' cleanly with correct vocal fold resonance and tongue posture.`,
      connectedSpeechTip: 'Keep the sound natural and fluid when embedded within complete sentences.'
    };
  });

  const learnData = {
    gameType: 'pronunciationFocus',
    phase: 'learn',
    batchIndex: b,
    levels: `${startLevel}-${endLevel}`,
    quests: learnQuests
  };
  const learnFile = path.join(curriculumDir, `pronunciationFocus_learn_${startLevel}_${endLevel}.json`);
  fs.writeFileSync(learnFile, JSON.stringify(learnData, null, 2), 'utf8');

  // 1c. Generate Practice file
  const practiceQuests = quests.map((q, idx) => {
    const levelMatch = (q.id || '').match(/_L(\d+)_Q(\d+)/);
    const lvl = levelMatch ? levelMatch[1] : `${startLevel + Math.floor(idx / 3)}`;
    const qnum = levelMatch ? levelMatch[2] : `${(idx % 3) + 1}`;
    const phoneme = (q.targetPhoneme || '[sound]').trim();
    const textToSpeak = q.textToSpeak || '';

    // Create a concise summary of the explanation for Option 0 (Correct)
    let summaryExpl = q.explanation || 'Proper mouth and tongue positioning';
    // Clean trailing periods or simplify first clause
    const firstPeriod = summaryExpl.indexOf('.');
    if (firstPeriod > 20 && firstPeriod < 120) {
      summaryExpl = summaryExpl.substring(0, firstPeriod).trim();
    }

    const correctOpt = `${summaryExpl} (Correct: Accurately articulates the ${phoneme} target sound)`;

    // Extract mistakes or fallback articulatory traps
    const mistakes = q.commonMistakes || [];
    let d1 = mistakes[0] || 'Vocalizing without adequate airflow release';
    let d2 = mistakes[1] || 'Improper tongue contact against the palate';
    let d3 = mistakes[2] || 'Distorting vowel duration around the consonant boundary';

    // Ensure distractors are distinct
    if (d1 === d2) d2 = 'Confusing voiced vibration with voiceless aspiration';
    if (d3 === d1 || d3 === d2) d3 = 'Incomplete closure distorting the phonetic boundary';

    const dist1Opt = `${d1} (Incorrect: Common pronunciation error)`;
    const dist2Opt = `${d2} (Incorrect: Flawed articulatory mechanics)`;
    const dist3Opt = `${d3} (Incorrect: Distorts acoustic precision)`;

    const options = [correctOpt, dist1Opt, dist2Opt, dist3Opt];

    const distractorFeedback = {};
    distractorFeedback[dist1Opt] = `Avoid this error: "${d1}". Focus on: ${q.hint || q.explanation}`;
    distractorFeedback[dist2Opt] = `Incorrect technique: "${d2}". Correct technique: ${q.explanation}`;
    distractorFeedback[dist3Opt] = `Acoustic distortion: "${d3}". Phonetic guide: ${q.phoneticHint || q.hint}`;

    return {
      id: `SPK_PRONUNCIATIONFOCUS_PRAC_L${lvl}_Q${qnum}`,
      phase: 'practice',
      instruction: 'Identify the correct articulatory mechanics and acoustic feature for the target sound.',
      targetPhoneme: phoneme,
      textToSpeak: textToSpeak,
      question: `Which articulatory description correctly produces the target sound ${phoneme} in: "${textToSpeak}"?`,
      options: options,
      correctIndex: 0,
      correctAnswer: correctOpt,
      hint: q.hint || '',
      explanation: `${phoneme}: ${q.explanation}`,
      phoneticHint: q.phoneticHint || '',
      distractorFeedback: distractorFeedback
    };
  });

  const practiceData = {
    gameType: 'pronunciationFocus',
    phase: 'practice',
    batchIndex: b,
    levels: `${startLevel}-${endLevel}`,
    quests: practiceQuests
  };
  const practiceFile = path.join(curriculumDir, `pronunciationFocus_practice_${startLevel}_${endLevel}.json`);
  fs.writeFileSync(practiceFile, JSON.stringify(practiceData, null, 2), 'utf8');

  console.log(`Batch ${b} (${startLevel}-${endLevel}) generated: mastery, learn, practice.`);
}

// Step 2: Delete all 20 unphased legacy files
console.log('Purging 20 unphased legacy files...');
for (let b = 1; b <= 20; b++) {
  const startLevel = (b - 1) * 10 + 1;
  const endLevel = b * 10;
  const legacyFile = path.join(curriculumDir, `pronunciationFocus_${startLevel}_${endLevel}.json`);
  if (fs.existsSync(legacyFile)) {
    fs.unlinkSync(legacyFile);
    console.log(`Deleted legacy: pronunciationFocus_${startLevel}_${endLevel}.json`);
  }
}

console.log('PronunciationFocus curriculum processing complete.');
