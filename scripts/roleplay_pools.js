/**
 * Roleplay Content Pools for VoxAI Quest
 * Each entry is a high-quality, non-placeholder roleplay scenario.
 */

const branchingDialogue = [
  {
    scene: "Artificial Intelligence Ethics",
    instruction: "Discuss the implications of AI development with a tech skeptic.",
    speaker: "Skeptic ({{name}})",
    startText: "I'm worried that AI like {{business}} will eventually replace human creativity. Don't you think we're losing our soul?",
    choices: [
      { text: "AI is a tool to amplify creativity, not replace it.", next: "amplify" },
      { text: "Technology has always changed how we create; this is just the next step.", next: "evolution" }
    ],
    nodes: {
      amplify: {
        text: "But if an AI in {{location}} can paint better than a person, why would anyone learn to paint?",
        choices: [
          { text: "Because the process of creation is human, regardless of the output.", next: "end_success" },
          { text: "AI can handle the technical work, allowing humans to focus on the concept.", next: "end_success" }
        ]
      },
      evolution: {
        text: "True, but the speed of this {{item}} revolution is unprecedented. Are we ready?",
        choices: [
          { text: "We must adapt our educational systems in {{location}} to match this pace.", next: "end_success" }
        ]
      },
      end_success: { text: "That's a fair point. It's a complex conversation for our {{time}} session.", end: true }
    }
  },
  {
    scene: "Salary Negotiation: High Stakes",
    instruction: "Negotiate your compensation for the new {{item}} project.",
    speaker: "HR Director ({{name}})",
    startText: "We're very impressed with your work at {{business}}. We'd like to offer you the Lead role in {{location}}, but our budget is firm.",
    choices: [
      { text: "I appreciate the offer, but my research shows the market rate for {{item}} leads is higher.", next: "market_rate" },
      { text: "If the base salary is fixed, can we discuss performance bonuses for the {{time}}?", next: "bonuses" }
    ],
    nodes: {
      market_rate: {
        text: "The {{location}} market is indeed competitive. What figure did you have in mind?",
        choices: [
          { text: "I'm looking for a 15% increase over the current offer.", next: "end_success" }
        ]
      },
      bonuses: {
        text: "That's a possibility. We could tie it to the {{business}} quarterly targets.",
        choices: [
          { text: "That sounds fair. Let's draft the metrics for the next {{item}} launch.", next: "end_success" }
        ]
      },
      end_success: { text: "Agreed. I'll send the updated contract by {{time}}.", end: true }
    }
  },
  {
    scene: "Project Post-Mortem",
    instruction: "Address a failed product launch with your team lead.",
    speaker: "Team Lead ({{name}})",
    startText: "The {{item}} launch in {{location}} was a disaster. The customers at {{business}} are furious. What went wrong?",
    choices: [
      { text: "We rushed the QA process to meet the {{time}} deadline.", next: "qa_failure" },
      { text: "The communication between the {{location}} and HQ teams broke down.", next: "comm_breakdown" }
    ],
    nodes: {
      qa_failure: {
        text: "Why wasn't I informed that the {{item}} wasn't ready?",
        choices: [
          { text: "I took a risk and I take full responsibility for the oversight.", next: "end_accountable" }
        ]
      },
      comm_breakdown: {
        text: "We need a new protocol. How do we ensure this doesn't happen at {{business}} again?",
        choices: [
          { text: "We should implement weekly syncs for every {{item}} milestone.", next: "end_success" }
        ]
      },
      end_accountable: { text: "I appreciate the honesty. Let's fix the {{item}} today.", end: true },
      end_success: { text: "Let's start that protocol immediately this {{time}}.", end: true }
    }
  },
  {
    scene: "Investors Coffee",
    instruction: "Pitch your vision to a potential seed investor.",
    speaker: "Investor ({{name}})",
    startText: "I've seen many {{item}} startups in {{location}}. What makes {{business}} different?",
    choices: [
      { text: "Our proprietary algorithm reduces latency by 40%.", next: "latency" },
      { text: "We have exclusive partnerships with the biggest firms in {{location}}.", next: "partnerships" }
    ],
    nodes: {
      latency: { text: "Technical edge is good. How do you plan to monetize this {{time}}?", choices: [{ text: "A subscription model for enterprise clients.", next: "end_success" }], end: false },
      partnerships: { text: "Partnerships are key. Can you name one major partner at {{business}}?", choices: [{ text: "We're currently in final talks with the Global Tech Group.", next: "end_success" }], end: false },
      end_success: { text: "Let's keep this conversation going. Send me your deck this {{time}}.", end: true }
    }
  },
  {
    scene: "Crisis Management: Data Breach",
    instruction: "Respond to a journalist about a security breach at {{business}}.",
    speaker: "Journalist ({{name}})",
    startText: "Sources say that the {{item}} data in {{location}} was compromised. What is your official statement?",
    choices: [
      { text: "We are investigating a potential anomaly and prioritizing user safety.", next: "investigation" },
      { text: "The breach was minor and only affected 0.1% of our {{location}} users.", next: "minimizing" }
    ],
    nodes: {
      investigation: { text: "Will you compensate the users in {{location}} for the breach?", choices: [{ text: "We will provide free identity protection for all affected users.", next: "end_success" }], end: false },
      minimizing: { text: "That still sounds like thousands of people. Is {{business}} taking this seriously?", choices: [{ text: "Absolutely. We are rebuilding our {{item}} firewall from scratch.", next: "end_success" }], end: false },
      end_success: { text: "Thank you. We'll publish the update by {{time}}.", end: true }
    }
  },
  {
    scene: "Mentorship Session",
    instruction: "Advise a junior developer on their career path at {{business}}.",
    speaker: "Junior ({{name}})",
    startText: "I feel like I'm stuck working on the {{item}} maintenance. How do I get onto the {{location}} R&D team?",
    choices: [
      { text: "Focus on mastering the current {{item}} architecture first.", next: "mastery" },
      { text: "Start contributing to open-source projects in {{location}} to build your profile.", next: "open_source" }
    ],
    nodes: {
      mastery: { text: "But the {{item}} tech is old. Won't I fall behind the {{location}} market?", choices: [{ text: "The fundamentals of {{item}} design never change; master them.", next: "end_success" }], end: false },
      open_source: { text: "Can you recommend any specific {{item}} projects for this {{time}}?", choices: [{ text: "Look for the {{business}} Labs repo on GitHub.", next: "end_success" }], end: false },
      end_success: { text: "I'll try that. Thanks for the advice, I'll see you this {{time}}.", end: true }
    }
  }
];

const conflictResolver = [
  {
    scenario: "Your colleague {{name}} keeps using your personal {{item}} at {{business}} without asking.",
    question: "How do you address this firmly but professionally?",
    options: ["I'd prefer if you ask before using my {{item}} next time.", "Stop touching my things!", "I'm hiding the {{item}} from now on.", "I'll use your laptop in return."],
    correctIndex: 0,
    hint: "Use 'I' statements to express your needs."
  },
  {
    scenario: "A client in {{location}} is {{feeling}} because the {{item}} you delivered is the wrong color.",
    question: "How do you resolve this at no extra cost to them?",
    options: ["We will ship the correct color today and you can keep the original as a gift.", "You should have specified it better.", "Color doesn't affect performance.", "That's the only one we have left."],
    correctIndex: 0,
    hint: "Offer an over-delivery to mend the relationship."
  },
  {
    scenario: "Two team members at {{business}} are arguing about the {{item}} budget for next {{time}}.",
    question: "As the lead, how do you mediate?",
    options: ["Let's sit down and review the priorities for both teams together.", "Flip a coin to decide.", "Whoever worked here longer gets more budget.", "I'll decide and you both just listen."],
    correctIndex: 0,
    hint: "Collaboration and shared understanding reduce friction."
  },
  {
    scenario: "Your manager, {{name}}, gave you a {{feeling}} performance review that you believe is unfair.",
    question: "What is your next step?",
    options: ["Request a meeting to discuss specific examples and areas for improvement.", "Quit immediately.", "Tell all your coworkers how bad {{name}} is.", "Ignore the review and keep working."],
    correctIndex: 0,
    hint: "Constructive dialogue can clarify misunderstandings."
  },
  {
    scenario: "An employee at {{business}} is frequently late for the {{time}} shift, affecting the {{location}} team.",
    question: "How do you handle the first warning?",
    options: ["I've noticed a pattern with your arrival times; is everything okay?", "You're fired if you're late again.", "I'm docking your pay starting today.", "Why can't you be more like {{name}}?"],
    correctIndex: 0,
    hint: "Start with empathy to understand the root cause."
  },
  {
    scenario: "A neighbor in {{location}} is complaining about the noise from your {{item}} testing.",
    question: "How do you maintain a good relationship?",
    options: ["Apologize and set specific hours for testing that don't disturb them.", "Tell them to move if they don't like it.", "It's a free country.", "Invite them to test it with you."],
    correctIndex: 0,
    hint: "Compromise and scheduling are key to neighborly harmony."
  },
  {
    scenario: "Your business partner at {{business}} wants to pivot to {{location}} but you want to stay local.",
    question: "How do you reach a decision?",
    options: ["Let's run a pilot program in {{location}} for three months to test the waters.", "I'm the CEO, we stay here.", "We should split the company.", "Whatever you want, I don't care."],
    correctIndex: 0,
    hint: "Pilot programs provide data for informed decisions."
  }
];

const elevatorPitch = [
  {
    scenario: "You have 30 seconds with a VC from {{location}} in the lobby of {{business}}.",
    question: "What's your hook for the new {{item}} app?",
    options: ["We're the 'Uber' for {{item}}s, already serving 50k users in {{location}}.", "It's a long story, do you have an hour?", "It's a secret for now.", "We need money to build a better office."],
    correctIndex: 0,
    hint: "Start with a high-concept pitch and a traction metric."
  },
  {
    scenario: "You're introducing yourself to the CEO of {{business}} at a {{time}} gala.",
    question: "How do you describe your impact?",
    options: ["I'm the one who saved the {{location}} project from the {{item}} failure.", "I'm just a junior analyst.", "I work in the basement.", "I'm {{name}}, nice to meet you."],
    correctIndex: 0,
    hint: "Focus on the value you've delivered to the organization."
  },
  {
    scenario: "A potential partner asks what {{business}} does while waiting for a taxi in {{location}}.",
    question: "What is your concise summary?",
    options: ["We streamline {{item}} logistics for global enterprises using AI.", "We sell stuff online.", "It's a tech company.", "Ask {{name}}, they know better."],
    correctIndex: 0,
    hint: "Use clear, professional industry terms."
  },
  {
    scenario: "An old friend at {{location}} asks why they should join your new {{item}} venture.",
    question: "What's the vision?",
    options: ["We're going to disrupt the {{item}} industry in {{location}} by 2030.", "It's better than your current job.", "The snacks are great.", "I don't know, just join."],
    correctIndex: 0,
    hint: "Focus on long-term industry disruption and vision."
  }
];

const emergencyHub = [
  {
    scenario: "A caller named {{name}} is panicked because they found a suspicious {{item}} at the {{location}} station.",
    question: "What is your first instruction?",
    options: ["Please move everyone at least 100 meters away from the {{item}}.", "Open it and see what's inside.", "Don't worry, it's probably just trash.", "Stay right there and guard it."],
    correctIndex: 0,
    hint: "Safety and distance are the priorities."
  },
  {
    scenario: "There is a massive {{item}} spill at the {{business}} plant in {{location}} this {{time}}.",
    question: "What is the immediate protocol?",
    options: ["Evacuate the area and engage the primary containment sub-routine.", "Try to clean it with water.", "Call {{name}} and ask for advice.", "Take a photo for social media."],
    correctIndex: 0,
    hint: "Containment and evacuation save lives."
  },
  {
    scenario: "An employee at {{business}} has collapsed in the lobby during the {{time}} rush.",
    question: "What do you tell the person on the scene?",
    options: ["Check for a pulse and start chest compressions if needed.", "Give them some water.", "Shake them until they wake up.", "Wait for the ambulance without touching them."],
    correctIndex: 0,
    hint: "Basic life support steps are critical."
  },
  {
    scenario: "The {{location}} fire alarm is sounding at {{business}} but no smoke is visible.",
    question: "How do you handle the evacuation?",
    options: ["Proceed with a full evacuation as if it were a real fire.", "Ignore it, it's probably a drill.", "Go check the kitchen first.", "Wait for {{name}} to tell you what to do."],
    correctIndex: 0,
    hint: "Never assume a fire alarm is a drill."
  }
];

const gourmetOrder = [
  {
    scenario: "A food critic from {{business}} is {{feeling}} about the wait for their {{item}} soup.",
    question: "How do you handle the table?",
    options: ["Offer a glass of our finest vintage from {{location}} on the house.", "Tell them the chef is having a bad {{time}}.", "The kitchen is busy, wait your turn.", "Just bring them more bread."],
    correctIndex: 0,
    hint: "Acknowledge the status and offer a premium gesture."
  },
  {
    scenario: "A guest at your {{location}} restaurant has a severe allergy to the {{item}} ingredient.",
    question: "How do you ensure their safety?",
    options: ["I will personally oversee the preparation to avoid any cross-contamination.", "It's only a small amount, you'll be fine.", "We don't have anything without that.", "Just eat around it."],
    correctIndex: 0,
    hint: "Allergies require personal oversight and 100% certainty."
  },
  {
    scenario: "The table in the corner at {{business}} wants to order a {{item}} that isn't on the menu.",
    question: "How do you respond politely?",
    options: ["While it's not on our menu, I'll see if the chef can prepare it for you.", "We don't do custom orders.", "You should have gone to a different place.", "No."],
    correctIndex: 0,
    hint: "Hospitality is about trying to say 'yes' within reason."
  },
  {
    scenario: "A customer in {{location}} says their {{item}} steak is overcooked.",
    question: "What is the professional response?",
    options: ["I'm so sorry; I'll have the chef prepare a fresh one for you immediately.", "It looks fine to me.", "Do you want a discount instead?", "You should have ordered it rare."],
    correctIndex: 0,
    hint: "Immediate replacement is the standard for overcooked mains."
  }
];

const jobInterview = [
  {
    scenario: "The CEO of {{business}} asks: 'Where do you see yourself in 5 years in the {{location}} market?'",
    question: "What is the most ambitious yet grounded response?",
    options: ["Leading the {{item}} division and expanding our footprint in {{location}}.", "I hope to have your job.", "I just want to be happy.", "Maybe living in a different city."],
    correctIndex: 0,
    hint: "Align your growth with the company's expansion."
  },
  {
    scenario: "The interviewer, {{name}}, asks why you want to work for {{business}} specifically.",
    question: "What is the most impressive answer?",
    options: ["I admire your innovative approach to {{item}} and your commitment to {{location}}.", "I need the money.", "My friend works here.", "It's the only place that called me back."],
    correctIndex: 0,
    hint: "Show that you've researched the company and its values."
  },
  {
    scenario: "You are asked about your biggest weakness at {{business}}.",
    question: "How do you frame it positively?",
    options: ["I sometimes get too focused on details, but I'm using {{item}} tools to manage my time better.", "I'm a perfectionist.", "I don't have any weaknesses.", "I'm always late for {{time}} meetings."],
    correctIndex: 0,
    hint: "Mention a real weakness and the specific tool/method you're using to fix it."
  }
];

const medicalConsult = [
  {
    scenario: "The patient {{name}} is {{feeling}} because they read online that their {{symptom}} is terminal.",
    question: "How do you provide professional reassurance?",
    options: ["Let's rely on the clinical tests we did at {{business}} rather than internet searches.", "You shouldn't believe everything you read.", "It might be terminal, we don't know yet.", "Stop using your {{item}} for research."],
    correctIndex: 0,
    hint: "Redirect them to verified clinical data."
  },
  {
    scenario: "A patient in {{location}} is refusing to take their {{item}} medication.",
    question: "How do you address their concerns?",
    options: ["Can you tell me more about what's worrying you about the {{item}}?", "You have to take it or you'll get worse.", "I'm the doctor, just do what I say.", "I'll tell {{name}} to talk to you."],
    correctIndex: 0,
    hint: "Open-ended questions help uncover the source of non-compliance."
  }
];

const situationalResponse = [
  {
    scenario: "You accidentally broke a valuable {{item}} at {{name}}'s house during a {{time}} party.",
    question: "What is the most honorable reaction?",
    options: ["Tell them immediately and offer to replace it or pay the full value.", "Hide it behind the sofa.", "Blame the cat.", "Pretend you didn't see it."],
    correctIndex: 0,
    hint: "Honesty is always the best policy in social settings."
  },
  {
    scenario: "You see someone drop their {{item}} at the {{location}} airport.",
    question: "What do you do?",
    options: ["Excuse me! I think you dropped your {{item}}.", "Wait for them to leave and keep it.", "Kick it under a bench.", "Tell security and let them handle it."],
    correctIndex: 0,
    hint: "Direct assistance is the fastest way to help."
  }
];

const socialSpark = [
  {
    scenario: "You want to talk to the keynote speaker, {{name}}, at the {{location}} {{business}} summit.",
    question: "What's the best way to open?",
    options: ["I really enjoyed your point about {{item}} integration; how did you test it?", "Can I take a selfie?", "You talked for a long time.", "Do you have any jobs available?"],
    correctIndex: 0,
    hint: "Ask a specific follow-up question about their talk."
  },
  {
    scenario: "You're at a {{time}} mixer in {{location}} and don't know anyone.",
    question: "How do you join a group conversation?",
    options: ["Wait for a natural pause and say: 'Hi, I'm {{name}}, do you mind if I join you?'", "Just stand there and listen without saying anything.", "Start talking over the person who is speaking.", "Check your {{item}} until someone talks to you."],
    correctIndex: 0,
    hint: "A polite introduction during a pause is standard etiquette."
  }
];

const travelDesk = [
  {
    scenario: "A traveler in {{location}} needs to get to the {{business}} airport in 15 minutes during the {{time}} rush.",
    question: "What is the only viable advice?",
    options: ["The express motorcycle courier is the only way through the {{location}} traffic.", "You should have left an hour ago.", "Take the bus.", "Try running."],
    correctIndex: 0,
    hint: "In a rush, unconventional transport is sometimes the only fix."
  },
  {
    scenario: "The {{location}} flight was cancelled and {{name}} is {{feeling}}.",
    question: "How do you help them as the desk agent?",
    options: ["I've already booked you on the next flight and issued a {{business}} voucher.", "There's nothing I can do.", "You'll have to wait until {{time}} tomorrow.", "Call your travel agent."],
    correctIndex: 0,
    hint: "Proactive rebooking and compensation mitigate frustration."
  }
];

module.exports = {
  branchingDialogue,
  conflictResolver,
  elevatorPitch,
  emergencyHub,
  gourmetOrder,
  jobInterview,
  medicalConsult,
  situationalResponse,
  socialSpark,
  travelDesk
};
