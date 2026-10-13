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

class PhotoVocabularyDictionary {
  static const Map<String, PhotoDictionaryEntry> dictionary = {
    // ─── 1. Electronics & Tech ──────────────────────────────────────────
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
      grammarTip:
          'Noun. Can be modified as "desktop computer" or "personal computer".',
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
      grammarTip:
          'Noun. Short for telephone. Can also be used as a verb: "I will phone him."',
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
      definition:
          'The flat surface of a device where images and text are displayed.',
      example: 'Staring at a bright screen all day can hurt your eyes.',
      grammarTip:
          'Noun. Often used in compounds like "touchscreen" or "widescreen".',
    ),
    'television': PhotoDictionaryEntry(
      ipa: '/ˈtel.ɪ.vɪʒ.ən/',
      definition: 'An electronic device with a screen for watching broadcasts and shows.',
      example: 'The children watched an educational cartoon on the television.',
      grammarTip: 'Noun. Often abbreviated as "TV". We say "watch television" without an article.',
    ),
    'tv': PhotoDictionaryEntry(
      ipa: '/ˌtiːˈviː/',
      definition: 'Informal short form for television.',
      example: 'Turn off the TV when you finish watching.',
      grammarTip: 'Noun. Always capitalized as TV. Plural is TVs.',
    ),
    'headphones': PhotoDictionaryEntry(
      ipa: '/ˈhed.fəʊnz/',
      definition: 'A pair of speakers worn over or in the ears for listening to audio privately.',
      example: 'He plugged in his headphones to listen to English podcasts.',
      grammarTip: 'Noun. Plural. Count them using "a pair of headphones".',
    ),
    'charger': PhotoDictionaryEntry(
      ipa: '/ˈtʃɑː.dʒər/',
      definition: 'A device used for recharging batteries in electronic gadgets.',
      example: 'I forgot my phone charger at home.',
      grammarTip: 'Noun. Countable. Use with prepositions: "plug into a charger".',
    ),

    // ─── 2. Furniture & Home ─────────────────────────────────────────────
    'desk': PhotoDictionaryEntry(
      ipa: '/desk/',
      definition:
          'A piece of furniture with a flat surface, used for working or studying.',
      example: 'She organized the papers on her wooden desk.',
      grammarTip: 'Noun. We usually say "sit at a desk", not "sit on a desk".',
    ),
    'chair': PhotoDictionaryEntry(
      ipa: '/tʃeər/',
      definition:
          'A separate seat for one person, typically with a back and four legs.',
      example: 'He pulled up a chair and joined the conversation.',
      grammarTip:
          'Noun. We say "sit in a chair" (with arms) or "sit on a chair" (without arms).',
    ),
    'table': PhotoDictionaryEntry(
      ipa: '/ˈteɪ.bəl/',
      definition: 'A piece of furniture with a flat top and one or more legs.',
      example: 'They gathered around the dining table for dinner.',
      grammarTip: 'Noun. We say "sit at the table".',
    ),
    'couch': PhotoDictionaryEntry(
      ipa: '/kaʊtʃ/',
      definition:
          'A long upholstered piece of furniture for several people to sit on.',
      example: 'We relaxed on the couch and watched a movie.',
      grammarTip: 'Noun. Synonymous with "sofa".',
    ),
    'sofa': PhotoDictionaryEntry(
      ipa: '/ˈsəʊ.fə/',
      definition: 'A comfortable seat with a back and arms for two or more people.',
      example: 'The cat curled up on the soft sofa cushion.',
      grammarTip: 'Noun. Countable. Plural is "sofas".',
    ),
    'cushion': PhotoDictionaryEntry(
      ipa: '/ˈkʊʃ.ən/',
      definition: 'A soft bag of cloth filled with feathers or foam, used on chairs or sofas.',
      example: 'She placed a decorative cushion behind her back for comfort.',
      grammarTip: 'Noun. Countable. Distinct from "pillow", which is mainly for beds.',
    ),
    'bed': PhotoDictionaryEntry(
      ipa: '/bed/',
      definition: 'A piece of furniture for sleep or rest.',
      example: 'I was so tired I went straight to bed.',
      grammarTip:
          'Noun. When referring to sleeping, we say "go to bed" (without "the").',
    ),
    'door': PhotoDictionaryEntry(
      ipa: '/dɔːr/',
      definition:
          'A hinged, sliding, or revolving barrier at the entrance to a room or building.',
      example: 'Please close the door behind you.',
      grammarTip: 'Noun. We say "open/close the door" or "knock on the door".',
    ),
    'window': PhotoDictionaryEntry(
      ipa: '/ˈwɪn.dəʊ/',
      definition:
          'An opening in a wall, fitted with glass to let in light and air.',
      example: 'She looked out the window at the falling snow.',
      grammarTip:
          'Noun. We say "look out the window" or "look through the window".',
    ),
    'mirror': PhotoDictionaryEntry(
      ipa: '/ˈmɪr.ər/',
      definition: 'A reflective surface made of glass that shows an image of whatever is before it.',
      example: 'He adjusted his tie while looking in the bathroom mirror.',
      grammarTip: 'Noun. We say "look in the mirror", not "look at the mirror".',
    ),
    'lamp': PhotoDictionaryEntry(
      ipa: '/læmp/',
      definition: 'A device for providing artificial light from an electrical bulb or flame.',
      example: 'She switched on the desk lamp to read her book.',
      grammarTip: 'Noun. We say "turn on/off the lamp" or "switch on the lamp".',
    ),
    'clock': PhotoDictionaryEntry(
      ipa: '/klɒk/',
      definition: 'An instrument to measure and indicate time, typically on a wall or shelf.',
      example: 'The wall clock ticked quietly in the library.',
      grammarTip: 'Noun. Clocks stay on walls or surfaces, while "watches" are worn on wrists.',
    ),
    'calendar': PhotoDictionaryEntry(
      ipa: '/ˈkæl.ɪn.dər/',
      definition: 'A chart or series of pages showing the days, weeks, and months of a year.',
      example: 'I marked the exam date on my wall calendar.',
      grammarTip: 'Noun. Spelled with "ar" at the end, not "er".',
    ),
    'picture frame': PhotoDictionaryEntry(
      ipa: '/ˈpɪk.tʃər freɪm/',
      definition: 'A border or rim made of wood or metal designed to hold and protect a picture.',
      example: 'She framed a family portrait in a silver picture frame.',
      grammarTip: 'Noun. Compound noun. Plural is "picture frames".',
    ),
    'vase': PhotoDictionaryEntry(
      ipa: '/vɑːz/',
      definition: 'A decorative container, usually made of glass or ceramic, for holding cut flowers.',
      example: 'He placed fresh flowers in a ceramic vase on the dining table.',
      grammarTip: 'Noun. Countable. Can hold water: "a vase of flowers".',
    ),

    // ─── 3. Plants & Nature ──────────────────────────────────────────────
    'plant': PhotoDictionaryEntry(
      ipa: '/plɑːnt/',
      definition: 'A living organism, such as trees, shrubs, herbs, and ferns.',
      example: 'Don\'t forget to water the plant while I am away.',
      grammarTip: 'Noun. Can also be a verb: "to plant a seed".',
    ),
    'houseplant': PhotoDictionaryEntry(
      ipa: '/ˈhaʊs.plɑːnt/',
      definition: 'A plant grown indoors for decoration in homes or offices.',
      example: 'This sunny windowsill is ideal for a leafy houseplant.',
      grammarTip: 'Noun. Compound noun formed from "house" and "plant".',
    ),
    'tree': PhotoDictionaryEntry(
      ipa: '/triː/',
      definition: 'A tall perennial plant with a woody trunk, branches, and leaves.',
      example: 'The birds built a nest high up in the oak tree.',
      grammarTip: 'Noun. Prepositions: "birds in a tree", "sit under a tree".',
    ),
    'flower': PhotoDictionaryEntry(
      ipa: '/flaʊ.ər/',
      definition: 'The seed-bearing part of a plant, consisting of reproductive organs and colorful petals.',
      example: 'She picked a bright yellow flower from the garden.',
      grammarTip: 'Noun. Countable: "a bunch of flowers" or "a bouquet of flowers".',
    ),

    // ─── 4. Food, Drink & Kitchenware ────────────────────────────────────
    'coffee': PhotoDictionaryEntry(
      ipa: '/ˈkɒf.i/',
      definition:
          'A hot drink made from the roasted and ground seeds of a tropical shrub.',
      example: 'I need a cup of hot coffee to wake up this morning.',
      grammarTip:
          'Noun. Uncountable in general ("I love coffee"), countable when ordering ("Two coffees, please").',
    ),
    'cup': PhotoDictionaryEntry(
      ipa: '/kʌp/',
      definition:
          'A small, bowl-shaped container for drinking from, typically having a handle.',
      example: 'She poured the tea into a porcelain cup.',
      grammarTip: 'Noun. Often used as a unit of measurement in recipes.',
    ),
    'coffee cup': PhotoDictionaryEntry(
      ipa: '/ˈkɒf.i kʌp/',
      definition: 'A cup designed specifically for serving hot coffee.',
      example: 'He set his ceramic coffee cup down on the saucer.',
      grammarTip: 'Noun. Compound noun. Plural is "coffee cups".',
    ),
    'mug': PhotoDictionaryEntry(
      ipa: '/mʌɡ/',
      definition:
          'A large cup, typically cylindrical with a handle and used without a saucer.',
      example: 'He drank hot chocolate from his favorite winter mug.',
      grammarTip: 'Noun. Usually used for hot drinks in informal settings.',
    ),
    'bottle': PhotoDictionaryEntry(
      ipa: '/ˈbɒt.əl/',
      definition:
          'A glass or plastic container with a narrow neck, used for storing drinks.',
      example: 'He brought a bottle of water to the gym.',
      grammarTip:
          'Noun. Commonly used with the preposition "of" (e.g., bottle of water).',
    ),
    'water': PhotoDictionaryEntry(
      ipa: '/ˈwɔː.tər/',
      definition:
          'A colorless, transparent liquid that forms seas, lakes, and rain.',
      example: 'It is important to drink plenty of water every day.',
      grammarTip:
          'Noun. Uncountable noun; do not say "a water" unless referring to a bottle.',
    ),
    'apple': PhotoDictionaryEntry(
      ipa: '/ˈæp.əl/',
      definition:
          'A round fruit with red, yellow, or green skin and firm white flesh.',
      example: 'She ate a crisp green apple for an afternoon snack.',
      grammarTip: 'Noun. Starts with a vowel sound, so use "an": "an apple".',
    ),
    'banana': PhotoDictionaryEntry(
      ipa: '/bəˈnɑː.nə/',
      definition: 'A long curved fruit with a yellow skin and soft sweet flesh.',
      example: 'He peeled a ripe banana and put slices on his cereal.',
      grammarTip: 'Noun. Countable. A group is called "a bunch of bananas".',
    ),
    'orange': PhotoDictionaryEntry(
      ipa: '/ˈɒr.ɪndʒ/',
      definition: 'A round citrus fruit with a tough bright reddish-yellow rind.',
      example: 'She squeezed fresh orange juice for breakfast.',
      grammarTip: 'Noun. Starts with a vowel sound: "an orange". Also an adjective for color.',
    ),
    'bread': PhotoDictionaryEntry(
      ipa: '/bred/',
      definition: 'A staple food made of flour, water, and yeast baked in an oven.',
      example: 'The baker took warm loaves of fresh bread out of the oven.',
      grammarTip: 'Noun. Uncountable. Count it using "a loaf of bread" or "a slice of bread".',
    ),
    'food': PhotoDictionaryEntry(
      ipa: '/fuːd/',
      definition:
          'Any nutritious substance that people or animals eat or drink.',
      example: 'The restaurant serves excellent Italian food.',
      grammarTip:
          'Noun. Usually uncountable. "Foods" is used only for distinct categories.',
    ),
    'spoon': PhotoDictionaryEntry(
      ipa: '/spuːn/',
      definition: 'An implement consisting of a small shallow bowl on a handle, used for eating or stirring.',
      example: 'He stirred sugar into his tea with a small spoon.',
      grammarTip: 'Noun. Countable. Preposition: "eat with a spoon".',
    ),
    'fork': PhotoDictionaryEntry(
      ipa: '/fɔːk/',
      definition: 'A piece of cutlery with two or more prongs used for picking up food.',
      example: 'Hold your knife in your right hand and your fork in your left.',
      grammarTip: 'Noun. Countable. Pair with knife: "knife and fork".',
    ),
    'knife': PhotoDictionaryEntry(
      ipa: '/naɪf/',
      definition: 'A cutting instrument with a sharp blade fastened to a handle.',
      example: 'Use a butter knife to spread jam on your toast.',
      grammarTip: 'Noun. Irregular plural: one knife, two "knives". The initial "k" is silent.',
    ),
    'plate': PhotoDictionaryEntry(
      ipa: '/pleɪt/',
      definition: 'A flat dish, typically circular, from which food is eaten or served.',
      example: 'She placed a warm sandwich on the ceramic plate.',
      grammarTip: 'Noun. Countable. Preposition: "food on a plate".',
    ),
    'bowl': PhotoDictionaryEntry(
      ipa: '/bəʊl/',
      definition: 'A round, deep dish used especially for food or liquid like soup or cereal.',
      example: 'He ate a warm bowl of vegetable soup for lunch.',
      grammarTip: 'Noun. Preposition: "food in a bowl". Unit: "a bowl of soup".',
    ),
    'pan': PhotoDictionaryEntry(
      ipa: '/pæn/',
      definition: 'A metal container used for cooking food, especially on a stove.',
      example: 'Heat olive oil in the frying pan before adding garlic.',
      grammarTip: 'Noun. Often called "frying pan" or "skillet".',
    ),
    'pot': PhotoDictionaryEntry(
      ipa: '/pɒt/',
      definition: 'A deep round container used for cooking stews, soups, or boiling water.',
      example: 'The chef stirred the pasta in a large stainless steel pot.',
      grammarTip: 'Noun. Deeper than a pan. Can also mean "flowerpot".',
    ),
    'oven': PhotoDictionaryEntry(
      ipa: '/ˈʌv.ən/',
      definition: 'An enclosed compartment used for baking and roasting food.',
      example: 'Bake the pizza in the oven at two hundred degrees.',
      grammarTip: 'Noun. Starts with a vowel sound: "an oven". Preposition: "bake in an oven".',
    ),
    'refrigerator': PhotoDictionaryEntry(
      ipa: '/rɪˈfrɪdʒ.ər.eɪ.tər/',
      definition: 'An appliance that keeps food and drinks cool and fresh.',
      example: 'Keep the milk cold inside the refrigerator.',
      grammarTip: 'Noun. Often shortened to "fridge" in everyday English.',
    ),
    'fridge': PhotoDictionaryEntry(
      ipa: '/frɪdʒ/',
      definition: 'A common informal word for refrigerator.',
      example: 'Is there any orange juice left in the fridge?',
      grammarTip: 'Noun. Notice the "d" in fridge, which is absent in refrigerator.',
    ),
    'microwave': PhotoDictionaryEntry(
      ipa: '/ˈmaɪ.krə.weɪv/',
      definition: 'An appliance that cooks or reheats food quickly using electromagnetic radiation.',
      example: 'You can reheat your soup in the microwave for two minutes.',
      grammarTip: 'Noun. Can also be a verb: "microwave the food for one minute".',
    ),
    'toaster': PhotoDictionaryEntry(
      ipa: '/ˈtəʊ.stər/',
      definition: 'An electrical appliance for toasting bread slices.',
      example: 'Two golden slices of toast popped out of the toaster.',
      grammarTip: 'Noun. Countable. Derived from the verb "toast".',
    ),
    'blender': PhotoDictionaryEntry(
      ipa: '/ˈblen.dər/',
      definition: 'An electric kitchen machine with sharp blades for pureeing or mixing liquids.',
      example: 'She blended strawberries and yogurt into a fruit smoothie.',
      grammarTip: 'Noun. Countable. Derived from the verb "blend".',
    ),

    // ─── 5. Personal Items & Bathroom ────────────────────────────────────
    'backpack': PhotoDictionaryEntry(
      ipa: '/ˈbæk.pæk/',
      definition: 'A bag carried on the back, with two shoulder straps.',
      example: 'He packed his textbooks and water bottle into his backpack.',
      grammarTip: 'Noun. Compound noun from "back" and "pack". Also called a "rucksack".',
    ),
    'bag': PhotoDictionaryEntry(
      ipa: '/bæɡ/',
      definition:
          'A flexible container with an opening at the top, used for carrying things.',
      example: 'She packed her bag the night before the trip.',
      grammarTip: 'Noun. Can refer to a purse, backpack, or shopping bag.',
    ),
    'wallet': PhotoDictionaryEntry(
      ipa: '/ˈwɒl.ɪt/',
      definition: 'A pocket-sized, flat folding case for holding money and cards.',
      example: 'He kept his identification card safely inside his leather wallet.',
      grammarTip: 'Noun. Countable. Preposition: "keep money in a wallet".',
    ),
    'keys': PhotoDictionaryEntry(
      ipa: '/kiːz/',
      definition: 'Small pieces of metal shaped to open locks, doors, or start vehicles.',
      example: 'Don\'t forget your house keys on the kitchen counter.',
      grammarTip: 'Noun. Plural. A collection is called "a bunch of keys" or "a set of keys".',
    ),
    'watch': PhotoDictionaryEntry(
      ipa: '/wɒtʃ/',
      definition:
          'A small timepiece worn typically on a strap on one\'s wrist.',
      example: 'She checked her watch and realized she was late.',
      grammarTip:
          'Noun. Can also be a verb meaning to observe: "to watch a movie".',
    ),
    'glasses': PhotoDictionaryEntry(
      ipa: '/ˈɡlɑː.sɪz/',
      definition:
          'A pair of lenses set in a frame resting on the nose and ears, used to correct vision.',
      example: 'He took off his reading glasses and wiped the lenses.',
      grammarTip: 'Noun. Always plural. Use "a pair of glasses" to count them.',
    ),
    'shoe': PhotoDictionaryEntry(
      ipa: '/ʃuː/',
      definition: 'A covering for the foot, typically made of leather, rubber, or cloth.',
      example: 'He tied his running shoe before going for a jog.',
      grammarTip: 'Noun. Usually counted as "a pair of shoes". Plural is "shoes".',
    ),
    'shoes': PhotoDictionaryEntry(
      ipa: '/ʃuːz/',
      definition: 'Footwear worn to protect and comfort the human foot.',
      example: 'Please take off your shoes before entering the house.',
      grammarTip: 'Noun. Plural of shoe. Counted with "pairs of shoes".',
    ),
    'toothbrush': PhotoDictionaryEntry(
      ipa: '/ˈtuːθ.brʌʃ/',
      definition: 'A small brush with a long handle used for cleaning teeth.',
      example: 'Dentists recommend replacing your toothbrush every three months.',
      grammarTip: 'Noun. Compound noun: singular "tooth" + "brush", even though you brush multiple teeth.',
    ),
    'towel': PhotoDictionaryEntry(
      ipa: '/taʊ.əl/',
      definition: 'A piece of thick absorbent cloth used for drying the body or surfaces.',
      example: 'Dry your hands with the clean cotton towel hanging by the sink.',
      grammarTip: 'Noun. Countable: "bath towel", "hand towel", "beach towel".',
    ),
    'soap': PhotoDictionaryEntry(
      ipa: '/səʊp/',
      definition: 'A substance used with water for washing and cleaning the body.',
      example: 'Always wash your hands thoroughly with soap and warm water.',
      grammarTip: 'Noun. Uncountable in general. Count it as "a bar of soap".',
    ),
    'shampoo': PhotoDictionaryEntry(
      ipa: '/ʃæmˈpuː/',
      definition: 'A liquid cosmetic preparation for washing the hair.',
      example: 'Lather the shampoo into your hair and rinse thoroughly.',
      grammarTip: 'Noun. Uncountable liquid. Count it as "a bottle of shampoo". Can also be a verb.',
    ),
    'comb': PhotoDictionaryEntry(
      ipa: '/kəʊm/',
      definition: 'A strip of plastic or wood with a row of teeth, used for untangling hair.',
      example: 'She ran a fine-toothed comb through her long hair.',
      grammarTip: 'Noun. Silent "b" at the end. Can also be a verb: "comb your hair".',
    ),

    // ─── 6. Stationery & Tools ───────────────────────────────────────────
    'pen': PhotoDictionaryEntry(
      ipa: '/pen/',
      definition: 'An instrument for writing or drawing with liquid ink.',
      example: 'Could I borrow a blue pen to sign this form?',
      grammarTip: 'Noun. We say "write with a pen" or "write in pen".',
    ),
    'notebook': PhotoDictionaryEntry(
      ipa: '/ˈnəʊt.bʊk/',
      definition:
          'A book with blank or ruled pages for writing notes, lists, or journaling.',
      example: 'He jotted down new English vocabulary words in his notebook.',
      grammarTip: 'Noun. Compound noun formed from "note" and "book".',
    ),
    'book': PhotoDictionaryEntry(
      ipa: '/bʊk/',
      definition:
          'A written or printed work consisting of pages bound together.',
      example: 'She sat by the window and read an inspiring book.',
      grammarTip:
          'Noun. Can also be a verb meaning to reserve: "to book a ticket".',
    ),
    'scissors': PhotoDictionaryEntry(
      ipa: '/ˈsɪz.əz/',
      definition: 'An instrument used for cutting paper, cloth, or hair, having two pivoted blades.',
      example: 'Use blunt-ended safety scissors to cut out the paper shapes.',
      grammarTip: 'Noun. Always plural. Count with "a pair of scissors".',
    ),
    'tape': PhotoDictionaryEntry(
      ipa: '/teɪp/',
      definition: 'A narrow strip of material with an adhesive backing used for fastening things.',
      example: 'She sealed the cardboard box with clear packing tape.',
      grammarTip: 'Noun. Uncountable. Count as "a roll of tape" or "a piece of tape".',
    ),
    'stapler': PhotoDictionaryEntry(
      ipa: '/ˈsteɪ.plər/',
      definition: 'A mechanical device that joins sheets of paper together with wire staples.',
      example: 'Fasten the report pages together with the desk stapler.',
      grammarTip: 'Noun. The small metal fasteners are called "staples".',
    ),

    // ─── 7. Vehicles & Transportation ────────────────────────────────────
    'car': PhotoDictionaryEntry(
      ipa: '/kɑːr/',
      definition:
          'A four-wheeled motor vehicle used for passenger transportation.',
      example: 'We parked our car in the designated space outside the store.',
      grammarTip: 'Noun. We say "get into a car", "get out of a car", or "drive a car".',
    ),
    'bicycle': PhotoDictionaryEntry(
      ipa: '/ˈbaɪ.sɪ.kəl/',
      definition:
          'A human-powered vehicle consisting of two wheels attached to a frame.',
      example: 'She rides her bicycle to school every morning along the bike lane.',
      grammarTip: 'Noun. Often shortened to "bike". We say "ride a bicycle".',
    ),
    'bike': PhotoDictionaryEntry(
      ipa: '/baɪk/',
      definition: 'A common informal word for a bicycle or motorcycle.',
      example: 'He locked his bike to the metal bike rack.',
      grammarTip: 'Noun. Preposition: "ride on a bike" or "travel by bike".',
    ),

    // ─── 8. Animals & People ─────────────────────────────────────────────
    'dog': PhotoDictionaryEntry(
      ipa: '/dɒɡ/',
      definition:
          'A domesticated carnivorous mammal known for loyalty and keen senses.',
      example: 'He taught his dog to sit and give a paw.',
      grammarTip: 'Noun. Young dogs are called "puppies". Sound: dogs "bark".',
    ),
    'cat': PhotoDictionaryEntry(
      ipa: '/kæt/',
      definition: 'A small domesticated feline animal kept as a beloved pet.',
      example: 'The cat purred softly while resting in the warm sunlight.',
      grammarTip: 'Noun. Young cats are called "kittens". Sound: cats "meow" or "purr".',
    ),
    'bird': PhotoDictionaryEntry(
      ipa: '/bɜːd/',
      definition:
          'A warm-blooded egg-laying animal with feathers, wings, and a beak.',
      example: 'A colorful songbird perched on the tree branch.',
      grammarTip: 'Noun. The collective noun for birds is a "flock of birds".',
    ),
    'person': PhotoDictionaryEntry(
      ipa: '/ˈpɜː.sən/',
      definition: 'A human being regarded as an individual.',
      example: 'There was only one other person in the waiting room.',
      grammarTip: 'Noun. The standard plural is "people", not "persons".',
    ),
    'man': PhotoDictionaryEntry(
      ipa: '/mæn/',
      definition: 'An adult male human being.',
      example: 'The man greeted his neighbor with a friendly smile.',
      grammarTip: 'Noun. Irregular plural: one man, two "men".',
    ),
    'woman': PhotoDictionaryEntry(
      ipa: '/ˈwʊm.ən/',
      definition: 'An adult female human being.',
      example: 'The woman led the science workshop with great enthusiasm.',
      grammarTip: 'Noun. Irregular plural: one woman, two "women" (pronounced /ˈwɪm.ɪn/).',
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
    if (key.endsWith('s') && dictionary.containsKey(key.substring(0, key.length - 1))) {
      return dictionary[key.substring(0, key.length - 1)]!;
    }
    if (key.endsWith('es') && dictionary.containsKey(key.substring(0, key.length - 2))) {
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
      generatedGrammarTip = 'Grammar: Compound noun (formed by combining words).';
    } else if (key.endsWith('s') && key.length > 3) {
      generatedGrammarTip = 'Grammar: Plural noun ending in "s". Use plural verbs.';
    } else if (key.endsWith('ing')) {
      generatedGrammarTip = 'Grammar: Word ending in "-ing" (gerund or action form).';
    } else if (key.endsWith('y')) {
      generatedGrammarTip =
          'Grammar: Ends in "-y". Change "y" to "-ies" for plural form.';
    } else if (key.length >= 8) {
      generatedGrammarTip = 'Grammar: Multi-syllable noun. Practice pronouncing each part.';
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
      'coffee cup': ['coffee cup', 'cup', 'mug', 'coffee', 'teacup', 'cappuccino', 'drinkware'],
      'mug': ['mug', 'cup', 'coffee cup', 'coffee mug', 'teacup'],
      'cup': ['cup', 'coffee cup', 'mug', 'teacup', 'glass'],
      'keyboard': ['keyboard', 'computer keyboard', 'keypad', 'keys'],
      'houseplant': ['houseplant', 'house plant', 'plant', 'flowerpot', 'pot plant', 'flora', 'potted plant'],
      'backpack': ['backpack', 'pack', 'bag', 'rucksack', 'knapsack', 'schoolbag'],
      'chair': ['chair', 'armchair', 'seat', 'furniture', 'stool', 'office chair'],
      'desk': ['desk', 'office desk', 'writing desk', 'table', 'study desk', 'workstation'],
      'shoe': ['shoe', 'shoes', 'footwear', 'sneaker', 'sneakers', 'boot', 'boots', 'athletic shoe'],
      'watch': ['watch', 'wrist watch', 'wristwatch', 'timepiece', 'clock'],
      'spoon': ['spoon', 'teaspoon', 'tablespoon', 'cutlery', 'flatware', 'silverware'],
      'glasses': ['glasses', 'spectacles', 'eyewear', 'sunglasses', 'eyeglasses', 'goggles'],
      'pen': ['pen', 'ballpoint pen', 'fountain pen', 'marker', 'writing implement', 'pencil', 'stationery'],
      'notebook': ['notebook', 'book', 'notepad', 'journal', 'diary', 'spiral notebook'],
      'bottle': ['bottle', 'water bottle', 'plastic bottle', 'glass bottle', 'flask'],
      'lamp': ['lamp', 'table lamp', 'desk lamp', 'lantern', 'lighting', 'light fixture'],
      'television': ['television', 'tv', 'screen', 'monitor', 'display', 'flat screen'],
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
      'phone': ['phone', 'mobile phone', 'cell phone', 'smartphone', 'telephone', 'cellular'],
      'headphones': ['headphones', 'headphone', 'earphones', 'headset', 'earbuds'],
      'charger': ['charger', 'battery charger', 'power adapter', 'cable', 'usb charger'],
      'scissors': ['scissors', 'shears', 'clippers'],
      'tape': ['tape', 'adhesive tape', 'duct tape', 'scotch tape'],
      'stapler': ['stapler', 'staples', 'office stapler'],
      'clock': ['clock', 'wall clock', 'alarm clock', 'timepiece'],
      'calendar': ['calendar', 'schedule', 'wall calendar'],
      'picture frame': ['picture frame', 'frame', 'photo frame', 'painting', 'picture', 'artwork'],
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
    };

    if (aliases.containsKey(target)) {
      final targetAliases = aliases[target]!;
      if (targetAliases.any((alias) =>
          detected == alias ||
          detected.contains(alias) ||
          alias.contains(detected))) {
        return true;
      }
    }

    // Word token matching: if any multi-word target token matches a detected token
    final targetWords = target.split(' ');
    final detectedWords = detected.split(' ');
    for (final tw in targetWords) {
      if (tw.length <= 2) continue; // Skip trivial words like "in", "a"
      for (final dw in detectedWords) {
        if (dw.length <= 2) continue;
        if (tw == dw || tw == '${dw}s' || dw == '${tw}s') {
          return true;
        }
      }
    }

    return false;
  }
}
