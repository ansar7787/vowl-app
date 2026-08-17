const fs = require('fs');
const https = require('https');
const path = require('path');

async function fetchURL(url) {
    return new Promise((resolve, reject) => {
        let rawData = '';
        https.get(url, (res) => {
            if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
                return fetchURL(res.headers.location).then(resolve).catch(reject);
            }
            res.on('data', (chunk) => { rawData += chunk; });
            res.on('end', () => resolve(rawData));
        }).on('error', reject);
    });
}

function getPOS(word, definition) {
    let lowerDef = definition.toLowerCase();
    if (lowerDef.startsWith("to ")) return "verb";
    if (word.endsWith("ly")) return "adverb";
    if (word.endsWith("ic") || word.endsWith("ous") || word.endsWith("ive") || word.endsWith("ful") || word.endsWith("less")) return "adjective";
    if (word.endsWith("tion") || word.endsWith("ness") || word.endsWith("ment") || word.endsWith("ity")) return "noun";
    return "noun"; // default fallback
}

function generateExample(word, pos) {
    if (pos === "verb") return `I like to ${word} every morning.`;
    if (pos === "adjective") return `That is a very ${word} idea.`;
    if (pos === "adverb") return `She completed the task ${word}.`;
    return `The ${word} is over there.`; // simple, human conversational
}

function isValidWord(w) {
    if (w.length < 2 && w !== 'a' && w !== 'i') return false;
    if (!/^[a-z]+$/.test(w)) return false; // no numbers or special chars
    // Filter out common web-crawl artifacts
    const roboticWords = ['http', 'https', 'www', 'com', 'org', 'net', 'html', 'php', 'aspx', 'img', 'src', 'href'];
    if (roboticWords.includes(w)) return false;
    return true;
}

function purifyDefinition(raw) {
    // 1. Remove bracketed/parenthetical text (archaic markers)
    let text = raw.replace(/\([^)]+\)/g, '').replace(/\[[^\]]+\]/g, '');
    
    // 2. Remove numbering like "1. ", "2. ", "(a)"
    text = text.replace(/[0-9]+\.\s*/g, '').replace(/\([a-z]\)\s*/g, '');
    
    // 3. Keep only the very first phrase/sentence for human-readability
    let split = text.split(/[;.]/);
    text = split[0];
    
    // 4. Cleanup whitespace
    text = text.replace(/\s+/g, ' ').trim();
    
    // 5. Capitalize and punctuate
    if (text.length > 0) {
        text = text.charAt(0).toUpperCase() + text.slice(1);
        if (!text.endsWith('.')) {
            text += '.';
        }
    }
    
    return text;
}

(async () => {
    console.log("Downloading 20,000 most common words list...");
    const wordsTxt = await fetchURL('https://raw.githubusercontent.com/first20hours/google-10000-english/master/20k.txt');
    let commonWords = wordsTxt.split('\n').map(w => w.trim().toLowerCase()).filter(isValidWord);
    
    console.log("Downloading Webster dictionary for definitions...");
    const dictText = await fetchURL('https://raw.githubusercontent.com/matthewreagan/WebstersEnglishDictionary/master/dictionary_compact.json');
    const dictionary = JSON.parse(dictText);
    
    let validWords = [];
    console.log("Processing and purifying words...");
    for (let i = 0; i < commonWords.length; i++) {
        const w = commonWords[i];
        
        let rawDef = dictionary[w] || dictionary[w.charAt(0).toUpperCase() + w.slice(1)];
        if (rawDef) {
            let pureDef = purifyDefinition(rawDef);
            
            // Skip empty definitions after purification
            if (pureDef.length < 5) continue;

            let pos = getPOS(w, pureDef);
            let example = generateExample(w, pos);
            
            validWords.push({
                word: w,
                partOfSpeech: pos,
                definition: pureDef,
                synonyms: [], // kept empty to focus on pure definitions
                example: example
            });
        }
        if (validWords.length >= 10000) break;
    }
    
    console.log(`Successfully curated ${validWords.length} highly-conversational English words.`);
    
    const outputDir = "c:\\Users\\asus\\Documents\\App Projects\\vowl\\assets\\curriculum\\daily_words";
    
    const themes = [
        "Everyday Essentials", "Common Actions", "Basic Descriptions", 
        "Time & Place", "People & Relationships", "Emotions & Feelings",
        "Work & Study", "Nature & Environment", "Food & Dining", "Travel & Transport"
    ];

    let wordCounter = 1;
    let globalIndex = 0;
    
    for (let file_index = 1; file_index <= 100; file_index++) {
        let start_day = (file_index - 1) * 10 + 1;
        let end_day = file_index * 10;
        
        let batch_data = { days: [] };
        
        for (let day_offset = 0; day_offset < 10; day_offset++) {
            let current_day = start_day + day_offset;
            let theme = themes[current_day % themes.length];
            
            let day_data = {
                day: current_day,
                theme: theme,
                words: []
            };
            
            for (let w = 0; w < 10; w++) {
                let currentWord = validWords[globalIndex];
                if (!currentWord) currentWord = validWords[0]; // safety fallback
                
                day_data.words.push({
                    id: "dw_" + String(wordCounter).padStart(4, '0'),
                    word: currentWord.word,
                    phonetic: "/" + currentWord.word + "/", 
                    partOfSpeech: currentWord.partOfSpeech,
                    definition: currentWord.definition,
                    example: currentWord.example,
                    synonyms: currentWord.synonyms,
                    difficulty: 1 + Math.floor(wordCounter / 2000),
                    frequencyRank: wordCounter
                });
                wordCounter++;
                globalIndex++;
            }
            batch_data.days.push(day_data);
        }
        
        let filename = "daily_words_" + String(start_day).padStart(3, '0') + "_" + String(end_day).padStart(3, '0') + ".json";
        fs.writeFileSync(path.join(outputDir, filename), JSON.stringify(batch_data, null, 2));
    }
    
    console.log("Rewritten all 100 files with clean, conversational definitions!");
})();
