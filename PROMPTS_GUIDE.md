# VOWL: Master Curriculum Upgrade Prompts
This guide contains the bulletproof, loophole-free Claude 3.5 Sonnet prompts to upgrade all 100 curriculum game modules (2,000 files total) to the Diamond Standard. 

I have personally inspected the Flutter UI code (e.g., `academic_word_screen.dart`, `idioms_screen.dart`, `listening_screen.dart`, `roleplay_screen.dart`) to ensure these JSON schemas perfectly map to exactly what your app renders. 

## Instructions for Use
1. Open Claude 3.5 Sonnet.
2. Drag and drop all 20 JSON files for a specific game type (e.g., all 20 `collocations_*.json` files).
3. Copy the **Bulletproof Base Prompt** below, and combine it with the **JSON Schema** for the specific game you are working on.
4. Send the prompt to Claude.
5. Claude will return the JSON for the **first file only**.
6. Copy Claude's output, paste it into your local file, and save.
7. Reply to Claude: `"Perfect, now give me the JSON for the next file."`
8. Repeat until all 20 files are upgraded!

---

## 🛡️ THE BULLETPROOF BASE PROMPT
*Copy this exact text, paste it into Claude, and then paste your specific game schema below it.*

```text
I am uploading 20 JSON files (Levels 1-200) for a progressive language learning application. You are acting as an expert linguist, curriculum designer, and strict JSON data generator. 

Your objective is to upgrade the pedagogical content of these files to absolute 10/10 quality. 

CRITICAL RULES TO PREVENT AI LOOPHOLES:
1. STRICT PROGRESSION: The curriculum is progressively scaled. 
   - Files 1-5 (Levels 1-50): A1/A2 (Basic, concrete concepts)
   - Files 6-10 (Levels 51-100): B1 (Intermediate, practical concepts)
   - Files 11-15 (Levels 101-150): B2/C1 (Upper intermediate, academic/professional)
   - Files 16-20 (Levels 151-200): C2 (Mastery, nuanced, rare, literary)
   You MUST adapt the difficulty of the vocabulary, the reading level of the sentences, and the complexity of the explanations to perfectly match the batch you are updating.
2. ZERO REPETITION: You must NEVER repeat a target word, concept, or sentence across the entire curriculum. Every single item must be unique. Do not get lazy.
3. DISTRACTORS MUST BE TRICKY: Do not provide obvious, silly incorrect options. The incorrect options must be lexically similar, grammatically plausible, or common ESL learner mistakes.
4. NATIVE, ADULT TONE: No childish examples. Use professional, literary, or highly realistic native contexts.
5. REPETITION TRACKING: Before you output the JSON block, you MUST first output a numbered list of the 10 target concepts you have chosen for this file. Cross-reference this list with all previous files in this chat to guarantee zero repetition.

WORKFLOW:
Do NOT generate all files at once. You will hit an output token limit and break the JSON. 
Start by generating ONLY the fully updated JSON for the very first file in the batch sequence. Keep the exact same `id` and `interactionType` values.
Return ONLY the raw, perfectly formatted JSON array/object so I can copy and paste it.

Here is the exact schema and UI rendering rules for the specific game you are updating:

[PASTE THE SPECIFIC GAME SCHEMA BELOW]
```

---

## VOCABULARY GAME SCHEMAS (Paste ONE of these below the base prompt)

### 1. Flashcards (`flashcards_X_Y.json`)
```text
1. "instruction": A short prompt (e.g., "DEFINE THIS WORD").
2. "hint": The text on the FRONT of the card (word itself, fill-in-the-blank, or clever clue).
3. "definition": A punchy, adult-level dictionary definition for the back of the card.
4. "example": A highly realistic, native-sounding sentence.
5. "usageExample": A tip on nuance, tone, or collocation. (NEVER use a generic placeholder).
6. "explanation": Conversational explanation.
7. "topicEmoji": A single highly relevant emoji used as a visual background watermark.
8. "word" & "correctAnswer": Must match exactly in ALL CAPS.
```

### 2. Academic Word (`academicWord_X_Y.json`)
```text
1. "word" & "correctAnswer": The target academic word in ALL CAPS.
2. "hint": A short, clear definition clue.
3. "options": Array of 4 words in ALL CAPS (1 correct, 3 tricky distractors).
4. "explanation": A detailed explanation of why the word fits the academic context.
5. "passage": A sentence with "[TARGET]" where the word belongs.
6. "instruction": "Drag the correct word to complete the sentence."
7. "academicField": The field of study (e.g., "Sociology", "Biology") displayed in the UI label.
8. "collocations": Array of 3 common collocations using the word displayed in the summary UI.
```

### 3. Antonym Search (`antonymSearch_X_Y.json`)
```text
1. "word": The base word in ALL CAPS.
2. "correctAnswer": The antonym in ALL CAPS.
3. "instruction": "Select the antonym for the given word."
4. "hint": A thought-provoking clue about the antonym.
5. "explanation": Explain the contrast between the word and its antonym.
6. "options": Array of 4 words in ALL CAPS (1 correct antonym, 3 synonyms or unrelated distractors).
7. "gradientScale": Array of 5 strings showing the linguistic spectrum from the word to the antonym.
```

### 4. Collocations (`collocations_X_Y.json`)
```text
UI NOTE: The user must combine the 'word' and 'correctAnswer' (e.g., DO + HOMEWORK).
1. "word": The base verb/noun (e.g., "DO").
2. "correctAnswer": The collocating word (e.g., "HOMEWORK").
3. "instruction": "Find the word that naturally completes the pair."
4. "hint": A clue about the meaning of the combined phrase.
5. "explanation": Explain why these words go together and why others don't.
6. "options": Array of 4 words (1 correct, 3 tricky incorrect ones).
7. "wrongCollocations": Array of 3 common learner mistakes (e.g., ["make HOMEWORK", "have HOMEWORK"]).
8. "contextSentence": A sentence with a blank "__" for the correct answer.
```

### 5. Context Clues (`contextClues_X_Y.json`)
```text
1. "word" & "correctAnswer": The target word.
2. "instruction": "Analyze the sentence to deduce the hidden word."
3. "sentence": A sentence with "[TARGET]" where the word belongs.
4. "hint": A clever clue to point them in the right direction.
5. "options": Array of 4 words.
6. "explanation": Explain how the evidence in the sentence reveals the answer.
7. "clueType": "synonym", "antonym", or "inference".
8. "evidenceWords": Array of 2-3 words extracted precisely from the sentence that provide the context clue.
```

### 6. Contextual Usage (`contextualUsage_X_Y.json`)
```text
1. "word" & "correctAnswer": The target word.
2. "question": A sentence with "_____" indicating the missing word.
3. "instruction": "Select the correct word to complete the sentence."
4. "hint": A short definition of the correct word.
5. "options": Array of 4 easily confused words (e.g., THERE, THEIR, THEY'RE).
6. "explanation": Clearly explain the grammatical difference.
7. "registerLevel": Number from 1-10 indicating formality.
```

### 7. Idioms (`idioms_X_Y.json`)
```text
UI NOTE: The user must physically speak the 'correctAnswer' into the microphone.
1. "word" & "correctAnswer": The idiom in ALL CAPS (e.g., "BREAK A LEG").
2. "instruction": "Select the correct idiom for the given meaning."
3. "hint": The literal definition of what the idiom means.
4. "options": Array of 4 idioms.
5. "explanation": Explain the figurative meaning with an example.
6. "topicEmoji": A relevant emoji displayed huge in the UI.
7. "origin": A fascinating 1-sentence historical origin of the idiom displayed in the post-game summary.
```

### 8. Phrasal Verbs (`phrasalVerbs_X_Y.json`)
```text
1. "word": The base verb (e.g., "GET").
2. "correctAnswer": The preposition/particle (e.g., "UP").
3. "instruction": "Select the correct particle to complete the phrasal verb."
4. "hint": The definition of the phrasal verb.
5. "explanation": Explain the meaning with an example sentence.
6. "options": Array of 4 particles (e.g., ["UP", "IN", "ON", "OUT"]).
7. "literalVsFigurative": A 2-sentence breakdown explaining the difference between its literal and figurative use.
```

### 9. Prefix Suffix (`prefixSuffix_X_Y.json`)
```text
1. "correctAnswer": The full combined word (e.g., "REDO").
2. "rootWord": The base word (e.g., "DO").
3. "instruction": "Select the correct prefix or suffix."
4. "hint": The definition of the new word.
5. "explanation": Explain what the affix means (e.g., "RE- means again").
6. "options": Array of 4 affixes (e.g., ["-LY", "-FUL", "RE-", "UN-"]).
7. "meaningBreakdown": Text displaying the word math (e.g., "RE (prefix) + DO (root)").
```

### 10. Synonym Search (`synonymSearch_X_Y.json`)
```text
1. "word": The base word.
2. "correctAnswer": The synonym.
3. "instruction": "Find the synonym for the given word."
4. "hint": A clue about the meaning.
5. "explanation": Explain the nuance between the base word and the synonym.
6. "options": Array of 4 words (1 correct synonym, 3 distractors).
7. "nuanceDifference": Explain exactly when to use this synonym over the base word.
```

### 11. Topic Vocab (`topicVocab_X_Y.json`)
```text
1. "instruction": "Sort the words into their correct categories."
2. "topicBuckets": Array of EXACTLY 2 categories (e.g., ["Hot", "Cold"]).
3. "hint": A tip on how to distinguish the categories.
4. "explanation": A breakdown of why the words belong in those categories.
5. "options": Array of 5 words to be sorted.
6. "correctAnswer": Comma separated pairs (e.g., "Hot:Boiling, Cold:Freezing, ...").
7. "relatedWords": Array of 5 strings explaining each option briefly.
```

### 12. Word Formation (`wordFormation_X_Y.json`)
```text
1. "correctAnswer": The full word.
2. "rootWord": The base root word.
3. "instruction": "Slide the correct morpheme into the core to form a new word."
4. "hint": A clue about what kind of word it forms (e.g., "Form an adjective...").
5. "explanation": Explain the word math (e.g., "HELP + -FUL = HELPFUL").
6. "options": Array of 4 morphemes.
7. "familyTree": Array of 3-4 related words from the same root to show morphology.
```

---

## GRAMMAR GAME SCHEMAS
*(Use the same Bulletproof Base Prompt, but paste one of these Grammar schemas below it!)*

### 13. Article Insertion (`articleInsertion_X_Y.json`)
```text
1. "instruction": "INSERT THE CORRECT ARTICLE"
2. "question" & "sentence": A sentence with "___" where the article belongs. (e.g. "I want ___ apple.")
3. "options": Array of exactly 4 strings: ["a", "an", "the", "(no article)"].
4. "correctAnswerIndex": The integer index (0-3) of the correct answer in your options array.
5. "correctAnswer": The exact string of the correct answer.
6. "hint": A clue about vowel sounds, specific vs general, or countability.
7. "explanation": Explain the rule clearly.
8. "grammarRule": A short title of the rule (e.g., "Definite Article").
```

### 14. Clause Connector (`clauseConnector_X_Y.json`)
```text
1. "instruction": "Select the correct connector."
2. "question" & "sentence": A sentence with "____" connecting two clauses.
3. "options": Array of 4 connector words (e.g., "and", "but", "so", "although").
4. "correctAnswerIndex": Integer index (0-3) of the correct option.
5. "correctAnswer": The exact string of the correct option.
6. "hint": A clue about the relationship (e.g., "Look for a contrast").
7. "explanation": Explain how the connector joins the two specific ideas.
8. "grammarRule": Title of rule (e.g., "Contrast (although)").
```

### 15. Conditionals (`conditionals_X_Y.json`)
```text
1. "instruction": "LINK THE CONSEQUENCE"
2. "question": The 'If' clause (e.g., "If you heat ice,").
3. "options": Array of 4 possible consequence clauses.
4. "correctAnswerIndex": Integer index (0-3) of the correct consequence.
5. "correctAnswer": The exact correct string.
6. "hint": A clue about the conditional type being used.
7. "explanation": Detail the structure (e.g., "Zero conditional = always true. If + present simple, present simple").
8. "grammarRule": Title (e.g., "Zero Conditional").
```

### 16. Conjunctions (`conjunctions_X_Y.json`)
```text
1. "instruction": "JOIN THE JUNCTION"
2. "question": A sentence with "___" where the conjunction belongs.
3. "options": Array of 4 conjunctions.
4. "correctAnswerIndex": Integer index (0-3).
5. "correctAnswer": The exact correct string.
6. "hint": A clue about the grammatical function.
7. "explanation": Explain why this conjunction fits best.
8. "grammarRule": (e.g., "Coordinating Conjunctions").
```

### 17. Direct/Indirect Speech (`directIndirectSpeech_X_Y.json`)
```text
1. "instruction": "TRANSFORM THE SPEECH"
2. "question": "Convert to reported speech: [Quote]" or "Convert to direct speech: [Sentence]".
3. "sentence": The original sentence text.
4. "options": Array of 3 or 4 transformations.
5. "correctAnswerIndex": Integer index of correct answer.
6. "correctAnswer": The exact correct string.
7. "hint": A clue about tense backshifting or pronoun changes.
8. "explanation": Detail the exact mechanical changes made.
9. "grammarRule": Title (e.g., "Tense Backshift").
10. "changesList": Array containing 1 string summarizing the change (e.g., ["Format changed to reported speech"]).
```

### 18. Grammar Quest (`grammarQuest_X_Y.json`)
```text
1. "instruction": "RESOLVE THE PATTERN"
2. "question": A generic grammar sentence with "___".
3. "options": Array of 4 choices.
4. "correctAnswerIndex": Integer index (0-3).
5. "correctAnswer": The exact string.
6. "hint": A general grammar hint.
7. "explanation": A detailed, adult-level explanation of the grammar mechanic.
8. "grammarRule": The specific topic (e.g., "Verb 'To Be' (Present)").
```

### 19. Modals Selection (`modalsSelection_X_Y.json`)
```text
1. "instruction": "CHOOSE THE MODAL"
2. "question": A sentence missing a modal verb "___".
3. "options": Array of 4 modals (e.g., "must", "might", "could", "would").
4. "correctAnswerIndex": Integer index (0-3).
5. "correctAnswer": The exact string.
6. "hint": A clue about obligation, ability, or probability.
7. "explanation": Explain the subtle modality difference between the options.
8. "grammarRule": Title (e.g., "Obligation & Deduction (must)").
```

### 20. Modifier Placement (`modifierPlacement_X_Y.json`)
```text
UI NOTE: This is a sentence-building game where words are dragged into order.
1. "instruction": "PLACE THE MODIFIER"
2. "sentence": e.g., "Insert the modifier 'fresh' into the correct position."
3. "correctAnswer": The fully assembled correct sentence.
4. "shuffledWords": Array of strings containing ALL words in the correct sentence, BUT scrambled randomly. Include punctuation attached to the last word.
5. "hint": A clue about where adjectives/adverbs go.
6. "explanation": Explain the grammatical placement rule.
7. "grammarRule": Title (e.g., "Adjective Placement").
```

### 21. Parts of Speech (`partsOfSpeech_X_Y.json`)
```text
1. "instruction": "IDENTIFY THE FUNCTION"
2. "question": e.g., "What part of speech is 'cat' in the sentence below?"
3. "targetWord": The specific word in question (e.g., "cat").
4. "sentence": The full sentence for context.
5. "options": Array of 4 parts of speech (e.g., ["Noun", "Verb", "Adjective", "Adverb"]).
6. "correctAnswerIndex": Integer index (0-3).
7. "correctAnswer": The correct string.
8. "hint": A clue about its function.
9. "explanation": Explain why it functions as that part of speech.
10. "grammarRule": Title (e.g., "Nouns").
```

### 22. Preposition Choice (`prepositionChoice_X_Y.json`)
```text
1. "instruction": "CHOOSE THE POSITION"
2. "question": A sentence with "___".
3. "options": Array of 4 prepositions.
4. "correctAnswerIndex": Integer index.
5. "correctAnswer": The correct string.
6. "hint": A clue about time/place logic.
7. "explanation": Explain the preposition rule used here.
8. "grammarRule": Title (e.g., "Prepositions of Place").
```

### 23. Pronoun Resolution (`pronounResolution_X_Y.json`)
```text
1. "instruction": "Resolve the pronoun."
2. "question": e.g., "Tom lost his wallet. Who does 'his' refer to?"
3. "targetWord": The pronoun (e.g., "his").
4. "sentence": The original context sentence.
5. "options": Array of 3 or 4 possible referents (e.g., ["Tom", "lost", "The wallet"]).
6. "correctAnswerIndex": Integer index.
7. "correctAnswer": The exact correct string.
8. "hint": A simple clue.
9. "explanation": Explain the grammatical connection.
10. "grammarRule": Title (e.g., "Possessive Adjectives").
```

### 24. Punctuation Mastery (`punctuationMastery_X_Y.json`)
```text
1. "instruction": "APPLY HOLOGRAPHIC DECALS"
2. "sentence": A sentence missing all its punctuation (e.g., "We packed shirts socks and shoes").
3. "correctAnswer": The fully and perfectly punctuated sentence.
4. "hint": A clue about pauses or lists.
5. "explanation": Explain the specific punctuation rule.
6. "grammarRule": Title (e.g., "Periods").
```

### 25. Question Formatter (`questionFormatter_X_Y.json`)
```text
1. "instruction": "Turn the statement into a question."
2. "question" & "sentence": The original statement.
3. "options": Array of 4 question transformations (1 correct, 3 grammatically tricky distractors).
4. "correctAnswerIndex": Integer index.
5. "correctAnswer": Exact correct string.
6. "hint": Clue about auxiliary verbs or word order.
7. "explanation": Explain the transformation mechanics.
8. "grammarRule": Title (e.g., "Present Simple Questions").
```

### 26. Relative Clauses (`relativeClauses_X_Y.json`)
```text
1. "instruction": "CAST THE RELATIVE LINK"
2. "question": A sentence missing a relative pronoun "___".
3. "hint": A clue about person vs thing.
4. "explanation": Explain why this relative pronoun fits.
5. "options": Array of 4 pronouns (e.g., ["who", "which", "whose", "where"]).
6. "correctAnswerIndex": Integer index.
7. "correctAnswer": Exact correct string.
8. "grammarRule": Title (e.g., "Relative Pronoun 'who'").
```

### 27. Sentence Correction (`sentenceCorrection_X_Y.json`)
```text
1. "instruction": "ZAP THE ERROR"
2. "question": e.g., "Fix: 'My sister don't drink coffee.'"
3. "sentence": The incorrect sentence.
4. "incorrectPart": The exact word that is wrong (e.g., "don't").
5. "correctedPart": The exact word that fixes it (e.g., "doesn't").
6. "options": Array of 4 possible fixes.
7. "correctAnswerIndex": Integer index.
8. "correctAnswer": The correct string.
9. "hint": A clue about the error.
10. "explanation": Explain the grammatical correction.
11. "grammarRule": Title (e.g., "Subject-Verb Agreement").
```

### 28. Subject-Verb Agreement (`subjectVerbAgreement_X_Y.json`)
```text
1. "instruction": "SYNC THE AGREEMENT"
2. "question": A sentence missing its verb "___".
3. "hint": A clue about singular/plural subject.
4. "explanation": State the agreement rule clearly.
5. "options": Array of 2-4 verb forms.
6. "correctAnswerIndex": Integer index.
7. "correctAnswer": Exact correct string.
8. "grammarRule": Title (e.g., "Subject-Verb Agreement (Singular)").
```

### 29. Tense Mastery (`tenseMastery_X_Y.json`)
```text
1. "instruction": "Map the timeline."
2. "sentence": A sentence in a specific tense.
3. "correctAnswer" & "correctAnswerCategory": e.g., "Past", "Present", or "Future".
4. "hint": A clue focusing on time markers.
5. "explanation": Explain why the verb tense maps to that timeline position.
6. "grammarRule": Title (e.g., "Simple Past Tense").
7. "timelinePosition": (Same as correctAnswerCategory).
```

### 30. Voice Swap (`voiceSwap_X_Y.json`)
```text
1. "instruction": "FLIP THE VOICE TRANSMUTER"
2. "question" & "sentence": A sentence in either active or passive voice.
3. "options": ["Active", "Passive"]
4. "correctAnswerIndex": 0 (if Active) or 1 (if Passive).
5. "correctAnswer" & "correctAnswerCategory": "Active" or "Passive".
6. "hint": A clue about identifying the doer.
7. "explanation": Explain how to identify the voice and how to flip it.
8. "grammarRule": Title (e.g., "Simple Present Active").
```

### 31. Word Reorder (`wordReorder_X_Y.json`)
```text
UI NOTE: The user must reconstruct the sentence from shuffled words.
1. "instruction": "REORDER WORDS"
2. "sentence": The perfectly assembled sentence.
3. "shuffledWords": Array of strings representing the scrambled sentence. Punctuation must be attached to the final word.
4. "correctOrder": An array of integers representing the index of each word in the `shuffledWords` array that forms the `sentence`. (e.g., if the sentence is "A B", and shuffledWords is ["B", "A"], correctOrder is [1, 0]).
```

---

## READING GAME SCHEMAS
*(Use the same Bulletproof Base Prompt, but paste one of these Reading schemas below it!)*

### 32. Cloze Test (`clozeTest_X_Y.json`)
```text
1. "instruction": "Fill in the blank with the correct word."
2. "passage": A sentence or short paragraph with "____" indicating the missing word.
3. "options": Array of 4 words.
4. "correctAnswer" & "missingWord": The exact correct string.
5. "hint": A contextual clue.
6. "explanation": Explain why this word fits best based on context.
7. "wordCategory": The part of speech of the missing word (e.g., "noun", "phrasal verb").
```

### 33. Find Word Meaning (`findWordMeaning_X_Y.json`)
```text
UI NOTE: The user must search the passage for a specific word that matches a definition.
1. "instruction": "Find the word in the passage that matches the meaning."
2. "passage": A short reading text.
3. "question": "Find the word in the passage that means: [Definition]"
4. "targetWord" & "correctAnswer": The exact word from the passage.
5. "hint": A clue to help them scan the text.
6. "explanation": Explain the definition of the word in context.
7. "wordInContext": A string explaining how the word is used in the passage.
```

### 34. Guess Title (`guessTitle_X_Y.json`)
```text
1. "instruction": "Drag the best title for the passage."
2. "passage": A well-written, multi-sentence paragraph.
3. "options": Array of 4 possible titles (1 correct, 3 distractors).
4. "correctAnswer": The exact correct title string.
5. "hint": A clue about the main idea.
6. "explanation": Explain why this title summarizes the passage best.
7. "whyThisTitle": A short 1-sentence recap of the main idea.
```

### 35. Paragraph Summary (`paragraphSummary_X_Y.json`)
```text
1. "instruction": "Choose the best summary for the paragraph."
2. "passage": A detailed paragraph.
3. "keywords": Array of 3-4 key concepts/words from the passage.
4. "options": Array of 4 summary sentences.
5. "correctAnswer": The exact correct summary string.
6. "hint": A clue focusing on combining ideas rather than isolating one detail.
7. "explanation": Explain why the correct answer encapsulates the entire paragraph.
```

### 36. Read and Answer (`readAndAnswer_X_Y.json`)
```text
1. "instruction": "Read the passage and select the correct answer."
2. "passage": A detailed paragraph. Optionally include a bracketed title like "[Morning Routine]".
3. "question": A reading comprehension question.
4. "options": Array of 4 possible answers.
5. "correctAnswer": The exact string of the correct answer.
6. "correctAnswerIndex": Integer index (0-3).
7. "hint": A clue directing them to a specific part of the text.
8. "explanation": Explain how the text proves the answer.
9. "passageWordCount": Integer representing the approximate word count of the passage.
```

### 37. Read and Match (`readAndMatch_X_Y.json`)
```text
UI NOTE: The user must draw lines between words and their definitions based on a reading context.
1. "instruction": "Match each word with its meaning."
2. "pairs": Array of exactly 3 or 4 objects. Each object must have a `key` (format: "[L{level}-Q{questNum}-{index}] Word") and a `value` (the definition). Example: `{"key": "[L1-Q1-0] Happy", "value": "Feeling pleased..."}`.
3. "hint": A general clue about the vocabulary used.
```

### 38. Reading Conclusion (`readingConclusion_X_Y.json`)
```text
1. "instruction": "Read the passage and select the correct conclusion."
2. "passage": A scenario that leads to an unstated outcome.
3. "options": Array of 4 possible conclusions.
4. "correctAnswer": Exact correct string.
5. "hint": A clue focusing on logical deduction.
6. "explanation": Explain the logical jump from the text to the conclusion.
7. "logicChain": Array of 1 string summarizing the deduction (e.g., ["Premise -> Conclusion"]).
```

### 39. Reading Inference (`readingInference_X_Y.json`)
```text
1. "instruction": "Read the passage and select the correct inference."
2. "passage": A text with subtext or implied meaning.
3. "question": e.g., "What can you infer about [Subject]?"
4. "options": Array of 4 inferences.
5. "correctAnswer": Exact correct string.
6. "hint": Clue about reading between the lines.
7. "explanation": Explain how the subtext proves the inference.
8. "clueWords": Array of 2 strings highlighting words from the text that hint at the inference.
```

### 40. Reading Speed Check (`readingSpeedCheck_X_Y.json`)
```text
1. "instruction": "Read the text quickly and answer the question."
2. "passage": A text to be speed-read.
3. "question": A factual recall question.
4. "options": Array of 4 answers.
5. "correctAnswer": Exact string.
6. "timeLimit": Integer (e.g., 20) representing seconds allowed to read.
7. "word": A target word from the text they should have noticed.
8. "hint": Factual clue.
9. "explanation": Direct proof from the text.
10. "wpm_target": Integer (e.g., 150) representing Words Per Minute goal.
```

### 41. Sentence Order Reading (`sentenceOrderReading_X_Y.json`)
```text
1. "instruction": "Arrange the sentences in the correct order to form a logical paragraph."
2. "shuffledSentences": Array of 3 to 5 strings representing the sentences out of order.
3. "correctOrder": Array of integers representing the index of each sentence in `shuffledSentences` that forms the chronological paragraph.
4. "hint": Clue about time/transition words.
5. "explanation": Explain the chronological flow of the sentences.
6. "transitionWords": Array of 2 strings showing the link words used (e.g., ["First", "Then"]).
```

### 42. Skimming & Scanning (`skimmingScanning_X_Y.json`)
```text
1. "instruction": "Scan the text to find and select the target word."
2. "passage": A dense text containing specific data (numbers, names, dates).
3. "targetItem" & "correctAnswer": The specific word/data point they must find.
4. "options": Array of 4 strings from the text.
5. "hint": Clue about what to scan for (e.g., "Look for a capitalized name").
6. "explanation": State where the data point was in the text.
7. "timeLimit": Integer (e.g., 20).
8. "targetInfo": Short string describing the data type (e.g., "A specific year").
```

### 43. True/False Reading (`trueFalseReading_X_Y.json`)
```text
1. "instruction": "Read the passage and determine if the statement is true or false."
2. "passage": The reading text.
3. "question": A statement that is either true or false based on the passage.
4. "options": ["true", "false"] (Must be exactly these strings).
5. "correctAnswer": "true" or "false".
6. "hint": Clue directing them to a specific sentence.
7. "explanation": Explain why the statement contradicts or supports the text.
8. "evidenceLine": Quote the exact sentence from the text that proves the answer.
```

---

## LISTENING GAME SCHEMAS
*(Use the same Bulletproof Base Prompt, but paste one of these Listening schemas below it!)*

### 44. Ambient ID (`ambientId_X_Y.json`)
```text
1. "instruction": "Listen to the description and identify the location."
2. "hint": A clue about the background sounds described.
3. "explanation": Explain how the sounds reveal the location.
4. "textToSpeak": A rich descriptive sentence of sounds (e.g., "A cash register beeps..."). This is what the TTS reads.
5. "options": Array of 4 locations (e.g., ["Video Game Arcade", "Supermarket"]).
6. "correctAnswerIndex": Integer index.
7. "locationContext": A short note about the location.
8. "vocabularyWords": Array of 2 keywords from the text.
```

### 45. Audio Fill Blanks (`audioFillBlanks_X_Y.json`)
```text
1. "instruction": "Listen to the audio and type the missing word."
2. "hint": A clue about the missing word.
3. "explanation": Detail why the word fits grammatically and contextually.
4. "textToSpeak": The complete sentence that the TTS will read aloud.
5. "textWithBlanks": The sentence with "___" where the word is missing.
6. "missingWord" & "correctAnswer": The exact missing word.
7. "distractorWords": Array of 2 grammatically plausible wrong words.
8. "imageUrl": Use the exact format `https://loremflickr.com/800/600/$missingWord/all?lock=${quest['id'].hashCode}` (just replace $missingWord with the actual word).
```

### 46. Audio Multiple Choice (`audioMultipleChoice_X_Y.json`)
```text
1. "instruction": "Listen to the audio and select the correct answer."
2. "hint": Clue about the spoken text.
3. "explanation": Clarify what the audio said to prove the answer.
4. "textToSpeak": The sentence that the TTS will read aloud.
5. "question": A question about the spoken text.
6. "options": Array of 4 possible answers.
7. "correctAnswerIndex": Integer index.
8. "emoji": A single relevant emoji.
9. "audioTranscript": A string displaying the exact `textToSpeak` (used for review).
```

### 47. Audio Sentence Order (`audioSentenceOrder_X_Y.json`)
```text
1. "instruction": "Listen to the audio and arrange the words in the correct order."
2. "hint": A clue about grammar or word order.
3. "explanation": Explain the grammatical structure of the sentence.
4. "textToSpeak": The complete sentence that the TTS will read aloud.
5. "shuffledSentences": Array of strings representing the individual words of the sentence scrambled randomly. Punctuation goes on the last word.
6. "correctOrder": An array of integers mapping the `shuffledSentences` array into the correct `textToSpeak` order.
```

### 48. Audio True False (`audioTrueFalse_X_Y.json`)
```text
1. "instruction": "Listen to the statement and determine if it is true or false."
2. "hint": A clue about the discrepancy.
3. "explanation": Detail why the statement matches or contradicts the audio.
4. "textToSpeak": The factual sentence that the TTS reads aloud.
5. "statement": A text statement that the user reads, which is either true or false based on the audio.
6. "correctAnswer": "true" or "false".
7. "emoji": A relevant emoji.
8. "evidenceQuote": The exact part of `textToSpeak` that proves the answer.
```

### 49. Detail Spotlight (`detailSpotlight_X_Y.json`)
```text
1. "instruction": "Listen to the audio and select the correct detail."
2. "hint": Clue focusing on a specific, tiny detail (e.g., a color, a number).
3. "explanation": Confirm what the audio said.
4. "textToSpeak": The sentence containing the detail.
5. "targetDetail": The specific word they need to hear.
6. "options": Array of 4 details (1 correct, 3 wrong).
7. "correctAnswerIndex": Integer index.
8. "emoji": A relevant emoji.
9. "detailCategory": Category of the detail (e.g., "Key Information", "Color", "Time").
```

### 50. Emotion Recognition (`emotionRecognition_X_Y.json`)
```text
1. "instruction": "Listen to the audio and select the matching emotion."
2. "hint": A clue about the tone or vocabulary used.
3. "explanation": Detail how the words reveal the speaker's feelings.
4. "textToSpeak": A sentence rich with emotion, exclamation, or tone.
5. "options": Array of 4 emotions with emojis attached (e.g., ["happy 😊", "sad 😢"]).
6. "correctAnswerIndex": Integer index.
7. "emoji": The correct emotion's emoji.
8. "emotionScale": Integer from 1-5 indicating intensity.
```

### 51. Fast Speech Decoder (`fastSpeechDecoder_X_Y.json`)
```text
1. "instruction": "Listen to the audio and select the exact spoken sentence."
2. "hint": A clue about a specific contraction, linking sound, or reduced vowel.
3. "explanation": Explain how native speakers shrink or blend the words (e.g., "sister's" instead of "sister is").
4. "textToSpeak": A sentence that contains natural native-speaker reductions.
5. "options": Array of 4 highly similar sentences (e.g., differing by one small grammar word).
6. "correctAnswerIndex": Integer index.
7. "emoji": Relevant emoji.
8. "slowVersion": Write out the uncontracted, fully enunciated version of the sentence.
```

### 52. Listening Inference (`listeningInference_X_Y.json`)
```text
1. "instruction": "Listen to the audio and answer the question."
2. "hint": A clue about reading between the lines of what is said.
3. "explanation": Detail the subtext or implication.
4. "textToSpeak": A sentence that implies something without directly stating it.
5. "question": "What does the speaker imply?" or "How does she feel?"
6. "options": Array of 4 inferences.
7. "correctAnswerIndex": Integer index.
8. "emoji": Relevant emoji.
9. "literalMeaning": What is actually said.
10. "impliedMeaning": The subtext.
```

### 53. Sound Image Match (`soundImageMatch_X_Y.json`)
```text
1. "instruction": "Listen to the audio and select the matching image."
2. "hint": Clue about the specific object mentioned.
3. "explanation": Confirm the object in the sentence.
4. "textToSpeak": A sentence containing the target noun.
5. "options": Array of 4 nouns. (In the UI, these will be converted to icons/images).
6. "correctAnswerIndex": Integer index.
7. "emoji": Relevant emoji.
8. "imageDescriptions": Array of 4 descriptions of the images (e.g., ["Image of spoon", "Image of apple"]).
```

---

## SPEAKING GAME SCHEMAS
*(Use the same Bulletproof Base Prompt, but paste one of these Speaking schemas below it!)*

### 54. Daily Expression (`dailyExpression_X_Y.json`)
```text
1. "instruction": "Speak the expression."
2. "hint": A clue about the idiom or phrase.
3. "explanation": State the origin or reason behind the expression.
4. "meaning": A clear, direct definition of the idiom.
5. "sampleUsage": A full sentence using the idiom naturally.
6. "expression" & "correctAnswer" & "textToSpeak": The exact idiom string (e.g., "Bite the bullet").
7. "situationExample": A brief context on when to use this (e.g., "Use this when meeting a friend.").
```

### 55. Dialogue Roleplay (`dialogueRoleplay_X_Y.json`)
```text
1. "instruction": "Respond to the dialogue."
2. "hint": A clue on how to respond.
3. "explanation": Detail why this response works culturally or grammatically.
4. "partnerDialogue": What the AI or "partner" says first.
5. "correctAnswer" & "sampleAnswer": The best, most natural response.
6. "smartReplies": Array of 3 natural, acceptable responses.
7. "acceptedSynonyms": Array of 4-5 acceptable speech-to-text variations (e.g., lowercase, missing punctuation).
```

### 56. Pronunciation Focus (`pronunciationFocus_X_Y.json`)
```text
1. "instruction": "Read the sentence aloud."
2. "hint": Focus on a specific phoneme.
3. "explanation": Describe exactly how to move the mouth/tongue to make the sound.
4. "textToSpeak": A sentence rich with the target phoneme.
5. "targetPhoneme": The IPA bracketed sound (e.g., "[p]").
6. "phoneticHint": A tip on where the sound occurs in the sentence.
7. "commonMistakes": Array of 1 string highlighting a frequent error.
```

### 57. Repeat Sentence (`repeatSentence_X_Y.json`)
```text
1. "instruction": "Repeat the sentence."
2. "hint": A tip on linking sounds or word stress.
3. "explanation": A brief grammar/usage note about the sentence.
4. "textToSpeak" & "correctAnswer": The exact sentence to repeat.
5. "pronunciationTips": A string starting with "[IPA Tip]" offering a phonetic clue.
```

### 58. Scene Description (`sceneDescriptionSpeaking_X_Y.json`)
```text
1. "instruction": "Describe the scene."
2. "hint": A clue pointing to 3 specific items in the scene.
3. "explanation": Why learning these descriptive words is useful.
4. "sceneText": A pipe-separated string: "Scene Title|Task 1|Task 2|Task 3".
5. "options": Array of 3 key items from the scene.
6. "correctAnswer": The primary item being highlighted.
7. "sampleAnswer": A full, fluent sentence describing the scene.
8. "acceptedSynonyms": Array of 3 comma-separated strings matching the options.
9. "keyVocabulary": Array of 3-4 keywords to learn.
```

### 59. Situation Speaking (`situationSpeaking_X_Y.json`)
```text
1. "instruction": "Respond to the situation."
2. "hint": A clue about politeness level or phrasing.
3. "explanation": Why this specific phrasing is natural for native speakers.
4. "situationText": A description of the scenario (e.g., "You are ordering a latte...").
5. "correctAnswer": The core phrase required to pass.
6. "sampleAnswer": A full, perfect response to the situation.
7. "acceptedSynonyms": Array of 4-5 acceptable speech-to-text variations.
```

### 60. Speak Missing Word (`speakMissingWord_X_Y.json`)
```text
1. "instruction": "Speak the missing word."
2. "hint": A clue about the missing word.
3. "explanation": Grammar/usage context for the word.
4. "textToSpeak": A sentence with "___" where the word is missing.
5. "missingWord": The exact missing string.
6. "correctAnswer": The fully assembled correct sentence.
7. "contextClue": A short tip about the word's usage.
```

### 61. Speak Opposite (`speakOpposite_X_Y.json`)
```text
1. "instruction": "Speak the opposite of the highlighted word."
2. "hint": A clue guiding them to the antonym.
3. "explanation": Confirm the correct answer and define it.
4. "textToSpeak": A sentence with the target word wrapped in asterisks (e.g., "*hot*").
5. "correctAnswer": The exact opposite word.
6. "acceptedSynonyms": Array of 4-5 valid antonyms.
7. "bonusAntonyms": Array of 1 additional antonym.
```

### 62. Speak Synonym (`speakSynonym_X_Y.json`)
```text
1. "instruction": "Say a synonym for the highlighted word."
2. "hint": A definition-based clue.
3. "explanation": Detail why the synonym fits perfectly in this context.
4. "textToSpeak": A sentence with the target word wrapped in asterisks.
5. "correctAnswer": The best synonym.
6. "acceptedSynonyms": Array of 4-5 valid synonyms.
```

### 63. Yes/No Speaking (`yesNoSpeaking_X_Y.json`)
```text
1. "instruction": "Listen and tilt to yes if the audio matches the text, or no if it doesn't."
2. "hint": A tip on what to listen for (e.g., the subject).
3. "explanation": Detail exactly what changed between the text and audio.
4. "prompt": The base sentence text.
5. "sampleAnswer": The modified sentence that the audio actually plays.
6. "followUpQuestion": Usually just "Why do you think that?".
```

---

## WRITING GAME SCHEMAS
*(Use the same Bulletproof Base Prompt, but paste one of these Writing schemas below it!)*

### 64. Complete Sentence (`completeSentence_X_Y.json`)
```text
1. "instruction": "Complete the sentence."
2. "partialSentence": A sentence with "____" for the missing word.
3. "options": Array of 4 grammatically similar words.
4. "correctAnswer": The exact missing string.
5. "hint": A grammar clue.
6. "explanation": Explain why this specific word fits grammatically.
7. "grammarFocus": The grammar topic being tested (e.g., "General Grammar").
```

### 65. Correction Writing (`correctionWriting_X_Y.json`)
```text
1. "instruction": "Correct the grammatical error in the sentence."
2. "passage": A sentence containing a bracketed error (e.g., "The dogs [is] barking").
3. "options": Array of 4 replacements (1 correct, 3 distractors).
4. "correctAnswer": The exact correct replacement phrase.
5. "hint": Clue about the error.
6. "explanation": Detail the grammar rule.
7. "errorCount": Integer (usually 3 distractors means 3 errors to avoid).
```

### 66. Daily Journal (`dailyJournal_X_Y.json`)
```text
1. "instruction": "Write a daily journal entry."
2. "prompt": The journal prompt to answer.
3. "options": Array of 3 keywords the user must include in their answer.
4. "sampleAnswer": A model full-sentence response using all keywords.
5. "hint": A tip on structure or tense.
6. "explanation": Detail why the sample answer is well-written.
7. "promptQuestions": Array of 2 strings with follow-up or guiding questions.
```

### 67. Describe Situation (`describeSituationWriting_X_Y.json`)
```text
1. "instruction": "TAP FLOATING EMOJIS AND CONSTRUCT A SITUATION DESCRIPTION"
2. "situation": The writing prompt/scenario.
3. "emojis": Array of exactly 4 emojis relevant to the scenario.
4. "keywords": A JSON object mapping strings "0", "1", "2", "3" to arrays of 3 uppercase strings each (e.g., `"0": ["ALARM", "WAKE", "MORNING"]`).
5. "minWords": Integer (e.g., 15) for minimum word count.
6. "hint": A clue for structuring the paragraph.
7. "explanation": Explain the structure or vocabulary used.
8. "modelAnswer": A fully written paragraph demonstrating a perfect response.
```

### 68. Essay Drafting (`essayDrafting_X_Y.json`)
```text
1. "instruction": "SEQUENCE THE PARAGRAPH BLOCKS TO COMPLETE THE ARCHITECT BLUEPRINT"
2. "essayTopic": The overall topic question.
3. "requiredPoints": Array of 4 structural labels (e.g., ["Topic Sentence", "First Reason", "Second Reason", "Closing Sentence"]).
4. "options": Array of 4 full sentences representing the essay parts, scrambled.
5. "correctOrder": Array of integers mapping the `options` into logical paragraph order.
6. "hint": Clue on identifying the topic sentence or conclusion.
7. "explanation": Explain the logical flow of the paragraph.
8. "essayType": Category string (e.g., "Opinion", "Persuasive").
```

### 69. Fix The Sentence (`fixTheSentence_X_Y.json`)
```text
1. "instruction": "Tap or scrub the incorrect word to restore the sentence."
2. "passage": A sentence containing one specific wrong word.
3. "missingWord": The word that is currently wrong in the passage (e.g., "like" in "She like dogs").
4. "options": Array of 4 conjugations/forms of the word.
5. "correctAnswer": The fixed word (e.g., "likes").
6. "hint": Grammar clue.
7. "explanation": State the grammar rule applied.
8. "errorType": String (e.g., "Grammar Error").
```

### 70. Opinion Writing (`opinionWriting_X_Y.json`)
```text
1. "instruction": "Decide if each statement is a Pro (it supports the opinion) or a Con (it argues against it)."
2. "prompt": The central opinion statement.
3. "options": Array of 4 arguments (some pros, some cons).
4. "correctOrder": Array of 2 integers representing the indices of the "Pro" arguments from the options list.
5. "hint": A clue differentiating pros vs cons.
6. "explanation": Detail why the answers are pros/cons.
7. "structureGuide": String (e.g., "Intro, Body, Conclusion").
```

### 71. Sentence Builder (`sentenceBuilder_X_Y.json`)
```text
1. "instruction": "Build the sentence."
2. "shuffledWords": Array of strings representing a scrambled sentence.
3. "correctAnswer": The perfectly assembled sentence string.
4. "hint": Grammar clue about word order.
5. "explanation": Identify Subject-Verb-Object flow.
6. "sentenceType": String (e.g., "statement", "question").
```

### 72. Short Answer Writing (`shortAnswerWriting_X_Y.json`)
```text
1. "instruction": "Write a short, natural answer to the prompt below, using all three key words."
2. "prompt": A question to answer.
3. "options": Array of 3 lowercase keywords that must be used.
4. "sampleAnswer": A model full-sentence response.
5. "hint": A tip on grammar or linking words.
6. "explanation": Describe the grammar used in the sample answer.
7. "keywordsExpected": Array of strings (can mirror options).
```

### 73. Summarize Story (`summarizeStoryWriting_X_Y.json`)
```text
1. "instruction": "Arrange the story in the correct order."
2. "story": A short 3-sentence narrative.
3. "options": Array of 4 sentences (3 are events from the story scrambled, 1 is a false distractor).
4. "correctOrder": Array of 3 integers mapping the true events from `options` into chronological order.
5. "hint": Clue identifying the false distractor or the first event.
6. "explanation": Summarize the chronological flow.
7. "storyKeyEvents": Array of strings (labels for the events).
```

### 74. Writing Email (`writingEmail_X_Y.json`)
```text
1. "instruction": "ARRANGE THE EMAIL PARTS INTO THE CORRECT ORDER"
2. "prompt": The writing scenario.
3. "options": Array of 4 email components (Subject, Greeting, Body, Sign-off) completely scrambled.
4. "correctOrder": Array of 4 integers mapping `options` into standard email format (Subject -> Greeting -> Body -> Sign-off).
5. "hint": A clue about email formatting rules.
6. "explanation": Explain standard email structure.
7. "formatRequirements": String (e.g., "Standard Email Format").
```

---

## ROLEPLAY GAME SCHEMAS
*(Use the same Bulletproof Base Prompt, but paste one of these Roleplay schemas below it!)*

### 75. Branching Dialogue (`branchingDialogue_X_Y.json`)
```text
1. "instruction": "Usually 'Choose the best response'."
2. "persona": The persona the user is talking to (e.g., "The Interviewer").
3. "scene": Description of the scenario.
4. "options": Array of 3 responses.
5. "correctAnswerIndex": Integer (0, 1, or 2).
6. "hint": A clue for the best response.
7. "explanation": Detail why the correct option is best.
8. "consequencePreviews": Array of 3 strings mapping exactly to the `options`, showing how the persona would react.
```

### 76. Conflict Resolver (`conflictResolver_X_Y.json`)
```text
1. "instruction": "Usually 'Select the most de-escalating response'."
2. "scene": Description of the conflict scenario.
3. "options": Array of 3 responses.
4. "correctAnswer": The string of the correct response (must exactly match one of the options).
5. "hint": A clue for de-escalation.
6. "explanation": Detail why the correct response works.
7. "empathyScore": Float between 0.0 and 1.0 (e.g., 0.8) rating the correct answer's empathy.
8. "escalationLevel": Integer (usually 1 to 5) indicating the severity of the conflict.
```

### 77. Elevator Pitch (`elevatorPitch_X_Y.json`)
```text
1. "instruction": "Usually 'Choose the most effective pitch'."
2. "prompt": The scenario requiring a pitch.
3. "options": Array of 3 pitches.
4. "correctAnswer": The exact string of the best pitch.
5. "hint": A clue focusing on brevity and impact.
6. "explanation": Explain why the pitch is effective.
7. "timeLimit": Integer representing seconds (e.g., 30 or 60).
```

### 78. Emergency Hub (`emergencyHub_X_Y.json`)
```text
1. "instruction": "Usually 'Select the clearest emergency response'."
2. "dispatcherQuestion": The question from the 911/emergency dispatcher.
3. "options": Array of 3 responses.
4. "correctAnswer": The exact string of the correct response.
5. "hint": A clue emphasizing clarity and urgency.
6. "explanation": Explain why the response is the most helpful for emergency services.
7. "urgencyLevel": Integer (usually 1 to 5).
```

### 79. Gourmet Order (`gourmetOrder_X_Y.json`)
```text
1. "instruction": "Usually 'Listen to the order and select the correct items'."
2. "prompt": The text representing what the customer said (this will be read aloud by TTS).
3. "options": Array of 4-6 menu items (e.g., ["Latte", "Espresso", "Croissant", "Muffin"]).
4. "correctAnswer": A single string of comma-separated correct items (e.g., "Latte, Croissant").
5. "hint": A clue about what was ordered.
6. "explanation": Detail the items requested by the customer.
7. "menuItems": Array of objects, each with a "name" and "price" (e.g., `[{"name": "Latte", "price": 4.5}]`).
```

### 80. Job Interview (`jobInterview_X_Y.json`)
```text
1. "instruction": "Choose the response that shows the most professionalism."
2. "interviewerQuestion": The question asked by the interviewer.
3. "options": Array of 3 responses.
4. "correctAnswerIndex": Integer (0, 1, or 2).
5. "professionalismRating": Integer (usually 5) rating the correct response.
6. "hint": A clue for interviewing best practices.
7. "explanation": Detail why the correct option is most professional.
8. "interviewerReaction": Array of 3 strings ("impressed", "disappointed", etc.) mapping exactly to the `options`.
```

### 81. Medical Consult (`medicalConsult_X_Y.json`)
```text
1. "instruction": "Select the symptom that matches what the patient says."
2. "prompt": The patient's statement.
3. "symptoms": Array of 4 medical symptoms/conditions.
4. "correctAnswer": The exact string of the correct symptom.
5. "hint": A clue for the medical term.
6. "explanation": Define the symptom.
7. "medicalVocab": Array of 3 related medical vocabulary words.
```

### 82. Situational Response (`situationalResponse_X_Y.json`)
```text
1. "instruction": "Choose the bubble that fits the mood."
2. "scene": Description of a situation.
3. "options": Array of 4 moods or emotions (e.g., "Angry", "Happy").
4. "correctAnswerIndex": Integer (0, 1, 2, or 3).
5. "hint": A clue about how someone would feel in the situation.
6. "explanation": Explain the emotion.
7. "culturalNote": A note on how this situation is culturally perceived.
8. "formalityScore": Integer (e.g., 50).
```

### 83. Social Spark (`socialSpark_X_Y.json`)
```text
1. "instruction": "Arrange the words to..."
2. "shuffledWords": Array of strings representing a scrambled phrase/sentence.
3. "correctAnswer": The perfectly assembled sentence string.
4. "hint": A clue on how to start or end the sentence.
5. "explanation": Explain the social context or phrase usage.
6. "socialContext": String (e.g., "Train Station", "House Party").
```

### 84. Travel Desk (`travelDesk_X_Y.json`)
```text
1. "instruction": "Match the destination to the traveler's request."
2. "prompt": The traveler's request.
3. "itinerary": Array of 4 long location names (e.g., "Neighborhood Post Office").
4. "options": Array of 4 short location names (e.g., "Post Office").
5. "correctAnswerIndex": Integer (0, 1, 2, or 3).
6. "hint": A clue to identify the location.
7. "explanation": Detail why the location fits the need.
8. "travelDocuments": String (e.g., "City Map", "Passport").
```

---

## ELITE MASTERY GAME SCHEMAS
*(Use the same Bulletproof Base Prompt, but paste one of these Elite Mastery schemas below it!)*

### 85. Accent Shadowing (`accentShadowing_X_Y.json`)
```text
1. "instruction": "Usually 'Listen and repeat the sentence exactly as you hear it'."
2. "textToSpeak": The sentence the user will shadow.
3. "hint": A pronunciation tip (e.g., stress, linking).
4. "explanation": Detail the pronunciation rule being tested.
5. "shadowingFocus": String (e.g., "Focus: Connected Speech", "Focus: Word & Phrase Stress").
6. "targetAccent": String (e.g., "Received Pronunciation (RP)", "General American (GA)").
```

### 86. Idiom Match (`idiomMatch_X_Y.json`)
```text
1. "instruction": "Usually 'Select the matching idiom'."
2. "question": A scenario where an idiom is needed.
3. "options": Array of 4 idioms.
4. "correctAnswerIndex": Integer (0, 1, 2, or 3).
5. "hint": A clue to the idiom's meaning or imagery.
6. "explanation": Explain the meaning and usage of the correct idiom.
7. "usageContext": Detail when and how it is appropriate to use the idiom.
8. "idiomOrigin": Brief historical origin or literal meaning.
9. "visualMetaphor": A visual image helping to remember the idiom.
```

### 87. Speed Spelling (`speedSpelling_X_Y.json`)
```text
1. "instruction": "Usually 'Spell the word'."
2. "word": The target word to spell.
3. "hint": A clue about the tricky part of the spelling.
4. "explanation": Explain the spelling rule or pattern.
5. "spellingRule": String describing the pattern (e.g., "Pattern: Orthographic Memorization", "Pattern: Silent Letter Rules").
6. "difficultyTier": String (e.g., "Common", "Advanced").
```

### 88. Story Builder (`storyBuilder_X_Y.json`)
```text
1. "instruction": "Usually 'Read the sentences and arrange them in the correct order'."
2. "sentences": Array of 4 sentences that make up a coherent story (can be scrambled or ordered, but standard is chronological order mapped by correctOrder).
3. "correctOrder": Array of 4 integers mapping the `sentences` into logical chronological order (e.g., [0, 1, 2, 3] if sentences are already ordered, or [2, 0, 1, 3] if scrambled).
4. "hint": Clue for the starting sentence or sequence logic.
5. "explanation": Summarize the logical flow of the story.
6. "sequenceLogic": String (e.g., "Cause & Effect", "Chronological Order").
7. "plotStructure": String (e.g., "Beginning, Middle, Climax, Ending").
```

---

## ACCENT & PRONUNCIATION GAMES
*(Use the same Bulletproof Base Prompt, but paste one of these Accent schemas below it!)*

### 89. Connected Speech (`connectedSpeech_X_Y.json`)
```text
1. "instruction": "Listen and identify the connected speech."
2. "textToSpeak": The sentence spoken with natural linking.
3. "hint": A clue about how words blend together.
4. "explanation": Detail the phonetic linking rule.
5. "options": Array of 4 phonetic representations.
6. "correctAnswerIndex": Integer index.
7. "linkingRule": String describing the rule (e.g., "Consonant to Vowel").
```

### 90. Consonant Clarity (`consonantClarity_X_Y.json`)
```text
1. "instruction": "Select the correct consonant sound."
2. "textToSpeak": The spoken word/sentence.
3. "hint": A clue about tongue or lip placement.
4. "explanation": Detail how to produce the consonant sound.
5. "options": Array of 4 similar words.
6. "correctAnswerIndex": Integer index.
7. "targetConsonant": The IPA symbol (e.g., "[θ]").
```

### 91. Dialect Drill (`dialectDrill_X_Y.json`)
```text
1. "instruction": "Which pronunciation is British/American?"
2. "word": The target word.
3. "options": Array of 2 strings (e.g., ["LAHT (American)", "LOT (British)"]).
4. "correctAnswerIndex": Integer index.
5. "hint": A pronunciation clue comparing the vowels.
6. "explanation": Explain the difference between the two dialects.
7. "dialectNote": The specific phonetic rule difference.
8. "dialectRegion": String (e.g., "United Kingdom", "United States").
```

### 92. Intonation Mimic (`intonationMimic_X_Y.json`)
```text
1. "instruction": "Identify the intonation."
2. "word" & "textToSpeak": The spoken sentence.
3. "options": Array of 2 strings (e.g., ["Falling Intonation", "Rising Intonation"]).
4. "correctAnswer": String matching one of the options.
5. "correctAnswerIndex": Integer index.
6. "intonationMap": Array of 4 integers representing pitch (e.g., [2, 2, 1, 0]).
7. "hint": A clue about the pitch direction.
8. "explanation": Detail the meaning behind this intonation pattern.
```

### 93. Minimal Pairs (`minimalPairs_X_Y.json`)
```text
1. "instruction": "Listen carefully, then select the word you hear."
2. "word1" & "word2": The two minimal pair words.
3. "ipa1" & "ipa2": The IPA transcriptions.
4. "textToSpeak" & "correctAnswer": The specific word spoken.
5. "options": Array of 2 strings (the minimal pairs).
6. "correctAnswerIndex": Integer index.
7. "hint": A clue comparing vowel length or consonant voicing.
8. "explanation": Detailed phonetic distinction.
9. "vowelTensionRule": The linguistic rule for vowels (or "consonantVoicingRule").
10. "mouthPosition": Description of physical mouth shape.
```

### 94. Pitch Modulation (`pitchModulation_X_Y.json`)
```text
1. "instruction": "Identify the emphasized word."
2. "textToSpeak": The sentence with one word pitched higher.
3. "hint": A clue about the stress.
4. "explanation": Why pitch changes meaning here.
5. "options": Array of 4 words from the sentence.
6. "correctAnswerIndex": Integer index.
```

### 95. Pitch Pattern Match (`pitchPatternMatch_X_Y.json`)
```text
1. "instruction": "Match the pitch pattern."
2. "textToSpeak": The spoken word/phrase.
3. "hint": A pitch clue.
4. "explanation": Detail the intonation curve.
5. "options": Array of 4 pattern descriptions.
6. "correctAnswerIndex": Integer index.
```

### 96. Shadowing Challenge (`shadowingChallenge_X_Y.json`)
```text
1. "instruction": "Shadow the speaker perfectly."
2. "textToSpeak": The target sentence.
3. "hint": Clue on rhythm and pacing.
4. "explanation": Detail the natural flow.
5. "rhythmBreaks": Array of strings showing where to pause.
6. "targetFluency": String (e.g., "Smooth connected speech").
```

### 97. Speed Variance (`speedVariance_X_Y.json`)
```text
1. "instruction": "Understand the fast speech."
2. "textToSpeak": The sentence spoken quickly.
3. "hint": Clue about reductions (e.g., 'gonna').
4. "explanation": Breakdown of the fast speech elements.
5. "slowVersion": The uncontracted, fully enunciated version.
6. "options": Array of 4 interpretations.
7. "correctAnswerIndex": Integer index.
```

### 98. Syllable Stress (`syllableStress_X_Y.json`)
```text
1. "instruction": "Identify the stressed syllable."
2. "word": The target word.
3. "options": Array of syllables with one capitalized (e.g., ["pho-TO-graph", "PHO-to-graph"]).
4. "correctAnswerIndex": Integer index.
5. "hint": A clue about word stress rules.
6. "explanation": Explain why this syllable receives primary stress.
7. "stressRule": String describing the rule (e.g., "Noun vs Verb stress").
```

### 99. Vowel Distinction (`vowelDistinction_X_Y.json`)
```text
1. "instruction": "Select the correct vowel sound."
2. "textToSpeak": The target word/sentence.
3. "options": Array of 4 words with different vowels.
4. "correctAnswerIndex": Integer index.
5. "hint": Clue on lip rounding or tongue height.
6. "explanation": Detail the IPA vowel differences.
7. "targetVowel": IPA symbol (e.g., "[æ]").
```

### 100. Word Linking (`wordLinking_X_Y.json`)
```text
1. "instruction": "Identify how the words link."
2. "textToSpeak": Phrase demonstrating linking.
3. "hint": Clue on consonant-vowel bridging.
4. "explanation": Describe the phonetic bridge.
5. "options": Array of 4 linking pairs (e.g., ["an_apple", "a_napple"]).
6. "correctAnswerIndex": Integer index.
7. "linkingType": String (e.g., "Intrusion", "Elision", "Catenation").
```

---

---

## 🛡️ KIDS ZONE BASE PROMPT
*Copy this exact text, paste it into Claude, and then paste your specific Kids game schema below it.*

```text
I am uploading 20 JSON batch files for the Kids Zone of a language learning application. You are acting as an expert early-childhood curriculum designer and strict JSON data generator. 

Your objective is to upgrade the pedagogical content of these files to absolute 10/10 quality. 

CRITICAL RULES TO PREVENT AI LOOPHOLES:
1. STRICT PROGRESSION: The curriculum is progressively scaled. As the levels increase from Level 1 to Level 200, the difficulty of the questions, the complexity of the hints, and the rarity of the target words MUST increase.
2. ZERO REPETITION: You must NEVER repeat a target word, question, hint, or fun fact across the 20 batches. Every single quest must be 100% unique. 
3. ZERO MOCKING: Do not use placeholders like "..." or "Continue for other levels". Output the fully expanded, complete JSON arrays.
4. CHILD-FRIENDLY TONE: Use a polite, encouraging, and age-appropriate tone. Use emojis generously in the string fields and keep `funFact` sentences short and fascinating for kids.

WORKFLOW:
Do NOT generate all files at once. 
Start by generating ONLY the fully updated JSON for the very first batch file (e.g., `batch_1.json`). 
Return ONLY the raw, perfectly formatted JSON array so I can copy and paste it.

Here is the exact schema for the specific kids game you are updating:

[PASTE THE SPECIFIC KIDS GAME SCHEMA BELOW]
```

---

## KIDS ZONE SCHEMAS (25 Categories)

Kids Zone JSONs are structured as an Array of Levels, where each Level contains an Array of `quests`. The difficulty (risk) must increase progressively from Level 1 to Level 10 (or 20). Questions must NEVER be repeated.

### 101. Kids Alphabet (`alphabet_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_ALPHABET_L[level]_Q[questionNumber]"
  2. "gameType": "alphabet"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "explanation": String
  10. "wordExample": String
  11. "wordEmoji": String (often Emoji or text)
  12. "capitalLetter": String
  13. "phonetic": String
  14. "funFact": String
```

### 102. Kids Animals (`animals_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_ANIMALS_L[level]_Q[questionNumber]"
  2. "gameType": "animals"
  3. "level": Integer
  4. "instruction": String
  5. "correctAnswer": String (often Emoji or text)
  6. "options": Array of 3 Strings
  7. "hint": String
  8. "explanation": String
  9. "animalSound": String
  10. "funFact": String
  11. "question": String
```

### 103. Kids Body_parts (`body_parts_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_BODY_PARTS_L[level]_Q[questionNumber]"
  2. "gameType": "body_parts"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 104. Kids Clothing (`clothing_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_CLOTHING_L[level]_Q[questionNumber]"
  2. "gameType": "clothing"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 105. Kids Colors (`colors_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_COLORS_L[level]_Q[questionNumber]"
  2. "gameType": "colors"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 106. Kids Day_night (`day_night_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_DAY_NIGHT_L[level]_Q[questionNumber]"
  2. "gameType": "day_night"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 107. Kids Emotions (`emotions_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_EMOTIONS_L[level]_Q[questionNumber]"
  2. "gameType": "emotions"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 108. Kids Family (`family_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_FAMILY_L[level]_Q[questionNumber]"
  2. "gameType": "family"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 109. Kids Food (`food_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_FOOD_L[level]_Q[questionNumber]"
  2. "gameType": "food"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 110. Kids Fruits (`fruits_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_FRUITS_L[level]_Q[questionNumber]"
  2. "gameType": "fruits"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 111. Kids Handwriting (`handwriting_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_HANDWRITING_L[level]_Q[questionNumber]"
  2. "gameType": "handwriting"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "hint": String
  8. "explanation": String
  9. "funFact": String
```

### 112. Kids Home (`home_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_HOME_L[level]_Q[questionNumber]"
  2. "gameType": "home"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 113. Kids Nature (`nature_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_NATURE_L[level]_Q[questionNumber]"
  2. "gameType": "nature"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 114. Kids Numbers (`numbers_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_NUMBERS_L[level]_Q[questionNumber]"
  2. "gameType": "numbers"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "explanation": String
  10. "funFact": String
```

### 115. Kids Opposites (`opposites_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_OPPOSITES_L[level]_Q[questionNumber]"
  2. "gameType": "opposites"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 116. Kids Phonics (`phonics_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_PHONICS_L[level]_Q[questionNumber]"
  2. "gameType": "phonics"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 117. Kids Prepositions (`prepositions_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_PREPOSITIONS_L[level]_Q[questionNumber]"
  2. "gameType": "prepositions"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 118. Kids Professions (`professions_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_PROFESSIONS_L[level]_Q[questionNumber]"
  2. "gameType": "professions"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "options": Array of 3 Strings
  7. "correctAnswer": String (often Emoji or text)
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 119. Kids Routine (`routine_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_ROUTINE_L[level]_Q[questionNumber]"
  2. "gameType": "routine"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 120. Kids School (`school_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_SCHOOL_L[level]_Q[questionNumber]"
  2. "gameType": "school"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 121. Kids Shapes (`shapes_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_SHAPES_L[level]_Q[questionNumber]"
  2. "gameType": "shapes"
  3. "level": Integer
  4. "instruction": String
  5. "correctAnswer": String (often Emoji or text)
  6. "options": Array of 3 Strings
  7. "hint": String
  8. "emoji": String (often Emoji or text)
  9. "explanation": String
  10. "funFact": String
  11. "subtype": String
  12. "interactionType": String
```

### 122. Kids Time (`time_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_TIME_L[level]_Q[questionNumber]"
  2. "gameType": "time"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
  12. "subtype": String
  13. "interactionType": String
```

### 123. Kids Transport (`transport_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_TRANSPORT_L[level]_Q[questionNumber]"
  2. "gameType": "transport"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 124. Kids Verbs (`verbs_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_VERBS_L[level]_Q[questionNumber]"
  2. "gameType": "verbs"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "correctAnswer": String (often Emoji or text)
  7. "options": Array of 3 Strings
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

### 125. Kids Weather (`weather_batch_X.json`)
```text
Array of Objects, each containing:
- "level": Integer
- "quests": Array of Objects (3 questions per level)
  1. "id": "KIDS_WEATHER_L[level]_Q[questionNumber]"
  2. "gameType": "weather"
  3. "level": Integer
  4. "instruction": String
  5. "question": String
  6. "options": Array of 3 Strings
  7. "correctAnswer": String (often Emoji or text)
  8. "hint": String
  9. "emoji": String (often Emoji or text)
  10. "explanation": String
  11. "funFact": String
```

---

---

## 🛡️ DAILY FEATURES BASE PROMPT
*Copy this exact text, paste it into Claude, and then paste your specific Daily Feature schema below it.*

```text
I am uploading the JSON file(s) for the Daily Features of a language learning application. You are acting as an expert linguist and strict JSON data generator. 

Your objective is to upgrade and harden the content of this file to absolute 10/10 production-ready quality. 

CRITICAL RULES TO PREVENT AI LOOPHOLES:
1. STRICT SCHEMA COMPLIANCE: Do not invent new keys. Exactly follow the schema provided below.
2. ADULT, MOTIVATIONAL TONE: If writing messages (e.g., Calendar), the tone should be highly motivational, philosophical, and encouraging for adult learners, focusing on consistency and growth.
3. PROGRESSIVE SCALING: If writing challenges or daily words, the difficulty must progressively increase. 
4. ZERO MOCKING / HALLUCINATIONS: Do not use placeholders. You must completely fill out every array and object requested with 100% unique, thoughtful content.

WORKFLOW:
Output the fully updated, robust JSON. Return ONLY the raw, perfectly formatted JSON so I can copy and paste it.

Here is the exact schema for the specific Daily Feature you are updating:

[PASTE THE SPECIFIC DAILY FEATURE SCHEMA BELOW]
```

---

## DAILY FEATURES SCHEMAS (5 Categories)

These files handle daily engagement, spaced repetition, and real-world interactions.

### 126. Daily Words (`daily_words_XXX_YYY.json`)
```text
Object containing:
- "days": Array of Objects
  - "day": Integer
  - "theme": String
  - "words": Array of 10 Objects
    1. "id": "dw_XXXX"
    2. "word": String
    3. "phonetic": String
    4. "partOfSpeech": String
    5. "definition": String
    6. "example": String
    7. "difficulty": Integer (1-5)
    8. "frequencyRank": Integer
```

### 127. Calendar (`vowl_calendar.json`)
```text
Object containing:
1. "annual": Object mapping dates (MM-DD) to {"title": String, "text": String}
2. "specific": Object mapping full dates (YYYY-MM-DD) to {"title": String, "text": String}
3. "monthly": Object mapping months (01-12) to {"theme": String, "messages": Array of Strings}
```

### 128. Daily Challenges (`daily_challenges.json`)
```text
Object containing keys for challenge types mapping to an Array of Objects.
For "word_snap":
  1. "id": Integer
  2. "word": String
  3. "question": String
  
For "word_mixer":
  1. "id": Integer
  2. "word": String
  3. "hint": String
```

### 129. Photo Bounties (`photo_bounties.json`)
```text
Array of Strings representing simple, findable real-world objects to find with the camera.
- Example: ["Coffee cup", "Keyboard", "Houseplant"]
```

### 130. Scan Bounties (`scan_bounties.json`)
```text
Array of Strings representing simple text or objects to scan.
- Example: ["Stop sign", "Barcode", "Book cover"]
```
