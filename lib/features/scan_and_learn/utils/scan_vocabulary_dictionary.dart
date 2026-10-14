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
      realWorldTip:
          'Look for glowing green or red signs above doors in public buildings.',
    ),
    'entrance': ScanDictionaryEntry(
      signCategory: 'Direction Sign',
      meaning: 'A door or gate where people enter a place.',
      realWorldTip:
          'Often paired with "Welcome" or arrows indicating entry points.',
    ),
    'open': ScanDictionaryEntry(
      signCategory: 'Business Status Sign',
      meaning:
          'Indicates the store, office, or facility is ready for customers.',
      realWorldTip:
          'Usually hung in shop windows alongside opening business hours.',
    ),
    'closed': ScanDictionaryEntry(
      signCategory: 'Business Status Sign',
      meaning:
          'Indicates the store or service is currently shut and not operating.',
      realWorldTip: 'Check the door sign for when the location will reopen.',
    ),
    'push': ScanDictionaryEntry(
      signCategory: 'Door Instruction',
      meaning:
          'Apply forward physical force against the door to swing it open.',
      realWorldTip: 'Located near door handles; do not pull when it says push!',
    ),
    'pull': ScanDictionaryEntry(
      signCategory: 'Door Instruction',
      meaning:
          'Grasp the handle and draw the door toward your body to open it.',
      realWorldTip: 'Usually found on doors with vertical bar handles.',
    ),
    'welcome': ScanDictionaryEntry(
      signCategory: 'Hospitality Sign',
      meaning: 'A warm greeting welcoming visitors into a venue or city.',
      realWorldTip:
          'Commonly seen at hotel entryways, town borders, and shops.',
    ),
    'restroom': ScanDictionaryEntry(
      signCategory: 'Facility Sign',
      meaning: 'A public room containing sinks and toilets.',
      realWorldTip:
          'Common in American English; paired with icons of men/women.',
    ),
    'toilet': ScanDictionaryEntry(
      signCategory: 'Facility Sign',
      meaning:
          'A sanitary facility equipped with a water closet and washbasin.',
      realWorldTip: 'Commonly used across the UK, Europe, Australia, and Asia.',
    ),
    'washroom': ScanDictionaryEntry(
      signCategory: 'Facility Sign',
      meaning: 'A room with washing and toilet facilities.',
      realWorldTip: 'Especially standard in Canadian and business English.',
    ),
    'private': ScanDictionaryEntry(
      signCategory: 'Restriction Notice',
      meaning:
          'Belonging to a particular person or group; not open to the general public.',
      realWorldTip:
          'Do not enter rooms marked "Private" without explicit permission.',
    ),

    // ─── Safety, Caution & Emergency ────────────────────────────────────────
    'warning': ScanDictionaryEntry(
      signCategory: 'Public Safety Notice',
      meaning:
          'A statement or sign advising of a potential danger or hazard ahead.',
      realWorldTip:
          'Usually framed in bright yellow or orange with an exclamation symbol.',
    ),
    'danger': ScanDictionaryEntry(
      signCategory: 'High Hazard Notice',
      meaning: 'A warning of severe risk of physical harm or death.',
      realWorldTip:
          'Take immediate precautions; stay away from electrical or chemical hazards.',
    ),
    'caution': ScanDictionaryEntry(
      signCategory: 'Safety Precaution',
      meaning: 'Care taken to avoid danger, accidents, or slips.',
      realWorldTip:
          'Frequently seen on yellow folding cones reading "Caution: Wet Floor".',
    ),
    'stop': ScanDictionaryEntry(
      signCategory: 'Traffic & Action Sign',
      meaning: 'Come to a complete halt and look both ways before proceeding.',
      realWorldTip:
          'Recognizable worldwide as a red octagon with bold white letters.',
    ),
    'emergency': ScanDictionaryEntry(
      signCategory: 'Urgent Response Sign',
      meaning: 'A serious, unexpected situation requiring immediate action.',
      realWorldTip:
          'Found near emergency exits, fire alarms, and first-aid kits.',
    ),
    'fire': ScanDictionaryEntry(
      signCategory: 'Life Safety Sign',
      meaning: 'Related to fire equipment, fire escapes, or fire alarms.',
      realWorldTip:
          'Directs to fire extinguishers, hoses, or emergency staircases.',
    ),
    'no smoking': ScanDictionaryEntry(
      signCategory: 'Prohibition Sign',
      meaning:
          'Smoking tobacco or e-cigarettes is strictly forbidden in this area.',
      realWorldTip: 'Paired with a crossed-out red cigarette symbol.',
    ),
    'police': ScanDictionaryEntry(
      signCategory: 'Public Authority Sign',
      meaning:
          'Identifies police stations, officers, or emergency help points.',
      realWorldTip:
          'Often visible on emergency patrol vehicles and civic headquarters.',
    ),
    'hospital': ScanDictionaryEntry(
      signCategory: 'Medical Facility Sign',
      meaning: 'An institution providing medical treatment and nursing care.',
      realWorldTip:
          'Marked with a bold "H" sign along roadways and building facades.',
    ),
    'pharmacy': ScanDictionaryEntry(
      signCategory: 'Healthcare Store',
      meaning:
          'A retail store where medicines, health goods, and prescriptions are prepared.',
      realWorldTip:
          'Often symbolized by a green cross in Europe and worldwide.',
    ),

    // ─── Retail, Commerce & Payments ────────────────────────────────────────
    'menu': ScanDictionaryEntry(
      signCategory: 'Dining Document',
      meaning:
          'A list of food dishes and drinks available with corresponding prices.',
      realWorldTip:
          'Displayed in restaurant windows, on tables, or via QR codes.',
    ),
    'receipt': ScanDictionaryEntry(
      signCategory: 'Purchase Record',
      meaning: 'A printed slip proving that money or goods were received.',
      realWorldTip:
          'Keep your receipt for store returns, tax records, or warranty claims.',
    ),
    'sale': ScanDictionaryEntry(
      signCategory: 'Promotion Sign',
      meaning: 'An event where goods are sold at reduced promotional prices.',
      realWorldTip:
          'Often features percentages like "50% Off" or "End of Season Sale".',
    ),
    'notice': ScanDictionaryEntry(
      signCategory: 'Official Announcement',
      meaning:
          'A formal notification providing information or rules to the public.',
      realWorldTip:
          'Posted on bulletin boards, shop windows, and apartment lobbies.',
    ),
    'store': ScanDictionaryEntry(
      signCategory: 'Commercial Venue',
      meaning: 'A retail establishment selling goods or services to customers.',
      realWorldTip:
          'Can refer to grocery stores, clothing boutiques, or department stores.',
    ),
    'shop': ScanDictionaryEntry(
      signCategory: 'Commercial Venue',
      meaning: 'A retail outlet where goods are displayed for purchase.',
      realWorldTip:
          'Widely used in British English for retail businesses of all sizes.',
    ),
    'market': ScanDictionaryEntry(
      signCategory: 'Commerce Area',
      meaning:
          'An open square or hall where vendors display produce and goods.',
      realWorldTip:
          'Look for farmers markets, street markets, and fresh food stalls.',
    ),
    'supermarket': ScanDictionaryEntry(
      signCategory: 'Grocery Store',
      meaning:
          'A large self-service grocery store offering food and household supplies.',
      realWorldTip:
          'Organized into aisles with shopping carts and checkout lanes.',
    ),
    'bank': ScanDictionaryEntry(
      signCategory: 'Financial Institution',
      meaning:
          'An establishment that manages deposits, currency exchange, and loans.',
      realWorldTip:
          'Essential for currency conversion and secure financial transactions.',
    ),
    'atm': ScanDictionaryEntry(
      signCategory: 'Automated Banking',
      meaning:
          'Automated Teller Machine providing cash withdrawals and account balances.',
      realWorldTip:
          'Look for the 3-letter acronym ATM outside banks and convenience stores.',
    ),
    'cash': ScanDictionaryEntry(
      signCategory: 'Payment Method',
      meaning: 'Money in the physical form of bills, notes, and coins.',
      realWorldTip:
          'Some checkout counters post "Cash Only" or "No Cash" notices.',
    ),
    'credit': ScanDictionaryEntry(
      signCategory: 'Financial Account',
      meaning:
          'Payment method allowing consumers to purchase goods and pay later.',
      realWorldTip:
          'Found on credit card logos like Visa, Mastercard, and Amex.',
    ),
    'card': ScanDictionaryEntry(
      signCategory: 'Payment Device',
      meaning:
          'A small plastic or metal bank card used for digital transactions.',
      realWorldTip:
          'Often displayed as "Card Accepted" or "Insert / Tap Card".',
    ),
    'pay': ScanDictionaryEntry(
      signCategory: 'Transaction Action',
      meaning: 'To give money in exchange for goods, services, or transit.',
      realWorldTip:
          'Found on checkout counters, parking meters, and online payment kiosks.',
    ),
    'free': ScanDictionaryEntry(
      signCategory: 'Price Notice',
      meaning: 'Provided without any charge, cost, or fee required.',
      realWorldTip:
          'Seen on signs like "Free Wi-Fi", "Free Admission", or "Buy 1 Get 1 Free".',
    ),
    'discount': ScanDictionaryEntry(
      signCategory: 'Price Reduction',
      meaning: 'A deduction from the regular price of something.',
      realWorldTip: 'Look for student, senior, or seasonal discount notices.',
    ),
    'offer': ScanDictionaryEntry(
      signCategory: 'Promotional Deal',
      meaning:
          'A temporary special deal or price discount presented to buyers.',
      realWorldTip: 'Look for "Special Offer" or "Limited Time Offer" banners.',
    ),
    'price': ScanDictionaryEntry(
      signCategory: 'Cost Information',
      meaning:
          'The amount of money expected, required, or given in payment for something.',
      realWorldTip: 'Printed on price tags, menus, and shelf barcode labels.',
    ),
    'cost': ScanDictionaryEntry(
      signCategory: 'Financial Metric',
      meaning:
          'An amount that has to be paid or spent to buy or obtain something.',
      realWorldTip: 'Look for signs displaying ticket costs or service fees.',
    ),
    'total': ScanDictionaryEntry(
      signCategory: 'Bill Summary',
      meaning: 'The final aggregate sum of all purchases including taxes.',
      realWorldTip:
          'Printed at the very bottom of store receipts and restaurant bills.',
    ),
    'tax': ScanDictionaryEntry(
      signCategory: 'Government Fee',
      meaning: 'A compulsory financial charge imposed by government on sales.',
      realWorldTip:
          'Receipts show VAT (Value Added Tax) or local sales tax line items.',
    ),
    'tip': ScanDictionaryEntry(
      signCategory: 'Gratuity',
      meaning: 'A sum of money given to someone as a reward for their service.',
      realWorldTip:
          'Common in dining and hospitality; lines on bills often read "Gratuity/Tip".',
    ),
    'service': ScanDictionaryEntry(
      signCategory: 'Hospitality & Charge',
      meaning:
          'Work done by hospitality staff, often included as a fee on bills.',
      realWorldTip:
          'Check whether a "Service Charge Included" notice appears on the bill.',
    ),
    'included': ScanDictionaryEntry(
      signCategory: 'Billing Status',
      meaning: 'Contained as part of a whole condition or package price.',
      realWorldTip: 'Seen as "Tax Included" or "Breakfast Included with Room".',
    ),
    'excluded': ScanDictionaryEntry(
      signCategory: 'Billing Status',
      meaning:
          'Not included in the listed price and requiring an additional fee.',
      realWorldTip:
          'Notice lines like "Taxes Excluded" to avoid billing surprises.',
    ),

    // ─── Meals, Food & Beverages ────────────────────────────────────────────
    'breakfast': ScanDictionaryEntry(
      signCategory: 'Meal Schedule',
      meaning: 'The first meal of the day, typically eaten in the morning.',
      realWorldTip:
          'Look for hotel breakfast hours such as "Breakfast: 7:00 AM – 10:30 AM".',
    ),
    'lunch': ScanDictionaryEntry(
      signCategory: 'Meal Schedule',
      meaning: 'A meal eaten in the middle of the day.',
      realWorldTip:
          'Cafes frequently advertise "Lunch Specials" from 12:00 PM to 2:00 PM.',
    ),
    'dinner': ScanDictionaryEntry(
      signCategory: 'Meal Schedule',
      meaning:
          'The main meal of the day, taken either in the middle or evening.',
      realWorldTip:
          'Restaurant dinner menus often feature evening entrees and specials.',
    ),
    'drinks': ScanDictionaryEntry(
      signCategory: 'Beverage Section',
      meaning: 'Liquids intended for human consumption, hot or cold.',
      realWorldTip:
          'Found as a header on menus for sodas, teas, coffees, and juices.',
    ),
    'water': ScanDictionaryEntry(
      signCategory: 'Essential Beverage',
      meaning: 'Pure transparent liquid essential for hydration.',
      realWorldTip:
          'Look for "Drinking Water", "Tap Water", or "Bottled Mineral Water".',
    ),
    'coffee': ScanDictionaryEntry(
      signCategory: 'Hot Beverage',
      meaning: 'A brewed drink prepared from roasted coffee beans.',
      realWorldTip:
          'Cafe menus offer espresso, latte, cappuccino, and americano.',
    ),
    'tea': ScanDictionaryEntry(
      signCategory: 'Hot Beverage',
      meaning:
          'A beverage made by infusing dried crushed tea leaves in boiling water.',
      realWorldTip:
          'Common varieties on menus include Black, Green, Earl Grey, and Herbal.',
    ),
    'juice': ScanDictionaryEntry(
      signCategory: 'Cold Beverage',
      meaning: 'The liquid naturally contained in fruit or vegetable tissues.',
      realWorldTip:
          'Look for "Freshly Squeezed Orange Juice" or "Apple Juice" on morning menus.',
    ),
    'beer': ScanDictionaryEntry(
      signCategory: 'Alcoholic Beverage',
      meaning:
          'An alcoholic drink made from yeast-fermented malt flavored with hops.',
      realWorldTip:
          'Found in the pub/bar section of menus; usually requires 18+ or 21+ age ID.',
    ),
    'wine': ScanDictionaryEntry(
      signCategory: 'Alcoholic Beverage',
      meaning: 'An alcoholic drink made from fermented grape juice.',
      realWorldTip: 'Divided into Red, White, Sparkling, and Rose categories.',
    ),
    'food': ScanDictionaryEntry(
      signCategory: 'Dining General',
      meaning: 'Any nutritious substance consumed to maintain life and growth.',
      realWorldTip:
          'Seen on store signs like "Food Hall", "Fast Food", or "Whole Foods".',
    ),
    'meat': ScanDictionaryEntry(
      signCategory: 'Food Ingredient',
      meaning: 'The flesh of an animal as food.',
      realWorldTip: 'Look for dietary labels or butchery sections.',
    ),
    'chicken': ScanDictionaryEntry(
      signCategory: 'Poultry Food',
      meaning: 'Domestic fowl kept for its eggs or meat; common lean protein.',
      realWorldTip:
          'Popular on menus as grilled chicken, roast chicken, or chicken sandwich.',
    ),
    'fish': ScanDictionaryEntry(
      signCategory: 'Seafood',
      meaning:
          'Limbless cold-blooded vertebrate living in water, prepared as food.',
      realWorldTip:
          'Found in seafood menus, often accompanied by allergen warnings.',
    ),
    'vegetarian': ScanDictionaryEntry(
      signCategory: 'Dietary Preference',
      meaning: 'Food containing no meat or fish ingredients.',
      realWorldTip:
          'Marked on menus with a green "V" or leaf symbol for easy identification.',
    ),

    // ─── Curriculum Expansion · 1. Street, Traffic & Direction Signs ────────────────
    'pedestrian': ScanDictionaryEntry(
      signCategory: 'Traffic Sign',
      meaning: 'A person who travels on foot, not in a vehicle.',
      realWorldTip:
          'Look for it on crossing signs near schools, shops, and busy roads.',
    ),
    'crosswalk': ScanDictionaryEntry(
      signCategory: 'Road Marking',
      meaning: 'A marked place on a road where people can safely walk across.',
      realWorldTip:
          'Look for white stripes on the road, often next to traffic lights.',
    ),
    'sidewalk': ScanDictionaryEntry(
      signCategory: 'Street Sign',
      meaning:
          'The path beside a road for people who walk. In British English it is called a pavement.',
      realWorldTip: 'Look for "Sidewalk Closed" signs near building work.',
    ),
    'yield': ScanDictionaryEntry(
      signCategory: 'Traffic Sign',
      meaning: 'Slow down and let other cars or people go first.',
      realWorldTip:
          'Look for a red and white triangle sign at roundabouts and junctions.',
    ),
    'speed limit': ScanDictionaryEntry(
      signCategory: 'Traffic Sign',
      meaning: 'The fastest speed a vehicle is allowed to go on that road.',
      realWorldTip:
          'Look for a round sign with a number, such as 50, beside the road.',
    ),
    'one way': ScanDictionaryEntry(
      signCategory: 'Direction Sign',
      meaning: 'Vehicles can only travel in one direction on this street.',
      realWorldTip:
          'Look for an arrow sign at the start of narrow city streets.',
    ),
    'detour': ScanDictionaryEntry(
      signCategory: 'Road Notice',
      meaning: 'A different route you take when the main road is closed.',
      realWorldTip: 'Look for orange signs with arrows when a road is blocked.',
    ),
    'parking': ScanDictionaryEntry(
      signCategory: 'Parking Sign',
      meaning: 'A place where you can leave your car for a short or long time.',
      realWorldTip:
          'Look for a blue sign with a white P near shops, malls, and offices.',
    ),
    'ahead': ScanDictionaryEntry(
      signCategory: 'Road Sign',
      meaning: 'In front of you, further along the way.',
      realWorldTip:
          'Look for it in warnings like "Stop Ahead" or "Road Work Ahead".',
    ),
    'slow': ScanDictionaryEntry(
      signCategory: 'Traffic Sign',
      meaning: 'Reduce your speed and move carefully.',
      realWorldTip:
          'Look for "Slow" painted on the road near schools and car parks.',
    ),
    'roundabout': ScanDictionaryEntry(
      signCategory: 'Traffic Sign',
      meaning:
          'A circular junction where traffic moves around in one direction.',
      realWorldTip:
          'Look for a blue sign with three arrows in a circle before the junction.',
    ),
    'road work': ScanDictionaryEntry(
      signCategory: 'Road Notice',
      meaning: 'Workers are building or repairing the road, so be careful.',
      realWorldTip:
          'Look for orange signs and cones along roads that are being fixed.',
    ),
    'dead end': ScanDictionaryEntry(
      signCategory: 'Street Sign',
      meaning:
          'A street that is closed at one end, so you cannot drive through.',
      realWorldTip: 'Look for it at the start of small neighborhood streets.',
    ),
    'toll': ScanDictionaryEntry(
      signCategory: 'Highway Sign',
      meaning: 'Money you pay to use a road, bridge, or tunnel.',
      realWorldTip:
          'Look for it on signs before payment booths on highways and bridges.',
    ),
    'fuel': ScanDictionaryEntry(
      signCategory: 'Station Sign',
      meaning: 'Gas or diesel that you put in a vehicle to make it go.',
      realWorldTip: 'Look for it on signs and pumps at gas stations.',
    ),
    'traffic': ScanDictionaryEntry(
      signCategory: 'Road Sign',
      meaning: 'The cars, buses, and trucks moving along a road.',
      realWorldTip:
          'Look for it on signs like "Heavy Traffic" or "Traffic Light" on busy roads.',
    ),
    'bike lane': ScanDictionaryEntry(
      signCategory: 'Road Marking',
      meaning: 'A part of the road kept for people riding bicycles.',
      realWorldTip:
          'Look for a bicycle symbol painted on the side of city streets.',
    ),
    'street': ScanDictionaryEntry(
      signCategory: 'Street Sign',
      meaning: 'A public road in a town or city with buildings along it.',
      realWorldTip: 'Look for the street name on a sign at each corner.',
    ),

    // ─── Curriculum Expansion · 2. Public Transit, Airport & Subway ─────────────────
    'subway': ScanDictionaryEntry(
      signCategory: 'Transit Sign',
      meaning: 'An underground train system in a city.',
      realWorldTip:
          'Look for it on signs at stairs that go down to the station.',
    ),
    'platform': ScanDictionaryEntry(
      signCategory: 'Station Sign',
      meaning: 'The raised area at a station where you wait for a train.',
      realWorldTip:
          'Look for platform numbers on signs above the stairs at train stations.',
    ),
    'ticket': ScanDictionaryEntry(
      signCategory: 'Transit Sign',
      meaning:
          'A piece of paper or card that lets you travel or enter a place.',
      realWorldTip:
          'Look for it on machines and windows at stations and airports.',
    ),
    'station': ScanDictionaryEntry(
      signCategory: 'Transit Sign',
      meaning:
          'A place where trains or buses stop so people can get on and off.',
      realWorldTip:
          'Look for it on large signs at the front of train and bus buildings.',
    ),
    'bus': ScanDictionaryEntry(
      signCategory: 'Transit Sign',
      meaning: 'A large vehicle that carries many people along a fixed route.',
      realWorldTip:
          'Look for the bus number on the front of the bus and at bus stops.',
    ),
    'taxi': ScanDictionaryEntry(
      signCategory: 'Transit Sign',
      meaning:
          'A car with a driver that you pay to take you where you want to go.',
      realWorldTip:
          'Look for a lit sign on the roof of the car or a taxi stand sign.',
    ),
    'airport': ScanDictionaryEntry(
      signCategory: 'Airport Sign',
      meaning: 'A place where airplanes take off and land.',
      realWorldTip:
          'Look for airplane symbols on road signs leading to the airport.',
    ),
    'gate': ScanDictionaryEntry(
      signCategory: 'Airport Sign',
      meaning: 'The door where passengers wait and then get on their airplane.',
      realWorldTip:
          'Look for a letter and number, like B12, on screens and signs in the airport.',
    ),
    'boarding': ScanDictionaryEntry(
      signCategory: 'Airport Notice',
      meaning: 'The time when passengers get on a plane, train, or ship.',
      realWorldTip: 'Look for "Now Boarding" on screens at airport gates.',
    ),
    'departures': ScanDictionaryEntry(
      signCategory: 'Airport Sign',
      meaning: 'The area or list for flights and trains that are leaving.',
      realWorldTip:
          'Look for it on big screens and hall signs in airports and stations.',
    ),
    'arrivals': ScanDictionaryEntry(
      signCategory: 'Airport Sign',
      meaning: 'The area or list for flights and trains that are coming in.',
      realWorldTip:
          'Look for it on screens and signs where you meet people at the airport.',
    ),
    'luggage': ScanDictionaryEntry(
      signCategory: 'Airport Sign',
      meaning: 'The bags and suitcases you take when you travel.',
      realWorldTip:
          'Look for it at check-in desks and on signs for carts and lockers.',
    ),
    'passport': ScanDictionaryEntry(
      signCategory: 'Airport Sign',
      meaning:
          'An official book that shows who you are when you travel to other countries.',
      realWorldTip:
          'Look for it on border signs and on your own travel document.',
    ),
    'security': ScanDictionaryEntry(
      signCategory: 'Airport Sign',
      meaning:
          'The check that keeps people safe by looking at bags and people.',
      realWorldTip: 'Look for it on signs before the area with bag scanners.',
    ),
    'customs': ScanDictionaryEntry(
      signCategory: 'Airport Sign',
      meaning: 'The place where officers check what you bring into a country.',
      realWorldTip:
          'Look for it on signs after you collect your bags at the airport.',
    ),
    'terminal': ScanDictionaryEntry(
      signCategory: 'Airport Sign',
      meaning: 'A large building at an airport where a trip starts or ends.',
      realWorldTip:
          'Look for "Terminal 1" or "Terminal 2" on airport roads and buses.',
    ),
    'flight': ScanDictionaryEntry(
      signCategory: 'Airport Sign',
      meaning: 'A trip made by plane, or the plane\'s number and schedule.',
      realWorldTip: 'Look for flight numbers like AB123 on airport screens.',
    ),
    'delayed': ScanDictionaryEntry(
      signCategory: 'Airport Notice',
      meaning: 'Later than planned; not on time.',
      realWorldTip:
          'Look for it in red or orange next to flights on airport screens.',
    ),
    'fare': ScanDictionaryEntry(
      signCategory: 'Transit Sign',
      meaning: 'The money you pay for a bus, train, or taxi trip.',
      realWorldTip: 'Look for it on signs inside buses and on ticket machines.',
    ),

    // ─── Curriculum Expansion · 3. Restaurant, Cafe & Menu Vocabulary ───────────────
    'starters': ScanDictionaryEntry(
      signCategory: 'Menu Label',
      meaning: 'Small dishes served first, before the main meal.',
      realWorldTip:
          'Look for it as a heading near the top of a restaurant menu.',
    ),
    'dessert': ScanDictionaryEntry(
      signCategory: 'Menu Label',
      meaning:
          'A sweet food, like cake or ice cream, eaten at the end of a meal.',
      realWorldTip: 'Look for it as the last section of a restaurant menu.',
    ),
    'soup': ScanDictionaryEntry(
      signCategory: 'Menu Label',
      meaning: 'A hot liquid food made with vegetables, meat, or fish.',
      realWorldTip: 'Look for "Soup of the Day" on cafe chalkboards.',
    ),
    'salad': ScanDictionaryEntry(
      signCategory: 'Menu Label',
      meaning: 'A cold dish made with raw vegetables.',
      realWorldTip:
          'Look for it in the lunch section of menus and at salad bars.',
    ),
    'pizza': ScanDictionaryEntry(
      signCategory: 'Menu Label',
      meaning: 'A flat round bread baked with cheese and other toppings.',
      realWorldTip:
          'Look for it on restaurant windows, delivery boxes, and menu boards.',
    ),
    'takeout': ScanDictionaryEntry(
      signCategory: 'Restaurant Sign',
      meaning:
          'Food you buy in a restaurant and eat somewhere else. In British English it is called takeaway.',
      realWorldTip: 'Look for it in shop windows and on counter signs.',
    ),
    'delivery': ScanDictionaryEntry(
      signCategory: 'Restaurant Sign',
      meaning: 'A service that brings food or goods to your home.',
      realWorldTip:
          'Look for it on shop windows with phone numbers and app logos.',
    ),
    'reserved': ScanDictionaryEntry(
      signCategory: 'Table Sign',
      meaning: 'Kept for a certain person or group, so others cannot use it.',
      realWorldTip: 'Look for a small card standing on a restaurant table.',
    ),
    'spicy': ScanDictionaryEntry(
      signCategory: 'Menu Label',
      meaning: 'Having a strong, hot taste from peppers or spices.',
      realWorldTip: 'Look for a chili symbol next to hot dishes on menus.',
    ),

    // ─── Curriculum Expansion · 4. Supermarket, Food Packaging & Nutrition ──────────
    'organic': ScanDictionaryEntry(
      signCategory: 'Food Label',
      meaning: 'Grown or made without artificial chemicals.',
      realWorldTip:
          'Look for it on green labels on fruit, vegetables, and milk.',
    ),
    'gluten-free': ScanDictionaryEntry(
      signCategory: 'Food Label',
      meaning:
          'Made without gluten, a part of wheat that some people cannot eat.',
      realWorldTip: 'Look for it on packages in the special food aisle.',
    ),
    'ingredients': ScanDictionaryEntry(
      signCategory: 'Packaging Label',
      meaning: 'The list of everything used to make a food.',
      realWorldTip: 'Look for it on the back of boxes, cans, and bottles.',
    ),
    'calories': ScanDictionaryEntry(
      signCategory: 'Nutrition Label',
      meaning: 'Units that measure the energy in food.',
      realWorldTip:
          'Look for it in the nutrition table on the back of packages.',
    ),
    'sugar': ScanDictionaryEntry(
      signCategory: 'Nutrition Label',
      meaning: 'A sweet white food used in drinks, cakes, and candy.',
      realWorldTip:
          'Look for it in the nutrition table and the ingredients list.',
    ),
    'best before': ScanDictionaryEntry(
      signCategory: 'Packaging Date',
      meaning: 'The date after which food may not taste its best.',
      realWorldTip: 'Look for it printed on the top or bottom of packages.',
    ),
    'fresh': ScanDictionaryEntry(
      signCategory: 'Food Label',
      meaning: 'Newly made or picked, not old or frozen.',
      realWorldTip:
          'Look for it on signs above fruit, bread, and fish in supermarkets.',
    ),
    'frozen': ScanDictionaryEntry(
      signCategory: 'Food Label',
      meaning: 'Kept very cold so it becomes hard like ice.',
      realWorldTip:
          'Look for it on freezer signs and on bags and boxes of food.',
    ),
    'vegan': ScanDictionaryEntry(
      signCategory: 'Food Label',
      meaning: 'Made without any meat, fish, milk, or eggs.',
      realWorldTip: 'Look for a green V or leaf symbol on packages and menus.',
    ),
    'milk': ScanDictionaryEntry(
      signCategory: 'Food Label',
      meaning: 'A white drink that comes from cows.',
      realWorldTip:
          'Look for it on cartons and bottles in the cold section of a store.',
    ),
    'allergens': ScanDictionaryEntry(
      signCategory: 'Nutrition Label',
      meaning:
          'Things in food, like nuts or eggs, that can make some people ill.',
      realWorldTip: 'Look for them in bold letters in the ingredients list.',
    ),
    'nuts': ScanDictionaryEntry(
      signCategory: 'Food Label',
      meaning: 'Hard-shelled seeds like peanuts, almonds, and cashews.',
      realWorldTip: 'Look for "Contains Nuts" warnings on snack packages.',
    ),

    // ─── Curriculum Expansion · 5. Store, Shopping, Sales & Receipts ────────────────
    'cashier': ScanDictionaryEntry(
      signCategory: 'Store Sign',
      meaning: 'The person who takes your money when you buy something.',
      realWorldTip: 'Look for it above the desks where you pay in a shop.',
    ),
    'refund': ScanDictionaryEntry(
      signCategory: 'Store Notice',
      meaning: 'Money given back to you when you return something.',
      realWorldTip: 'Look for it on receipts and at returns desks.',
    ),
    'clearance': ScanDictionaryEntry(
      signCategory: 'Sale Sign',
      meaning: 'A sale with very low prices to sell old items quickly.',
      realWorldTip:
          'Look for it on red tags and in a special corner of the shop.',
    ),
    'self service': ScanDictionaryEntry(
      signCategory: 'Store Sign',
      meaning: 'A place where customers help themselves without a worker.',
      realWorldTip:
          'Look for it at gas stations, fast-food counters, and supermarket checkouts.',
    ),

    // ─── Curriculum Expansion · 6. Safety, Hazard, Caution & Emergency Notices ──────
    'fragile': ScanDictionaryEntry(
      signCategory: 'Package Label',
      meaning: 'Easy to break, so handle with care.',
      realWorldTip: 'Look for it on red tape and labels on boxes sent by post.',
    ),
    'keep out': ScanDictionaryEntry(
      signCategory: 'Safety Warning',
      meaning: 'Do not go into this place.',
      realWorldTip:
          'Look for it on fences, gates, and doors at building sites.',
    ),
    'wet floor': ScanDictionaryEntry(
      signCategory: 'Safety Warning',
      meaning: 'The floor is wet and you may slip.',
      realWorldTip:
          'Look for a yellow stand sign in malls and public restrooms after cleaning.',
    ),
    'flammable': ScanDictionaryEntry(
      signCategory: 'Hazard Label',
      meaning: 'Able to catch fire very easily.',
      realWorldTip:
          'Look for it on labels of cleaning products and gas bottles.',
    ),
    'poison': ScanDictionaryEntry(
      signCategory: 'Hazard Label',
      meaning: 'A substance that can make people very sick if swallowed.',
      realWorldTip:
          'Look for it on labels of strong cleaning products and garden chemicals.',
    ),
    'first aid': ScanDictionaryEntry(
      signCategory: 'Emergency Sign',
      meaning: 'Basic help given to a hurt person before a doctor arrives.',
      realWorldTip:
          'Look for a white cross on a green sign above first aid boxes.',
    ),
    'ambulance': ScanDictionaryEntry(
      signCategory: 'Emergency Sign',
      meaning: 'A vehicle that takes sick or hurt people to hospital.',
      realWorldTip:
          'Look for it on the front of emergency vehicles and on roads near hospitals.',
    ),
    'extinguisher': ScanDictionaryEntry(
      signCategory: 'Safety Sign',
      meaning: 'A metal bottle with foam or gas that puts out small fires.',
      realWorldTip:
          'Look for a red cylinder on the wall with a sign above it in public buildings.',
    ),
    'alarm': ScanDictionaryEntry(
      signCategory: 'Safety Notice',
      meaning: 'A loud sound or device that warns people of danger.',
      realWorldTip:
          'Look for it on red boxes on walls and on signs in buildings.',
    ),
    'beware': ScanDictionaryEntry(
      signCategory: 'Safety Warning',
      meaning: 'Be careful because of a possible danger.',
      realWorldTip: 'Look for "Beware of the Dog" on garden gates.',
    ),
    'staff only': ScanDictionaryEntry(
      signCategory: 'Access Sign',
      meaning: 'Only workers may enter this area, not customers.',
      realWorldTip:
          'Look for it on doors behind counters in shops and restaurants.',
    ),
    'evacuate': ScanDictionaryEntry(
      signCategory: 'Emergency Notice',
      meaning: 'Leave a building quickly because it is not safe.',
      realWorldTip:
          'Look for evacuation plans on walls near the stairs in hotels and offices.',
    ),

    // ─── Curriculum Expansion · 7. Facility, Building & Restroom Signs ──────────────
    'elevator': ScanDictionaryEntry(
      signCategory: 'Facility Sign',
      meaning:
          'A small room that moves people up and down in a building. In British English it is called a lift.',
      realWorldTip:
          'Look for it next to buttons with arrows in malls and offices.',
    ),
    'escalator': ScanDictionaryEntry(
      signCategory: 'Facility Sign',
      meaning: 'Moving stairs that carry people up or down.',
      realWorldTip:
          'Look for it in shopping malls, airports, and train stations.',
    ),
    'stairs': ScanDictionaryEntry(
      signCategory: 'Facility Sign',
      meaning: 'A set of steps that connect different floors of a building.',
      realWorldTip:
          'Look for it on green exit signs and on doors beside elevators.',
    ),
    'lobby': ScanDictionaryEntry(
      signCategory: 'Facility Sign',
      meaning: 'The large entrance room of a hotel or big building.',
      realWorldTip:
          'Look for it on directory signs near the front doors of hotels and offices.',
    ),
    'men': ScanDictionaryEntry(
      signCategory: 'Restroom Sign',
      meaning: 'A word for the restroom used by male people.',
      realWorldTip: 'Look for it on restroom doors, often with a man symbol.',
    ),
    'women': ScanDictionaryEntry(
      signCategory: 'Restroom Sign',
      meaning: 'A word for the restroom used by female people.',
      realWorldTip: 'Look for it on restroom doors, often with a woman symbol.',
    ),
    'accessible': ScanDictionaryEntry(
      signCategory: 'Facility Sign',
      meaning:
          'Easy to use for people who use a wheelchair or have trouble walking.',
      realWorldTip:
          'Look for a blue wheelchair symbol on doors, ramps, and parking spaces.',
    ),
    'trash': ScanDictionaryEntry(
      signCategory: 'Facility Sign',
      meaning:
          'Things you throw away, or the bin you throw them in. British English: rubbish.',
      realWorldTip: 'Look for it on bins in parks, streets, and malls.',
    ),
    'recycling': ScanDictionaryEntry(
      signCategory: 'Facility Sign',
      meaning: 'Collecting used paper, glass, and plastic to make new things.',
      realWorldTip:
          'Look for it on green or blue bins with a triangle arrow symbol.',
    ),
    'changing room': ScanDictionaryEntry(
      signCategory: 'Shop Sign',
      meaning:
          'A small room in a shop where you try on clothes. Also called a fitting room.',
      realWorldTip: 'Look for it at the back of clothing stores.',
    ),
    'basement': ScanDictionaryEntry(
      signCategory: 'Building Sign',
      meaning: 'A floor of a building that is below the ground.',
      realWorldTip: 'Look for it on elevator buttons marked B or -1.',
    ),

    // ─── Curriculum Expansion · 8. Travel, Hotel, Tourism & Hospitality ─────────────
    'hotel': ScanDictionaryEntry(
      signCategory: 'Hotel Sign',
      meaning: 'A building where travelers pay to sleep in a room.',
      realWorldTip:
          'Look for it on tall signs outside buildings with many windows.',
    ),
    'reception': ScanDictionaryEntry(
      signCategory: 'Hotel Sign',
      meaning: 'The desk where guests arrive and ask for help.',
      realWorldTip: 'Look for it above the main desk in hotels and offices.',
    ),
    'check in': ScanDictionaryEntry(
      signCategory: 'Hotel Sign',
      meaning: 'Telling the hotel you have arrived and getting your room key.',
      realWorldTip: 'Look for it on signs at hotel desks and airport counters.',
    ),
    'check out': ScanDictionaryEntry(
      signCategory: 'Hotel Sign',
      meaning: 'Leaving a hotel and paying your bill.',
      realWorldTip:
          'Look for it near the reception desk with a time, such as 11 AM.',
    ),
    'reservation': ScanDictionaryEntry(
      signCategory: 'Hotel Notice',
      meaning: 'An arrangement to keep a room or table for you.',
      realWorldTip:
          'Look for it on booking emails and on desk signs in hotels.',
    ),
    'vacancy': ScanDictionaryEntry(
      signCategory: 'Hotel Sign',
      meaning: 'An empty room that you can rent.',
      realWorldTip:
          'Look for a lit "Vacancy" sign outside small hotels and motels.',
    ),
    'tourist': ScanDictionaryEntry(
      signCategory: 'Tourist Sign',
      meaning: 'A person who visits a place for fun and to see the sights.',
      realWorldTip: 'Look for "Tourist Information" signs in city centers.',
    ),
    'museum': ScanDictionaryEntry(
      signCategory: 'Tourist Sign',
      meaning: 'A building where people can see old or important objects.',
      realWorldTip: 'Look for it on brown tourist signs and on street maps.',
    ),
    'souvenir': ScanDictionaryEntry(
      signCategory: 'Tourist Sign',
      meaning: 'A small gift you buy to remember a trip.',
      realWorldTip: 'Look for it in shop windows near famous places.',
    ),
    'beach': ScanDictionaryEntry(
      signCategory: 'Tourist Sign',
      meaning: 'A sandy area beside the sea or a lake.',
      realWorldTip: 'Look for blue signs with a wave symbol on coast roads.',
    ),
    'pool': ScanDictionaryEntry(
      signCategory: 'Hotel Sign',
      meaning: 'A place filled with water for swimming.',
      realWorldTip:
          'Look for it on signs with rules and opening times in hotels.',
    ),
    'gym': ScanDictionaryEntry(
      signCategory: 'Hotel Sign',
      meaning: 'A room with equipment for exercise.',
      realWorldTip:
          'Look for it on directory signs in hotels and apartment buildings.',
    ),
    'spa': ScanDictionaryEntry(
      signCategory: 'Hotel Sign',
      meaning: 'A place where you relax with massages and warm baths.',
      realWorldTip: 'Look for it on signs near the pool in hotels.',
    ),
    'housekeeping': ScanDictionaryEntry(
      signCategory: 'Hotel Notice',
      meaning: 'The cleaning and tidying of hotel rooms.',
      realWorldTip: 'Look for it on the card you hang on your hotel room door.',
    ),
    'do not disturb': ScanDictionaryEntry(
      signCategory: 'Hotel Sign',
      meaning: 'A request for people not to knock or come in.',
      realWorldTip: 'Look for it on the card you hang on a hotel door handle.',
    ),
    'concierge': ScanDictionaryEntry(
      signCategory: 'Hotel Sign',
      meaning: 'A hotel worker who helps guests with trips and bookings.',
      realWorldTip: 'Look for it on a small desk near the hotel lobby.',
    ),
    'exchange': ScanDictionaryEntry(
      signCategory: 'Travel Sign',
      meaning: 'Changing money from one country for money from another.',
      realWorldTip:
          'Look for "Currency Exchange" at airports and tourist areas.',
    ),
    'tour': ScanDictionaryEntry(
      signCategory: 'Tourist Sign',
      meaning: 'A trip around a place to see its main sights.',
      realWorldTip: 'Look for it on posters and boards near famous places.',
    ),

    // ─── Curriculum Expansion · 9. Office, School, Library & Business Hours ─────────
    'library': ScanDictionaryEntry(
      signCategory: 'Library Sign',
      meaning: 'A place where you can read and borrow books.',
      realWorldTip: 'Look for it on signs outside schools and city buildings.',
    ),
    'school': ScanDictionaryEntry(
      signCategory: 'School Sign',
      meaning: 'A place where children go to learn.',
      realWorldTip:
          'Look for it on road signs near crossings with a children symbol.',
    ),
    'office': ScanDictionaryEntry(
      signCategory: 'Office Sign',
      meaning: 'A room or building where people do desk work.',
      realWorldTip:
          'Look for it on doors and directory boards inside large buildings.',
    ),
    'hours': ScanDictionaryEntry(
      signCategory: 'Business Sign',
      meaning: 'The times when a place is open for customers.',
      realWorldTip:
          'Look for "Opening Hours" on the door of shops and offices.',
    ),
    'information': ScanDictionaryEntry(
      signCategory: 'Information Sign',
      meaning: 'Facts and help for visitors, usually at a desk.',
      realWorldTip:
          'Look for a white letter i on a blue sign in malls and stations.',
    ),
    'quiet': ScanDictionaryEntry(
      signCategory: 'Library Sign',
      meaning: 'Do not make noise.',
      realWorldTip: 'Look for it on signs in libraries and study rooms.',
    ),
    'appointment': ScanDictionaryEntry(
      signCategory: 'Office Notice',
      meaning: 'A time arranged to meet a doctor or another person.',
      realWorldTip: 'Look for it on clinic doors and reception desks.',
    ),
    'visitors': ScanDictionaryEntry(
      signCategory: 'Office Sign',
      meaning: 'People who come to see a person or place.',
      realWorldTip: 'Look for it on signs at reception desks and school gates.',
    ),
    'return': ScanDictionaryEntry(
      signCategory: 'Library Sign',
      meaning: 'Bring something back to the place you got it.',
      realWorldTip: 'Look for a "Book Return" slot at libraries.',
    ),
    'queue': ScanDictionaryEntry(
      signCategory: 'Office Sign',
      meaning: 'A line of people waiting for their turn.',
      realWorldTip:
          'Look for it on floor signs and barriers in banks and stations.',
    ),
    'counter': ScanDictionaryEntry(
      signCategory: 'Business Sign',
      meaning: 'A long table where customers are served in a shop or bank.',
      realWorldTip:
          'Look for numbers above the counter windows in banks and post offices.',
    ),
    'holiday': ScanDictionaryEntry(
      signCategory: 'Business Notice',
      meaning: 'A day when shops and offices are closed.',
      realWorldTip: 'Look for "Closed for Holiday" on shop doors.',
    ),
    'admission': ScanDictionaryEntry(
      signCategory: 'Business Sign',
      meaning: 'The price or right to go into a place.',
      realWorldTip: 'Look for it on the ticket window at museums and parks.',
    ),
    'lost and found': ScanDictionaryEntry(
      signCategory: 'Office Sign',
      meaning: 'A place where lost things are kept for their owners.',
      realWorldTip: 'Look for it on desks in schools, stations, and malls.',
    ),

    // ─── Curriculum Expansion · 10. Digital, Connectivity & Modern Amenities ────────
    'wifi': ScanDictionaryEntry(
      signCategory: 'Digital Sign',
      meaning: 'A wireless way to connect to the internet.',
      realWorldTip:
          'Look for it on cafe doors and hotel desks with the network name.',
    ),
    'password': ScanDictionaryEntry(
      signCategory: 'Digital Notice',
      meaning: 'A secret word you type to use a network or account.',
      realWorldTip:
          'Look for it on small cards in cafes and hotel rooms next to the Wifi name.',
    ),
    'qr code': ScanDictionaryEntry(
      signCategory: 'Digital Sign',
      meaning: 'A square pattern you scan with your phone to open a page.',
      realWorldTip: 'Look for it on menus, posters, and shop windows.',
    ),
    'scan': ScanDictionaryEntry(
      signCategory: 'Digital Sign',
      meaning: 'Use a camera or machine to read a code or paper.',
      realWorldTip:
          'Look for it on signs next to QR codes and self-service machines.',
    ),
    'contactless': ScanDictionaryEntry(
      signCategory: 'Payment Sign',
      meaning: 'Paying by tapping your card or phone on a machine.',
      realWorldTip: 'Look for a wave symbol on card machines at shop counters.',
    ),
    'cashless': ScanDictionaryEntry(
      signCategory: 'Payment Sign',
      meaning: 'Not using paper money or coins to pay.',
      realWorldTip:
          'Look for it on signs in cafes and buses that only take cards.',
    ),
    'barcode': ScanDictionaryEntry(
      signCategory: 'Packaging Label',
      meaning:
          'A pattern of black lines that a machine reads to find the price.',
      realWorldTip: 'Look for it on the back of products and on shelf labels.',
    ),
    'charging': ScanDictionaryEntry(
      signCategory: 'Digital Sign',
      meaning: 'Putting electricity into a battery.',
      realWorldTip:
          'Look for "Charging Station" signs at airports and for electric cars.',
    ),
    'bluetooth': ScanDictionaryEntry(
      signCategory: 'Digital Sign',
      meaning:
          'A wireless way to connect devices like headphones and speakers.',
      realWorldTip:
          'Look for it on speaker boxes and in the settings of devices in stores.',
    ),
    'network': ScanDictionaryEntry(
      signCategory: 'Digital Notice',
      meaning: 'A group of connected devices that share the internet.',
      realWorldTip: 'Look for the network name on cards at hotels and cafes.',
    ),
    'login': ScanDictionaryEntry(
      signCategory: 'Digital Sign',
      meaning:
          'The step where you enter your name and password to use a service.',
      realWorldTip:
          'Look for it on screens at ticket machines and library computers.',
    ),
    'website': ScanDictionaryEntry(
      signCategory: 'Digital Sign',
      meaning: 'A place on the internet with pages about a company or service.',
      realWorldTip:
          'Look for addresses starting with www at the bottom of posters and packages.',
    ),
    'online': ScanDictionaryEntry(
      signCategory: 'Digital Sign',
      meaning: 'Connected to the internet, or done through the internet.',
      realWorldTip: 'Look for it on shop signs, such as "Order Online".',
    ),
    'download': ScanDictionaryEntry(
      signCategory: 'Digital Sign',
      meaning: 'Copy a file or app from the internet to your phone.',
      realWorldTip: 'Look for it on posters next to app store icons.',
    ),
    'touchscreen': ScanDictionaryEntry(
      signCategory: 'Digital Sign',
      meaning: 'A screen that you control by touching it.',
      realWorldTip:
          'Look for it on ticket machines and information points in stations.',
    ),
  };

  /// Retrieves an entry for a given sign/text word, falling back to dynamic metadata.
  static ScanDictionaryEntry getEntry(String rawWord) {
    final key = rawWord.trim().toLowerCase();
    if (dictionary.containsKey(key)) {
      return dictionary[key]!;
    }

    // Try singular / plural resolution
    if (key.endsWith('s') &&
        dictionary.containsKey(key.substring(0, key.length - 1))) {
      return dictionary[key.substring(0, key.length - 1)]!;
    }
    if (dictionary.containsKey('${key}s')) {
      return dictionary['${key}s']!;
    }

    // Smart fallback for any arbitrary scanned sign
    return ScanDictionaryEntry(
      signCategory: 'Scanned Printed Sign',
      meaning: 'Real-world printed text captured by camera OCR.',
      realWorldTip:
          'Read the surrounding words to understand the full context.',
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

    // Space / hyphen variation: "no smoking" vs "no-smoking" vs "nosmoking",
    // "supermarket" vs "super market". Compares whole words only, so "station"
    // no longer matches "stationery" and "office" no longer matches "officer".
    if (_matchesJoinedWords(text, target)) return true;

    // Signage domain aliases
    const Map<String, List<String>> aliases = {
      'restroom': [
        'bathroom',
        'washroom',
        'toilet',
        'lavatory',
        'wc',
        'rest room',
      ],
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
      // Curriculum expansion aliases (regional spellings and common synonyms)
      'crosswalk': ['zebra crossing', 'crossing'],
      'sidewalk': ['pavement', 'footpath'],
      'yield': ['give way'],
      'speed limit': ['max speed'],
      'one way': ['one-way'],
      'detour': ['diversion', 'alternate route'],
      'parking': ['car park', 'parking lot'],
      'slow': ['slow down'],
      'roundabout': ['traffic circle'],
      'road work': ['roadworks', 'road works', 'men at work'],
      'dead end': ['no through road', 'cul de sac'],
      'toll': ['toll plaza', 'toll road'],
      'fuel': ['petrol', 'gasoline', 'diesel', 'gas station'],
      'traffic': ['traffic jam'],
      'bike lane': ['bicycle lane', 'cycle lane', 'cycle path'],
      'street': ['avenue', 'boulevard'],
      'subway': ['metro', 'underground', 'tube'],
      'ticket': ['tickets'],
      'bus': ['coach'],
      'taxi': ['cab', 'taxi rank'],
      'boarding': ['boarding pass'],
      'departures': ['departure'],
      'arrivals': ['arrival'],
      'luggage': ['baggage', 'baggage claim'],
      'passport': ['passport control', 'immigration'],
      'security': ['security check'],
      'customs': ['customs control'],
      'flight': ['flights'],
      'delayed': ['delay'],
      'starters': ['appetizers', 'appetisers'],
      'dessert': ['desserts', 'sweets'],
      'pizza': ['pizzeria'],
      'takeout': ['takeaway', 'take away', 'to go'],
      'delivery': ['home delivery'],
      'spicy': ['hot and spicy'],
      'organic': ['bio'],
      'gluten-free': ['gluten free'],
      'ingredients': ['ingredient'],
      'calories': ['calorie', 'kcal'],
      'sugar': ['sugars'],
      'best before': ['use by', 'expiry date', 'expiration date', 'sell by'],
      'frozen': ['freezer'],
      'vegan': ['plant based', 'plant-based'],
      'milk': ['dairy'],
      'allergens': ['allergen', 'allergy'],
      'nuts': ['peanuts', 'tree nuts'],
      'cashier': ['till', 'cash desk'],
      'refund': ['money back'],
      'self service': ['self-service', 'self serve'],
      'fragile': ['handle with care'],
      'keep out': ['no trespassing', 'do not enter', 'no entry'],
      'wet floor': ['slippery when wet', 'wet surface'],
      'flammable': ['inflammable', 'highly flammable'],
      'poison': ['poisonous', 'toxic'],
      'first aid': ['first-aid'],
      'alarm': ['fire alarm'],
      'staff only': ['employees only', 'authorized personnel'],
      'evacuate': ['evacuation'],
      'elevator': ['lift'],
      'stairs': ['staircase', 'stairway'],
      'lobby': ['foyer'],
      'men': ['gents', 'gentlemen'],
      'women': ['ladies', 'womens'],
      'accessible': ['wheelchair', 'disabled'],
      'trash': ['rubbish', 'garbage', 'litter'],
      'recycling': ['recycle'],
      'changing room': ['fitting room', 'dressing room'],
      'basement': ['lower level'],
      'hotel': ['inn', 'motel'],
      'reception': ['front desk'],
      'check in': ['check-in', 'registration'],
      'check out': ['check-out'],
      'reservation': ['booking'],
      'vacancy': ['vacancies', 'rooms available'],
      'tourist': ['tourists', 'tourism'],
      'museum': ['gallery'],
      'souvenir': ['souvenirs', 'gift shop'],
      'beach': ['seaside'],
      'pool': ['swimming pool'],
      'gym': ['fitness center', 'fitness centre'],
      'spa': ['sauna'],
      'housekeeping': ['housekeeper'],
      'do not disturb': ['dnd'],
      'concierge': ['guest services'],
      'exchange': ['currency exchange', 'money exchange'],
      'tour': ['tours', 'guided tour'],
      'library': ['public library'],
      'office': ['offices'],
      'hours': ['opening hours', 'business hours'],
      'information': ['info', 'enquiries', 'inquiries'],
      'quiet': ['silence', 'silent'],
      'appointment': ['appointments', 'by appointment'],
      'visitors': ['guests'],
      'return': ['returns'],
      'queue': ['wait here', 'please wait'],
      'counter': ['service counter'],
      'holiday': ['public holiday', 'bank holiday'],
      'admission': ['entry fee', 'entrance fee'],
      'lost and found': ['lost property', 'lost & found'],
      'wifi': ['wi-fi', 'wi fi', 'wlan'],
      'password': ['passcode'],
      'qr code': ['qr', 'qrcode'],
      'scan': ['scanner'],
      'contactless': ['tap to pay', 'nfc'],
      'cashless': ['card only', 'no cash'],
      'barcode': ['bar code'],
      'charging': ['charge', 'charger'],
      'network': ['networks', 'ssid'],
      'login': ['log in', 'log-in', 'sign in'],
      'website': ['web site', 'www', 'web address'],
      'online': ['on line'],
      'download': ['downloads', 'get the app'],
      'touchscreen': ['touch screen', 'touch-screen'],
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

  /// True when 1-4 consecutive whole words of [text], joined without spaces,
  /// equal [target] without spaces (singular or plural form).
  static bool _matchesJoinedWords(String text, String target) {
    final hasSeparator = RegExp(r'[\s\-_]').hasMatch(target);
    final compact = target.replaceAll(RegExp(r'[\s\-_]'), '');
    if (!hasSeparator && compact.length < 6) return false;

    final variants = <String>{
      compact,
      compact.endsWith('s')
          ? compact.substring(0, compact.length - 1)
          : '${compact}s',
    };
    final words = text
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.isNotEmpty)
        .toList();

    for (var start = 0; start < words.length; start++) {
      var joined = '';
      for (var end = start; end < words.length && end < start + 4; end++) {
        joined += words[end];
        if (joined.length > compact.length + 1) break;
        if (variants.contains(joined)) return true;
      }
    }
    return false;
  }

  static bool _containsWordBoundary(String fullText, String word) {
    if (word.isEmpty) return false;
    // Word boundary regex that accounts for punctuation like quotes, colons, exclamation marks
    final escaped = RegExp.escape(word);
    final regex = RegExp(
      '(^|[^a-zA-Z0-9])$escaped([^a-zA-Z0-9]|\$)',
      caseSensitive: false,
    );
    return regex.hasMatch(fullText);
  }
}
