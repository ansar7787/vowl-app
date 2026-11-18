const fs = require('fs');
const path = require('path');

const curriculumDir = path.join(__dirname, '..', 'assets', 'curriculum', 'speaking');

console.log('Starting DialogueRoleplay 3-phase curriculum generation...');

const fallbackDistractors = [
  'I am not quite sure what you mean by that.',
  'Could you please repeat that more slowly?',
  'That sounds good to me, thank you.',
  'I will check my schedule and get back to you.',
  'Sorry, I have to run to another meeting now.',
  'It depends on the circumstances, actually.'
];

// Step 1: Process all 20 batches (levels 1-10 through 191-200)
for (let b = 1; b <= 20; b++) {
  const startLevel = (b - 1) * 10 + 1;
  const endLevel = b * 10;
  const legacyFile = path.join(curriculumDir, `dialogueRoleplay_${startLevel}_${endLevel}.json`);

  if (!fs.existsSync(legacyFile)) {
    console.error(`Error: Legacy file missing: ${legacyFile}`);
    process.exit(1);
  }

  const legacyData = JSON.parse(fs.readFileSync(legacyFile, 'utf8'));
  const quests = legacyData.quests || [];

  // 1a. Generate Mastery file
  const masteryData = {
    gameType: 'dialogueRoleplay',
    phase: 'mastery',
    batchIndex: b,
    levels: `${startLevel}-${endLevel}`,
    quests: quests.map(q => ({
      ...q,
      phase: 'mastery'
    }))
  };
  const masteryFile = path.join(curriculumDir, `dialogueRoleplay_mastery_${startLevel}_${endLevel}.json`);
  fs.writeFileSync(masteryFile, JSON.stringify(masteryData, null, 2), 'utf8');

  // 1b. Generate Learn file
  const learnQuests = quests.map((q, idx) => {
    const levelMatch = (q.id || '').match(/_L(\d+)_Q(\d+)/);
    const lvl = levelMatch ? levelMatch[1] : `${startLevel + Math.floor(idx / 3)}`;
    const qnum = levelMatch ? levelMatch[2] : `${(idx % 3) + 1}`;
    const sampleAns = (q.sampleAnswer || q.correctAnswer || '').trim();

    return {
      id: `SPK_DIALOGUEROLEPLAY_LEARN_L${lvl}_Q${qnum}`,
      phase: 'learn',
      partnerDialogue: q.partnerDialogue || '',
      instruction: q.instruction || 'Practice natural conversational turn-taking and responsive timing.',
      sampleAnswer: sampleAns,
      smartReplies: q.smartReplies || [sampleAns],
      explanation: q.explanation || '',
      hint: q.hint || '',
      emotionTag: q.emotionTag || 'Neutral',
      rhythmAdvice: 'Listen to the partner line carefully, observe the communicative goal, and reply naturally with matched tone and cadence.'
    };
  });

  const learnData = {
    gameType: 'dialogueRoleplay',
    phase: 'learn',
    batchIndex: b,
    levels: `${startLevel}-${endLevel}`,
    quests: learnQuests
  };
  const learnFile = path.join(curriculumDir, `dialogueRoleplay_learn_${startLevel}_${endLevel}.json`);
  fs.writeFileSync(learnFile, JSON.stringify(learnData, null, 2), 'utf8');

  // 1c. Generate Practice file
  const practiceQuests = quests.map((q, idx) => {
    const levelMatch = (q.id || '').match(/_L(\d+)_Q(\d+)/);
    const lvl = levelMatch ? levelMatch[1] : `${startLevel + Math.floor(idx / 3)}`;
    const qnum = levelMatch ? levelMatch[2] : `${(idx % 3) + 1}`;
    const correctAns = (q.sampleAnswer || q.correctAnswer || '').trim();
    const partnerDialogue = q.partnerDialogue || '';
    const explanation = q.explanation || '';

    const distractors = [];
    for (let offset = 1; offset < quests.length && distractors.length < 3; offset++) {
      const other = quests[(idx + offset) % quests.length];
      const otherAns = (other.sampleAnswer || other.correctAnswer || '').trim();
      if (otherAns && otherAns.toLowerCase() !== correctAns.toLowerCase() && !distractors.some(d => d.toLowerCase() === otherAns.toLowerCase())) {
        distractors.push(otherAns);
      }
    }

    for (const fb of fallbackDistractors) {
      if (distractors.length >= 3) break;
      if (fb.toLowerCase() !== correctAns.toLowerCase() && !distractors.some(d => d.toLowerCase() === fb.toLowerCase())) {
        distractors.push(fb);
      }
    }

    const options = [correctAns, ...distractors];

    const distractorFeedback = {};
    for (const d of distractors) {
      distractorFeedback[d] = `Incorrect: "${d}" is not the natural response to: "${partnerDialogue}".`;
    }

    return {
      id: `SPK_DIALOGUEROLEPLAY_PRAC_L${lvl}_Q${qnum}`,
      phase: 'practice',
      partnerDialogue: partnerDialogue,
      instruction: q.instruction || 'Select the most natural and socially appropriate response:',
      question: `When your roleplay partner says: "${partnerDialogue}", which response is the most natural and appropriate?`,
      options: options,
      correctIndex: 0,
      correctAnswer: correctAns,
      explanation: explanation,
      hint: q.hint || '',
      emotionTag: q.emotionTag || 'Neutral',
      distractorFeedback: distractorFeedback
    };
  });

  const practiceData = {
    gameType: 'dialogueRoleplay',
    phase: 'practice',
    batchIndex: b,
    levels: `${startLevel}-${endLevel}`,
    quests: practiceQuests
  };
  const practiceFile = path.join(curriculumDir, `dialogueRoleplay_practice_${startLevel}_${endLevel}.json`);
  fs.writeFileSync(practiceFile, JSON.stringify(practiceData, null, 2), 'utf8');

  // 1d. Purge legacy file
  fs.unlinkSync(legacyFile);
  console.log(`Processed batch ${b} (${startLevel}-${endLevel}): Created Learn, Practice, Mastery & purged legacy.`);
}

console.log('DialogueRoleplay 3-phase curriculum generation completed successfully.');
