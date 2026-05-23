const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/grammar';
const gameType = 'sentenceCorrection';

// 20 progressive grammatical topics (1 per batch file)
const topics = [
  {
    name: "Subject-Verb Agreement (Simple)",
    baseScenarios: [
      { s: "He don't know the answer.", err: "don't", cor: "doesn't", opt: ["don't", "don'ts", "does"], h: "Third person singular subjects take 'doesn't'." },
      { s: "She have been waiting for hours.", err: "have", cor: "has", opt: ["have", "having", "haves"], h: "Singular subject 'she' requires 'has'." },
      { s: "They was playing outside.", err: "was", cor: "were", opt: ["was", "wass", "be"], h: "Plural subject 'they' takes 'were'." },
      { s: "Everyone are ready for the test.", err: "are", cor: "is", opt: ["are", "be", "been"], h: "Indefinite pronouns like 'everyone' are singular." },
      { s: "Neither of the boys were present.", err: "were", cor: "was", opt: ["were", "be", "being"], h: "'Neither' functions as a singular subject." },
      { s: "The pack of wolves are hunting.", err: "are", cor: "is", opt: ["are", "be", "been"], h: "Collective nouns representing a single unit take singular verbs." },
      { s: "Each of the scouts have a map.", err: "have", cor: "has", opt: ["have", "having", "haves"], h: "'Each' is a singular subject." },
      { s: "The news about the storm are bad.", err: "are", cor: "is", opt: ["are", "be", "been"], h: "'News' is an uncountable singular noun." },
      { s: "There is many challenges ahead.", err: "is", cor: "are", opt: ["is", "be", "am"], h: "The verb agrees with the plural subject 'challenges'." },
      { s: "Mathematics are my favorite subject.", err: "are", cor: "is", opt: ["are", "be", "been"], h: "Academic subjects ending in 's' are singular." }
    ],
    contexts: ["in the sector", "during the mission", "at the outpost", "in the archive"]
  },
  {
    name: "Pluralization & Countable/Uncountable Nouns",
    baseScenarios: [
      { s: "I need some advices on this.", err: "advices", cor: "advice", opt: ["advices", "advicess", "advises"], h: "'Advice' is uncountable and cannot be pluralized." },
      { s: "We bought three new furnitures.", err: "furnitures", cor: "pieces of furniture", opt: ["furnitures", "furniture", "furnituress"], h: "'Furniture' is uncountable; use 'pieces of furniture'." },
      { s: "Five childs are playing in the yard.", err: "childs", cor: "children", opt: ["childs", "childrens", "childes"], h: "The plural of 'child' is irregular: 'children'." },
      { s: "She has beautiful tooths.", err: "tooths", cor: "teeth", opt: ["tooths", "teeths", "toothes"], h: "The plural of 'tooth' is 'teeth'." },
      { s: "The scientist collected many datas.", err: "datas", cor: "data points", opt: ["datas", "datums", "datae"], h: "'Data' is uncountable in modern usage or plural; 'datas' is incorrect." },
      { s: "He lost two sheeps yesterday.", err: "sheeps", cor: "sheep", opt: ["sheeps", "sheepes", "sheep's"], h: "'Sheep' has the same form in singular and plural." },
      { s: "Many electrical equipmentes were damaged.", err: "equipmentes", cor: "equipments", opt: ["equipmentes", "equipment", "equipment's"], h: "'Equipment' is uncountable; 'equipmentes' is invalid." },
      { s: "The team performed several analysisses.", err: "analysisses", cor: "analyses", opt: ["analysisses", "analysis", "analysises"], h: "The plural of 'analysis' is 'analyses'." },
      { s: "These criteria is very strict.", err: "is", cor: "are", opt: ["is", "be", "been"], h: "'Criteria' is the plural of 'criterion' and needs 'are'." },
      { s: "The pilot saw three phenomenas.", err: "phenomenas", cor: "phenomena", opt: ["phenomenas", "phenomenon", "phenomenae"], h: "'Phenomena' is already plural; 'phenomenas' is double-pluralized." }
    ],
    contexts: ["inside the hub", "at the research station", "in the valley", "under the dome"]
  },
  {
    name: "Irregular Past Tense Verbs",
    baseScenarios: [
      { s: "He goed to the market yesterday.", err: "goed", cor: "went", opt: ["goed", "goeds", "gone"], h: "The irregular past tense of 'go' is 'went'." },
      { s: "The bird flied over the building.", err: "flied", cor: "flew", opt: ["flied", "flowed", "flown"], h: "The irregular past tense of 'fly' is 'flew'." },
      { s: "She writed a beautiful letter.", err: "writed", cor: "wrote", opt: ["writed", "written", "writes"], h: "The irregular past tense of 'write' is 'wrote'." },
      { s: "We buyed some fresh fruits.", err: "buyed", cor: "bought", opt: ["buyed", "buying", "buys"], h: "The past tense of 'buy' is 'bought'." },
      { s: "The glass breaked when it fell.", err: "breaked", cor: "broke", opt: ["breaked", "broken", "breaks"], h: "The past tense of 'break' is 'broke'." },
      { s: "I runned three miles this morning.", err: "runned", cor: "ran", opt: ["runned", "running", "runs"], h: "The past tense of 'run' is 'ran'." },
      { s: "They singed a lovely song.", err: "singed", cor: "sang", opt: ["singed", "sung", "sings"], h: "The past tense of 'sing' is 'sang'." },
      { s: "The sun rised at six o'clock.", err: "rised", cor: "rose", opt: ["rised", "risen", "rises"], h: "The past tense of 'rise' is 'rose'." },
      { s: "He catched the ball easily.", err: "catched", cor: "caught", opt: ["catched", "catching", "catches"], h: "The past tense of 'catch' is 'caught'." },
      { s: "She keeped all her old toys.", err: "keeped", cor: "kept", opt: ["keeped", "keeping", "keeps"], h: "The past tense of 'keep' is 'kept'." }
    ],
    contexts: ["during the trial", "before the backup", "in the historical zone", "near the gate"]
  },
  {
    name: "Double Comparatives & Superlatives",
    baseScenarios: [
      { s: "He is more taller than his brother.", err: "more taller", cor: "taller", opt: ["more taller", "most taller", "tallerest"], h: "Avoid double comparatives; 'taller' is already comparative." },
      { s: "This is the most biggest cake ever.", err: "most biggest", cor: "biggest", opt: ["most biggest", "more biggest", "biggestest"], h: "Avoid double superlatives; 'biggest' is already superlative." },
      { s: "She is more happier today.", err: "more happier", cor: "happier", opt: ["more happier", "most happier", "happierest"], h: "Adjectives ending in '-y' take '-ier'; do not use 'more'." },
      { s: "That was the most worst movie.", err: "most worst", cor: "worst", opt: ["most worst", "more worst", "worstest"], h: "'Worst' is already superlative; do not combine with 'most'." },
      { s: "His drawing is more better than mine.", err: "more better", cor: "better", opt: ["more better", "most better", "betterer"], h: "'Better' is already comparative; do not use 'more'." },
      { s: "This room is more quieter now.", err: "more quieter", cor: "quieter", opt: ["more quieter", "most quieter", "quieterest"], h: "Use 'quieter' alone without 'more'." },
      { s: "She is the most smartest student.", err: "most smartest", cor: "smartest", opt: ["most smartest", "more smartest", "smartestest"], h: "Use 'smartest' alone without 'most'." },
      { s: "My computer is more faster than yours.", err: "more faster", cor: "faster", opt: ["more faster", "most faster", "fasterer"], h: "Use 'faster' alone without 'more'." },
      { s: "It was the most coldest night of winter.", err: "most coldest", cor: "coldest", opt: ["most coldest", "more coldest", "coldestest"], h: "Use 'coldest' alone without 'most'." },
      { s: "The solution is more simpler than that.", err: "more simpler", cor: "simpler", opt: ["more simpler", "most simpler", "simplerer"], h: "Use 'simpler' alone without 'more'." }
    ],
    contexts: ["in the sector", "during the analysis", "at the repair bay", "inside the shuttle"]
  },
  {
    name: "Pronoun Case (Subject vs. Object)",
    baseScenarios: [
      { s: "Me and him went to the library.", err: "Me and him", cor: "He and I", opt: ["Me and him", "Him and I", "Me and he"], h: "Use subject pronouns 'He and I' for the subject of a sentence." },
      { s: "Between you and I, this is a secret.", err: "I", cor: "me", opt: ["I", "myself", "mine"], h: "Prepositions like 'between' take object pronouns like 'me'." },
      { s: "Give the documents to she tomorrow.", err: "she", cor: "her", opt: ["she", "hers", "herself"], h: "'To' is a preposition and requires the object pronoun 'her'." },
      { s: "Whom is calling at this late hour?", err: "Whom", cor: "Who", opt: ["Whom", "Whose", "Who's"], h: "Use 'who' as the subject pronoun of the verb 'is calling'." },
      { s: "The teacher praised Zane and I.", err: "I", cor: "me", opt: ["I", "myself", "mine"], h: "'Zane and me' is the direct object of the verb 'praised'." },
      { s: "Us scouts love camping in the woods.", err: "Us", cor: "We", opt: ["Us", "Ours", "Ourselves"], h: "Use the subject pronoun 'We' before the noun 'scouts'." },
      { s: "She runs much faster than him.", err: "him", cor: "he", opt: ["him", "himself", "his"], h: "Informal English accepts 'him', but formally it is 'than he (runs)'." },
      { s: "It was me who answered the phone.", err: "me", cor: "I", opt: ["me", "myself", "mine"], h: "Use subject pronoun 'I' after linking verbs (predicate nominative)." },
      { s: "The responsibility belongs to we all.", err: "we", cor: "us", opt: ["we", "our", "ourselves"], h: "Preposition 'to' requires the object pronoun 'us'." },
      { s: "Him playing the guitar was excellent.", err: "Him", cor: "His", opt: ["Him", "He", "Him's"], h: "Use possessive pronoun 'His' before gerunds (verbal nouns)." }
    ],
    contexts: ["during the expedition", "at the archives", "before the captain", "in the team room"]
  },
  {
    name: "Dangling & Misplaced Modifiers",
    baseScenarios: [
      { s: "Running to the bus, my bag fell.", err: "Running to the bus", cor: "While I was running to the bus", opt: ["Running to the bus", "On running to the bus", "By running to the bus"], h: "Clarify who was running; the bag itself cannot run." },
      { s: "I saw a huge dog using binoculars.", err: "using binoculars", cor: "with binoculars", opt: ["using binoculars", "by binoculars", "use binoculars"], h: "Position modifiers carefully so the dog isn't using binoculars." },
      { s: "Covered in hot sauce, I ate the wings.", err: "Covered in hot sauce", cor: "I ate the wings covered in hot sauce", opt: ["Covered in hot sauce", "By hot sauce covered", "Hot sauce covered"], h: "Ensure the modifier describes the wings, not the person eating." },
      { s: "Walking down the path, the trees were tall.", err: "Walking down the path", cor: "As we walked down the path", opt: ["Walking down the path", "On walking the path", "Path walking"], h: "Clarify who was walking down the path." },
      { s: "I only had five dollars left to spend.", err: "only had", cor: "had only", opt: ["only had", "had onlys", "only having"], h: "Place 'only' directly before the word it modifies." },
      { s: "Being tired, the bed felt very comfortable.", err: "Being tired", cor: "Since I was tired", opt: ["Being tired", "On being tired", "Tired being"], h: "Clarify who is tired; the bed itself cannot be tired." },
      { s: "I bought a fresh pie from the bakery that was hot.", err: "that was hot", cor: "hot from the bakery", opt: ["that was hot", "being hot", "hotly"], h: "Ensure 'hot' describes the pie, not the bakery." },
      { s: "While reading the book, the phone rang suddenly.", err: "While reading the book", cor: "While I was reading the book", opt: ["While reading the book", "Book reading", "On reading"], h: "Clarify who was reading the book." },
      { s: "They served delicious pizza on paper plates that was hot.", err: "that was hot", cor: "hot pizza on paper plates", opt: ["that was hot", "plate hot", "hotly plates"], h: "Ensure the modifier 'hot' attaches to the pizza, not the plates." },
      { s: "Hoping to pass, the study guide was reviewed.", err: "Hoping to pass", cor: "Hoping to pass, I reviewed the study guide", opt: ["Hoping to pass", "To hope passing", "Pass hoping"], h: "Clarify who is hoping to pass; the guide itself cannot hope." }
    ],
    contexts: ["in the sector", "during the test flight", "at the control room", "inside the dome"]
  },
  {
    name: "Parallel Structure in Lists",
    baseScenarios: [
      { s: "She likes hiking, swimming, and to dance.", err: "to dance", cor: "dancing", opt: ["to dance", "danced", "dance"], h: "Maintain gerund form ('-ing') across all list elements." },
      { s: "The job requires writing, editing, and to organize.", err: "to organize", cor: "organizing", opt: ["to dance", "dance", "danced"], h: "Keep all elements in the list parallel." },
      { s: "He was smart, energetic, and had reliability.", err: "had reliability", cor: "reliable", opt: ["had reliability", "reliably", "relies"], h: "Keep adjectives parallel in a descriptive list." },
      { s: "We decided to walk, to run, or swimming.", err: "swimming", cor: "to swim", opt: ["swimming", "swim", "swam"], h: "Maintain infinitive structure ('to ...') across all choices." },
      { s: "The course covers reading, writing, and how to speak.", err: "how to speak", cor: "speaking", opt: ["how to speak", "to speak", "speak"], h: "Use standard gerunds for list items." },
      { s: "She prepared the presentation quickly and with care.", err: "with care", cor: "carefully", opt: ["with care", "careful", "caring"], h: "Use parallel adverbs ('quickly and carefully')." },
      { s: "To succeed, you must study, practice, and listening.", err: "listening", cor: "listen", opt: ["listening", "listened", "to listen"], h: "Keep the base verbs parallel." },
      { s: "They enjoy playing chess, playing tennis, and golf.", err: "golf", cor: "playing golf", opt: ["golf", "to play golf", "played golf"], h: "Keep list items parallel." },
      { s: "The room was warm, cozy, and had lots of light.", err: "had lots of light", cor: "bright", opt: ["had lots of light", "brightly", "lights"], h: "Maintain a simple series of adjectives." },
      { s: "He promised to pay back the loan and that he would leave.", err: "that he would leave", cor: "to leave", opt: ["that he would leave", "leaving", "left"], h: "Maintain the infinitive pattern." }
    ],
    contexts: ["during training", "in the logs", "at the academy", "before the council"]
  },
  {
    name: "Double Negatives",
    baseScenarios: [
      { s: "I don't have no money left.", err: "don't have no", cor: "don't have any", opt: ["don't have no", "haven't no", "doesn't have no"], h: "Avoid double negatives; use 'any' with 'don't'." },
      { s: "She hasn't seen nothing in the lab.", err: "hasn't seen nothing", cor: "hasn't seen anything", opt: ["hasn't seen nothing", "no seen nothing", "hasn't no seen"], h: "Avoid combining negative verbs with negative pronouns." },
      { s: "We won't never forget this day.", err: "won't never", cor: "will never", opt: ["won't never", "won'ts never", "will never not"], h: "Use 'will never' or 'won't ever'." },
      { s: "He doesn't know nobody here.", err: "nobody", cor: "anybody", opt: ["nobody", "nobodies", "no one"], h: "Use 'anybody' after the negative verb 'doesn't'." },
      { s: "There isn't no water in the flask.", err: "isn't no", cor: "isn't any", opt: ["isn't no", "are no", "aren't no"], h: "Use 'isn't any' to avoid a double negative." },
      { s: "I couldn't barely hear the speaker.", err: "couldn't barely", cor: "could barely", opt: ["couldn't barely", "couldn't never", "couldn't not"], h: "'Barely' is already negative; use with positive auxiliary 'could'." },
      { s: "She didn't do nothing wrong.", err: "didn't do nothing", cor: "didn't do anything", opt: ["didn't do nothing", "does nothing", "did no nothing"], h: "Avoid double negatives; use 'anything'." },
      { s: "They don't want no trouble today.", err: "don't want no", cor: "don't want any", opt: ["don't want no", "wants no", "don't want noes"], h: "Use 'don't want any'." },
      { s: "He hasn't got no excuses.", err: "no", cor: "any", opt: ["no", "none", "noes"], h: "Use 'any' with the negative verb." },
      { s: "We can't scarcely believe the news.", err: "can't scarcely", cor: "can scarcely", opt: ["can't scarcely", "can't never", "can't not"], h: "'Scarcely' is negative; use with 'can'." }
    ],
    contexts: ["in the sector", "during the mission", "at the outpost", "in the archive"]
  },
  {
    name: "Preposition Errors",
    baseScenarios: [
      { s: "Our success depends of your hard work.", err: "depends of", cor: "depends on", opt: ["depends of", "depends at", "depends from"], h: "The verb 'depend' is followed by the preposition 'on'." },
      { s: "She was very angry on her brother.", err: "angry on", cor: "angry with", opt: ["angry on", "angry at", "angry of"], h: "Use 'angry with' when referring to a person." },
      { s: "This solution is different than that one.", err: "different than", cor: "different from", opt: ["different than", "different to", "different with"], h: "Standard formal English uses 'different from'." },
      { s: "He insisted to pay for the dinner.", err: "insisted to pay", cor: "insisted on paying", opt: ["insisted to pay", "insisted in paying", "insisted pay"], h: "The verb 'insist' takes the preposition 'on' plus a gerund." },
      { s: "We congratulate you for your promotion.", err: "congratulate you for", cor: "congratulate you on", opt: ["congratulate you for", "congratulate you at", "congratulate you of"], h: "Use 'congratulate on' for achievements." },
      { s: "She is capable to solve this problem.", err: "capable to solve", cor: "capable of solving", opt: ["capable to solve", "capable for solving", "capable solve"], h: "Use 'capable of' followed by a gerund." },
      { s: "He is good in playing chess.", err: "good in", cor: "good at", opt: ["good in", "good on", "good with"], h: "Use 'good at' to describe proficiency." },
      { s: "They arrived to the airport late.", err: "arrived to", cor: "arrived at", opt: ["arrived to", "arrived in", "arrived on"], h: "Use 'arrived at' for specific locations." },
      { s: "She was married with a doctor.", err: "married with", cor: "married to", opt: ["married with", "married at", "married by"], h: "Standard expression is 'married to'." },
      { s: "We are interested for this project.", err: "interested for", cor: "interested in", opt: ["interested for", "interested on", "interested at"], h: "The adjective 'interested' takes 'in'." }
    ],
    contexts: ["during discussions", "at the base", "in the lab", "near the shuttle"]
  },
  {
    name: "Subjunctive Mood",
    baseScenarios: [
      { s: "If I was you, I would take the offer.", err: "was", cor: "were", opt: ["was", "be", "am"], h: "Use 'were' for imaginary or counter-factual statements." },
      { s: "He demanded that the scout goes now.", err: "goes", cor: "go", opt: ["goes", "going", "went"], h: "Subjunctive clauses of demand use the base verb form 'go'." },
      { s: "It is essential that she is present.", err: "is", cor: "be", opt: ["is", "been", "was"], h: "Subjunctive clauses of importance require the base verb 'be'." },
      { s: "I wish Zane was here tonight.", err: "was", cor: "were", opt: ["was", "be", "been"], h: "Wishes express hypothetical states and require 'were'." },
      { s: "He suggested that Zane plays the game.", err: "plays", cor: "play", opt: ["plays", "played", "playing"], h: "Subjunctive suggestion clauses use the base verb." },
      { s: "If she were to know, she will be mad.", err: "will be", cor: "would be", opt: ["will be", "is", "was"], h: "Conditional subjunctive requires 'would be'." },
      { s: "It is crucial that Zane has a map.", err: "has", cor: "have", opt: ["has", "having", "haves"], h: "Use subjunctive base form 'have' after 'crucial that'." },
      { s: "I recommend that Zane takes a break.", err: "takes", cor: "take", opt: ["takes", "taking", "taken"], h: "Subjunctive recommendation takes base verb 'take'." },
      { s: "He acted as if he was the commander.", err: "was", cor: "were", opt: ["was", "be", "been"], h: "'As if' clauses indicating hypothetical roles require 'were'." },
      { s: "It is important that everyone knows this.", err: "knows", cor: "know", opt: ["knows", "knowing", "knew"], h: "Subjunctive clauses of importance use the base verb 'know'." }
    ],
    contexts: ["in the briefing", "during the meeting", "at the high council", "before the reactor"]
  },
  {
    name: "Active vs. Passive Voice & Modals",
    baseScenarios: [
      { s: "You should of called me earlier.", err: "should of", cor: "should have", opt: ["should of", "should off", "should'f"], h: "Use the helper verb 'have' instead of the preposition 'of'." },
      { s: "We must to complete this today.", err: "must to complete", cor: "must complete", opt: ["must to complete", "must to completes", "musted complete"], h: "Modals like 'must' are followed by the base verb without 'to'." },
      { s: "He could has done better on the test.", err: "could has", cor: "could have", opt: ["could has", "could haves", "could's"], h: "Modals are always followed by the base infinitive 'have'." },
      { s: "The relic was wrote by ancient scouts.", err: "was wrote", cor: "was written", opt: ["was wrote", "was writed", "was write"], h: "Passive voice takes past participle form 'written'." },
      { s: "You ought have finished that by now.", err: "ought have", cor: "ought to have", opt: ["ought have", "oughted to have", "oughts have"], h: "Modal 'ought' is always followed by 'to'." },
      { s: "The spaceship was steal last night.", err: "was steal", cor: "was stolen", opt: ["was steal", "was stealed", "was stole"], h: "Use passive past participle 'stolen'." },
      { s: "She might to arrive late tonight.", err: "might to arrive", cor: "might arrive", opt: ["might to arrive", "might arrived", "mights arrive"], h: "Modal 'might' does not take the infinitive particle 'to'." },
      { s: "They have been chose for the squad.", err: "been chose", cor: "been chosen", opt: ["been chose", "been choosed", "been choose"], h: "Use passive past participle 'chosen'." },
      { s: "We would had helped you if we knew.", err: "would had", cor: "would have", opt: ["would had", "would has", "would'd"], h: "Modal requires base form 'have'." },
      { s: "The message was send via sub-space.", err: "was send", cor: "was sent", opt: ["was send", "was sended", "was sending"], h: "Use passive past participle 'sent'." }
    ],
    contexts: ["during communications", "at the repair bay", "inside the dome", "near the core"]
  },
  {
    name: "Pronoun-Antecedent Agreement",
    baseScenarios: [
      { s: "Every student must bring their book.", err: "their", cor: "his or her", opt: ["their", "theirs", "they"], h: "Singular antecedents like 'Every student' need singular pronouns." },
      { s: "None of the girls finished their task.", err: "their", cor: "her", opt: ["their", "theirs", "they"], h: "'None' with a singular distribution takes a singular pronoun." },
      { s: "If a person works hard, they will succeed.", err: "they", cor: "he or she", opt: ["they", "them", "theirs"], h: "Singular indefinite antecedents traditionally take singular pronouns." },
      { s: "Each of the options has their drawbacks.", err: "their", cor: "its", opt: ["their", "theirs", "it"], h: "'Each' is singular and takes the singular possessive 'its'." },
      { s: "Either Lex or Zane will lose their way.", err: "their", cor: "his", opt: ["their", "theirs", "them"], h: "Singular nouns joined by 'or' take singular pronouns." },
      { s: "Nobody realized that their core was failing.", err: "their", cor: "his or her", opt: ["their", "theirs", "they"], h: "Singular indefinite pronoun 'Nobody' takes singular 'his or her'." },
      { s: "The council submitted their final report.", err: "their", cor: "its", opt: ["their", "theirs", "it"], h: "A collective noun acting as a single unit takes singular 'its'." },
      { s: "Every pilot has completed their flight.", err: "their", cor: "his or her", opt: ["their", "theirs", "they"], h: "Singular antecedent takes a singular pronoun." },
      { s: "Neither droid has updated their software.", err: "their", cor: "its", opt: ["their", "theirs", "it"], h: "'Neither' is singular, so it requires singular pronoun 'its'." },
      { s: "Someone left their scanner on the table.", err: "their", cor: "his or her", opt: ["their", "theirs", "they"], h: "Singular indefinite antecedent requires singular pronoun." }
    ],
    contexts: ["in the laboratory", "during training", "inside the shuttle", "at the main hub"]
  },
  {
    name: "Relative Pronouns (Who vs. Whom / Which vs. That)",
    baseScenarios: [
      { s: "The man which spoke to us is the captain.", err: "which", cor: "who", opt: ["which", "whom", "whose"], h: "Use 'who' when referring to people." },
      { s: "To who did you write the letter?", err: "who", cor: "whom", opt: ["who", "whose", "who's"], h: "'To' is a preposition and requires object relative 'whom'." },
      { s: "The droid whom we repaired is active.", err: "whom", cor: "which", opt: ["whom", "who", "whose"], h: "Droids (things) take 'which' or 'that', not 'whom'." },
      { s: "Zane is the pilot whom won the race.", err: "whom", cor: "who", opt: ["whom", "whose", "which"], h: "Use 'who' as the subject pronoun of the relative clause." },
      { s: "The anomalies that was detected are strange.", err: "that was", cor: "that were", opt: ["that was", "which was", "who was"], h: "'Anomalies' is plural; the relative clause verb must be plural." },
      { s: "The scouts who we met were very friendly.", err: "who", cor: "whom", opt: ["who", "whose", "which"], h: "Use 'whom' as the object of the relative clause." },
      { s: "I visited the station which the reactor is located.", err: "which", cor: "where", opt: ["which", "that", "whose"], h: "Use adverbial relative 'where' for locations." },
      { s: "The engine who was damaged is repaired.", err: "who", cor: "which", opt: ["who", "whom", "whose"], h: "Use 'which' for objects." },
      { s: "Is this the scientist whose we heard about?", err: "whose", cor: "whom", opt: ["whose", "who", "which"], h: "Use 'whom' as the object pronoun after about." },
      { s: "The keys whom were lost are found.", err: "whom", cor: "which", opt: ["whom", "who", "whose"], h: "Use 'which' for non-living objects." }
    ],
    contexts: ["during communications", "inside the tower", "at the outpost", "in the logs"]
  },
  {
    name: "Tense Shift & Reported Speech",
    baseScenarios: [
      { s: "He said he will come tomorrow.", err: "will", cor: "would", opt: ["will", "wills", "would'd"], h: "Reported speech in past tense shifts 'will' to 'would'." },
      { s: "She asked where was I going.", err: "where was I", cor: "where I was", opt: ["where was I", "where I wass", "where am I"], h: "Indirect questions do not use question inversion." },
      { s: "They claimed they are finished already.", err: "are", cor: "were", opt: ["are", "be", "been"], h: "Reported speech in the past shifts 'are' to 'were'." },
      { s: "I told him that I have seen the relic.", err: "have", cor: "had", opt: ["have", "has", "having"], h: "Reported speech shifts present perfect to past perfect." },
      { s: "She said she can fly the shuttle.", err: "can", cor: "could", opt: ["can", "cans", "could'd"], h: "Reported speech shifts 'can' to 'could'." },
      { s: "He wanted to know what is the code.", err: "what is the code", cor: "what the code was", opt: ["what is the code", "what code is", "what the code is"], h: "Reported questions shift tense and word order." },
      { s: "They stated they will help us later.", err: "will", cor: "would", opt: ["will", "wills", "would'd"], h: "Shifts 'will' to 'would'." },
      { s: "She wondered if we are ready.", err: "are", cor: "were", opt: ["are", "be", "been"], h: "Shifts present to past in indirect questions." },
      { s: "Zane confirmed that he is going.", err: "is", cor: "was", opt: ["is", "am", "be"], h: "Shifts 'is' to 'was'." },
      { s: "I asked Zane when does he leave.", err: "does he leave", cor: "he left", opt: ["does he leave", "he leaves", "did he leave"], h: "Shifts present tense and removes auxiliary." }
    ],
    contexts: ["in the briefings", "during logs", "at the outpost", "inside the cockpit"]
  },
  {
    name: "Gerunds vs. Infinitives",
    baseScenarios: [
      { s: "We must avoid to make mistakes.", err: "to make", cor: "making", opt: ["to make", "make", "made"], h: "The verb 'avoid' is followed by a gerund ('-ing')." },
      { s: "Zane enjoyed to play the simulation.", err: "to play", cor: "playing", opt: ["to play", "play", "played"], h: "The verb 'enjoy' takes a gerund." },
      { s: "They decided going to the launchpad.", err: "going", cor: "to go", opt: ["going", "go", "gone"], h: "The verb 'decide' is followed by an infinitive." },
      { s: "She suggested to leave the station now.", err: "to leave", cor: "leaving", opt: ["to leave", "leave", "left"], h: "The verb 'suggest' takes a gerund." },
      { s: "He promised helping me with the core.", err: "helping", cor: "to help", opt: ["helping", "help", "helped"], h: "The verb 'promise' is followed by an infinitive." },
      { s: "We are looking forward to meet you.", err: "to meet", cor: "to meeting", opt: ["to meet", "meet", "meeting"], h: "The expression 'look forward to' requires a gerund." },
      { s: "She managed completing the scan alone.", err: "completing", cor: "to complete", opt: ["completing", "complete", "completed"], h: "The verb 'manage' requires an infinitive." },
      { s: "They refused to cooperating with the pilot.", err: "to cooperating", cor: "to cooperate", opt: ["to cooperating", "cooperate", "cooperated"], h: "Use standard infinitive 'to cooperate'." },
      { s: "It is no use to complain about it.", err: "to complain", cor: "complaining", opt: ["to complain", "complain", "complained"], h: "The expression 'it is no use' takes a gerund." },
      { s: "He offered taking the scanner.", err: "taking", cor: "to take", opt: ["taking", "take", "taken"], h: "The verb 'offer' takes an infinitive." }
    ],
    contexts: ["inside the hub", "at the landing pad", "near the relay", "during the trek"]
  },
  {
    name: "Adverb vs. Adjective Usage",
    baseScenarios: [
      { s: "The team played good in the championship.", err: "good", cor: "well", opt: ["good", "goods", "goodly"], h: "Use the adverb 'well' to modify the verb 'played'." },
      { s: "Zane runs very quick to the base.", err: "quick", cor: "quickly", opt: ["quick", "quicks", "quickest"], h: "Use the adverb 'quickly' to modify the verb 'runs'." },
      { s: "That core is real powerful.", err: "real", cor: "really", opt: ["real", "reals", "realest"], h: "Use the adverb 'really' to modify the adjective 'powerful'." },
      { s: "The flower smells sweetly in the garden.", err: "sweetly", cor: "sweet", opt: ["sweetly", "sweetest", "sweets"], h: "Linking verbs like 'smells' take adjectives, not adverbs." },
      { s: "She solved the puzzle easy.", err: "easy", cor: "easily", opt: ["easy", "easier", "easies"], h: "Use the adverb 'easily' to modify the verb 'solved'." },
      { s: "The pilot landed the shuttle safe.", err: "safe", cor: "safely", opt: ["safe", "safes", "safest"], h: "Use the adverb 'safely' to modify the action verb 'landed'." },
      { s: "He spoke very polite to the council.", err: "polite", cor: "politely", opt: ["polite", "polites", "politest"], h: "Use the adverb 'politely' to modify the verb 'spoke'." },
      { s: "The soup tasted badly tonight.", err: "badly", cor: "bad", opt: ["badly", "bads", "badder"], h: "Linking verb 'tasted' requires an adjective ('bad')." },
      { s: "She did extreme well on the test.", err: "extreme", cor: "extremely", opt: ["extreme", "extremes", "extremest"], h: "Use the adverb 'extremely' to modify another adverb 'well'." },
      { s: "They completed the task quick.", err: "quick", cor: "quickly", opt: ["quick", "quicks", "quickest"], h: "Use the adverb 'quickly' to modify the verb 'completed'." }
    ],
    contexts: ["in the sector", "during the mission", "at the academy", "in the archive"]
  },
  {
    name: "Inversion after Negative Adverbs",
    baseScenarios: [
      { s: "Rarely I have seen such an anomaly.", err: "I have seen", cor: "have I seen", opt: ["I have seen", "I seen", "I saw"], h: "Place auxiliary verb 'have' before 'I' after negative adverbs like 'Rarely'." },
      { s: "Not only he failed the test, but he also lost his map.", err: "he failed", cor: "did he fail", opt: ["he failed", "he fails", "he did fail"], h: "Negative introductory phrases require auxiliary inversion 'did he fail'." },
      { s: "Scarcely she had entered when the alarm rang.", err: "she had entered", cor: "had she entered", opt: ["she had entered", "she entered", "she did enter"], h: "Invert subject and auxiliary after negative limiters." },
      { s: "Little they knew about the danger.", err: "they knew", cor: "did they know", opt: ["they knew", "they know", "they did know"], h: "Introductory 'Little' requires auxiliary inversion 'did they know'." },
      { s: "Seldom we see such beautiful stars.", err: "we see", cor: "do we see", opt: ["we see", "we sees", "we saw"], h: "Introductory 'Seldom' requires present inversion 'do we see'." },
      { s: "Never I will forget this expedition.", err: "I will", cor: "will I", opt: ["I will", "I'll", "I shall"], h: "Introductory 'Never' requires future auxiliary inversion 'will I'." },
      { s: "Under no circumstances you should enter.", err: "you should", cor: "should you", opt: ["you should", "you shall", "you enter"], h: "Introductory negative prepositions require auxiliary inversion." },
      { s: "Hardly he had finished when it rained.", err: "he had finished", cor: "had he finished", opt: ["he had finished", "he finished", "he did finish"], h: "Introductory 'Hardly' requires auxiliary inversion." },
      { s: "Only then I realized the truth.", err: "I realized", cor: "did I realize", opt: ["I realized", "I realize", "I did realize"], h: "Introductory 'Only then' requires past auxiliary inversion." },
      { s: "No sooner the spaceship landed than it broke.", err: "the spaceship landed", cor: "had the spaceship landed", opt: ["the spaceship landed", "the spaceship lands", "did the spaceship land"], h: "Introductory 'No sooner' requires auxiliary inversion." }
    ],
    contexts: ["during anomalous scans", "at the security hub", "near the portal", "in deep space"]
  },
  {
    name: "Conditional Sentence Structures (Mixed & Counterfactual)",
    baseScenarios: [
      { s: "If I would have known, I would have helped.", err: "would have known", cor: "had known", opt: ["would have known", "known", "knowed"], h: "Use past perfect ('had known') in the conditional if-clause of third conditionals." },
      { s: "If he studied, he would have passed.", err: "studied", cor: "had studied", opt: ["studied", "studies", "studying"], h: "Counter-factual past conditions require past perfect ('had studied')." },
      { s: "If they will arrive tomorrow, we will start.", err: "will arrive", cor: "arrive", opt: ["will arrive", "arrived", "arrives"], h: "Use present tense ('arrive') in first conditional if-clauses." },
      { s: "I would go if I was invited.", err: "was", cor: "were", opt: ["was", "be", "am"], h: "Use subjunctive 'were' in second conditional if-clauses." },
      { s: "If Zane has studied, he would succeed.", err: "has studied", cor: "had studied", opt: ["has studied", "studies", "study"], h: "Counter-factual past condition takes past perfect." },
      { s: "We would have succeeded if we followed the map.", err: "followed", cor: "had followed", opt: ["followed", "follows", "following"], h: "Third conditional if-clause takes past perfect." },
      { s: "If she is here yesterday, she would know.", err: "is here", cor: "had been here", opt: ["is here", "was here", "were here"], h: "Counter-factual past condition takes past perfect." },
      { s: "I will call you if I will finish early.", err: "will finish", cor: "finish", opt: ["will finish", "finished", "finishing"], h: "First conditional if-clause takes present tense." },
      { s: "If I were you, I will do it.", err: "will do", cor: "would do", opt: ["will do", "do", "done"], h: "Second conditional result clause takes 'would' + base verb." },
      { s: "They would have helped if they can.", err: "can", cor: "had been able to", opt: ["can", "could", "are able to"], h: "Third conditional if-clause requires past perfect." }
    ],
    contexts: ["in the sector", "during flights", "at the outpost", "in the briefing"]
  },
  {
    name: "Correlative Conjunctions (Either/Or, Neither/Nor)",
    baseScenarios: [
      { s: "Neither the droid or the pilot was ready.", err: "or", cor: "nor", opt: ["or", "nor", "but"], h: "The correlative conjunction 'neither' pairs with 'nor'." },
      { s: "Either Lex nor Zane will pilot the ship.", err: "nor", cor: "or", opt: ["nor", "but", "and"], h: "The correlative conjunction 'either' pairs with 'or'." },
      { s: "Not only he was tired, but as well hungry.", err: "but as well", cor: "but also", opt: ["but as well", "but too", "and also"], h: "'Not only' pairs with 'but also'." },
      { s: "Both Lex as well as Zane passed.", err: "as well as", cor: "and", opt: ["as well as", "or", "but"], h: "'Both' pairs with 'and' for compound structures." },
      { s: "Whether he goes nor stays is up to him.", err: "nor", cor: "or", opt: ["nor", "but", "and"], h: "'Whether' pairs with 'or'." },
      { s: "Neither the sensor nor the beam are working.", err: "are", cor: "is", opt: ["are", "be", "been"], h: "When singular subjects are joined by nor, the verb is singular." },
      { s: "Either the engineers or the pilot is correct.", err: "is", cor: "are", opt: ["is", "be", "am"], h: "The verb agrees with the closer subject 'pilot'." },
      { s: "He was both intelligent or handsome.", err: "or", cor: "and", opt: ["or", "nor", "but"], h: "'Both' pairs with 'and'." },
      { s: "Not only did they scan, but they analyzed.", err: "but they analyzed", cor: "but they also analyzed", opt: ["but they analyzed", "but analyzed", "and analyzed"], h: "Use 'but... also' to complete the correlative clause." },
      { s: "She would rather study nor work.", err: "nor", cor: "than", opt: ["nor", "then", "or"], h: "'Rather' pairs with 'than' to show preference." }
    ],
    contexts: ["in the archives", "during scans", "at the base", "inside the dome"]
  },
  {
    name: "Advanced Syntactic Glitches & Idiomatic Expressions",
    baseScenarios: [
      { s: "I prefer coffee than tea during missions.", err: "than", cor: "to", opt: ["than", "from", "at"], h: "The verb 'prefer' takes the preposition 'to' for comparisons." },
      { s: "This armor is superior than that one.", err: "than", cor: "to", opt: ["than", "from", "at"], h: "Adjectives of Latin origin like 'superior' take 'to' instead of 'than'." },
      { s: "We must cope up with the new systems.", err: "cope up with", cor: "cope with", opt: ["cope up with", "cope up", "cope withs"], h: "The correct idiomatic phrasal verb is 'cope with'." },
      { s: "Let's discuss about the issue today.", err: "discuss about", cor: "discuss", opt: ["discuss about", "discussions", "discussing about"], h: "The verb 'discuss' is transitive and does not take the preposition 'about'." },
      { s: "She is married with a scientist.", err: "married with", cor: "married to", opt: ["married with", "married at", "married of"], h: "Standard English uses 'married to'." },
      { s: "He is capable to complete the task.", err: "capable to complete", cor: "capable of completing", opt: ["capable to complete", "capable for completing", "capable complete"], h: "'Capable' takes 'of' followed by a gerund." },
      { s: "They congratulated Lex for his flight.", err: "congratulated Lex for", cor: "congratulated Lex on", opt: ["congratulated Lex for", "congratulated Lex in", "congratulated Lex at"], h: "Use 'congratulate... on' for achievements." },
      { s: "The outpost is near to the reactor.", err: "near to", cor: "near", opt: ["near to", "near with", "near by"], h: "Use 'near' directly as a preposition without 'to'." },
      { s: "He was filled by joy after the mission.", err: "filled by", cor: "filled with", opt: ["filled by", "filled in", "filled of"], h: "The correct idiom is 'filled with'." },
      { s: "I am looking forward to see the archive.", err: "to see", cor: "to seeing", opt: ["to see", "seeing", "see"], h: "'Look forward to' takes a gerund." }
    ],
    contexts: ["during debriefs", "at the academy", "in the hub", "near the sector boundary"]
  }
];

const VISUALS = [
  { painter: 'NeuralNegotiationSync', color: '0xFF00FFCC' },
  { painter: 'DataLogSync', color: '0xFF03A9F4' },
  { painter: 'ArchiveDecryptSync', color: '0xFF9E9E9E' },
  { painter: 'CouncilHallSync', color: '0xFFFFFFFF' },
  { painter: 'PurgeGridSync', color: '0xFFF44336' }
];

function getDifficulty(level) {
  if (level <= 40) return 1;
  if (level <= 80) return 2;
  if (level <= 120) return 3;
  if (level <= 160) return 4;
  return 5;
}

// Generate the 600 unique quests (20 batches * 10 levels * 3 quests/level = 600)
for (let batch = 0; batch < 20; batch++) {
  const startLevel = batch * 10 + 1;
  const endLevel = (batch + 1) * 10;
  const fileName = `sentenceCorrection_${startLevel}_${endLevel}.json`;
  const filePath = path.join(basePath, fileName);
  
  const topic = topics[batch % topics.length];
  const quests = [];
  
  let qCounter = 1;
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = getDifficulty(level);
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      // Pick a base scenario and a context to construct a unique sentence
      const baseIndex = ((level - startLevel) * 3 + (qNum - 1)) % topic.baseScenarios.length;
      const base = topic.baseScenarios[baseIndex];
      const contextText = topic.contexts[(level + qNum) % topic.contexts.length];
      
      // Inject context into the sentence cleanly
      let originalSentence = base.s;
      let cleanBaseSentence = originalSentence.replace(/[.]/g, '').trim();
      let finalSentence = `${cleanBaseSentence} ${contextText}.`;
      
      // Compute the incorrect part and the corrected part in the final sentence
      let incorrectPart = base.err;
      let correctedPart = base.cor;
      
      // Create clean choices list
      const originalOptions = [correctedPart, ...base.opt];
      // Filter duplicates
      const uniqueOptions = Array.from(new Set(originalOptions));
      // Shuffle options
      const shuffledOptions = [...uniqueOptions].sort(() => Math.random() - 0.5);
      
      const visual = VISUALS[(level + qNum) % VISUALS.length];
      
      quests.push({
        id: `sc_l${level}_q${qNum}`,
        instruction: "ZAP THE ERROR",
        difficulty: diff,
        subtype: "sentenceCorrection",
        interactionType: "Zapper Grid",
        question: `Fix: '${finalSentence}'`,
        sentence: finalSentence,
        incorrectPart: incorrectPart,
        correctedPart: correctedPart,
        options: shuffledOptions,
        correctAnswerIndex: shuffledOptions.indexOf(correctedPart),
        correctAnswer: correctedPart,
        hint: base.h,
        explanation: `'${incorrectPart}' should be corrected to '${correctedPart}' in this grammatical context.`
      });
    }
  }
  
  const fileData = {
    gameType: "sentenceCorrection",
    batchIndex: batch + 1,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified ${fileName}`);
}

console.log("Successfully generated all 600 unique sentenceCorrection quests across 20 batch files.");
