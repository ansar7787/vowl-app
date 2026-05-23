const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/grammar';
const gameType = 'tenseMastery';

// 20 progressive topics (1 per batch file) with 10 unique questions for Past, Present, and Future each (600 total)
const topics = [
  {
    name: "Simple Cosmic Timeframes",
    past: [
      { s: "We calibrated the portal yesterday.", h: "Look for the past time marker 'yesterday'.", e: "The action occurred and was completed in the past." },
      { s: "The scout scanned the anomalies last cycle.", h: "Look for the time marker 'last cycle'.", e: "The scanning was completed in a previous cycle." },
      { s: "An energy pulse disrupted the shields an hour ago.", h: "Look for the phrase 'an hour ago'.", e: "The disruption occurred in past time." },
      { s: "They established the outpost in the early era.", h: "Look for the historical reference 'early era'.", e: "Establishing the outpost is a historical event." },
      { s: "I received the transmission this morning.", h: "Look for the time frame 'this morning' (already passed).", e: "The receiving of the transmission is complete." },
      { s: "The mainframe crashed during the test.", h: "Look for 'during the test' implying a past event.", e: "The crash is a past event." },
      { s: "A star collapsed in the adjacent sector.", h: "The verb 'collapsed' indicates a completed action.", e: "The collapse is a historical astronomical event." },
      { s: "She completed the decryption sequence yesterday.", h: "Look for the explicit past marker 'yesterday'.", e: "The decryption finished in the past." },
      { s: "We detected foreign signals last night.", h: "Look for 'last night'.", e: "The detection is a completed past event." },
      { s: "The crew evacuated the science sector.", h: "The past verb 'evacuated' signifies a completed task.", e: "The evacuation is in the past." }
    ],
    present: [
      { s: "We calibrate the portal right now.", h: "Look for the present marker 'right now'.", e: "The action is currently happening." },
      { s: "The scout scans the anomalies currently.", h: "Look for the adverb 'currently'.", e: "The scanning is happening in the present moment." },
      { s: "An energy pulse disrupts the shields at this instant.", h: "Look for the phrase 'at this instant'.", e: "The disruption is actively occurring." },
      { s: "They establish the outpost in this era.", h: "Look for the reference to 'this era'.", e: "The establishment represents a present state." },
      { s: "I receive the transmission as we speak.", h: "Look for the idiom 'as we speak'.", e: "The transmission is arriving now." },
      { s: "The mainframe crashes every time we boot it.", h: "Look for the habit marker 'every time'.", e: "Repetitive or habitual action in the present." },
      { s: "A star collapses in the adjacent sector.", h: "The verb 'collapses' indicates a present observation.", e: "The event is described in the present tense." },
      { s: "She completes the decryption sequence now.", h: "Look for the simple present marker 'now'.", e: "The action is happening right now." },
      { s: "We detect foreign signals every day.", h: "Look for the frequency marker 'every day'.", e: "Repetitive present action." },
      { s: "The crew evacuates the science sector currently.", h: "Look for the keyword 'currently'.", e: "The evacuation is happening at the present time." }
    ],
    future: [
      { s: "We will calibrate the portal tomorrow.", h: "Look for the future marker 'tomorrow'.", e: "The action will occur after the present moment." },
      { s: "The scout will scan the anomalies next cycle.", h: "Look for 'next cycle'.", e: "The scanning is planned for a future cycle." },
      { s: "An energy pulse will disrupt the shields soon.", h: "Look for the future adverb 'soon'.", e: "The disruption is predicted to happen later." },
      { s: "They will establish the outpost in the next era.", h: "Look for the marker 'next era'.", e: "This represents a future establishment." },
      { s: "I will receive the transmission later today.", h: "Look for 'later today'.", e: "The transmission will arrive in the future." },
      { s: "The mainframe will crash if we overload it.", h: "Look for the conditional future 'will crash'.", e: "The predicted consequence lies in the future." },
      { s: "A star will collapse in the adjacent sector.", h: "The future helper 'will collapse' indicates a future event.", e: "The event is predicted to happen later." },
      { s: "She will complete the decryption sequence shortly.", h: "Look for the future adverb 'shortly'.", e: "The completion lies ahead in time." },
      { s: "We will detect foreign signals eventually.", h: "Look for the future expectancy marker 'eventually'.", e: "The detection will occur in the future." },
      { s: "The crew will evacuate the science sector soon.", h: "Look for the future indicator 'soon'.", e: "The evacuation is scheduled for later." }
    ]
  },
  {
    name: "Continuous / Progressive Actions",
    past: [
      { s: "I was repairing the thrusters when the alarm rang.", h: "Look for 'was repairing' and 'when the alarm rang'.", e: "An ongoing action in the past was interrupted." },
      { s: "The droids were charging their batteries all night.", h: "Look for the past continuous 'were charging'.", e: "The charging was an ongoing process in the past." },
      { s: "We were navigating the nebula yesterday.", h: "Look for 'were navigating' combined with 'yesterday'.", e: "Describes a past continuous action." },
      { s: "She was monitoring the core temperature.", h: "Look for the auxiliary 'was' + present participle.", e: "Describes an ongoing state in past time." },
      { s: "The systems were failing rapidly during the storm.", h: "Look for 'were failing' and 'during the storm'.", e: "Represents progressive failure in the past." },
      { s: "They were decoding the matrix all evening.", h: "Look for the duration indicator 'all evening' in the past.", e: "Ongoing past decryption process." },
      { s: "I was observing the orbital alignment.", h: "Look for 'was observing'.", e: "The observation was in progress in the past." },
      { s: "The shields were fluctuating in the previous hour.", h: "Look for 'were fluctuating' and 'previous hour'.", e: "Progressive changes in the past." },
      { s: "We were fleeing the pirate cruiser.", h: "Look for the past auxiliary 'were fleeing'.", e: "Continuous flight in past time." },
      { s: "The scientist was recording data last cycle.", h: "Look for 'was recording' and 'last cycle'.", e: "Ongoing recording in the past." }
    ],
    present: [
      { s: "I am repairing the thrusters at this moment.", h: "Look for 'am repairing' and 'at this moment'.", e: "Ongoing action occurring now." },
      { s: "The droids are charging their batteries currently.", h: "Look for 'are charging' and 'currently'.", e: "Continuous charging happening now." },
      { s: "We are navigating the nebula right now.", h: "Look for 'are navigating' and 'right now'.", e: "Ongoing navigation in the present." },
      { s: "She is monitoring the core temperature currently.", h: "Look for the auxiliary 'is' + present participle.", e: "Ongoing present monitoring." },
      { s: "The systems are failing rapidly now.", h: "Look for 'are failing' and 'now'.", e: "Continuous failure in the present." },
      { s: "They are decoding the matrix at present.", h: "Look for 'are decoding' and 'at present'.", e: "Ongoing decryption in the present." },
      { s: "I am observing the orbital alignment today.", h: "Look for the present progressive 'am observing'.", e: "The observation is currently in progress." },
      { s: "The shields are fluctuating this minute.", h: "Look for 'are fluctuating' and 'this minute'.", e: "Fluctuations are happening right now." },
      { s: "We are fleeing the pirate cruiser now.", h: "Look for 'are fleeing' and 'now'.", e: "Active flight in the present." },
      { s: "The scientist is recording data right now.", h: "Look for 'is recording' and 'right now'.", e: "Ongoing recording in the present." }
    ],
    future: [
      { s: "I will be repairing the thrusters tomorrow.", h: "Look for 'will be repairing' and 'tomorrow'.", e: "Ongoing action scheduled for the future." },
      { s: "The droids will be charging their batteries next cycle.", h: "Look for 'will be charging' and 'next cycle'.", e: "Continuous future action." },
      { s: "We will be navigating the nebula soon.", h: "Look for 'will be navigating' and 'soon'.", e: "Continuous navigation in the future." },
      { s: "She will be monitoring the core temperature later.", h: "Look for the future continuous structure 'will be monitoring'.", e: "Ongoing monitoring set for later." },
      { s: "The systems will be failing if we don't act.", h: "Look for the predictive future continuous 'will be failing'.", e: "Predicted future continuous process." },
      { s: "They will be decoding the matrix tomorrow night.", h: "Look for 'will be decoding' and 'tomorrow night'.", e: "Continuous future decryption." },
      { s: "I will be observing the orbital alignment then.", h: "Look for 'will be observing' and the future tag 'then'.", e: "Continuous action in future time." },
      { s: "The shields will be fluctuating during the jump.", h: "Look for 'will be fluctuating' and 'during the jump' (future).", e: "Continuous future fluctuations." },
      { s: "We will be fleeing the zone by next hour.", h: "Look for the progressive future marker 'will be fleeing'.", e: "Continuous future retreat." },
      { s: "The scientist will be recording data tomorrow.", h: "Look for 'will be recording' and 'tomorrow'.", e: "Continuous future recording." }
    ]
  },
  {
    name: "Perfected Accomplishments",
    past: [
      { s: "We had secured the sector before they arrived.", h: "Look for the past perfect 'had secured'.", e: "The securing was completed before another past event." },
      { s: "The AI had predicted the collapse already.", h: "Look for 'had predicted' and 'already'.", e: "The prediction was complete prior to a past reference." },
      { s: "She had bypassed the lock before the guards woke.", h: "Look for the past perfect structure 'had bypassed'.", e: "Completed action prior to another past event." },
      { s: "The fuel had depleted before we reached the port.", h: "Look for 'had depleted' showing earlier completion.", e: "Depletion was fully complete in the past." },
      { s: "I had sent the distress signal earlier.", h: "Look for 'had sent' and the past marker 'earlier'.", e: "The sending was completed in the past." },
      { s: "They had initialized the shield prior to impact.", h: "Look for 'had initialized' and 'prior to impact'.", e: "Completed action before a past milestone." },
      { s: "The stars had aligned before we launched.", h: "Look for the auxiliary 'had' + past participle 'aligned'.", e: "Tense is past perfect." },
      { s: "He had studied the ruins before the storm hit.", h: "Look for 'had studied' and 'before the storm hit'.", e: "Completed past study." },
      { s: "We had unlocked the gate prior to the backup arrival.", h: "Look for 'had unlocked' showing earlier completion.", e: "Completed past action." },
      { s: "The pilot had adjusted the course before the collision.", h: "Look for 'had adjusted' showing past completion.", e: "Adjustment occurred before the past collision." }
    ],
    present: [
      { s: "We have secured the sector now.", h: "Look for the present perfect 'have secured' and 'now'.", e: "Action completed in the past with current relevance." },
      { s: "The AI has predicted the collapse already.", h: "Look for 'has predicted' with present relevance.", e: "The action is completed as of the present moment." },
      { s: "She has bypassed the lock successfully.", h: "Look for 'has bypassed' showing present completion.", e: "Completion in the present timeline." },
      { s: "The fuel has depleted completely.", h: "Look for 'has depleted' with current impact.", e: "The fuel state is currently empty." },
      { s: "I have sent the distress signal already.", h: "Look for 'have sent' and 'already'.", e: "The message is currently sent." },
      { s: "They have initialized the shield just now.", h: "Look for 'have initialized' and 'just now'.", e: "The action completed just at this moment." },
      { s: "The stars have aligned today.", h: "Look for the present perfect 'have aligned'.", e: "Alignment is complete in the current period." },
      { s: "He has studied the ruins recently.", h: "Look for the recent time marker 'recently'.", e: "Completed action in recent present time." },
      { s: "We have unlocked the gate now.", h: "Look for the present perfect 'have unlocked'.", e: "The gate is currently open." },
      { s: "The pilot has adjusted the course already.", h: "Look for 'has adjusted' showing present completion.", e: "Adjustment is completed as of now." }
    ],
    future: [
      { s: "We will have secured the sector by tomorrow.", h: "Look for 'will have secured' and 'by tomorrow'.", e: "Action will be completed by a specific future time." },
      { s: "The AI will have predicted the collapse by next cycle.", h: "Look for 'will have predicted' and 'by next cycle'.", e: "Future completion of prediction." },
      { s: "She will have bypassed the lock by the time you arrive.", h: "Look for 'will have bypassed'.", e: "Completion is set prior to a future event." },
      { s: "The fuel will have depleted by next hour.", h: "Look for 'will have depleted' showing future exhaustion.", e: "Predicts completed depletion in the future." },
      { s: "I will have sent the distress signal by then.", h: "Look for 'will have sent' and 'by then'.", e: "The action will be completed in the future." },
      { s: "They will have initialized the shield before the impact.", h: "Look for 'will have initialized' indicating future completion.", e: "Completed shield setup before future impact." },
      { s: "The stars will have aligned by next week.", h: "Look for the future perfect helper 'will have aligned'.", e: "Future completion of alignment." },
      { s: "He will have studied the ruins by next month.", h: "Look for 'will have studied' and 'by next month'.", e: "Completed future study." },
      { s: "We will have unlocked the gate before they land.", h: "Look for 'will have unlocked' showing future completion.", e: "Completed action before a future event." },
      { s: "The pilot will have adjusted the course before the event.", h: "Look for 'will have adjusted' showing future completion.", e: "Completed course correction in the future." }
    ]
  },
  {
    name: "Perfect Continuous Sequences",
    past: [
      { s: "We had been traveling for days when we saw the star.", h: "Look for 'had been traveling' indicating past ongoing duration.", e: "Ongoing past action interrupted by another past event." },
      { s: "The reactor had been leaking for hours before shutdown.", h: "Look for 'had been leaking'.", e: "Past continuous duration completed prior to a past action." },
      { s: "She had been researching the virus since yesterday.", h: "Look for 'had been researching'.", e: "Continuous study up to a past point in time." },
      { s: "They had been decoding files before the power cut.", h: "Look for 'had been decoding'.", e: "Ongoing duration before a past interruption." },
      { s: "The engines had been failing all day.", h: "Look for the past perfect continuous 'had been failing'.", e: "Ongoing failure leading to a past point." },
      { s: "I had been monitoring the signal for an hour.", h: "Look for 'had been monitoring'.", e: "Completed past duration of active monitoring." },
      { s: "We had been seeking the artifact since last cycle.", h: "Look for 'had been seeking' and 'last cycle'.", e: "Continuous search up to a past milestone." },
      { s: "The crew had been waiting for instructions.", h: "Look for 'had been waiting'.", e: "Ongoing waiting prior to a past update." },
      { s: "The computer had been calculating the trajectory.", h: "Look for the auxiliary combination 'had been calculating'.", e: "Continuous past calculation process." },
      { s: "He had been flying the shuttle since midnight.", h: "Look for 'had been flying'.", e: "Continuous flight up to a past reference point." }
    ],
    present: [
      { s: "We have been traveling for days now.", h: "Look for 'have been traveling' and 'now'.", e: "Action started in the past and is still ongoing." },
      { s: "The reactor has been leaking for hours.", h: "Look for 'has been leaking' showing current ongoing action.", e: "Continuous leak up to the present moment." },
      { s: "She has been researching the virus since yesterday.", h: "Look for 'has been researching' with present relevance.", e: "Active research continuing now." },
      { s: "They have been decoding files recently.", h: "Look for 'have been decoding' and 'recently'.", e: "Ongoing file decryption continuing in the present." },
      { s: "The engines have been failing all day today.", h: "Look for 'have been failing' and 'today'.", e: "Continuous failure extending into the present." },
      { s: "I have been monitoring the signal for an hour now.", h: "Look for 'have been monitoring' and 'now'.", e: "Active monitoring continuing at this instant." },
      { s: "We have been seeking the artifact since last cycle.", h: "Look for 'have been seeking' indicating ongoing search.", e: "The search remains active now." },
      { s: "The crew has been waiting for instructions today.", h: "Look for 'has been waiting' and 'today'.", e: "Continuous waiting ongoing in the present." },
      { s: "The computer has been calculating the trajectory.", h: "Look for 'has been calculating' showing active process.", e: "Ongoing present calculation." },
      { s: "He has been flying the shuttle since midnight.", h: "Look for 'has been flying' showing active flight.", e: "Continuous flight extending to the present." }
    ],
    future: [
      { s: "We will have been traveling for days by next week.", h: "Look for 'will have been traveling' and 'by next week'.", e: "Duration projected to complete at a future point." },
      { s: "The reactor will have been leaking for a year by tomorrow.", h: "Look for 'will have been leaking' and 'by tomorrow'.", e: "Projected continuous future duration." },
      { s: "She will have been researching the virus for a decade soon.", h: "Look for 'will have been researching' and 'soon'.", e: "Projected future research duration." },
      { s: "They will have been decoding files for months next cycle.", h: "Look for 'will have been decoding' and 'next cycle'.", e: "Future projection of continuous decryption." },
      { s: "The engines will have been failing for days by tomorrow.", h: "Look for 'will have been failing' and 'by tomorrow'.", e: "Projected future progressive failure duration." },
      { s: "I will have been monitoring the signal for a week soon.", h: "Look for 'will have been monitoring' and 'soon'.", e: "Projected duration of future monitoring." },
      { s: "We will have been seeking the artifact for years by then.", h: "Look for 'will have been seeking' and 'by then'.", e: "Continuous duration projected to a future milestone." },
      { s: "The crew will have been waiting for weeks by next month.", h: "Look for 'will have been waiting' and 'by next month'.", e: "Projected continuous wait time." },
      { s: "The computer will have been calculating for hours by noon.", h: "Look for the future perfect continuous 'will have been calculating'.", e: "Duration projected to a future hour." },
      { s: "He will have been flying the shuttle for days by tomorrow.", h: "Look for 'will have been flying' and 'by tomorrow'.", e: "Continuous future flight duration." }
    ]
  },
  {
    name: "Habitual or Customary Routines",
    past: [
      { s: "We used to perform calibrations in the old hangar.", h: "Look for the past habit marker 'used to'.", e: "Represents an custom or habit that was discontinued in the past." },
      { s: "The pilot regularly adjusted the fuel flow last year.", h: "Look for 'regularly' and 'last year'.", e: "Habitual past action." },
      { s: "They constantly scanned for invaders during the war.", h: "Look for 'constantly' and 'during the war'.", e: "Represents past recurring action." },
      { s: "She monitored the sensors daily in the previous cycle.", h: "Look for 'daily' and 'previous cycle'.", e: "Past habitual monitoring." },
      { s: "The systems failed habitually before the upgrade.", h: "Look for 'habitually' and 'before the upgrade'.", e: "Past recurring failure." },
      { s: "I decoded the signal routinely back then.", h: "Look for 'routinely' and 'back then'.", e: "Routines performed in the past." },
      { s: "The crew frequently evacuated due to solar flares.", h: "Look for the frequency marker 'frequently' in the past context.", e: "Frequent past occurrences." },
      { s: "The stars aligned periodically in that century.", h: "Look for the historical context 'in that century'.", e: "Past repetitive cosmic event." },
      { s: "We analyzed the samples weekly during the trial.", h: "Look for 'weekly' and 'during the trial'.", e: "Ongoing past scheduled actions." },
      { s: "He flew the shuttle every weekend during training.", h: "Look for 'every weekend' and 'during training'.", e: "Past routine actions." }
    ],
    present: [
      { s: "We perform calibrations in the hangar daily.", h: "Look for the present routine frequency 'daily'.", e: "Ongoing present routine." },
      { s: "The pilot regularly adjusts the fuel flow now.", h: "Look for the frequency 'regularly' and 'now'.", e: "Active present habit." },
      { s: "They constantly scan for invaders currently.", h: "Look for 'constantly' and 'currently'.", e: "Continuous routine in the present." },
      { s: "She monitors the sensors daily nowadays.", h: "Look for 'daily' and 'nowadays'.", e: "Ongoing present routine." },
      { s: "The systems fail habitually under high loads.", h: "Look for 'habitually' showing general present truths.", e: "Present recurring status." },
      { s: "I decode the signal routinely these days.", h: "Look for 'routinely' and 'these days'.", e: "Represents present ongoing routine." },
      { s: "The crew frequently evacuates due to warnings.", h: "Look for 'frequently' combined with present tense.", e: "Frequent present occurrence." },
      { s: "The stars align periodically in this galaxy.", h: "Describes a general scientific truth in the present.", e: "Present recurring cycle." },
      { s: "We analyze the samples weekly in the lab.", h: "Look for the scheduled frequency 'weekly'.", e: "Present schedule routine." },
      { s: "He flies the shuttle every weekend currently.", h: "Look for 'every weekend' and 'currently'.", e: "Active present routine." }
    ],
    future: [
      { s: "We will perform calibrations in the hangar henceforth.", h: "Look for 'will perform' and 'henceforth'.", e: "Future routine beginning later." },
      { s: "The pilot will regularly adjust the fuel flow starting tomorrow.", h: "Look for 'will adjust' and 'starting tomorrow'.", e: "Scheduled future habit." },
      { s: "They will constantly scan for invaders in the next zone.", h: "Look for 'will scan' and 'next zone'.", e: "Anticipated future continuous routine." },
      { s: "She will monitor the sensors daily from now on.", h: "Look for 'will monitor' and 'from now on'.", e: "Future habitual monitoring." },
      { s: "The systems will fail habitually if we do not patch them.", h: "Look for 'will fail habitually'.", e: "Predicted future recurring status." },
      { s: "I will decode the signal routinely in the future.", h: "Look for 'will decode' and 'in the future'.", e: "Planned future routine." },
      { s: "The crew will frequently evacuate the hangar henceforth.", h: "Look for 'will evacuate' and 'henceforth'.", e: "Anticipated frequent future occurrence." },
      { s: "The stars will align periodically next eon.", h: "Look for 'will align' and 'next eon'.", e: "Anticipated future cycle." },
      { s: "We will analyze the samples weekly next semester.", h: "Look for 'will analyze' and 'next semester'.", e: "Scheduled future routine." },
      { s: "He will fly the shuttle every weekend during the mission.", h: "Look for 'will fly' and 'during the mission' (future).", e: "Planned future routine." }
    ]
  },
  {
    name: "Remote vs. Immediate Observational States",
    past: [
      { s: "Eons ago, the planet hosted advanced civilizations.", h: "Look for the remote past marker 'Eons ago'.", e: "The hosting occurred and ended in the deep past." },
      { s: "Previously, the mainframe processed double the bandwidth.", h: "Look for the past transition marker 'Previously'.", e: "Refers to a past state of processing." },
      { s: "Initially, we detected zero ambient radiation.", h: "Look for the historical trigger 'Initially'.", e: "Refers to the start of a past mission." },
      { s: "Before the update, the AI encountered fatal loops.", h: "Look for 'Before the update'.", e: "Past systemic failures." },
      { s: "Yesterday, the crew witnessed a hyper-nova.", h: "Look for the past marker 'Yesterday'.", e: "Completed past observation." },
      { s: "A moment ago, the sensor blinked twice.", h: "Look for the immediate past 'A moment ago'.", e: "The blinking occurred just before the present." },
      { s: "Last cycle, the terminal displayed an warning.", h: "Look for the past cycle reference.", e: "Completed past presentation of warning." },
      { s: "Earlier, the scout reported scout status.", h: "Look for the past marker 'Earlier'.", e: "The reporting happened in the past." },
      { s: "In ancient times, astronomers observed this constellation.", h: "Look for the historical marker 'In ancient times'.", e: "Completed past observation." },
      { s: "Formerly, the portal linked to sector seven.", h: "Look for the historical adverb 'Formerly'.", e: "Tense is past." }
    ],
    present: [
      { s: "Currently, the planet hosts advanced civilizations.", h: "Look for the present transition marker 'Currently'.", e: "Refers to a present active state." },
      { s: "At present, the mainframe processes double the bandwidth.", h: "Look for the marker 'At present'.", e: "Refers to active present processing." },
      { s: "At this stage, we detect zero ambient radiation.", h: "Look for the present marker 'At this stage'.", e: "Refers to current active detection." },
      { s: "Following the update, the AI encounters fatal loops.", h: "Look for 'Following the update' in the present tense.", e: "Present active systemic state." },
      { s: "Right now, the crew witnesses a hyper-nova.", h: "Look for the immediate marker 'Right now'.", e: "Ongoing observation in the present." },
      { s: "At this very split second, the sensor blinks twice.", h: "Look for 'At this very split second'.", e: "Event occurring exactly at this instant." },
      { s: "In this cycle, the terminal displays an warning.", h: "Look for 'In this cycle' representing current time.", e: "Active present display state." },
      { s: "Currently, the scout reports scout status.", h: "Look for the active adverb 'Currently'.", e: "Reporting is happening now." },
      { s: "In modern times, astronomers observe this constellation.", h: "Look for the modern context 'In modern times'.", e: "Active present scientific observation." },
      { s: "At this moment, the portal links to sector seven.", h: "Look for the active present marker 'At this moment'.", e: "Active present connection." }
    ],
    future: [
      { s: "In future eons, the planet will host advanced civilizations.", h: "Look for the future marker 'In future eons'.", e: "Predicted future state." },
      { s: "Subsequently, the mainframe will process double the bandwidth.", h: "Look for the transition adverb 'Subsequently'.", e: "Predicted future capability." },
      { s: "Eventually, we will detect zero ambient radiation.", h: "Look for the future marker 'Eventually'.", e: "Anticipated future detection." },
      { s: "After the next patch, the AI will encounter fatal loops.", h: "Look for the conditional future 'will encounter'.", e: "Predicted future systemic state." },
      { s: "Tomorrow, the crew will witness a hyper-nova.", h: "Look for the future marker 'Tomorrow'.", e: "Scheduled future observation." },
      { s: "In a moment, the sensor will blink twice.", h: "Look for 'In a moment' pointing ahead.", e: "The blinking is predicted to happen soon." },
      { s: "Next cycle, the terminal will display an warning.", h: "Look for the upcoming reference 'Next cycle'.", e: "Scheduled future warning." },
      { s: "Later, the scout will report scout status.", h: "Look for the future time tag 'Later'.", e: "The report will occur in the future." },
      { s: "In future eras, astronomers will observe this constellation.", h: "Look for 'In future eras' and 'will observe'.", e: "Anticipated future observation." },
      { s: "Eventually, the portal will link to sector seven.", h: "Look for 'Eventually' and 'will link'.", e: "Anticipated future connection." }
    ]
  },
  {
    name: "Temporal Sub-Clauses & Time Triggers",
    past: [
      { s: "Before we departed, the commander gave us the key.", h: "Look for the past clause 'Before we departed'.", e: "All actions occurred and concluded in the past." },
      { s: "As soon as the pulse fired, the shields failed.", h: "Look for the past time trigger 'As soon as'.", e: "Describes a sequence of completed past events." },
      { s: "Until the backup arrived, we fought the fire.", h: "Look for the past conjunction 'Until' + past verb.", e: "Refers to continuous past action ending in the past." },
      { s: "Once the system rebooted, the grid stabilized.", h: "Look for 'Once the system rebooted' (past).", e: "Completed past sequence of events." },
      { s: "While the planet rotated, the telescope recorded data.", h: "Look for 'While the planet rotated' indicating past parallel events.", e: "Tense is simple past." },
      { s: "When the alarm sounded, the crew ran to the pods.", h: "Look for 'When the alarm sounded'.", e: "Completed past reaction sequence." },
      { s: "No sooner had the hatch opened than the air escaped.", h: "Look for 'had the hatch opened' in past perfect inversion.", e: "Represents rapid past sequence." },
      { s: "By the time they called, we had left.", h: "Look for the past trigger 'By the time'.", e: "Describes an action completed before a past moment." },
      { s: "Since they launched, we monitored their flight.", h: "Look for the past anchor 'Since they launched'.", e: "Completed past monitoring." },
      { s: "After the shield broke, the hull sustained damage.", h: "Look for the past sequence 'After the shield broke'.", e: "Tense is simple past." }
    ],
    present: [
      { s: "Before we depart, the commander gives us the key.", h: "Look for the present clause 'Before we depart'.", e: "Describes present habit or direct instruction." },
      { s: "As soon as the pulse fires, the shields fail.", h: "Look for the present conditional trigger 'As soon as'.", e: "Describes a present natural law or standard system reaction." },
      { s: "Until the backup arrives, we fight the fire.", h: "Look for 'Until' + present verb.", e: "Refers to active present struggle." },
      { s: "Once the system reboots, the grid stabilizes.", h: "Look for the present sequence trigger 'Once'.", e: "Describes a present programmatic rule." },
      { s: "While the planet rotates, the telescope records data.", h: "Describes ongoing parallel actions in the present.", e: "Tense is simple present." },
      { s: "When the alarm sounds, the crew runs to the pods.", h: "Look for the recurring trigger 'When'.", e: "Present recurring standard operating procedure." },
      { s: "No sooner does the hatch open than the air escapes.", h: "Look for the present inversion structure 'does the hatch open'.", e: "Describes a present systemic inevitability." },
      { s: "By the time they call, we leave the ship.", h: "Look for 'By the time they call'.", e: "Standard present routine or rule." },
      { s: "Since they launch now, we monitor their flight.", h: "Look for the present trigger 'Since they launch now'.", e: "Present active monitoring." },
      { s: "After the shield breaks, the hull sustains damage.", h: "Describes sequential events in the present timeline.", e: "Tense is simple present." }
    ],
    future: [
      { s: "Before we depart, the commander will give us the key.", h: "Look for the future main clause 'will give'.", e: "The giving lies in the future." },
      { s: "As soon as the pulse fires, the shields will fail.", h: "Look for 'will fail' following the present conditional clause.", e: "Future consequence predicted." },
      { s: "Until the backup arrives, we will fight the fire.", h: "Look for 'will fight' indicating future commitment.", e: "Ongoing future action." },
      { s: "Once the system reboots, the grid will stabilize.", h: "Look for 'will stabilize' showing future certainty.", e: "Future consequence." },
      { s: "While the planet rotates, the telescope will record data.", h: "Look for 'will record' describing future observation.", e: "Future planned actions." },
      { s: "When the alarm sounds, the crew will run to the pods.", h: "Look for 'will run' showing future reaction.", e: "Future action sequence." },
      { s: "No sooner will the hatch open than the air will escape.", h: "Look for future indicators 'will the hatch open'.", e: "Predicted rapid future sequence." },
      { s: "By the time they call, we will have left.", h: "Look for 'will have left' showing future perfect completion.", e: "Completed action prior to a future moment." },
      { s: "Since they will launch soon, we will monitor their flight.", h: "Look for 'will launch soon' and 'will monitor'.", e: "Planned future monitoring." },
      { s: "After the shield breaks, the hull will sustain damage.", h: "Look for 'will sustain' predicting future consequence.", e: "Future damage prediction." }
    ]
  },
  {
    name: "Perfect Tense Inversions & Modals",
    past: [
      { s: "You should have completed the scan yesterday.", h: "Look for the past modal 'should have completed'.", e: "Action was advisable but not completed in the past." },
      { s: "We could have bypassed the firewall last night.", h: "Look for past capability 'could have bypassed'.", e: "Past ability that was not realized." },
      { s: "They must have reached the planet by now.", h: "Look for past deduction 'must have reached'.", e: "Deduction about a past completed event." },
      { s: "He might have sent the data earlier.", h: "Look for past possibility 'might have sent'.", e: "Speculation about a past action." },
      { s: "We would have repaired the hull if we had steel.", h: "Look for past counterfactual 'would have repaired'.", e: "Tense is past perfect modal conditional." },
      { s: "The scout ought to have returned yesterday.", h: "Look for past duty 'ought to have returned'.", e: "Past obligation that was unfulfilled." },
      { s: "They shouldn't have activated the beacon.", h: "Look for past negative modal 'shouldn't have activated'.", e: "Past inadvisable action." },
      { s: "I needn't have downloaded the entire database.", h: "Look for past lack of necessity 'needn't have downloaded'.", e: "An unnecessary action was done in the past." },
      { s: "She was supposed to have launched the probe.", h: "Look for the past structure 'was supposed to have launched'.", e: "Unfulfilled past expectation." },
      { s: "You could have warned us before the explosion.", h: "Look for past capability 'could have warned'.", e: "Unrealized past capability." }
    ],
    present: [
      { s: "You should complete the scan now.", h: "Look for the present modal 'should complete'.", e: "Action is advisable in the present moment." },
      { s: "We can bypass the firewall currently.", h: "Look for present capability 'can bypass'.", e: "Active present ability." },
      { s: "They must reach the planet today.", h: "Look for present necessity 'must reach'.", e: "Strong present obligation." },
      { s: "He might send the data right now.", h: "Look for present possibility 'might send'.", e: "Speculation about a present action." },
      { s: "We would repair the hull if we had steel now.", h: "Look for second conditional present 'would repair'.", e: "Present hypothetical conditional." },
      { s: "The scout ought to return currently.", h: "Look for present duty 'ought to return'.", e: "Present obligation." },
      { s: "They shouldn't activate the beacon now.", h: "Look for present negative advice 'shouldn't activate'.", e: "Present inadvisable action." },
      { s: "I needn't download the database today.", h: "Look for present lack of necessity 'needn't download'.", e: "Unnecessary present action." },
      { s: "She is supposed to launch the probe currently.", h: "Look for the present structure 'is supposed to launch'.", e: "Active present expectation." },
      { s: "You can warn us now before it's too late.", h: "Look for present capability 'can warn'.", e: "Active present capability." }
    ],
    future: [
      { s: "You should complete the scan tomorrow.", h: "Look for future expectation 'should complete' with 'tomorrow'.", e: "Action advisable in the future." },
      { s: "We will be able to bypass the firewall tomorrow.", h: "Look for future ability 'will be able to bypass'.", e: "Future capability." },
      { s: "They must reach the planet next cycle.", h: "Look for future necessity 'must reach' with 'next cycle'.", e: "Future obligation." },
      { s: "He might send the data eventually.", h: "Look for future possibility 'might send' with 'eventually'.", e: "Speculation about a future action." },
      { s: "We would repair the hull if we got steel tomorrow.", h: "Look for future conditional 'would repair'.", e: "Future hypothetical." },
      { s: "The scout ought to return tomorrow.", h: "Look for future duty 'ought to return' with 'tomorrow'.", e: "Future obligation." },
      { s: "They shouldn't activate the beacon tomorrow.", h: "Look for future negative advice 'shouldn't activate' with 'tomorrow'.", e: "Future inadvisable action." },
      { s: "I needn't download the database tomorrow.", h: "Look for future lack of necessity 'needn't download' with 'tomorrow'.", e: "Unnecessary future action." },
      { s: "She is supposed to launch the probe tomorrow.", h: "Look for 'supposed to launch' with future 'tomorrow'.", e: "Scheduled future expectation." },
      { s: "You will be able to warn us before the next launch.", h: "Look for future capability 'will be able to warn'.", e: "Future potential capability." }
    ]
  },
  {
    name: "Active vs. Passive Shifts",
    past: [
      { s: "The capsule was intercepted by pirates yesterday.", h: "Look for the past passive 'was intercepted' and 'yesterday'.", e: "Completed action done to the subject in the past." },
      { s: "Ancient coordinates were carved into the relic.", h: "Look for passive auxiliary 'were carved'.", e: "Historical passive state." },
      { s: "Our thrusters were heavily damaged in the crossfire.", h: "Look for past passive 'were damaged'.", e: "Past damage event in passive voice." },
      { s: "A distress code was broadcast last night.", h: "Look for passive 'was broadcast' and 'last night'.", e: "Completed past broadcast." },
      { s: "The reactor was shut down by the automation.", h: "Look for past passive 'was shut down'.", e: "Passive shutdown completed in the past." },
      { s: "Several stars were swallowed by the black hole.", h: "Look for past passive 'were swallowed'.", e: "Cosmic historical event." },
      { s: "The engine was repaired before the jump.", h: "Look for past passive 'was repaired'.", e: "Completed past repair." },
      { s: "Alien patterns were discovered in the soil.", h: "Look for passive 'were discovered'.", e: "Past passive discovery." },
      { s: "A breach was detected by the internal sensors.", h: "Look for past passive 'was detected'.", e: "Past detection event." },
      { s: "We were given instructions by the fleet commander.", h: "Look for past passive 'were given'.", e: "Completed past instruction delivery." }
    ],
    present: [
      { s: "The capsule is intercepted by pirates currently.", h: "Look for the present passive 'is intercepted' and 'currently'.", e: "Action actively done to the subject now." },
      { s: "Ancient coordinates are carved into the relic.", h: "Look for present passive state 'are carved'.", e: "Refers to a present passive state." },
      { s: "Our thrusters are heavily damaged currently.", h: "Look for present passive 'are damaged'.", e: "Present ongoing state of damage." },
      { s: "A distress code is broadcast at this moment.", h: "Look for passive 'is broadcast' and 'at this moment'.", e: "Active present passive broadcast." },
      { s: "The reactor is shut down by the automation currently.", h: "Look for present passive 'is shut down'.", e: "Refers to active present automation action." },
      { s: "Several stars are swallowed by the black hole currently.", h: "Look for present passive 'are swallowed'.", e: "Ongoing present cosmic event." },
      { s: "The engine is repaired by the droid now.", h: "Look for present passive 'is repaired'.", e: "Active repair in progress." },
      { s: "Alien patterns are discovered in the soil daily.", h: "Look for passive 'are discovered' and 'daily'.", e: "Recurring present passive state." },
      { s: "A breach is detected by the internal sensors now.", h: "Look for present passive 'is detected' and 'now'.", e: "Immediate present passive alert." },
      { s: "We are given instructions by the fleet commander today.", h: "Look for present passive 'are given' and 'today'.", e: "Active instruction delivery in the present." }
    ],
    future: [
      { s: "The capsule will be intercepted by pirates tomorrow.", h: "Look for the future passive 'will be intercepted' and 'tomorrow'.", e: "Action scheduled to be done to the subject later." },
      { s: "Ancient coordinates will be carved into the relic soon.", h: "Look for future passive 'will be carved'.", e: "Predicted future passive state." },
      { s: "Our thrusters will be heavily damaged if we fight.", h: "Look for future passive 'will be damaged'.", e: "Future damage prediction in passive voice." },
      { s: "A distress code will be broadcast tomorrow night.", h: "Look for future passive 'will be broadcast'.", e: "Scheduled future passive broadcast." },
      { s: "The reactor will be shut down by automation soon.", h: "Look for future passive 'will be shut down'.", e: "Anticipated future passive action." },
      { s: "Several stars will be swallowed by the black hole eventually.", h: "Look for future passive 'will be swallowed'.", e: "Predicted future cosmic event." },
      { s: "The engine will be repaired before the jump tomorrow.", h: "Look for future passive 'will be repaired'.", e: "Scheduled future repair." },
      { s: "Alien patterns will be discovered in the soil next year.", h: "Look for future passive 'will be discovered'.", e: "Future passive discovery." },
      { s: "A breach will be detected by internal sensors soon.", h: "Look for future passive 'will be detected'.", e: "Anticipated future passive alert." },
      { s: "We will be given instructions by the fleet commander soon.", h: "Look for future passive 'will be given'.", e: "Scheduled future passive delivery." }
    ]
  },
  {
    name: "Subjunctive Moods & Desires",
    past: [
      { s: "If I were the captain, I would have fled.", h: "Look for subjunctive second conditional past 'were' and 'would have fled'.", e: "Expresses a past counterfactual role and action." },
      { s: "He suggested that the cadet report immediately yesterday.", h: "Look for past suggestion subjunctive 'report' (base verb).", e: "Subjunctive base verb following a past tense demand/suggestion." },
      { s: "It was vital that she remain silent during the raid.", h: "Look for vital past subjunctive 'remain' (not remained).", e: "Subjunctive base verb expressing past cruciality." },
      { s: "I wish the star were stable last cycle.", h: "Look for past wish subjunctive 'were' (not was).", e: "Expresses an imaginary past wish." },
      { s: "She insisted that he leave the outpost yesterday.", h: "Look for past insistence subjunctive 'leave' (not left).", e: "Subjunctive base verb following past insistence." },
      { s: "If the shield were functional, we would have survived.", h: "Look for past counterfactual 'were' and 'would have survived'.", e: "Tense is past subjunctive conditional." },
      { s: "It was recommended that he take the scanner.", h: "Look for past recommendation subjunctive 'take'.", e: "Subjunctive base verb following past recommendation." },
      { s: "He acted as though he were the commander back then.", h: "Look for hypothetical 'as though' and past 'were'.", e: "Hypothetical past subjunctive." },
      { s: "It was crucial that everyone be ready at midnight.", h: "Look for past crucial subjunctive 'be' (not was/were).", e: "Subjunctive base 'be' in the past." },
      { s: "I demanded that she show us the logs yesterday.", h: "Look for past demand subjunctive 'show' (not showed).", e: "Subjunctive base verb following past demand." }
    ],
    present: [
      { s: "If I were the captain, I would flee now.", h: "Look for subjunctive 'were' and present hypothetical 'would flee'.", e: "Expresses a present counterfactual state." },
      { s: "He suggests that the cadet report immediately now.", h: "Look for present suggestion subjunctive 'report' (base verb).", e: "Subjunctive base verb following present suggestion." },
      { s: "It is vital that she remain silent currently.", h: "Look for vital present subjunctive 'remain'.", e: "Subjunctive base verb expressing present urgency." },
      { s: "I wish the star were stable currently.", h: "Look for present wish subjunctive 'were'.", e: "Expresses an active present wish." },
      { s: "She insists that he leave the outpost currently.", h: "Look for present insistence subjunctive 'leave'.", e: "Subjunctive base verb following present active insistence." },
      { s: "If the shield were functional, we would survive now.", h: "Look for present counterfactual 'were' and 'would survive'.", e: "Tense is present subjunctive conditional." },
      { s: "It is recommended that he take the scanner now.", h: "Look for present recommendation subjunctive 'take'.", e: "Subjunctive base verb following present recommendation." },
      { s: "He acts as though he were the commander currently.", h: "Look for hypothetical 'as though' and present 'were'.", e: "Active present subjunctive state." },
      { s: "It is crucial that everyone be ready right now.", h: "Look for present crucial subjunctive 'be'.", e: "Subjunctive base 'be' in the present." },
      { s: "I demand that she show us the logs currently.", h: "Look for present active demand subjunctive 'show'.", e: "Subjunctive base verb following active demand." }
    ],
    future: [
      { s: "If I were the captain, I would flee tomorrow.", h: "Look for subjunctive 'were' and future hypothetical 'would flee'.", e: "Expresses a future counterfactual state." },
      { s: "He will suggest that the cadet report tomorrow.", h: "Look for future suggestion subjunctive 'report' (base verb).", e: "Subjunctive base verb following future suggestion." },
      { s: "It will be vital that she remain silent tomorrow.", h: "Look for vital future subjunctive 'remain'.", e: "Subjunctive base verb expressing future urgency." },
      { s: "I wish the star were stable tomorrow.", h: "Look for future wish subjunctive 'were' with 'tomorrow'.", e: "Expresses a future hypothetical wish." },
      { s: "She will insist that he leave the outpost tomorrow.", h: "Look for future insistence subjunctive 'leave'.", e: "Subjunctive base verb following future insistence." },
      { s: "If the shield were functional, we would survive tomorrow.", h: "Look for future counterfactual 'were' and 'would survive'.", e: "Tense is future subjunctive conditional." },
      { s: "It will be recommended that he take the scanner tomorrow.", h: "Look for future recommendation subjunctive 'take'.", e: "Subjunctive base verb following future recommendation." },
      { s: "He will act as though he were the commander tomorrow.", h: "Look for hypothetical 'as though' and future 'were'.", e: "Predicted future subjunctive state." },
      { s: "It will be crucial that everyone be ready tomorrow.", h: "Look for future crucial subjunctive 'be'.", e: "Subjunctive base 'be' in the future." },
      { s: "I will demand that she show us the logs tomorrow.", h: "Look for future demand subjunctive 'show'.", e: "Subjunctive base verb following future demand." }
    ]
  },
  {
    name: "Scientific Axioms & Universal Laws",
    past: [
      { s: "Astronomers discovered that stars collapsed into black holes.", h: "Look for the past scientific observation 'discovered'.", e: "The past discovery event is complete." },
      { s: "In early models, the planet orbited two suns.", h: "Look for historical models context 'In early models'.", e: "A past conceptual framework." },
      { s: "Gravity accelerated objects downward during the trial.", h: "Look for the past observation context 'during the trial'.", e: "Tense is past." },
      { s: "Light traveled faster in vacuum in previous tests.", h: "Look for the past test context 'in previous tests'.", e: "Completed past experiment." },
      { s: "Hydrogen reacted with oxygen in the laboratory.", h: "Look for the laboratory context in the past.", e: "A completed past reaction." },
      { s: "Magnetism fluctuated near the core yesterday.", h: "Look for the past time tag 'yesterday'.", e: "Tense is simple past." },
      { s: "The galaxy expanded rapidly in the early era.", h: "Look for 'early era' showing past astronomical time.", e: "Past cosmic history." },
      { s: "Energy transformed into matter in the reactor.", h: "Look for past transformation 'transformed'.", e: "Completed past process." },
      { s: "The waves propagated outward during the collision.", h: "Look for past propagation 'propagated'.", e: "Tense is simple past." },
      { s: "Water boiled at low temperatures on the peak.", h: "Look for past observation context 'on the peak'.", e: "Completed past observation." }
    ],
    present: [
      { s: "Astronomers know that stars collapse into black holes.", h: "Describes an active universal law in the present.", e: "Scientific truths are written in the present tense." },
      { s: "In modern models, the planet orbits two suns.", h: "Describes an active present conceptual framework.", e: "Tense is simple present." },
      { s: "Gravity accelerates objects downward constantly.", h: "Describes a constant physical law.", e: "Scientific axiom in the present tense." },
      { s: "Light travels faster in vacuum than in gas.", h: "Describes an unchanging universal truth.", e: "Tense is simple present." },
      { s: "Hydrogen reacts with oxygen to form water.", h: "Describes an unchanging chemical law.", e: "Tense is simple present." },
      { s: "Magnetism fluctuates near the core constantly.", h: "Describes a continuous present physical state.", e: "Tense is simple present." },
      { s: "The galaxy expands rapidly in this era.", h: "Describes active present cosmic expansion.", e: "Tense is simple present." },
      { s: "Energy transforms into matter under high heat.", h: "Describes a physical law in the present.", e: "Tense is simple present." },
      { s: "The waves propagate outward from the center.", h: "Describes active geometric propagation.", e: "Tense is simple present." },
      { s: "Water boils at lower temperatures under vacuum.", h: "Describes a physical law.", e: "Tense is simple present." }
    ],
    future: [
      { s: "Astronomers predict that stars will collapse into black holes.", h: "Look for the future prediction 'will collapse'.", e: "A predicted future scientific event." },
      { s: "In future models, the planet will orbit two suns.", h: "Look for future model context and 'will orbit'.", e: "A predicted future orbital configuration." },
      { s: "Gravity will accelerate objects downward if we drop them.", h: "Look for future condition 'will accelerate'.", e: "Future physical consequence." },
      { s: "Light will travel faster in the new vacuum tubes.", h: "Look for 'will travel' predicting future performance.", e: "Tense is simple future." },
      { s: "Hydrogen will react with oxygen if we heat it.", h: "Look for future reaction prediction 'will react'.", e: "Future chemical reaction." },
      { s: "Magnetism will fluctuate near the core tomorrow.", h: "Look for future prediction 'will fluctuate'.", e: "Tense is simple future." },
      { s: "The galaxy will expand rapidly next eon.", h: "Look for the upcoming time tag 'next eon'.", e: "Future cosmic history prediction." },
      { s: "Energy will transform into matter inside the new device.", h: "Look for future passive 'will transform'.", e: "Predicted future transformation." },
      { s: "The waves will propagate outward once launched.", h: "Look for future condition 'will propagate'.", e: "Tense is simple future." },
      { s: "Water will boil at lower temperatures in the shuttle.", h: "Look for future prediction 'will boil'.", e: "Predicted physical result." }
    ]
  },
  {
    name: "Time-Sensitive Logical Conditions",
    past: [
      { s: "If the beacon flashed, they fled.", h: "Look for past simple conditional 'flashed' and 'fled'.", e: "Tense is simple past conditional." },
      { s: "Provided the gate opened, we entered.", h: "Look for past conditional trigger 'Provided' and past verbs.", e: "Describes a past factual sequence." },
      { s: "If we detected signs, we reported them.", h: "Look for past trigger 'detected' and past result 'reported'.", e: "Past habitual sequence." },
      { s: "Supposing they arrived, did you help them?", h: "Look for past query 'did you help' and past condition.", e: "Tense is simple past query." },
      { s: "Unless the power failed, the server ran.", h: "Look for past conditional 'Unless' + past verbs.", e: "Past continuous reliability." },
      { s: "If they called, I answered.", h: "Look for past conditional 'called' and past reaction 'answered'.", e: "Past standard sequence." },
      { s: "In case the alarm rang, we evacuated.", h: "Look for past precautionary clause 'In case' + past verbs.", e: "Past precautionary action." },
      { s: "If you studied, you passed.", h: "Look for past simple conditional 'studied' and 'passed'.", e: "Tense is simple past." },
      { s: "Assuming she signed, did they accept?", h: "Look for past condition 'signed' and past query 'did they accept'.", e: "Tense is simple past." },
      { s: "Provided the engine started, we launched.", h: "Look for past sequence 'started' and 'launched'.", e: "Tense is simple past." }
    ],
    present: [
      { s: "If the beacon flashes, they flee.", h: "Look for present simple conditional 'flashes' and 'flee'.", e: "Describes a present recurring standard rule." },
      { s: "Provided the gate opens, we enter.", h: "Look for present conditional 'opens' and present 'enter'.", e: "Active present conditional sequence." },
      { s: "If we detect signs, we report them.", h: "Look for present triggers 'detect' and 'report'.", e: "Present standard operating procedure." },
      { s: "Supposing they arrive, do you help them?", h: "Look for present query 'do you help'.", e: "Active present inquiry." },
      { s: "Unless the power fails, the server runs.", h: "Look for present conditional 'fails' and 'runs'.", e: "Present structural state." },
      { s: "If they call, I answer.", h: "Look for present conditional 'call' and present reaction 'answer'.", e: "Present active habit." },
      { s: "In case the alarm rings, we evacuate.", h: "Look for present precaution 'rings' and 'evacuate'.", e: "Present safety protocol." },
      { s: "If you study, you pass.", h: "Look for present simple conditional 'study' and 'pass'.", e: "Present factual truth." },
      { s: "Assuming she signs, do they accept?", h: "Look for present condition 'signs' and present query 'do they accept'.", e: "Active present inquiry." },
      { s: "Provided the engine starts, we launch.", h: "Look for present active sequence 'starts' and 'launch'.", e: "Present operational rule." }
    ],
    future: [
      { s: "If the beacon flashes, they will flee.", h: "Look for future result 'will flee' following present condition.", e: "Future predicted consequence." },
      { s: "Provided the gate opens, we will enter.", h: "Look for future result 'will enter'.", e: "Future planned sequence." },
      { s: "If we detect signs, we will report them.", h: "Look for future result 'will report'.", e: "Future operational promise." },
      { s: "Supposing they arrive, will you help them?", h: "Look for future query 'will you help'.", e: "Inquiry about future intent." },
      { s: "Unless the power fails, the server will run.", h: "Look for future prediction 'will run'.", e: "Future systemic guarantee." },
      { s: "If they call, I will answer.", h: "Look for future commitment 'will answer'.", e: "Future planned action." },
      { s: "In case the alarm rings, we will evacuate.", h: "Look for future precautionary plan 'will evacuate'.", e: "Future planned protocol." },
      { s: "If you study, you will pass.", h: "Look for future prediction 'will pass'.", e: "Future consequence." },
      { s: "Assuming she signs, will they accept?", h: "Look for future query 'will they accept'.", e: "Inquiry about a future result." },
      { s: "Provided the engine starts, we will launch.", h: "Look for future planned action 'will launch'.", e: "Future operational commitment." }
    ]
  },
  {
    name: "Chronological Sequence Markers",
    past: [
      { s: "Previously, the fleet cruised the solar sector.", h: "Look for the past transition marker 'Previously'.", e: "Tense is simple past." },
      { s: "Initially, the core emitted low frequency waves.", h: "Look for the past marker 'Initially'.", e: "Refers to the past baseline of the core." },
      { s: "Earlier, we scanned the spatial coordinate.", h: "Look for past marker 'Earlier'.", e: "The scanning was completed earlier in the past." },
      { s: "Yesterday, the crew detected a gravitational anomaly.", h: "Look for past marker 'Yesterday'.", e: "Completed past detection." },
      { s: "Before, the terminal presented correct logs.", h: "Look for past marker 'Before'.", e: "Refers to a past state." },
      { s: "A moment ago, the droid completed the cycle.", h: "Look for past marker 'A moment ago'.", e: "Tense is simple past." },
      { s: "Last cycle, the shield absorbed high energy.", h: "Look for past cycle reference.", e: "Completed past action." },
      { s: "Once, the sector contained five habitable planets.", h: "Look for past transition marker 'Once'.", e: "Refers to a historical past state." },
      { s: "In ancient cycles, the relay operated perfectly.", h: "Look for past reference 'In ancient cycles'.", e: "Tense is simple past." },
      { s: "Formerly, the pilot served in the federation.", h: "Look for past transition adverb 'Formerly'.", e: "Completed past service." }
    ],
    present: [
      { s: "Currently, the fleet cruises the solar sector.", h: "Look for the present transition marker 'Currently'.", e: "Refers to a present active state." },
      { s: "Currently, the core emits low frequency waves.", h: "Look for the present active adverb 'Currently'.", e: "Refers to the present state of the core." },
      { s: "Right now, we scan the spatial coordinate.", h: "Look for present active marker 'Right now'.", e: "Active present scanning." },
      { s: "Today, the crew detects a gravitational anomaly.", h: "Look for present active marker 'Today'.", e: "Active present detection." },
      { s: "At present, the terminal presents correct logs.", h: "Look for present active marker 'At present'.", e: "Active present presentation." },
      { s: "At this instant, the droid completes the cycle.", h: "Look for present marker 'At this instant'.", e: "Tense is simple present." },
      { s: "In this cycle, the shield absorbs high energy.", h: "Look for 'In this cycle' representing current time.", e: "Active present state." },
      { s: "Currently, the sector contains five habitable planets.", h: "Look for present active marker 'Currently'.", e: "Present active geographical state." },
      { s: "In current cycles, the relay operates perfectly.", h: "Look for present active context 'In current cycles'.", e: "Active present state." },
      { s: "Currently, the pilot serves in the federation.", h: "Look for present active adverb 'Currently'.", e: "Active present service." }
    ],
    future: [
      { s: "Subsequently, the fleet will cruise the solar sector.", h: "Look for the future transition marker 'Subsequently'.", e: "Tense is simple future." },
      { s: "Eventually, the core will emit low frequency waves.", h: "Look for the future marker 'Eventually'.", e: "Predicted future behavior." },
      { s: "Later, we will scan the spatial coordinate.", h: "Look for future marker 'Later'.", e: "Planned future scanning." },
      { s: "Tomorrow, the crew will detect a gravitational anomaly.", h: "Look for future marker 'Tomorrow'.", e: "Anticipated future detection." },
      { s: "Henceforth, the terminal will present correct logs.", h: "Look for future marker 'Henceforth'.", e: "Predicted future state." },
      { s: "In a moment, the droid will complete the cycle.", h: "Look for future marker 'In a moment'.", e: "Tense is simple future." },
      { s: "Next cycle, the shield will absorb high energy.", h: "Look for upcoming cycle reference.", e: "Planned future absorption." },
      { s: "Eventually, the sector will contain five habitable planets.", h: "Look for future transition marker 'Eventually'.", e: "Predicted future state." },
      { s: "In future cycles, the relay will operate perfectly.", h: "Look for future context 'In future cycles'.", e: "Predicted future performance." },
      { s: "Subsequently, the pilot will serve in the federation.", h: "Look for future transition adverb 'Subsequently'.", e: "Future planned service." }
    ]
  },
  {
    name: "Ancient Chronology & Historical Records",
    past: [
      { s: "In the first millennium, explorers charted the rim.", h: "Look for historical past tag 'In the first millennium'.", e: "Charted is completed past action." },
      { s: "During the ancient war, they constructed the wall.", h: "Look for historical context 'During the ancient war'.", e: "Past historical construction." },
      { s: "Ancient civilizations developed the gateway tech.", h: "Look for historical subject 'Ancient civilizations'.", e: "Tense is simple past." },
      { s: "In early history, a comet struck the planet.", h: "Look for past astronomical historical marker.", e: "Completed past event." },
      { s: "Decades ago, the mainframe operated offline.", h: "Look for past duration 'Decades ago'.", e: "Refers to past operations." },
      { s: "Centuries ago, the empire dissolved into factions.", h: "Look for past context 'Centuries ago'.", e: "Completed past dissolution." },
      { s: "In previous eras, the sun burned brighter.", h: "Look for past context 'In previous eras'.", e: "Tense is simple past." },
      { s: "The first builders designed the base layout.", h: "Look for historical subject 'first builders'.", e: "Completed historical design." },
      { s: "In archaic cycles, they utilized analog signals.", h: "Look for past marker 'archaic cycles'.", e: "Completed past utilization." },
      { s: "Long ago, the species abandoned the homeworld.", h: "Look for past marker 'Long ago'.", e: "Completed past migration." }
    ],
    present: [
      { s: "In this millennium, explorers chart the rim.", h: "Look for present active context 'In this millennium'.", e: "Chart is active present action." },
      { s: "In this peace era, they construct the wall.", h: "Look for present active context 'In this peace era'.", e: "Active present construction." },
      { s: "Modern civilizations develop the gateway tech currently.", h: "Look for active present subject 'Modern civilizations'.", e: "Tense is simple present." },
      { s: "In modern history, a comet strikes the planet rarely.", h: "Look for present frequency marker 'rarely'.", e: "Present recurring event." },
      { s: "Currently, the mainframe operates offline.", h: "Look for active present adverb 'Currently'.", e: "Active present operations." },
      { s: "Currently, the empire dissolves into factions.", h: "Look for active present adverb 'Currently'.", e: "Active present dissolution." },
      { s: "In these eras, the sun burns brighter.", h: "Look for present active context 'In these eras'.", e: "Tense is simple present." },
      { s: "The current builders design the base layout now.", h: "Look for active present subject 'current builders'.", e: "Active present design." },
      { s: "In modern cycles, they utilize analog signals currently.", h: "Look for active present marker 'modern cycles'.", e: "Active present utilization." },
      { s: "Currently, the species abandons the homeworld.", h: "Look for present active adverb 'Currently'.", e: "Active present migration." }
    ],
    future: [
      { s: "In the next millennium, explorers will chart the rim.", h: "Look for future time tag 'In the next millennium'.", e: "will chart is simple future." },
      { s: "During the upcoming war, they will construct the wall.", h: "Look for future context 'During the upcoming war'.", e: "Future planned construction." },
      { s: "Future civilizations will develop the gateway tech.", h: "Look for future subject 'Future civilizations'.", e: "Tense is simple future." },
      { s: "In future history, a comet will strike the planet eventually.", h: "Look for upcoming astronomical event prediction.", e: "Predicted future event." },
      { s: "Decades from now, the mainframe will operate offline.", h: "Look for future duration 'Decades from now'.", e: "Refers to future operations." },
      { s: "Centuries from now, the empire will dissolve into factions.", h: "Look for future context 'Centuries from now'.", e: "Predicted future dissolution." },
      { s: "In upcoming eras, the sun will burn brighter.", h: "Look for future context 'In upcoming eras'.", e: "Tense is simple future." },
      { s: "The next builders will design the base layout soon.", h: "Look for future subject 'next builders'.", e: "Future planned design." },
      { s: "In future cycles, they will utilize analog signals.", h: "Look for future marker 'future cycles'.", e: "Future planned utilization." },
      { s: "Eventually, the species will abandon the homeworld.", h: "Look for future marker 'Eventually'.", e: "Predicted future migration." }
    ]
  },
  {
    name: "Rapid Event Sequences",
    past: [
      { s: "No sooner had the alarm sounded than they left.", h: "Look for past perfect inversion 'had the alarm sounded'.", e: "Completed rapid past sequence." },
      { s: "Hardly had the launch initialized when it failed.", h: "Look for past inversion 'Hardly had... initialized'.", e: "Rapid past interruption." },
      { s: "We had just finished when the core exploded.", h: "Look for past perfect 'had just finished'.", e: "Completed action immediately followed by another past event." },
      { s: "They had scarcely entered before the roof fell.", h: "Look for past inversion 'had scarcely entered'.", e: "Past continuous sequence interrupted." },
      { s: "The signal had barely arrived when we lost power.", h: "Look for past perfect 'had barely arrived'.", e: "Rapid past sequence." },
      { s: "I had only just arrived when you called.", h: "Look for past perfect 'had only just arrived'.", e: "Tense is past perfect." },
      { s: "We had no sooner logged in than we were disconnected.", h: "Look for past perfect sequence 'had no sooner logged'.", e: "Tense is past perfect." },
      { s: "She had hardly started when the transmission broke.", h: "Look for past perfect 'had hardly started'.", e: "Tense is past perfect." },
      { s: "They had scarcely jumped before they detected threat.", h: "Look for past perfect 'had scarcely jumped'.", e: "Tense is past perfect." },
      { s: "The capsule had barely landed when it burst.", h: "Look for past perfect 'had barely landed'.", e: "Tense is past perfect." }
    ],
    present: [
      { s: "No sooner does the alarm sound than they leave.", h: "Look for present inversion structure 'does the alarm sound'.", e: "Describes a present rapid sequence habit." },
      { s: "Hardly does the launch initialize when it fails.", h: "Look for present inversion 'Hardly does...'.", e: "Describes a regular rapid present failure." },
      { s: "We just finish when the core explodes daily.", h: "Look for simple present 'finish' and 'explodes'.", e: "Standard present recurring sequence." },
      { s: "They scarcely enter before the roof falls.", h: "Look for present verbs 'enter' and 'falls'.", e: "Active present sequence." },
      { s: "The signal barely arrives when we lose power.", h: "Look for present verbs 'arrives' and 'lose'.", e: "Regular present sequential failure." },
      { s: "I only just arrive when you call.", h: "Look for present verbs 'arrive' and 'call'.", e: "Tense is simple present." },
      { s: "We no sooner log in than we are disconnected.", h: "Look for present sequence 'no sooner log... than'.", e: "Tense is simple present." },
      { s: "She hardly starts when the transmission breaks.", h: "Look for present sequence 'hardly starts... when'.", e: "Tense is simple present." },
      { s: "They scarcely jump before they detect threat.", h: "Look for present sequence 'scarcely jump... before'.", e: "Tense is simple present." },
      { s: "The capsule barely lands when it bursts.", h: "Look for present sequence 'barely lands... when'.", e: "Tense is simple present." }
    ],
    future: [
      { s: "No sooner will the alarm sound than they will leave.", h: "Look for future inversion structure 'will the alarm sound'.", e: "Predicted future rapid sequence." },
      { s: "Hardly will the launch initialize when it will fail.", h: "Look for future inversion 'Hardly will...'.", e: "Predicted rapid future failure." },
      { s: "We will just finish when the core will explode.", h: "Look for future sequence 'will just finish... will explode'.", e: "Predicted future sequence." },
      { s: "They will scarcely enter before the roof will fall.", h: "Look for future verbs 'will enter' and 'will fall'.", e: "Anticipated future sequence." },
      { s: "The signal will barely arrive when we will lose power.", h: "Look for future verbs 'will arrive' and 'will lose'.", e: "Predicted future sequence." },
      { s: "I will only just arrive when you will call.", h: "Look for future sequence 'will arrive... will call'.", e: "Tense is simple future." },
      { s: "We will no sooner log in than we will be disconnected.", h: "Look for future sequence 'will no sooner log...'.", e: "Tense is simple future." },
      { s: "She will hardly start when the transmission will break.", h: "Look for future sequence 'will hardly start...'.", e: "Tense is simple future." },
      { s: "They will scarcely jump before they will detect threat.", h: "Look for future sequence 'will scarcely jump...'.", e: "Tense is simple future." },
      { s: "The capsule will barely land when it will burst.", h: "Look for future sequence 'will barely land...'.", e: "Tense is simple future." }
    ]
  },
  {
    name: "Sensory Observations & Audits",
    past: [
      { s: "The crew heard a strange hum yesterday.", h: "Look for past verb 'heard' and 'yesterday'.", e: "Completed past auditory observation." },
      { s: "I smelled ozone in the server room last night.", h: "Look for past verb 'smelled' and 'last night'.", e: "Completed past olfactory observation." },
      { s: "The pilot saw warning lights on the panel.", h: "Look for past verb 'saw' and past context.", e: "Completed past visual observation." },
      { s: "The computer registered high ambient temperature.", h: "Look for past verb 'registered'.", e: "Completed past mechanical audit." },
      { s: "We noticed anomalous patterns during the flight.", h: "Look for past verb 'noticed' and 'during the flight'.", e: "Completed past observation." },
      { s: "She perceived a drop in pressure earlier.", h: "Look for past verb 'perceived' and 'earlier'.", e: "Completed past sensory assessment." },
      { s: "The sensors detected cosmic dust in sector four.", h: "Look for past verb 'detected' and past sector.", e: "Completed past detection." },
      { s: "They felt the ground shake during the quake.", h: "Look for past verb 'felt' and 'during the quake'.", e: "Completed past physical sensation." },
      { s: "The scanner identified three energy signatures.", h: "Look for past verb 'identified'.", e: "Completed past identification." },
      { s: "We witnessed the system initialization yesterday.", h: "Look for past verb 'witnessed' and 'yesterday'.", e: "Completed past observation." }
    ],
    present: [
      { s: "The crew hears a strange hum currently.", h: "Look for present verb 'hears' and 'currently'.", e: "Active present auditory observation." },
      { s: "I smell ozone in the server room currently.", h: "Look for present verb 'smell' and 'currently'.", e: "Active present olfactory observation." },
      { s: "The pilot sees warning lights on the panel.", h: "Look for present verb 'sees' showing active observation.", e: "Active present visual observation." },
      { s: "The computer registers high ambient temperature.", h: "Look for present verb 'registers'.", e: "Active present mechanical audit." },
      { s: "We notice anomalous patterns currently.", h: "Look for present verb 'notice' and 'currently'.", e: "Active present observation." },
      { s: "She perceives a drop in pressure currently.", h: "Look for present verb 'perceives' and 'currently'.", e: "Active present sensory assessment." },
      { s: "The sensors detect cosmic dust in sector four.", h: "Look for present verb 'detect' showing active observation.", e: "Active present detection." },
      { s: "They feel the ground shake currently.", h: "Look for present verb 'feel' and 'currently'.", e: "Active present physical sensation." },
      { s: "The scanner identifies three energy signatures.", h: "Look for present verb 'identifies'.", e: "Active present identification." },
      { s: "We witness the system initialization currently.", h: "Look for present verb 'witness' and 'currently'.", e: "Active present observation." }
    ],
    future: [
      { s: "The crew will hear a strange hum tomorrow.", h: "Look for future verb 'will hear' and 'tomorrow'.", e: "Anticipated future auditory observation." },
      { s: "I will smell ozone in the server room tomorrow.", h: "Look for future verb 'will smell' and 'tomorrow'.", e: "Anticipated future olfactory observation." },
      { s: "The pilot will see warning lights on the panel.", h: "Look for future verb 'will see' showing future prediction.", e: "Anticipated future visual observation." },
      { s: "The computer will register high ambient temperature.", h: "Look for future verb 'will register'.", e: "Anticipated future mechanical audit." },
      { s: "We will notice anomalous patterns tomorrow.", h: "Look for future verb 'will notice' and 'tomorrow'.", e: "Anticipated future observation." },
      { s: "She will perceive a drop in pressure tomorrow.", h: "Look for future verb 'will perceive' and 'tomorrow'.", e: "Anticipated future sensory assessment." },
      { s: "The sensors will detect cosmic dust in sector four.", h: "Look for future verb 'will detect' showing future prediction.", e: "Anticipated future detection." },
      { s: "They will feel the ground shake tomorrow.", h: "Look for future verb 'will feel' and 'tomorrow'.", e: "Anticipated future physical sensation." },
      { s: "The scanner will identify three energy signatures.", h: "Look for future verb 'will identify'.", e: "Anticipated future identification." },
      { s: "We will witness the system initialization tomorrow.", h: "Look for future verb 'will witness' and 'tomorrow'.", e: "Anticipated future observation." }
    ]
  },
  {
    name: "Tech Upgrades & Diagnostics",
    past: [
      { s: "We upgraded the cooling system yesterday.", h: "Look for past verb 'upgraded' and 'yesterday'.", e: "Completed past technical upgrade." },
      { s: "The technician replaced the main relay last cycle.", h: "Look for past verb 'replaced' and 'last cycle'.", e: "Completed past maintenance." },
      { s: "They patched the software firewall last night.", h: "Look for past verb 'patched' and 'last night'.", e: "Completed past patch." },
      { s: "The diagnostic revealed two bad circuits.", h: "Look for past verb 'revealed'.", e: "Completed past diagnostic." },
      { s: "We optimized the thrust vectors yesterday.", h: "Look for past verb 'optimized' and 'yesterday'.", e: "Completed past optimization." },
      { s: "She recalibrated the sensor grid last hour.", h: "Look for past verb 'recalibrated' and 'last hour'.", e: "Completed past calibration." },
      { s: "The team clean-installed the operating system.", h: "Look for past verb 'clean-installed'.", e: "Completed past installation." },
      { s: "We bypassed the broken junction yesterday.", h: "Look for past verb 'bypassed' and 'yesterday'.", e: "Completed past routing bypass." },
      { s: "The crew repaired the reactor cooling system.", h: "Look for past verb 'repaired'.", e: "Completed past repair." },
      { s: "They executed the diagnostic script yesterday.", h: "Look for past verb 'executed' and 'yesterday'.", e: "Completed past command execution." }
    ],
    present: [
      { s: "We upgrade the cooling system currently.", h: "Look for present verb 'upgrade' and 'currently'.", e: "Active present technical upgrade." },
      { s: "The technician replaces the main relay currently.", h: "Look for present verb 'replaces' and 'currently'.", e: "Active present maintenance." },
      { s: "They patch the software firewall currently.", h: "Look for present verb 'patch' and 'currently'.", e: "Active present patch." },
      { s: "The diagnostic reveals two bad circuits.", h: "Look for present verb 'reveals'.", e: "Active present diagnostic." },
      { s: "We optimize the thrust vectors currently.", h: "Look for present verb 'optimize' and 'currently'.", e: "Active present optimization." },
      { s: "She recalibrates the sensor grid currently.", h: "Look for present verb 'recalibrates' and 'currently'.", e: "Active present calibration." },
      { s: "The team clean-installs the operating system.", h: "Look for present verb 'clean-installs'.", e: "Active present installation." },
      { s: "We bypass the broken junction currently.", h: "Look for present verb 'bypass' and 'currently'.", e: "Active present routing bypass." },
      { s: "The crew repairs the reactor cooling system.", h: "Look for present verb 'repairs'.", e: "Active present repair." },
      { s: "They execute the diagnostic script currently.", h: "Look for present verb 'execute' and 'currently'.", e: "Active present command execution." }
    ],
    future: [
      { s: "We will upgrade the cooling system tomorrow.", h: "Look for future verb 'will upgrade' and 'tomorrow'.", e: "Anticipated future technical upgrade." },
      { s: "The technician will replace the main relay tomorrow.", h: "Look for future verb 'will replace' and 'tomorrow'.", e: "Anticipated future maintenance." },
      { s: "They will patch the software firewall tomorrow.", h: "Look for future verb 'will patch' and 'tomorrow'.", e: "Anticipated future patch." },
      { s: "The diagnostic will reveal two bad circuits.", h: "Look for future verb 'will reveal'.", e: "Anticipated future diagnostic." },
      { s: "We will optimize the thrust vectors tomorrow.", h: "Look for future verb 'will optimize' and 'tomorrow'.", e: "Anticipated future optimization." },
      { s: "She will recalibrate the sensor grid tomorrow.", h: "Look for future verb 'will recalibrate' and 'tomorrow'.", e: "Anticipated future calibration." },
      { s: "The team will clean-install the operating system.", h: "Look for future verb 'will clean-install'.", e: "Anticipated future installation." },
      { s: "We will bypass the broken junction tomorrow.", h: "Look for future verb 'will bypass' and 'tomorrow'.", e: "Anticipated future routing bypass." },
      { s: "The crew will repair the reactor cooling system.", h: "Look for future verb 'will repair'.", e: "Anticipated future repair." },
      { s: "They will execute the diagnostic script tomorrow.", h: "Look for future verb 'will execute' and 'tomorrow'.", e: "Anticipated future command execution." }
    ]
  },
  {
    name: "Spatial Coordinates & Navigation",
    past: [
      { s: "We entered the wormhole coordinate yesterday.", h: "Look for past verb 'entered' and 'yesterday'.", e: "Completed past transit." },
      { s: "The pilot navigated the asteroid field yesterday.", h: "Look for past verb 'navigated' and 'yesterday'.", e: "Completed past navigation." },
      { s: "They crossed the galactic equator last cycle.", h: "Look for past verb 'crossed' and 'last cycle'.", e: "Completed past boundary crossing." },
      { s: "The shuttle cleared the atmosphere yesterday.", h: "Look for past verb 'cleared' and 'yesterday'.", e: "Completed past atmosphere clearance." },
      { s: "We established orbit around the gas giant.", h: "Look for past verb 'established'.", e: "Completed past orbital insertion." },
      { s: "She mapped the coordinates of the sector.", h: "Look for past verb 'mapped'.", e: "Completed past spatial mapping." },
      { s: "The probe bypassed the security grid.", h: "Look for past verb 'bypassed'.", e: "Completed past navigation bypass." },
      { s: "We orbited the primary star last cycle.", h: "Look for past verb 'orbited' and 'last cycle'.", e: "Completed past orbit." },
      { s: "They landed the vessel safely yesterday.", h: "Look for past verb 'landed' and 'yesterday'.", e: "Completed past landing." },
      { s: "The pilot executed a high-G maneuver.", h: "Look for past verb 'executed'.", e: "Completed past pilot maneuver." }
    ],
    present: [
      { s: "We enter the wormhole coordinate currently.", h: "Look for present verb 'enter' and 'currently'.", e: "Active present transit." },
      { s: "The pilot navigates the asteroid field currently.", h: "Look for present verb 'navigates' and 'currently'.", e: "Active present navigation." },
      { s: "They cross the galactic equator currently.", h: "Look for present verb 'cross' and 'currently'.", e: "Active present boundary crossing." },
      { s: "The shuttle clears the atmosphere currently.", h: "Look for present verb 'clears' and 'currently'.", e: "Active present atmosphere clearance." },
      { s: "We establish orbit around the gas giant.", h: "Look for present verb 'establish'.", e: "Active present orbital insertion." },
      { s: "She maps the coordinates of the sector.", h: "Look for present verb 'maps'.", e: "Active present spatial mapping." },
      { s: "The probe bypasses the security grid.", h: "Look for present verb 'bypasses'.", e: "Active present navigation bypass." },
      { s: "We orbit the primary star currently.", h: "Look for present verb 'orbit' and 'currently'.", e: "Active present orbit." },
      { s: "They land the vessel safely currently.", h: "Look for present verb 'land' and 'currently'.", e: "Active present landing." },
      { s: "The pilot executes a high-G maneuver.", h: "Look for present verb 'executes'.", e: "Active present pilot maneuver." }
    ],
    future: [
      { s: "We will enter the wormhole coordinate tomorrow.", h: "Look for future verb 'will enter' and 'tomorrow'.", e: "Anticipated future transit." },
      { s: "The pilot will navigate the asteroid field tomorrow.", h: "Look for future verb 'will navigate' and 'tomorrow'.", e: "Anticipated future navigation." },
      { s: "They will cross the galactic equator tomorrow.", h: "Look for future verb 'will cross' and 'tomorrow'.", e: "Anticipated future boundary crossing." },
      { s: "The shuttle will clear the atmosphere tomorrow.", h: "Look for future verb 'will clear' and 'tomorrow'.", e: "Anticipated future atmosphere clearance." },
      { s: "We will establish orbit around the gas giant.", h: "Look for future verb 'will establish'.", e: "Anticipated future orbital insertion." },
      { s: "She will map the coordinates of the sector.", h: "Look for future verb 'will map'.", e: "Anticipated future spatial mapping." },
      { s: "The probe will bypass the security grid.", h: "Look for future verb 'will bypass'.", e: "Anticipated future navigation bypass." },
      { s: "We will orbit the primary star tomorrow.", h: "Look for future verb 'will orbit' and 'tomorrow'.", e: "Anticipated future orbit." },
      { s: "They will land the vessel safely tomorrow.", h: "Look for future verb 'will land' and 'tomorrow'.", e: "Anticipated future landing." },
      { s: "The pilot will execute a high-G maneuver.", h: "Look for future verb 'will execute'.", e: "Anticipated future pilot maneuver." }
    ]
  },
  {
    name: "Command Directives & Operations",
    past: [
      { s: "The commander authorized the security purge yesterday.", h: "Look for past verb 'authorized' and 'yesterday'.", e: "Completed past authorization." },
      { s: "We initialized the quarantine protocol yesterday.", h: "Look for past verb 'initialized' and 'yesterday'.", e: "Completed past protocol launch." },
      { s: "They triggered the self-destruct cycle yesterday.", h: "Look for past verb 'triggered' and 'yesterday'.", e: "Completed past trigger." },
      { s: "The system locked the target coordinate yesterday.", h: "Look for past verb 'locked' and 'yesterday'.", e: "Completed past target lock." },
      { s: "We override the security clearance yesterday.", h: "Look for past verb 'override' and 'yesterday' (read as past override).", e: "Completed past bypass." },
      { s: "She terminated the data stream yesterday.", h: "Look for past verb 'terminated' and 'yesterday'.", e: "Completed past termination." },
      { s: "The fleet deployed three cruisers yesterday.", h: "Look for past verb 'deployed' and 'yesterday'.", e: "Completed past fleet deployment." },
      { s: "We evacuated the lower hangar yesterday.", h: "Look for past verb 'evacuated' and 'yesterday'.", e: "Completed past evacuation." },
      { s: "They disabled the alarm grid yesterday.", h: "Look for past verb 'disabled' and 'yesterday'.", e: "Completed past disable command." },
      { s: "The system generated a status report yesterday.", h: "Look for past verb 'generated' and 'yesterday'.", e: "Completed past report generation." }
    ],
    present: [
      { s: "The commander authorizes the security purge currently.", h: "Look for present verb 'authorizes' and 'currently'.", e: "Active present authorization." },
      { s: "We initialize the quarantine protocol currently.", h: "Look for present verb 'initialize' and 'currently'.", e: "Active present protocol launch." },
      { s: "They trigger the self-destruct cycle currently.", h: "Look for present verb 'trigger' and 'currently'.", e: "Active present trigger." },
      { s: "The system locks the target coordinate currently.", h: "Look for present verb 'locks' and 'currently'.", e: "Active present target lock." },
      { s: "We override the security clearance currently.", h: "Look for present verb 'override' and 'currently'.", e: "Active present bypass." },
      { s: "She terminates the data stream currently.", h: "Look for present verb 'terminates' and 'currently'.", e: "Active present termination." },
      { s: "The fleet deploys three cruisers currently.", h: "Look for present verb 'deploys' and 'currently'.", e: "Active present fleet deployment." },
      { s: "We evacuate the lower hangar currently.", h: "Look for present verb 'evacuate' and 'currently'.", e: "Active present evacuation." },
      { s: "They disable the alarm grid currently.", h: "Look for present verb 'disable' and 'currently'.", e: "Active present disable command." },
      { s: "The system generates a status report currently.", h: "Look for present verb 'generates' and 'currently'.", e: "Active present report generation." }
    ],
    future: [
      { s: "The commander will authorize the security purge tomorrow.", h: "Look for future verb 'will authorize' and 'tomorrow'.", e: "Anticipated future authorization." },
      { s: "We will initialize the quarantine protocol tomorrow.", h: "Look for future verb 'will initialize' and 'tomorrow'.", e: "Anticipated future protocol launch." },
      { s: "They will trigger the self-destruct cycle tomorrow.", h: "Look for future verb 'will trigger' and 'tomorrow'.", e: "Anticipated future trigger." },
      { s: "The system will lock the target coordinate tomorrow.", h: "Look for future verb 'will lock' and 'tomorrow'.", e: "Anticipated future target lock." },
      { s: "We will override the security clearance tomorrow.", h: "Look for future verb 'will override' and 'tomorrow'.", e: "Anticipated future bypass." },
      { s: "She will terminate the data stream tomorrow.", h: "Look for future verb 'will terminate' and 'tomorrow'.", e: "Anticipated future termination." },
      { s: "The fleet will deploy three cruisers tomorrow.", h: "Look for future verb 'will deploy' and 'tomorrow'.", e: "Anticipated future fleet deployment." },
      { s: "We will evacuate the lower hangar tomorrow.", h: "Look for future verb 'will evacuate' and 'tomorrow'.", e: "Anticipated future evacuation." },
      { s: "They will disable the alarm grid tomorrow.", h: "Look for future verb 'will disable' and 'tomorrow'.", e: "Anticipated future disable command." },
      { s: "The system will generates a status report tomorrow.", h: "Look for future verb 'will generates' (will generate) and 'tomorrow'.", e: "Anticipated future report generation." }
    ]
  },
  {
    name: "Complex Temporal Shifts & Syntheses",
    past: [
      { s: "We had completed the synthesis before the backup arrived.", h: "Look for past perfect 'had completed'.", e: "Action completed prior to another past milestone." },
      { s: "They had analyzed the samples before the grid failed.", h: "Look for past perfect 'had analyzed'.", e: "Completed action prior to systemic failure in the past." },
      { s: "She had bypassed the security before she was caught.", h: "Look for past perfect 'had bypassed'.", e: "Completed action before a past arrest." },
      { s: "We had decrypted the file prior to the lockout.", h: "Look for past perfect 'had decrypted'.", e: "Decryption completed before past lockout." },
      { s: "I had sent the notification before the crash.", h: "Look for past perfect 'had sent'.", e: "Sending completed before past system crash." },
      { s: "They had secured the hangar before they launched.", h: "Look for past perfect 'had secured'.", e: "Securing was complete prior to past launch." },
      { s: "We had resolved the issue before the client called.", h: "Look for past perfect 'had resolved'.", e: "Issue solved before past call." },
      { s: "She had mapped the quadrant before the sensor died.", h: "Look for past perfect 'had mapped'.", e: "Quadrant mapped before past sensor death." },
      { s: "The probe had entered deep space before we lost it.", h: "Look for past perfect 'had entered'.", e: "Probe entered deep space before past signal loss." },
      { s: "We had optimized the engine before the jump.", h: "Look for past perfect 'had optimized'.", e: "Optimization complete before past jump." }
    ],
    present: [
      { s: "We have completed the synthesis currently.", h: "Look for present perfect 'have completed' and 'currently'.", e: "Synthesis completed with current active status." },
      { s: "They have analyzed the samples currently.", h: "Look for present perfect 'have analyzed'.", e: "Completed action in the present." },
      { s: "She has bypassed the security currently.", h: "Look for present perfect 'has bypassed'.", e: "Security is currently bypassed." },
      { s: "We have decrypted the file currently.", h: "Look for present perfect 'have decrypted'.", e: "File is currently decrypted." },
      { s: "I have sent the notification currently.", h: "Look for present perfect 'have sent'.", e: "Notification is currently sent." },
      { s: "They have secured the hangar currently.", h: "Look for present perfect 'have secured'.", e: "Hangar is currently secured." },
      { s: "We have resolved the issue currently.", h: "Look for present perfect 'have resolved'.", e: "Issue is currently resolved." },
      { s: "She has mapped the quadrant currently.", h: "Look for present perfect 'has mapped'.", e: "Quadrant is currently mapped." },
      { s: "The probe has entered deep space currently.", h: "Look for present perfect 'has entered'.", e: "Probe is currently in deep space." },
      { s: "We have optimized the engine currently.", h: "Look for present perfect 'have optimized'.", e: "Engine is currently optimized." }
    ],
    future: [
      { s: "We will have completed the synthesis by tomorrow.", h: "Look for future perfect 'will have completed' and 'by tomorrow'.", e: "Synthesis will be complete by a future target time." },
      { s: "They will have analyzed the samples by tomorrow.", h: "Look for future perfect 'will have analyzed'.", e: "Future completed analysis." },
      { s: "She will have bypassed the security by tomorrow.", h: "Look for future perfect 'will have bypassed'.", e: "Future completed bypass." },
      { s: "We will have decrypted the file by tomorrow.", h: "Look for future perfect 'will have decrypted'.", e: "Future completed decryption." },
      { s: "I will have sent the notification by tomorrow.", h: "Look for future perfect 'will have sent'.", e: "Future completed notification." },
      { s: "They will have secured the hangar by tomorrow.", h: "Look for future perfect 'will have secured'.", e: "Future completed security." },
      { s: "We will have resolved the issue by tomorrow.", h: "Look for future perfect 'will have resolved'.", e: "Future completed resolution." },
      { s: "She will have mapped the quadrant by tomorrow.", h: "Look for future perfect 'will have mapped'.", e: "Future completed mapping." },
      { s: "The probe will have entered deep space by tomorrow.", h: "Look for future perfect 'will have entered'.", e: "Future completed entry." },
      { s: "We will have optimized the engine by tomorrow.", h: "Look for future perfect 'will have optimized'.", e: "Future completed optimization." }
    ]
  }
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
  const fileName = `tenseMastery_${startLevel}_${endLevel}.json`;
  const filePath = path.join(basePath, fileName);
  
  // Topic is selected deterministically based on batch index
  const topic = topics[batch % topics.length];
  const quests = [];
  
  for (let level = startLevel; level <= endLevel; level++) {
    const diff = getDifficulty(level);
    
    // Level is composed of 3 questions:
    // q1: Past
    // q2: Present
    // q3: Future
    const tensesOrder = ["Past", "Present", "Future"];
    
    for (let qNum = 1; qNum <= 3; qNum++) {
      const tense = tensesOrder[qNum - 1];
      
      // Select index deterministically within the 10 available templates
      const index = (level - startLevel) % 10;
      
      let item;
      if (tense === "Past") {
        item = topic.past[index];
      } else if (tense === "Present") {
        item = topic.present[index];
      } else {
        item = topic.future[index];
      }
      
      quests.push({
        id: `tm_l${level}_q${qNum}`,
        instruction: "MAP THE TIMELINE",
        difficulty: diff,
        subtype: "tenseMastery",
        interactionType: "Timeline Slider",
        sentence: item.s,
        correctAnswer: tense,
        correctAnswerCategory: tense,
        hint: item.h,
        explanation: item.e
      });
    }
  }
  
  const fileData = {
    gameType: "tenseMastery",
    batchIndex: batch + 1,
    levels: `${startLevel}-${endLevel}`,
    quests: quests
  };
  
  fs.writeFileSync(filePath, JSON.stringify(fileData, null, 2));
  console.log(`Generated and purified ${fileName}`);
}

console.log("Successfully generated all 600 unique tenseMastery quests across 20 batch files.");
