
const fs = require('fs');

const domainBank = {
  "Astronomy": ["Quasar", "Pulsar", "Nebula", "Galaxy", "Supernova", "Exoplanet", "Parallax", "Binary Star", "Singularity"],
  "Geology": ["Basalt", "Obsidian", "Quartz", "Tectonic", "Sediment", "Magma", "Fissure", "Stratum", "Erosion"],
  "Microeconomics": ["Elasticity", "Utility", "Incentive", "Scarcity", "Equilibrium", "Marginal", "Monopoly", "Oligopoly", "Duopoly"],
  "Macroeconomics": ["Inflation", "GDP", "Recession", "Deflation", "Fiscal", "Monetary", "Aggregate", "Liquidity", "Stagflation"],
  "Organic Chemistry": ["Polymer", "Covalent", "Isomer", "Alkane", "Enzyme", "Catalyst", "Synthesis", "Isotope", "Monomer"],
  "Criminal Law": ["Felony", "Prosecutor", "Indictment", "Larceny", "Perjury", "Homicide", "Warrant", "Arraignment", "Verdict"],
  "Civil Law": ["Liability", "Plaintiff", "Tort", "Contract", "Statute", "Negligence", "Litigation", "Subpoena", "Probate"],
  "Genetics": ["Phenotype", "Allele", "Mutation", "Genome", "Chromosome", "Dominant", "Recessive", "Hybrid", "Cloning"],
  "Ecology": ["Biosphere", "Symbiosis", "Succession", "Habitat", "Diversity", "Niche", "Food Chain", "Ecosystem", "Biome"],
  "Psychology": ["Cognition", "Behaviorism", "Psyche", "Neurosis", "Trauma", "Ego", "Superego", "Fixation", "Projection"],
  "Sociology": ["Urbanization", "Stratification", "Norms", "Culture", "Class", "Mobility", "Deviance", "Anomie", "Institution"],
  "Renaissance": ["Humanism", "Perspective", "Fresco", "Mannerism", "Sculpt", "Patron", "Secular", "Vernacular", "Engraving"],
  "Baroque": ["Chiaroscuro", "Ornate", "Grandeur", "Dramatic", "Concerto", "Ornamental", "Opera", "Intensity", "Dynamic"],
  "Architecture": ["Facade", "Cantilever", "Blueprint", "Architrave", "Cornice", "Column", "Portal", "Balustrade", "Gable"],
  "Music Theory": ["Symphony", "Sonata", "Syncopation", "Improvisation", "Cadence", "Interval", "Pitch", "Tempo", "Timbre"],
  "Botany": ["Stamen", "Chlorophyll", "Photosynthesis", "Vascular", "Petal", "Germination", "Root", "Spore", "Leaf"],
  "Philosophy": ["Metaphysics", "Epistemology", "Ethics", "Logic", "Ontology", "Existential", "Aesthetic", "Idealism", "Stoicism"],
  "Politics": ["Bilateral", "Diplomacy", "Coalition", "Embargo", "Ratify", "Sovereign", "Suffrage", "Veto", "Electorate"],
  "Typography": ["Kerning", "Serif", "Ligature", "Baseline", "Ascender", "Descender", "Typeface", "Gutter", "Tracking"],
  "Meteorology": ["Cyclone", "Anticyclone", "Isobar", "Tropopause", "Hygrometer", "Convection", "Frontal", "Adiabatic", "Albedo"],
  "Anatomy": ["Cerebellum", "Ventricle", "Capillary", "Phalanges", "Diaphragm", "Hypothalamus", "Clavicle", "Sternum", "Ligament"],
  "Oceanography": ["Benthic", "Pelagic", "Bathymetry", "Halocline", "Upwelling", "Abyssal", "Trench", "Current", "Salinity"],
  "Linguistics": ["Phoneme", "Morpheme", "Syntax", "Semantics", "Pragmatics", "Lexicon", "Dialect", "Etymology", "Syllable"],
  "Cybersecurity": ["Firewall", "Encryption", "Malware", "Phishing", "Protocol", "Vulnerability", "Backdoor", "Ransomware", "Sandbox"],
  "Paleontology": ["Fossil", "Trilobite", "Excavation", "Strata", "Epoch", "Mesozoic", "Jurassic", "Cretaceous", "Ammonite"],
  "Mythology": ["Pantheon", "Chimera", "Oracle", "Deity", "Avatar", "Legend", "Folklore", "Hero", "Omen"],
  "Physics": ["Hadron", "Boson", "Entropy", "Quark", "Lepton", "Quantum", "Singularity", "Relativity", "Momentum"],
  "Finance": ["Dividend", "Annuity", "Derivative", "Capital", "Arbitrage", "Hedge", "Escrow", "Audit", "Collateral"],
  "Marketing": ["Branding", "Segment", "Funnel", "Engagement", "Analytics", "Positioning", "Slogan", "Logo", "Reach"],
  "Agriculture": ["Irrigation", "Agronomy", "Cultivar", "Fallow", "Tillage", "Harvest", "Fertilizer", "Pesticide", "Livestock"],
  "Fashion": ["Couture", "Silhouette", "Textile", "Atelier", "Ensemble", "Collection", "Runway", "Trend", "Fabric"],
  "Nautical": ["Starboard", "Schooner", "Latitude", "Longitude", "Anchor", "Sextant", "Bow", "Stern", "Knot"],
  "Aviation": ["Fuselage", "Altimeter", "Payload", "Turbulence", "Propulsion", "Aileron", "Cockpit", "Radar", "Jetstream"],
  "Culinary": ["Sauté", "Braise", "Julienne", "Reduction", "Deglaze", "Mise-en-place", "Stock", "Zest", "Poach"],
  "Photography": ["Aperture", "ISO", "Exposure", "Focal", "Sensor", "Composition", "Shutter", "Tripod", "Depth"],
  "Mathematics": ["Calculus", "Geometry", "Algebra", "Theorem", "Fractal", "Integer", "Matrix", "Vector", "Limit"],
  "Electronics": ["Capacitor", "Resistor", "Inductor", "Transistor", "Diode", "Circuit", "Voltage", "Current", "Watt"],
  "Horticulture": ["Pruning", "Mulch", "Perennial", "Hybrid", "Propagation", "Greenhouse", "Trellis", "Bulb", "Compost"],
  "Jurisprudence": ["Precedent", "Litigation", "Statutory", "Injunction", "Counsel", "Affidavit", "Jurisdiction", "Decree", "Mandate"],
  "Anthropology": ["Ethnography", "Kinship", "Lineage", "Ritual", "Primitive", "Evolution", "Culture", "Fossil", "Primitive"],
};

function generate600FinalQuests() {
    const quests = [];
    const keys = Object.keys(domainBank);
    let questCount = 0;

    // Use a 3-pass approach with 40 pairs = 120 unique sorting tasks per pass
    // To get 600, we need to iterate and mix different pairs.
    for (let pass = 0; pass < 15; pass++) {
        for (let i = 0; i < keys.length; i++) {
            if (questCount >= 600) break;
            
            const domainA = keys[i];
            const domainB = keys[(i + 1 + pass) % keys.length];
            if (domainA === domainB) continue;
            
            const wordOffset = Math.floor(questCount / keys.length) % 3;
            const wordsA = domainBank[domainA].slice(wordOffset * 3, (wordOffset * 3) + 3);
            const wordsB = domainBank[domainB].slice(wordOffset * 3, (wordOffset * 3) + 3);
            
            if (wordsA.length < 3 || wordsB.length < 3) continue;

            const tier = questCount < 200 ? 1 : (questCount < 400 ? 2 : 3);
            const allWords = [...wordsA, ...wordsB].sort(() => Math.random() - 0.5);
            const correctAnswer = `${domainA}: ${wordsA.join(", ")} | ${domainB}: ${wordsB.join(", ")}`;

            quests.push({
                id: `VOC_TOPIC_VOCAB_L${Math.floor(questCount/3)+1}_Q${(questCount%3)+1}`,
                instruction: "Neural Categorization: Sort terms into their thematic silos.",
                difficulty: tier,
                subtype: "topicVocab",
                interactionType: "sort",
                topicBuckets: [domainA, domainB],
                options: allWords,
                correctAnswer: correctAnswer,
                hint: `Identify the unique signatures of ${domainA} and ${domainB}.`,
                explanation: `Mastery attained. These terms are perfectly indexed within the ${domainA} and ${domainB} knowledge bases.`,
                visual_config: {
                    painter_type: tier === 1 ? "CouncilHallSync" : (tier === 2 ? "NexusCoreSync" : "ArchiveDecryptSync"),
                    primary_color: tier === 1 ? "0xFF00BCD4" : (tier === 2 ? "0xFF9C27B0" : "0xFF607D8B"),
                    pulse_intensity: 0.6,
                    shader_effect: "binary_pulse"
                }
            });
            questCount++;
        }
    }
    return quests;
}

const allQuests = generate600FinalQuests();

for (let b = 1; b <= 20; b++) {
  const start = (b - 1) * 10 + 1;
  const end = b * 10;
  const fileName = `c:/Users/asus/Documents/App Projects/vowl/assets/curriculum/vocabulary/topic_vocab_${start}_${end}.json`;
  const batch = allQuests.filter(q => {
      const level = parseInt(q.id.split('_L')[1].split('_Q')[0]);
      return level >= start && level <= end;
  });

  fs.writeFileSync(fileName, JSON.stringify({ gameType: "topicVocab", batchIndex: b, levels: `${start}-${end}`, quests: batch }, null, 2));
}

console.log(`ABSOLUTE INFINITY COMPLETE: ${allQuests.length} unique quests generated across 20 files.`);
