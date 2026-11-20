import 'package:vowl/core/data/models/phased_quest_model.dart';

/// Default fallback quests for the Flashcard Learn Phase if network or asset load fails.
List<PhasedQuest> getFlashcardLearnFallbackQuests(int level) => [
  PhasedQuest(
    id: 'FALLBACK_L${level}_1',
    level: level,
    word: 'AUTHENTIC',
    pronunciation: '/ɔːˈθen.tɪk/',
    definition:
        'Genuine, real, and true to original traditions rather than an imitation.',
    example:
        'The chef insisted on using only authentic Italian ingredients for the pasta.',
    nativeTip:
        "Native speakers often describe honest, grounded people as 'very authentic'.",
    commonMistake:
        "Don't confuse 'authentic' with 'original' — an original idea is new; an authentic item is real and genuine.",
    familyWords: const ['authenticity', 'authenticate', 'authentically'],
    rawExtra: const {
      'syllables': ['au', 'then', 'tic'],
      'stressedSyllableIndex': 1,
      'contextDomain': 'Culinary & Traditions',
      'collocations': [
        'authentic cuisine',
        'authentic leadership',
        'authentic smile',
      ],
    },
  ),
  PhasedQuest(
    id: 'FALLBACK_L${level}_2',
    level: level,
    word: 'GENUINE',
    pronunciation: '/ˈdʒen.ju.ɪn/',
    definition: 'Truly what something is said to be; honest and sincere.',
    example: 'Her genuine smile immediately put everyone in the room at ease.',
    nativeTip:
        "Use 'genuine' for sincere feelings or real materials like leather.",
    commonMistake:
        "Don't confuse 'genuine' with 'legitimate' — genuine is sincerity; legitimate is legal validity.",
    familyWords: const ['genuineness', 'genuinely'],
    rawExtra: const {
      'syllables': ['gen', 'u', 'ine'],
      'stressedSyllableIndex': 0,
      'contextDomain': 'Character & Sincerity',
      'collocations': ['genuine smile', 'genuine leather', 'genuine interest'],
    },
  ),
  PhasedQuest(
    id: 'FALLBACK_L${level}_3',
    level: level,
    word: 'LEGITIMATE',
    pronunciation: '/lɪˈdʒɪt.ə.mət/',
    definition: 'Conforming to the law or rules; valid and justified.',
    example:
        'The committee raised several legitimate concerns regarding public safety.',
    nativeTip:
        "Native speakers shorten this to 'legit' in casual conversation.",
    commonMistake:
        "Don't confuse with 'authentic' — a claim is legitimate (valid), an antique is authentic (real).",
    familyWords: const ['legitimacy', 'legitimize', 'legitimately'],
    rawExtra: const {
      'syllables': ['le', 'git', 'i', 'mate'],
      'stressedSyllableIndex': 1,
      'contextDomain': 'Legal & Procedural',
      'collocations': [
        'legitimate concern',
        'legitimate business',
        'legitimate claim',
      ],
    },
  ),
];

/// Default fallback quests for the Flashcard Practice Phase if network or asset load fails.
List<PhasedQuest> getFlashcardPracticeFallbackQuests(int level) => [
  PhasedQuest(
    id: 'FALLBACK_P$level',
    level: level,
    word: 'AUTHENTIC',
    example:
        'The chef insisted on using only _____ Italian ingredients for the pasta.',
    rawExtra: const {
      'hint': 'Think of a 3-syllable word meaning genuine.',
      'scrambledChunks': ['AU', 'THEN', 'TIC', 'TION', 'IC'],
      'collocationOptions': [
        'authentic cuisine',
        'authentic weather',
        'authentic price',
      ],
      'correctCollocationIndex': 0,
    },
  ),
];
