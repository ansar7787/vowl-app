// scripts/shadowing_data_gen.js
// Generates exactly 600 unique shadowing challenges with accurate stress patterns

function generateUniqueShadowingQuestions() {
  const allQuestions = [];

  const addQ = (sentence, stressPattern, hint) => {
    allQuestions.push({
      instruction: "Listen and echo with exact rhythm.",
      interactionType: "speech",
      sentence,
      stressPattern,
      hint
    });
  };

  // 1. Obligations (Subject + need to + Verb + Object + Time)
  const subj1 = [
    { t: "I", s: "I" },
    { t: "We", s: "WE" },
    { t: "The team", s: "The TEAM" },
    { t: "My boss", s: "My BOSS" },
  ];
  const verb1 = [
    { t: "finish", s: "FINish" },
    { t: "review", s: "reVIEW" },
    { t: "update", s: "UPdate" },
    { t: "cancel", s: "CANcel" },
  ];
  const obj1 = [
    { t: "the report", s: "the rePORT" },
    { t: "the project", s: "the PROJect" },
    { t: "the budget", s: "the BUDget" },
    { t: "the schedule", s: "the SCHEDule" },
  ];
  const time1 = [
    { t: "by tomorrow", s: "by toMORrow" },
    { t: "this afternoon", s: "this afterNOON" },
    { t: "before noon", s: "beFORE NOON" },
    { t: "next week", s: "NEXT WEEK" },
  ];

  for (let s of subj1) {
    for (let v of verb1) {
      for (let o of obj1) {
        for (let t of time1) {
          addQ(
            `${s.t} need to ${v.t} ${o.t} ${t.t}.`,
            `${s.s} NEED to ${v.s} ${o.s} ${t.s}`,
            "Stress the main action and time."
          );
        }
      }
    }
  } // 4 * 4 * 4 * 4 = 256

  // 2. Polite Requests (Could you + verb + object + context)
  const reqVerbs = [
    { t: "send me", s: "SEND me" },
    { t: "print out", s: "PRINT OUT" },
    { t: "look over", s: "LOOK OVer" },
    { t: "bring me", s: "BRING me" }
  ];
  const reqObjs = [
    { t: "those files", s: "those FILES" },
    { t: "the documents", s: "the DOCuments" },
    { t: "the contracts", s: "the CONtracts" },
    { t: "the tickets", s: "the TICKets" }
  ];
  const reqCtx = [
    { t: "when you have a minute", s: "when you HAVE a MINute" },
    { t: "before you leave", s: "beFORE you LEAVE" },
    { t: "as soon as possible", s: "as SOON as POSsible" },
    { t: "later today", s: "LAter toDAY" }
  ];

  for (let v of reqVerbs) {
    for (let o of reqObjs) {
      for (let c of reqCtx) {
        addQ(
          `Could you ${v.t} ${o.t} ${c.t}?`,
          `COULD you ${v.s} ${o.s} ${c.s}?`,
          "Polite requests gently rise at the end."
        );
      }
    }
  } // 4 * 4 * 4 = 64

  // 3. Opinions / Thoughts (I think that + subject + is + adjective + context)
  const opSubj = [
    { t: "this idea", s: "this iDEA" },
    { t: "the new design", s: "the NEW deSIGN" },
    { t: "the proposal", s: "the proPOsal" },
    { t: "their strategy", s: "their STRATegy" }
  ];
  const opAdj = [
    { t: "absolutely brilliant", s: "ABsolutely BRILliant" },
    { t: "a bit confusing", s: "a BIT conFUSing" },
    { t: "really interesting", s: "REALly INteresting" },
    { t: "quite expensive", s: "QUITE exPENsive" },
    { t: "very effective", s: "VERy efFECtive" }
  ];
  const opCtx = [
    { t: "for our market", s: "for our MARket" },
    { t: "in the long run", s: "in the LONG RUN" },
    { t: "at this moment", s: "at THIS MOment" }
  ];

  for (let s of opSubj) {
    for (let a of opAdj) {
      for (let c of opCtx) {
        addQ(
          `I think that ${s.t} is ${a.t} ${c.t}.`,
          `I THINK that ${s.s} is ${a.s} ${c.s}`,
          "Emphasize the descriptive adjectives."
        );
      }
    }
  } // 4 * 5 * 3 = 60

  // 4. Daily Life / Routine (Subject + adverb + verb + location/object)
  const dlSubj = [
    { t: "My sister", s: "My SISter" },
    { t: "Our neighbor", s: "Our NEIGHbor" },
    { t: "The teacher", s: "The TEACHer" },
    { t: "My best friend", s: "My BEST FRIEND" }
  ];
  const dlAdv = [
    { t: "usually", s: "USually" },
    { t: "always", s: "ALways" },
    { t: "rarely", s: "RAREly" },
    { t: "sometimes", s: "SOMEtimes" }
  ];
  const dlVerbObj = [
    { t: "drinks coffee", s: "DRINKS COFfee" },
    { t: "reads a book", s: "READS a BOOK" },
    { t: "goes for a walk", s: "GOES for a WALK" },
    { t: "watches a movie", s: "WATCHes a MOvie" }
  ];
  const dlLoc = [
    { t: "in the evening", s: "in the EVEning" },
    { t: "on the weekend", s: "on the WEEKend" },
    { t: "after dinner", s: "AFter DINner" }
  ];

  for (let s of dlSubj) {
    for (let a of dlAdv) {
      for (let v of dlVerbObj) {
        for (let l of dlLoc) {
          addQ(
            `${s.t} ${a.t} ${v.t} ${l.t}.`,
            `${s.s} ${a.s} ${v.s} ${l.s}`,
            "Adverbs of frequency take stress."
          );
        }
      }
    }
  } // 4 * 4 * 4 * 3 = 192

  // 5. Travel & Directions (Excuse me, do you know where + place + is?)
  const places = [
    { t: "the nearest subway station", s: "the NEARest SUBway STAtion" },
    { t: "the post office", s: "the POST OFfice" },
    { t: "a good coffee shop", s: "a GOOD COFfee SHOP" },
    { t: "the art museum", s: "the ART muSEum" },
    { t: "the central library", s: "the CENtral LIBrary" }
  ];
  const ends = [
    { t: "is around here", s: "is aROUND HERE" },
    { t: "is located", s: "is loCAted" },
    { t: "might be", s: "MIGHT BE" },
    { t: "is exactly", s: "is exACTly" },
  ];

  for (let p of places) {
    for (let e of ends) {
      addQ(
        `Excuse me, do you know where ${p.t} ${e.t}?`,
        `exCUSE me, do you KNOW WHERE ${p.s} ${e.s}?`,
        "Question words and target nouns carry the melody."
      );
    }
  } // 5 * 4 = 20

  // 6. Weather & Small Talk (It looks like it's going to + weather + time)
  const weather = [
    { t: "rain heavily", s: "RAIN HEAVily" },
    { t: "snow a lot", s: "SNOW a LOT" },
    { t: "clear up", s: "CLEAR UP" },
    { t: "get very cold", s: "GET VERy COLD" },
  ];
  const wTime = [
    { t: "later this evening", s: "LAter this EVEning" },
    { t: "by tomorrow morning", s: "by toMORrow MORNing" },
    { t: "over the weekend", s: "OVer the WEEKend" },
  ];

  for (let w of weather) {
    for (let t of wTime) {
      addQ(
        `It looks like it's going to ${w.t} ${t.t}.`,
        `It LOOKS LIKE it's GOing to ${w.s} ${t.s}`,
        "Weather verbs and time markers are stressed."
      );
    }
  } // 4 * 3 = 12

  // Total generated: 256 + 64 + 60 + 192 + 20 + 12 = 604 questions!

  // Shuffle the questions so they are randomly distributed across levels
  // Use a seeded shuffle for consistency if needed, or just random
  for (let i = allQuestions.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [allQuestions[i], allQuestions[j]] = [allQuestions[j], allQuestions[i]];
  }

  // Slice exactly 600
  return allQuestions.slice(0, 600);
}

module.exports = { generateUniqueShadowingQuestions };
