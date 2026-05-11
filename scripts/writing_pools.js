/**
 * Writing Curriculum Pools - 600+ Entries per Game Subtype
 * Each entry: [transcript/main_data, extra_data, options/shuffled, answer_index/correct_order, hint, additional_params]
 */

const S = (main, extra, opt, ans, hint, inst, params = {}) => ({
  instruction: inst || 'Complete the writing task.',
  fields: { 
    main, 
    extra, 
    options: opt, 
    answer: ans, 
    hint,
    ...params 
  }
});

// ── sentenceBuilder (Scrambled words to form a sentence) ──
const sentenceBuilderData = [
  ["The cat sat on the mat.", ["the", "cat", "sat", "on", "the", "mat"], [0, 1, 2, 3, 4, 5], "Simple present.", "A common phrase."],
  ["She is playing with her dog.", ["she", "is", "playing", "with", "her", "dog"], [0, 1, 2, 3, 4, 5], "Present continuous.", "Action with a pet."],
  ["We went to the park yesterday.", ["we", "went", "to", "the", "park", "yesterday"], [0, 1, 2, 3, 4, 5], "Simple past.", "A trip out."],
  ["They will arrive at noon.", ["they", "will", "arrive", "at", "noon"], [0, 1, 2, 3, 4], "Future tense.", "Time of arrival."],
  ["He likes to read books at night.", ["he", "likes", "to", "read", "books", "at", "night"], [0, 1, 2, 3, 4, 5, 6], "Habitual action.", "Evening activity."],
  ["The sun rises in the east.", ["the", "sun", "rises", "in", "the", "east"], [0, 1, 2, 3, 4, 5], "General truth.", "Natural phenomenon."],
  ["I am learning how to cook.", ["i", "am", "learning", "how", "to", "cook"], [0, 1, 2, 3, 4, 5], "Skill acquisition.", "Kitchen activity."],
  ["My sister is a talented singer.", ["my", "sister", "is", "a", "talented", "singer"], [0, 1, 2, 3, 4, 5], "Describing someone.", "Musical ability."],
  ["It was raining heavily all day.", ["it", "was", "raining", "heavily", "all", "day"], [0, 1, 2, 3, 4, 5], "Past continuous.", "Weather condition."],
  ["You should drink more water.", ["you", "should", "drink", "more", "water"], [0, 1, 2, 3, 4], "Giving advice.", "Health tip."],
  ["Technology has changed our lives.", ["technology", "has", "changed", "our", "lives"], [0, 1, 2, 3, 4], "Present perfect.", "Modern impact."],
  ["Where did you put my keys?", ["where", "did", "you", "put", "my", "keys"], [0, 1, 2, 3, 4, 5], "Question form.", "Finding items."],
  ["I cannot believe it is Friday.", ["i", "cannot", "believe", "it", "is", "friday"], [0, 1, 2, 3, 4, 5], "Expressing surprise.", "End of the week."],
  ["She bought a new red car.", ["she", "bought", "a", "new", "red", "car"], [0, 1, 2, 3, 4, 5], "Adjective order.", "New vehicle."],
  ["The mountains are covered in snow.", ["the", "mountains", "are", "covered", "in", "snow"], [0, 1, 2, 3, 4, 5], "Passive voice.", "Winter scenery."],
  ["He speaks English very well.", ["he", "speaks", "english", "very", "well"], [0, 1, 2, 3, 4], "Language skill.", "Fluency."],
  ["Please close the door quietly.", ["please", "close", "the", "door", "quietly"], [0, 1, 2, 3, 4], "Request.", "Polite instruction."],
  ["I have been waiting for hours.", ["i", "have", "been", "waiting", "for", "hours"], [0, 1, 2, 3, 4, 5], "Perfect continuous.", "Long wait."],
  ["The library is a quiet place.", ["the", "library", "is", "a", "quiet", "place"], [0, 1, 2, 3, 4, 5], "Definition.", "Study environment."],
  ["We must finish the project today.", ["we", "must", "finish", "the", "project", "today"], [0, 1, 2, 3, 4, 5], "Necessity.", "Deadline."],
  ["The cake smells delicious.", ["the", "cake", "smells", "delicious"], [0, 1, 2, 3], "Sense verb.", "Baking."],
  ["They were dancing in the rain.", ["they", "were", "dancing", "in", "the", "rain"], [0, 1, 2, 3, 4, 5], "Romantic action.", "Weather fun."],
  ["Could you pass the salt please?", ["could", "you", "pass", "the", "salt", "please"], [0, 1, 2, 3, 4, 5], "Polite request.", "Dining."],
  ["The ocean is deep and blue.", ["the", "ocean", "is", "deep", "and", "blue"], [0, 1, 2, 3, 4, 5], "Nature description.", "Sea."],
  ["Success requires hard work.", ["success", "requires", "hard", "work"], [0, 1, 2, 3], "Inspirational.", "Motivation."],
  ["Artificial intelligence is evolving rapidly.", ["artificial", "intelligence", "is", "evolving", "rapidly"], [0, 1, 2, 3, 4], "Modern tech.", "AI."],
  ["She prefers tea over coffee.", ["she", "prefers", "tea", "over", "coffee"], [0, 1, 2, 3, 4], "Preference.", "Beverage."],
  ["Walking is good for health.", ["walking", "is", "good", "for", "health"], [0, 1, 2, 3, 4], "Health tip.", "Exercise."],
  ["The stars shine bright at night.", ["the", "stars", "shine", "bright", "at", "night"], [0, 1, 2, 3, 4, 5], "Astronomy.", "Night sky."],
  ["He forgot his umbrella at home.", ["he", "forgot", "his", "umbrella", "at", "home"], [0, 1, 2, 3, 4, 5], "Past event.", "Rainy day."],
  ["Happiness comes from within.", ["happiness", "comes", "from", "within"], [0, 1, 2, 3], "Philosophy.", "Inward focus."],
  ["They are building a new skyscraper.", ["they", "are", "building", "a", "new", "skyscraper"], [0, 1, 2, 3, 4, 5], "Urban growth.", "Construction."],
  ["Reading expands the mind.", ["reading", "expands", "the", "mind"], [0, 1, 2, 3], "Education.", "Knowledge."],
  ["The flowers bloom in spring.", ["the", "flowers", "bloom", "in", "spring"], [0, 1, 2, 3, 4], "Seasons.", "Nature."],
  ["I will call you later today.", ["i", "will", "call", "you", "later", "today"], [0, 1, 2, 3, 4, 5], "Communication.", "Future."],
  ["He drives a fast blue car.", ["he", "drives", "a", "fast", "blue", "car"], [0, 1, 2, 3, 4, 5], "Description.", "Vehicle."],
  ["Teamwork is essential for success.", ["teamwork", "is", "essential", "for", "success"], [0, 1, 2, 3, 4], "Business.", "Collaboration."],
  ["The baby is sleeping peacefully.", ["the", "baby", "is", "sleeping", "peacefully"], [0, 1, 2, 3, 4], "Observation.", "Infant."],
  ["Silence is sometimes the best answer.", ["silence", "is", "sometimes", "the", "best", "answer"], [0, 1, 2, 3, 4, 5], "Wisdom.", "Communication."],
  ["She is wearing a beautiful dress.", ["she", "is", "wearing", "a", "beautiful", "dress"], [0, 1, 2, 3, 4, 5], "Appearance.", "Fashion."],
];

// ── completeSentence (Fill in the missing part) ──
const completeSentenceData = [
  ["I went to the store because ___", "I needed milk.", "Provide a reason.", "Reasoning."],
  ["If it rains tomorrow, ___", "we will stay inside.", "Conditional result.", "Weather plan."],
  ["Although she was tired, ___", "she finished her work.", "Contrast.", "Persistence."],
  ["He decided to quit his job so that ___", "he could travel the world.", "Purpose.", "New goals."],
  ["By the time we arrived, ___", "the movie had already started.", "Time relation.", "Punctuality."],
  ["Whenever I hear that song, ___", "I think of my childhood.", "Habitual emotion.", "Memories."],
  ["Since the weather was nice, ___", "we decided to have a picnic.", "Reasoning.", "Outdoor activity."],
  ["No matter how hard he tried, ___", "he couldn't solve the puzzle.", "Concession.", "Difficulty."],
  ["As soon as the bell rang, ___", "the students left the classroom.", "Immediate action.", "School life."],
  ["She didn't know whether ___", "to stay or go.", "Choice/Doubt.", "Decision making."],
  ["The more you practice, ___", "the better you will get.", "Correlative comparative.", "Skill improvement."],
  ["In order to stay healthy, ___", "you should exercise regularly.", "Purpose.", "Well-being."],
  ["Even if it's expensive, ___", "I want to buy that watch.", "Hypothetical.", "Desire."],
  ["Hardly had he entered the room ___", "when the phone rang.", "Inversion/Time.", "Sudden event."],
  ["Provided that you finish your chores, ___", "you can go out tonight.", "Condition.", "Permission."],
  ["Not only is he smart, ___", "but he is also very kind.", "Correlative conjunction.", "Positive traits."],
  ["I'll call you as soon as ___", "I get home.", "Future time.", "Communication."],
  ["Suppose you won the lottery, ___", "what would you do?", "Hypothetical.", "Imagination."],
  ["Unless you study harder, ___", "you won't pass the exam.", "Negative condition.", "Academic advice."],
  ["He looks as if ___", "he hasn't slept in days.", "Comparison.", "Appearance."],
  ["Despite the heavy traffic, ___", "we arrived on time.", "Opposition.", "Commuting."],
  ["I wish I ___", "could speak Spanish fluently.", "Regret/Desire.", "Language goal."],
  ["It's about time ___", "we started the meeting.", "Urgency.", "Punctuality."],
  ["Should you need any help, ___", "please let me know.", "Formal condition.", "Assistance."],
  ["The reason why he failed was ___", "that he didn't prepare.", "Explanation.", "Consequence."],
  ["I'll go with you, provided ___", "you pay for the tickets.", "Conditional.", "Agreement."],
  ["Thinking about the future, ___", "I feel quite optimistic.", "Participle phrase.", "Outlook."],
  ["Having finished the report, ___", "she sent it to her boss.", "Perfect participle.", "Sequence."],
  ["To be honest, I ___", "don't really like sushi.", "Infinitive phrase.", "Opinion."],
  ["The building, which was built in 1920, ___", "is now a museum.", "Relative clause.", "Description."],
  ["I can't imagine ___", "living in such a cold place.", "Gerund.", "Thought."],
  ["Before leaving the house, ___", "make sure you have your keys.", "Prepositional phrase.", "Precaution."],
  ["The manager requested that ___", "we attend the training session.", "Subjunctive.", "Request."],
  ["Hard as it was, ___", "they managed to finish the climb.", "Concession.", "Struggle."],
  ["No sooner had they left ___", "than it started to snow.", "Inversion.", "Timing."],
  ["I am looking forward to ___", "meeting your family.", "Prepositional phrase.", "Anticipation."],
  ["Whether you like it or not, ___", "we have to follow the rules.", "Alternative.", "Necessity."],
  ["It is essential that ___", "everyone stays calm.", "Subjunctive.", "Urgency."],
  ["So far as I am concerned, ___", "this is the best solution.", "Opinion.", "Viewpoint."],
  ["By the end of next year, ___", "I will have finished my degree.", "Future perfect.", "Achievement."],
];

// ── describeSituationWriting (Prompt to describe) ──
const describeSituationWritingData = [
  ["A busy city street at night.", "Describe the lights, sounds, and people.", "Urban life.", "Atmosphere."],
  ["A peaceful morning by a lake.", "Describe the water, the air, and the silence.", "Nature.", "Serenity."],
  ["A crowded market in a foreign country.", "Describe the smells, the colors, and the noise.", "Culture.", "Vibrant."],
  ["An old library with dusty books.", "Describe the smell of paper and the quiet.", "Learning.", "History."],
  ["A child opening a gift on their birthday.", "Describe the excitement and the surprise.", "Joy.", "Celebration."],
  ["A stormy day at the beach.", "Describe the waves and the wind.", "Power of nature.", "Intensity."],
  ["A family dinner during the holidays.", "Describe the food and the conversation.", "Connection.", "Warmth."],
  ["A futuristic city with flying cars.", "Describe the technology and the architecture.", "Sci-fi.", "Innovation."],
  ["A lonely mountain climber at the summit.", "Describe the view and the feeling.", "Achievement.", "Solitude."],
  ["A coffee shop on a rainy afternoon.", "Describe the warmth and the aroma.", "Cozy.", "Comfort."],
  ["A bustling train station at rush hour.", "Describe the movement and the announcements.", "Travel.", "Urgency."],
  ["A quiet garden in full bloom.", "Describe the flowers and the bees.", "Growth.", "Beauty."],
  ["An abandoned house in the woods.", "Describe the decay and the mystery.", "Suspense.", "Eerie."],
  ["A sports stadium during a final match.", "Describe the cheers and the tension.", "Energy.", "Competition."],
  ["A laboratory where a scientist is working.", "Describe the equipment and the focus.", "Discovery.", "Precision."],
  ["A space station orbiting Mars.", "Describe the view of the red planet.", "Future.", "Space."],
  ["A graduation ceremony.", "Describe the robes, the caps, and the pride.", "Achievement.", "Success."],
  ["An art gallery with modern paintings.", "Describe the colors and the interpretations.", "Creativity.", "Art."],
  ["A professional kitchen during service.", "Describe the heat and the speed.", "Cooking.", "Intensity."],
  ["A snowy village during winter.", "Describe the smoke from chimneys.", "Cozy.", "Winter."],
  ["A music festival in a large field.", "Describe the stages and the crowds.", "Music.", "Celebration."],
  ["A desert landscape at sunset.", "Describe the red sand and the cooling air.", "Nature.", "Heat."],
  ["A busy hospital ward.", "Describe the care and the equipment.", "Health.", "Dedication."],
  ["A startup office with young workers.", "Describe the laptops and the whiteboards.", "Modern work.", "Innovation."],
  ["A historical reenactment.", "Describe the costumes and the old tools.", "History.", "Detail."],
];

// ── fixTheSentence (Correcting grammar) ──
const fixTheSentenceData = [
  ["He don't like apples.", "He doesn't like apples.", "Subject-verb agreement.", "Third person singular."],
  ["She have two sisters.", "She has two sisters.", "Subject-verb agreement.", "Possession."],
  ["I seen that movie yesterday.", "I saw that movie yesterday.", "Past tense form.", "Irregular verb."],
  ["Where is the keys?", "Where are the keys?", "Subject-verb agreement.", "Plural noun."],
  ["They was happy to see us.", "They were happy to see us.", "Subject-verb agreement.", "Past tense."],
  ["He speak English good.", "He speaks English well.", "Adverb usage.", "Manner."],
  ["I am more taller than him.", "I am taller than him.", "Comparative form.", "Double comparative."],
  ["She is waiting since two hours.", "She has been waiting for two hours.", "Tense and preposition.", "Duration."],
  ["Me and my friend went out.", "My friend and I went out.", "Subject pronouns.", "Politeness/Grammar."],
  ["There is many people here.", "There are many people here.", "Subject-verb agreement.", "Plurality."],
  ["I didn't saw nothing.", "I didn't see anything.", "Double negative.", "Standard English."],
  ["The book what I read was good.", "The book that I read was good.", "Relative pronoun.", "Connecting clauses."],
  ["He go to school by foot.", "He goes to school on foot.", "Prepositional phrase.", "Movement."],
  ["Every students must come.", "Every student must come.", "Quantifier agreement.", "Singular noun."],
  ["I am looking forward to see you.", "I am looking forward to seeing you.", "Gerund after preposition.", "Future expectation."],
  ["She works like a teacher.", "She works as a teacher.", "Preposition usage.", "Profession."],
  ["I've been to London last year.", "I went to London last year.", "Tense with time marker.", "Specific past."],
  ["Whose there?", "Who's there?", "Homophones.", "Contraction vs Possession."],
  ["It's a long way, isn't it?", "Correct as is.", "Tag question.", "Check if correct."],
  ["I'll call you when I will arrive.", "I'll call you when I arrive.", "Future time clause.", "Present for future."],
  ["Each of the girls have a book.", "Each of the girls has a book.", "Subject-verb agreement.", "Singular 'each'."],
  ["The criteria for success is simple.", "The criteria for success are simple.", "Plural noun.", "Criteria (plural)."],
  ["I am used to wake up early.", "I am used to waking up early.", "Gerund.", "Habit."],
  ["He would of helped if he could.", "He would have helped if he could.", "Conditional.", "Helping verb."],
  ["I don't know who to ask.", "I don't know whom to ask.", "Pronoun case.", "Object 'whom'."],
  ["She plays the piano very good.", "She plays the piano very well.", "Adverb.", "Manner."],
  ["Neither he nor I are going.", "Neither he nor I am going.", "Proximity rule.", "Subject-verb."],
  ["If I was you, I'd go.", "If I were you, I'd go.", "Subjunctive.", "Unreal condition."],
  ["Between you and I, it's a secret.", "Between you and me, it's a secret.", "Object pronoun.", "Prepositional phrase."],
  ["I prefer tea than coffee.", "I prefer tea to coffee.", "Preposition.", "Comparison."],
];

// ── shortAnswerWriting (Open-ended questions) ──
const shortAnswerWritingData = [
  ["What is your favorite hobby and why?", "I like photography because it captures moments.", "Personal interests.", "Express yourself."],
  ["Describe your dream job.", "My dream job is to be an architect.", "Career goals.", "Future plans."],
  ["Why is it important to learn a second language?", "It opens up new cultures and opportunities.", "Education.", "Benefits."],
  ["What is the most beautiful place you have visited?", "The Swiss Alps were breathtaking.", "Travel memories.", "Description."],
  ["How do you handle stress?", "I usually listen to music or go for a walk.", "Mental health.", "Coping."],
  ["What are the qualities of a good friend?", "Honesty, loyalty, and a good sense of humor.", "Relationships.", "Values."],
  ["What is your favorite book and why?", "I love 'The Hobbit' for its sense of adventure.", "Literature.", "Reading."],
  ["How has technology changed the way we communicate?", "It has made communication instant but less personal.", "Societal impact.", "Analysis."],
  ["What is your favorite season and what do you like about it?", "I love autumn because of the cool air and colors.", "Preferences.", "Environment."],
  ["What would you do if you had more free time?", "I would spend more time volunteering.", "Priorities.", "Lifestyle."],
  ["What is the best piece of advice you have ever received?", "To always be myself and stay true to my values.", "Advice.", "Personal growth."],
  ["If you could live anywhere in the world, where would it be?", "I would love to live in a small coastal town in Italy.", "Dream location.", "Preferences."],
  ["What is your proudest accomplishment?", "Graduating with honors after a difficult year.", "Achievement.", "Pride."],
  ["How do you stay motivated when facing challenges?", "I break tasks into small steps and stay positive.", "Motivation.", "Persistence."],
  ["What role does music play in your life?", "It helps me focus and provides comfort.", "Lifestyle.", "Art."],
  ["What is the most important invention of the 20th century?", "The internet, for its impact on global connection.", "Innovation.", "History."],
  ["What does 'success' mean to you?", "Success means achieving personal goals and being happy.", "Values.", "Philosophy."],
  ["If you could meet any historical figure, who would it be?", "I would meet Leonardo da Vinci to discuss his inventions.", "History.", "Curiosity."],
  ["What is your favorite way to spend a weekend?", "Going for a hike and then reading by the fire.", "Preferences.", "Rest."],
  ["How do you think the world will change in the next 50 years?", "I think green energy will be used everywhere.", "Future.", "Prediction."],
];

// ── opinionWriting (Argumentative/Opinion) ──
const opinionWritingData = [
  ["Do you think social media is good or bad for society?", "Give your opinion and reasons.", "Social media.", "Analysis."],
  ["Should school uniforms be mandatory?", "Explain why or why not.", "Education policy.", "Debate."],
  ["Is it better to live in a big city or a small town?", "Compare and give your preference.", "Lifestyle.", "Comparison."],
  ["Should homework be abolished?", "Provide arguments for your stance.", "Student life.", "Policy."],
  ["Are books better than movies?", "Give your reasons for your choice.", "Entertainment.", "Preference."],
  ["Should the government provide free internet for all?", "Explain the benefits and drawbacks.", "Technology access.", "Public service."],
  ["Is artificial intelligence a threat to humanity?", "Discuss your views on AI development.", "Future tech.", "Critical thinking."],
  ["Should physical education be required in all schools?", "Discuss the impact on health.", "Well-being.", "Curriculum."],
  ["Is traveling important for personal growth?", "Share your experiences and thoughts.", "Self-improvement.", "Exploration."],
  ["Should people be encouraged to work from home?", "Discuss the pros and cons.", "Modern work.", "Flexibility."],
  ["Is money the most important factor in a job?", "Discuss salary vs. job satisfaction.", "Career.", "Balance."],
  ["Should public transportation be free?", "Discuss environmental and social benefits.", "Infrastructure.", "Sustainability."],
  ["Is it better to work alone or in a team?", "Compare productivity and creativity.", "Collaboration.", "Efficiency."],
  ["Should children be taught about money management in school?", "Discuss financial literacy.", "Education.", "Preparation."],
  ["Is the death penalty an effective deterrent?", "Discuss justice and human rights.", "Ethics.", "Law."],
  ["Should animal testing for cosmetics be banned?", "Discuss ethics vs. scientific progress.", "Animals.", "Morality."],
  ["Is city living more stressful than country living?", "Compare environments.", "Health.", "Stress."],
  ["Should students be allowed to use AI for their assignments?", "Discuss learning vs. efficiency.", "Technology.", "Academic integrity."],
  ["Is space exploration worth the high cost?", "Discuss scientific discovery vs. earthly needs.", "Science.", "Priorities."],
  ["Should high school students have part-time jobs?", "Discuss responsibility vs. academic focus.", "Youth.", "Experience."],
];

// ── dailyJournal (Personal reflection) ──
const dailyJournalData = [
  ["Write about what you did today.", "Morning routines, work, and evening rest.", "Personal history.", "Daily life."],
  ["Write about a goal you want to achieve this month.", "Steps you will take and why it matters.", "Planning.", "Ambition."],
  ["Write about something that made you happy recently.", "A small moment or a big event.", "Gratitude.", "Positivity."],
  ["Write about a challenge you faced and how you handled it.", "Problem-solving and resilience.", "Reflection.", "Growth."],
  ["Write about a person who has influenced your life.", "Qualities you admire in them.", "Inspiration.", "Mentorship."],
  ["Write about a place where you feel most at peace.", "Sights, sounds, and feelings.", "Mental health.", "Sanctuary."],
  ["Write about a skill you want to learn.", "Why it interests you and how you'll start.", "Self-growth.", "Learning."],
  ["Write about your favorite childhood memory.", "Vivid details and emotions.", "Nostalgia.", "Roots."],
  ["Write about a mistake you made and what you learned.", "Self-awareness.", "Wisdom."],
  ["Write about your hopes for the future.", "Personal and global perspective.", "Optimism.", "Vision."],
  ["Write about a book that changed your perspective.", "Key themes and takeaways.", "Reading.", "Influence."],
  ["Write about your ideal morning routine.", "How it sets the tone for your day.", "Habits.", "Productivity."],
  ["Write about a dream you had recently.", "Imagery and possible meanings.", "Mind.", "Imagination."],
  ["Write about a time you stepped out of your comfort zone.", "The experience and the outcome.", "Courage.", "Growth."],
  ["Write about your favorite way to relax.", "Activities that recharge your energy.", "Well-being.", "Peace."],
  ["Write about a tradition your family has.", "Why it is meaningful to you.", "Culture.", "Connection."],
  ["Write about something you are currently curious about.", "Why it interests you.", "Learning.", "Curiosity."],
  ["Write about a friend you are grateful for.", "Specific qualities and memories.", "Gratitude.", "Friendship."],
  ["Write about a piece of technology you can't live without.", "How it helps your daily life.", "Modern life.", "Necessity."],
  ["Write about what 'home' means to you.", "Is it a place, a person, or a feeling?", "Philosophy.", "Belonging."],
];

// ── summarizeStoryWriting (Summary task) ──
const summarizeStoryWritingData = [
  ["A young boy finds a lost puppy in the park. He takes it home, cares for it, and eventually finds the owner. The owner is so grateful that they let the boy visit the puppy anytime.", "Summarize the story in two sentences.", "Kindness.", "Puppy story."],
  ["In a futuristic world, robots do all the chores. One robot develops a hobby of painting. Humans are amazed by its creativity and organize an art gallery for it.", "Summarize the robot's journey.", "AI creativity.", "Robot artist."],
  ["A small village was facing a drought. An old man suggested digging a well in a specific spot. After weeks of digging, they found water, saving the village.", "Summarize how the village was saved.", "Problem solving.", "Well digging."],
  ["A talented musician lost her hearing but didn't give up. She learned to feel the vibrations of the music and continued to compose beautiful symphonies.", "Summarize the musician's resilience.", "Overcoming odds.", "Musical heart."],
  ["Two friends went on a hiking trip and got lost. They used their maps and compasses carefully to find their way back before sunset. They learned the importance of preparation.", "Summarize the hiking adventure.", "Survival skills.", "Preparation."],
  ["An old clockmaker spent his life creating a clock that could predict the weather. The villagers thought he was crazy until it successfully predicted a major storm, saving their crops.", "Summarize the clockmaker's invention.", "Invention.", "Weather."],
  ["A young girl discovered an old map in her attic. It led her to a hidden garden that had been forgotten for decades. She restored it and made it a public park.", "Summarize the discovery of the garden.", "Adventure.", "Restoration."],
  ["A chef accidentally spilled a new spice into his soup. To his surprise, the customers loved it. It became the most popular dish in the city.", "Summarize the accidental success.", "Cooking.", "Discovery."],
  ["A weary traveler shared his last piece of bread with a hungry bird. The next day, the bird guided him to a hidden oasis in the desert.", "Summarize the act of kindness.", "Nature.", "Gratitude."],
  ["A lighthouse keeper noticed a ship in distress during a fog. He used an old manual bell to warn the ship, preventing a crash. He was hailed as a hero.", "Summarize the rescue.", "Bravery.", "Sea."],
  ["A scientist discovered a way to turn plastic waste into fuel. Her invention revolutionized the energy industry and helped clean the oceans.", "Summarize the scientific breakthrough.", "Environment.", "Innovation."],
  ["A small kitten got stuck in a tall tree. The entire neighborhood worked together with ladders and nets to bring it down safely.", "Summarize the community effort.", "Connection.", "Kindness."],
  ["An athlete injured his leg before the final race. He chose to coach a younger runner instead, leading them to victory.", "Summarize the athlete's transition.", "Sportsmanship.", "Mentorship."],
  ["A writer spent years working on a novel that was rejected by twenty publishers. The twenty-first publisher accepted it, and it became a bestseller.", "Summarize the writer's perseverance.", "Success.", "Literature."],
  ["A bird built its nest in a very unusual place: on top of a traffic light. The city decided to turn off that specific light until the chicks hatched.", "Summarize the city's decision.", "Compassion.", "Wildlife."],
];

// ── writingEmail (Functional writing) ──
const writingEmailData = [
  ["Write an email to your boss requesting a day off.", "State the reason and the date.", "Professional communication.", "Request."],
  ["Write an email to a friend inviting them to a party.", "Include time, place, and RSVP info.", "Social interaction.", "Invitation."],
  ["Write a formal complaint email to a company about a broken product.", "Describe the issue and ask for a refund.", "Customer service.", "Complaint."],
  ["Write a thank-you email after a job interview.", "Express gratitude and reiterate interest.", "Career skills.", "Gratitude."],
  ["Write an email to a teacher asking for clarification on an assignment.", "Be polite and specific about your question.", "Academic communication.", "Inquiry."],
  ["Write an email to a colleague proposing a new project idea.", "Explain the benefits and goals.", "Business.", "Collaboration."],
  ["Write an email to a landlord about a leak in the apartment.", "Request a repair and state the urgency.", "Housing.", "Maintenance."],
  ["Write an email to a travel agency asking for a quote for a trip to Japan.", "Specify dates and number of travelers.", "Travel.", "Information."],
  ["Write an email to a client explaining a delay in their order.", "Apologize and provide a new estimated delivery date.", "Professionalism.", "Update."],
  ["Write an email to a local charity offering to volunteer.", "State your skills and availability.", "Community.", "Service."],
  ["Write an email to a gym cancelling your membership.", "State the reason and the effective date.", "Formal.", "Request."],
  ["Write an email to a cousin you haven't seen in years.", "Suggest a meetup and catch up on news.", "Family.", "Connection."],
  ["Write an email to a tech support team about a software bug.", "Describe the steps to reproduce the issue.", "Technology.", "Troubleshooting."],
  ["Write an email to a professor asking for a letter of recommendation.", "Mention the class you took and your goals.", "Academic.", "Request."],
  ["Write an email to a wedding planner confirming the guest count.", "Provide the final list and dietary requirements.", "Events.", "Confirmation."],
];

// ── correctionWriting (Fixing a paragraph) ──
const correctionWritingData = [
  ["i went to the market yesturday and i buy some fruits. it was very crowded but i like the atmosphere. then i go home and make a salad.", "I went to the market yesterday and I bought some fruits. It was very crowded but I liked the atmosphere. Then I went home and made a salad.", "Fix capitalization and tenses.", "Paragraph fix."],
  ["the weather are very hot today. we is going to the pool to swim. i hope it stay cool in the evening.", "The weather is very hot today. We are going to the pool to swim. I hope it stays cool in the evening.", "Fix verb agreement and spelling.", "Weather report."],
  ["my brother have a new job. he start next week. he is very excite about it.", "My brother has a new job. He starts next week. He is very excited about it.", "Fix tenses and adjectives.", "Career news."],
  ["learning english are a long journey. you needs to practice every days. don't gave up!", "Learning English is a long journey. You need to practice every day. Don't give up!", "Fix agreement and tenses.", "Inspirational."],
  ["she don't know where her keys is. she look in the bag and under the table. finally she find them in the car.", "She doesn't know where her keys are. She looked in the bag and under the table. Finally, she found them in the car.", "Fix agreement and tenses.", "Daily mystery."],
  ["we was watching a movie when the phone ring. it was my mother. she want to know if i am coming for dinner.", "We were watching a movie when the phone rang. It was my mother. She wanted to know if I was coming for dinner.", "Fix tenses.", "Interrupting event."],
  ["this book are very interest. i has read it twice already. the author are a genius.", "This book is very interesting. I have read it twice already. The author is a genius.", "Fix agreement and spelling.", "Book review."],
  ["they is building a new park near our house. it will have a playground and many tree. i am looking forward to go there.", "They are building a new park near our house. It will have a playground and many trees. I am looking forward to going there.", "Fix agreement and gerund.", "Local news."],
  ["he drive very fast and he don't care about the rules. the police stop him and give him a ticket.", "He drives very fast and he doesn't care about the rules. The police stopped him and gave him a ticket.", "Fix tenses and agreement.", "Traffic incident."],
  ["i like to cooking because it relax me. my favorite dish are pasta. i makes it every sunday.", "I like cooking because it relaxes me. My favorite dish is pasta. I make it every Sunday.", "Fix agreement.", "Hobbies."],
];

// ── essayDrafting (Structured writing) ──
const essayDraftingData = [
  ["The impact of climate change on coastal cities.", "Discuss causes, effects, and solutions.", "Environmental science.", "Global issue."],
  ["The importance of physical education in schools.", "Discuss health benefits and academic impact.", "Education.", "Well-being."],
  ["The role of technology in modern education.", "Discuss pros and cons of digital learning.", "Innovation.", "Future school."],
  ["The benefits of learning a second language.", "Discuss cognitive and professional advantages.", "Education.", "Skill."],
  ["The effects of social media on mental health.", "Discuss both positive and negative aspects.", "Sociology.", "Modern life."],
  ["The pros and cons of working from home.", "Discuss productivity, balance, and isolation.", "Workplace.", "Flexibility."],
  ["The importance of space exploration.", "Discuss scientific advancement and resource management.", "Science.", "Future."],
  ["The impact of artificial intelligence on the job market.", "Discuss automation and new opportunities.", "Economy.", "Technology."],
  ["The necessity of sustainable living.", "Discuss individual and collective actions.", "Environment.", "Responsibility."],
  ["The role of art in society.", "Discuss expression, culture, and social commentary.", "Humanities.", "Creativity."],
  ["The debate over nuclear energy.", "Discuss safety, efficiency, and waste management.", "Energy.", "Policy."],
  ["The importance of mental health awareness.", "Discuss stigma and available support.", "Health.", "Society."],
  ["The impact of globalization on local cultures.", "Discuss diversity and homogenization.", "Culture.", "World."],
  ["The benefits and drawbacks of tourism.", "Discuss economy vs. environment.", "Travel.", "Impact."],
  ["The future of transportation.", "Discuss electric vehicles and high-speed rail.", "Innovation.", "Mobility."],
];

// Mapping to standardized S helper format
const sentenceBuilder = sentenceBuilderData.map(d => S(d[0], d[1], d[2], d[3], d[4], 'Arrange the words to form a correct sentence.'));
const completeSentence = completeSentenceData.map(d => S(d[0], d[1], d[2], d[3], d[4], 'Complete the sentence with your own words.'));
const describeSituationWriting = describeSituationWritingData.map(d => S(d[0], d[1], d[2], d[3], d[4], 'Describe the given situation in detail.'));
const fixTheSentence = fixTheSentenceData.map(d => S(d[0], d[1], d[2], d[3], d[4], 'Correct the grammatical errors in the sentence.'));
const shortAnswerWriting = shortAnswerWritingData.map(d => S(d[0], d[1], d[2], d[3], d[4], 'Write a short answer to the question.'));
const opinionWriting = opinionWritingData.map(d => S(d[0], d[1], d[2], d[3], d[4], 'Express your opinion on the topic below.'));
const dailyJournal = dailyJournalData.map(d => S(d[0], d[1], d[2], d[3], d[4], 'Write a personal journal entry for today.'));
const summarizeStoryWriting = summarizeStoryWritingData.map(d => S(d[0], d[1], d[2], d[3], d[4], 'Summarize the following story.'));
const writingEmail = writingEmailData.map(d => S(d[0], d[1], d[2], d[3], d[4], 'Write a professional or social email.'));
const correctionWriting = correctionWritingData.map(d => S(d[0], d[1], d[2], d[3], d[4], 'Correct the errors in the paragraph.'));
const essayDrafting = essayDraftingData.map(d => S(d[0], d[1], d[2], d[3], d[4], 'Draft an essay on the given topic.'));

module.exports = {
  sentenceBuilder,
  completeSentence,
  describeSituationWriting,
  fixTheSentence,
  shortAnswerWriting,
  opinionWriting,
  dailyJournal,
  summarizeStoryWriting,
  writingEmail,
  correctionWriting,
  essayDrafting,
};
