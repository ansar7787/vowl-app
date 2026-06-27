const fs = require('fs');
const path = require('path');

const dir = 'assets/curriculum/listening';
const files = fs.readdirSync(dir).filter(f => f.startsWith('emotionRecognition_') && f.endsWith('.json'));

const emojiMap = {
    'happy': '😊',
    'sad': '😢',
    'angry': '😠',
    'surprised': '😲',
    'nervous': '😬',
    'curious': '🤔',
    'bored': '🥱',
    'excited': '🤩',
    'confident': '😎',
    'neutral': '😐',
    'fear': '😨',
    'disgusted': '🤢',
    'proud': '😌',
    'jealous': '😒',
    'annoyed': '🙄',
    'hopeful': '🤞',
    'confused': '😕',
    'frustrated': '😤',
    'calm': '😌',
    'lonely': '😔',
    'guilty': '😳',
    'embarrassed': '😳',
    'relieved': '😅',
    'suspicious': '🤨'
};

let allGood = true;

for (const f of files) {
    const filePath = path.join(dir, f);
    let raw = fs.readFileSync(filePath, 'utf8');
    
    // Check for unsupported symbols
    if (raw.includes('’') || raw.includes('‘') || raw.includes('“') || raw.includes('”')) {
        console.log(`Fixing unsupported symbols in ${f}`);
        raw = raw.replace(/’/g, "'").replace(/‘/g, "'").replace(/“/g, '"').replace(/”/g, '"');
    }

    let data = JSON.parse(raw);
    
    let levelStart = parseInt(f.split('_')[1]);
    let levelEnd = parseInt(f.split('_')[2].split('.')[0]);
    let expectedLevel = levelStart;
    let expectedQ = 1;

    for (let i = 0; i < data.quests.length; i++) {
        let q = data.quests[i];
        
        // 1. Check ID
        let expectedId = `LIS_EMOTIONRECOGNITION_L${expectedLevel}_Q${expectedQ}`;
        if (q.id !== expectedId) {
            console.log(`ID mismatch in ${f}: Expected ${expectedId}, got ${q.id}. Fixing it.`);
            q.id = expectedId;
        }

        // Increment for next question
        expectedQ++;
        if (expectedQ > 3) {
            expectedQ = 1;
            expectedLevel++;
        }

        // 2. Add Instruction (insert after interactionType)
        // We will do this by re-creating the quest object to keep keys ordered nicely if possible,
        // but JavaScript objects preserve insertion order except for integer keys.
        // Doing this manually is safer.
        let newQ = {};
        for (const key in q) {
            newQ[key] = q[key];
            if (key === 'interactionType' && !('instruction' in q)) {
                newQ['instruction'] = "Listen to the audio and select the matching emotion.";
            }
        }
        // Fallback if it was already added
        if (!('instruction' in newQ)) {
            newQ['instruction'] = "Listen to the audio and select the matching emotion.";
        }
        data.quests[i] = newQ;

        // 3. Emojis in options
        for (let j = 0; j < newQ.options.length; j++) {
            let opt = newQ.options[j];
            // If it already has an emoji, skip
            if (!opt.match(/[\uD800-\uDBFF][\uDC00-\uDFFF]|\u261D|\uD83C[\uDF00-\uDFFF]|\uD83D[\uDC00-\uDDFF]|\uD83E[\uDD00-\uDDFF]/)) {
                // extract base word
                let baseWord = opt.trim().toLowerCase();
                if (emojiMap[baseWord]) {
                    newQ.options[j] = `${opt} ${emojiMap[baseWord]}`;
                } else {
                    console.log(`MISSING EMOJI FOR: ${opt} in ${f}`);
                }
            }
        }
    }
    
    fs.writeFileSync(filePath, JSON.stringify(data, null, 4));
}
console.log('Audit and update complete.');
