import 'dart:io';
import 'dart:convert';
import 'dart:math';

void main() {
  final List<Map<String, dynamic>> categoryPool = [
    {"buckets": ["Space", "Deep Sea"], "options": [["Nebula", "Galaxy", "Pulsar", "Quasar", "Asteroid", "Supernova", "Black Hole", "Comet"], ["Coral", "Trench", "Abyss", "Plankton", "Anemone", "Hydrothermal", "Bioluminescence", "Reef"]]},
    {"buckets": ["Fruits", "Vegetables"], "options": [["Mango", "Kiwi", "Peach", "Pomegranate", "Blueberry", "Nectarine", "Papaya", "Fig"], ["Broccoli", "Spinach", "Carrot", "Zucchini", "Eggplant", "Asparagus", "Kale", "Radish"]]},
    {"buckets": ["Mammals", "Reptiles"], "options": [["Dolphin", "Elephant", "Tiger", "Platypus", "Kangaroo", "Walrus", "Cheetah", "Sloth"], ["Iguana", "Python", "Turtle", "Crocodile", "Chameleon", "Gecko", "Komodo", "Viper"]]},
    {"buckets": ["Hardware", "Software"], "options": [["Processor", "Motherboard", "RAM", "Graphics Card", "Heatsink", "Power Supply", "Transistor", "Circuit"], ["Compiler", "Database", "Browser", "Algorithm", "Middleware", "Operating System", "Firmware", "Application"]]},
    {"buckets": ["String Instruments", "Wind Instruments"], "options": [["Cello", "Violin", "Harp", "Guitar", "Double Bass", "Mandolin", "Banjo", "Viola"], ["Flute", "Oboe", "Clarinet", "Saxophone", "Trumpet", "Trombone", "Bassoon", "Harmonica"]]},
    {"buckets": ["Warm Colors", "Cool Colors"], "options": [["Crimson", "Amber", "Scarlet", "Vermillion", "Saffron", "Coral", "Maroon", "Gold"], ["Azure", "Emerald", "Indigo", "Sapphire", "Turquoise", "Teal", "Violet", "Cyan"]]},
    {"buckets": ["Indoor Sports", "Outdoor Sports"], "options": [["Badminton", "Bowling", "Fencing", "Billiards", "Squash", "Table Tennis", "Gymnastics", "Darts"], ["Surfing", "Cycling", "Archery", "Kayaking", "Hiking", "Skiing", "Rowing", "Golf"]]},
    {"buckets": ["Inner Planets", "Outer Planets"], "options": [["Mercury", "Venus", "Mars", "Earth"], ["Jupiter", "Saturn", "Neptune", "Uranus", "Pluto (Dwarf)"]]},
    {"buckets": ["Kitchen Tools", "Office Supplies"], "options": [["Whisk", "Spatula", "Grater", "Colander", "Ladle", "Peeler", "Rolling Pin", "Tongs"], ["Stapler", "Binder", "Scanner", "Paperclip", "Projector", "Calculator", "Highlighter", "Envelope"]]},
    {"buckets": ["Land Transport", "Air Transport"], "options": [["Locomotive", "Scooter", "Tractor", "Motorcycle", "Ambulance", "Rickshaw", "Unicycle", "Truck"], ["Glider", "Dirigible", "Biplane", "Helicopter", "Jet", "Zeppelin", "Parachute", "Spaceship"]]},
    {"buckets": ["Summer Clothing", "Winter Clothing"], "options": [["Sandals", "Swimsuit", "Shorts", "Tank Top", "Flip-flops", "Sun Hat", "Sarong", "Vest"], ["Parka", "Mittens", "Scarf", "Overcoat", "Beanie", "Snow Boots", "Ear Muffs", "Trench Coat"]]},
    {"buckets": ["Nouns", "Verbs"], "options": [["Cathedral", "Symphony", "Diamond", "Landscape", "Architecture", "Evolution", "Satellite", "Philosophy"], ["Sprint", "Calculate", "Analyze", "Simplify", "Illustrate", "Negotiate", "Generate", "Synthesize"]]},
    {"buckets": ["Living Room", "Bedroom"], "options": [["Ottoman", "Fireplace", "Sofa", "Chandelier", "Coffee Table", "Armchair", "Recliner", "Rug"], ["Wardrobe", "Mattress", "Nightstand", "Duvet", "Pillowcase", "Dresser", "Alarm Clock", "Headboard"]]},
    {"buckets": ["Positive Emotions", "Negative Emotions"], "options": [["Euphoria", "Serenity", "Gratitude", "Optimism", "Contentment", "Elation", "Affection", "Hope"], ["Anguish", "Dread", "Resentment", "Melancholy", "Hostility", "Envy", "Sorrow", "Despair"]]},
    {"buckets": ["Natural Materials", "Synthetic Materials"], "options": [["Marble", "Wool", "Bamboo", "Cotton", "Silk", "Granite", "Clay", "Leather"], ["Polyester", "Acrylic", "Nylon", "Plastic", "Neoprene", "Teflon", "Silicone", "PVC"]]},
    {"buckets": ["Medical Jobs", "Creative Jobs"], "options": [["Surgeon", "Pharmacist", "Pediatrician", "Neurologist", "Optometrist", "Dentist", "Nurse", "Radiologist"], ["Illustrator", "Copywriter", "Sculptor", "Composer", "Choreographer", "Director", "Animator", "Architect"]]},
    {"buckets": ["Insects", "Birds"], "options": [["Beetle", "Locust", "Cricket", "Dragonfly", "Moth", "Termite", "Cicada", "Wasp"], ["Falcon", "Sparrow", "Penguin", "Eagle", "Owl", "Parrot", "Swan", "Flamingo"]]},
    {"buckets": ["Shapes", "Colors"], "options": [["Hexagon", "Rhombus", "Ellipse", "Trapezoid", "Cylinder", "Sphere", "Pyramid", "Pentagon"], ["Turquoise", "Magenta", "Beige", "Lavender", "Charcoal", "Ivory", "Crimson", "Ochre"]]},
    {"buckets": ["Countries", "Cities"], "options": [["Argentina", "Portugal", "Vietnam", "Egypt", "Canada", "Norway", "Kenya", "Thailand"], ["Tokyo", "Berlin", "Nairobi", "Sydney", "Paris", "London", "Cairo", "Moscow"]]},
    {"buckets": ["Hobbies", "Chores"], "options": [["Pottery", "Photography", "Gardening", "Painting", "Knitting", "Cooking", "Fishing", "Hiking"], ["Laundry", "Mopping", "Dusting", "Ironing", "Vacuuming", "Sweeping", "Scrubbing", "Mowing"]]},
    {"buckets": ["Dairy Products", "Grains"], "options": [["Yogurt", "Cheddar", "Butter", "Cheese", "Cream", "Mozzarella", "Milk", "Ghee"], ["Barley", "Quinoa", "Oatmeal", "Rice", "Wheat", "Millet", "Rye", "Buckwheat"]]},
    {"buckets": ["European Countries", "Asian Countries"], "options": [["Finland", "Greece", "Austria", "Italy", "Spain", "France", "Germany", "Sweden"], ["Thailand", "Malaysia", "Japan", "Vietnam", "Korea", "China", "India", "Indonesia"]]},
    {"buckets": ["Furniture", "Appliances"], "options": [["Bookshelf", "Armchair", "Cabinet", "Desk", "Dining Table", "Bench", "Stool", "Sideboard"], ["Refrigerator", "Microwave", "Dishwasher", "Toaster", "Washing Machine", "Blender", "Oven", "Iron"]]},
    {"buckets": ["Time Units", "Length Units"], "options": [["Decade", "Century", "Millennium", "Minute", "Hour", "Second", "Day", "Week"], ["Kilometer", "Millimeter", "Nautical Mile", "Meter", "Centimeter", "Inch", "Yard", "Foot"]]},
    {"buckets": ["Precious Metals", "Gemstones"], "options": [["Platinum", "Palladium", "Silver", "Gold", "Rhodium", "Iridium", "Osmium", "Ruthenium"], ["Sapphire", "Emerald", "Topaz", "Ruby", "Diamond", "Amethyst", "Opal", "Jade"]]},
    {"buckets": ["Herbivores", "Carnivores"], "options": [["Giraffe", "Gazelle", "Zebra", "Elephant", "Rabbit", "Deer", "Cow", "Horse"], ["Leopard", "Cheetah", "Hyena", "Lion", "Wolf", "Shark", "Eagle", "Tiger"]]},
    {"buckets": ["Ancient History", "Modern History"], "options": [["Pharaoh", "Gladiator", "Ziggurat", "Hieroglyphs", "Scribe", "Empire", "Dynasty", "Papyrus"], ["Internet", "Aviation", "Nuclear Power", "Smartphone", "Spacecraft", "Robotics", "Genetics", "Nano-tech"]]},
    {"buckets": ["Mythology", "Science Fiction"], "options": [["Centaur", "Phoenix", "Chimera", "Dragon", "Unicorn", "Griffin", "Kraken", "Cyclops"], ["Android", "Starship", "Teleportation", "Cyborg", "Time Travel", "Laser", "Alien", "Clone"]]},
    {"buckets": ["Musical Genres", "Art Styles"], "options": [["Jazz", "Reggae", "Classical", "Rock", "Pop", "Blues", "Country", "Hip-hop"], ["Impressionism", "Cubism", "Surrealism", "Renaissance", "Baroque", "Modernism", "Abstract", "Gothic"]]},
    {"buckets": ["Desserts", "Beverages"], "options": [["Tiramisu", "Brownie", "Macaron", "Cheesecake", "Pudding", "Sorbet", "Tart", "Custard"], ["Espresso", "Smoothie", "Lemonade", "Tea", "Coffee", "Juice", "Soda", "Cider"]]},
    {"buckets": ["Oceans", "Deserts"], "options": [["Pacific", "Atlantic", "Indian", "Arctic", "Antarctic"], ["Sahara", "Gobi", "Mojave", "Atacama", "Kalahari", "Arabian", "Thar", "Gobi"]]},
    {"buckets": ["Trees", "Flowers"], "options": [["Oak", "Pine", "Maple", "Birch", "Cedar", "Willow", "Cherry", "Banyan"], ["Rose", "Tulip", "Daisy", "Lily", "Sun-flower", "Orchid", "Lavender", "Poppy"]]},
    {"buckets": ["Metals", "Gases"], "options": [["Iron", "Copper", "Gold", "Steel", "Aluminum", "Lead", "Zinc", "Nickel"], ["Oxygen", "Helium", "Neon", "Hydrogen", "Nitrogen", "Argon", "Carbon Dioxide", "Xenon"]]}
  ];

  final Random random = Random();
  
  // Total questions to generate: 600 (3 per level * 200 levels)
  int totalQuests = 600;
  Set<String> usedSets = {};

  for (int batch = 0; batch < 20; batch++) {
    int startLevel = batch * 10 + 1;
    int endLevel = (batch + 1) * 10;
    String fileName = "topicVocab_${startLevel}_${endLevel}.json";
    
    List<Map<String, dynamic>> quests = [];
    
    for (int level = startLevel; level <= endLevel; level++) {
      for (int qNum = 1; qNum <= 3; qNum++) {
        Map<String, dynamic>? selectedQuest;
        
        // Try to generate a unique set
        while (selectedQuest == null) {
          final cat = categoryPool[random.nextInt(categoryPool.length)];
          final buckets = List<String>.from(cat['buckets']);
          final optionsPool = List<List<String>>.from(cat['options']);
          
          final List<String> currentOptions = [];
          String correctAnswer = "";
          
          // Select 3 random unique items from each bucket
          List<String> selectedItems = [];
          for (int i = 0; i < buckets.length; i++) {
            final bucketName = buckets[i];
            final pool = List<String>.from(optionsPool[i]);
            pool.shuffle(random);
            
            final count = min(3, pool.length);
            final items = pool.take(count).toList();
            items.sort(); // Sort for uniqueness checking
            
            currentOptions.addAll(items);
            selectedItems.addAll(items);
            
            if (correctAnswer.isNotEmpty) correctAnswer += " | ";
            correctAnswer += "$bucketName: ${items.join(', ')}";
          }
          
          // Uniqueness Key based on bucket name + sorted items
          selectedItems.sort();
          final uniquenessKey = "${buckets.join(',')}|${selectedItems.join(',')}";
          
          if (!usedSets.contains(uniquenessKey)) {
            usedSets.add(uniquenessKey);
            currentOptions.shuffle(random);
            
            selectedQuest = {
              "instruction": "Sort the data into category buckets.",
              "difficulty": (level / 50).ceil(),
              "subtype": "topicVocab",
              "interactionType": "sort",
              "topicBuckets": buckets,
              "options": currentOptions,
              "correctAnswer": correctAnswer,
              "hint": "Focus on the relationship between these items.",
              "explanation": "Categorization deepens vocabulary associations.",
              "id": "VOC_TOPICVOCAB_L${level}_Q$qNum",
              "xpReward": 10,
              "coinReward": 10,
              "visual_config": {
                "painter_type": "VocabNexusSync",
                "primary_color": "0xFF00FFD2"
              }
            };
          }
        }
        quests.add(selectedQuest);
      }
    }

    final fullJson = {
      "gameType": "topicVocab",
      "batchIndex": batch + 1,
      "levels": "$startLevel-$endLevel",
      "quests": quests
    };

    final File file = File('assets/curriculum/vocabulary/$fileName');
    file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(fullJson));
  }
  print("Generated 600 GUARANTEED unique topicVocab questions.");
}
