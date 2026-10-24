/// Represents an annotated vocabulary entry with IPA, CEFR level, definition, and grammar tip.
class PhotoDictionaryEntry {
  final String? ipa;
  final String? cefr;
  final String definition;
  final String example;
  final String grammarTip;

  const PhotoDictionaryEntry({
    required this.ipa,
    this.cefr,
    required this.definition,
    required this.example,
    this.grammarTip = 'Common everyday noun used in real-world contexts.',
  });
}

/// Static repository of everyday vocabulary entries recognized by image labeling.
class PhotoVocabularyDictionary {
  static const Map<String, PhotoDictionaryEntry> dictionary = {
    // ─── 1. Electronics & Tech ──────────────────────────────────────────
    'laptop': PhotoDictionaryEntry(
      ipa: '/ˈlæp.tɒp/',
      cefr: 'A2',
      definition: 'A portable computer small enough to use on your lap.',
      example: 'She typed the report on her new laptop.',
      grammarTip: 'Noun. Often paired with prepositions "on" or "with".',
    ),
    'computer': PhotoDictionaryEntry(
      ipa: '/kəmˈpjuː.tər/',
      cefr: 'A1',
      definition: 'An electronic device for storing and processing data.',
      example: 'The computer is rendering the video right now.',
      grammarTip:
          'Noun. Can be modified as "desktop computer" or "personal computer".',
    ),
    'mobile phone': PhotoDictionaryEntry(
      ipa: '/ˈməʊ.baɪl fəʊn/',
      cefr: 'A1',
      definition: 'A portable telephone that can make and receive calls.',
      example: 'Please put your mobile phone on silent during the movie.',
      grammarTip: 'Noun. In American English, often called a "cell phone".',
    ),
    'phone': PhotoDictionaryEntry(
      ipa: '/fəʊn/',
      cefr: 'A1',
      definition: 'A device used for transmitting voices over a distance.',
      example: 'His phone rang right in the middle of the meeting.',
      grammarTip:
          'Noun. Short for telephone. Can also be used as a verb: "I will phone him."',
    ),
    'keyboard': PhotoDictionaryEntry(
      ipa: '/ˈkiː.bɔːd/',
      cefr: 'A2',
      definition: 'A panel of keys that operate a computer or typewriter.',
      example: 'He bought a mechanical keyboard for faster typing.',
      grammarTip: 'Noun. The keys are pressed, so we say "type on a keyboard".',
    ),
    'mouse': PhotoDictionaryEntry(
      ipa: '/maʊs/',
      cefr: 'A1',
      definition: 'A small hand-held device used to control a computer screen.',
      example: 'Click the left button on your mouse to open the link.',
      grammarTip: 'Noun. Plural for the device is "mice" or "mouses".',
    ),
    'screen': PhotoDictionaryEntry(
      ipa: '/skriːn/',
      cefr: 'A2',
      definition:
          'The flat surface of a device where images and text are displayed.',
      example: 'Staring at a bright screen all day can hurt your eyes.',
      grammarTip:
          'Noun. Often used in compounds like "touchscreen" or "widescreen".',
    ),
    'television': PhotoDictionaryEntry(
      ipa: '/ˈtel.ɪ.vɪʒ.ən/',
      cefr: 'A1',
      definition:
          'An electronic device with a screen for watching broadcasts and shows.',
      example: 'The children watched an educational cartoon on the television.',
      grammarTip:
          'Noun. Often abbreviated as "TV". We say "watch television" without an article.',
    ),
    'tv': PhotoDictionaryEntry(
      ipa: '/ˌtiːˈviː/',
      cefr: 'A1',
      definition: 'Informal short form for television.',
      example: 'Turn off the TV when you finish watching.',
      grammarTip: 'Noun. Always capitalized as TV. Plural is TVs.',
    ),
    'headphones': PhotoDictionaryEntry(
      ipa: '/ˈhed.fəʊnz/',
      cefr: 'A2',
      definition:
          'A pair of speakers worn over or in the ears for listening to audio privately.',
      example: 'He plugged in his headphones to listen to English podcasts.',
      grammarTip: 'Noun. Plural. Count them using "a pair of headphones".',
    ),
    'charger': PhotoDictionaryEntry(
      ipa: '/ˈtʃɑː.dʒər/',
      cefr: 'A2',
      definition:
          'A device used for recharging batteries in electronic gadgets.',
      example: 'I forgot my phone charger at home.',
      grammarTip:
          'Noun. Countable. Use with prepositions: "plug into a charger".',
    ),

    // ─── 2. Furniture & Home ─────────────────────────────────────────────
    'desk': PhotoDictionaryEntry(
      ipa: '/desk/',
      cefr: 'A1',
      definition:
          'A piece of furniture with a flat surface, used for working or studying.',
      example: 'She organized the papers on her wooden desk.',
      grammarTip: 'Noun. We usually say "sit at a desk", not "sit on a desk".',
    ),
    'chair': PhotoDictionaryEntry(
      ipa: '/tʃeər/',
      cefr: 'A1',
      definition:
          'A separate seat for one person, typically with a back and four legs.',
      example: 'He pulled up a chair and joined the conversation.',
      grammarTip:
          'Noun. We say "sit in a chair" (with arms) or "sit on a chair" (without arms).',
    ),
    'table': PhotoDictionaryEntry(
      ipa: '/ˈteɪ.bəl/',
      cefr: 'A1',
      definition: 'A piece of furniture with a flat top and one or more legs.',
      example: 'They gathered around the dining table for dinner.',
      grammarTip: 'Noun. We say "sit at the table".',
    ),
    'couch': PhotoDictionaryEntry(
      ipa: '/kaʊtʃ/',
      cefr: 'A1',
      definition:
          'A long upholstered piece of furniture for several people to sit on.',
      example: 'We relaxed on the couch and watched a movie.',
      grammarTip: 'Noun. Synonymous with "sofa".',
    ),
    'sofa': PhotoDictionaryEntry(
      ipa: '/ˈsəʊ.fə/',
      cefr: 'A1',
      definition:
          'A comfortable seat with a back and arms for two or more people.',
      example: 'The cat curled up on the soft sofa cushion.',
      grammarTip: 'Noun. Countable. Plural is "sofas".',
    ),
    'cushion': PhotoDictionaryEntry(
      ipa: '/ˈkʊʃ.ən/',
      cefr: 'A2',
      definition:
          'A soft bag of cloth filled with feathers or foam, used on chairs or sofas.',
      example: 'She placed a decorative cushion behind her back for comfort.',
      grammarTip:
          'Noun. Countable. Distinct from "pillow", which is mainly for beds.',
    ),
    'bed': PhotoDictionaryEntry(
      ipa: '/bed/',
      cefr: 'A1',
      definition: 'A piece of furniture for sleep or rest.',
      example: 'I was so tired I went straight to bed.',
      grammarTip:
          'Noun. When referring to sleeping, we say "go to bed" (without "the").',
    ),
    'door': PhotoDictionaryEntry(
      ipa: '/dɔːr/',
      cefr: 'A1',
      definition:
          'A hinged, sliding, or revolving barrier at the entrance to a room or building.',
      example: 'Please close the door behind you.',
      grammarTip: 'Noun. We say "open/close the door" or "knock on the door".',
    ),
    'window': PhotoDictionaryEntry(
      ipa: '/ˈwɪn.dəʊ/',
      cefr: 'A1',
      definition:
          'An opening in a wall, fitted with glass to let in light and air.',
      example: 'She looked out the window at the falling snow.',
      grammarTip:
          'Noun. We say "look out the window" or "look through the window".',
    ),
    'mirror': PhotoDictionaryEntry(
      ipa: '/ˈmɪr.ər/',
      cefr: 'A1',
      definition:
          'A reflective surface made of glass that shows an image of whatever is before it.',
      example: 'He adjusted his tie while looking in the bathroom mirror.',
      grammarTip:
          'Noun. We say "look in the mirror", not "look at the mirror".',
    ),
    'lamp': PhotoDictionaryEntry(
      ipa: '/læmp/',
      cefr: 'A1',
      definition:
          'A device for providing artificial light from an electrical bulb or flame.',
      example: 'She switched on the desk lamp to read her book.',
      grammarTip:
          'Noun. We say "turn on/off the lamp" or "switch on the lamp".',
    ),
    'clock': PhotoDictionaryEntry(
      ipa: '/klɒk/',
      cefr: 'A1',
      definition:
          'An instrument to measure and indicate time, typically on a wall or shelf.',
      example: 'The wall clock ticked quietly in the library.',
      grammarTip:
          'Noun. Clocks stay on walls or surfaces, while "watches" are worn on wrists.',
    ),
    'calendar': PhotoDictionaryEntry(
      ipa: '/ˈkæl.ɪn.dər/',
      cefr: 'A2',
      definition:
          'A chart or series of pages showing the days, weeks, and months of a year.',
      example: 'I marked the exam date on my wall calendar.',
      grammarTip: 'Noun. Spelled with "ar" at the end, not "er".',
    ),
    'picture frame': PhotoDictionaryEntry(
      ipa: '/ˈpɪk.tʃər freɪm/',
      cefr: 'A2',
      definition:
          'A border or rim made of wood or metal designed to hold and protect a picture.',
      example: 'She framed a family portrait in a silver picture frame.',
      grammarTip: 'Noun. Compound noun. Plural is "picture frames".',
    ),
    'vase': PhotoDictionaryEntry(
      ipa: '/vɑːz/',
      cefr: 'A2',
      definition:
          'A decorative container, usually made of glass or ceramic, for holding cut flowers.',
      example: 'He placed fresh flowers in a ceramic vase on the dining table.',
      grammarTip: 'Noun. Countable. Can hold water: "a vase of flowers".',
    ),

    // ─── 3. Plants & Nature ──────────────────────────────────────────────
    'plant': PhotoDictionaryEntry(
      ipa: '/plɑːnt/',
      cefr: 'A1',
      definition: 'A living organism, such as trees, shrubs, herbs, and ferns.',
      example: 'Don\'t forget to water the plant while I am away.',
      grammarTip: 'Noun. Can also be a verb: "to plant a seed".',
    ),
    'houseplant': PhotoDictionaryEntry(
      ipa: '/ˈhaʊs.plɑːnt/',
      cefr: 'A2',
      definition: 'A plant grown indoors for decoration in homes or offices.',
      example: 'This sunny windowsill is ideal for a leafy houseplant.',
      grammarTip: 'Noun. Compound noun formed from "house" and "plant".',
    ),
    'tree': PhotoDictionaryEntry(
      ipa: '/triː/',
      cefr: 'A1',
      definition:
          'A tall perennial plant with a woody trunk, branches, and leaves.',
      example: 'The birds built a nest high up in the oak tree.',
      grammarTip: 'Noun. Prepositions: "birds in a tree", "sit under a tree".',
    ),
    'flower': PhotoDictionaryEntry(
      ipa: '/flaʊ.ər/',
      cefr: 'A1',
      definition:
          'The seed-bearing part of a plant, consisting of reproductive organs and colorful petals.',
      example: 'She picked a bright yellow flower from the garden.',
      grammarTip:
          'Noun. Countable: "a bunch of flowers" or "a bouquet of flowers".',
    ),

    // ─── 4. Food, Drink & Kitchenware ────────────────────────────────────
    'coffee': PhotoDictionaryEntry(
      ipa: '/ˈkɒf.i/',
      cefr: 'A1',
      definition:
          'A hot drink made from the roasted and ground seeds of a tropical shrub.',
      example: 'I need a cup of hot coffee to wake up this morning.',
      grammarTip:
          'Noun. Uncountable in general ("I love coffee"), countable when ordering ("Two coffees, please").',
    ),
    'cup': PhotoDictionaryEntry(
      ipa: '/kʌp/',
      cefr: 'A1',
      definition:
          'A small, bowl-shaped container for drinking from, typically having a handle.',
      example: 'She poured the tea into a porcelain cup.',
      grammarTip: 'Noun. Often used as a unit of measurement in recipes.',
    ),
    'coffee cup': PhotoDictionaryEntry(
      ipa: '/ˈkɒf.i kʌp/',
      cefr: 'A1',
      definition: 'A cup designed specifically for serving hot coffee.',
      example: 'He set his ceramic coffee cup down on the saucer.',
      grammarTip: 'Noun. Compound noun. Plural is "coffee cups".',
    ),
    'mug': PhotoDictionaryEntry(
      ipa: '/mʌɡ/',
      cefr: 'A1',
      definition:
          'A large cup, typically cylindrical with a handle and used without a saucer.',
      example: 'He drank hot chocolate from his favorite winter mug.',
      grammarTip: 'Noun. Usually used for hot drinks in informal settings.',
    ),
    'bottle': PhotoDictionaryEntry(
      ipa: '/ˈbɒt.əl/',
      cefr: 'A1',
      definition:
          'A glass or plastic container with a narrow neck, used for storing drinks.',
      example: 'He brought a bottle of water to the gym.',
      grammarTip:
          'Noun. Commonly used with the preposition "of" (e.g., bottle of water).',
    ),
    'water': PhotoDictionaryEntry(
      ipa: '/ˈwɔː.tər/',
      cefr: 'A1',
      definition:
          'A colorless, transparent liquid that forms seas, lakes, and rain.',
      example: 'It is important to drink plenty of water every day.',
      grammarTip:
          'Noun. Uncountable noun; do not say "a water" unless referring to a bottle.',
    ),
    'apple': PhotoDictionaryEntry(
      ipa: '/ˈæp.əl/',
      cefr: 'A1',
      definition:
          'A round fruit with red, yellow, or green skin and firm white flesh.',
      example: 'She ate a crisp green apple for an afternoon snack.',
      grammarTip: 'Noun. Starts with a vowel sound, so use "an": "an apple".',
    ),
    'banana': PhotoDictionaryEntry(
      ipa: '/bəˈnɑː.nə/',
      cefr: 'A1',
      definition:
          'A long curved fruit with a yellow skin and soft sweet flesh.',
      example: 'He peeled a ripe banana and put slices on his cereal.',
      grammarTip: 'Noun. Countable. A group is called "a bunch of bananas".',
    ),
    'orange': PhotoDictionaryEntry(
      ipa: '/ˈɒr.ɪndʒ/',
      cefr: 'A1',
      definition:
          'A round citrus fruit with a tough bright reddish-yellow rind.',
      example: 'She squeezed fresh orange juice for breakfast.',
      grammarTip:
          'Noun. Starts with a vowel sound: "an orange". Also an adjective for color.',
    ),
    'bread': PhotoDictionaryEntry(
      ipa: '/bred/',
      cefr: 'A1',
      definition:
          'A staple food made of flour, water, and yeast baked in an oven.',
      example: 'The baker took warm loaves of fresh bread out of the oven.',
      grammarTip:
          'Noun. Uncountable. Count it using "a loaf of bread" or "a slice of bread".',
    ),
    'food': PhotoDictionaryEntry(
      ipa: '/fuːd/',
      cefr: 'A1',
      definition:
          'Any nutritious substance that people or animals eat or drink.',
      example: 'The restaurant serves excellent Italian food.',
      grammarTip:
          'Noun. Usually uncountable. "Foods" is used only for distinct categories.',
    ),
    'spoon': PhotoDictionaryEntry(
      ipa: '/spuːn/',
      cefr: 'A1',
      definition:
          'An implement consisting of a small shallow bowl on a handle, used for eating or stirring.',
      example: 'He stirred sugar into his tea with a small spoon.',
      grammarTip: 'Noun. Countable. Preposition: "eat with a spoon".',
    ),
    'fork': PhotoDictionaryEntry(
      ipa: '/fɔːk/',
      cefr: 'A1',
      definition:
          'A piece of cutlery with two or more prongs used for picking up food.',
      example: 'Hold your knife in your right hand and your fork in your left.',
      grammarTip: 'Noun. Countable. Pair with knife: "knife and fork".',
    ),
    'knife': PhotoDictionaryEntry(
      ipa: '/naɪf/',
      cefr: 'A1',
      definition:
          'A cutting instrument with a sharp blade fastened to a handle.',
      example: 'Use a butter knife to spread jam on your toast.',
      grammarTip:
          'Noun. Irregular plural: one knife, two "knives". The initial "k" is silent.',
    ),
    'plate': PhotoDictionaryEntry(
      ipa: '/pleɪt/',
      cefr: 'A1',
      definition:
          'A flat dish, typically circular, from which food is eaten or served.',
      example: 'She placed a warm sandwich on the ceramic plate.',
      grammarTip: 'Noun. Countable. Preposition: "food on a plate".',
    ),
    'bowl': PhotoDictionaryEntry(
      ipa: '/bəʊl/',
      cefr: 'A1',
      definition:
          'A round, deep dish used especially for food or liquid like soup or cereal.',
      example: 'He ate a warm bowl of vegetable soup for lunch.',
      grammarTip:
          'Noun. Preposition: "food in a bowl". Unit: "a bowl of soup".',
    ),
    'pan': PhotoDictionaryEntry(
      ipa: '/pæn/',
      cefr: 'A2',
      definition:
          'A metal container used for cooking food, especially on a stove.',
      example: 'Heat olive oil in the frying pan before adding garlic.',
      grammarTip: 'Noun. Often called "frying pan" or "skillet".',
    ),
    'pot': PhotoDictionaryEntry(
      ipa: '/pɒt/',
      cefr: 'A1',
      definition:
          'A deep round container used for cooking stews, soups, or boiling water.',
      example: 'The chef stirred the pasta in a large stainless steel pot.',
      grammarTip: 'Noun. Deeper than a pan. Can also mean "flowerpot".',
    ),
    'oven': PhotoDictionaryEntry(
      ipa: '/ˈʌv.ən/',
      cefr: 'A2',
      definition: 'An enclosed compartment used for baking and roasting food.',
      example: 'Bake the pizza in the oven at two hundred degrees.',
      grammarTip:
          'Noun. Starts with a vowel sound: "an oven". Preposition: "bake in an oven".',
    ),
    'refrigerator': PhotoDictionaryEntry(
      ipa: '/rɪˈfrɪdʒ.ər.eɪ.tər/',
      cefr: 'A2',
      definition: 'An appliance that keeps food and drinks cool and fresh.',
      example: 'Keep the milk cold inside the refrigerator.',
      grammarTip: 'Noun. Often shortened to "fridge" in everyday English.',
    ),
    'fridge': PhotoDictionaryEntry(
      ipa: '/frɪdʒ/',
      cefr: 'A2',
      definition: 'A common informal word for refrigerator.',
      example: 'Is there any orange juice left in the fridge?',
      grammarTip:
          'Noun. Notice the "d" in fridge, which is absent in refrigerator.',
    ),
    'microwave': PhotoDictionaryEntry(
      ipa: '/ˈmaɪ.krə.weɪv/',
      cefr: 'A2',
      definition:
          'An appliance that cooks or reheats food quickly using electromagnetic radiation.',
      example: 'You can reheat your soup in the microwave for two minutes.',
      grammarTip:
          'Noun. Can also be a verb: "microwave the food for one minute".',
    ),
    'toaster': PhotoDictionaryEntry(
      ipa: '/ˈtəʊ.stər/',
      cefr: 'B1',
      definition: 'An electrical appliance for toasting bread slices.',
      example: 'Two golden slices of toast popped out of the toaster.',
      grammarTip: 'Noun. Countable. Derived from the verb "toast".',
    ),
    'blender': PhotoDictionaryEntry(
      ipa: '/ˈblen.dər/',
      cefr: 'B1',
      definition:
          'An electric kitchen machine with sharp blades for pureeing or mixing liquids.',
      example: 'She blended strawberries and yogurt into a fruit smoothie.',
      grammarTip: 'Noun. Countable. Derived from the verb "blend".',
    ),

    // ─── 5. Personal Items & Bathroom ────────────────────────────────────
    'backpack': PhotoDictionaryEntry(
      ipa: '/ˈbæk.pæk/',
      cefr: 'A1',
      definition: 'A bag carried on the back, with two shoulder straps.',
      example: 'He packed his textbooks and water bottle into his backpack.',
      grammarTip:
          'Noun. Compound noun from "back" and "pack". Also called a "rucksack".',
    ),
    'bag': PhotoDictionaryEntry(
      ipa: '/bæɡ/',
      cefr: 'A1',
      definition:
          'A flexible container with an opening at the top, used for carrying things.',
      example: 'She packed her bag the night before the trip.',
      grammarTip: 'Noun. Can refer to a purse, backpack, or shopping bag.',
    ),
    'wallet': PhotoDictionaryEntry(
      ipa: '/ˈwɒl.ɪt/',
      cefr: 'A2',
      definition:
          'A pocket-sized, flat folding case for holding money and cards.',
      example:
          'He kept his identification card safely inside his leather wallet.',
      grammarTip: 'Noun. Countable. Preposition: "keep money in a wallet".',
    ),
    'keys': PhotoDictionaryEntry(
      ipa: '/kiːz/',
      cefr: 'A1',
      definition:
          'Small pieces of metal shaped to open locks, doors, or start vehicles.',
      example: 'Don\'t forget your house keys on the kitchen counter.',
      grammarTip:
          'Noun. Plural. A collection is called "a bunch of keys" or "a set of keys".',
    ),
    'watch': PhotoDictionaryEntry(
      ipa: '/wɒtʃ/',
      cefr: 'A1',
      definition:
          'A small timepiece worn typically on a strap on one\'s wrist.',
      example: 'She checked her watch and realized she was late.',
      grammarTip:
          'Noun. Can also be a verb meaning to observe: "to watch a movie".',
    ),
    'glasses': PhotoDictionaryEntry(
      ipa: '/ˈɡlɑː.sɪz/',
      cefr: 'A1',
      definition:
          'A pair of lenses set in a frame resting on the nose and ears, used to correct vision.',
      example: 'He took off his reading glasses and wiped the lenses.',
      grammarTip: 'Noun. Always plural. Use "a pair of glasses" to count them.',
    ),
    'shoe': PhotoDictionaryEntry(
      ipa: '/ʃuː/',
      cefr: 'A1',
      definition:
          'A covering for the foot, typically made of leather, rubber, or cloth.',
      example: 'He tied his running shoe before going for a jog.',
      grammarTip:
          'Noun. Usually counted as "a pair of shoes". Plural is "shoes".',
    ),
    'shoes': PhotoDictionaryEntry(
      ipa: '/ʃuːz/',
      cefr: 'A1',
      definition: 'Footwear worn to protect and comfort the human foot.',
      example: 'Please take off your shoes before entering the house.',
      grammarTip: 'Noun. Plural of shoe. Counted with "pairs of shoes".',
    ),
    'toothbrush': PhotoDictionaryEntry(
      ipa: '/ˈtuːθ.brʌʃ/',
      cefr: 'A1',
      definition: 'A small brush with a long handle used for cleaning teeth.',
      example:
          'Dentists recommend replacing your toothbrush every three months.',
      grammarTip:
          'Noun. Compound noun: singular "tooth" + "brush", even though you brush multiple teeth.',
    ),
    'towel': PhotoDictionaryEntry(
      ipa: '/taʊ.əl/',
      cefr: 'A1',
      definition:
          'A piece of thick absorbent cloth used for drying the body or surfaces.',
      example:
          'Dry your hands with the clean cotton towel hanging by the sink.',
      grammarTip: 'Noun. Countable: "bath towel", "hand towel", "beach towel".',
    ),
    'soap': PhotoDictionaryEntry(
      ipa: '/səʊp/',
      cefr: 'A1',
      definition:
          'A substance used with water for washing and cleaning the body.',
      example: 'Always wash your hands thoroughly with soap and warm water.',
      grammarTip: 'Noun. Uncountable in general. Count it as "a bar of soap".',
    ),
    'shampoo': PhotoDictionaryEntry(
      ipa: '/ʃæmˈpuː/',
      cefr: 'A2',
      definition: 'A liquid cosmetic preparation for washing the hair.',
      example: 'Lather the shampoo into your hair and rinse thoroughly.',
      grammarTip:
          'Noun. Uncountable liquid. Count it as "a bottle of shampoo". Can also be a verb.',
    ),
    'comb': PhotoDictionaryEntry(
      ipa: '/kəʊm/',
      cefr: 'A1',
      definition:
          'A strip of plastic or wood with a row of teeth, used for untangling hair.',
      example: 'She ran a fine-toothed comb through her long hair.',
      grammarTip:
          'Noun. Silent "b" at the end. Can also be a verb: "comb your hair".',
    ),

    // ─── 6. Stationery & Tools ───────────────────────────────────────────
    'pen': PhotoDictionaryEntry(
      ipa: '/pen/',
      cefr: 'A1',
      definition: 'An instrument for writing or drawing with liquid ink.',
      example: 'Could I borrow a blue pen to sign this form?',
      grammarTip: 'Noun. We say "write with a pen" or "write in pen".',
    ),
    'notebook': PhotoDictionaryEntry(
      ipa: '/ˈnəʊt.bʊk/',
      cefr: 'A1',
      definition:
          'A book with blank or ruled pages for writing notes, lists, or journaling.',
      example: 'He jotted down new English vocabulary words in his notebook.',
      grammarTip: 'Noun. Compound noun formed from "note" and "book".',
    ),
    'book': PhotoDictionaryEntry(
      ipa: '/bʊk/',
      cefr: 'A1',
      definition:
          'A written or printed work consisting of pages bound together.',
      example: 'She sat by the window and read an inspiring book.',
      grammarTip:
          'Noun. Can also be a verb meaning to reserve: "to book a ticket".',
    ),
    'scissors': PhotoDictionaryEntry(
      ipa: '/ˈsɪz.əz/',
      cefr: 'A2',
      definition:
          'An instrument used for cutting paper, cloth, or hair, having two pivoted blades.',
      example: 'Use blunt-ended safety scissors to cut out the paper shapes.',
      grammarTip: 'Noun. Always plural. Count with "a pair of scissors".',
    ),
    'tape': PhotoDictionaryEntry(
      ipa: '/teɪp/',
      cefr: 'A2',
      definition:
          'A narrow strip of material with an adhesive backing used for fastening things.',
      example: 'She sealed the cardboard box with clear packing tape.',
      grammarTip:
          'Noun. Uncountable. Count as "a roll of tape" or "a piece of tape".',
    ),
    'stapler': PhotoDictionaryEntry(
      ipa: '/ˈsteɪ.plər/',
      cefr: 'B1',
      definition:
          'A mechanical device that joins sheets of paper together with wire staples.',
      example: 'Fasten the report pages together with the desk stapler.',
      grammarTip: 'Noun. The small metal fasteners are called "staples".',
    ),

    // ─── 7. Vehicles & Transportation ────────────────────────────────────
    'car': PhotoDictionaryEntry(
      ipa: '/kɑːr/',
      cefr: 'A1',
      definition:
          'A four-wheeled motor vehicle used for passenger transportation.',
      example: 'We parked our car in the designated space outside the store.',
      grammarTip:
          'Noun. We say "get into a car", "get out of a car", or "drive a car".',
    ),
    'bicycle': PhotoDictionaryEntry(
      ipa: '/ˈbaɪ.sɪ.kəl/',
      cefr: 'A1',
      definition:
          'A human-powered vehicle consisting of two wheels attached to a frame.',
      example:
          'She rides her bicycle to school every morning along the bike lane.',
      grammarTip: 'Noun. Often shortened to "bike". We say "ride a bicycle".',
    ),
    'bike': PhotoDictionaryEntry(
      ipa: '/baɪk/',
      cefr: 'A1',
      definition: 'A common informal word for a bicycle or motorcycle.',
      example: 'He locked his bike to the metal bike rack.',
      grammarTip: 'Noun. Preposition: "ride on a bike" or "travel by bike".',
    ),

    // ─── 8. Animals & People ─────────────────────────────────────────────
    'dog': PhotoDictionaryEntry(
      ipa: '/dɒɡ/',
      cefr: 'A1',
      definition:
          'A domesticated carnivorous mammal known for loyalty and keen senses.',
      example: 'He taught his dog to sit and give a paw.',
      grammarTip: 'Noun. Young dogs are called "puppies". Sound: dogs "bark".',
    ),
    'cat': PhotoDictionaryEntry(
      ipa: '/kæt/',
      cefr: 'A1',
      definition: 'A small domesticated feline animal kept as a beloved pet.',
      example: 'The cat purred softly while resting in the warm sunlight.',
      grammarTip:
          'Noun. Young cats are called "kittens". Sound: cats "meow" or "purr".',
    ),
    'bird': PhotoDictionaryEntry(
      ipa: '/bɜːd/',
      cefr: 'A1',
      definition:
          'A warm-blooded egg-laying animal with feathers, wings, and a beak.',
      example: 'A colorful songbird perched on the tree branch.',
      grammarTip: 'Noun. The collective noun for birds is a "flock of birds".',
    ),
    'person': PhotoDictionaryEntry(
      ipa: '/ˈpɜː.sən/',
      cefr: 'A1',
      definition: 'A human being regarded as an individual.',
      example: 'There was only one other person in the waiting room.',
      grammarTip: 'Noun. The standard plural is "people", not "persons".',
    ),
    'man': PhotoDictionaryEntry(
      ipa: '/mæn/',
      cefr: 'A1',
      definition: 'An adult male human being.',
      example: 'The man greeted his neighbor with a friendly smile.',
      grammarTip: 'Noun. Irregular plural: one man, two "men".',
    ),
    'woman': PhotoDictionaryEntry(
      ipa: '/ˈwʊm.ən/',
      cefr: 'A1',
      definition: 'An adult female human being.',
      example: 'The woman led the science workshop with great enthusiasm.',
      grammarTip:
          'Noun. Irregular plural: one woman, two "women" (pronounced /ˈwɪm.ɪn/).',
    ),
    // ─── Curriculum Expansion · 1. Bedroom & Furniture ────────────────────────────
    'pillow': PhotoDictionaryEntry(
      ipa: '/ˈpɪl.oʊ/',
      cefr: 'A1',
      definition: 'A soft cushion used to rest your head when sleeping.',
      example: 'He rested his head on the soft pillow.',
      grammarTip: 'Countable noun. Plural: pillows.',
    ),
    'blanket': PhotoDictionaryEntry(
      ipa: '/ˈblæŋ.kɪt/',
      cefr: 'A1',
      definition: 'A large piece of warm cloth used as a bed covering.',
      example: 'She pulled the warm blanket over her bed.',
      grammarTip:
          'Countable noun. Pair with preposition "under": "under the blanket".',
    ),
    'wardrobe': PhotoDictionaryEntry(
      ipa: '/ˈwɔːr.droʊb/',
      cefr: 'A2',
      definition: 'A tall cupboard where you hang or keep your clothes.',
      example: 'She hung her dress in the wardrobe.',
      grammarTip: 'Countable noun. Americans often say "closet" instead.',
    ),
    'nightstand': PhotoDictionaryEntry(
      ipa: '/ˈnaɪt.stænd/',
      cefr: 'B1',
      definition: 'A small table that stands next to a bed.',
      example: 'He put his glasses on the nightstand.',
      grammarTip: 'Countable noun. British English: "bedside table".',
    ),
    'drawer': PhotoDictionaryEntry(
      ipa: '/drɔːr/',
      cefr: 'A2',
      definition: 'A sliding box built into furniture for keeping things.',
      example: 'The socks are in the top drawer.',
      grammarTip: 'Countable noun. Use "in the drawer" or "open the drawer".',
    ),
    'alarm clock': PhotoDictionaryEntry(
      ipa: '/əˈlɑːrm klɑːk/',
      cefr: 'A2',
      definition: 'A clock that makes a sound to wake you up at a set time.',
      example: 'My alarm clock rings at seven every morning.',
      grammarTip: 'Compound noun. Say "set an alarm" or "the alarm goes off".',
    ),

    // ─── Curriculum Expansion · 2. Kitchen & Utensils ─────────────────────────────
    'kettle': PhotoDictionaryEntry(
      ipa: '/ˈket.əl/',
      cefr: 'A2',
      definition: 'A container with a spout and handle for boiling water.',
      example: 'She filled the kettle and made tea.',
      grammarTip:
          'Countable noun. Say "put the kettle on" to start boiling water.',
    ),
    'spatula': PhotoDictionaryEntry(
      ipa: '/ˈspætʃ.ə.lə/',
      cefr: 'A2',
      definition:
          'A flat kitchen tool with a handle for turning or lifting food.',
      example: 'He flipped the pancake with a spatula.',
      grammarTip: 'Countable noun. Stress the first syllable: SPA-chuh-luh.',
    ),
    'ladle': PhotoDictionaryEntry(
      ipa: '/ˈleɪ.dəl/',
      cefr: 'B1',
      definition: 'A large, deep spoon used for serving soup.',
      example: 'She served the hot soup with a ladle.',
      grammarTip: 'Countable noun. Used for liquids such as soup and sauce.',
    ),
    'chopsticks': PhotoDictionaryEntry(
      ipa: '/ˈtʃɑːp.stɪks/',
      cefr: 'A2',
      definition: 'A pair of thin sticks used for eating food.',
      example: 'He picked up the noodles with chopsticks.',
      grammarTip: 'Plural noun, used in pairs. Say "a pair of chopsticks".',
    ),
    'cutting board': PhotoDictionaryEntry(
      ipa: '/ˈkʌt̬.ɪŋ bɔːrd/',
      cefr: 'B1',
      definition: 'A flat board you use to cut food on.',
      example: 'Chop the onions on the cutting board.',
      grammarTip: 'Compound noun. British English also says "chopping board".',
    ),
    'teapot': PhotoDictionaryEntry(
      ipa: '/ˈtiː.pɑːt/',
      cefr: 'A2',
      definition: 'A pot with a spout and handle for making and pouring tea.',
      example: 'Grandma poured tea from the teapot.',
      grammarTip: 'Compound noun (tea + pot), written as one word.',
    ),
    'lunch box': PhotoDictionaryEntry(
      ipa: '/ˈlʌntʃ ˌbɑːks/',
      cefr: 'A2',
      definition: 'A small container for carrying food to school or work.',
      example: 'I packed a sandwich in my lunch box.',
      grammarTip: 'Compound noun. Also written "lunchbox".',
    ),
    'glass': PhotoDictionaryEntry(
      ipa: '/ɡlæs/',
      cefr: 'A1',
      definition: 'A clear cup made of glass for drinking.',
      example: 'He drank a glass of cold water.',
      grammarTip:
          '"A glass" is a cup; "glass" is also the material. "Glasses" (plural) are for your eyes.',
    ),
    'colander': PhotoDictionaryEntry(
      ipa: '/ˈkɑː.lən.dɚ/',
      cefr: 'B1',
      definition: 'A bowl with small holes used for draining water from food.',
      example: 'Pour the pasta into the colander.',
      grammarTip: 'Countable noun. Also called a "strainer".',
    ),

    // ─── Curriculum Expansion · 3. Fruits, Vegetables & Food ──────────────────────
    'tomato': PhotoDictionaryEntry(
      ipa: '/təˈmeɪ.toʊ/',
      cefr: 'A1',
      definition: 'A soft, round, red fruit that is eaten as a vegetable.',
      example: 'She sliced a tomato for the salad.',
      grammarTip: 'Countable noun. Plural adds -es: tomatoes.',
    ),
    'carrot': PhotoDictionaryEntry(
      ipa: '/ˈker.ət/',
      cefr: 'A1',
      definition: 'A long orange vegetable that grows under the ground.',
      example: 'Rabbits love to eat carrots.',
      grammarTip: 'Countable noun. Plural: carrots.',
    ),
    'potato': PhotoDictionaryEntry(
      ipa: '/pəˈteɪ.toʊ/',
      cefr: 'A1',
      definition:
          'A round vegetable with brown skin that grows under the ground.',
      example: 'He baked a potato for dinner.',
      grammarTip: 'Countable noun. Plural adds -es: potatoes.',
    ),
    'egg': PhotoDictionaryEntry(
      ipa: '/eɡ/',
      cefr: 'A1',
      definition: 'An oval food with a shell, laid by a hen.',
      example: 'I had a boiled egg for breakfast.',
      grammarTip: 'Countable noun. Use "an" before it: "an egg".',
    ),
    'strawberry': PhotoDictionaryEntry(
      ipa: '/ˈstrɔː.ber.i/',
      cefr: 'A1',
      definition: 'A small, sweet, red fruit with tiny seeds on its skin.',
      example: 'The strawberry jam tastes delicious.',
      grammarTip: 'Countable noun. Plural: change -y to -ies: strawberries.',
    ),
    'grapes': PhotoDictionaryEntry(
      ipa: '/ɡreɪps/',
      cefr: 'A1',
      definition:
          'Small round fruits that grow in bunches and can be green or purple.',
      example: 'She ate a handful of sweet grapes.',
      grammarTip:
          'Usually plural. Say "a bunch of grapes"; one fruit is "a grape".',
    ),
    'lemon': PhotoDictionaryEntry(
      ipa: '/ˈlem.ən/',
      cefr: 'A1',
      definition: 'A yellow citrus fruit with a sour taste.',
      example: 'Squeeze some lemon into your tea.',
      grammarTip:
          'Countable noun. Can also describe other nouns: "lemon juice".',
    ),
    'pizza': PhotoDictionaryEntry(
      ipa: '/ˈpiːt.sə/',
      cefr: 'A1',
      definition: 'A flat round bread baked with cheese and other toppings.',
      example: 'We ordered a large pizza for dinner.',
      grammarTip: 'Countable noun. Say "a slice of pizza" for one piece.',
    ),
    'sandwich': PhotoDictionaryEntry(
      ipa: '/ˈsæn.wɪtʃ/',
      cefr: 'A1',
      definition: 'Two slices of bread with food in between.',
      example: 'He made a cheese sandwich for lunch.',
      grammarTip: 'Countable noun. Plural adds -es: sandwiches.',
    ),
    'cookie': PhotoDictionaryEntry(
      ipa: '/ˈkʊk.i/',
      cefr: 'A1',
      definition: 'A small, flat, sweet baked treat.',
      example: 'She dunked her cookie in milk.',
      grammarTip: 'Countable noun. British English often says "biscuit".',
    ),
    'cake': PhotoDictionaryEntry(
      ipa: '/keɪk/',
      cefr: 'A1',
      definition: 'A sweet baked food, often made for birthdays.',
      example: 'We cut the birthday cake together.',
      grammarTip:
          'Countable and uncountable. Say "a piece of cake" or "a slice of cake".',
    ),
    'hamburger': PhotoDictionaryEntry(
      ipa: '/ˈhæm.bɝː.ɡɚ/',
      cefr: 'A1',
      definition: 'A sandwich with a cooked beef patty in a round bun.',
      example: 'He ordered a hamburger and fries.',
      grammarTip: 'Countable noun. Often shortened to "burger".',
    ),
    'ice cream': PhotoDictionaryEntry(
      ipa: '/ˌaɪs ˈkriːm/',
      cefr: 'A1',
      definition: 'A frozen sweet food made from milk or cream.',
      example: 'The children shared a cone of ice cream.',
      grammarTip: 'Uncountable noun. Say "a scoop of ice cream".',
    ),
    'watermelon': PhotoDictionaryEntry(
      ipa: '/ˈwɑː.t̬ɚˌmel.ən/',
      cefr: 'A1',
      definition: 'A very large green fruit that is red and juicy inside.',
      example: 'We ate cold watermelon on a hot day.',
      grammarTip: 'Compound noun (water + melon). Say "a slice of watermelon".',
    ),
    'pineapple': PhotoDictionaryEntry(
      ipa: '/ˈpaɪnˌæp.əl/',
      cefr: 'A1',
      definition:
          'A large tropical fruit with spiky skin and sweet yellow flesh.',
      example: 'She cut the pineapple into small pieces.',
      grammarTip: 'Compound noun (pine + apple). Countable.',
    ),
    'mango': PhotoDictionaryEntry(
      ipa: '/ˈmæŋ.ɡoʊ/',
      cefr: 'A1',
      definition: 'A sweet, juicy tropical fruit with a large seed.',
      example: 'The mango was ripe and delicious.',
      grammarTip: 'Countable noun. Plural: mangoes or mangos.',
    ),
    'cucumber': PhotoDictionaryEntry(
      ipa: '/ˈkjuː.kʌm.bɚ/',
      cefr: 'A2',
      definition: 'A long green vegetable that is often eaten raw in salads.',
      example: 'She added cucumber to the salad.',
      grammarTip: 'Countable noun. Stress the first syllable: CU-cum-ber.',
    ),
    'broccoli': PhotoDictionaryEntry(
      ipa: '/ˈbrɑː.kəl.i/',
      cefr: 'A2',
      definition: 'A green vegetable that looks like a small tree.',
      example: 'The kids ate steamed broccoli with rice.',
      grammarTip: 'Uncountable noun. Do not say "broccolis".',
    ),
    'corn': PhotoDictionaryEntry(
      ipa: '/kɔːrn/',
      cefr: 'A2',
      definition: 'A tall plant with yellow seeds that are eaten as food.',
      example: 'We grilled fresh corn on the cob.',
      grammarTip: 'Uncountable noun. Say "an ear of corn" for one piece.',
    ),
    'donut': PhotoDictionaryEntry(
      ipa: '/ˈdoʊ.nʌt/',
      cefr: 'A2',
      definition:
          'A sweet, round, fried cake, often with a hole in the middle.',
      example: 'He bought a chocolate donut at the bakery.',
      grammarTip: 'Countable noun. Also spelled "doughnut".',
    ),
    'bell pepper': PhotoDictionaryEntry(
      ipa: '/ˈbel ˌpep.ɚ/',
      cefr: 'B1',
      definition:
          'A hollow, crunchy vegetable that can be red, green, or yellow.',
      example: 'She chopped a red bell pepper for the stir-fry.',
      grammarTip:
          'Compound noun. Not the same as black pepper, which is a spice.',
    ),
    'avocado': PhotoDictionaryEntry(
      ipa: '/ˌɑː.vəˈkɑː.doʊ/',
      cefr: 'B1',
      definition: 'A green fruit with soft, creamy flesh and a big seed.',
      example: 'He mashed an avocado and spread it on toast.',
      grammarTip: 'Countable noun. Plural: avocados (or avocadoes).',
    ),
    'pear': PhotoDictionaryEntry(
      ipa: '/per/',
      cefr: 'A1',
      definition:
          'A sweet fruit that is round at the bottom and narrow at the top.',
      example: 'She ate a juicy pear after lunch.',
      grammarTip: 'Countable noun. Sounds the same as "pair" and "pare".',
    ),
    'cheese': PhotoDictionaryEntry(
      ipa: '/tʃiːz/',
      cefr: 'A1',
      definition: 'A solid food made from milk.',
      example: 'I put cheese on my sandwich.',
      grammarTip:
          'Uncountable noun. Say "a slice of cheese" or "a piece of cheese".',
    ),
    'candy': PhotoDictionaryEntry(
      ipa: '/ˈkæn.di/',
      cefr: 'A1',
      definition: 'A small sweet food made from sugar.',
      example: 'The children shared the candy.',
      grammarTip:
          'Uncountable in American English. British English says "sweets".',
    ),

    // ─── Curriculum Expansion · 4. Study, Classroom & Stationery ──────────────────
    'pencil': PhotoDictionaryEntry(
      ipa: '/ˈpen.səl/',
      cefr: 'A1',
      definition:
          'A thin wooden tool with a dark center used for writing or drawing.',
      example: 'Write your name with a pencil.',
      grammarTip: 'Countable noun. Use "with a pencil".',
    ),
    'ruler': PhotoDictionaryEntry(
      ipa: '/ˈruː.lɚ/',
      cefr: 'A1',
      definition:
          'A flat, straight tool used to measure length and draw lines.',
      example: 'Use a ruler to draw a straight line.',
      grammarTip: 'Countable noun. "Ruler" can also mean a king or leader.',
    ),
    'eraser': PhotoDictionaryEntry(
      ipa: '/ɪˈreɪ.sɚ/',
      cefr: 'A1',
      definition: 'A small rubber tool that removes pencil marks.',
      example: 'She used an eraser to fix her mistake.',
      grammarTip: 'Countable noun. British English often says "rubber".',
    ),
    'crayon': PhotoDictionaryEntry(
      ipa: '/ˈkreɪ.ɑːn/',
      cefr: 'A1',
      definition: 'A colored wax stick used for drawing.',
      example: 'The child drew a sun with a yellow crayon.',
      grammarTip: 'Countable noun. Say "a box of crayons".',
    ),
    'paper': PhotoDictionaryEntry(
      ipa: '/ˈpeɪ.pɚ/',
      cefr: 'A1',
      definition:
          'A thin, flat material used for writing, drawing, or printing.',
      example: 'Please write your answer on a piece of paper.',
      grammarTip:
          'Uncountable noun. Say "a sheet of paper" or "a piece of paper".',
    ),
    'calculator': PhotoDictionaryEntry(
      ipa: '/ˈkæl.kjə.leɪ.t̬ɚ/',
      cefr: 'A2',
      definition: 'A small electronic device for doing math.',
      example: 'Use the calculator to add these numbers.',
      grammarTip: 'Countable noun. Say "on a calculator".',
    ),
    'marker': PhotoDictionaryEntry(
      ipa: '/ˈmɑːr.kɚ/',
      cefr: 'A2',
      definition: 'A thick colored pen with a soft tip.',
      example: 'The teacher wrote on the board with a marker.',
      grammarTip: 'Countable noun. Also called a "felt-tip pen".',
    ),
    'pencil case': PhotoDictionaryEntry(
      ipa: '/ˈpen.səl ˌkeɪs/',
      cefr: 'A1',
      definition: 'A small bag or box for holding pens and pencils.',
      example: 'He keeps his pens in a pencil case.',
      grammarTip: 'Compound noun. Also called "pencil box" or "pencil pouch".',
    ),
    'whiteboard': PhotoDictionaryEntry(
      ipa: '/ˈwaɪt.bɔːrd/',
      cefr: 'A2',
      definition: 'A smooth white board that you write on with markers.',
      example: 'The teacher wrote the date on the whiteboard.',
      grammarTip: 'Countable noun. Use "on the whiteboard".',
    ),
    'highlighter': PhotoDictionaryEntry(
      ipa: '/ˈhaɪ.laɪ.t̬ɚ/',
      cefr: 'B1',
      definition: 'A bright pen used to mark important words.',
      example: 'She marked the key words with a yellow highlighter.',
      grammarTip: 'Countable noun. It comes from the verb "to highlight".',
    ),
    'paper clip': PhotoDictionaryEntry(
      ipa: '/ˈpeɪ.pɚ ˌklɪp/',
      cefr: 'A2',
      definition: 'A small bent piece of wire that holds papers together.',
      example: 'He used a paper clip to hold the pages.',
      grammarTip: 'Compound noun. Also written "paperclip".',
    ),
    'dictionary': PhotoDictionaryEntry(
      ipa: '/ˈdɪk.ʃə.ner.i/',
      cefr: 'A2',
      definition: 'A book that explains the meanings of words.',
      example: 'I looked up the word in the dictionary.',
      grammarTip:
          'Countable noun. Plural: dictionaries. Say "look up a word in a dictionary".',
    ),
    'map': PhotoDictionaryEntry(
      ipa: '/mæp/',
      cefr: 'A1',
      definition: 'A drawing that shows places, roads, or countries.',
      example: 'We looked at the map to find the park.',
      grammarTip: 'Countable noun. Say "on the map".',
    ),

    // ─── Curriculum Expansion · 5. Personal Belongings & Clothing ─────────────────
    'sock': PhotoDictionaryEntry(
      ipa: '/sɑːk/',
      cefr: 'A1',
      definition: 'A soft covering that you wear on your foot inside a shoe.',
      example: 'He lost one sock in the laundry.',
      grammarTip: 'Countable noun, usually plural. Say "a pair of socks".',
    ),
    'hat': PhotoDictionaryEntry(
      ipa: '/hæt/',
      cefr: 'A1',
      definition: 'A covering that you wear on your head.',
      example: 'She wore a warm hat in winter.',
      grammarTip: 'Countable noun. Use "wear a hat" and "put on a hat".',
    ),
    'jacket': PhotoDictionaryEntry(
      ipa: '/ˈdʒæk.ɪt/',
      cefr: 'A1',
      definition: 'A short coat that you wear on the top half of your body.',
      example: 'Take your jacket because it is cold outside.',
      grammarTip:
          'Countable noun. Use "put on a jacket" and "take off a jacket".',
    ),
    'shirt': PhotoDictionaryEntry(
      ipa: '/ʃɝːt/',
      cefr: 'A1',
      definition:
          'A piece of clothing for the upper body, usually with a collar and buttons.',
      example: 'He wore a white shirt to school.',
      grammarTip: 'Countable noun. A "T-shirt" has no collar or buttons.',
    ),
    'pants': PhotoDictionaryEntry(
      ipa: '/pænts/',
      cefr: 'A1',
      definition: 'A piece of clothing that covers both legs.',
      example: 'These pants are too long for me.',
      grammarTip:
          'Plural noun. Say "a pair of pants". British English: "trousers".',
    ),
    'dress': PhotoDictionaryEntry(
      ipa: '/dres/',
      cefr: 'A1',
      definition: 'A one-piece garment worn by women and girls.',
      example: 'She wore a red dress to the party.',
      grammarTip: 'Countable noun. As a verb, "dress" means to put on clothes.',
    ),
    'cap': PhotoDictionaryEntry(
      ipa: '/kæp/',
      cefr: 'A1',
      definition: 'A soft hat with a flat piece at the front.',
      example: 'He wore a baseball cap in the sun.',
      grammarTip: 'Countable noun. Say "baseball cap".',
    ),
    'shorts': PhotoDictionaryEntry(
      ipa: '/ʃɔːrts/',
      cefr: 'A1',
      definition: 'Short pants that end above the knee.',
      example: 'He wears shorts in the summer.',
      grammarTip: 'Plural noun. Say "a pair of shorts".',
    ),
    'belt': PhotoDictionaryEntry(
      ipa: '/belt/',
      cefr: 'A2',
      definition: 'A strip of leather or cloth worn around the waist.',
      example: 'He tightened his belt.',
      grammarTip: 'Countable noun. Use "wear a belt".',
    ),
    'glove': PhotoDictionaryEntry(
      ipa: '/ɡlʌv/',
      cefr: 'A2',
      definition:
          'A covering for the hand with a separate part for each finger.',
      example: 'She wore warm gloves in winter.',
      grammarTip: 'Countable noun, usually plural. Say "a pair of gloves".',
    ),
    'scarf': PhotoDictionaryEntry(
      ipa: '/skɑːrf/',
      cefr: 'A1',
      definition: 'A long piece of cloth worn around the neck.',
      example: 'Wrap a scarf around your neck.',
      grammarTip: 'Countable noun. Plural: scarves or scarfs.',
    ),
    'umbrella': PhotoDictionaryEntry(
      ipa: '/ʌmˈbrel.ə/',
      cefr: 'A1',
      definition:
          'A folding cover held over your head to keep off rain or sun.',
      example: 'Take an umbrella because it might rain.',
      grammarTip:
          'Countable noun. Starts with a vowel sound, so use "an umbrella".',
    ),
    'sweater': PhotoDictionaryEntry(
      ipa: '/ˈswet.ɚ/',
      cefr: 'A1',
      definition: 'A warm knitted piece of clothing for the upper body.',
      example: 'She put on a wool sweater.',
      grammarTip: 'Countable noun. British English also says "jumper".',
    ),
    'boots': PhotoDictionaryEntry(
      ipa: '/buːts/',
      cefr: 'A1',
      definition: 'Strong shoes that cover your ankle or leg.',
      example: 'He wore rain boots in the puddles.',
      grammarTip: 'Usually plural. Say "a pair of boots".',
    ),
    'sandals': PhotoDictionaryEntry(
      ipa: '/ˈsæn.dəlz/',
      cefr: 'A2',
      definition: 'Light open shoes with straps, worn in warm weather.',
      example: 'She wore sandals to the beach.',
      grammarTip: 'Usually plural. Say "a pair of sandals".',
    ),
    'sunglasses': PhotoDictionaryEntry(
      ipa: '/ˈsʌnˌɡlæs.ɪz/',
      cefr: 'A2',
      definition: 'Dark glasses that protect your eyes from the sun.',
      example: 'He put on his sunglasses.',
      grammarTip: 'Plural noun. Say "a pair of sunglasses".',
    ),
    'necklace': PhotoDictionaryEntry(
      ipa: '/ˈnek.ləs/',
      cefr: 'A2',
      definition: 'A piece of jewelry worn around the neck.',
      example: 'She wore a silver necklace.',
      grammarTip: 'Countable noun. Use "wear a necklace".',
    ),
    'hoodie': PhotoDictionaryEntry(
      ipa: '/ˈhʊd.i/',
      cefr: 'A2',
      definition: 'A sweatshirt with a hood.',
      example: 'He pulled up his hoodie in the rain.',
      grammarTip: 'Informal noun. Also called a "hooded sweatshirt".',
    ),

    // ─── Curriculum Expansion · 6. Electronics & Home Appliances ──────────────────
    'monitor': PhotoDictionaryEntry(
      ipa: '/ˈmɑː.nə.t̬ɚ/',
      cefr: 'A2',
      definition: 'A screen that shows what a computer is doing.',
      example: 'He has two monitors on his desk.',
      grammarTip:
          'Countable noun. As a verb, "to monitor" means to watch carefully.',
    ),
    'remote control': PhotoDictionaryEntry(
      ipa: '/rɪˌmoʊt kənˈtroʊl/',
      cefr: 'A2',
      definition: 'A small device used to control a TV from far away.',
      example: 'Where is the TV remote control?',
      grammarTip: 'Compound noun. Often shortened to "remote".',
    ),
    'speaker': PhotoDictionaryEntry(
      ipa: '/ˈspiː.kɚ/',
      cefr: 'A2',
      definition: 'A device that plays sound or music.',
      example: 'Turn up the speaker, please.',
      grammarTip:
          'Countable noun. A "speaker" can also be a person who speaks.',
    ),
    'fan': PhotoDictionaryEntry(
      ipa: '/fæn/',
      cefr: 'A2',
      definition: 'A machine with blades that moves air to keep you cool.',
      example: 'Turn on the fan because it is hot.',
      grammarTip:
          'Countable noun. Also means a person who loves something, like a football fan.',
    ),
    'camera': PhotoDictionaryEntry(
      ipa: '/ˈkæm.rə/',
      cefr: 'A1',
      definition: 'A device for taking photographs or videos.',
      example: 'She took a photo with her camera.',
      grammarTip: 'Countable noun. Often said with two syllables: CAM-ruh.',
    ),
    'tablet': PhotoDictionaryEntry(
      ipa: '/ˈtæb.lət/',
      cefr: 'A2',
      definition: 'A flat touchscreen computer that is bigger than a phone.',
      example: 'He reads books on his tablet.',
      grammarTip: 'Countable noun. Also called a "tablet computer".',
    ),
    'light bulb': PhotoDictionaryEntry(
      ipa: '/ˈlaɪt ˌbʌlb/',
      cefr: 'A2',
      definition:
          'A glass object that gives light when electricity passes through it.',
      example: 'The light bulb burned out last night.',
      grammarTip: 'Compound noun. Also written "lightbulb".',
    ),
    'washing machine': PhotoDictionaryEntry(
      ipa: '/ˈwɑː.ʃɪŋ məˌʃiːn/',
      cefr: 'A2',
      definition: 'A machine that washes clothes.',
      example: 'Put the dirty clothes in the washing machine.',
      grammarTip: 'Compound noun. Americans also say "washer".',
    ),
    'game controller': PhotoDictionaryEntry(
      ipa: '/ˈɡeɪm kənˌtroʊ.lɚ/',
      cefr: 'A2',
      definition: 'A handheld device used to play video games.',
      example: 'He held the game controller with both hands.',
      grammarTip: 'Compound noun. Also called a "gamepad".',
    ),
    'printer': PhotoDictionaryEntry(
      ipa: '/ˈprɪn.t̬ɚ/',
      cefr: 'B1',
      definition: 'A machine that puts words or pictures on paper.',
      example: 'The printer is out of paper.',
      grammarTip: 'Countable noun. It comes from the verb "to print".',
    ),
    'vacuum cleaner': PhotoDictionaryEntry(
      ipa: '/ˈvæk.juːm ˌkliː.nɚ/',
      cefr: 'B1',
      definition: 'A machine that cleans floors by sucking up dirt.',
      example: 'She used the vacuum cleaner on the carpet.',
      grammarTip:
          'Compound noun. Informally called a "vacuum"; also a verb: "to vacuum".',
    ),
    'hair dryer': PhotoDictionaryEntry(
      ipa: '/ˈher ˌdraɪ.ɚ/',
      cefr: 'B1',
      definition: 'A machine that blows warm air to dry your hair.',
      example: 'She dried her hair with a hair dryer.',
      grammarTip: 'Compound noun. Also written "hairdryer".',
    ),
    'microphone': PhotoDictionaryEntry(
      ipa: '/ˈmaɪ.krə.foʊn/',
      cefr: 'B1',
      definition: 'A device that records voices or makes them louder.',
      example: 'The singer held the microphone.',
      grammarTip: 'Countable noun. Often shortened to "mic".',
    ),
    'radio': PhotoDictionaryEntry(
      ipa: '/ˈreɪ.di.oʊ/',
      cefr: 'A1',
      definition: 'A device that plays music and news from stations.',
      example: 'Grandpa listens to the radio every morning.',
      grammarTip: 'Countable noun. Say "listen to the radio" (with the).',
    ),

    // ─── Curriculum Expansion · 7. Living Room & Decor ────────────────────────────
    'rug': PhotoDictionaryEntry(
      ipa: '/rʌɡ/',
      cefr: 'A2',
      definition: 'A thick piece of cloth that covers part of a floor.',
      example: 'The cat sleeps on the rug.',
      grammarTip: 'Countable noun. A rug is smaller than a carpet.',
    ),
    'curtains': PhotoDictionaryEntry(
      ipa: '/ˈkɝː.t̬ənz/',
      cefr: 'A1',
      definition: 'Pieces of cloth that hang over a window.',
      example: 'Please close the curtains.',
      grammarTip: 'Usually plural. One piece is "a curtain".',
    ),
    'bookshelf': PhotoDictionaryEntry(
      ipa: '/ˈbʊk.ʃelf/',
      cefr: 'A1',
      definition: 'A piece of furniture with shelves for holding books.',
      example: 'She put the novel on the bookshelf.',
      grammarTip: 'Countable noun. Plural: bookshelves (-f changes to -ves).',
    ),
    'armchair': PhotoDictionaryEntry(
      ipa: '/ˈɑːrm.tʃer/',
      cefr: 'A1',
      definition: 'A comfortable chair with side supports for your arms.',
      example: 'Grandpa reads in his armchair.',
      grammarTip: 'Compound noun (arm + chair). Use "in an armchair".',
    ),
    'coffee table': PhotoDictionaryEntry(
      ipa: '/ˈkɑː.fi ˌteɪ.bəl/',
      cefr: 'A2',
      definition: 'A low table in a living room.',
      example: 'She placed the magazines on the coffee table.',
      grammarTip: 'Compound noun. Use "on the coffee table".',
    ),
    'flowerpot': PhotoDictionaryEntry(
      ipa: '/ˈflaʊ.ɚ.pɑːt/',
      cefr: 'A2',
      definition: 'A container for growing plants.',
      example: 'She watered the flowerpot by the window.',
      grammarTip: 'Compound noun. Also written "flower pot".',
    ),
    'poster': PhotoDictionaryEntry(
      ipa: '/ˈpoʊ.stɚ/',
      cefr: 'A2',
      definition: 'A large printed picture or notice hung on a wall.',
      example: 'He hung a poster of a rocket on his wall.',
      grammarTip: 'Countable noun. Use "on the wall".',
    ),
    'doormat': PhotoDictionaryEntry(
      ipa: '/ˈdɔːr.mæt/',
      cefr: 'B1',
      definition: 'A small mat outside a door for wiping your shoes.',
      example: 'Wipe your feet on the doormat.',
      grammarTip: 'Compound noun (door + mat).',
    ),
    'basket': PhotoDictionaryEntry(
      ipa: '/ˈbæs.kɪt/',
      cefr: 'A2',
      definition:
          'A container made of woven strips, used for carrying or storing things.',
      example: 'She carried the fruit in a basket.',
      grammarTip: 'Countable noun. Say "a basket of fruit".',
    ),
    'cactus': PhotoDictionaryEntry(
      ipa: '/ˈkæk.təs/',
      cefr: 'A2',
      definition: 'A spiky desert plant that stores water.',
      example: 'The cactus on the windowsill needs little water.',
      grammarTip: 'Countable noun. Plural: cacti or cactuses.',
    ),
    'box': PhotoDictionaryEntry(
      ipa: '/bɑːks/',
      cefr: 'A1',
      definition: 'A container with straight sides, used for keeping things.',
      example: 'She put the toys in a box.',
      grammarTip: 'Countable noun. Plural adds -es: boxes.',
    ),

    // ─── Curriculum Expansion · 8. Bathroom & Personal Care ───────────────────────
    'toothpaste': PhotoDictionaryEntry(
      ipa: '/ˈtuːθ.peɪst/',
      cefr: 'A1',
      definition: 'A soft cream you put on a brush to clean your teeth.',
      example: 'Put a little toothpaste on your toothbrush.',
      grammarTip: 'Uncountable noun. Say "a tube of toothpaste".',
    ),
    'sink': PhotoDictionaryEntry(
      ipa: '/sɪŋk/',
      cefr: 'A1',
      definition: 'A bowl with a tap for washing hands or dishes.',
      example: 'She washed her hands in the sink.',
      grammarTip:
          'Countable noun. As a verb, "sink" means to go down in water.',
    ),
    'hairbrush': PhotoDictionaryEntry(
      ipa: '/ˈher.brʌʃ/',
      cefr: 'A1',
      definition: 'A tool with bristles used to make your hair smooth.',
      example: 'She used a hairbrush every morning.',
      grammarTip: 'Compound noun (hair + brush), written as one word.',
    ),
    'toilet': PhotoDictionaryEntry(
      ipa: '/ˈtɔɪ.lət/',
      cefr: 'A1',
      definition:
          'A bowl-shaped seat in a bathroom used for getting rid of body waste.',
      example: 'Please flush the toilet after you use it.',
      grammarTip:
          'Countable noun. Polite words in American English: "restroom" or "bathroom".',
    ),
    'bathtub': PhotoDictionaryEntry(
      ipa: '/ˈbæθ.tʌb/',
      cefr: 'A1',
      definition: 'A large container you fill with water to wash your body.',
      example: 'He ran warm water into the bathtub.',
      grammarTip: 'Compound noun. British English also says "bath".',
    ),
    'toilet paper': PhotoDictionaryEntry(
      ipa: '/ˈtɔɪ.lət ˌpeɪ.pɚ/',
      cefr: 'A2',
      definition: 'Soft paper in a roll used in the bathroom.',
      example: 'We need to buy more toilet paper.',
      grammarTip: 'Uncountable noun. Say "a roll of toilet paper".',
    ),
    'bucket': PhotoDictionaryEntry(
      ipa: '/ˈbʌk.ɪt/',
      cefr: 'A2',
      definition: 'A round open container with a handle for carrying water.',
      example: 'He filled the bucket with water.',
      grammarTip: 'Countable noun. Say "a bucket of water".',
    ),
    'trash can': PhotoDictionaryEntry(
      ipa: '/ˈtræʃ ˌkæn/',
      cefr: 'A2',
      definition: 'A container where you throw away waste.',
      example: 'Please throw the paper in the trash can.',
      grammarTip:
          'Compound noun. British English says "rubbish bin" or "dustbin".',
    ),
    'faucet': PhotoDictionaryEntry(
      ipa: '/ˈfɑː.sɪt/',
      cefr: 'B1',
      definition: 'A device that controls the flow of water from a pipe.',
      example: 'Turn off the faucet when you brush your teeth.',
      grammarTip: 'American English word. British English says "tap".',
    ),
    'soap dispenser': PhotoDictionaryEntry(
      ipa: '/ˈsoʊp dɪˌspen.sɚ/',
      cefr: 'B1',
      definition: 'A container that gives out liquid soap when you press it.',
      example: 'Press the soap dispenser twice.',
      grammarTip: 'Compound noun. It comes from the verb "to dispense".',
    ),
    'laundry basket': PhotoDictionaryEntry(
      ipa: '/ˈlɔːn.dri ˌbæs.kɪt/',
      cefr: 'B1',
      definition: 'A basket for dirty clothes that are waiting to be washed.',
      example: 'Put your dirty socks in the laundry basket.',
      grammarTip: 'Compound noun. "Laundry" is uncountable.',
    ),

    // ─── Curriculum Expansion · 9. Outdoor, Garden, Nature & Transport ────────────
    'leaf': PhotoDictionaryEntry(
      ipa: '/liːf/',
      cefr: 'A1',
      definition: 'A flat green part of a plant that grows on a stem.',
      example: 'A red leaf fell from the tree.',
      grammarTip: 'Countable noun. Irregular plural: leaves.',
    ),
    'grass': PhotoDictionaryEntry(
      ipa: '/ɡræs/',
      cefr: 'A1',
      definition: 'A green plant with thin leaves that covers the ground.',
      example: 'The children played on the soft grass.',
      grammarTip: 'Uncountable noun. Say "on the grass".',
    ),
    'cloud': PhotoDictionaryEntry(
      ipa: '/klaʊd/',
      cefr: 'A1',
      definition: 'A white or gray mass floating in the sky.',
      example: 'A big cloud covered the sun.',
      grammarTip: 'Countable noun. Say "clouds in the sky".',
    ),
    'rock': PhotoDictionaryEntry(
      ipa: '/rɑːk/',
      cefr: 'A1',
      definition: 'A hard piece of stone from the ground.',
      example: 'He sat on a big rock by the river.',
      grammarTip: '"A rock" is one piece; "rock" is also the material.',
    ),
    'house': PhotoDictionaryEntry(
      ipa: '/haʊs/',
      cefr: 'A1',
      definition: 'A building where people live.',
      example: 'Their house has a red door.',
      grammarTip:
          'Countable noun. The noun is /haʊs/; the verb "to house" is /haʊz/.',
    ),
    'road': PhotoDictionaryEntry(
      ipa: '/roʊd/',
      cefr: 'A1',
      definition: 'A hard path where cars and buses travel.',
      example: 'Look both ways before you cross the road.',
      grammarTip: 'Countable noun. Say "on the road" and "cross the road".',
    ),
    'bus': PhotoDictionaryEntry(
      ipa: '/bʌs/',
      cefr: 'A1',
      definition: 'A large vehicle that carries many people.',
      example: 'I take the bus to school.',
      grammarTip:
          'Countable noun. Plural: buses. Say "by bus" without an article.',
    ),
    'truck': PhotoDictionaryEntry(
      ipa: '/trʌk/',
      cefr: 'A1',
      definition: 'A large vehicle for carrying heavy goods.',
      example: 'A truck delivered the furniture.',
      grammarTip: 'Countable noun. British English also says "lorry".',
    ),
    'boat': PhotoDictionaryEntry(
      ipa: '/boʊt/',
      cefr: 'A1',
      definition: 'A small vehicle that travels on water.',
      example: 'We crossed the river by boat.',
      grammarTip: 'Countable noun. Say "by boat" without an article.',
    ),
    'airplane': PhotoDictionaryEntry(
      ipa: '/ˈer.pleɪn/',
      cefr: 'A1',
      definition: 'A vehicle with wings that flies in the sky.',
      example: 'The airplane landed at noon.',
      grammarTip:
          'Countable noun. British English: "aeroplane". Shorter: "plane".',
    ),
    'train': PhotoDictionaryEntry(
      ipa: '/treɪn/',
      cefr: 'A1',
      definition: 'A long vehicle that runs on rails.',
      example: 'She travels by train every Monday.',
      grammarTip: 'Countable noun. Say "by train" without an article.',
    ),
    'motorcycle': PhotoDictionaryEntry(
      ipa: '/ˈmoʊ.t̬ɚˌsaɪ.kəl/',
      cefr: 'A2',
      definition: 'A two-wheeled vehicle with an engine.',
      example: 'He rides a motorcycle to work.',
      grammarTip:
          'Countable noun. Often shortened to "motorbike" in British English.',
    ),
    'fish': PhotoDictionaryEntry(
      ipa: '/fɪʃ/',
      cefr: 'A1',
      definition: 'An animal that lives and breathes in water.',
      example: 'The fish swam around the tank.',
      grammarTip:
          'Plural is usually "fish" (same form). "Fishes" refers to different species.',
    ),
    'horse': PhotoDictionaryEntry(
      ipa: '/hɔːrs/',
      cefr: 'A1',
      definition: 'A large, strong animal that people ride.',
      example: 'She rode a horse across the field.',
      grammarTip: 'Countable noun. Say "ride a horse".',
    ),
    'cow': PhotoDictionaryEntry(
      ipa: '/kaʊ/',
      cefr: 'A1',
      definition: 'A large farm animal kept for milk.',
      example: 'The cow ate grass in the field.',
      grammarTip: 'Countable noun. Plural: cows.',
    ),
    'chicken': PhotoDictionaryEntry(
      ipa: '/ˈtʃɪk.ɪn/',
      cefr: 'A1',
      definition: 'A farm bird kept for eggs and meat.',
      example: 'The chicken laid an egg this morning.',
      grammarTip: 'Countable for the bird; uncountable for the meat.',
    ),
    'rabbit': PhotoDictionaryEntry(
      ipa: '/ˈræb.ɪt/',
      cefr: 'A1',
      definition: 'A small furry animal with long ears.',
      example: 'The rabbit hopped across the garden.',
      grammarTip: 'Countable noun. Plural: rabbits.',
    ),
    'duck': PhotoDictionaryEntry(
      ipa: '/dʌk/',
      cefr: 'A1',
      definition: 'A water bird with a flat beak.',
      example: 'The duck swam across the pond.',
      grammarTip:
          'Countable noun. Also a verb meaning to lower your head quickly.',
    ),
    'sheep': PhotoDictionaryEntry(
      ipa: '/ʃiːp/',
      cefr: 'A1',
      definition: 'A farm animal with thick wool.',
      example: 'The sheep ate grass on the hill.',
      grammarTip: 'Same form for singular and plural: one sheep, two sheep.',
    ),
    'butterfly': PhotoDictionaryEntry(
      ipa: '/ˈbʌt̬.ɚ.flaɪ/',
      cefr: 'A1',
      definition: 'An insect with large, colorful wings.',
      example: 'A yellow butterfly landed on the flower.',
      grammarTip: 'Countable noun. Plural: change -y to -ies: butterflies.',
    ),
    'squirrel': PhotoDictionaryEntry(
      ipa: '/ˈskwɝː.əl/',
      cefr: 'A2',
      definition: 'A small animal with a bushy tail that climbs trees.',
      example: 'The squirrel ran up the tree.',
      grammarTip: 'Countable noun. Pronounced in two syllables: SKWUR-ul.',
    ),
    'bench': PhotoDictionaryEntry(
      ipa: '/bentʃ/',
      cefr: 'A2',
      definition: 'A long seat for several people, often outdoors.',
      example: 'We sat on a bench in the park.',
      grammarTip: 'Countable noun. Plural: benches. Say "on a bench".',
    ),
    'fence': PhotoDictionaryEntry(
      ipa: '/fens/',
      cefr: 'A2',
      definition: 'A wooden or metal wall around a garden or field.',
      example: 'The dog jumped over the fence.',
      grammarTip: 'Countable noun. Say "over the fence".',
    ),
    'mailbox': PhotoDictionaryEntry(
      ipa: '/ˈmeɪl.bɑːks/',
      cefr: 'B1',
      definition: 'A box where letters are delivered.',
      example: 'She checked the mailbox for letters.',
      grammarTip: 'Compound noun. British English: "postbox" or "letterbox".',
    ),
    'fountain': PhotoDictionaryEntry(
      ipa: '/ˈfaʊn.tən/',
      cefr: 'B1',
      definition: 'A structure that sprays water into the air.',
      example: 'The children played near the fountain.',
      grammarTip: 'Countable noun. Pronounced FOWN-tin.',
    ),

    // ─── Curriculum Expansion · 10. Toys, Hobbies & Sports ────────────────────────
    'ball': PhotoDictionaryEntry(
      ipa: '/bɔːl/',
      cefr: 'A1',
      definition: 'A round object used in games and sports.',
      example: 'He kicked the ball across the field.',
      grammarTip: 'Countable noun. Use "throw", "kick", or "catch" a ball.',
    ),
    'teddy bear': PhotoDictionaryEntry(
      ipa: '/ˈted.i ˌber/',
      cefr: 'A1',
      definition: 'A soft toy that looks like a bear.',
      example: 'She hugged her teddy bear at night.',
      grammarTip: 'Compound noun. Often shortened to "teddy".',
    ),
    'doll': PhotoDictionaryEntry(
      ipa: '/dɑːl/',
      cefr: 'A1',
      definition: 'A small toy shaped like a person.',
      example: 'She dressed the doll in a pink dress.',
      grammarTip: 'Countable noun. Say "play with a doll".',
    ),
    'balloon': PhotoDictionaryEntry(
      ipa: '/bəˈluːn/',
      cefr: 'A1',
      definition: 'A thin rubber bag filled with air or gas.',
      example: 'The red balloon floated into the sky.',
      grammarTip: 'Countable noun. Stress the second syllable: buh-LOON.',
    ),
    'toy car': PhotoDictionaryEntry(
      ipa: '/ˈtɔɪ ˌkɑːr/',
      cefr: 'A1',
      definition: 'A small model car for children to play with.',
      example: 'He pushed the toy car across the floor.',
      grammarTip: 'Compound noun. "Toy" before a noun shows it is not real.',
    ),
    'basketball': PhotoDictionaryEntry(
      ipa: '/ˈbæs.kɪt.bɔːl/',
      cefr: 'A1',
      definition: 'A large orange ball used in the game of basketball.',
      example: 'He bounced the basketball on the court.',
      grammarTip: 'Compound noun. Also the name of the sport.',
    ),
    'football': PhotoDictionaryEntry(
      ipa: '/ˈfʊt.bɔːl/',
      cefr: 'A1',
      definition:
          'A round ball used in the game of football, called soccer in the US.',
      example: 'The boys kicked a football in the park.',
      grammarTip:
          'In most countries, football means soccer. In the US it is a different ball.',
    ),
    'puzzle': PhotoDictionaryEntry(
      ipa: '/ˈpʌz.əl/',
      cefr: 'A2',
      definition: 'A game where you fit pieces together to make a picture.',
      example: 'We finished the puzzle in one hour.',
      grammarTip: 'Countable noun. Say "do a puzzle".',
    ),
    'guitar': PhotoDictionaryEntry(
      ipa: '/ɡɪˈtɑːr/',
      cefr: 'A1',
      definition:
          'A musical instrument with strings that you play with your fingers.',
      example: 'He plays the guitar in a band.',
      grammarTip: 'Countable noun. Say "play the guitar".',
    ),
    'kite': PhotoDictionaryEntry(
      ipa: '/kaɪt/',
      cefr: 'A1',
      definition: 'A light toy that flies in the wind on a long string.',
      example: 'They flew a kite on the beach.',
      grammarTip: 'Countable noun. Say "fly a kite".',
    ),
    'skateboard': PhotoDictionaryEntry(
      ipa: '/ˈskeɪt.bɔːrd/',
      cefr: 'A2',
      definition: 'A board with four wheels that you stand on and ride.',
      example: 'He rode his skateboard to the park.',
      grammarTip: 'Compound noun. Say "ride a skateboard".',
    ),
    'piano': PhotoDictionaryEntry(
      ipa: '/piˈæn.oʊ/',
      cefr: 'A1',
      definition: 'A large musical instrument with black and white keys.',
      example: 'She plays the piano every evening.',
      grammarTip: 'Countable noun. Say "play the piano".',
    ),
    'drum': PhotoDictionaryEntry(
      ipa: '/drʌm/',
      cefr: 'A1',
      definition:
          'A round musical instrument that you hit with sticks or your hands.',
      example: 'He hit the drum with two sticks.',
      grammarTip: 'Countable noun. Say "play the drums" for a full set.',
    ),
    'helmet': PhotoDictionaryEntry(
      ipa: '/ˈhel.mɪt/',
      cefr: 'A1',
      definition: 'A hard hat that protects your head.',
      example: 'Always wear a helmet when you ride a bike.',
      grammarTip: 'Countable noun. Use "wear a helmet".',
    ),
    'building blocks': PhotoDictionaryEntry(
      ipa: '/ˈbɪl.dɪŋ ˌblɑːks/',
      cefr: 'A2',
      definition: 'Small colored pieces that children stack to build things.',
      example: 'He built a tall tower from building blocks.',
      grammarTip: 'Plural compound noun. Singular: "building block".',
    ),
    'board game': PhotoDictionaryEntry(
      ipa: '/ˈbɔːrd ˌɡeɪm/',
      cefr: 'B1',
      definition: 'A game played on a flat board with pieces or cards.',
      example: 'We played a board game on Sunday.',
      grammarTip: 'Compound noun. Say "play a board game".',
    ),
    'violin': PhotoDictionaryEntry(
      ipa: '/ˌvaɪ.əˈlɪn/',
      cefr: 'A2',
      definition:
          'A small musical instrument with four strings, played with a bow.',
      example: 'She practices the violin every day.',
      grammarTip: 'Countable noun. Say "play the violin".',
    ),
  };

  /// Normalizes a label by trimming, lowercasing, and stripping punctuation.
  static String normalize(String label) {
    return label
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Returns dictionary data if available, otherwise generates a smart fallback.
  static PhotoDictionaryEntry getEntry(String label) {
    final key = normalize(label);

    // 1. Direct dictionary match
    if (dictionary.containsKey(key)) {
      return dictionary[key]!;
    }

    // 2. Singular/plural normalization match (bidirectional)
    if (key.endsWith('s') &&
        dictionary.containsKey(key.substring(0, key.length - 1))) {
      return dictionary[key.substring(0, key.length - 1)]!;
    }
    if (key.endsWith('es') &&
        dictionary.containsKey(key.substring(0, key.length - 2))) {
      return dictionary[key.substring(0, key.length - 2)]!;
    }
    if (dictionary.containsKey('${key}s')) {
      return dictionary['${key}s']!;
    }
    if (dictionary.containsKey('${key}es')) {
      return dictionary['${key}es']!;
    }

    // 3. Compound word match without spaces (e.g. "house plant" -> "houseplant")
    final collapsed = key.replaceAll(' ', '');
    if (dictionary.containsKey(collapsed)) {
      return dictionary[collapsed]!;
    }

    // 4. Token-based multi-word match (e.g. "red coffee mug" -> "mug")
    final tokens = key.split(' ');
    if (tokens.length > 1) {
      for (final t in tokens) {
        if (dictionary.containsKey(t)) {
          return dictionary[t]!;
        }
      }
    }

    if (key.isEmpty) {
      return const PhotoDictionaryEntry(
        ipa: null,
        definition: 'An object identified in your environment.',
        example: 'I can see an object in this image.',
        grammarTip: 'Grammar: Nouns represent people, places, or things.',
      );
    }

    // Smart grammatical fallback for rare/unknown words
    final startsWithVowel = ['a', 'e', 'i', 'o', 'u'].contains(key[0]);
    final article = startsWithVowel ? 'an' : 'a';

    String generatedGrammarTip = '';
    if (key.contains(' ')) {
      generatedGrammarTip =
          'Grammar: Compound noun (formed by combining words).';
    } else if (key.endsWith('s') && key.length > 3) {
      generatedGrammarTip =
          'Grammar: Plural noun ending in "s". Use plural verbs.';
    } else if (key.endsWith('ing')) {
      generatedGrammarTip =
          'Grammar: Word ending in "-ing" (gerund or action form).';
    } else if (key.endsWith('y')) {
      generatedGrammarTip =
          'Grammar: Ends in "-y". Change "y" to "-ies" for plural form.';
    } else if (key.length >= 8) {
      generatedGrammarTip =
          'Grammar: Multi-syllable noun. Practice pronouncing each part.';
    } else {
      generatedGrammarTip = startsWithVowel
          ? 'Grammar: Precede with article "an" before a vowel sound.'
          : 'Grammar: Precede with article "a" before a consonant sound.';
    }

    return PhotoDictionaryEntry(
      ipa: null,
      cefr: 'A2',
      definition: 'An everyday object identified in your environment.',
      example: 'I can see $article $key in this photo.',
      grammarTip: generatedGrammarTip,
    );
  }

  /// Checks if a detected label matches the current target bounty challenge,
  /// incorporating semantic aliases and plural/compound normalization.
  static bool isBountyMatch(String targetBounty, String detectedLabel) {
    final target = normalize(targetBounty);
    final detected = normalize(detectedLabel);

    if (target.isEmpty || detected.isEmpty) return false;

    // Direct match
    if (target == detected) return true;

    // Stemming / plural normalization
    if (target == '${detected}s' ||
        detected == '${target}s' ||
        target == '${detected}es' ||
        detected == '${target}es') {
      return true;
    }

    // Space / hyphen variation (e.g. "coffee cup" vs "coffeecup", "houseplant" vs "house plant")
    if (target.replaceAll(' ', '') == detected.replaceAll(' ', '')) return true;

    // Known ESL and Computer Vision alias dictionary
    const Map<String, List<String>> aliases = {
      'coffee cup': [
        'coffee cup',
        'cup',
        'mug',
        'coffee',
        'teacup',
        'cappuccino',
        'drinkware',
      ],
      'mug': ['mug', 'cup', 'coffee cup', 'coffee mug', 'teacup'],
      'cup': ['cup', 'coffee cup', 'mug', 'teacup', 'glass'],
      'keyboard': ['keyboard', 'computer keyboard', 'keypad', 'keys'],
      'houseplant': [
        'houseplant',
        'house plant',
        'plant',
        'flowerpot',
        'pot plant',
        'flora',
        'potted plant',
      ],
      'backpack': [
        'backpack',
        'pack',
        'bag',
        'rucksack',
        'knapsack',
        'schoolbag',
      ],
      'chair': [
        'chair',
        'armchair',
        'seat',
        'furniture',
        'stool',
        'office chair',
      ],
      'desk': [
        'desk',
        'office desk',
        'writing desk',
        'table',
        'study desk',
        'workstation',
      ],
      'shoe': [
        'shoe',
        'shoes',
        'footwear',
        'sneaker',
        'sneakers',
        'boot',
        'boots',
        'athletic shoe',
      ],
      'watch': ['watch', 'wrist watch', 'wristwatch', 'timepiece', 'clock'],
      'spoon': [
        'spoon',
        'teaspoon',
        'tablespoon',
        'cutlery',
        'flatware',
        'silverware',
      ],
      'glasses': [
        'glasses',
        'spectacles',
        'eyewear',
        'sunglasses',
        'eyeglasses',
        'goggles',
      ],
      'pen': [
        'pen',
        'ballpoint pen',
        'fountain pen',
        'marker',
        'writing implement',
        'pencil',
        'stationery',
      ],
      'notebook': [
        'notebook',
        'book',
        'notepad',
        'journal',
        'diary',
        'spiral notebook',
      ],
      'bottle': [
        'bottle',
        'water bottle',
        'plastic bottle',
        'glass bottle',
        'flask',
      ],
      'lamp': [
        'lamp',
        'table lamp',
        'desk lamp',
        'lantern',
        'lighting',
        'light fixture',
      ],
      'television': [
        'television',
        'tv',
        'screen',
        'monitor',
        'display',
        'flat screen',
      ],
      'sofa': ['sofa', 'couch', 'settee', 'furniture', 'davenport'],
      'cushion': ['cushion', 'cushions', 'pillow', 'throw pillow'],
      'door': ['door', 'doorway', 'entrance', 'gate'],
      'window': ['window', 'windowpane', 'casement', 'glass window'],
      'mirror': ['mirror', 'looking glass', 'reflector'],
      'toothbrush': ['toothbrush', 'tooth brush', 'dental brush'],
      'towel': ['towel', 'bath towel', 'hand towel', 'cloth'],
      'soap': ['soap', 'soap bar', 'hand soap', 'bar soap', 'cleanser'],
      'shampoo': ['shampoo', 'hair wash', 'hair product', 'conditioner'],
      'comb': ['comb', 'hairbrush', 'hair comb', 'brush'],
      'wallet': ['wallet', 'purse', 'billfold', 'pocketbook'],
      'keys': ['key', 'keys', 'car key', 'door key', 'keychain'],
      'phone': [
        'phone',
        'mobile phone',
        'cell phone',
        'smartphone',
        'telephone',
        'cellular',
      ],
      'headphones': [
        'headphones',
        'headphone',
        'earphones',
        'headset',
        'earbuds',
      ],
      'charger': [
        'charger',
        'battery charger',
        'power adapter',
        'cable',
        'usb charger',
      ],
      'scissors': ['scissors', 'shears', 'clippers'],
      'tape': ['tape', 'adhesive tape', 'duct tape', 'scotch tape'],
      'stapler': ['stapler', 'staples', 'office stapler'],
      'clock': ['clock', 'wall clock', 'alarm clock', 'timepiece'],
      'calendar': ['calendar', 'schedule', 'wall calendar'],
      'picture frame': [
        'picture frame',
        'frame',
        'photo frame',
        'painting',
        'picture',
        'artwork',
      ],
      'vase': ['vase', 'flower vase', 'urn', 'ceramic vase'],
      'plate': ['plate', 'dish', 'dinner plate', 'saucer', 'tableware'],
      'bowl': ['bowl', 'cereal bowl', 'soup bowl', 'dish'],
      'fork': ['fork', 'table fork', 'cutlery', 'silverware'],
      'knife': ['knife', 'knives', 'butter knife', 'kitchen knife', 'cutlery'],
      'pan': ['pan', 'frying pan', 'skillet', 'saucepan', 'cookware'],
      'pot': ['pot', 'cooking pot', 'stockpot', 'saucepot', 'cookware'],
      'oven': ['oven', 'stove', 'range', 'kitchen oven'],
      'refrigerator': ['refrigerator', 'fridge', 'freezer', 'cooler', 'icebox'],
      'microwave': ['microwave', 'microwave oven', 'oven'],
      'toaster': ['toaster', 'toaster oven'],
      'blender': ['blender', 'food processor', 'mixer'],
      'apple': ['apple', 'red apple', 'green apple', 'fruit'],
      'banana': ['banana', 'ripe banana', 'fruit'],
      'orange': ['orange', 'citrus', 'mandarin', 'tangerine', 'fruit'],
      'bread': ['bread', 'loaf', 'toast', 'baguette', 'bakery'],
      'car': ['car', 'automobile', 'vehicle', 'motor vehicle', 'sedan'],
      'bicycle': ['bicycle', 'bike', 'cycle', 'mountain bike'],
      'tree': ['tree', 'woody plant', 'forest', 'trunk', 'wood'],
      'flower': ['flower', 'blossom', 'bloom', 'petal', 'flora'],
      'dog': ['dog', 'puppy', 'canine', 'hound'],
      'cat': ['cat', 'kitten', 'feline', 'kitty'],
      'bird': ['bird', 'songbird', 'avian', 'fowl'],

      // ── Curriculum expansion aliases (CV label synonyms) ──
      'pillow': ['pillow', 'pillows', 'bed pillow', 'head pillow'],
      'blanket': ['blanket', 'blankets', 'quilt', 'comforter', 'duvet'],
      'wardrobe': ['wardrobe', 'closet', 'armoire', 'clothes cupboard'],
      'nightstand': ['nightstand', 'bedside table', 'night table', 'end table'],
      'drawer': ['drawer', 'drawers', 'chest of drawers', 'dresser', 'cabinet'],
      'kettle': [
        'kettle',
        'electric kettle',
        'tea kettle',
        'water kettle',
        'cookware and bakeware',
      ],
      'spatula': [
        'spatula',
        'turner',
        'pancake turner',
        'kitchen utensil',
        'cutlery',
      ],
      'ladle': ['ladle', 'soup ladle', 'serving spoon', 'dipper', 'cutlery'],
      'chopsticks': ['chopsticks', 'chopstick', 'eating utensil', 'cutlery'],
      'cutting board': [
        'cutting board',
        'chopping board',
        'wooden board',
        'kitchen board',
        'countertop',
        'kitchen',
      ],
      'teapot': [
        'teapot',
        'tea pot',
        'tea set',
        'teaware',
        'tableware',
        'porcelain',
      ],
      'lunch box': [
        'lunch box',
        'lunchbox',
        'bento',
        'tiffin',
        'food container',
        'lunch',
      ],
      'colander': [
        'colander',
        'strainer',
        'sieve',
        'pasta strainer',
        'cookware and bakeware',
      ],
      'tomato': [
        'tomato',
        'tomatoes',
        'cherry tomato',
        'roma tomato',
        'vegetable',
        'food',
      ],
      'carrot': [
        'carrot',
        'carrots',
        'baby carrot',
        'root vegetable',
        'vegetable',
        'food',
      ],
      'potato': [
        'potato',
        'potatoes',
        'russet potato',
        'sweet potato',
        'vegetable',
        'food',
      ],
      'egg': ['egg', 'eggs', 'boiled egg', 'fried egg', 'eggshell', 'food'],
      'strawberry': [
        'strawberry',
        'strawberries',
        'berry',
        'red berry',
        'fruit',
        'food',
      ],
      'grapes': [
        'grapes',
        'grape',
        'bunch of grapes',
        'seedless grapes',
        'fruit',
        'food',
      ],
      'lemon': ['lemon', 'lemons', 'yellow lemon', 'citrus', 'fruit', 'food'],
      'pizza': ['pizza', 'pizza slice', 'slice of pizza', 'pizzas'],
      'sandwich': [
        'sandwich',
        'sandwiches',
        'sub sandwich',
        'toast',
        'fast food',
      ],
      'cookie': ['cookie', 'cookies', 'biscuit', 'chocolate chip cookie'],
      'cake': ['cake', 'birthday cake', 'cupcake', 'cakes'],
      'hamburger': [
        'hamburger',
        'burger',
        'cheeseburger',
        'hamburgers',
        'fast food',
      ],
      'ice cream': ['ice cream', 'icecream', 'ice cream cone', 'gelato'],
      'watermelon': [
        'watermelon',
        'watermelons',
        'melon',
        'slice of watermelon',
        'fruit',
        'food',
      ],
      'pineapple': [
        'pineapple',
        'pineapples',
        'ananas',
        'tropical fruit',
        'fruit',
        'food',
      ],
      'mango': ['mango', 'mangoes', 'mangos', 'ripe mango', 'fruit', 'food'],
      'cucumber': [
        'cucumber',
        'cucumbers',
        'zucchini',
        'pickle',
        'vegetable',
        'food',
      ],
      'broccoli': [
        'broccoli',
        'cauliflower',
        'green broccoli',
        'broccoli florets',
        'vegetable',
        'food',
      ],
      'corn': [
        'corn',
        'sweet corn',
        'corn on the cob',
        'maize',
        'corncob',
        'vegetable',
        'food',
      ],
      'donut': ['donut', 'doughnut', 'donuts', 'doughnuts', 'bagel', 'food'],
      'bell pepper': [
        'bell pepper',
        'pepper',
        'capsicum',
        'sweet pepper',
        'bell peppers',
        'vegetable',
        'food',
      ],
      'avocado': [
        'avocado',
        'avocados',
        'guacamole',
        'avocado half',
        'fruit',
        'food',
      ],
      'pear': ['pear', 'pears', 'green pear', 'asian pear', 'fruit', 'food'],
      'cheese': [
        'cheese',
        'cheddar',
        'cheese slice',
        'mozzarella',
        'block of cheese',
        'food',
      ],
      'candy': ['candy', 'candies', 'sweets', 'lollipop', 'chocolate', 'food'],
      'pencil': [
        'pencil',
        'pencils',
        'lead pencil',
        'colored pencil',
        'writing implement',
      ],
      'ruler': [
        'ruler',
        'measuring tape',
        'straightedge',
        'yardstick',
        'scale ruler',
      ],
      'eraser': ['eraser', 'rubber', 'pencil eraser', 'rubber eraser'],
      'crayon': ['crayon', 'crayons', 'wax crayon', 'oil pastel'],
      'paper': [
        'paper',
        'sheet of paper',
        'paper sheet',
        'paper product',
        'white paper',
      ],
      'calculator': [
        'calculator',
        'calculators',
        'pocket calculator',
        'scientific calculator',
      ],
      'marker': ['marker', 'marker pen', 'felt tip pen', 'sharpie', 'markers'],
      'pencil case': [
        'pencil case',
        'pencil box',
        'pencil pouch',
        'pencil bag',
      ],
      'whiteboard': [
        'whiteboard',
        'white board',
        'dry erase board',
        'blackboard',
        'chalkboard',
      ],
      'highlighter': [
        'highlighter',
        'highlighter pen',
        'highlighters',
        'marker pen',
      ],
      'paper clip': ['paper clip', 'paperclip', 'binder clip', 'paper clips'],
      'dictionary': [
        'dictionary',
        'dictionaries',
        'reference book',
        'word book',
      ],
      'map': ['map', 'world map', 'road map', 'atlas', 'maps'],
      'sock': ['sock', 'socks', 'ankle sock', 'hosiery'],
      'hat': ['hat', 'hats', 'sun hat', 'fedora', 'beanie'],
      'jacket': ['jacket', 'coat', 'blazer', 'windbreaker', 'outerwear'],
      'shirt': [
        'shirt',
        'shirts',
        'tshirt',
        't shirt',
        'polo shirt',
        'blouse',
        'jersey',
        'polo',
      ],
      'pants': ['pants', 'trousers', 'jeans', 'slacks', 'denim'],
      'dress': ['dress', 'gown', 'frock', 'sundress', 'dresses'],
      'cap': ['cap', 'baseball cap', 'peaked cap', 'beanie'],
      'shorts': [
        'shorts',
        'short pants',
        'swim shorts',
        'board shorts',
        'bermuda shorts',
      ],
      'belt': [
        'belt',
        'leather belt',
        'waist belt',
        'buckle',
        'belts',
        'strap',
      ],
      'glove': ['glove', 'gloves', 'mitten', 'mittens', 'handwear'],
      'scarf': ['scarf', 'scarves', 'shawl', 'neckwear', 'muffler'],
      'umbrella': ['umbrella', 'umbrellas', 'parasol', 'sunshade', 'rain gear'],
      'sweater': [
        'sweater',
        'jumper',
        'pullover',
        'cardigan',
        'knitwear',
        'outerwear',
        'wool',
      ],
      'boots': [
        'boots',
        'boot',
        'rain boots',
        'hiking boots',
        'footwear',
        'shoe',
        'sneakers',
      ],
      'sandals': [
        'sandals',
        'sandal',
        'flip flops',
        'slippers',
        'slides',
        'shoe',
        'sneakers',
      ],
      'sunglasses': ['sunglasses', 'shades', 'dark glasses', 'eyewear'],
      'necklace': ['necklace', 'necklaces', 'chain', 'pendant', 'beads'],
      'hoodie': [
        'hoodie',
        'hooded sweatshirt',
        'sweatshirt',
        'hood',
        'hoodies',
        'outerwear',
      ],
      'monitor': [
        'monitor',
        'computer monitor',
        'display',
        'lcd screen',
        'screen',
        'computer',
      ],
      'remote control': ['remote control', 'remote', 'tv remote', 'clicker'],
      'speaker': [
        'speaker',
        'loudspeaker',
        'bluetooth speaker',
        'audio speaker',
        'sound box',
        'subwoofer',
      ],
      'fan': [
        'fan',
        'ceiling fan',
        'electric fan',
        'table fan',
        'pedestal fan',
        'blower',
      ],
      'camera': [
        'camera',
        'digital camera',
        'dslr',
        'photo camera',
        'camcorder',
      ],
      'tablet': [
        'tablet',
        'tablet computer',
        'ipad',
        'touchscreen',
        'e reader',
        'computer',
      ],
      'light bulb': [
        'light bulb',
        'lightbulb',
        'bulb',
        'led bulb',
        'lamp bulb',
      ],
      'washing machine': [
        'washing machine',
        'washer',
        'laundry machine',
        'clothes washer',
        'front loader',
      ],
      'game controller': [
        'game controller',
        'gamepad',
        'controller',
        'joystick',
        'video game controller',
      ],
      'printer': [
        'printer',
        'inkjet printer',
        'laser printer',
        'copier',
        'photocopier',
      ],
      'vacuum cleaner': [
        'vacuum cleaner',
        'vacuum',
        'hoover',
        'carpet cleaner',
        'floor cleaner',
      ],
      'hair dryer': ['hair dryer', 'hairdryer', 'blow dryer', 'hair drier'],
      'microphone': ['microphone', 'microphones', 'mike', 'karaoke microphone'],
      'radio': ['radio', 'transistor radio', 'radio set', 'boombox', 'stereo'],
      'rug': ['rug', 'carpet', 'area rug', 'floor mat', 'floor covering'],
      'curtains': ['curtains', 'curtain', 'drapes', 'window curtain', 'blinds'],
      'bookshelf': [
        'bookshelf',
        'bookcase',
        'shelf',
        'shelves',
        'bookshelves',
        'cabinetry',
      ],
      'armchair': [
        'armchair',
        'easy chair',
        'recliner',
        'lounge chair',
        'loveseat',
        'armrest',
      ],
      'coffee table': [
        'coffee table',
        'low table',
        'center table',
        'living room table',
      ],
      'flowerpot': [
        'flowerpot',
        'flower pot',
        'plant pot',
        'planter',
        'potted plant',
      ],
      'poster': ['poster', 'wall art', 'posters', 'wall poster', 'banner'],
      'doormat': ['doormat', 'door mat', 'welcome mat', 'entrance mat'],
      'cactus': [
        'cactus',
        'cacti',
        'cactuses',
        'succulent',
        'desert plant',
        'plant',
        'flora',
      ],
      'box': ['box', 'cardboard box', 'carton', 'package', 'crate'],
      'toothpaste': [
        'toothpaste',
        'tooth paste',
        'dental cream',
        'toothpaste tube',
      ],
      'sink': ['sink', 'wash basin', 'basin', 'kitchen sink', 'bathroom sink'],
      'hairbrush': ['hairbrush', 'hair brush', 'bristle brush', 'paddle brush'],
      'toilet': [
        'toilet',
        'toilet bowl',
        'lavatory',
        'commode',
        'bathroom fixture',
        'bathroom',
      ],
      'bathtub': ['bathtub', 'bath tub', 'bath', 'tub', 'bathtubs', 'bathroom'],
      'toilet paper': [
        'toilet paper',
        'toilet roll',
        'bathroom tissue',
        'tissue roll',
      ],
      'bucket': ['bucket', 'pail', 'water bucket', 'plastic bucket', 'buckets'],
      'trash can': [
        'trash can',
        'garbage can',
        'waste basket',
        'rubbish bin',
        'dustbin',
      ],
      'faucet': [
        'faucet',
        'water tap',
        'spigot',
        'water faucet',
        'plumbing fixture',
        'bathroom',
      ],
      'soap dispenser': [
        'soap dispenser',
        'dispenser',
        'pump bottle',
        'liquid soap',
        'hand soap',
        'bathroom',
      ],
      'laundry basket': [
        'laundry basket',
        'laundry hamper',
        'clothes basket',
        'hamper',
      ],
      'leaf': [
        'leaf',
        'leaves',
        'green leaf',
        'foliage',
        'plant leaf',
        'plant',
        'flora',
        'twig',
        'branch',
      ],
      'grass': [
        'grass',
        'lawn',
        'meadow',
        'turf',
        'green grass',
        'field',
        'prairie',
      ],
      'cloud': ['cloud', 'clouds', 'cloudy sky', 'cumulus', 'sky'],
      'rock': ['rock', 'rocks', 'stone', 'boulder', 'pebble'],
      'house': [
        'house',
        'home',
        'cottage',
        'villa',
        'residential building',
        'building',
        'roof',
      ],
      'road': ['road', 'street', 'highway', 'roadway', 'asphalt'],
      'bus': ['bus', 'school bus', 'coach', 'minibus', 'buses'],
      'truck': [
        'truck',
        'lorry',
        'pickup truck',
        'delivery truck',
        'trucks',
        'van',
        'vehicle',
      ],
      'boat': ['boat', 'ship', 'canoe', 'fishing boat', 'rowboat'],
      'airplane': ['airplane', 'aeroplane', 'plane', 'aircraft', 'jet'],
      'train': [
        'train',
        'locomotive',
        'railway train',
        'passenger train',
        'trains',
      ],
      'motorcycle': [
        'motorcycle',
        'motorbike',
        'scooter',
        'moped',
        'motorcycles',
      ],
      'fish': [
        'fish',
        'goldfish',
        'aquarium fish',
        'koi',
        'fishes',
        'aquarium',
        'pomacentridae',
      ],
      'horse': ['horse', 'pony', 'stallion', 'mare', 'horses'],
      'cow': ['cow', 'cattle', 'bull', 'calf', 'dairy cow', 'herd'],
      'chicken': ['chicken', 'hen', 'rooster', 'chickens', 'poultry', 'bird'],
      'rabbit': ['rabbit', 'bunny', 'hare', 'pet rabbit', 'rabbits', 'pet'],
      'duck': ['duck', 'ducks', 'duckling', 'mallard', 'waterfowl'],
      'sheep': ['sheep', 'lamb', 'ram', 'flock of sheep', 'herd'],
      'butterfly': ['butterfly', 'butterflies', 'moth', 'monarch butterfly'],
      'squirrel': ['squirrel', 'chipmunk', 'tree squirrel', 'squirrels'],
      'bench': ['bench', 'park bench', 'garden bench', 'outdoor bench'],
      'fence': ['fence', 'wooden fence', 'garden fence', 'railing', 'fences'],
      'mailbox': ['mailbox', 'letter box', 'postbox', 'post box', 'mail box'],
      'fountain': ['fountain', 'water fountain', 'fountains', 'water jet'],
      'ball': [
        'ball',
        'soccer ball',
        'tennis ball',
        'playground ball',
        'balls',
        'soccer',
        'softball',
      ],
      'teddy bear': [
        'teddy bear',
        'teddy',
        'stuffed toy',
        'stuffed animal',
        'plush toy',
        'plush',
      ],
      'doll': ['doll', 'dolls', 'toy doll', 'puppet', 'figurine', 'toy'],
      'balloon': ['balloon', 'balloons', 'party balloon', 'helium balloon'],
      'toy car': [
        'toy car',
        'toy vehicle',
        'model car',
        'miniature car',
        'toy',
        'miniature',
        'model',
      ],
      'basketball': ['basketball', 'basket ball', 'orange ball'],
      'puzzle': [
        'puzzle',
        'jigsaw puzzle',
        'jigsaw',
        'puzzle pieces',
        'puzzles',
        'toy',
      ],
      'guitar': [
        'guitar',
        'acoustic guitar',
        'electric guitar',
        'guitars',
        'ukulele',
        'musical instrument',
      ],
      'kite': ['kite', 'kites', 'flying kite', 'toy kite', 'paper kite'],
      'skateboard': ['skateboard', 'skate board', 'longboard', 'skateboards'],
      'piano': ['piano', 'grand piano', 'upright piano', 'pianos'],
      'drum': [
        'drum',
        'drums',
        'drum set',
        'snare drum',
        'percussion',
        'musical instrument',
      ],
      'helmet': [
        'helmet',
        'bike helmet',
        'bicycle helmet',
        'hard hat',
        'helmets',
      ],
      'building blocks': [
        'building blocks',
        'toy blocks',
        'building block',
        'blocks',
        'lego',
        'toy',
      ],
      'board game': [
        'board game',
        'boardgame',
        'game board',
        'tabletop game',
        'chess',
      ],
      'violin': [
        'violin',
        'fiddle',
        'violins',
        'string instrument',
        'musical instrument',
      ],
      'bed': ['bed', 'bunk bed', 'mattress', 'bed frame', 'bedroom'],
      'laptop': [
        'laptop',
        'notebook computer',
        'computer',
        'macbook',
        'netbook',
      ],
      'mouse': [
        'mouse',
        'computer mouse',
        'mice',
        'input device',
        'peripheral',
      ],
      'book': ['book', 'textbook', 'novel', 'paperback', 'hardcover'],
      'bag': ['bag', 'handbag', 'tote bag', 'purse', 'shopping bag'],
    };

    // Whole-word alias matching: "car" must not match "carrot", "pan" must
    // not match "pants", "pot" must not match "potato".
    final targetAliases = aliases[target];
    if (targetAliases != null) {
      final detectedStem = _stemPhrase(detected);
      for (final alias in targetAliases) {
        final aliasStem = _stemPhrase(alias);
        if (detectedStem == aliasStem ||
            ' $detectedStem '.contains(' $aliasStem ')) {
          return true;
        }
      }
    }

    return false;
  }

  /// Strips a simple plural "s" per word so "boots" == "boot", "keys" == "key".
  static String _stem(String word) {
    if (word.length > 4 && word.endsWith('ies')) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.length > 4 &&
        (word.endsWith('xes') ||
            word.endsWith('ches') ||
            word.endsWith('shes'))) {
      return word.substring(0, word.length - 2);
    }
    if (word.length > 3 && word.endsWith('s') && !word.endsWith('ss')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  static String _stemPhrase(String phrase) =>
      phrase.split(' ').map(_stem).join(' ');
}
