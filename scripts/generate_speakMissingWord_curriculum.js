const fs = require('fs');
const path = require('path');

const curriculumDir = path.join(__dirname, '..', 'assets', 'curriculum', 'speaking');

console.log('Starting SpeakMissingWord 3-phase curriculum generation...');

// Step 1: Process all 20 batches
for (let b = 1; b <= 20; b++) {
  const startLevel = (b - 1) * 10 + 1;
  const endLevel = b * 10;
  const legacyFile = path.join(curriculumDir, `speakMissingWord_${startLevel}_${endLevel}.json`);

  if (!fs.existsSync(legacyFile)) {
    console.error(`Error: Legacy file missing: ${legacyFile}`);
    process.exit(1);
  }

  const legacyData = JSON.parse(fs.readFileSync(legacyFile, 'utf8'));
  const quests = legacyData.quests || [];

  // Extract all missing words in this batch for distractor pooling
  const batchWords = quests.map(q => (q.missingWord || '').trim()).filter(w => w.length > 0);

  // 1a. Generate Mastery file
  const masteryData = {
    gameType: 'speakMissingWord',
    phase: 'mastery',
    batchIndex: b,
    levels: `${startLevel}-${endLevel}`,
    quests: quests.map(q => ({
      ...q,
      phase: 'mastery'
    }))
  };
  const masteryFile = path.join(curriculumDir, `speakMissingWord_mastery_${startLevel}_${endLevel}.json`);
  fs.writeFileSync(masteryFile, JSON.stringify(masteryData, null, 2), 'utf8');

  // 1b. Generate Learn file
  const learnQuests = quests.map((q, idx) => {
    const levelMatch = (q.id || '').match(/_L(\d+)_Q(\d+)/);
    const lvl = levelMatch ? levelMatch[1] : `${startLevel + Math.floor(idx / 3)}`;
    const qnum = levelMatch ? levelMatch[2] : `${(idx % 3) + 1}`;
    const word = (q.missingWord || '').trim();

    return {
      id: `SPK_SPEAKMISSINGWORD_LEARN_L${lvl}_Q${qnum}`,
      phase: 'learn',
      instruction: 'Study the context clue, discover the missing word, and practice oral articulation.',
      textWithBlank: q.textToSpeak || '',
      missingWord: word,
      completeSentence: q.correctAnswer || '',
      contextClue: q.contextClue || '',
      hint: q.hint || '',
      explanation: q.explanation || '',
      phoneticGuide: `Articulate '${word}' clearly with accurate syllable stress and steady oral projection.`,
      articulationTip: `Connect '${word}' smoothly with the surrounding words to maintain natural spoken tempo.`
    };
  });

  const learnData = {
    gameType: 'speakMissingWord',
    phase: 'learn',
    batchIndex: b,
    levels: `${startLevel}-${endLevel}`,
    quests: learnQuests
  };
  const learnFile = path.join(curriculumDir, `speakMissingWord_learn_${startLevel}_${endLevel}.json`);
  fs.writeFileSync(learnFile, JSON.stringify(learnData, null, 2), 'utf8');

  // 1c. Generate Practice file
  const practiceQuests = quests.map((q, idx) => {
    const levelMatch = (q.id || '').match(/_L(\d+)_Q(\d+)/);
    const lvl = levelMatch ? levelMatch[1] : `${startLevel + Math.floor(idx / 3)}`;
    const qnum = levelMatch ? levelMatch[2] : `${(idx % 3) + 1}`;
    const word = (q.missingWord || '').trim();

    // Select 3 distractors from batchWords that don't match word
    const candidates = batchWords.filter(w => w.toLowerCase() !== word.toLowerCase());
    // Deterministic selection based on index so it is consistent and varied
    const d1 = candidates[(idx + 1) % candidates.length] || 'item';
    const d2 = candidates[(idx + 7) % candidates.length] || 'sound';
    const d3 = candidates[(idx + 13) % candidates.length] || 'action';

    const correctOpt = `${word} (Correct: Accurately completes the situational context)`;
    const dist1Opt = `${d1} (Incorrect: Does not fit the situational premise)`;
    const dist2Opt = `${d2} (Incorrect: Incompatible with the sentence meaning)`;
    const dist3Opt = `${d3} (Incorrect: Creates an illogical statement in this context)`;

    const options = [correctOpt, dist1Opt, dist2Opt, dist3Opt];

    const distractorFeedback = {};
    distractorFeedback[dist1Opt] = `"${d1}" does not fit the context: ${q.contextClue || q.hint}`;
    distractorFeedback[dist2Opt] = `"${d2}" contradicts the logical meaning of this sentence.`;
    distractorFeedback[dist3Opt] = `"${d3}" is semantically incompatible with the action described.`;

    return {
      id: `SPK_SPEAKMISSINGWORD_PRAC_L${lvl}_Q${qnum}`,
      phase: 'practice',
      instruction: 'Select the word that accurately completes the context and exhibits correct oral collocation.',
      textWithBlank: q.textToSpeak || '',
      question: `Which word correctly fills the blank in: "${q.textToSpeak}"?`,
      options: options,
      correctIndex: 0,
      correctAnswer: correctOpt,
      hint: q.hint || '',
      explanation: `${word}: ${q.explanation || ''}`,
      contextClue: q.contextClue || '',
      distractorFeedback: distractorFeedback
    };
  });

  const practiceData = {
    gameType: 'speakMissingWord',
    phase: 'practice',
    batchIndex: b,
    levels: `${startLevel}-${endLevel}`,
    quests: practiceQuests
  };
  const practiceFile = path.join(curriculumDir, `speakMissingWord_practice_${startLevel}_${endLevel}.json`);
  fs.writeFileSync(practiceFile, JSON.stringify(practiceData, null, 2), 'utf8');

  console.log(`Generated batch ${b} (${startLevel}-${endLevel})`);
}

// Step 2: Purge legacy files
console.log('Purging legacy unphased files...');
for (let b = 1; b <= 20; b++) {
  const startLevel = (b - 1) * 10 + 1;
  const endLevel = b * 10;
  const legacyFile = path.join(curriculumDir, `speakMissingWord_${startLevel}_${endLevel}.json`);
  if (fs.existsSync(legacyFile)) {
    fs.unlinkSync(legacyFile);
    console.log(`Purged legacy: ${path.basename(legacyFile)}`);
  }
}

// Step 3: Verification
const allFiles = fs.readdirSync(curriculumDir);
const smwFiles = allFiles.filter(f => f.startsWith('speakMissingWord'));
const learnFiles = smwFiles.filter(f => f.startsWith('speakMissingWord_learn_'));
const practiceFiles = smwFiles.filter(f => f.startsWith('speakMissingWord_practice_'));
const masteryFiles = smwFiles.filter(f => f.startsWith('speakMissingWord_mastery_'));
const legacyRemaining = smwFiles.filter(f => !f.includes('_learn_') && !f.includes('_practice_') && !f.includes('_mastery_'));

console.log('\n--- VERIFICATION SUMMARY ---');
console.log(`Total speakMissingWord files: ${smwFiles.length} (Expected: 60)`);
console.log(`Learn files: ${learnFiles.length} (Expected: 20)`);
console.log(`Practice files: ${practiceFiles.length} (Expected: 20)`);
console.log(`Mastery files: ${masteryFiles.length} (Expected: 20)`);
console.log(`Legacy remaining: ${legacyRemaining.length} (Expected: 0)`);

if (smwFiles.length === 60 && learnFiles.length === 20 && practiceFiles.length === 20 && masteryFiles.length === 20 && legacyRemaining.length === 0) {
  console.log('✅ CURRICULUM ARCHITECTURE VERIFIED 100% SUCCEEDED!');
} else {
  console.error('❌ VERIFICATION FAILED!');
  process.exit(1);
}
