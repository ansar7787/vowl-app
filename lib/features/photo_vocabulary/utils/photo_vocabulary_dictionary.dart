class PhotoDictionaryEntry {
  final String ipa;
  final String definition;
  final String example;
  final String grammarTip;

  const PhotoDictionaryEntry({
    required this.ipa,
    required this.definition,
    required this.example,
    required this.grammarTip,
  });
}

class PhotoVocabularyDictionary {
  static const Map<String, PhotoDictionaryEntry> dictionary = {
    // Electronics & Tech
    'laptop': PhotoDictionaryEntry(
      ipa: '/ˈlæp.tɒp/',
      definition: 'A portable computer small enough to use on your lap.',
      example: 'She typed the report on her new laptop.',
      grammarTip: 'Noun. Often paired with prepositions "on" or "with".',
    ),
    'computer': PhotoDictionaryEntry(
      ipa: '/kəmˈpjuː.tər/',
      definition: 'An electronic device for storing and processing data.',
      example: 'The computer is rendering the video right now.',
      grammarTip: 'Noun. Can be modified as "desktop computer" or "personal computer".',
    ),
    'mobile phone': PhotoDictionaryEntry(
      ipa: '/ˈməʊ.baɪl fəʊn/',
      definition: 'A portable telephone that can make and receive calls.',
      example: 'Please put your mobile phone on silent during the movie.',
      grammarTip: 'Noun. In American English, often called a "cell phone".',
    ),
    'phone': PhotoDictionaryEntry(
      ipa: '/fəʊn/',
      definition: 'A device used for transmitting voices over a distance.',
      example: 'His phone rang right in the middle of the meeting.',
      grammarTip: 'Noun. Short for telephone. Can also be used as a verb: "I will phone him."',
    ),
    'keyboard': PhotoDictionaryEntry(
      ipa: '/ˈkiː.bɔːd/',
      definition: 'A panel of keys that operate a computer or typewriter.',
      example: 'He bought a mechanical keyboard for faster typing.',
      grammarTip: 'Noun. The keys are pressed, so we say "type on a keyboard".',
    ),
    'mouse': PhotoDictionaryEntry(
      ipa: '/maʊs/',
      definition: 'A small hand-held device used to control a computer screen.',
      example: 'Click the left button on your mouse to open the link.',
      grammarTip: 'Noun. Plural for the device is "mice" or "mouses".',
    ),
    'screen': PhotoDictionaryEntry(
      ipa: '/skriːn/',
      definition: 'The flat surface of a device where images and text are displayed.',
      example: 'Staring at a bright screen all day can hurt your eyes.',
      grammarTip: 'Noun. Often used in compounds like "touchscreen" or "widescreen".',
    ),
    
    // Furniture & Home
    'desk': PhotoDictionaryEntry(
      ipa: '/desk/',
      definition: 'A piece of furniture with a flat surface, used for working or studying.',
      example: 'She organized the papers on her wooden desk.',
      grammarTip: 'Noun. We usually say "sit at a desk", not "sit on a desk".',
    ),
    'chair': PhotoDictionaryEntry(
      ipa: '/tʃeər/',
      definition: 'A separate seat for one person, typically with a back and four legs.',
      example: 'He pulled up a chair and joined the conversation.',
      grammarTip: 'Noun. We say "sit in a chair" (if it has arms) or "sit on a chair" (no arms).',
    ),
    'table': PhotoDictionaryEntry(
      ipa: '/ˈteɪ.bəl/',
      definition: 'A piece of furniture with a flat top and one or more legs.',
      example: 'They gathered around the dining table for dinner.',
      grammarTip: 'Noun. We say "sit at the table".',
    ),
    'couch': PhotoDictionaryEntry(
      ipa: '/kaʊtʃ/',
      definition: 'A long upholstered piece of furniture for several people to sit on.',
      example: 'We relaxed on the couch and watched a movie.',
      grammarTip: 'Noun. Synonymous with "sofa".',
    ),
    'bed': PhotoDictionaryEntry(
      ipa: '/bed/',
      definition: 'A piece of furniture for sleep or rest.',
      example: 'I was so tired I went straight to bed.',
      grammarTip: 'Noun. When referring to sleeping, we say "go to bed" (without "the").',
    ),
    'door': PhotoDictionaryEntry(
      ipa: '/dɔːr/',
      definition: 'A hinged, sliding, or revolving barrier at the entrance to a room or building.',
      example: 'Please close the door behind you.',
      grammarTip: 'Noun. We say "open/close the door" or "knock on the door".',
    ),
    'window': PhotoDictionaryEntry(
      ipa: '/ˈwɪn.dəʊ/',
      definition: 'An opening in a wall, fitted with glass to let in light and air.',
      example: 'She looked out the window at the falling snow.',
      grammarTip: 'Noun. We say "look out the window" or "look through the window".',
    ),
    'plant': PhotoDictionaryEntry(
      ipa: '/plɑːnt/',
      definition: 'A living organism, such as trees, shrubs, herbs, and ferns.',
      example: 'Don\'t forget to water the plant while I am away.',
      grammarTip: 'Noun. Can also be a verb: "to plant a seed".',
    ),

    // Food & Drink
    'coffee': PhotoDictionaryEntry(
      ipa: '/ˈkɒf.i/',
      definition: 'A hot drink made from the roasted and ground seeds (beans) of a tropical shrub.',
      example: 'I need a cup of hot coffee to wake up this morning.',
      grammarTip: 'Noun. Uncountable in general ("I love coffee"), but countable when ordering ("Two coffees, please").',
    ),
    'cup': PhotoDictionaryEntry(
      ipa: '/kʌp/',
      definition: 'A small, bowl-shaped container for drinking from, typically having a handle.',
      example: 'She poured the tea into a porcelain cup.',
      grammarTip: 'Noun. Often used as a unit of measurement in recipes.',
    ),
    'mug': PhotoDictionaryEntry(
      ipa: '/mʌɡ/',
      definition: 'A large cup, typically cylindrical with a handle and used without a saucer.',
      example: 'He drank hot chocolate from his favorite winter mug.',
      grammarTip: 'Noun. Usually used for hot drinks in informal settings.',
    ),
    'bottle': PhotoDictionaryEntry(
      ipa: '/ˈbɒt.əl/',
      definition: 'A glass or plastic container with a narrow neck, used for storing drinks.',
      example: 'He brought a bottle of water to the gym.',
      grammarTip: 'Noun. Commonly used with the preposition "of" (e.g., bottle of water).',
    ),
    'water': PhotoDictionaryEntry(
      ipa: '/ˈwɔː.tər/',
      definition: 'A colorless, transparent, odorless liquid that forms the seas, lakes, and rain.',
      example: 'It is important to drink plenty of water every day.',
      grammarTip: 'Noun. An uncountable noun; do not say "a water" unless referring to a bottle.',
    ),
    'apple': PhotoDictionaryEntry(
      ipa: '/ˈæp.əl/',
      definition: 'A round fruit with red or green skin and a whitish interior.',
      example: 'She ate a crisp green apple for a snack.',
      grammarTip: 'Noun. Starts with a vowel sound, so use "an": "an apple".',
    ),
    'food': PhotoDictionaryEntry(
      ipa: '/fuːd/',
      definition: 'Any nutritious substance that people or animals eat or drink.',
      example: 'The restaurant serves excellent Italian food.',
      grammarTip: 'Noun. Usually uncountable. "Foods" is used only for distinct types (e.g., "frozen foods").',
    ),

    // Common Objects
    'book': PhotoDictionaryEntry(
      ipa: '/bʊk/',
      definition: 'A written or printed work consisting of pages glued or sewn together.',
      example: 'She sat by the fire and read a fascinating book.',
      grammarTip: 'Noun. Can also be a verb meaning to reserve something: "to book a flight".',
    ),
    'pen': PhotoDictionaryEntry(
      ipa: '/pen/',
      definition: 'An instrument for writing or drawing with ink.',
      example: 'Could I borrow a pen to sign this document?',
      grammarTip: 'Noun. We say "write with a pen" or "write in pen".',
    ),
    'notebook': PhotoDictionaryEntry(
      ipa: '/ˈnəʊt.bʊk/',
      definition: 'A small book with blank or ruled pages for writing notes in.',
      example: 'He jotted down the idea in his spiral notebook.',
      grammarTip: 'Noun. Often used for school or journaling.',
    ),
    'glasses': PhotoDictionaryEntry(
      ipa: '/ˈɡlɑː.sɪz/',
      definition: 'A pair of lenses set in a frame resting on the nose and ears, used to correct vision.',
      example: 'He took off his glasses and rubbed his eyes.',
      grammarTip: 'Noun. Always plural. Use "a pair of glasses" to count them.',
    ),
    'watch': PhotoDictionaryEntry(
      ipa: '/wɒtʃ/',
      definition: 'A small timepiece worn typically on a strap on one\'s wrist.',
      example: 'She checked her watch and realized she was late.',
      grammarTip: 'Noun. Can also be a verb meaning to look at something: "to watch TV".',
    ),
    'shoe': PhotoDictionaryEntry(
      ipa: '/ʃuː/',
      definition: 'A covering for the foot, typically made of leather.',
      example: 'He tied his shoe before going for a run.',
      grammarTip: 'Noun. Almost always used in the plural form: "shoes".',
    ),
    'bag': PhotoDictionaryEntry(
      ipa: '/bæɡ/',
      definition: 'A flexible container with an opening at the top, used for carrying things.',
      example: 'She packed her bag the night before the trip.',
      grammarTip: 'Noun. Can refer to a purse, backpack, or shopping bag.',
    ),

    // People & Animals
    'person': PhotoDictionaryEntry(
      ipa: '/ˈpɜː.sən/',
      definition: 'A human being regarded as an individual.',
      example: 'There was only one other person in the waiting room.',
      grammarTip: 'Noun. The plural is usually "people", not "persons".',
    ),
    'man': PhotoDictionaryEntry(
      ipa: '/mæn/',
      definition: 'An adult male human being.',
      example: 'The man in the blue jacket asked for directions.',
      grammarTip: 'Noun. The plural is irregular: "men".',
    ),
    'woman': PhotoDictionaryEntry(
      ipa: '/ˈwʊm.ən/',
      definition: 'An adult female human being.',
      example: 'The woman smiled and waved from across the street.',
      grammarTip: 'Noun. The plural is irregular: "women".',
    ),
    'cat': PhotoDictionaryEntry(
      ipa: '/kæt/',
      definition: 'A small domesticated carnivorous mammal with soft fur.',
      example: 'The cat curled up on the rug and fell asleep.',
      grammarTip: 'Noun. Young cats are called "kittens".',
    ),
    'dog': PhotoDictionaryEntry(
      ipa: '/dɒɡ/',
      definition: 'A domesticated carnivorous mammal that typically has a long snout and acute sense of smell.',
      example: 'He took his dog for a long walk in the park.',
      grammarTip: 'Noun. Young dogs are called "puppies".',
    ),
    'bird': PhotoDictionaryEntry(
      ipa: '/bɜːd/',
      definition: 'A warm-blooded egg-laying vertebrate distinguished by the possession of feathers, wings, and a beak.',
      example: 'A small yellow bird landed on the window sill.',
      grammarTip: 'Noun. The collective noun for birds is a "flock".',
    ),
    
    // Vehicles
    'car': PhotoDictionaryEntry(
      ipa: '/kɑːr/',
      definition: 'A four-wheeled road vehicle that is powered by an engine and is able to carry a small number of people.',
      example: 'We rented a car to drive along the coast.',
      grammarTip: 'Noun. We say "get into a car" or "drive a car".',
    ),
    'bicycle': PhotoDictionaryEntry(
      ipa: '/ˈbaɪ.sɪ.kəl/',
      definition: 'A vehicle consisting of two wheels held in a frame one behind the other, propelled by pedals.',
      example: 'She rode her bicycle through the quiet neighborhood.',
      grammarTip: 'Noun. Often shortened to "bike". We say "ride a bicycle".',
    ),
  };

  /// Returns dictionary data if available, otherwise generates a smart fallback.
  static PhotoDictionaryEntry getEntry(String label) {
    final key = label.toLowerCase().trim();
    if (dictionary.containsKey(key)) {
      return dictionary[key]!;
    }
    
    // Smart fallback for unknown words
    final startsWithVowel = ['a', 'e', 'i', 'o', 'u'].contains(key[0]);
    final article = startsWithVowel ? 'an' : 'a';
    
    return PhotoDictionaryEntry(
      ipa: 'Noun',
      definition: 'An object identified in your environment.',
      example: 'I can see $article $key in this image.',
      grammarTip: startsWithVowel 
          ? 'Grammar: Use "an" before a vowel sound.'
          : 'Grammar: Use "a" before a consonant sound.',
    );
  }
}
