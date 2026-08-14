import 'package:flutter/material.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';

/// Immutable model representing a narrative milestones/narrative trigger.
class StoryBeat {
  final String text;
  final String mascotEmoji;
  final String title;
  final Color themeColor;

  const StoryBeat({
    required this.text,
    required this.mascotEmoji,
    required this.title,
    required this.themeColor,
  });
}

/// Abstract contract defining the Vowl Narrative Engine service.
///
/// Decouples story triggers and milestone scripts from the calling presentation layer,
/// in accordance with clean SOLID design rules.
abstract class StoryService {
  /// Factory mapping constructor supporting seamless backwards compatibility for callers.
  factory StoryService() = StoryServiceImpl;

  /// Resolves a storytelling narrative beat or milestone reward text.
  StoryBeat? getStoryBeat(BuildContext context, String categoryId, int level);
}

/// Concrete high-performance implementation of [StoryService] utilizing static const script pools.
class StoryServiceImpl implements StoryService {
  // Pre-computed milestones triggers
  static const List<int> milestones = [1, 10, 20, 50, 100, 200];

  // Granular Scripts for Modern Games (100+ Specific Types)
  static const Map<String, String> modernGameScripts = {
    // Accent
    'consonantClarity':
        "Tap the exact consonant sound you hear to speak clearly and confidently.",
    'dialectDrill':
        "Listen closely to the speaker to identify where in the world they are from.",
    'intonationMimic':
        "Follow the voice and slide the fader up or down to match the pitch perfectly.",
    'minimalPairs':
        "Listen carefully to spot the tiny differences between two very similar words.",
    'pitchPatternMatch':
        "Slide the fader to match the exact melody and rhythm of the sentence.",
    'shadowingChallenge':
        "Tap the chat bubble that exactly matches the sentence you just heard.",
    'speedVariance':
        "Train your ears to understand English whether it's spoken fast, medium, or slow.",
    'syllableStress':
        "Listen to the word and find the part that sounds the loudest and longest.",
    'vowelDistinction':
        "Slide left or right to find the exact vowel sound spoken in the audio.",
    'wordLinking':
        "Listen to how native speakers link two separate words into one smooth sound.",
    'pitchModulation':
        "Learn how changing your pitch can show surprise, excitement, or calm.",
    'connectedSpeech':
        "Find the floating card that perfectly links the words together.",

    // Grammar
    'articleInsertion':
        "A, An, The. The small words that build big structures. Let's place them perfectly.",
    'clauseConnector':
        "The Bridge Builder. Link your thoughts into powerful, complex sentences.",
    'grammarQuest':
        "The Nexus Trial. Prove your mastery of the laws that govern the language.",
    'modifierPlacement':
        "Precision description. Place your modifiers for maximum clarity and impact.",
    'partsOfSpeech':
        "The Building Blocks. Identify the core components of every great sentence.",
    'questionFormatter':
        "The Seeker of Truth. Learn to craft the perfect questions for any situation.",
    'sentenceCorrection':
        "The Architect's Eye. Find and fix the structural flaws in these sentences.",
    'subjectVerbAgreement':
        "Perfect Harmony. Ensure your subjects and verbs work together in total unity.",
    'tenseMastery':
        "The Time Traveler. Command the past, present, and future with absolute confidence.",
    'voiceSwap':
        "Active to Passive. Change the perspective of your sentences with strategic skill.",
    'wordReorder':
        "The Puzzle Master. Rearrange these words to reveal the hidden meaning within.",
    'modalsSelection':
        "Degrees of Certainty. Use modals to express possibility, ability, and necessity.",
    'prepositionChoice':
        "Spatial Intelligence. Place your objects in the perfect context with prepositions.",
    'pronounResolution':
        "Identity Logic. Master the art of clear reference through perfect pronouns.",
    'punctuationMastery':
        "The Rhythm of Reading. Use punctuation to guide the breath and the mind.",
    'relativeClauses':
        "Depth of Detail. Add layers of meaning to your subjects with relative clauses.",
    'conditionals':
        "The Logic of 'If'. Explore the world of possibility and consequence.",
    'conjunctions':
        "Logic Links. Use conjunctions to create smooth, logical transitions.",
    'directIndirectSpeech':
        "The Messenger's Art. Master the subtle shift between quoted and reported speech.",

    // Listening
    'ambientId':
        "Soundscape Discovery. Identify the subtle sounds hidden in your environment.",
    'audioFillBlanks':
        "The Missing Link. Hear the gaps and complete the message with total accuracy.",
    'audioMultipleChoice':
        "Selective Hearing. Identify the true message amidst a sea of options.",
    'audioSentenceOrder':
        "The Rhythm of Story. Reconstruct the sequence of sounds into a narrative.",
    'audioTrueFalse':
        "Fact or Fiction. Train your ears to detect the truth in spoken messages.",
    'detailSpotlight':
        "Laser Focus. Tune in to the specific details that others usually miss.",
    'emotionRecognition':
        "The Heart's Resonance. Hear the feelings hidden behind every spoken word.",
    'fastSpeechDecoder':
        "Speed Listening. Unlock the meaning of fast-paced, natural conversation.",
    'listeningInference':
        "Between the Whispers. Hear what isn't said and understand the subtext.",
    'soundImageMatch':
        "Visual Harmony. Connect the sounds of the world with their visual forms.",

    // Reading
    'findWordMeaning':
        "Contextual Detective. Unlock the meaning of new words through the power of context.",
    'guessTitle':
        "The Big Picture. Identify the core theme and give this story its true name.",
    'paragraphSummary':
        "The Essence of Thought. Condense complex ideas into their purest form.",
    'readAndAnswer':
        "Knowledge Retrieval. Prove your comprehension by finding the key facts.",
    'readAndMatch':
        "Pattern Recognition. Connect related ideas across a vast landscape of text.",
    'readingConclusion':
        "The Logical Leap. Draw the final conclusion from the evidence provided.",
    'readingInference':
        "Silent Discovery. Read between the lines to find the hidden truth.",
    'readingSpeedCheck':
        "Rapid Comprehension. Read with speed without sacrificing your understanding.",
    'sentenceOrderReading':
        "Narrative Logic. Rebuild the story by placing every sentence in its home.",
    'trueFalseReading':
        "Critical Analysis. Verify the facts and separate truth from assumption.",
    'skimmingScanning':
        "Visual Efficiency. Find exactly what you need in a sea of information.",
    'clozeTest':
        "The Completionist. Use logic and context to fill the gaps in the narrative.",

    // Roleplay
    'branchingDialogue':
        "Infinite Paths. Every choice you make creates a new reality. Choose wisely.",
    'conflictResolver':
        "The Peacekeeper. Use the power of words to turn tension into harmony.",
    'elevatorPitch':
        "Impact in Seconds. Deliver your message with maximum power and brevity.",
    'emergencyHub':
        "Calm in Chaos. Use precise language to handle high-pressure situations.",
    'gourmetOrder':
        "The Social Connoisseur. Handle sophisticated dining scenarios with grace.",
    'jobInterview':
        "Professional Zenith. Present your best self and win the future you want.",
    'medicalConsult':
        "Clarity of Care. Use precise language to communicate health and wellness.",
    'situationalResponse':
        "Adaptive Intelligence. React to any social scenario with perfect timing.",
    'socialSpark':
        "The Charismatic Leader. Ignite connections and lead any conversation.",
    'travelDesk':
        "Global Citizen. Navigate the world with confidence and linguistic skill.",

    // Speaking
    'dailyExpression':
        "The Natural Voice. Master the common phrases used in everyday life.",
    'dialogueRoleplay':
        "The Conversationist. Practice the art of back-and-forth social interaction.",
    'pronunciationFocus':
        "Phonetic Perfection. Refine the specific sounds that define your speech.",
    'repeatSentence':
        "The Vocal Mirror. Mirror the rhythm and tone of a native speaker.",
    'sceneDescriptionSpeaking':
        "Vivid Imagery. Use your voice to paint a picture for your listeners.",
    'situationSpeaking':
        "Contextual Speech. Adapt your voice to meet the needs of any situation.",
    'speakMissingWord':
        "Cognitive Speech. Think and speak simultaneously to complete the thought.",
    'speakOpposite':
        "Dynamic Reversal. Train your brain to find the antonym in real-time.",
    'speakSynonym':
        "Linguistic Variety. Expand your range by finding new ways to say the same thing.",
    'yesNoSpeaking':
        "Rapid Response. Train your reflexes for fast, accurate communication.",

    // Vocabulary
    'academicWord':
        "Scholarly Power. Master the advanced vocabulary of higher learning.",
    'antonymSearch':
        "The Shadow Side. Find the perfect opposite for every word in your arsenal.",
    'contextClues':
        "The Detective's Mind. Use the surrounding world to unlock unknown meanings.",
    'flashcards':
        "The Memory Bank. Build your foundation through rapid, focused repetition.",
    'idioms':
        "Cultural Secrets. Unlock the colorful phrases that define native speech.",
    'phrasalVerbs':
        "The Action Multiplier. Master the complex combinations of verbs and prepositions.",
    'prefixSuffix':
        "Word Alchemy. Use prefixes and suffixes to transform and create new words.",
    'synonymSearch':
        "The Lexical Explorer. Find the many shades of meaning in every word.",
    'topicVocab':
        "Word Sorter. Group words by topic to easily build your vocabulary.",
    'wordFormation':
        "Welcome to word building! We're going to learn how to create powerful new words by mixing and matching their core pieces.",
    'contextualUsage':
        "Strategic Application. Use the right word in exactly the right way.",
    'collocations':
        "Natural Pairs. Learn which words naturally belong together in fluent speech.",

    // Writing
    'completeSentence':
        "The Architect of Thought. Build a complete, powerful message from a fragment.",
    'correctionWriting':
        "The Editor's Edge. Refine and polish your writing to professional standards.",
    'dailyJournal':
        "Personal Reflection. Use writing to explore your own thoughts and experiences.",
    'describeSituationWriting':
        "Atmospheric Prose. Paint a scene using only the power of your words.",
    'essayDrafting':
        "Logical Structure. Build a compelling argument through structured writing.",
    'fixTheSentence':
        "The Structural Fixer. Identify and repair errors in complex written logic.",
    'opinionWriting':
        "The Persuader. Use your written voice to influence and convince others.",
    'sentenceBuilder':
        "Construction Logic. Assemble the pieces of a sentence into a perfect whole.",
    'shortAnswerWriting':
        "Brevity and Power. Convey your message with maximum efficiency.",
    'summarizeStoryWriting':
        "The Narrative Distiller. Capture the core of a story in just a few words.",
    'writingEmail':
        "Digital Correspondence. Master the art of professional and personal emails.",

    // Elite Mastery
    'storyBuilder':
        "Read the scrambled sentences and arrange them in the correct logical order to build a complete story.",
    'idiomMatch':
        "Read the context and choose the correct English idiom that matches the meaning.",
    'speedSpelling':
        "Unscramble the letters to spell the hidden vocabulary word correctly.",
    'accentShadowing':
        "Tap the chat bubble that exactly matches the sentence you just heard.",
  };

  static const Map<String, List<String>> kidsScripts = {
    'handwriting': [
      "Pen in hand! Let's draw some beautiful magic letters today! ✍️",
      "Calligraphy Hero! You're making every word look like art! 🎨",
      "The Magic Scroll is glowing! Your writing is becoming so clear! ✨",
      "A master of lines! You draw the perfect shapes every time! 📐",
      "100 levels of writing! You are the Master of the Golden Pen! 🖋️",
      "Legendary Scribe! Your handwriting is the most beautiful in the world! 📜",
    ],
    'weather': [
      "Sun or rain! Let's learn about the beautiful sky today! ☀️",
      "Cloud Chaser! You know exactly what the sky is telling us! ☁️",
      "The Storm is passed! You're a hero of the seasons! 🌈",
      "A perfect forecast! You understand the rhythm of nature! 🌩️",
      "100 levels of weather! You are the Master of the Elements! 🌪️",
      "Sky Guardian! You control the sunshine and the rain! 🌦️",
    ],
    'professions': [
      "What do you want to be? Let's explore all the amazing jobs! 👩‍🚀",
      "The Helper! You know how everyone makes the world a better place! 👨‍🚒",
      "A community of heroes! You're learning how we all work together! 👩‍⚕️",
      "The Architect of Dreams! You can be anything you want to be! 👷",
      "100 levels of careers! You are the Mayor of the City! 🏙️",
      "World Leader! You understand every amazing job in the world! 🌍",
    ],

    'alphabet': [
      "Hi little explorer! Let's find all the hidden magic letters in the forest! 🕵️‍♂️",
      "Yay! The Alphabet Bridge is fixed! Now we can cross into the Land of Stories! 🌈",
      "You found the Golden A! You're a superstar learner and a great friend! ⭐",
      "The Letter Dragon is so happy! You've learned so many magic words today! 🐉",
      "100 letters found! You are now the officially crowned King of the Alphabet! 👑",
      "ABC Master! You have the power to read every story in the whole wide world! 🌍",
    ],
    'numbers': [
      "One, two, three... Let's count all the twinkling stars in the night sky! ✨",
      "You're a Number Hero! The counting dragon is doing a happy dance for you! 🐉",
      "Double digits! You're getting super fast at solving these number puzzles! 🚀",
      "Halfway to 100! You're becoming a real Math Wizard with a magic wand! 🧙‍♂️",
      "100 levels of number fun! You can count all the way to the moon and back! 🌕",
      "The Math Legend! You've solved every single puzzle in the Number Kingdom! 🏆",
    ],
    'colors': [
      "The world is a giant rainbow! Can you help me find the juicy red apple? 🍎",
      "You've painted the whole sky a beautiful blue! Everything looks so pretty! 🦋",
      "A kaleidoscope of magic colors! You're a brilliant little artist, friend! 🎨",
      "You found the Golden Glow! The world is so bright and happy because of you! ✨",
      "100 colors mastered! You are now the official Master of the Rainbow! 🌈",
      "The Color King! You've made the whole world look like a beautiful castle! 🏰",
    ],
    'shapes': [
      "Circles, squares, and triangles! Let's find all the hidden shapes in the park! 🔺",
      "Shape Shifter! You found the perfect circle. You're getting so smart! 🔵",
      "Geometry Genius! The world is made of beautiful patterns and shapes. ⬛",
      "The Shape Kingdom is safe! You've solved the puzzle of the stars! ⭐",
      "100 shapes found! You are now the Grand Architect of the World! 🏛️",
      "Master of Forms! You can build anything with your magic shapes! 🏰",
    ],
    'animals': [
      "Welcome to the Great Safari! Can you help me find the king of the jungle? 🦁",
      "The Jungle is cheering for you! You're a kind friend to every animal we meet! 🐾",
      "You found the hidden Giraffe! You're a brave and smart explorer, adventurer! 🦒",
      "The Ocean is deep and blue! Let's dive in and play with our fishy friends! 🐬",
      "100 animal friends found! You are now the leader of the Jungle Safari! 🌴",
      "Master of Nature! All the animals in the world want to be your best friend! 🦖",
    ],
    'fruits': [
      "Mmm, yummy! Let's find the sweet red strawberry hiding in the garden! 🍓",
      "A big basket of goodness! You're a healthy hero with lots of energy! 🍌",
      "The Fruit Garden is growing big! You've found the magical mango treat! 🥭",
      "A tropical surprise! You've discovered the pineapple crown in the sand! 🍍",
      "100 levels of fruit fun! You're the King of the Enchanted Fruit Garden! 🍏",
      "Healthy Master! You've tasted all the sweetest treats in the whole world! 🍇",
    ],
    'family': [
      "Family is love! Let's meet everyone in our happy little house! 🏠",
      "You're a great helper! Everyone is so proud of you today, friend! ❤️",
      "The Family Tree is blooming with love. You're a very special branch! 🌳",
      "A celebration of love! You bring so much joy to everyone you meet! ✨",
      "100 levels of family fun! You are the heart of our happy home! 💖",
      "Master of Hearts! Your kindness makes every family happy! 👨‍👩‍👧‍👦",
    ],
    'school': [
      "Welcome to the Fun School! Let's grab our backpacks and start learning! 🎒",
      "Teacher's Pet! You're the brightest student in the whole classroom! 🍎",
      "Recess is fun, but learning is a superpower! You're doing great! 🏫",
      "The Principal is impressed! You've solved the big chalkboard puzzle! 🎓",
      "100 levels of school! You're the smartest student in the world! 📚",
      "Grand Graduate! You've mastered everything in the Fun School! 🏅",
    ],
    'verbs': [
      "Jump, run, and play! Let's find all the action words in the yard! 🏃",
      "Action Hero! You're moving fast and learning even faster! ⚡",
      "The Energy Level is high! You've mastered the art of doing! 🤸",
      "A whirlwind of action! You're the star of every active game! 🎾",
      "100 verbs mastered! You're the champion of the Action Arena! 🏆",
      "Master of Motion! You can do anything with your action words! 🚀",
    ],
    'routine': [
      "Good morning! Let's start our day with a smile and a big stretch! ☀️",
      "Tick-tock! You're a master of time and a hero of your daily habits! ⏰",
      "The Daily Rhythm is perfect! You're getting so organized and smart! 📅",
      "A day full of wonder! You handle every part of your day like a pro! 🌙",
      "100 days of routine! You are the master of your own destiny! 🌟",
      "Eternal Hero! You've mastered the art of living a happy life! 🌈",
    ],
    'emotions': [
      "How are you feeling today? Let's find the biggest, brightest happy face! 😊",
      "It's okay to feel a little sad sometimes. You're a very kind and caring friend. 💙",
      "You're an Emotion Expert! You know exactly how to make everyone feel better! 🌟",
      "The Heart Garden is full of love and kindness because of your big heart! ❤️",
      "100 levels of feelings! You have a heart of pure gold and a soul of light! 💛",
      "Master of Hearts! You have the magic power to make everyone in the world smile! 🌈",
    ],
    'prepositions': [
      "In, on, and under! Where is the little mouse hiding today? 🐭",
      "Spatial Explorer! You found the treasure behind the magic waterfall! 🗺️",
      "Above the clouds! You're learning how everything fits together! ☁️",
      "The Navigator! You never get lost in the forest of words! 🌲",
      "100 levels of placement! You are the Master of the Map! 📍",
      "Grand Navigator! You know exactly where everything in the world is! 🌍",
    ],
    'phonics': [
      "A-A-Apple! Let's listen to the secret sounds of the letters! 🔊",
      "Sound Scientist! You've unlocked the music hidden in every word! 🎵",
      "The Phonics Symphony is playing! You're the lead conductor! 🎻",
      "A chorus of clarity! Your reading is becoming magical and clear! ✨",
      "100 phonics puzzles! You are the Master of the Sound Garden! 🎤",
      "Legendary Reader! You can hear the music in every book! 🎼",
    ],
    'time': [
      "Tick-tock! Can you help me find the big clock in the tower? 🕰️",
      "Time Traveler! You're learning the secrets of seconds and hours! ⏳",
      "The Future is bright! You handle every moment with wisdom! 🚀",
      "Master of the Calendar! You know exactly when the magic happens! 📅",
      "100 levels of time! You are the Eternal Guardian of the Clock! 🛡️",
      "Time Lord! You have mastered the past, present, and future! 🌌",
    ],
    'opposites': [
      "Hot and cold, big and small! Let's find all the pairs today! 🌗",
      "Balance Master! You've found the perfect match for every word! ⚖️",
      "The Mirror World is clear! You see both sides of every story! 🪞",
      "Dynamic Duo! You're getting so fast at finding the opposites! 💥",
      "100 levels of contrast! You are the Master of the Balance! ☯️",
      "Harmony Legend! You've brought peace to the world of words! 🕊️",
    ],
    'daynight': [
      "Sun and Moon! Let's explore the world from dawn to dusk! ☀️",
      "Star Gazer! You're a hero of the day and a guardian of the night! 🌙",
      "The Eternal Cycle! You understand the rhythm of our beautiful earth! 🌍",
      "A sky full of wonder! You're the star of the day and night! ✨",
      "100 cycles completed! You are the Guardian of the Sky! 🏹",
      "Master of the Elements! You control the light and the shadows! 🌌",
    ],
    'nature': [
      "Green trees and blue seas! Let's protect our beautiful planet! 🌳",
      "Eco Hero! You're a friend to every flower and every forest! 🌺",
      "The Earth is happy! Your love for nature is making it bloom! 🌏",
      "Wilderness Explorer! You've found the secret waterfall! 💦",
      "100 levels of nature! You are the Protector of the Wild! 🏹",
      "Nature Legend! You are one with the heart of the world! 🌿",
    ],
    'home': [
      "Home sweet home! Let's find the cozy chair in the living room! 🛋️",
      "Domestic Hero! You're making our home a place of magic and joy! ✨",
      "The Hearth is warm! You bring so much comfort to everyone! 🔥",
      "A sanctuary of love! Our house is a castle because of you! 🏰",
      "100 levels of home! You are the heart of the household! 🏠",
      "Grand Architect! You've made every room a place of happiness! 🏡",
    ],
    'food': [
      "Yum yum! Let's cook up some magic in the kitchen today! 🍳",
      "Chef de Cuisine! Your taste in words is absolutely delicious! 🍰",
      "A feast of knowledge! You're feeding your mind with greatness! 🍲",
      "The Table is set! You're a master of the culinary arts! 🍽️",
      "100 levels of flavor! You are the Master of the Feast! 🏆",
      "Gourmet Legend! You've tasted all the wisdom in the world! 🍷",
    ],
    'transport': [
      "Vroom vroom! Let's jump into the fast red car and start our engines! 🚗",
      "To the sky! You're flying the big blue airplane above the fluffy clouds! ✈️",
      "Choo choo! The friendship train is leaving the station. All aboard, friend! 🚂",
      "3, 2, 1... Blast off! You're going to visit the moon in a shiny silver rocket! 🚀",
      "100 levels of travel! You've seen every corner of our beautiful world! 🌍",
      "Master Explorer! You've traveled through the land, the sea, and the stars! 🛸",
    ],
    'bodyparts': [
      "Head, shoulders, knees, and toes! Let's learn about ourselves! 🧒",
      "Human Wonder! You're discovering how amazing your body is! 💪",
      "The Anatomy Ace! You're getting so smart about your senses! 👂",
      "A miracle of motion! You're the star of your own physical journey! 🏃",
      "100 levels of self-discovery! You are the Master of the Mirror! 🪞",
      "Grand Biologist! You know every secret of the human form! 🧬",
    ],
    'clothing': [
      "Dressed for success! Let's find the colorful hat in the closet! 🎩",
      "Fashion Hero! You're looking sharp and learning even sharper! 👔",
      "The Style Icon! You have the perfect outfit for every occasion! 👗",
      "A runway of words! You're the trendsetter of the classroom! 👟",
      "100 levels of fashion! You are the Master of the Wardrobe! 🧥",
      "Grand Designer! You've dressed the world in beautiful words! 👑",
    ],
  };

  static const Map<String, List<String>> legacyAdultScripts = {
    'grammar': [
      "", // level 1 handled dynamically
      "Great start! You're building a strong foundation in grammar.",
      "Your sentences are becoming much clearer and more structured.",
      "Halfway there! Your command of grammar rules is very impressive.",
      "Level 100! Your sentence structure and syntax are excellent.",
      "Level 200 reached! You have mastered the core rules of the language.",
    ],
    'writing': [
      "",
      "Good job! Your writing is starting to flow much better.",
      "You're expressing your ideas with a lot more clarity now.",
      "Halfway to 100! Your writing is becoming natural and persuasive.",
      "Level 100! You can now write complex thoughts with total confidence.",
      "Level 200 reached! Your written communication is exceptional.",
    ],
    'speaking': [
      "",
      "Nice work! Your pronunciation is getting clearer every day.",
      "You're sounding more natural and confident when you speak.",
      "Halfway there! Your spoken English is becoming very smooth.",
      "Level 100! You can now express yourself clearly in any conversation.",
      "Level 200 reached! Your speaking skills are truly advanced.",
    ],
    'listening': [
      "",
      "Good start! You are picking up on details much faster now.",
      "Your listening comprehension is improving. Keep it up!",
      "Halfway to 100! You can easily follow natural conversations.",
      "Level 100! You understand spoken English with great accuracy.",
      "Level 200 reached! You can comprehend native speakers effortlessly.",
    ],
    'accent': [
      "",
      "You sound great! Your speaking is getting much clearer and more natural.",
      "Amazing progress! You are starting to sound just like a local speaker.",
      "Halfway to 100! Your pronunciation is incredibly smooth and easy to understand.",
      "Level 100! You can now speak clearly and naturally with anyone in the world.",
      "Level 200 reached! You have completely mastered clear and natural English pronunciation.",
    ],
    'vocabulary': [
      "",
      "Your vocabulary is growing quickly. Great job learning new words!",
      "You're starting to find the right word for every situation.",
      "Halfway to 100! You have a very strong command of the language.",
      "Level 100! You can now express yourself with precise and varied vocabulary.",
      "Level 200 reached! Your vocabulary is advanced and highly expressive.",
    ],
    'roleplay': [
      "",
      "Nice work! You're handling everyday situations with much more ease.",
      "You're becoming very comfortable in different social scenarios.",
      "Halfway there! You can navigate complex conversations naturally.",
      "Level 100! You are completely prepared for any real-world interaction.",
      "Level 200 reached! Your conversational skills are outstanding.",
    ],
    'reading': [
      "",
      "Good start! Your reading speed and understanding are improving.",
      "You're starting to easily grasp the main ideas of texts.",
      "Halfway to 100! You can read complex articles with confidence.",
      "Level 100! Your reading comprehension is excellent.",
      "Level 200 reached! You can read and analyze advanced texts effortlessly.",
    ],
    'storybuilder': [
      "",
      "Great job! Building narratives is key to language fluency.",
      "Your structural logic is becoming incredibly sharp.",
      "Halfway to 100! You are constructing complex thoughts effortlessly.",
      "Level 100! You are a master storyteller.",
      "Level 200 reached! Your narrative architecture is flawless.",
    ],
    'idiommatch': [
      "",
      "Great job! Idioms are the secret to native-sounding speech.",
      "Your cultural vocabulary is expanding rapidly.",
      "Halfway to 100! You are deciphering complex meanings with ease.",
      "Level 100! You have mastered the art of figurative language.",
      "Level 200 reached! You can converse with natives on any abstract topic.",
    ],
    'speedspelling': [
      "",
      "Great job! Spelling under pressure sharpens your memory.",
      "Your lexical recall is becoming incredibly fast.",
      "Halfway to 100! You are decoding words with machine-like precision.",
      "Level 100! Your orthography is elite.",
      "Level 200 reached! You have mastered the most complex vocabulary spelling.",
    ],
    'accentshadowing': [
      "",
      "Great job! Shadowing is the fastest path to native pronunciation.",
      "Your rhythm and pitch are aligning perfectly with native speakers.",
      "Halfway to 100! You are conquering the nuances of connected speech.",
      "Level 100! Your spoken cadence is incredibly natural.",
      "Level 200 reached! You possess flawless phonetic mimicry.",
    ],
    'consonantclarity': [
      "",
      "Well done! You are building a strong foundation in consonants.",
      "You are decoding consonants with impressive accuracy.",
      "Amazing! You manipulate consonants with natural ease.",
      "Level 100! You are an absolute master of consonants.",
      "Double Centurion! No one knows consonants better than you.",
    ],
    'dialectdrill': [
      "",
      "Nice work! Conquering dialects is a huge step forward.",
      "Your skills in dialects are becoming incredibly sharp.",
      "Halfway to 100! You are handling dialects effortlessly.",
      "Level 100! You are an absolute master of dialects.",
      "Level 200! You have transcended the limits of dialects.",
    ],
    'intonationmimic': [
      "",
      "Nice work! Conquering intonation is a huge step forward.",
      "Your skills in intonation are becoming incredibly sharp.",
      "Amazing! You manipulate intonation with natural ease.",
      "Level 100! Your execution of intonation is flawless.",
      "Level 200! You have transcended the limits of intonation.",
    ],
    'minimalpairs': [
      "",
      "Excellent start! Your understanding of minimal pairs is growing.",
      "Your progress in minimal pairs is genuinely impressive.",
      "Halfway to 100! You are handling minimal pairs effortlessly.",
      "Level 100! Your expertise in minimal pairs is elite.",
      "Double Centurion! No one knows minimal pairs better than you.",
    ],
    'pitchpatternmatch': [
      "",
      "Nice work! Conquering pitch patterns is a huge step forward.",
      "Your skills in pitch patterns are becoming incredibly sharp.",
      "50 levels cleared! Your pitch patterns skills are rock solid.",
      "Level 100! Your execution of pitch patterns is flawless.",
      "Level 200! You have transcended the limits of pitch patterns.",
    ],
    'shadowingchallenge': [
      "",
      "Fantastic! Exploring shadowing will elevate your skills rapidly.",
      "Your progress in shadowing is genuinely impressive.",
      "50 levels cleared! Your shadowing skills are rock solid.",
      "Level 100! Your execution of shadowing is flawless.",
      "Level 200! You are a supreme grandmaster of shadowing.",
    ],
    'speedvariance': [
      "",
      "Great job! Mastering speech speed is key to true fluency.",
      "Your skills in speech speed are becoming incredibly sharp.",
      "50 levels cleared! Your speech speed skills are rock solid.",
      "100 levels beat! You truly dominate speech speed.",
      "200 levels cleared! Your speech speed abilities are unmatched globally.",
    ],
    'syllablestress': [
      "",
      "Fantastic! Exploring syllable stress will elevate your skills rapidly.",
      "Your skills in syllable stress are becoming incredibly sharp.",
      "Amazing! You manipulate syllable stress with natural ease.",
      "Level 100! Your execution of syllable stress is flawless.",
      "200 levels cleared! Your syllable stress abilities are unmatched globally.",
    ],
    'voweldistinction': [
      "",
      "Well done! You are building a strong foundation in vowels.",
      "Your mastery of vowels is noticeably improving daily.",
      "Halfway there! You are a rising star in vowels.",
      "Centurion! You have conquered the complexities of vowels.",
      "Level 200! You have transcended the limits of vowels.",
    ],
    'wordlinking': [
      "",
      "Nice work! Conquering word linking is a huge step forward.",
      "Your mastery of word linking is noticeably improving daily.",
      "Halfway to 100! You are handling word linking effortlessly.",
      "100 levels beat! You truly dominate word linking.",
      "Level 200! You are a supreme grandmaster of word linking.",
    ],
    'pitchmodulation': [
      "",
      "Excellent start! Your understanding of pitch modulation is growing.",
      "Your progress in pitch modulation is genuinely impressive.",
      "Amazing! You manipulate pitch modulation with natural ease.",
      "Centurion! You have conquered the complexities of pitch modulation.",
      "Level 200 reached! Your grasp of pitch modulation is legendary.",
    ],
    'connectedspeech': [
      "",
      "Fantastic! Exploring connected speech will elevate your skills rapidly.",
      "You are navigating connected speech with increasing confidence.",
      "50 levels cleared! Your connected speech skills are rock solid.",
      "Level 100! Your execution of connected speech is flawless.",
      "Level 200! You have transcended the limits of connected speech.",
    ],
    'articleinsertion': [
      "",
      "Great job! Mastering articles is key to true fluency.",
      "Your skills in articles are becoming incredibly sharp.",
      "50 levels cleared! Your articles skills are rock solid.",
      "Level 100! Your execution of articles is flawless.",
      "Level 200! You are a supreme grandmaster of articles.",
    ],
    'clauseconnector': [
      "",
      "Nice work! Conquering clauses is a huge step forward.",
      "Your skills in clauses are becoming incredibly sharp.",
      "Halfway there! You are a rising star in clauses.",
      "Level 100! Your expertise in clauses is elite.",
      "Level 200 reached! Your grasp of clauses is legendary.",
    ],
    'grammarquest': [
      "",
      "Excellent start! Your understanding of grammar rules is growing.",
      "Your mastery of grammar rules is noticeably improving daily.",
      "Amazing! You manipulate grammar rules with natural ease.",
      "Centurion! You have conquered the complexities of grammar rules.",
      "Level 200 reached! Your grasp of grammar rules is legendary.",
    ],
    'modifierplacement': [
      "",
      "Well done! You are building a strong foundation in modifiers.",
      "You are decoding modifiers with impressive accuracy.",
      "50 levels cleared! Your modifiers skills are rock solid.",
      "Centurion! You have conquered the complexities of modifiers.",
      "200 levels cleared! Your modifiers abilities are unmatched globally.",
    ],
    'partsofspeech': [
      "",
      "Well done! You are building a strong foundation in parts of speech.",
      "You are decoding parts of speech with impressive accuracy.",
      "Halfway there! You are a rising star in parts of speech.",
      "100 levels beat! You truly dominate parts of speech.",
      "Level 200! You are a supreme grandmaster of parts of speech.",
    ],
    'questionformatter': [
      "",
      "Excellent start! Your understanding of questions is growing.",
      "You are navigating questions with increasing confidence.",
      "Halfway there! You are a rising star in questions.",
      "Centurion! You have conquered the complexities of questions.",
      "Double Centurion! No one knows questions better than you.",
    ],
    'sentencecorrection': [
      "",
      "Excellent start! Your understanding of sentence structure is growing.",
      "You are decoding sentence structure with impressive accuracy.",
      "Halfway to 100! You are handling sentence structure effortlessly.",
      "Centurion! You have conquered the complexities of sentence structure.",
      "Level 200! You are a supreme grandmaster of sentence structure.",
    ],
    'subjectverbagreement': [
      "",
      "Excellent start! Your understanding of subject-verb agreement is growing.",
      "You are navigating subject-verb agreement with increasing confidence.",
      "Halfway to 100! You are handling subject-verb agreement effortlessly.",
      "100 levels beat! You truly dominate subject-verb agreement.",
      "Double Centurion! No one knows subject-verb agreement better than you.",
    ],
    'tensemastery': [
      "",
      "Great job! Mastering tenses is key to true fluency.",
      "Your mastery of tenses is noticeably improving daily.",
      "50 levels cleared! Your tenses skills are rock solid.",
      "100 levels beat! You truly dominate tenses.",
      "Level 200! You have transcended the limits of tenses.",
    ],
    'voiceswap': [
      "",
      "Excellent start! Your understanding of active/passive voice is growing.",
      "Your skills in active/passive voice are becoming incredibly sharp.",
      "50 levels cleared! Your active/passive voice skills are rock solid.",
      "Level 100! Your execution of active/passive voice is flawless.",
      "Level 200! You have transcended the limits of active/passive voice.",
    ],
    'wordreorder': [
      "",
      "Excellent start! Your understanding of syntax is growing.",
      "You are navigating syntax with increasing confidence.",
      "Halfway there! You are a rising star in syntax.",
      "Centurion! You have conquered the complexities of syntax.",
      "Double Centurion! No one knows syntax better than you.",
    ],
    'modalsselection': [
      "",
      "Nice work! Conquering modals is a huge step forward.",
      "You are decoding modals with impressive accuracy.",
      "Halfway to 100! You are handling modals effortlessly.",
      "Level 100! You are an absolute master of modals.",
      "Level 200 reached! Your grasp of modals is legendary.",
    ],
    'prepositionchoice': [
      "",
      "Fantastic! Exploring prepositions will elevate your skills rapidly.",
      "You are navigating prepositions with increasing confidence.",
      "Amazing! You manipulate prepositions with natural ease.",
      "Level 100! You are an absolute master of prepositions.",
      "200 levels cleared! Your prepositions abilities are unmatched globally.",
    ],
    'pronounresolution': [
      "",
      "Excellent start! Your understanding of pronouns is growing.",
      "You are decoding pronouns with impressive accuracy.",
      "Level 50! Your command of pronouns is exceptional.",
      "Level 100! Your execution of pronouns is flawless.",
      "Level 200! You have transcended the limits of pronouns.",
    ],
    'punctuationmastery': [
      "",
      "Well done! You are building a strong foundation in punctuation.",
      "You are navigating punctuation with increasing confidence.",
      "50 levels cleared! Your punctuation skills are rock solid.",
      "Centurion! You have conquered the complexities of punctuation.",
      "Level 200 reached! Your grasp of punctuation is legendary.",
    ],
    'relativeclauses': [
      "",
      "Nice work! Conquering relative clauses is a huge step forward.",
      "Your mastery of relative clauses is noticeably improving daily.",
      "50 levels cleared! Your relative clauses skills are rock solid.",
      "Level 100! You are an absolute master of relative clauses.",
      "Level 200 reached! Your grasp of relative clauses is legendary.",
    ],
    'conditionals': [
      "",
      "Great job! Mastering conditionals is key to true fluency.",
      "Your skills in conditionals are becoming incredibly sharp.",
      "50 levels cleared! Your conditionals skills are rock solid.",
      "100 levels beat! You truly dominate conditionals.",
      "Double Centurion! No one knows conditionals better than you.",
    ],
    'conjunctions': [
      "",
      "Well done! You are building a strong foundation in conjunctions.",
      "Your progress in conjunctions is genuinely impressive.",
      "Halfway there! You are a rising star in conjunctions.",
      "100 levels beat! You truly dominate conjunctions.",
      "Level 200! You have transcended the limits of conjunctions.",
    ],
    'directindirectspeech': [
      "",
      "Great job! Mastering reported speech is key to true fluency.",
      "Your progress in reported speech is genuinely impressive.",
      "Level 50! Your command of reported speech is exceptional.",
      "Level 100! Your expertise in reported speech is elite.",
      "Level 200! You have transcended the limits of reported speech.",
    ],
    'ambientid': [
      "",
      "Nice work! Conquering ambient sounds is a huge step forward.",
      "You are navigating ambient sounds with increasing confidence.",
      "Level 50! Your command of ambient sounds is exceptional.",
      "Level 100! Your execution of ambient sounds is flawless.",
      "Double Centurion! No one knows ambient sounds better than you.",
    ],
    'audiofillblanks': [
      "",
      "Great job! Mastering audio gaps is key to true fluency.",
      "You are navigating audio gaps with increasing confidence.",
      "Level 50! Your command of audio gaps is exceptional.",
      "Centurion! You have conquered the complexities of audio gaps.",
      "200 levels cleared! Your audio gaps abilities are unmatched globally.",
    ],
    'audiomultiplechoice': [
      "",
      "Fantastic! Exploring audio analysis will elevate your skills rapidly.",
      "You are decoding audio analysis with impressive accuracy.",
      "Halfway there! You are a rising star in audio analysis.",
      "Level 100! Your expertise in audio analysis is elite.",
      "Double Centurion! No one knows audio analysis better than you.",
    ],
    'audiosentenceorder': [
      "",
      "Well done! You are building a strong foundation in audio sequencing.",
      "Your progress in audio sequencing is genuinely impressive.",
      "Halfway there! You are a rising star in audio sequencing.",
      "Centurion! You have conquered the complexities of audio sequencing.",
      "Level 200! You are a supreme grandmaster of audio sequencing.",
    ],
    'audiotruefalse': [
      "",
      "Nice work! Conquering audio verification is a huge step forward.",
      "Your mastery of audio verification is noticeably improving daily.",
      "Level 50! Your command of audio verification is exceptional.",
      "100 levels beat! You truly dominate audio verification.",
      "Level 200! You have transcended the limits of audio verification.",
    ],
    'detailspotlight': [
      "",
      "Excellent start! Your understanding of audio details is growing.",
      "Your mastery of audio details is noticeably improving daily.",
      "Amazing! You manipulate audio details with natural ease.",
      "Centurion! You have conquered the complexities of audio details.",
      "Level 200 reached! Your grasp of audio details is legendary.",
    ],
    'emotionrecognition': [
      "",
      "Fantastic! Exploring emotion recognition will elevate your skills rapidly.",
      "Your mastery of emotion recognition is noticeably improving daily.",
      "Halfway there! You are a rising star in emotion recognition.",
      "Level 100! Your expertise in emotion recognition is elite.",
      "Level 200! You have transcended the limits of emotion recognition.",
    ],
    'fastspeechdecoder': [
      "",
      "Nice work! Conquering fast speech is a huge step forward.",
      "Your progress in fast speech is genuinely impressive.",
      "Halfway to 100! You are handling fast speech effortlessly.",
      "Level 100! Your expertise in fast speech is elite.",
      "Level 200 reached! Your grasp of fast speech is legendary.",
    ],
    'listeninginference': [
      "",
      "Excellent start! Your understanding of audio inference is growing.",
      "You are decoding audio inference with impressive accuracy.",
      "50 levels cleared! Your audio inference skills are rock solid.",
      "Level 100! You are an absolute master of audio inference.",
      "200 levels cleared! Your audio inference abilities are unmatched globally.",
    ],
    'soundimagematch': [
      "",
      "Excellent start! Your understanding of sound matching is growing.",
      "Your skills in sound matching are becoming incredibly sharp.",
      "Amazing! You manipulate sound matching with natural ease.",
      "Level 100! Your execution of sound matching is flawless.",
      "Level 200! You have transcended the limits of sound matching.",
    ],
    'findwordmeaning': [
      "",
      "Excellent start! Your understanding of contextual meaning is growing.",
      "You are navigating contextual meaning with increasing confidence.",
      "Halfway to 100! You are handling contextual meaning effortlessly.",
      "Level 100! Your execution of contextual meaning is flawless.",
      "Level 200 reached! Your grasp of contextual meaning is legendary.",
    ],
    'guesstitle': [
      "",
      "Excellent start! Your understanding of main ideas is growing.",
      "Your progress in main ideas is genuinely impressive.",
      "Halfway to 100! You are handling main ideas effortlessly.",
      "Level 100! Your execution of main ideas is flawless.",
      "Level 200! You have transcended the limits of main ideas.",
    ],
    'paragraphsummary': [
      "",
      "Excellent start! Your understanding of summarization is growing.",
      "You are navigating summarization with increasing confidence.",
      "Amazing! You manipulate summarization with natural ease.",
      "Centurion! You have conquered the complexities of summarization.",
      "Level 200 reached! Your grasp of summarization is legendary.",
    ],
    'readandanswer': [
      "",
      "Excellent start! Your understanding of reading comprehension is growing.",
      "Your mastery of reading comprehension is noticeably improving daily.",
      "Halfway there! You are a rising star in reading comprehension.",
      "Centurion! You have conquered the complexities of reading comprehension.",
      "Level 200 reached! Your grasp of reading comprehension is legendary.",
    ],
    'readandmatch': [
      "",
      "Great job! Mastering semantic matching is key to true fluency.",
      "Your mastery of semantic matching is noticeably improving daily.",
      "Amazing! You manipulate semantic matching with natural ease.",
      "100 levels beat! You truly dominate semantic matching.",
      "200 levels cleared! Your semantic matching abilities are unmatched globally.",
    ],
    'readingconclusion': [
      "",
      "Excellent start! Your understanding of conclusions is growing.",
      "Your mastery of conclusions is noticeably improving daily.",
      "Halfway there! You are a rising star in conclusions.",
      "Level 100! Your execution of conclusions is flawless.",
      "200 levels cleared! Your conclusions abilities are unmatched globally.",
    ],
    'readinginference': [
      "",
      "Well done! You are building a strong foundation in reading inference.",
      "Your progress in reading inference is genuinely impressive.",
      "Halfway there! You are a rising star in reading inference.",
      "Level 100! Your execution of reading inference is flawless.",
      "200 levels cleared! Your reading inference abilities are unmatched globally.",
    ],
    'readingspeedcheck': [
      "",
      "Excellent start! Your understanding of reading speed is growing.",
      "Your progress in reading speed is genuinely impressive.",
      "Level 50! Your command of reading speed is exceptional.",
      "Centurion! You have conquered the complexities of reading speed.",
      "200 levels cleared! Your reading speed abilities are unmatched globally.",
    ],
    'sentenceorderreading': [
      "",
      "Well done! You are building a strong foundation in text sequencing.",
      "You are navigating text sequencing with increasing confidence.",
      "Level 50! Your command of text sequencing is exceptional.",
      "100 levels beat! You truly dominate text sequencing.",
      "Level 200! You have transcended the limits of text sequencing.",
    ],
    'truefalsereading': [
      "",
      "Fantastic! Exploring fact checking will elevate your skills rapidly.",
      "You are navigating fact checking with increasing confidence.",
      "Level 50! Your command of fact checking is exceptional.",
      "Centurion! You have conquered the complexities of fact checking.",
      "Level 200! You are a supreme grandmaster of fact checking.",
    ],
    'skimmingscanning': [
      "",
      "Excellent start! Your understanding of skimming and scanning is growing.",
      "You are navigating skimming and scanning with increasing confidence.",
      "Level 50! Your command of skimming and scanning is exceptional.",
      "Level 100! You are an absolute master of skimming and scanning.",
      "200 levels cleared! Your skimming and scanning abilities are unmatched globally.",
    ],
    'clozetest': [
      "",
      "Great job! Mastering cloze reading is key to true fluency.",
      "You are navigating cloze reading with increasing confidence.",
      "50 levels cleared! Your cloze reading skills are rock solid.",
      "Centurion! You have conquered the complexities of cloze reading.",
      "Double Centurion! No one knows cloze reading better than you.",
    ],
    'branchingdialogue': [
      "",
      "Nice work! Conquering dialogue paths is a huge step forward.",
      "You are decoding dialogue paths with impressive accuracy.",
      "Level 50! Your command of dialogue paths is exceptional.",
      "Level 100! You are an absolute master of dialogue paths.",
      "200 levels cleared! Your dialogue paths abilities are unmatched globally.",
    ],
    'conflictresolver': [
      "",
      "Fantastic! Exploring conflict resolution will elevate your skills rapidly.",
      "Your skills in conflict resolution are becoming incredibly sharp.",
      "Amazing! You manipulate conflict resolution with natural ease.",
      "Level 100! Your expertise in conflict resolution is elite.",
      "200 levels cleared! Your conflict resolution abilities are unmatched globally.",
    ],
    'elevatorpitch': [
      "",
      "Excellent start! Your understanding of elevator pitches is growing.",
      "Your mastery of elevator pitches is noticeably improving daily.",
      "Halfway to 100! You are handling elevator pitches effortlessly.",
      "Centurion! You have conquered the complexities of elevator pitches.",
      "Double Centurion! No one knows elevator pitches better than you.",
    ],
    'emergencyhub': [
      "",
      "Well done! You are building a strong foundation in emergency communication.",
      "Your progress in emergency communication is genuinely impressive.",
      "Halfway to 100! You are handling emergency communication effortlessly.",
      "100 levels beat! You truly dominate emergency communication.",
      "Level 200! You are a supreme grandmaster of emergency communication.",
    ],
    'gourmetorder': [
      "",
      "Excellent start! Your understanding of dining etiquette is growing.",
      "You are navigating dining etiquette with increasing confidence.",
      "Halfway to 100! You are handling dining etiquette effortlessly.",
      "Centurion! You have conquered the complexities of dining etiquette.",
      "Level 200 reached! Your grasp of dining etiquette is legendary.",
    ],
    'jobinterview': [
      "",
      "Fantastic! Exploring interviews will elevate your skills rapidly.",
      "Your mastery of interviews is noticeably improving daily.",
      "50 levels cleared! Your interviews skills are rock solid.",
      "Level 100! Your expertise in interviews is elite.",
      "Double Centurion! No one knows interviews better than you.",
    ],
    'medicalconsult': [
      "",
      "Fantastic! Exploring medical communication will elevate your skills rapidly.",
      "You are decoding medical communication with impressive accuracy.",
      "Level 50! Your command of medical communication is exceptional.",
      "Level 100! Your expertise in medical communication is elite.",
      "200 levels cleared! Your medical communication abilities are unmatched globally.",
    ],
    'situationalresponse': [
      "",
      "Fantastic! Exploring situational speaking will elevate your skills rapidly.",
      "Your progress in situational speaking is genuinely impressive.",
      "Halfway to 100! You are handling situational speaking effortlessly.",
      "Level 100! Your expertise in situational speaking is elite.",
      "200 levels cleared! Your situational speaking abilities are unmatched globally.",
    ],
    'socialspark': [
      "",
      "Excellent start! Your understanding of small talk is growing.",
      "Your progress in small talk is genuinely impressive.",
      "Halfway there! You are a rising star in small talk.",
      "Level 100! Your expertise in small talk is elite.",
      "Level 200 reached! Your grasp of small talk is legendary.",
    ],
    'traveldesk': [
      "",
      "Well done! You are building a strong foundation in travel communication.",
      "You are decoding travel communication with impressive accuracy.",
      "50 levels cleared! Your travel communication skills are rock solid.",
      "100 levels beat! You truly dominate travel communication.",
      "Level 200 reached! Your grasp of travel communication is legendary.",
    ],
    'dailyexpression': [
      "",
      "Well done! You are building a strong foundation in daily expressions.",
      "Your skills in daily expressions are becoming incredibly sharp.",
      "Halfway there! You are a rising star in daily expressions.",
      "Level 100! Your execution of daily expressions is flawless.",
      "200 levels cleared! Your daily expressions abilities are unmatched globally.",
    ],
    'dialogueroleplay': [
      "",
      "Well done! You are building a strong foundation in dialogue speaking.",
      "Your skills in dialogue speaking are becoming incredibly sharp.",
      "Amazing! You manipulate dialogue speaking with natural ease.",
      "Level 100! Your execution of dialogue speaking is flawless.",
      "Level 200! You are a supreme grandmaster of dialogue speaking.",
    ],
    'pronunciationfocus': [
      "",
      "Great job! Mastering pronunciation is key to true fluency.",
      "You are decoding pronunciation with impressive accuracy.",
      "50 levels cleared! Your pronunciation skills are rock solid.",
      "Level 100! You are an absolute master of pronunciation.",
      "Level 200 reached! Your grasp of pronunciation is legendary.",
    ],
    'repeatsentence': [
      "",
      "Great job! Mastering sentence repetition is key to true fluency.",
      "You are navigating sentence repetition with increasing confidence.",
      "50 levels cleared! Your sentence repetition skills are rock solid.",
      "Level 100! Your execution of sentence repetition is flawless.",
      "Level 200! You are a supreme grandmaster of sentence repetition.",
    ],
    'scenedescriptionspeaking': [
      "",
      "Excellent start! Your understanding of scene description is growing.",
      "Your progress in scene description is genuinely impressive.",
      "Amazing! You manipulate scene description with natural ease.",
      "Centurion! You have conquered the complexities of scene description.",
      "Double Centurion! No one knows scene description better than you.",
    ],
    'situationspeaking': [
      "",
      "Fantastic! Exploring contextual speaking will elevate your skills rapidly.",
      "You are navigating contextual speaking with increasing confidence.",
      "Halfway to 100! You are handling contextual speaking effortlessly.",
      "Level 100! Your execution of contextual speaking is flawless.",
      "Level 200! You are a supreme grandmaster of contextual speaking.",
    ],
    'speakmissingword': [
      "",
      "Great job! Mastering spoken cloze is key to true fluency.",
      "Your mastery of spoken cloze is noticeably improving daily.",
      "Halfway there! You are a rising star in spoken cloze.",
      "Centurion! You have conquered the complexities of spoken cloze.",
      "Level 200! You are a supreme grandmaster of spoken cloze.",
    ],
    'speakopposite': [
      "",
      "Great job! Mastering spoken antonyms is key to true fluency.",
      "Your progress in spoken antonyms is genuinely impressive.",
      "Halfway to 100! You are handling spoken antonyms effortlessly.",
      "100 levels beat! You truly dominate spoken antonyms.",
      "200 levels cleared! Your spoken antonyms abilities are unmatched globally.",
    ],
    'speaksynonym': [
      "",
      "Excellent start! Your understanding of spoken synonyms is growing.",
      "Your mastery of spoken synonyms is noticeably improving daily.",
      "Halfway there! You are a rising star in spoken synonyms.",
      "Level 100! Your expertise in spoken synonyms is elite.",
      "Level 200! You are a supreme grandmaster of spoken synonyms.",
    ],
    'yesnospeaking': [
      "",
      "Excellent start! Your understanding of rapid confirmation is growing.",
      "Your skills in rapid confirmation are becoming incredibly sharp.",
      "Level 50! Your command of rapid confirmation is exceptional.",
      "Level 100! Your expertise in rapid confirmation is elite.",
      "Level 200! You are a supreme grandmaster of rapid confirmation.",
    ],
    'academicword': [
      "",
      "Nice work! Conquering academic words is a huge step forward.",
      "Your mastery of academic words is noticeably improving daily.",
      "50 levels cleared! Your academic words skills are rock solid.",
      "Centurion! You have conquered the complexities of academic words.",
      "Level 200! You have transcended the limits of academic words.",
    ],
    'antonymsearch': [
      "",
      "Fantastic! Exploring antonyms will elevate your skills rapidly.",
      "You are navigating antonyms with increasing confidence.",
      "50 levels cleared! Your antonyms skills are rock solid.",
      "Level 100! Your expertise in antonyms is elite.",
      "Level 200! You have transcended the limits of antonyms.",
    ],
    'contextclues': [
      "",
      "Excellent start! Your understanding of context clues is growing.",
      "Your progress in context clues is genuinely impressive.",
      "50 levels cleared! Your context clues skills are rock solid.",
      "100 levels beat! You truly dominate context clues.",
      "200 levels cleared! Your context clues abilities are unmatched globally.",
    ],
    'flashcards': [
      "",
      "Great job! Mastering vocabulary recall is key to true fluency.",
      "Your progress in vocabulary recall is genuinely impressive.",
      "Halfway there! You are a rising star in vocabulary recall.",
      "Level 100! Your expertise in vocabulary recall is elite.",
      "Level 200! You have transcended the limits of vocabulary recall.",
    ],
    'idioms': [
      "",
      "Excellent start! Your understanding of idioms is growing.",
      "You are navigating idioms with increasing confidence.",
      "Halfway there! You are a rising star in idioms.",
      "Level 100! You are an absolute master of idioms.",
      "200 levels cleared! Your idioms abilities are unmatched globally.",
    ],
    'phrasalverbs': [
      "",
      "Excellent start! Your understanding of phrasal verbs is growing.",
      "Your mastery of phrasal verbs is noticeably improving daily.",
      "Halfway there! You are a rising star in phrasal verbs.",
      "100 levels beat! You truly dominate phrasal verbs.",
      "Level 200! You have transcended the limits of phrasal verbs.",
    ],
    'prefixsuffix': [
      "",
      "Great start! You're learning how to build and modify words perfectly.",
      "You are getting so good at connecting prefixes and suffixes!",
      "Halfway to 100! Your vocabulary is growing stronger with every new affix you learn.",
      "Level 100! You can now confidently shape and transform words like a native speaker.",
      "Level 200 reached! You have completely mastered the art of word building.",
    ],
    'synonymsearch': [
      "",
      "Great job! Mastering synonyms is key to true fluency.",
      "Your mastery of synonyms is noticeably improving daily.",
      "Halfway there! You are a rising star in synonyms.",
      "Centurion! You have conquered the complexities of synonyms.",
      "Level 200 reached! Your grasp of synonyms is legendary.",
    ],
    'topicvocab': [
      "",
      "Fantastic! Exploring topic vocabulary will elevate your skills rapidly.",
      "Your progress in topic vocabulary is genuinely impressive.",
      "Halfway to 100! You are handling topic vocabulary effortlessly.",
      "Centurion! You have conquered the complexities of topic vocabulary.",
      "200 levels cleared! Your topic vocabulary abilities are unmatched globally.",
    ],
    'wordformation': [
      "",
      "Great job! You're really getting the hang of how words fit together.",
      "You're doing fantastic! Your vocabulary is growing stronger every day.",
      "Halfway to a hundred! You're building words like a true natural now.",
      "Level 100! This is a massive milestone. You've truly mastered the art of word building!",
      "Level 200! Absolutely incredible. You understand the very DNA of the English language.",
    ],
    'contextualusage': [
      "",
      "Well done! You are building a strong foundation in word usage.",
      "Your skills in word usage are becoming incredibly sharp.",
      "Amazing! You manipulate word usage with natural ease.",
      "Level 100! Your execution of word usage is flawless.",
      "Level 200 reached! Your grasp of word usage is legendary.",
    ],
    'collocations': [
      "",
      "Well done! You are building a strong foundation in collocations.",
      "You are decoding collocations with impressive accuracy.",
      "Halfway to 100! You are handling collocations effortlessly.",
      "100 levels beat! You truly dominate collocations.",
      "200 levels cleared! Your collocations abilities are unmatched globally.",
    ],
    'completesentence': [
      "",
      "Excellent start! Your understanding of sentence completion is growing.",
      "You are navigating sentence completion with increasing confidence.",
      "Amazing! You manipulate sentence completion with natural ease.",
      "Level 100! Your expertise in sentence completion is elite.",
      "Level 200! You have transcended the limits of sentence completion.",
    ],
    'correctionwriting': [
      "",
      "Excellent start! Your understanding of writing correction is growing.",
      "Your mastery of writing correction is noticeably improving daily.",
      "Level 50! Your command of writing correction is exceptional.",
      "Centurion! You have conquered the complexities of writing correction.",
      "Double Centurion! No one knows writing correction better than you.",
    ],
    'dailyjournal': [
      "",
      "Great job! Mastering journaling is key to true fluency.",
      "Your skills in journaling are becoming incredibly sharp.",
      "Halfway there! You are a rising star in journaling.",
      "Level 100! You are an absolute master of journaling.",
      "Level 200! You have transcended the limits of journaling.",
    ],
    'describesituationwriting': [
      "",
      "Well done! You are building a strong foundation in descriptive writing.",
      "Your progress in descriptive writing is genuinely impressive.",
      "Amazing! You manipulate descriptive writing with natural ease.",
      "Centurion! You have conquered the complexities of descriptive writing.",
      "Level 200! You have transcended the limits of descriptive writing.",
    ],
    'essaydrafting': [
      "",
      "Fantastic! Exploring essay drafting will elevate your skills rapidly.",
      "You are navigating essay drafting with increasing confidence.",
      "Halfway to 100! You are handling essay drafting effortlessly.",
      "Level 100! You are an absolute master of essay drafting.",
      "Level 200 reached! Your grasp of essay drafting is legendary.",
    ],
    'fixthesentence': [
      "",
      "Well done! You are building a strong foundation in sentence editing.",
      "Your mastery of sentence editing is noticeably improving daily.",
      "Halfway there! You are a rising star in sentence editing.",
      "100 levels beat! You truly dominate sentence editing.",
      "200 levels cleared! Your sentence editing abilities are unmatched globally.",
    ],
    'opinionwriting': [
      "",
      "Excellent start! Your understanding of opinion writing is growing.",
      "Your progress in opinion writing is genuinely impressive.",
      "50 levels cleared! Your opinion writing skills are rock solid.",
      "Level 100! Your execution of opinion writing is flawless.",
      "Level 200! You are a supreme grandmaster of opinion writing.",
    ],
    'sentencebuilder': [
      "",
      "Excellent start! Your understanding of sentence building is growing.",
      "You are decoding sentence building with impressive accuracy.",
      "Amazing! You manipulate sentence building with natural ease.",
      "100 levels beat! You truly dominate sentence building.",
      "Double Centurion! No one knows sentence building better than you.",
    ],
    'shortanswerwriting': [
      "",
      "Excellent start! Your understanding of short answers is growing.",
      "You are navigating short answers with increasing confidence.",
      "Halfway there! You are a rising star in short answers.",
      "Level 100! You are an absolute master of short answers.",
      "Level 200 reached! Your grasp of short answers is legendary.",
    ],
    'summarizestorywriting': [
      "",
      "Nice work! Conquering story summarization is a huge step forward.",
      "Your skills in story summarization are becoming incredibly sharp.",
      "Halfway to 100! You are handling story summarization effortlessly.",
      "Centurion! You have conquered the complexities of story summarization.",
      "Double Centurion! No one knows story summarization better than you.",
    ],
    'writingemail': [
      "",
      "Excellent start! Your understanding of email writing is growing.",
      "You are navigating email writing with increasing confidence.",
      "Amazing! You manipulate email writing with natural ease.",
      "Centurion! You have conquered the complexities of email writing.",
      "Double Centurion! No one knows email writing better than you.",
    ],

    'elitemastery': [
      "",
      "Great job! These advanced challenges are making you much sharper.",
      "Your speed and accuracy are improving significantly.",
      "Halfway to 100! You are performing at a very high level.",
      "Level 100! Your dedication to learning is paying off.",
      "Level 200 reached! You have mastered the most difficult challenges.",
    ],
  };

  StoryServiceImpl();

  @override
  StoryBeat? getStoryBeat(BuildContext context, String categoryId, int level) {
    if (!milestones.contains(level)) return null;

    final int beatIndex = milestones.indexOf(level);
    final String cleanId = categoryId.toLowerCase().replaceAll('_', '');

    // 1. Level 1: Granular "NEW QUEST" Matching (Modern & Kids)
    if (level == 1) {
      // Check Granular Modern First
      if (modernGameScripts.containsKey(categoryId)) {
        return StoryBeat(
          title: context.tr('story.new_quest', fallback: 'New Quest'),
          text: context.tr(
            'story_scripts.$categoryId',
            fallback: modernGameScripts[categoryId]!,
          ),
          mascotEmoji: _getMascotEmoji(categoryId),
          themeColor: _getCategoryColor(categoryId),
        );
      }

      // Check Kids (using cleanId)
      if (kidsScripts.containsKey(cleanId)) {
        return StoryBeat(
          title: context.tr('story.new_quest', fallback: 'New Quest'),
          text: context.tr(
            'story_scripts.$cleanId',
            fallback: kidsScripts[cleanId]![0],
          ),
          mascotEmoji: _getMascotEmoji(cleanId),
          themeColor: _getCategoryColor(cleanId),
        );
      }

      // Universal Fallback with Category Intelligence
      final bool isKids =
          categoryId.contains('kids') ||
          [
            'alphabet',
            'numbers',
            'colors',
            'shapes',
            'animals',
            'fruits',
            'family',
            'school',
            'verbs',
            'routine',
            'emotions',
            'prepositions',
            'phonics',
            'time',
            'opposites',
            'daynight',
            'nature',
            'home',
            'food',
            'transport',
            'bodyparts',
            'clothing',
            'handwriting',
            'weather',
            'professions',
          ].contains(cleanId);

      final String broadCategory = _getBroadCategory(categoryId);
      final String categoryName = broadCategory.isNotEmpty
          ? broadCategory[0].toUpperCase() + broadCategory.substring(1)
          : "Vowl";

      return StoryBeat(
        title: context.tr('story.new_quest', fallback: 'New Quest'),
        text: isKids
            ? context.tr(
                'story.fallback_kids',
                fallback: 'Let\'s go on an adventure!',
                args: [categoryName],
              )
            : context.tr(
                'story.fallback_modern',
                fallback: 'Your mission begins now.',
                args: [categoryName],
              ),
        mascotEmoji: isKids ? "✨" : "🚀",
        themeColor: _getCategoryColor(cleanId),
      );
    }

    // 2. Milestones: 10, 20, 50, 100, 200 (Legacy Scripts)
    if (kidsScripts.containsKey(cleanId)) {
      final script = kidsScripts[cleanId]!;
      if (beatIndex < script.length) {
        return StoryBeat(
          title: context.tr('story.adventure_log', fallback: 'Adventure Log'),
          text: context.tr(
            'story_scripts.${cleanId}_beat_$beatIndex',
            fallback: script[beatIndex],
          ),
          mascotEmoji: _getMascotEmoji(cleanId),
          themeColor: _getCategoryColor(cleanId),
        );
      }
    }

    // 3. Milestones > 1 (Legacy Scripts)
    // First try granular match
    if (legacyAdultScripts.containsKey(cleanId)) {
      final script = legacyAdultScripts[cleanId]!;
      if (beatIndex < script.length && script[beatIndex].isNotEmpty) {
        return StoryBeat(
          title: context.tr('story.system_update', fallback: 'System Update'),
          text: context.tr(
            'story_scripts.${cleanId}_beat_$beatIndex',
            fallback: script[beatIndex],
          ),
          mascotEmoji: _getMascotEmoji(categoryId),
          themeColor: _getCategoryColor(categoryId),
        );
      }
    }

    // Try broad adult category fallback
    final String broadId = _getBroadCategory(categoryId);
    if (legacyAdultScripts.containsKey(broadId)) {
      final script = legacyAdultScripts[broadId]!;
      if (beatIndex < script.length && script[beatIndex].isNotEmpty) {
        return StoryBeat(
          title: context.tr('story.system_update', fallback: 'System Update'),
          text: context.tr(
            'story_scripts.${broadId}_beat_$beatIndex',
            fallback: script[beatIndex],
          ),
          mascotEmoji: _getMascotEmoji(categoryId),
          themeColor: _getCategoryColor(categoryId),
        );
      }
    }

    return null;
  }

  /// Resolves [gameType] to its authoritative [QuestType] category via the
  /// [GameSubtype] enum, or `null` if it isn't a recognized adult/modern
  /// subtype id (in which case it's most likely a kids-zone topic id like
  /// 'animal' or 'food', handled separately via [kidsScripts]).
  ///
  /// Shared by [_getBroadCategory], [_getMascotEmoji], and
  /// [_getCategoryColor] so all three theming lookups agree with each
  /// other and with the exact category the legacy milestone scripts use -
  /// see the doc comment on [_getMascotEmoji] for why this matters.
  QuestType? _resolveQuestType(String gameType) {
    final String id = gameType.toLowerCase();
    final bool isKnownSubtype = GameSubtype.values.any(
      (s) => s.name.toLowerCase() == id,
    );
    if (!isKnownSubtype) return null;
    return GameSubtype.fromString(gameType).category;
  }

  String _getBroadCategory(String gameType) {
    // Not a recognized adult/modern GameSubtype id (most likely a
    // kids-zone topic id like 'animal' or 'food', which is handled
    // earlier in getStoryBeat() via kidsScripts - this path is only
    // reached as a fallback). No broad adult category applies.
    return _resolveQuestType(gameType)?.serializedName ?? '';
  }

  /// Emoji shown per broad category for every *recognized* adult/modern
  /// [GameSubtype] id, keyed by the same [QuestType] used for milestone
  /// script selection (see [legacyAdultScripts]).
  static const Map<QuestType, String> _categoryEmoji = {
    QuestType.grammar: '⚖️',
    QuestType.writing: '✍️',
    QuestType.speaking: '🗣️',
    QuestType.listening: '🎧',
    QuestType.reading: '📖',
    QuestType.eliteMastery: '🏆',
    QuestType.accent: '🎙️',
    QuestType.roleplay: '🎭',
    QuestType.vocabulary: '📚',
  };

  /// BUG FIX: this previously matched *every* id (kids-zone topics AND
  /// adult/modern GameSubtype ids alike) purely by checking whether the
  /// lowercased id string *contains* a handful of category substrings, in
  /// a fixed priority order. That worked by coincidence for ids that happen
  /// to literally contain their category's keyword, but produced wrong
  /// results wherever a subtype's name doesn't: e.g. `phrasalVerbs` (a
  /// **Vocabulary** subtype) contains "verb" and so matched the kids-zone
  /// "verbs" branch (🏃) instead of a vocabulary emoji; `consonantClarity`,
  /// `dialectDrill`, `connectedSpeech`, etc. (all **Accent** subtypes)
  /// don't literally contain "accent" and fell through to the generic
  /// default; and `accentShadowing` (an **Elite Mastery** subtype)
  /// contains "accent" and so was themed as plain Accent instead of Elite.
  /// Vocabulary additionally had no emoji branch at all.
  ///
  /// Now, any id that's a recognized [GameSubtype] is themed via the exact
  /// enum-backed category lookup already used for milestone script
  /// selection (guaranteed correct, no substring guessing). The original
  /// substring heuristic is preserved unchanged as the fallback for
  /// kids-zone topic ids (which aren't part of the [GameSubtype] enum and
  /// have no authoritative category to look up), so no kids-zone behavior
  /// changes.
  String _getMascotEmoji(String categoryId) {
    final resolvedCategory = _resolveQuestType(categoryId);
    if (resolvedCategory != null) {
      return _categoryEmoji[resolvedCategory] ?? '🦉';
    }

    final String id = categoryId.toLowerCase();
    if (id.contains('animal')) return '🦁';
    if (id.contains('alphabet')) return '🔠';
    if (id.contains('number')) return '🔢';
    if (id.contains('color')) return '🎨';
    if (id.contains('shape')) return '🔺';
    if (id.contains('fruit')) return '🍎';
    if (id.contains('family')) return '🏠';
    if (id.contains('school')) return '🎒';
    if (id.contains('verb')) return '🏃';
    if (id.contains('routine')) return '⏰';
    if (id.contains('emotion')) return '😊';
    if (id.contains('preposition')) return '🐭';
    if (id.contains('phonics')) return '🔊';
    if (id.contains('time')) return '🕰️';
    if (id.contains('opposite')) return '🌗';
    if (id.contains('daynight')) return '☀️';
    if (id.contains('nature')) return '🌳';
    if (id.contains('home')) return '🏠';
    if (id.contains('food')) return '🍳';
    if (id.contains('transport')) return '🚀';
    if (id.contains('bodypart')) return '🧒';
    if (id.contains('clothing')) return '🎩';
    if (id.contains('grammar')) return '⚖️';
    if (id.contains('write')) return '✍️';
    if (id.contains('speak')) return '🗣️';
    if (id.contains('listen')) return '🎧';
    if (id.contains('read')) return '📖';
    if (id.contains('elite')) return '🏆';
    if (id.contains('accent')) return '🎙️';
    if (id.contains('roleplay')) return '🎭';
    return '🦉';
  }

  /// BUG FIX: same class of cross-category substring collision as
  /// [_getMascotEmoji] (see its doc comment for concrete examples) -
  /// resolved the same way: recognized [GameSubtype] ids are themed via
  /// the authoritative enum-backed category lookup first; the original
  /// substring heuristic remains, unchanged, as the fallback for kids-zone
  /// topic ids.
  Color _getCategoryColor(String categoryId) {
    final resolvedCategory = _resolveQuestType(categoryId);
    if (resolvedCategory != null) {
      return LevelThemeHelper.getCategoryBaseColor(resolvedCategory.name);
    }

    final String id = categoryId.toLowerCase();

    // Kids Zone exact color matching
    // Fallback on LevelThemeHelper's unified method for all 25 kids games
    // We check if it's a known kids game color by seeing if it matches one of the kids IDs.
    // Actually, we can just check if it's one of the known 25, or let the adult fallback handle it.
    final kidsColor = LevelThemeHelper.getKidsGameColor(id);
    if (kidsColor != Colors.blue || id == 'numbers') {
      // 'numbers' is blue, so it's a valid return
      return kidsColor;
    }

    // Adult category fallbacks
    if (id.contains('speak') || id.contains('dialogue')) {
      return LevelThemeHelper.getCategoryBaseColor('speaking');
    }
    if (id.contains('grammar') || id.contains('sentence')) {
      return LevelThemeHelper.getCategoryBaseColor('grammar');
    }
    if (id.contains('write') || id.contains('journal')) {
      return LevelThemeHelper.getCategoryBaseColor('writing');
    }
    if (id.contains('listen') || id.contains('audio')) {
      return LevelThemeHelper.getCategoryBaseColor('listening');
    }
    if (id.contains('accent') || id.contains('pronunciation')) {
      return LevelThemeHelper.getCategoryBaseColor('accent');
    }
    if (id.contains('roleplay') || id.contains('situation')) {
      return LevelThemeHelper.getCategoryBaseColor('roleplay');
    }
    if (id.contains('read') || id.contains('paragraph')) {
      return LevelThemeHelper.getCategoryBaseColor('reading');
    }
    if (id.contains('vocab') || id.contains('word')) {
      return LevelThemeHelper.getCategoryBaseColor('vocabulary');
    }
    if (id.contains('elite') || id.contains('mastery')) {
      return LevelThemeHelper.getCategoryBaseColor('elitemastery');
    }

    return LevelThemeHelper.getCategoryBaseColor('grammar');
  }
}
