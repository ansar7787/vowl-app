class ScanDictionaryEntry {
  final String signCategory;
  final String meaning;
  final String realWorldTip;

  const ScanDictionaryEntry({
    required this.signCategory,
    required this.meaning,
    required this.realWorldTip,
  });
}

/// Dictionary and matching engine tailored specifically for real-world printed
/// English signs, notices, packaging, and menus scanned via OCR.
class ScanVocabularyDictionary {
  static const Map<String, ScanDictionaryEntry> dictionary = {
    // ─── Directions, Doors & Access ─────────────────────────────────────────
    'exit': ScanDictionaryEntry(
      signCategory: 'Safety & Direction Sign',
      meaning: 'A doorway or passage that leads out of a building or room.',
      realWorldTip: 'Look for glowing green or red signs above doors in public buildings.',
    ),
    'entrance': ScanDictionaryEntry(
      signCategory: 'Direction Sign',
      meaning: 'A door or gate where people enter a place.',
      realWorldTip: 'Often paired with "Welcome" or arrows indicating entry points.',
    ),
    'open': ScanDictionaryEntry(
      signCategory: 'Business Status Sign',
      meaning: 'Indicates the store, office, or facility is ready for customers.',
      realWorldTip: 'Usually hung in shop windows alongside opening business hours.',
    ),
    'closed': ScanDictionaryEntry(
      signCategory: 'Business Status Sign',
      meaning: 'Indicates the store or service is currently shut and not operating.',
      realWorldTip: 'Check the door sign for when the location will reopen.',
    ),
    'push': ScanDictionaryEntry(
      signCategory: 'Door Instruction',
      meaning: 'Apply forward physical force against the door to swing it open.',
      realWorldTip: 'Located near door handles; do not pull when it says push!',
    ),
    'pull': ScanDictionaryEntry(
      signCategory: 'Door Instruction',
      meaning: 'Grasp the handle and draw the door toward your body to open it.',
      realWorldTip: 'Usually found on doors with vertical bar handles.',
    ),
    'welcome': ScanDictionaryEntry(
      signCategory: 'Hospitality Sign',
      meaning: 'A warm greeting welcoming visitors into a venue or city.',
      realWorldTip: 'Commonly seen at hotel entryways, town borders, and shops.',
    ),
    'restroom': ScanDictionaryEntry(
      signCategory: 'Facility Sign',
      meaning: 'A public room containing sinks and toilets.',
      realWorldTip: 'Common in American English; paired with icons of men/women.',
    ),
    'toilet': ScanDictionaryEntry(
      signCategory: 'Facility Sign',
      meaning: 'A sanitary facility equipped with a water closet and washbasin.',
      realWorldTip: 'Commonly used across the UK, Europe, Australia, and Asia.',
    ),
    'washroom': ScanDictionaryEntry(
      signCategory: 'Facility Sign',
      meaning: 'A room with washing and toilet facilities.',
      realWorldTip: 'Especially standard in Canadian and business English.',
    ),
    'private': ScanDictionaryEntry(
      signCategory: 'Restriction Notice',
      meaning: 'Belonging to a particular person or group; not open to the general public.',
      realWorldTip: 'Do not enter rooms marked "Private" without explicit permission.',
    ),

    // ─── Safety, Caution & Emergency ────────────────────────────────────────
    'warning': ScanDictionaryEntry(
      signCategory: 'Public Safety Notice',
      meaning: 'A statement or sign advising of a potential danger or hazard ahead.',
      realWorldTip: 'Usually framed in bright yellow or orange with an exclamation symbol.',
    ),
    'danger': ScanDictionaryEntry(
      signCategory: 'High Hazard Notice',
      meaning: 'A warning of severe risk of physical harm or death.',
      realWorldTip: 'Take immediate precautions; stay away from electrical or chemical hazards.',
    ),
    'caution': ScanDictionaryEntry(
      signCategory: 'Safety Precaution',
      meaning: 'Care taken to avoid danger, accidents, or slips.',
      realWorldTip: 'Frequently seen on yellow folding cones reading "Caution: Wet Floor".',
    ),
    'stop': ScanDictionaryEntry(
      signCategory: 'Traffic & Action Sign',
      meaning: 'Come to a complete halt and look both ways before proceeding.',
      realWorldTip: 'Recognizable worldwide as a red octagon with bold white letters.',
    ),
    'emergency': ScanDictionaryEntry(
      signCategory: 'Urgent Response Sign',
      meaning: 'A serious, unexpected situation requiring immediate action.',
      realWorldTip: 'Found near emergency exits, fire alarms, and first-aid kits.',
    ),
    'fire': ScanDictionaryEntry(
      signCategory: 'Life Safety Sign',
      meaning: 'Related to fire equipment, fire escapes, or fire alarms.',
      realWorldTip: 'Directs to fire extinguishers, hoses, or emergency staircases.',
    ),
    'no smoking': ScanDictionaryEntry(
      signCategory: 'Prohibition Sign',
      meaning: 'Smoking tobacco or e-cigarettes is strictly forbidden in this area.',
      realWorldTip: 'Paired with a crossed-out red cigarette symbol.',
    ),
    'police': ScanDictionaryEntry(
      signCategory: 'Public Authority Sign',
      meaning: 'Identifies police stations, officers, or emergency help points.',
      realWorldTip: 'Often visible on emergency patrol vehicles and civic headquarters.',
    ),
    'hospital': ScanDictionaryEntry(
      signCategory: 'Medical Facility Sign',
      meaning: 'An institution providing medical treatment and nursing care.',
      realWorldTip: 'Marked with a bold "H" sign along roadways and building facades.',
    ),
    'pharmacy': ScanDictionaryEntry(
      signCategory: 'Healthcare Store',
      meaning: 'A retail store where medicines, health goods, and prescriptions are prepared.',
      realWorldTip: 'Often symbolized by a green cross in Europe and worldwide.',
    ),

    // ─── Retail, Commerce & Payments ────────────────────────────────────────
    'menu': ScanDictionaryEntry(
      signCategory: 'Dining Document',
      meaning: 'A list of food dishes and drinks available with corresponding prices.',
      realWorldTip: 'Displayed in restaurant windows, on tables, or via QR codes.',
    ),
    'receipt': ScanDictionaryEntry(
      signCategory: 'Purchase Record',
      meaning: 'A printed slip proving that money or goods were received.',
      realWorldTip: 'Keep your receipt for store returns, tax records, or warranty claims.',
    ),
    'sale': ScanDictionaryEntry(
      signCategory: 'Promotion Sign',
      meaning: 'An event where goods are sold at reduced promotional prices.',
      realWorldTip: 'Often features percentages like "50% Off" or "End of Season Sale".',
    ),
    'notice': ScanDictionaryEntry(
      signCategory: 'Official Announcement',
      meaning: 'A formal notification providing information or rules to the public.',
      realWorldTip: 'Posted on bulletin boards, shop windows, and apartment lobbies.',
    ),
    'store': ScanDictionaryEntry(
      signCategory: 'Commercial Venue',
      meaning: 'A retail establishment selling goods or services to customers.',
      realWorldTip: 'Can refer to grocery stores, clothing boutiques, or department stores.',
    ),
    'shop': ScanDictionaryEntry(
      signCategory: 'Commercial Venue',
      meaning: 'A retail outlet where goods are displayed for purchase.',
      realWorldTip: 'Widely used in British English for retail businesses of all sizes.',
    ),
    'market': ScanDictionaryEntry(
      signCategory: 'Commerce Area',
      meaning: 'An open square or hall where vendors display produce and goods.',
      realWorldTip: 'Look for farmers markets, street markets, and fresh food stalls.',
    ),
    'supermarket': ScanDictionaryEntry(
      signCategory: 'Grocery Store',
      meaning: 'A large self-service grocery store offering food and household supplies.',
      realWorldTip: 'Organized into aisles with shopping carts and checkout lanes.',
    ),
    'bank': ScanDictionaryEntry(
      signCategory: 'Financial Institution',
      meaning: 'An establishment that manages deposits, currency exchange, and loans.',
      realWorldTip: 'Essential for currency conversion and secure financial transactions.',
    ),
    'atm': ScanDictionaryEntry(
      signCategory: 'Automated Banking',
      meaning: 'Automated Teller Machine providing cash withdrawals and account balances.',
      realWorldTip: 'Look for the 3-letter acronym ATM outside banks and convenience stores.',
    ),
    'cash': ScanDictionaryEntry(
      signCategory: 'Payment Method',
      meaning: 'Money in the physical form of bills, notes, and coins.',
      realWorldTip: 'Some checkout counters post "Cash Only" or "No Cash" notices.',
    ),
    'credit': ScanDictionaryEntry(
      signCategory: 'Financial Account',
      meaning: 'Payment method allowing consumers to purchase goods and pay later.',
      realWorldTip: 'Found on credit card logos like Visa, Mastercard, and Amex.',
    ),
    'card': ScanDictionaryEntry(
      signCategory: 'Payment Device',
      meaning: 'A small plastic or metal bank card used for digital transactions.',
      realWorldTip: 'Often displayed as "Card Accepted" or "Insert / Tap Card".',
    ),
    'pay': ScanDictionaryEntry(
      signCategory: 'Transaction Action',
      meaning: 'To give money in exchange for goods, services, or transit.',
      realWorldTip: 'Found on checkout counters, parking meters, and online payment kiosks.',
    ),
    'free': ScanDictionaryEntry(
      signCategory: 'Price Notice',
      meaning: 'Provided without any charge, cost, or fee required.',
      realWorldTip: 'Seen on signs like "Free Wi-Fi", "Free Admission", or "Buy 1 Get 1 Free".',
    ),
    'discount': ScanDictionaryEntry(
      signCategory: 'Price Reduction',
      meaning: 'A deduction from the regular price of something.',
      realWorldTip: 'Look for student, senior, or seasonal discount notices.',
    ),
    'offer': ScanDictionaryEntry(
      signCategory: 'Promotional Deal',
      meaning: 'A temporary special deal or price discount presented to buyers.',
      realWorldTip: 'Look for "Special Offer" or "Limited Time Offer" banners.',
    ),
    'price': ScanDictionaryEntry(
      signCategory: 'Cost Information',
      meaning: 'The amount of money expected, required, or given in payment for something.',
      realWorldTip: 'Printed on price tags, menus, and shelf barcode labels.',
    ),
    'cost': ScanDictionaryEntry(
      signCategory: 'Financial Metric',
      meaning: 'An amount that has to be paid or spent to buy or obtain something.',
      realWorldTip: 'Look for signs displaying ticket costs or service fees.',
    ),
    'total': ScanDictionaryEntry(
      signCategory: 'Bill Summary',
      meaning: 'The final aggregate sum of all purchases including taxes.',
      realWorldTip: 'Printed at the very bottom of store receipts and restaurant bills.',
    ),
    'tax': ScanDictionaryEntry(
      signCategory: 'Government Fee',
      meaning: 'A compulsory financial charge imposed by government on sales.',
      realWorldTip: 'Receipts show VAT (Value Added Tax) or local sales tax line items.',
    ),
    'tip': ScanDictionaryEntry(
      signCategory: 'Gratuity',
      meaning: 'A sum of money given to someone as a reward for their service.',
      realWorldTip: 'Common in dining and hospitality; lines on bills often read "Gratuity/Tip".',
    ),
    'service': ScanDictionaryEntry(
      signCategory: 'Hospitality & Charge',
      meaning: 'Work done by hospitality staff, often included as a fee on bills.',
      realWorldTip: 'Check whether a "Service Charge Included" notice appears on the bill.',
    ),
    'included': ScanDictionaryEntry(
      signCategory: 'Billing Status',
      meaning: 'Contained as part of a whole condition or package price.',
      realWorldTip: 'Seen as "Tax Included" or "Breakfast Included with Room".',
    ),
    'excluded': ScanDictionaryEntry(
      signCategory: 'Billing Status',
      meaning: 'Not included in the listed price and requiring an additional fee.',
      realWorldTip: 'Notice lines like "Taxes Excluded" to avoid billing surprises.',
    ),

    // ─── Meals, Food & Beverages ────────────────────────────────────────────
    'breakfast': ScanDictionaryEntry(
      signCategory: 'Meal Schedule',
      meaning: 'The first meal of the day, typically eaten in the morning.',
      realWorldTip: 'Look for hotel breakfast hours such as "Breakfast: 7:00 AM – 10:30 AM".',
    ),
    'lunch': ScanDictionaryEntry(
      signCategory: 'Meal Schedule',
      meaning: 'A meal eaten in the middle of the day.',
      realWorldTip: 'Cafes frequently advertise "Lunch Specials" from 12:00 PM to 2:00 PM.',
    ),
    'dinner': ScanDictionaryEntry(
      signCategory: 'Meal Schedule',
      meaning: 'The main meal of the day, taken either in the middle or evening.',
      realWorldTip: 'Restaurant dinner menus often feature evening entrees and specials.',
    ),
    'drinks': ScanDictionaryEntry(
      signCategory: 'Beverage Section',
      meaning: 'Liquids intended for human consumption, hot or cold.',
      realWorldTip: 'Found as a header on menus for sodas, teas, coffees, and juices.',
    ),
    'water': ScanDictionaryEntry(
      signCategory: 'Essential Beverage',
      meaning: 'Pure transparent liquid essential for hydration.',
      realWorldTip: 'Look for "Drinking Water", "Tap Water", or "Bottled Mineral Water".',
    ),
    'coffee': ScanDictionaryEntry(
      signCategory: 'Hot Beverage',
      meaning: 'A brewed drink prepared from roasted coffee beans.',
      realWorldTip: 'Cafe menus offer espresso, latte, cappuccino, and americano.',
    ),
    'tea': ScanDictionaryEntry(
      signCategory: 'Hot Beverage',
      meaning: 'A beverage made by infusing dried crushed tea leaves in boiling water.',
      realWorldTip: 'Common varieties on menus include Black, Green, Earl Grey, and Herbal.',
    ),
    'juice': ScanDictionaryEntry(
      signCategory: 'Cold Beverage',
      meaning: 'The liquid naturally contained in fruit or vegetable tissues.',
      realWorldTip: 'Look for "Freshly Squeezed Orange Juice" or "Apple Juice" on morning menus.',
    ),
    'beer': ScanDictionaryEntry(
      signCategory: 'Alcoholic Beverage',
      meaning: 'An alcoholic drink made from yeast-fermented malt flavored with hops.',
      realWorldTip: 'Found in the pub/bar section of menus; usually requires 18+ or 21+ age ID.',
    ),
    'wine': ScanDictionaryEntry(
      signCategory: 'Alcoholic Beverage',
      meaning: 'An alcoholic drink made from fermented grape juice.',
      realWorldTip: 'Divided into Red, White, Sparkling, and Rose categories.',
    ),
    'food': ScanDictionaryEntry(
      signCategory: 'Dining General',
      meaning: 'Any nutritious substance consumed to maintain life and growth.',
      realWorldTip: 'Seen on store signs like "Food Hall", "Fast Food", or "Whole Foods".',
    ),
    'meat': ScanDictionaryEntry(
      signCategory: 'Food Ingredient',
      meaning: 'The flesh of an animal as food.',
      realWorldTip: 'Look for dietary labels or butchery sections.',
    ),
    'chicken': ScanDictionaryEntry(
      signCategory: 'Poultry Food',
      meaning: 'Domestic fowl kept for its eggs or meat; common lean protein.',
      realWorldTip: 'Popular on menus as grilled chicken, roast chicken, or chicken sandwich.',
    ),
    'fish': ScanDictionaryEntry(
      signCategory: 'Seafood',
      meaning: 'Limbless cold-blooded vertebrate living in water, prepared as food.',
      realWorldTip: 'Found in seafood menus, often accompanied by allergen warnings.',
    ),
    'vegetarian': ScanDictionaryEntry(
      signCategory: 'Dietary Preference',
      meaning: 'Food containing no meat or fish ingredients.',
      realWorldTip: 'Marked on menus with a green "V" or leaf symbol for easy identification.',
    ),
  };

  /// Retrieves an entry for a given sign/text word, falling back to dynamic metadata.
  static ScanDictionaryEntry getEntry(String rawWord) {
    final key = rawWord.trim().toLowerCase();
    if (dictionary.containsKey(key)) {
      return dictionary[key]!;
    }

    // Try singular / plural resolution
    if (key.endsWith('s') && dictionary.containsKey(key.substring(0, key.length - 1))) {
      return dictionary[key.substring(0, key.length - 1)]!;
    }
    if (dictionary.containsKey('${key}s')) {
      return dictionary['${key}s']!;
    }

    // Smart fallback for any arbitrary scanned sign
    return ScanDictionaryEntry(
      signCategory: 'Scanned Printed Sign',
      meaning: 'Real-world printed text captured by camera OCR.',
      realWorldTip: 'Read the surrounding words to understand the full context.',
    );
  }

  /// Evaluates whether recognized OCR text contains the targeted bounty word,
  /// using whole-word boundaries, plural normalization, and known signage aliases.
  static bool isBountyMatch(String targetBounty, String recognizedText) {
    final target = targetBounty.trim().toLowerCase();
    final text = recognizedText.trim().toLowerCase();

    if (target.isEmpty || text.isEmpty) return false;

    // Direct token check
    if (_containsWordBoundary(text, target)) return true;

    // Plural / singular variants
    if (target.endsWith('s')) {
      final singular = target.substring(0, target.length - 1);
      if (_containsWordBoundary(text, singular)) return true;
    } else {
      final plural = '${target}s';
      if (_containsWordBoundary(text, plural)) return true;
    }

    // Space / hyphen variation for multi-word phrases or longer compound words (e.g. "no smoking" vs "nosmoking", "supermarket" vs "super market")
    final cleanTarget = target.replaceAll(RegExp(r'[\s\-_]'), '');
    if (target.contains(' ') || target.contains('-') || cleanTarget.length >= 5) {
      final cleanText = text.replaceAll(RegExp(r'[\s\-_]'), '');
      if (cleanText.contains(cleanTarget)) {
        return true;
      }
    }

    // Signage domain aliases
    const Map<String, List<String>> aliases = {
      'restroom': ['bathroom', 'washroom', 'toilet', 'lavatory', 'wc', 'rest room'],
      'toilet': ['restroom', 'bathroom', 'washroom', 'wc', 'lavatory'],
      'washroom': ['restroom', 'bathroom', 'toilet', 'wc'],
      'entrance': ['entry', 'way in', 'inlet', 'doorway'],
      'exit': ['way out', 'emergency exit', 'fire exit'],
      'store': ['shop', 'retail', 'outlet', 'market'],
      'shop': ['store', 'boutique', 'market', 'outlet'],
      'pharmacy': ['chemist', 'drugstore', 'apothecary'],
      'receipt': ['bill', 'invoice', 'voucher', 'sales slip'],
      'cash': ['money', 'banknotes', 'coins', 'currency'],
      'atm': ['cash machine', 'cashpoint', 'automated teller'],
      'no smoking': ['smoke free', 'smoking prohibited', 'non smoking'],
      'danger': ['hazard', 'peril', 'high voltage'],
      'caution': ['watch your step', 'wet floor', 'take care', 'attention'],
      'warning': ['alert', 'notice', 'caution', 'danger'],
    };

    if (aliases.containsKey(target)) {
      final targetAliases = aliases[target]!;
      for (final alias in targetAliases) {
        if (_containsWordBoundary(text, alias)) {
          return true;
        }
      }
    }

    return false;
  }

  static bool _containsWordBoundary(String fullText, String word) {
    if (word.isEmpty) return false;
    // Word boundary regex that accounts for punctuation like quotes, colons, exclamation marks
    final escaped = RegExp.escape(word);
    final regex = RegExp('(^|[^a-zA-Z0-9])$escaped([^a-zA-Z0-9]|\$)', caseSensitive: false);
    return regex.hasMatch(fullText);
  }
}

