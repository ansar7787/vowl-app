const fs = require('fs');
const path = require('path');

const curriculumPath = 'c:\\Users\\asus\\Documents\\App Projects\\voxai_quest\\assets\\curriculum\\accent';
const files = fs.readdirSync(curriculumPath).filter(f => f.endsWith('.json'));

let allErrors = [];
let levelCounts = {}; // { gameType: { level: questionCount } }

for (const filename of files) {
    const filePath = path.join(curriculumPath, filename);
    const gameType = filename.split('_')[0];
    if (!levelCounts[gameType]) levelCounts[gameType] = {};

    try {
        const content = fs.readFileSync(filePath, 'utf8');
        const data = JSON.parse(content);
        
        const quests = data.quests || [];
        const levelMap = {};
        quests.forEach(q => {
            const match = q.id.match(/_l(\d+)_/);
            if (match) {
                const level = parseInt(match[1]);
                if (!levelMap[level]) levelMap[level] = [];
                levelMap[level].push(q);
                levelCounts[gameType][level] = (levelCounts[gameType][level] || 0) + 1; // Ensure levelCounts is updated
            } else {
                allErrors.push(`[${filename}] Quest has invalid ID format: ${q.id}`);
            }
        });

        const allQuestionsInFile = new Set();
        
        for (const [level, levelQuests] of Object.entries(levelMap)) {
            // 2. Check for question count (3 per level)
            if (levelQuests.length !== 3) {
                allErrors.push(`[${filename}] Level ${level} has ${levelQuests.length} questions (expected 3)`);
            }

            // 3. Check for duplicates within this level (robust check)
            const getQuestText = (q) => (q.textToSpeak || q.word || q.targetWord || q.prompt || q.sentence || '').trim().toLowerCase();
            const texts = levelQuests.map(getQuestText);
            const uniqueTexts = new Set(texts);
            if (uniqueTexts.size < texts.length) {
                allErrors.push(`[${filename}] Level ${level} contains duplicate questions: ${Array.from(uniqueTexts).filter(t => t !== '').join(' | ')}`);
            }

            // check for empty questions
            if (texts.some(t => t === '')) {
                allErrors.push(`[${filename}] Level ${level} has empty or missing question content`);
            }

            // 4. Check for ID format
            levelQuests.forEach((q, i) => {
                const expectedId = `${gameType}_l${level}_q${i + 1}`;
                if (q.id !== expectedId) {
                    allErrors.push(`[${filename}] Level ${level} Quest ${i + 1} has invalid ID: ${q.id} (expected ${expectedId})`);
                }
            });

            // Accumulate for across-level duplicates (within this file)
            texts.forEach(t => {
                if (t !== '') {
                    if (allQuestionsInFile.has(t)) {
                        allErrors.push(`[${filename}] Question repeated in Level ${level}: "${t}" (already seen in previous levels)`);
                    }
                    allQuestionsInFile.add(t);
                }
            });
        }

    } catch (e) {
        allErrors.push(`[${filename}] FAILED TO PARSE: ${e.message}`);
    }
}

// Check for missing levels (1-200)
for (const [gameType, levels] of Object.entries(levelCounts)) {
    for (let i = 1; i <= 200; i++) {
        if (!levels[i]) {
            allErrors.push(`[${gameType}] Missing Level ${i}`);
        }
    }
}

const auditOutput = `Audit Results - Total errors: ${allErrors.length}\n\n` + allErrors.join('\n');
fs.writeFileSync('accent_audit_results.txt', auditOutput);
console.log(`Audit complete. Results written to accent_audit_results.txt. Total errors: ${allErrors.length}`);
