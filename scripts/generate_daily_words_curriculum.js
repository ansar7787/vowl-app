const fs = require('fs');
const path = require('path');

// Requires: npm install @google/genai
const { GoogleGenAI, Type, Schema } = require('@google/genai');

const CURRICULUM_DIR = path.join(__dirname, '..', 'assets', 'curriculum', 'daily_words');

// We expect the user to set their Gemini API Key as an environment variable
const apiKey = process.env.GEMINI_API_KEY;

if (!apiKey) {
    console.error('❌ ERROR: GEMINI_API_KEY environment variable is missing.');
    console.error('Please run the script like this:');
    console.error('  $env:GEMINI_API_KEY="your_api_key_here"; node scripts/generate_daily_words_curriculum.js');
    process.exit(1);
}

const ai = new GoogleGenAI({ apiKey: apiKey });

const promptInstruction = `
You are an expert curriculum designer and linguist.
I am providing you with a JSON array of vocabulary words intended for English learners.
The current data has issues: fake phonetics, archaic definitions, and robotic example sentences.

Your task is to fix the data and return a JSON array of the EXACT SAME length, containing the SAME words in the SAME order.
For each word, provide:
1. "word": The original word.
2. "partOfSpeech": The correct part of speech (noun, verb, adjective, adverb, etc).
3. "phonetic": The accurate IPA transcription (e.g., /əˈmeɪ.zɪŋ/).
4. "definition": A clear, modern, and easily understandable definition.
5. "example": A natural, conversational, and interesting example sentence using the word.
6. "difficulty": Keep the original difficulty (1=Easy, 2=Medium, 3=Hard) or assign an appropriate one.

Return ONLY a JSON array of objects with the keys: id, word, partOfSpeech, phonetic, definition, example, difficulty.
Do NOT change the "id" of the words.
`;

const responseSchema = {
    type: Type.ARRAY,
    description: "List of fixed vocabulary words",
    items: {
        type: Type.OBJECT,
        properties: {
            id: { type: Type.STRING },
            word: { type: Type.STRING },
            partOfSpeech: { type: Type.STRING },
            phonetic: { type: Type.STRING },
            definition: { type: Type.STRING },
            example: { type: Type.STRING },
            difficulty: { type: Type.INTEGER }
        },
        required: ["id", "word", "partOfSpeech", "phonetic", "definition", "example", "difficulty"]
    }
};

async function processFile(filePath) {
    console.log(`⏳ Processing ${path.basename(filePath)}...`);
    const content = fs.readFileSync(filePath, 'utf-8');
    const data = JSON.parse(content);
    
    // We will process it day by day to keep the prompt size manageable
    for (const dayObj of data.days) {
        console.log(`  -> Enhancing Day ${dayObj.day} (${dayObj.theme})...`);
        
        try {
            const response = await ai.models.generateContent({
                model: 'gemini-2.5-flash',
                contents: [
                    { text: promptInstruction },
                    { text: JSON.stringify(dayObj.words) }
                ],
                config: {
                    responseMimeType: "application/json",
                    responseSchema: responseSchema,
                    temperature: 0.2,
                }
            });
            
            const fixedWords = JSON.parse(response.text);
            
            // Validation: Ensure lengths match
            if (fixedWords.length !== dayObj.words.length) {
                console.error(`  ❌ Mismatch for Day ${dayObj.day}: expected ${dayObj.words.length} words, got ${fixedWords.length}. Skipping this day.`);
                continue;
            }
            
            // Re-assign the fixed words
            dayObj.words = fixedWords;
            
            // Wait 2 seconds to avoid rate limiting
            await new Promise(resolve => setTimeout(resolve, 2000));
        } catch (error) {
            console.error(`  ❌ Error processing Day ${dayObj.day}:`, error.message);
        }
    }
    
    // Save the updated file
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8');
    console.log(`✅ Completed ${path.basename(filePath)}!\n`);
}

async function main() {
    const files = fs.readdirSync(CURRICULUM_DIR).filter(f => f.endsWith('.json'));
    console.log(`Found ${files.length} curriculum files to process.\n`);
    
    for (const file of files) {
        await processFile(path.join(CURRICULUM_DIR, file));
    }
    
    console.log('🎉 All files have been upgraded to the Diamond Standard!');
}

main().catch(console.error);
