import 'package:flutter/material.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

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
        "Domain Mastery. Learn the specific words that define any subject area.",
    'wordFormation':
        "The Morphologist. Learn how words are built from their core roots.",
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
      "The Grammar Goblins are defeated! Your sentences are gaining structure and power. Onward!",
      "A storm of confusion has passed. You are now a recognized Builder of Clarity!",
      "The High Council of Words is watching your progress. Your structural logic is becoming elite!",
      "You have reached the Century Milestone! Your command of syntax is virtually flawless.",
      "Ultimate Linguistic Mastery! The Great Library of Wisdom is now yours to command.",
    ],
    'writing': [
      "",
      "Your creative flow is improving! The Ink Wells are filling with your revolutionary ideas.",
      "A true Author emerges from the mist. Your written messages are now a beacon of clarity.",
      "The Great Scroll is nearly complete. Your legacy as a writer is becoming legendary!",
      "100 levels of pure creation! Your unique voice is now a powerful tool of expression.",
      "The Sovereign of Scripts! You have mastered the ancient and modern art of the pen.",
    ],
    'speaking': [
      "",
      "The Echo Valley is clear! Your pronunciation is sharp, confident, and full of life.",
      "You are now speaking the language of the future. The world is starting to listen!",
      "The Speaker's Podium is yours. You have the charisma to lead and inspire anyone.",
      "A truly golden voice! 100 levels of absolute confidence, clarity, and resonance.",
      "The Grand Orator! Your speech can now move mountains and bridge any cultural gap.",
    ],
    'listening': [
      "",
      "You've decoded the secrets of the Whisper Woods! Your focus is becoming razor-sharp.",
      "The sound of success is ringing loud! You are developing the ears of a true linguist.",
      "Silence is your ally. You now hear the nuances that others completely miss.",
      "A Master of Sonic Harmony! 100 levels of perfect auditory focus and comprehension.",
      "The Eternal Listener! You now understand the heartbeat and the soul of the world.",
    ],
    'accent': [
      "",
      "You sound great! Your speaking is getting much clearer and more natural.",
      "Amazing progress! You are starting to sound just like a local speaker.",
      "Halfway to 100! Your pronunciation is incredibly smooth and easy to understand.",
      "Level 100 reached! You can now speak clearly and naturally with anyone in the world.",
      "Level 200 reached! You have completely mastered clear and natural English pronunciation.",
    ],
    'vocabulary': [
      "",
      "Your vocabulary is blooming like a vibrant digital garden. Your mind is expanding!",
      "You have the perfect word for every possible situation. You are becoming a Sage!",
      "The Lexicon is vast and deep, but you have successfully mastered its furthest reaches.",
      "100 levels of pure wisdom! Your mind is now a treasure chest of expressive power.",
      "The Master of Tongues! Your wisdom and word-power now know no human bounds.",
    ],
    'roleplay': [
      "",
      "A master of social grace! You handle every complex situation with effortless ease.",
      "The spotlight is yours. Your social performances are now truly authentic and moving.",
      "A natural leader in any environment. You possess the charisma of a visionary.",
      "100 roles played with perfection! You are now a master of deep human connection.",
      "The Ultimate Social Chameleon! You have the skill to thrive in any reality or culture.",
    ],
    'reading': [
      "",
      "You've learned to read between the lines. The hidden truths are finally being revealed.",
      "A scholar in the making! Your speed and comprehension are becoming unmatched.",
      "The Great Library is now your home. You know every secret and story it holds.",
      "100 chapters of wisdom completed! Your mind is an endless ocean of knowledge.",
      "The Grand Scholar! You have learned to read the stories written in the stars.",
    ],
    'elitemastery': [
      "",
      "Your skills are sharpening to a fine edge. The Elite trials are only making you stronger.",
      "A Master in the shadows. Your speed and accuracy are reaching superhuman levels.",
      "The Vanguard of Vowl! You are among the top 1% of learners globally. Keep pushing!",
      "Century of Excellence! Your dedication to mastery is an inspiration to all.",
      "The Zenith of Achievement! You have conquered the most difficult path in the Nexus.",
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

    // Try broad adult category for milestones > 1
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

  /// Theme color per broad category for every *recognized* adult/modern
  /// [GameSubtype] id. Same key set and rationale as [_categoryEmoji].
  static const Map<QuestType, Color> _categoryColors = {
    QuestType.speaking: Color(0xFFE11D48), // Rose 600
    QuestType.grammar: Color(0xFF0284C7), // Sky 600
    QuestType.writing: Color(0xFFD97706), // Amber 600
    QuestType.listening: Color(0xFF4F46E5), // Indigo 600
    QuestType.accent: Color(0xFFDC2626), // Red 600
    QuestType.roleplay: Color(0xFF0891B2), // Cyan 600
    QuestType.reading: Color(0xFF1D4ED8), // Blue 700
    QuestType.vocabulary: Color(0xFF059669), // Emerald 600
    QuestType.eliteMastery: Color(0xFFEAB308), // Yellow 500
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
      return _categoryColors[resolvedCategory] ?? const Color(0xFF4F46E5);
    }

    final String id = categoryId.toLowerCase();

    if (id.contains('alphabet') ||
        id.contains('speak') ||
        id.contains('bodypart') ||
        id.contains('family')) {
      return const Color(0xFFE11D48); // Rose 600
    }
    if (id.contains('number') ||
        id.contains('grammar') ||
        id.contains('clothing') ||
        id.contains('time')) {
      return const Color(0xFF0284C7); // Sky 600
    }
    if (id.contains('color') ||
        id.contains('write') ||
        id.contains('shape') ||
        id.contains('home')) {
      return const Color(0xFFD97706); // Amber 600
    }
    if (id.contains('animal') ||
        id.contains('listen') ||
        id.contains('school') ||
        id.contains('routine')) {
      return const Color(0xFF4F46E5); // Indigo 600
    }
    if (id.contains('fruit') ||
        id.contains('accent') ||
        id.contains('food') ||
        id.contains('opposite')) {
      return const Color(0xFFDC2626); // Red 600
    }
    if (id.contains('emotion') ||
        id.contains('roleplay') ||
        id.contains('daynight') ||
        id.contains('verb')) {
      return const Color(0xFF0891B2); // Cyan 600
    }
    if (id.contains('transport') ||
        id.contains('read') ||
        id.contains('preposition') ||
        id.contains('phonics')) {
      return const Color(0xFF1D4ED8); // Blue 700
    }
    if (id.contains('nature') || id.contains('vocab')) {
      return const Color(0xFF059669); // Emerald 600
    }
    if (id.contains('elite')) return const Color(0xFFEAB308); // Yellow 500

    return const Color(0xFF4F46E5); // Indigo 600
  }
}
