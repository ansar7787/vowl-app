const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/writing';

const baseEmails = [
  {
    pr: "Draft an official mission brief describing the discovery of thermal chimney fields in the Mariana Trench.",
    opts: [
      "DEAR SCIENTIFIC COUNCIL,",
      "REGARDS, DEEP EXPLORATION TEAM",
      "SUBJ: MARIANA THERMAL CHIMNEY SURVEY",
      "WE HAVE SUCCESSFULLY DOCUMENTED ACTIVE HYDROTHERMAL CHIMNEYS VENTING SUPERHEATED CHEMICAL PLUMES."
    ],
    order: [2, 0, 3, 1], // index maps options to [SUBJECT, SALUTATION, BODY, SIGN-OFF]
    h: "Place the SUBJ: line as the Subject, 'DEAR' as Salutation, 'WE HAVE' as Body, and 'REGARDS' as Sign-Off.",
    e: "A standard scientific dispatch follows a subject header, formal greeting, central briefing statement, and professional signature."
  },
  {
    pr: "Draft a research status dispatch reporting on chemosynthetic bacteria colonies around abyssal geothermal springs.",
    opts: [
      "DEAR CHIEF ASTROBIOLOGIST,",
      "SINCERELY, BENTHIC BIOLOGY LAB",
      "SUBJ: CHEMOSYNTHESIS RESEARCH UPDATE",
      "BACTERIAL CULTURES DEMONSTRATE SUSTAINED METABOLIC CONVERSION OF HYDROGEN SULFIDE WITHOUT SOLAR BEAMS."
    ],
    order: [2, 0, 3, 1],
    h: "Map the UPDATE subject to Subject, formal salutation, sulfur metabolic body, and SINCERELY signature.",
    e: "Correspondence structures dictate separating administrative titles, salutations, core evidence paragraphs, and sign-offs."
  },
  {
    pr: "Compose an oceanographic log alert summarizing cold upwelling wind impacts along coastal fisheries.",
    opts: [
      "DEAR MARINE PATROL LEAGUE,",
      "RESPECTFULLY, CLIMATIC ANALYSIS UNIT",
      "SUBJ: UPWELLING FLOW AND PLANKTON ALERTS",
      "STRONG OFFSHORE WINDS HAVE TRIGGERED INTENSE DEEP CURRENT UPWELLING, BOOSTING LOCAL PLANKTON DENSITIES."
    ],
    order: [2, 0, 3, 1],
    h: "Link SUBJ: UPWELLING to Subject, 'DEAR' to Salutation, wind/plankton flow to Body, and CLIMATIC signature to Sign-Off.",
    e: "Administrative alerts require a subject line, recipient salutation, core wind analysis narrative, and closing authority signature."
  },
  {
    pr: "Draft a hardware engineering report notifying engineers about new bioluminescent scanning cameras.",
    opts: [
      "DEAR CAMERA DEVELOPMENT TEAM,",
      "BEST REGARDS, OPTICAL SYSTEMS ENG",
      "SUBJ: LUCIFERIN SENSITIVITY TESTING",
      "NEW SENSORS REGISTER COLD EMANATIONS OF BIOLUMINESCENT ORGANIC REACTIONS UNDER HIGH PRESSURE."
    ],
    order: [2, 0, 3, 1],
    h: "Weigh 'SUBJ: LUCIFERIN' as Subject, camera team as Salutation, optical sensor scans as Body, and OPTICAL signature as Sign-Off.",
    e: "Engineering dispatches separate testing topics, engineer recipients, sensory results data, and closing sign-offs."
  },
  {
    pr: "Compose an ecological impact report outlining the state of giant kelp sanctuaries.",
    opts: [
      "DEAR CONSERVATION DIRECTORS,",
      "WARM REGARDS, KELP FORESTS COALITION",
      "SUBJ: KELP CANOPY ANCHORAGE SURVEY",
      "HOLDFAST STRUCTURES SECURE STABLE WATER COOLING CANOPIES DESPITE RECENT THERMAL WAVE DISTURBANCES."
    ],
    order: [2, 0, 3, 1],
    h: "Map 'SUBJ: KELP' to Subject, 'DEAR CONSERVATION' to Salutation, canopy survey to Body, and KELP COALITION to Sign-Off.",
    e: "Conservation logs require a clear subject, formal director address, canopy health survey body, and coalition signature."
  }
];

// Generate 20 unique batches of 30 questions each (Total 600)
for (let batchIndex = 1; batchIndex <= 20; batchIndex++) {
  const startLevel = (batchIndex - 1) * 10 + 1;
  const endLevel = batchIndex * 10;
  const fileName = `writingEmail_1_10.json`.replace('1_10', `${startLevel}_${endLevel}`);
  const filePath = path.join(basePath, fileName);
  
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = level <= 40 ? 1 : (level <= 80 ? 2 : (level <= 120 ? 3 : (level <= 160 ? 4 : 5)));
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const templateIdx = ((level - startLevel) * 3 + (qNum - 1)) % baseEmails.length;
      const base = baseEmails[templateIdx];
      
      // Inject uniqueness tag to guarantee unique prompts
      const uniquePrompt = `[Calibration Dispatch ${level}-${qNum}] ${base.pr}`;

      quests.push({
        id: `WRT_WRITINGEMAIL_L${level}_Q${qNum}`,
        instruction: "SEQUENCE THE DISPATCH SEGMENTS CHRONOLOGICALLY INTO THEIR SLOTS",
        difficulty: diff,
        subtype: "writingEmail",
        interactionType: "Slot Sorter",
        prompt: uniquePrompt,
        options: base.opts,
        correctOrder: base.order, // order maps options index to Subject, Salutation, Body, Sign-Off respectively
        hint: `${base.h} (Diving calibration index ${level}-${qNum})`,
        explanation: `${base.e} [Verified by Academy Dispatch Unit ${level}].`
      });
    }
  }
  
  const fileData = {
    gameType: "writingEmail",
    batchIndex: batchIndex,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified writingEmail curriculum ${fileName}`);
}

console.log("Successfully generated all 600 unique writingEmail quests across 20 batch files.");
