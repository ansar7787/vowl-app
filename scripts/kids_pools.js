/**
 * Kids Zone Content Pools - EMOJI FIRST (Free & High Quality)
 * Focus: Visual Learning & Easy Questions
 */

const K = (inst, q, opt, correct, hint) => ({ 
  instruction: inst, 
  question: q, 
  options: opt, 
  correctAnswer: correct, 
  hint: hint 
});

const alphabet = [
  K("A is for...?", "A", ["🍎", "🐶", "🍌"], "🍎", "Apple starts with A!"),
  K("B is for...?", "B", ["🚗", "🐝", "🐱"], "🐝", "Bee starts with B!"),
  K("C is for...?", "C", ["🐱", "🏠", "🌲"], "🐱", "Cat starts with C!"),
  K("D is for...?", "D", ["🐕", "🍎", "🎈"], "🐕", "Dog starts with D!"),
  K("E is for...?", "E", ["🐘", "🍉", "🚁"], "🐘", "Elephant starts with E!"),
  K("Find the letter A", "🍎", ["A", "B", "C"], "A", "A for Apple!"),
  K("Find the letter B", "🐝", ["B", "P", "D"], "B", "B for Bee!"),
];

const numbers = [
  K("How many apples? 🍎🍎", "🍎🍎", ["1", "2", "3"], "2", "One, Two!"),
  K("Count the stars! ⭐⭐⭐⭐⭐", "⭐⭐⭐⭐⭐", ["4", "5", "6"], "5", "Five stars!"),
  K("Find the number 1", "👆", ["1", "2", "3"], "1", "One finger!"),
  K("Which is BIGGER?", "🐘🐭", ["Elephant", "Mouse"], "Elephant", "Elephants are huge!"),
  K("Find number 3", "🎈🎈🎈", ["2", "3", "4"], "3", "Three balloons!"),
];

const colors = [
  K("What color is this?", "🔴", ["Red", "Blue", "Green"], "Red", "It's Red!"),
  K("What color is the sun?", "☀️", ["Yellow", "Purple", "Pink"], "Yellow", "Yellow sun!"),
  K("Find the BLUE one", "🎨", ["🔵", "🔴", "🟢"], "🔵", "Blue like the sky!"),
  K("What color is grass?", "🌱", ["Green", "Orange", "Black"], "Green", "Green grass!"),
  K("Find the ORANGE", "🍊", ["Orange", "Blue", "Red"], "Orange", "Orange fruit!"),
];

const shapes = [
  K("What shape is this?", "⭕", ["Circle", "Square", "Triangle"], "Circle", "Round like a ball!"),
  K("Find the SQUARE", "📦", ["Square", "Circle", "Star"], "Square", "Boxes are square!"),
  K("How many sides?", "🔺", ["3", "4", "0"], "3", "Triangle has 3 sides!"),
  K("Find the STAR", "⭐", ["Star", "Square", "Oval"], "Star", "Twinkle twinkle!"),
  K("What shape is a window?", "🪟", ["Square", "Circle", "Heart"], "Square", "Most windows are square!"),
];

const animals = [
  K("Who says MOO?", "🐮", ["Cow", "Lion", "Pig"], "Cow", "Cows say moo!"),
  K("Find the LION", "🦁", ["Lion", "Monkey", "Tiger"], "Lion", "King of the jungle!"),
  K("Who has a long neck?", "🦒", ["Giraffe", "Elephant", "Dog"], "Giraffe", "Giraffes are tall!"),
  K("Find the DOG", "🐕", ["Dog", "Cat", "Bird"], "Dog", "Woof woof!"),
  K("Where is the MONKEY?", "🐒", ["Monkey", "Snake", "Fish"], "Monkey", "Monkeys love bananas!"),
];

const fruits = [
  K("Find the APPLE", "🍎", ["Apple", "Grape", "Banana"], "Apple", "Red and sweet!"),
  K("What fruit is this?", "🍌", ["Banana", "Pear", "Mango"], "Banana", "Yellow banana!"),
  K("Find the GRAPES", "🍇", ["Grapes", "Orange", "Kiwi"], "Grapes", "Purple grapes!"),
  K("Which is SOUR?", "🍋", ["Lemon", "Strawberry", "Melon"], "Lemon", "Lemons are sour!"),
  K("Find the WATERMELON", "🍉", ["Watermelon", "Cherry", "Peach"], "Watermelon", "Big and green!"),
];

const emotions = [
  K("How do they feel?", "😊", ["Happy", "Sad", "Angry"], "Happy", "A big smile!"),
  K("Find the SAD face", "😢", ["Happy", "Sad", "Tired"], "Sad", "They are crying!"),
  K("Who is ANGRY?", "😡", ["Angry", "Cool", "Surprised"], "Angry", "Red face!"),
  K("Find the SLEEPY one", "😴", ["Sleepy", "Excited", "Scared"], "Sleepy", "Time for bed!"),
  K("Who is SURPRISED?", "😮", ["Surprised", "Bored", "Happy"], "Surprised", "Oh wow!"),
];

const transport = [
  K("Which one flies?", "✈️", ["Airplane", "Car", "Train"], "Airplane", "High in the sky!"),
  K("What has 2 wheels?", "🚲", ["Bicycle", "Truck", "Bus"], "Bicycle", "Ride your bike!"),
  K("Find the BOAT", "🚢", ["Boat", "Plane", "Rocket"], "Boat", "On the water!"),
  K("Which is very FAST?", "🚀", ["Rocket", "Walking", "Scooter"], "Rocket", "To the moon!"),
  K("Find the POLICE car", "🚓", ["Police", "Ambulance", "Taxi"], "Police", "Nee-naw!"),
];

const nature = [
  K("Find the FLOWER", "🌸", ["Flower", "Rock", "Sand"], "Flower", "Smells nice!"),
  K("What is this?", "🌳", ["Tree", "Cloud", "Sun"], "Tree", "Green tree!"),
  K("Find the RAIN", "🌧️", ["Rain", "Snow", "Wind"], "Rain", "Wet water!"),
  K("What is in the sky?", "☁️", ["Cloud", "Grass", "Flower"], "Cloud", "White and fluffy!"),
  K("Find the MOON", "🌙", ["Moon", "Sun", "Star"], "Moon", "At night!"),
];

const home_kids = [
  K("Where do we sleep?", "🛏️", ["Bedroom", "Kitchen", "Garden"], "Bedroom", "In our bed!"),
  K("Find the HOUSE", "🏠", ["House", "Car", "Park"], "House", "Home sweet home!"),
  K("What do we sit on?", "🪑", ["Chair", "Stove", "Window"], "Chair", "Sit down please!"),
  K("Where is the TV?", "📺", ["Living Room", "Bathroom"], "Living Room", "Watching cartoons!"),
  K("Find the BATH", "🛁", ["Bathroom", "Kitchen"], "Bathroom", "Splish splash!"),
];

const school = [
  K("What do we use to draw?", "🖍️", ["Crayon", "Spoon", "Shoe"], "Crayon", "Colorful drawing!"),
  K("Find the BACKPACK", "🎒", ["Backpack", "Pillow", "Hat"], "Backpack", "For school!"),
  K("Who is the TEACHER?", "👩‍🏫", ["Teacher", "Baby", "Pet"], "Teacher", "They help us learn!"),
  K("Find the BOOK", "📖", ["Book", "Plate", "Ball"], "Book", "Let's read!"),
  K("What do we use to cut?", "✂️", ["Scissors", "Pencil", "Eraser"], "Scissors", "Be careful!"),
];

const verbs = [
  K("Who is RUNNING?", "🏃", ["Running", "Sitting", "Sleeping"], "Running", "Go fast!"),
  K("Find the DANCER", "💃", ["Dancing", "Eating", "Reading"], "Dancing", "Move to music!"),
  K("Who is EATING?", "😋", ["Eating", "Crying", "Jumping"], "Eating", "Yummy food!"),
  K("Find the SWIMMER", "🏊", ["Swimming", "Flying", "Driving"], "Swimming", "In the pool!"),
  K("Who is SINGING?", "🎤", ["Singing", "Writing", "Walking"], "Singing", "La la la!"),
];

const food_kids = [
  K("Find the PIZZA", "🍕", ["Pizza", "Salad", "Soup"], "Pizza", "Cheesy slice!"),
  K("What is SWEET?", "🍦", ["Ice Cream", "Broccoli", "Egg"], "Ice Cream", "Cold and sweet!"),
  K("Find the MILK", "🥛", ["Milk", "Water", "Juice"], "Milk", "White drink!"),
  K("Which is a VEGETABLE?", "🥦", ["Broccoli", "Candy", "Cookie"], "Broccoli", "Green and healthy!"),
  K("Find the DONUT", "🍩", ["Donut", "Bread", "Cheese"], "Donut", "With sprinkles!"),
];

const prepositions = [
  K("The bird is IN the cage", "🐦📥", ["In", "On", "Under"], "In", "Inside!"),
  K("The cat is ON the mat", "🐱🔝", ["On", "In", "Behind"], "On", "On top!"),
  K("Under the umbrella", "☔👇", ["Under", "Over", "Beside"], "Under", "Below!"),
  K("Next to each other", "👫", ["Next to", "Far away"], "Next to", "Side by side!"),
];

const phonics = [
  K("What sound does 🐍 make?", "🐍", ["Sss", "Buh", "Moo"], "Sss", "Snake hiss!"),
  K("Which starts with 'B'?", "🐝", ["Bee", "Ant", "Cat"], "Bee", "B-B-Bee!"),
  K("Find the rhyming word", "🐱", ["Hat", "Dog", "Pig"], "Hat", "Cat and Hat!"),
  K("What starts with 'P'?", "🍕", ["Pizza", "Apple", "Banana"], "Pizza", "P-P-Pizza!"),
];

const time = [
  K("When is it dark?", "🌙", ["Night", "Day"], "Night", "Time for bed!"),
  K("What tells time?", "⏰", ["Clock", "Book", "Toy"], "Clock", "Tick tock!"),
  K("When do we eat breakfast?", "🌅", ["Morning", "Evening"], "Morning", "Sun is rising!"),
];

const opposites = [
  K("Opposite of BIG", "🐘", ["Small", "Huge"], "Small", "Elephant is big, Mouse is small!"),
  K("Opposite of HOT", "🔥", ["Cold", "Warm"], "Cold", "Ice is cold!"),
  K("Opposite of FAST", "🏎️", ["Slow", "Quick"], "Slow", "Turtle is slow!"),
  K("Opposite of HAPPY", "😊", ["Sad", "Angry"], "Sad", "Frown is sad!"),
];

const family = [
  K("Who is the BABY?", "👶", ["Baby", "Daddy", "Mommy"], "Baby", "Goo goo ga ga!"),
  K("Find the GRANDMA", "👵", ["Grandma", "Brother", "Sister"], "Grandma", "She loves you!"),
  K("Who is the SISTER?", "👧", ["Sister", "Brother", "Uncle"], "Sister", "She is a girl!"),
];

const day_night = [
  K("We see the SUN during...", "☀️", ["Day", "Night"], "Day", "Bright day!"),
  K("We see STARS during...", "✨", ["Night", "Day"], "Night", "Sparkle sparkle!"),
  K("Time for Pajamas!", "🛌", ["Night", "Day"], "Night", "Going to sleep!"),
];

const routine = [
  K("Wash your hands!", "🧼", ["Clean", "Dirty"], "Clean", "Keep germs away!"),
  K("Brush your teeth!", "🪥", ["Teeth", "Hair"], "Teeth", "Sparkling smile!"),
  K("Time for a bath!", "🛁", ["Bath", "Lunch"], "Bath", "Splish splash!"),
];

module.exports = {
  alphabet, numbers, colors, shapes, animals, fruits, family, school, verbs, routine,
  emotions, prepositions, phonics, time, opposites, day_night, nature, home_kids, food_kids, transport
};
