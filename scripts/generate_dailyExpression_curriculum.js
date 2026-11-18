const fs = require('fs');
const path = require('path');

const curriculumDir = path.join(__dirname, '..', 'assets', 'curriculum', 'speaking');

console.log('Starting DailyExpression 3-phase curriculum generation...');

const fallbackDistractors = [
  { expr: 'Nice to meet you', meaning: 'A polite greeting for the first time you meet someone.' },
  { expr: 'See you tomorrow', meaning: 'A goodbye when you expect to see the person tomorrow.' },
  { expr: 'Never mind', meaning: 'Used to tell someone not to worry about something or ignore what was said.' },
  { expr: 'Take your time', meaning: 'Said to tell someone that they do not need to hurry.' },
  { expr: 'Catch you later', meaning: 'A casual way of saying goodbye.' },
  { expr: 'Under the weather', meaning: 'Feeling slightly ill or unwell.' },
  { expr: 'Break a leg', meaning: 'Used to wish someone good luck, especially before a performance.' },
  { expr: 'Call it a day', meaning: 'Decide to stop working on something for the day.' }
];

// Step 1: Process all 20 batches (levels 1-10 through 191-200)
for (let b = 1; b <= 20; b++) {
  const startLevel = (b - 1) * 10 + 1;
  const endLevel = b * 10;
  const legacyFile = path.join(curriculumDir, `dailyExpression_${startLevel}_${endLevel}.json`);

  if (!fs.existsSync(legacyFile)) {
    console.error(`Error: Legacy file missing: ${legacyFile}`);
    process.exit(1);
  }

  const legacyData = JSON.parse(fs.readFileSync(legacyFile, 'utf8'));
  const quests = legacyData.quests || [];

  // 1a. Generate Mastery file
  const masteryData = {
    gameType: 'dailyExpression',
    phase: 'mastery',
    batchIndex: b,
    levels: `${startLevel}-${endLevel}`,
    quests: quests.map(q => ({
      ...q,
      phase: 'mastery'
    }))
  };
  const masteryFile = path.join(curriculumDir, `dailyExpression_mastery_${startLevel}_${endLevel}.json`);
  fs.writeFileSync(masteryFile, JSON.stringify(masteryData, null, 2), 'utf8');

  // 1b. Generate Learn file
  const learnQuests = quests.map((q, idx) => {
    const levelMatch = (q.id || '').match(/_L(\d+)_Q(\d+)/);
    const lvl = levelMatch ? levelMatch[1] : `${startLevel + Math.floor(idx / 3)}`;
    const qnum = levelMatch ? levelMatch[2] : `${(idx % 3) + 1}`;
    const expr = (q.expression || q.correctAnswer || '').trim();

    return {
      id: `SPK_DAILYEXPRESSION_LEARN_L${lvl}_Q${qnum}`,
      phase: 'learn',
      expression: expr,
      meaning: q.meaning || '',
      situationExample: q.situationExample || '',
      sampleUsage: q.sampleUsage || '',
      explanation: q.explanation || '',
      instruction: q.instruction || 'Practice natural pronunciation, cadence, and intonation for this daily expression.',
      hint: q.hint || '',
      textToSpeak: expr,
      communicativeTip: 'Notice the conversational context, tone, and pacing before speaking.',
      culturalNuance: q.explanation || 'Commonly used in daily natural conversation among native speakers.'
    };
  });

  const learnData = {
    gameType: 'dailyExpression',
    phase: 'learn',
    batchIndex: b,
    levels: `${startLevel}-${endLevel}`,
    quests: learnQuests
  };
  const learnFile = path.join(curriculumDir, `dailyExpression_learn_${startLevel}_${endLevel}.json`);
  fs.writeFileSync(learnFile, JSON.stringify(learnData, null, 2), 'utf8');

  // 1c. Generate Practice file
  const practiceQuests = quests.map((q, idx) => {
    const levelMatch = (q.id || '').match(/_L(\d+)_Q(\d+)/);
    const lvl = levelMatch ? levelMatch[1] : `${startLevel + Math.floor(idx / 3)}`;
    const qnum = levelMatch ? levelMatch[2] : `${(idx % 3) + 1}`;
    const correctExpr = (q.expression || q.correctAnswer || '').trim();
    const meaning = q.meaning || '';
    const situation = q.situationExample || '';
    const explanation = q.explanation || '';

    const distractors = [];
    for (let offset = 1; offset < quests.length && distractors.length < 3; offset++) {
      const other = quests[(idx + offset) % quests.length];
      const otherExpr = (other.expression || other.correctAnswer || '').trim();
      if (otherExpr && otherExpr !== correctExpr && !distractors.some(d => d.expr === otherExpr)) {
        distractors.push({ expr: otherExpr, meaning: other.meaning || '' });
      }
    }

    for (const fb of fallbackDistractors) {
      if (distractors.length >= 3) break;
      if (fb.expr !== correctExpr && !distractors.some(d => d.expr === fb.expr)) {
        distractors.push(fb);
      }
    }

    const options = [correctExpr, ...distractors.map(d => d.expr)];

    const distractorFeedback = {};
    for (const d of distractors) {
      distractorFeedback[d.expr] = `Incorrect: "${d.expr}" does not fit this context.${d.meaning ? ' Meaning: ' + d.meaning : ''}`;
    }

    return {
      id: `SPK_DAILYEXPRESSION_PRAC_L${lvl}_Q${qnum}`,
      phase: 'practice',
      instruction: 'Select the daily expression that naturally fits this conversation:',
      situationExample: situation,
      meaning: meaning,
      explanation: explanation,
      sampleUsage: q.sampleUsage || '',
      question: 'Which daily expression best fits this conversational situation?',
      options: options,
      correctIndex: 0,
      correctAnswer: correctExpr,
      hint: q.hint || '',
      distractorFeedback: distractorFeedback
    };
  });

  const practiceData = {
    gameType: 'dailyExpression',
    phase: 'practice',
    batchIndex: b,
    levels: `${startLevel}-${endLevel}`,
    quests: practiceQuests
  };
  const practiceFile = path.join(curriculumDir, `dailyExpression_practice_${startLevel}_${endLevel}.json`);
  fs.writeFileSync(practiceFile, JSON.stringify(practiceData, null, 2), 'utf8');

  // 1d. Purge legacy file
  fs.unlinkSync(legacyFile);
  console.log(`Processed batch ${b} (${startLevel}-${endLevel}): Created Learn, Practice, Mastery & purged legacy.`);
}

console.log('DailyExpression 3-phase curriculum generation completed successfully.');
