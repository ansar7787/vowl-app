// Grammar question pools - each game needs 600 unique questions (200 levels × 3)
// We generate them programmatically from sentence banks

const S = (q,o,c,h,inst='Choose the correct answer.') => ({instruction:inst,fields:{question:q,options:o,correctAnswerIndex:c,hint:h}});
const R = (q,sw,co,h) => ({instruction:'Reorder the words.',interactionType:'reorder',fields:{question:q,shuffledWords:sw,correctOrder:co,hint:h,sentence:q}});
const V = (q,o,c,h,ps,as) => ({instruction:'Convert the voice.',fields:{question:q,options:o,correctAnswerIndex:c,hint:h,passiveSentence:ps||null,activeSentence:as||null}});

// ── grammarQuest: general grammar MCQ ──
const gqSentences = [
  ["He doesn't like coffee.","He don't like coffee.","He doesn't like coffee.","He not like coffee.","He doesn't likes coffee.",1,"Third person singular needs 'doesn't'."],
  ["She has two brothers.","She have two brothers.","She has two brothers.","She haves two brothers.","She having two brothers.",1,"'Has' for third person singular."],
  ["They are playing outside.","They is playing outside.","They are playing outside.","They am playing outside.","They be playing outside.",1,"Plural subject uses 'are'."],
  ["I went to school yesterday.","I goed to school yesterday.","I went to school yesterday.","I wented to school yesterday.","I go to school yesterday.",1,"Irregular past tense of 'go'."],
  ["She can swim very well.","She can swims very well.","She can swim very well.","She can swimming very well.","She can swam very well.",1,"Base form after modal verbs."],
  ["The children play in the park.","The childs play in the park.","The children play in the park.","The childrens play in the park.","The children plays in the park.",1,"Irregular plural + verb agreement."],
  ["This is the best movie ever.","This is the most best movie ever.","This is the best movie ever.","This is the more best movie ever.","This is the bestest movie ever.",1,"Superlative of 'good' is 'best'."],
  ["I have been to London twice.","I have went to London twice.","I have been to London twice.","I have go to London twice.","I have going to London twice.",1,"Present perfect uses past participle."],
  ["She told me to wait.","She told me wait.","She told me to wait.","She told me waiting.","She told to me wait.",1,"'Tell someone to do something'."],
  ["We need to buy some milk.","We need buy some milk.","We need to buy some milk.","We need buying some milk.","We needs to buy some milk.",1,"'Need to + base form'."],
  ["He was reading when I arrived.","He was read when I arrived.","He was reading when I arrived.","He reading when I arrived.","He were reading when I arrived.",1,"Past continuous: was + -ing."],
  ["If I were rich, I would travel.","If I was rich, I would travel.","If I were rich, I would travel.","If I am rich, I would travel.","If I be rich, I would travel.",1,"Subjunctive mood uses 'were'."],
  ["Neither Tom nor Jane is here.","Neither Tom nor Jane are here.","Neither Tom nor Jane is here.","Neither Tom or Jane is here.","Neither Tom nor Jane be here.",1,"'Neither...nor' with singular verb."],
  ["She speaks English fluently.","She speak English fluently.","She speaks English fluently.","She speaking English fluently.","She speaked English fluently.",1,"Third person singular adds 's'."],
  ["I wish I had more time.","I wish I have more time.","I wish I had more time.","I wish I has more time.","I wish I having more time.",1,"'Wish' + past tense for unreal present."],
  ["He suggested that we leave early.","He suggested that we left early.","He suggested that we leave early.","He suggested that we leaves early.","He suggested us to leave early.",1,"Subjunctive after 'suggest'."],
  ["The book which I read was good.","The book who I read was good.","The book which I read was good.","The book whom I read was good.","The book whose I read was good.",1,"'Which' for things."],
  ["She would rather stay home.","She would rather stays home.","She would rather stay home.","She would rather staying home.","She would rather to stay home.",1,"'Would rather' + base form."],
  ["By next year, I will have graduated.","By next year, I will graduated.","By next year, I will have graduated.","By next year, I will be graduate.","By next year, I have graduated.",1,"Future perfect tense."],
  ["He apologized for being late.","He apologized for be late.","He apologized for being late.","He apologized to being late.","He apologized of being late.",1,"Preposition + gerund."],
  ["The more you practice, the better you get.","The more you practice, the more better you get.","The more you practice, the better you get.","More you practice, better you get.","The more you practice, the good you get.",1,"Comparative correlative structure."],
  ["She asked me where I lived.","She asked me where I live.","She asked me where I lived.","She asked me where do I live.","She asked me where did I live.",1,"Reported speech: tense shift."],
  ["I am used to waking up early.","I am used to wake up early.","I am used to waking up early.","I used to waking up early.","I am use to waking up early.",1,"'Be used to' + gerund."],
  ["Not only is he smart, but also kind.","Not only he is smart, but also kind.","Not only is he smart, but also kind.","Not only is he smart, and also kind.","Not only he smart, but also kind.",1,"Inversion with 'not only'."],
  ["Had I known, I would have helped.","If I had known, I would helped.","Had I known, I would have helped.","Had I know, I would have helped.","Have I known, I would have helped.",1,"Inverted conditional (third)."],
  ["She insisted on paying the bill.","She insisted to pay the bill.","She insisted on paying the bill.","She insisted for paying the bill.","She insisted in paying the bill.",1,"'Insist on' + gerund."],
  ["It is essential that he be present.","It is essential that he is present.","It is essential that he be present.","It is essential that he being present.","It is essential that he been present.",1,"Subjunctive with 'essential'."],
  ["Scarcely had he left when it rained.","Scarcely he had left when it rained.","Scarcely had he left when it rained.","Scarcely had he leave when it rained.","Scarcely he left when it rained.",1,"Inversion with 'scarcely'."],
  ["Despite being tired, she continued.","Despite she was tired, she continued.","Despite being tired, she continued.","Despite of being tired, she continued.","Despite to be tired, she continued.",1,"'Despite' + gerund/noun."],
  ["He acts as if he were the boss.","He acts as if he is the boss.","He acts as if he were the boss.","He acts as if he was the boss.","He acts like he were the boss.",1,"Subjunctive with 'as if'."],
];
const grammarQuest = gqSentences.map(s => S(s[0],s.slice(1,5),s[5],s[6]));

// ── sentenceCorrection ──
const scData = [
  ["He don't know the answer.","He doesn't know the answer.","Find the error.","doesn't","don't","Third person singular."],
  ["She have been waiting.","She has been waiting.","Fix the verb.","has","have","'Has' for third person."],
  ["They was playing outside.","They were playing outside.","Fix the verb.","were","was","Plural needs 'were'."],
  ["I seen that movie before.","I have seen that movie before.","Fix the tense.","have seen","seen","Present perfect needs 'have'."],
  ["He goed to the store.","He went to the store.","Fix the verb.","went","goed","Irregular past tense."],
  ["Me and him went home.","He and I went home.","Fix the pronoun.","He and I","Me and him","Subject pronouns."],
  ["The dogs is barking loudly.","The dogs are barking loudly.","Fix subject-verb agreement.","are","is","Plural subject."],
  ["She don't want to go.","She doesn't want to go.","Fix the auxiliary.","doesn't","don't","Third person."],
  ["Him and me are friends.","He and I are friends.","Fix the pronouns.","He and I","Him and me","Subject form."],
  ["I have went there before.","I have gone there before.","Fix the participle.","gone","went","Past participle of 'go'."],
  ["She can sings beautifully.","She can sing beautifully.","Fix after modal.","sing","sings","Base form after modals."],
  ["There is many problems.","There are many problems.","Fix the verb.","are","is","Plural noun needs 'are'."],
  ["He brung his lunch today.","He brought his lunch today.","Fix the past tense.","brought","brung","Irregular past tense."],
  ["Her and I went shopping.","She and I went shopping.","Fix the pronoun.","She","Her","Subject pronoun needed."],
  ["The news are shocking today.","The news is shocking today.","Fix the verb.","is","are","'News' is singular."],
  ["Each students must register.","Each student must register.","Fix the noun.","student","students","'Each' + singular."],
  ["Neither option are correct.","Neither option is correct.","Fix the verb.","is","are","'Neither' + singular verb."],
  ["He did not went there.","He did not go there.","Fix after 'did'.","go","went","Base form after 'did'."],
  ["I am more taller than him.","I am taller than him.","Fix the comparative.","taller","more taller","Don't double comparatives."],
  ["She catched the ball easily.","She caught the ball easily.","Fix irregular past.","caught","catched","Irregular verb."],
  ["The informations is incorrect.","The information is incorrect.","Fix the noun.","information","informations","Uncountable noun."],
  ["Between you and I, it's wrong.","Between you and me, it's wrong.","Fix the pronoun.","me","I","Object after preposition."],
  ["He has less friends than me.","He has fewer friends than me.","Fix the quantifier.","fewer","less","'Fewer' for countable nouns."],
  ["Everyone have their own opinion.","Everyone has their own opinion.","Fix the verb.","has","have","'Everyone' is singular."],
  ["She lays down every afternoon.","She lies down every afternoon.","Fix the verb.","lies","lays","'Lie' = recline; 'lay' = put."],
  ["Who's book is this one?","Whose book is this one?","Fix possessive.","Whose","Who's","'Whose' = possession."],
  ["I could of helped you.","I could have helped you.","Fix the auxiliary.","have","of","'Could have', not 'could of'."],
  ["The datas shows improvement.","The data shows improvement.","Fix the noun.","data","datas","'Data' already plural/mass."],
  ["Irregardless, we must proceed.","Regardless, we must proceed.","Fix the word.","Regardless","Irregardless","'Irregardless' is nonstandard."],
  ["She did good on the test.","She did well on the test.","Fix adverb vs adjective.","well","good","Adverb modifies verb."],
];
const sentenceCorrection = scData.map(d => ({
  instruction: d[2],
  fields: {
    question: `Fix: "${d[0]}"`,
    sentence: d[0],
    correctedPart: d[3],
    incorrectPart: d[4],
    options: [d[1], d[0], d[0].replace(d[4], d[4]+'s'), d[0].replace(d[4], 'very '+d[4])],
    correctAnswerIndex: 0,
    hint: d[5],
    explanation: `"${d[4]}" should be "${d[3]}".`,
  }
}));

// ── wordReorder ──
const wrData = [
  ["The cat sat on the mat","mat the on sat cat The"],
  ["She is reading a book","book a reading is She"],
  ["They went to the park","park the to went They"],
  ["I like eating fresh fruit","fruit fresh eating like I"],
  ["He plays guitar every evening","evening every guitar plays He"],
  ["We should help each other","other each help should We"],
  ["The sun rises in the east","east the in rises sun The"],
  ["Birds fly south in winter","winter in south fly Birds"],
  ["She speaks three languages fluently","fluently languages three speaks She"],
  ["My brother works at a hospital","hospital a at works brother My"],
  ["Please close the door quietly","quietly door the close Please"],
  ["The children are playing outside","outside playing are children The"],
  ["I have never been to Japan","Japan to been never have I"],
  ["She always arrives on time","time on arrives always She"],
  ["The teacher explained the lesson","lesson the explained teacher The"],
  ["We are going to the beach","beach the to going are We"],
  ["He bought a new car","car new a bought He"],
  ["The flowers bloom in spring","spring in bloom flowers The"],
  ["I will finish this tomorrow","tomorrow this finish will I"],
  ["She made a delicious cake","cake delicious a made She"],
  ["The dog chased the cat","cat the chased dog The"],
  ["We enjoy watching movies together","together movies watching enjoy We"],
  ["He can solve difficult problems","problems difficult solve can He"],
  ["The train arrives at noon","noon at arrives train The"],
  ["I need to study harder","harder study to need I"],
  ["She gave him a present","present a him gave She"],
  ["The museum opens at nine","nine at opens museum The"],
  ["They celebrated their anniversary","anniversary their celebrated They"],
  ["I usually walk to school","school to walk usually I"],
  ["The baby is sleeping peacefully","peacefully sleeping is baby The"],
];
const wordReorder = wrData.map(d => {
  const words = d[0].split(' ');
  const shuffled = d[1].split(' ');
  const order = shuffled.map(w => words.indexOf(w));
  return R(d[0], shuffled, order, 'Rearrange to form a sentence.');
});

// ── tenseMastery ──
const tmData = [
  ["She ___ to school every day.","walks","walked","will walk","is walking",0,"Simple present for habits.","walk"],
  ["I ___ my homework yesterday.","finish","finished","will finish","am finishing",1,"Simple past for completed action.","finish"],
  ["They ___ a movie right now.","watch","watched","will watch","are watching",3,"Present continuous for now.","watch"],
  ["He ___ the project by Friday.","completes","completed","will complete","is completing",2,"Future simple with 'will'.","complete"],
  ["She ___ here since 2010.","lives","lived","will live","has lived",3,"Present perfect for duration.","live"],
  ["I ___ when the phone rang.","sleep","slept","was sleeping","have slept",2,"Past continuous interrupted.","sleep"],
  ["By next month, I ___ the course.","finish","finished","will have finished","am finishing",2,"Future perfect.","finish"],
  ["She ___ three books this year.","reads","read","has read","is reading",2,"Present perfect for this period.","read"],
  ["They ___ dinner when we arrived.","cook","cooked","had cooked","are cooking",2,"Past perfect before past event.","cook"],
  ["He ___ English for five years.","studies","studied","has been studying","will study",2,"Present perfect continuous.","study"],
  ["We ___ to Paris next summer.","travel","traveled","will travel","are traveling",2,"Future plans with 'will'.","travel"],
  ["She ___ the dishes every morning.","washes","washed","will wash","is washing",0,"Simple present routine.","wash"],
  ["I ___ that book last week.","read","read","will read","am reading",1,"Simple past completed.","read"],
  ["They ___ for two hours already.","wait","waited","have been waiting","will wait",2,"Present perfect continuous.","wait"],
  ["He ___ to work by bus daily.","goes","went","will go","is going",0,"Simple present habit.","go"],
  ["She ___ a letter when I called.","writes","wrote","was writing","has written",2,"Past continuous at that moment.","write"],
  ["By 2030, technology ___ a lot.","changes","changed","will have changed","is changing",2,"Future perfect prediction.","change"],
  ["I ___ sushi before I went to Japan.","never try","never tried","had never tried","am never trying",2,"Past perfect before past.","try"],
  ["We ___ this project since January.","work on","worked on","have been working on","will work on",2,"Present perfect continuous.","work on"],
  ["She ___ her keys. She can't find them.","loses","lost","has lost","is losing",2,"Present perfect recent result.","lose"],
  ["Tomorrow at 8, I ___ to work.","drive","drove","will be driving","have driven",2,"Future continuous.","drive"],
  ["He ___ his lunch before noon daily.","eats","ate","will eat","has eaten",0,"Simple present routine.","eat"],
  ["They ___ the house last summer.","paint","painted","will paint","are painting",1,"Simple past completed.","paint"],
  ["I ___ about this topic all day.","think","thought","have been thinking","will think",2,"Present perfect continuous.","think"],
  ["She ___ abroad if she saves enough.","travels","traveled","will travel","is traveling",2,"First conditional future.","travel"],
  ["We ___ a great time at the party.","have","had","will have","are having",1,"Simple past narrative.","have"],
  ["He ___ for the exam all week.","prepares","prepared","has been preparing","will prepare",2,"Present perfect continuous.","prepare"],
  ["The concert ___ at 8 PM tonight.","starts","started","will start","is starting",0,"Scheduled event simple present.","start"],
  ["I ___ you since childhood.","know","knew","have known","am knowing",2,"Present perfect duration.","know"],
  ["She ___ when the alarm went off.","sleeps","slept","was sleeping","has slept",2,"Past continuous interrupted.","sleep"],
];
const tenseMastery = tmData.map(d => ({
  instruction: 'Choose the correct tense.',
  fields: {
    question: d[0], options: [d[1],d[2],d[3],d[4]],
    correctAnswerIndex: d[5], hint: d[6], verb: d[7],
    targetTense: d[6].split(' ')[0] + ' ' + (d[6].split(' ')[1]||''),
  }
}));

// ── partsOfSpeech ──
const posData = [
  ["What part of speech is 'quickly' in: 'She ran quickly.'","Noun","Verb","Adverb","Adjective",2,"Modifies the verb 'ran'.","quickly"],
  ["Identify 'beautiful' in: 'A beautiful sunset.'","Noun","Adjective","Adverb","Verb",1,"Describes the noun 'sunset'.","beautiful"],
  ["What is 'they' in: 'They are coming.'","Pronoun","Noun","Verb","Adjective",0,"Replaces a noun.","they"],
  ["Identify 'running' in: 'He is running fast.'","Noun","Adjective","Verb","Adverb",2,"Part of present continuous.","running"],
  ["What is 'under' in: 'The cat is under the table.'","Noun","Verb","Preposition","Adverb",2,"Shows position.","under"],
  ["Identify 'joy' in: 'Joy filled the room.'","Verb","Noun","Adjective","Adverb",1,"Names an emotion.","joy"],
  ["What is 'and' in: 'Tom and Jerry.'","Preposition","Conjunction","Noun","Pronoun",1,"Connects two nouns.","and"],
  ["Identify 'Wow' in: 'Wow! That's amazing!'","Noun","Verb","Interjection","Adverb",2,"Expresses emotion.","Wow"],
  ["What is 'carefully' in: 'Drive carefully.'","Adjective","Adverb","Noun","Verb",1,"Modifies the verb 'drive'.","carefully"],
  ["Identify 'the' in: 'The dog barked.'","Pronoun","Article","Noun","Verb",1,"Definite article.","the"],
  ["What is 'swim' in: 'I like to swim.'","Noun","Adjective","Verb","Adverb",2,"Action word.","swim"],
  ["Identify 'his' in: 'His car is red.'","Pronoun","Adjective","Noun","Article",0,"Possessive pronoun.","his"],
  ["What is 'between' in: 'Sit between us.'","Adverb","Conjunction","Preposition","Noun",2,"Shows relationship.","between"],
  ["Identify 'happy' in: 'She looks happy.'","Noun","Verb","Adverb","Adjective",3,"Describes feeling.","happy"],
  ["What is 'slowly' in: 'Walk slowly.'","Adjective","Adverb","Verb","Noun",1,"Modifies 'walk'.","slowly"],
  ["Identify 'but' in: 'Smart but lazy.'","Preposition","Conjunction","Adverb","Noun",1,"Contrasting connector.","but"],
  ["What is 'freedom' in: 'Freedom is precious.'","Verb","Adjective","Noun","Adverb",2,"Abstract noun.","freedom"],
  ["Identify 'Oh' in: 'Oh, I see!'","Noun","Interjection","Adverb","Verb",1,"Expresses realization.","Oh"],
  ["What is 'extremely' in: 'Extremely hot day.'","Adjective","Noun","Adverb","Verb",2,"Modifies adjective 'hot'.","extremely"],
  ["Identify 'we' in: 'We love pizza.'","Noun","Pronoun","Adjective","Verb",1,"First person plural pronoun.","we"],
  ["What is 'above' in: 'Above the clouds.'","Noun","Verb","Preposition","Adjective",2,"Shows position.","above"],
  ["Identify 'tall' in: 'A tall building.'","Noun","Verb","Adverb","Adjective",3,"Describes the building.","tall"],
  ["What is 'sing' in: 'They sing well.'","Noun","Adverb","Verb","Adjective",2,"Action word.","sing"],
  ["Identify 'always' in: 'She always smiles.'","Adjective","Adverb","Verb","Noun",1,"Frequency adverb.","always"],
  ["What is 'or' in: 'Tea or coffee?'","Preposition","Conjunction","Noun","Adverb",1,"Gives alternatives.","or"],
  ["Identify 'these' in: 'These are mine.'","Verb","Pronoun","Adjective","Noun",1,"Demonstrative pronoun.","these"],
  ["What is 'honestly' in: 'Speak honestly.'","Adjective","Noun","Adverb","Verb",2,"Modifies 'speak'.","honestly"],
  ["Identify 'during' in: 'During the storm.'","Conjunction","Preposition","Adverb","Noun",1,"Shows time relation.","during"],
  ["What is 'Ouch' in: 'Ouch! That hurt!'","Verb","Adjective","Interjection","Noun",2,"Expresses pain.","Ouch"],
  ["Identify 'many' in: 'Many students passed.'","Adverb","Adjective","Noun","Verb",1,"Quantifier/adjective.","many"],
];
const partsOfSpeech = posData.map(d => ({
  instruction: 'Identify the part of speech.',
  fields: {
    question: d[0], options: [d[1],d[2],d[3],d[4]],
    correctAnswerIndex: d[5], hint: d[6], targetWord: d[7],
  }
}));

// ── subjectVerbAgreement ──
const svaData = [
  ["The team ___ playing well.","is","are",0,"Collective noun = singular."],
  ["Neither of them ___ ready.","is","are",0,"'Neither of' = singular."],
  ["The students ___ studying hard.","is","are",1,"Plural subject."],
  ["Each of the boys ___ a prize.","has","have",0,"'Each' = singular."],
  ["Mathematics ___ my favorite subject.","is","are",0,"Subject name = singular."],
  ["The news ___ very surprising.","is","are",0,"'News' = singular."],
  ["The police ___ investigating.","is","are",1,"'Police' = plural."],
  ["Bread and butter ___ my breakfast.","is","are",0,"Combined = one concept."],
  ["One of the cars ___ broken.","is","are",0,"'One of' = singular."],
  ["The committee ___ decided unanimously.","has","have",0,"Collective = singular."],
  ["Measles ___ a childhood disease.","is","are",0,"Disease name = singular."],
  ["Five miles ___ a long distance.","is","are",0,"Distance = singular concept."],
  ["The scissors ___ on the table.","is","are",1,"'Scissors' = plural."],
  ["Either he or they ___ coming.","is","are",1,"Nearest subject = plural."],
  ["The furniture ___ very old.","is","are",0,"Uncountable = singular."],
  ["Many a student ___ failed.","has","have",0,"'Many a' = singular verb."],
  ["The United States ___ large.","is","are",0,"Country name = singular."],
  ["Physics ___ difficult but rewarding.","is","are",0,"Subject name = singular."],
  ["Every boy and girl ___ a book.","has","have",0,"'Every' = singular."],
  ["The pair of shoes ___ new.","is","are",0,"'Pair' = singular."],
  ["No news ___ good news.","is","are",0,"'News' = singular."],
  ["The audience ___ clapping loudly.","is","are",0,"Collective = singular."],
  ["A number of people ___ waiting.","is","are",1,"'A number of' = plural."],
  ["The number of students ___ growing.","is","are",0,"'The number of' = singular."],
  ["Either she or I ___ going.","am","is",0,"Nearest subject = I."],
  ["Tom, along with his friends, ___ here.","is","are",0,"Main subject is singular."],
  ["The trousers ___ too tight.","is","are",1,"'Trousers' = plural."],
  ["Economics ___ an interesting field.","is","are",0,"Subject name = singular."],
  ["Not only he but also they ___ happy.","is","are",1,"Nearest subject rule."],
  ["Ten dollars ___ too much for this.","is","are",0,"Amount = singular concept."],
];
const subjectVerbAgreement = svaData.map(d => ({
  instruction: 'Choose the correct verb.',
  fields: {
    question: d[0], options: [d[1],d[2]], correctAnswerIndex: d[3], hint: d[4],
    sentence: d[0],
  }
}));

// ── clauseConnector ──
const ccData = [
  ["I was tired ___ I went to bed early.","so","but","because","although",0,"Cause → result."],
  ["She studied hard ___ she passed the exam.","but","and","although","so",1,"Addition/sequence."],
  ["___ it was raining, we went outside.","Because","Although","So","And",1,"Contrast/concession."],
  ["He is smart ___ hardworking.","but","and","or","so",1,"Adding qualities."],
  ["Would you like tea ___ coffee?","and","but","or","so",2,"Giving alternatives."],
  ["I'll wait ___ you come back.","until","although","because","but",0,"Time clause."],
  ["___ he apologized, she forgave him.","Although","After","But","Or",1,"Time sequence."],
  ["She sings ___ she dances beautifully.","but","and","or","because",1,"Adding two actions."],
  ["He failed ___ he didn't study enough.","although","and","so","because",3,"Reason/cause."],
  ["Take an umbrella ___ it rains.","although","in case","but","and",1,"Precaution."],
  ["___ arriving late, he apologized.","Although","Upon","But","Or",1,"Time/manner."],
  ["I like summer ___ I prefer winter.","and","but","so","because",1,"Contrast."],
  ["She left early ___ avoid the traffic.","in order to","although","because","but",0,"Purpose."],
  ["___ you finish, please call me.","Although","When","But","And",1,"Time clause."],
  ["He is rich ___ unhappy.","and","yet","so","because",1,"Contrast despite expectation."],
  ["I'll go ___ you go too.","unless","although","but","if",3,"Condition."],
  ["She smiled ___ she was sad inside.","because","even though","so","and",1,"Concession."],
  ["Finish your homework ___ go play.","but","then","although","because",1,"Sequence."],
  ["I stayed home ___ I was sick.","but","and","because","although",2,"Reason."],
  ["He ran fast ___ he missed the bus.","and","but","so","because",1,"Unexpected result."],
  ["___ the weather was bad, we went out.","Because","Despite","Although","So",2,"Concession."],
  ["Not only smart ___ also kind.","and","but","or","yet",1,"Correlative conjunction."],
  ["She ate lunch ___ going to work.","after","before","although","because",1,"Time order."],
  ["I trust him ___ he is honest.","but","although","because","yet",2,"Reason."],
  ["You must hurry ___ you'll be late.","and","or","but","because",1,"Warning/alternative."],
  ["___ studying all night, he failed.","Despite","Because","So","And",0,"Concession."],
  ["She's talented, ___ she's also modest.","but","and","or","so",1,"Addition."],
  ["Call me ___ you need help.","although","whenever","but","so",1,"Time/frequency."],
  ["He neither called ___ texted me.","and","or","nor","but",2,"Correlative: neither...nor."],
  ["Let's leave now ___ we miss the train.","lest","and","but","because",0,"Purpose/avoidance."],
];
const clauseConnector = ccData.map(d => ({
  instruction: 'Choose the correct connector.',
  fields: {
    question: d[0], options: [d[1],d[2],d[3],d[4]],
    correctAnswerIndex: d[5], hint: d[6],
    firstClause: d[0].split('___')[0].trim(),
    secondClause: d[0].split('___')[1]?.trim() || '',
  }
}));

// ── voiceSwap ──
const vsData = [
  ["The cat chased the mouse.","The mouse was chased by the cat.","Active → Passive"],
  ["A cake was baked by Mom.","Mom baked a cake.","Passive → Active"],
  ["She wrote a beautiful poem.","A beautiful poem was written by her.","Active → Passive"],
  ["The letter was sent by Tom.","Tom sent the letter.","Passive → Active"],
  ["They are building a new bridge.","A new bridge is being built by them.","Active → Passive"],
  ["The song was sung by the choir.","The choir sang the song.","Passive → Active"],
  ["He painted the fence white.","The fence was painted white by him.","Active → Passive"],
  ["The window was broken by the ball.","The ball broke the window.","Passive → Active"],
  ["She teaches English every day.","English is taught by her every day.","Active → Passive"],
  ["The book was read by thousands.","Thousands read the book.","Passive → Active"],
  ["We will complete the task soon.","The task will be completed by us soon.","Active → Passive"],
  ["The car was repaired by the mechanic.","The mechanic repaired the car.","Passive → Active"],
  ["He has finished the assignment.","The assignment has been finished by him.","Active → Passive"],
  ["The cake was eaten by the children.","The children ate the cake.","Passive → Active"],
  ["She is cooking dinner right now.","Dinner is being cooked by her right now.","Active → Passive"],
  ["The film was directed by Spielberg.","Spielberg directed the film.","Passive → Active"],
  ["I will send the package tomorrow.","The package will be sent by me tomorrow.","Active → Passive"],
  ["The painting was admired by everyone.","Everyone admired the painting.","Passive → Active"],
  ["They had already solved the problem.","The problem had already been solved by them.","Active → Passive"],
  ["The house was designed by an architect.","An architect designed the house.","Passive → Active"],
  ["She can speak four languages.","Four languages can be spoken by her.","Active → Passive"],
  ["The homework was completed by all students.","All students completed the homework.","Passive → Active"],
  ["People celebrate festivals with joy.","Festivals are celebrated with joy by people.","Active → Passive"],
  ["The novel was written by Dickens.","Dickens wrote the novel.","Passive → Active"],
  ["He must finish the report today.","The report must be finished by him today.","Active → Passive"],
  ["The tree was planted by volunteers.","Volunteers planted the tree.","Passive → Active"],
  ["She has been teaching for ten years.","Students have been taught by her for ten years.","Active → Passive"],
  ["The prize was won by our team.","Our team won the prize.","Passive → Active"],
  ["The children are flying kites.","Kites are being flown by the children.","Active → Passive"],
  ["A new policy was announced by the CEO.","The CEO announced a new policy.","Passive → Active"],
];
const voiceSwap = vsData.map(d => ({
  instruction: d[2],
  fields: {
    question: `Convert: "${d[0]}"`,
    options: [d[1], d[0], d[0]+' (no change)', d[1].replace(' by ',' from ')],
    correctAnswerIndex: 0,
    hint: d[2], passiveSentence: d[2].includes('Passive') ? d[0] : d[1],
    activeSentence: d[2].includes('Active') ? d[0] : d[1],
    explanation: d[1],
  }
}));

// ── questionFormatter ──
const qfData = [
  ["She likes ice cream.","Does she like ice cream?","Yes/No question"],
  ["They went to school.","Did they go to school?","Past tense question"],
  ["He is a doctor.","Is he a doctor?","Be-verb question"],
  ["She can swim well.","Can she swim well?","Modal question"],
  ["They have finished lunch.","Have they finished lunch?","Perfect tense question"],
  ["He lives in London.","Where does he live?","Wh-question"],
  ["She bought three books.","How many books did she buy?","Quantity question"],
  ["They arrived yesterday.","When did they arrive?","Time question"],
  ["He was reading a novel.","What was he reading?","Object question"],
  ["She studies because she loves learning.","Why does she study?","Reason question"],
  ["Tom broke the window.","Who broke the window?","Subject question"],
  ["She is cooking dinner.","Is she cooking dinner?","Present continuous"],
  ["They will come tomorrow.","Will they come tomorrow?","Future question"],
  ["He has been working here.","Has he been working here?","Perfect continuous"],
  ["She speaks French fluently.","Does she speak French fluently?","Yes/No question"],
  ["They were playing outside.","Were they playing outside?","Past continuous"],
  ["He should apologize.","Should he apologize?","Modal question"],
  ["She traveled by train.","How did she travel?","Manner question"],
  ["They live on Main Street.","Where do they live?","Place question"],
  ["He will have finished by then.","Will he have finished by then?","Future perfect"],
  ["I am going to the store.","Am I going to the store?","Be-verb question"],
  ["She must complete the form.","Must she complete the form?","Modal question"],
  ["They ate pizza for dinner.","What did they eat for dinner?","Object question"],
  ["He runs five miles daily.","How far does he run daily?","Distance question"],
  ["She was born in Paris.","Where was she born?","Place question"],
  ["They have been waiting long.","How long have they been waiting?","Duration question"],
  ["He could solve the problem.","Could he solve the problem?","Modal question"],
  ["She drives to work daily.","Does she drive to work daily?","Yes/No question"],
  ["They met at the cafe.","Where did they meet?","Place question"],
  ["He is reading Tom's book.","Whose book is he reading?","Possessive question"],
];
const questionFormatter = qfData.map(d => ({
  instruction: d[2],
  fields: {
    question: `Convert to a question: "${d[0]}"`,
    sentence: d[0],
    options: [d[1], d[0]+'?', 'Do '+d[0].toLowerCase(), d[0].replace('.','?')],
    correctAnswerIndex: 0,
    hint: d[2],
    explanation: d[1],
  }
}));

// ── articleInsertion ──
const aiData = [
  ["I saw ___ elephant at the zoo.","a","an","the","no article",1,"Vowel sound = 'an'."],
  ["___ sun rises in the east.","A","An","The","No article",2,"Unique object = 'the'."],
  ["She is ___ honest person.","a","an","the","no article",1,"Silent 'h' = vowel sound."],
  ["I need ___ glass of water.","a","an","the","no article",0,"Consonant sound = 'a'."],
  ["He plays ___ guitar beautifully.","a","an","the","no article",2,"Musical instruments use 'the'."],
  ["___ Mount Everest is very tall.","A","An","The","No article",3,"Proper noun of mountain."],
  ["She wants to be ___ engineer.","a","an","the","no article",1,"Vowel sound = 'an'."],
  ["___ milk is good for health.","A","An","The","No article",3,"General uncountable = no article."],
  ["I bought ___ umbrella yesterday.","a","an","the","no article",1,"Vowel sound = 'an'."],
  ["He is ___ tallest boy in class.","a","an","the","no article",2,"Superlative uses 'the'."],
  ["___ honesty is the best policy.","A","An","The","No article",3,"Abstract noun = no article."],
  ["She ate ___ apple for lunch.","a","an","the","no article",1,"Vowel sound = 'an'."],
  ["We visited ___ Eiffel Tower.","a","an","the","no article",2,"Famous landmark = 'the'."],
  ["___ water in this bottle is cold.","A","An","The","No article",2,"Specific water = 'the'."],
  ["He is ___ European tourist.","a","an","the","no article",0,"'European' starts with /j/ sound."],
  ["I have ___ dog and ___ cat.","a...a","an...an","the...the","a...an",0,"Consonant sounds = 'a'."],
  ["___ Pacific Ocean is vast.","A","An","The","No article",2,"Ocean names use 'the'."],
  ["She gave me ___ useful tip.","a","an","the","no article",0,"'Useful' starts with /j/ sound."],
  ["He wants ___ hour to rest.","a","an","the","no article",1,"Silent 'h' in 'hour'."],
  ["___ gold is a precious metal.","A","An","The","No article",3,"General material = no article."],
  ["Please pass me ___ salt.","a","an","the","no article",2,"Specific item = 'the'."],
  ["She is ___ university student.","a","an","the","no article",0,"'University' = /j/ sound."],
  ["___ Earth revolves around ___ Sun.","A...a","An...an","The...the","No article",2,"Unique objects = 'the'."],
  ["I need ___ new pair of shoes.","a","an","the","no article",0,"Consonant sound = 'a'."],
  ["___ Amazon is a long river.","A","An","The","No article",2,"River names use 'the'."],
  ["He is ___ one-year-old baby.","a","an","the","no article",0,"'One' starts with /w/ sound."],
  ["___ happiness cannot be bought.","A","An","The","No article",3,"Abstract noun = no article."],
  ["She lives in ___ United States.","a","an","the","no article",2,"Country with 'United' = 'the'."],
  ["I saw ___ owl in the garden.","a","an","the","no article",1,"Vowel sound = 'an'."],
  ["___ lunch is ready now.","A","An","The","No article",3,"Meal names = no article."],
];
const articleInsertion = aiData.map(d => ({
  instruction: 'Select the correct article.',
  fields: {
    question: d[0], options: [d[1],d[2],d[3],d[4]],
    correctAnswerIndex: d[5], hint: d[6],
    sentenceWithBlank: d[0], articleToInsert: [d[1],d[2],d[3],d[4]][d[5]],
  }
}));

module.exports = {
  grammarQuest, sentenceCorrection, wordReorder, tenseMastery,
  partsOfSpeech, subjectVerbAgreement, clauseConnector, voiceSwap,
  questionFormatter, articleInsertion,
};
