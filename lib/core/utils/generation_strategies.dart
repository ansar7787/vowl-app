import 'package:vowl/core/domain/entities/game_quest.dart';

class PromptStrategy {
  String getSpecificInstructions(QuestType skill, GameSubtype subtype) {
    switch (subtype) {
      // Category: Speaking (10)
      case GameSubtype.repeatSentence:
        return '{"id": "rs_L{LEVEL}_{ITEM}", "instruction": "Listen and repeat exactly what you hear.", "type": "speaking", "subtype": "repeatSentence", "difficulty": {LEVEL}, "textToSpeak": "{SENTENCE}", "xpReward": 10, "coinReward": 5, "livesAllowed": 3}';
      case GameSubtype.speakMissingWord:
        return '{"id": "smw_L{L}_{I}", "instruction": "Speak the missing word.", "type": "speaking", "subtype": "speakMissingWord", "difficulty": {L}, "textToSpeak": "{SENTENCE_WITH_BLANK}", "correctAnswer": "{MISSING_WORD}", "xpReward": 10, "coinReward": 5}';
      case GameSubtype.situationSpeaking:
        return '{"id": "sit_L{L}_{I}", "instruction": "You are {SCENE}. {TASK}", "type": "speaking", "subtype": "situationSpeaking", "difficulty": {L}, "situationText": "{SCENARIO_DESC}", "xpReward": 10, "coinReward": 5}';
      case GameSubtype.sceneDescriptionSpeaking:
        return '{"id": "sd_L{L}_{I}", "instruction": "Describe this scene.", "type": "speaking", "subtype": "sceneDescriptionSpeaking", "difficulty": {L}, "sceneText": "{VISUAL_DESCRIPTION}", "xpReward": 10, "coinReward": 5}';
      case GameSubtype.yesNoSpeaking:
        return '{"id": "yn_L{L}_{I}", "instruction": "Answer Yes or No.", "type": "speaking", "subtype": "yesNoSpeaking", "difficulty": {L}, "textToSpeak": "{FACTUAL_QUESTION}", "correctAnswer": "{YES_OR_NO}", "xpReward": 10, "coinReward": 5}';
      case GameSubtype.speakSynonym:
        return '{"id": "syn_L{L}_{I}", "instruction": "Say a synonym.", "type": "speaking", "subtype": "speakSynonym", "difficulty": {L}, "textToSpeak": "{WORD}", "acceptedSynonyms": ["{SYN1}", "{SYN2}"], "xpReward": 10, "coinReward": 5}';
      case GameSubtype.dialogueRoleplay:
        return '{"id": "dial_L{L}_{I}", "instruction": "Respond to the speaker.", "type": "speaking", "subtype": "dialogueRoleplay", "difficulty": {L}, "textToSpeak": "{SPEAKER_LINE}", "correctAnswer": "{APPROPRIATE_RESPONSE}", "xpReward": 10, "coinReward": 5}';
      case GameSubtype.pronunciationFocus:
        return '{"id": "pron_L{L}_{I}", "instruction": "Focus on clarity.", "type": "speaking", "subtype": "pronunciationFocus", "difficulty": {L}, "textToSpeak": "{DIFFICULT_WORD}", "phoneticHint": "{IPA_PHONETIC}", "xpReward": 10, "coinReward": 5}';
      case GameSubtype.speakOpposite:
        return '{"id": "opp_L{L}_{I}", "instruction": "Say the antonym.", "type": "speaking", "subtype": "speakOpposite", "difficulty": {L}, "textToSpeak": "{WORD}", "correctAnswer": "{ANTONYM}", "xpReward": 10, "coinReward": 5}';
      case GameSubtype.dailyExpression:
        return '{"id": "idm_L{L}_{I}", "instruction": "Practice this idiom.", "type": "speaking", "subtype": "dailyExpression", "difficulty": {L}, "textToSpeak": "{IDIOM}", "meaning": "{DEFINITION}", "sampleUsage": "{EXAMPLE_SENTENCE}", "xpReward": 10, "coinReward": 5}';

      // Category: Reading (10)
      case GameSubtype.readAndAnswer:
        return '{"id": "ra_L{L}_{I}", "instruction": "Answer based on text.", "type": "reading", "subtype": "readAndAnswer", "difficulty": {L}, "passage": "{STORY}", "question": "{Q}", "options": ["A", "B", "C"], "correctAnswerIndex": 0, "xpReward": 10, "coinReward": 5}';
      case GameSubtype.findWordMeaning:
        return '{"id": "fm_L{L}_{I}", "instruction": "What does the bold word mean?", "type": "reading", "subtype": "findWordMeaning", "difficulty": {L}, "passage": "{TEXT_WITH_WORD}", "highlightedWord": "{WORD}", "options": ["M1", "M2"], "correctAnswerIndex": 0, "xpReward": 10, "coinReward": 5}';
      case GameSubtype.trueFalseReading:
        return '{"id": "tf_L{L}_{I}", "instruction": "True or False?", "type": "reading", "subtype": "trueFalseReading", "difficulty": {L}, "passage": "{TEXT}", "statement": "{FACT_CHECK}", "correctAnswer": "True", "xpReward": 10, "coinReward": 5}';
      case GameSubtype.sentenceOrderReading:
        return '{"id": "ord_L{L}_{I}", "instruction": "Reorder the story.", "type": "reading", "subtype": "sentenceOrderReading", "difficulty": {L}, "shuffledSentences": ["S2", "S1", "S3"], "correctOrder": [1, 0, 2], "xpReward": 10, "coinReward": 5}';
      case GameSubtype.readingSpeedCheck:
        return '{"id": "sp_L{L}_{I}", "instruction": "Read fast.", "type": "reading", "subtype": "readingSpeedCheck", "difficulty": {L}, "passage": "{PARAGRAPH}", "xpReward": 10, "coinReward": 5}';
      case GameSubtype.guessTitle:
        return '{"id": "gt_L{L}_{I}", "instruction": "Pick the best title.", "type": "reading", "subtype": "guessTitle", "difficulty": {L}, "passage": "{TEXT}", "options": ["T1", "T2"], "correctAnswerIndex": 0}';
      case GameSubtype.readAndMatch:
        return '{"id": "match_L{L}_{I}", "instruction": "Match pairs.", "type": "reading", "subtype": "readAndMatch", "difficulty": {L}, "pairs": [{"term": "T1", "match": "M1"}, {"term": "T2", "match": "M2"}], "xpReward": 10, "coinReward": 5}';
      case GameSubtype.paragraphSummary:
        return '{"id": "sum_L{L}_{I}", "instruction": "Pick summary.", "type": "reading", "subtype": "paragraphSummary", "difficulty": {L}, "passage": "{TEXT}", "options": ["S1", "S2"], "correctAnswerIndex": 1}';
      case GameSubtype.readingInference:
        return '{"id": "r_inf_L{L}_{I}", "instruction": "Make an inference.", "type": "reading", "subtype": "readingInference", "difficulty": {L}, "passage": "{TEXT}"}';
      case GameSubtype.readingConclusion:
        return '{"id": "r_con_L{L}_{I}", "instruction": "Draw a conclusion.", "type": "reading", "subtype": "readingConclusion", "difficulty": {L}, "passage": "{TEXT}"}';

      // Category: Writing (10)
      case GameSubtype.sentenceBuilder:
        return '{"id": "sb_L{L}_{I}", "instruction": "Unscramble words.", "type": "writing", "subtype": "sentenceBuilder", "difficulty": {L}, "prompt": "Put in order.", "shuffledWords": ["the", "sat", "cat"], "correctSentence": "the cat sat"}';
      case GameSubtype.completeSentence:
        return '{"id": "cs_L{L}_{I}", "instruction": "Complete the thought.", "type": "writing", "subtype": "completeSentence", "difficulty": {L}, "prompt": "I enjoy...", "correctAnswer": "playing games", "xpReward": 10, "coinReward": 5}';
      case GameSubtype.describeSituationWriting:
        return '{"id": "ws_L{L}_{I}", "instruction": "Write a response.", "type": "writing", "subtype": "describeSituationWriting", "difficulty": {L}, "prompt": "{SCENARIO}", "sampleAnswer": "{MODEL_ANSWER}"}';
      case GameSubtype.fixTheSentence:
        return '{"id": "fix_L{L}_{I}", "instruction": "Correct the grammar.", "type": "writing", "subtype": "fixTheSentence", "difficulty": {L}, "incorrectSentence": "He go home.", "correctSentence": "He goes home."}';
      case GameSubtype.shortAnswerWriting:
        return '{"id": "sa_L{L}_{I}", "instruction": "Answer in a few words.", "type": "writing", "subtype": "shortAnswerWriting", "difficulty": {L}, "prompt": "{QUESTION}", "sampleAnswer": "{ANSWER}"}';
      case GameSubtype.opinionWriting:
        return '{"id": "op_L{L}_{I}", "instruction": "Give your opinion.", "type": "writing", "subtype": "opinionWriting", "difficulty": {L}, "topic": "{TITLE}", "sampleAnswer": "{MODEL_OPINION}"}';
      case GameSubtype.dailyJournal:
        return '{"id": "dj_L{L}_{I}", "instruction": "Write about your day.", "type": "writing", "subtype": "dailyJournal", "difficulty": {L}, "prompt": "{JOURNAL_PROMPT}", "sampleAnswer": "{MODEL_ENTRY}"}';
      case GameSubtype.summarizeStoryWriting:
        return '{"id": "w_ss_L{L}_{I}", "instruction": "Summarize the story.", "type": "writing", "subtype": "summarizeStoryWriting", "difficulty": {L}, "story": "{STORY}"}';
      case GameSubtype.correctionWriting:
        return '{"id": "w_corr_L{L}_{I}", "instruction": "Correct the text.", "type": "writing", "subtype": "correctionWriting", "difficulty": {L}, "text": "{BROKEN}"}';
      case GameSubtype.writingEmail:
        return '{"id": "w_em_L{L}_{I}", "instruction": "Write an email.", "type": "writing", "subtype": "writingEmail", "difficulty": {L}, "recipient": "{TO}", "context": "{INFO}"}';
      case GameSubtype.essayDrafting:
        return '{"id": "ed_L{L}_{I}", "instruction": "Draft an essay outline.", "type": "writing", "subtype": "essayDrafting", "difficulty": {L}, "topic": "{TOPIC}", "guidelines": "{PROMPTS}"}';

      // Category: Grammar (10)
      case GameSubtype.grammarQuest:
        return '{"id": "gq_L{L}_{I}", "instruction": "Pick correct form.", "type": "grammar", "subtype": "grammarQuest", "difficulty": {L}, "question": "{SENTENCE_WITH____}", "options": ["V1", "V2"], "correctAnswerIndex": 0, "explanation": "{WHY}", "xpReward": 10, "coinReward": 5}';
      case GameSubtype.tenseMastery:
        return '{"id": "tm_L{L}_{I}", "instruction": "Master the tenses.", "type": "grammar", "subtype": "tenseMastery", "difficulty": {L}, "question": "{SENTENCE}", "options": ["V1", "V2"]}';
      case GameSubtype.partsOfSpeech:
        return '{"id": "pos_L{L}_{I}", "instruction": "Identify parts of speech.", "type": "grammar", "subtype": "partsOfSpeech", "difficulty": {L}, "word": "{WORD}", "options": ["Noun", "Verb", "Adj"]}';
      case GameSubtype.wordReorder:
        return '{"id": "wr_L{L}_{I}", "instruction": "Build sentence.", "type": "grammar", "subtype": "wordReorder", "difficulty": {L}, "options": ["W2", "W1", "W3"], "correctSentence": "W1 W2 W3"}';
      case GameSubtype.subjectVerbAgreement:
        return '{"id": "sva_L{L}_{I}", "instruction": "Fix subject-verb agreement.", "type": "grammar", "subtype": "subjectVerbAgreement", "difficulty": {L}, "sentence": "{TEXT}", "options": ["is", "are"]}';
      case GameSubtype.sentenceCorrection:
        return '{"id": "sc_L{L}_{I}", "instruction": "Fix error.", "type": "grammar", "subtype": "sentenceCorrection", "difficulty": {L}, "question": "{BROKEN_SENTENCE}", "correctSentence": "{FIXED}", "explanation": "{RULE}"}';
      case GameSubtype.articleInsertion:
        return '{"id": "ai_L{L}_{I}", "instruction": "Insert a/an/the.", "type": "grammar", "subtype": "articleInsertion", "difficulty": {L}, "sentence": "__ apple a day.", "options": ["a", "an", "the"]}';
      case GameSubtype.clauseConnector:
        return '{"id": "cc_L{L}_{I}", "instruction": "Connect clauses.", "type": "grammar", "subtype": "clauseConnector", "difficulty": {L}, "clauses": ["C1", "C2"], "connector": "because"}';
      case GameSubtype.questionFormatter:
        return '{"id": "qf_L{L}_{I}", "instruction": "Form a question.", "type": "grammar", "subtype": "questionFormatter", "difficulty": {L}, "statement": "He is home.", "target": "Is he home?"}';
      case GameSubtype.voiceSwap:
        return '{"id": "vs_L{L}_{I}", "instruction": "Active to Passive.", "type": "grammar", "subtype": "voiceSwap", "difficulty": {L}, "sentence": "He ate the cake.", "target": "Passive"}';

      // Category: Listening (10)
      case GameSubtype.audioFillBlanks:
        return '{"id": "afb_L{L}_{I}", "instruction": "Type what you hear.", "type": "listening", "subtype": "audioFillBlanks", "difficulty": {L}, "transcript": "{FULL_SENTENCE}", "correctAnswer": "{THE_MISSING_WORD}", "audioUrl": ""}';
      case GameSubtype.audioMultipleChoice:
        return '{"id": "amc_L{L}_{I}", "instruction": "Answer based on audio.", "type": "listening", "subtype": "audioMultipleChoice", "difficulty": {L}, "transcript": "{AUDIO_STORY}", "question": "{Q}", "options": ["A", "B"], "correctAnswerIndex": 0, "audioUrl": ""}';
      case GameSubtype.audioSentenceOrder:
        return '{"id": "aso_L{L}_{I}", "instruction": "Order the sentences.", "type": "listening", "subtype": "audioSentenceOrder", "difficulty": {L}}';
      case GameSubtype.audioTrueFalse:
        return '{"id": "atf_L{L}_{I}", "instruction": "True or False?", "type": "listening", "subtype": "audioTrueFalse", "difficulty": {L}}';
      case GameSubtype.soundImageMatch:
        return '{"id": "sim_L{L}_{I}", "instruction": "Match sound to image.", "type": "listening", "subtype": "soundImageMatch", "difficulty": {L}}';
      case GameSubtype.fastSpeechDecoder:
        return '{"id": "fsd_L{L}_{I}", "instruction": "Decode fast speech.", "type": "listening", "subtype": "fastSpeechDecoder", "difficulty": {L}}';
      case GameSubtype.emotionRecognition:
        return '{"id": "er_L{L}_{I}", "instruction": "Identify the emotion.", "type": "listening", "subtype": "emotionRecognition", "difficulty": {L}}';
      case GameSubtype.detailSpotlight:
        return '{"id": "ds_L{L}_{I}", "instruction": "Find the specific detail.", "type": "listening", "subtype": "detailSpotlight", "difficulty": {L}}';
      case GameSubtype.listeningInference:
        return '{"id": "li_L{L}_{I}", "instruction": "Infer from the audio.", "type": "listening", "subtype": "listeningInference", "difficulty": {L}}';
      case GameSubtype.ambientId:
        return '{"id": "ai_L{L}_{I}", "instruction": "Identify the background sound.", "type": "listening", "subtype": "ambientId", "difficulty": {L}}';

      // Category: Accent (10)
      case GameSubtype.minimalPairs:
        return '{"id": "mp_L{L}_{I}", "instruction": "Contrast sounds.", "type": "accent", "subtype": "minimalPairs", "difficulty": {L}, "word": "{W1} vs {W2}", "phonetic": "/s/ vs /z/","xpReward": 10, "coinReward": 5}';
      case GameSubtype.intonationMimic:
        return '{"id": "int_L{L}_{I}", "instruction": "Mimic pitch.", "type": "accent", "subtype": "intonationMimic", "difficulty": {L}, "word": "{TEXT_TO_SAY}", "phonetic": "Rising Intonation", "xpReward": 10, "coinReward": 5}';
      case GameSubtype.syllableStress:
        return '{"id": "ss_L{L}_{I}", "instruction": "Stress the right syllable.", "type": "accent", "subtype": "syllableStress", "difficulty": {L}, "word": "{WORD}", "stressedIndex": 1}';
      case GameSubtype.wordLinking:
        return '{"id": "wl_L{L}_{I}", "instruction": "Link words naturally.", "type": "accent", "subtype": "wordLinking", "difficulty": {L}, "phrase": "{PHRASE}", "linkPoints": [0, 1]}';
      case GameSubtype.shadowingChallenge:
        return '{"id": "sc_L{L}_{I}", "instruction": "Shadow the speaker.", "type": "accent", "subtype": "shadowingChallenge", "difficulty": {L}, "text": "{TEXT}", "audioUrl": ""}';
      case GameSubtype.vowelDistinction:
        return '{"id": "vd_L{L}_{I}", "instruction": "Distinguish vowels.", "type": "accent", "subtype": "vowelDistinction", "difficulty": {L}, "vowels": ["/i:/", "/ɪ/"], "example": "{WORD}"}';
      case GameSubtype.consonantClarity:
        return '{"id": "cc_L{L}_{I}", "instruction": "Clear consonants.", "type": "accent", "subtype": "consonantClarity", "difficulty": {L}, "consonant": "{C}", "word": "{WORD}"}';
      case GameSubtype.pitchPatternMatch:
        return '{"id": "ppm_L{L}_{I}", "instruction": "Match the pitch.", "type": "accent", "subtype": "pitchPatternMatch", "difficulty": {L}, "pattern": "Falling"}';
      case GameSubtype.speedVariance:
        return '{"id": "sv_L{L}_{I}", "instruction": "Control your speed.", "type": "accent", "subtype": "speedVariance", "difficulty": {L}, "targetWpm": 120}';
      case GameSubtype.dialectDrill:
        return '{"id": "dd_L{L}_{I}", "instruction": "Practice the dialect.", "type": "accent", "subtype": "dialectDrill", "difficulty": {L}, "dialect": "British"}';

      // Category: Roleplay (10)
      case GameSubtype.branchingDialogue:
        return '{"id": "bd_L{L}_{I}", "instruction": "Negotiate scene.", "type": "roleplay", "subtype": "branchingDialogue", "difficulty": {L}, "roleName": "Tutor", "aiPrompt": "{CONTEXT_DESC}", "targetKeyPhrases": ["P1", "P2"]}';
      case GameSubtype.situationalResponse:
        return '{"id": "sr_L{L}_{I}", "instruction": "Respond properly.", "type": "roleplay", "subtype": "situationalResponse", "difficulty": {L}, "roleName": "Assistant", "aiPrompt": "{SITUATION}", "targetKeyPhrases": ["K1"]}';
      case GameSubtype.jobInterview:
        return '{"id": "ji_L{L}_{I}", "instruction": "Ace the interview.", "type": "roleplay", "subtype": "jobInterview", "difficulty": {L}, "company": "TechCorp", "targetPosition": "Junior Dev"}';
      case GameSubtype.medicalConsult:
        return '{"id": "mc_L{L}_{I}", "instruction": "Consult the doctor.", "type": "roleplay", "subtype": "medicalConsult", "difficulty": {L}, "symptoms": ["Headache", "Fever"]}';
      case GameSubtype.gourmetOrder:
        return '{"id": "go_L{L}_{I}", "instruction": "Order your meal.", "type": "roleplay", "subtype": "gourmetOrder", "difficulty": {L}, "restaurant": "The Bistro"}';
      case GameSubtype.travelDesk:
        return '{"id": "td_L{L}_{I}", "instruction": "Plan your trip.", "type": "roleplay", "subtype": "travelDesk", "difficulty": {L}, "destination": "Paris"}';
      case GameSubtype.conflictResolver:
        return '{"id": "cr_L{L}_{I}", "instruction": "Resolve the conflict.", "type": "roleplay", "subtype": "conflictResolver", "difficulty": {L}, "issue": "Late delivery"}';
      case GameSubtype.elevatorPitch:
        return '{"id": "ep_L{L}_{I}", "instruction": "Give your pitch.", "type": "roleplay", "subtype": "elevatorPitch", "difficulty": {L}, "idea": "Startup X"}';
      case GameSubtype.socialSpark:
        return '{"id": "sk_L{L}_{I}", "instruction": "Start a conversation.", "type": "roleplay", "subtype": "socialSpark", "difficulty": {L}, "event": "Networking Party"}';
      case GameSubtype.emergencyHub:
        return '{"id": "eh_L{L}_{I}", "instruction": "Handle the emergency.", "type": "roleplay", "subtype": "emergencyHub", "difficulty": {L}, "emergency": "Lost passport"}';

      // Category: Vocabulary (10)
      case GameSubtype.flashcards:
        return '{"id": "v_fc_L{L}_{I}", "instruction": "Learn new words.", "type": "vocabulary", "subtype": "flashcards", "difficulty": {L}, "word": "{WORD}", "definition": "{DEF}", "example": "{EX}"}';
      case GameSubtype.synonymSearch:
        return '{"id": "v_ss_L{L}_{I}", "instruction": "Find the synonym.", "type": "vocabulary", "subtype": "synonymSearch", "difficulty": {L}, "word": "{WORD}", "options": ["S1", "S2"], "correctAnswerIndex": 0}';
      case GameSubtype.antonymSearch:
        return '{"id": "v_as_L{L}_{I}", "instruction": "Find the antonym.", "type": "vocabulary", "subtype": "antonymSearch", "difficulty": {L}, "word": "{WORD}", "options": ["A1", "A2"], "correctAnswerIndex": 0}';
      case GameSubtype.contextClues:
        return '{"id": "v_cc_L{L}_{I}", "instruction": "Use context to define.", "type": "vocabulary", "subtype": "contextClues", "difficulty": {L}, "sentence": "{TEXT}", "word": "{WORD}", "options": ["M1", "M2"], "correctAnswerIndex": 0}';
      case GameSubtype.phrasalVerbs:
        return '{"id": "v_pv_p_L{L}_{I}", "instruction": "Learn phrasal verbs.", "type": "vocabulary", "subtype": "phrasalVerbs", "difficulty": {L}, "verb": "{VERB}", "definition": "{DEF}"}';
      case GameSubtype.idioms:
        return '{"id": "v_idm_p_L{L}_{I}", "instruction": "Learn idioms.", "type": "vocabulary", "subtype": "idioms", "difficulty": {L}, "idiom": "{IDIOM}", "meaning": "{DEF}"}';
      case GameSubtype.academicWord:
        return '{"id": "v_aw_L{L}_{I}", "instruction": "Master academic vocab.", "type": "vocabulary", "subtype": "academicWord", "difficulty": {L}, "word": "{WORD}"}';
      case GameSubtype.topicVocab:
        return '{"id": "v_tv_L{L}_{I}", "instruction": "Topic specific words.", "type": "vocabulary", "subtype": "topicVocab", "difficulty": {L}, "topic": "{TOPIC}", "words": ["W1", "W2"]}';
      case GameSubtype.wordFormation:
        return '{"id": "v_wf_L{L}_{I}", "instruction": "Form new words.", "type": "vocabulary", "subtype": "wordFormation", "difficulty": {L}, "base": "{BASE}", "target": "{TARGET}"}';
      case GameSubtype.prefixSuffix:
        return '{"id": "v_ps_L{L}_{I}", "instruction": "Add prefix/suffix.", "type": "vocabulary", "subtype": "prefixSuffix", "difficulty": {L}, "word": "{WORD}", "options": ["P1", "S1"]}';
      case GameSubtype.clozeTest:
        return '{"id": "clz_L{L}_{I}", "instruction": "Fill the blanks.", "type": "reading", "subtype": "clozeTest", "difficulty": {L}, "passage": "{TEXT_WITH_BLANKS}", "options": ["W1", "W2"], "correctAnswers": [0]}';
      case GameSubtype.skimmingScanning:
        return '{"id": "skm_L{L}_{I}", "instruction": "Scan for details.", "type": "reading", "subtype": "skimmingScanning", "difficulty": {L}, "passage": "{TEXT}", "questions": ["Q1"]}';
      case GameSubtype.modifierPlacement:
        return '{"id": "mod_L{L}_{I}", "instruction": "Place the modifier.", "type": "grammar", "subtype": "modifierPlacement", "difficulty": {L}, "sentence": "{TEXT}", "options": ["P1", "P2"]}';
      case GameSubtype.modalsSelection:
        return '{"id": "mdl_L{L}_{I}", "instruction": "Pick the modal.", "type": "grammar", "subtype": "modalsSelection", "difficulty": {L}, "sentence": "{TEXT}", "options": ["can", "must"]}';
      case GameSubtype.prepositionChoice:
        return '{"id": "prep_L{L}_{I}", "instruction": "Pick the preposition.", "type": "grammar", "subtype": "prepositionChoice", "difficulty": {L}, "sentence": "{TEXT}", "options": ["in", "on"]}';
      case GameSubtype.pronounResolution:
        return '{"id": "pro_L{L}_{I}", "instruction": "Resolve the pronoun.", "type": "grammar", "subtype": "pronounResolution", "difficulty": {L}, "sentence": "{TEXT}", "options": ["he", "she"]}';
      case GameSubtype.punctuationMastery:
        return '{"id": "punc_L{L}_{I}", "instruction": "Add punctuation.", "type": "grammar", "subtype": "punctuationMastery", "difficulty": {L}, "sentence": "{TEXT}"}';
      case GameSubtype.relativeClauses:
        return '{"id": "rel_L{L}_{I}", "instruction": "Join with relative clause.", "type": "grammar", "subtype": "relativeClauses", "difficulty": {L}, "clauses": ["C1", "C2"]}';
      case GameSubtype.conditionals:
        return '{"id": "cond_L{L}_{I}", "instruction": "Complete the conditional.", "type": "grammar", "subtype": "conditionals", "difficulty": {L}, "sentence": "If I..."}';
      case GameSubtype.conjunctions:
        return '{"id": "conj_L{L}_{I}", "instruction": "Pick the conjunction.", "type": "grammar", "subtype": "conjunctions", "difficulty": {L}, "options": ["and", "but"]}';
      case GameSubtype.directIndirectSpeech:
        return '{"id": "dis_L{L}_{I}", "instruction": "Change the speech.", "type": "grammar", "subtype": "directIndirectSpeech", "difficulty": {L}, "sentence": "He said..."}';
      case GameSubtype.collocations:
        return '{"id": "coll_L{L}_{I}", "instruction": "Find the collocation.", "type": "vocabulary", "subtype": "collocations", "difficulty": {L}, "word": "{WORD}", "options": ["W1", "W2"]}';
      case GameSubtype.contextualUsage:
        return '{"id": "ctx_L{L}_{I}", "instruction": "Use in context.", "type": "vocabulary", "subtype": "contextualUsage", "difficulty": {L}, "word": "{WORD}"}';
      case GameSubtype.connectedSpeech:
        return '{"id": "conn_L{L}_{I}", "instruction": "Natural linking.", "type": "accent", "subtype": "connectedSpeech", "difficulty": {L}, "phrase": "{PHRASE}"}';
      case GameSubtype.pitchModulation:
        return '{"id": "pitch_L{L}_{I}", "instruction": "Vary your pitch.", "type": "accent", "subtype": "pitchModulation", "difficulty": {L}, "phrase": "{PHRASE}"}';

      // Category: Elite Mastery (4)
      case GameSubtype.storyBuilder:
        return '{"id": "sb_elite_L{L}_{I}", "instruction": "Reorder the sentences to form a story.", "type": "eliteMastery", "subtype": "storyBuilder", "difficulty": {L}, "sentences": ["S1", "S2"], "correctOrder": [0, 1]}';
      case GameSubtype.idiomMatch:
        return '{"id": "im_elite_L{L}_{I}", "instruction": "Match the idiom to its meaning.", "type": "eliteMastery", "subtype": "idiomMatch", "difficulty": {L}, "idiom": "{IDIOM}", "options": ["M1", "M2"], "correctAnswerIndex": 0}';
      case GameSubtype.speedSpelling:
        return '{"id": "ss_elite_L{L}_{I}", "instruction": "Spell the word quickly.", "type": "eliteMastery", "subtype": "speedSpelling", "difficulty": {L}, "word": "{WORD}", "speedMultiplier": 1.0}';
      case GameSubtype.accentShadowing:
        return '{"id": "as_elite_L{L}_{I}", "instruction": "Listen and shadow.", "type": "eliteMastery", "subtype": "accentShadowing", "difficulty": {L}, "text": "{TEXT}", "audioUrl": ""}';
    }
  }
}
