# 🦉 Vowl: An AI-Powered English Learning Adventure

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Offline First](https://img.shields.io/badge/Offline--First-100%25-brightgreen)
![CI/CD](https://github.com/ansar7787/vowl-app/actions/workflows/flutter_ci.yml/badge.svg)

Vowl is my passion project—a massive, full-stack language learning application built from the ground up with Flutter and Firebase. I wanted to build something that goes far beyond simple multiple-choice quizzes. My goal was to create a living, breathing pedagogical engine that actually listens, speaks, and adapts to the user, **all while remaining completely offline-first with zero loading screens.**

What started as a simple idea has evolved into an enormous ecosystem. Vowl contains **100 distinct adult-level learning games** and **25 specific kids' games**, encompassing over 20,000 unique levels of curriculum. Whether you're an adult practicing for a job interview in the Roleplay arena, or a kid learning to write the alphabet using on-device handwriting recognition with their interactive buddy, Vowl handles it all within a single, highly structured codebase.

---

## 📸 A Look Inside

*(Note: Add your long, detailed scrolling screenshots of the app here to showcase the beautiful UI, the Kids Rooms, and the massive game variety!)*

<div align="center">
  <img src="https://via.placeholder.com/250x700.png?text=Home+Screen" width="250" />
  <img src="https://via.placeholder.com/250x700.png?text=Game+UI+Variety" width="250" />
  <img src="https://via.placeholder.com/250x700.png?text=Kids+Zone+Rooms" width="250" />
</div>

---

## 🎮 The Adult Curriculum: 100 Unique Game Mechanics

The adult learning section is built to take users from beginner to absolute fluency. I didn't just build one quiz screen; I built **100 entirely different game mechanics**, spanning multiple linguistic disciplines:

### Vocabulary & Memory
- **Topic Nexus**: Context-aware vocabulary training that spans over 50 real-world topics (business, travel, daily life).
- **Prefix & Suffix Builder**: Users physically drag and connect word roots to affixes to understand word origins.
- **Phrasal Verb Vault**: Deep dives into the hardest part of English—phrasal verbs—using interactive context sentences.
- **High-Speed Flashcards**: Spaced repetition memory training designed for rapid recall.
- **Synonym & Antonym Search**: Expanding lexical flexibility through targeted matching mechanics.

### Grammar & Structure
- **Grammar Architect**: Users physically drag and drop sentence fragments, clauses, and modifiers to build perfect sentences.
- **Sentence Correction**: Users must identify and tap the exact grammatical error in a dynamically generated paragraph.
- **Tense Mastery**: Real-time context switching where users must conjugate verbs perfectly based on the narrative timeline.

### Reading & Listening
- **Shadowing Playback**: Users listen to native audio, then attempt to speak the exact same sentence, matching the rhythm and intonation.
- **Context Sentence Builder**: Reading comprehension exercises that force the user to deduce meaning from surrounding context clues.
- **Blind Dictation**: Users hear a sentence with heavy accents or background noise and must type exactly what they heard.

### Speaking & Conversation
- **Roleplay Arena**: Users practice real-world scenarios, like negotiating a salary or ordering a coffee. 
- **Speech Evaluation Studio**: I use `speech_to_text` to capture the user's pronunciation, allowing the app to provide real-time grading on their speaking clarity.

### The Ultimate Challenge
- **Elite Mastery**: For users who think they've mastered everything, I built a grueling, 10,000-level gauntlet that throws every single game mechanic at them in rapid succession. 

---

## 🧒 The Kids Zone Ecosystem: 25 Sandboxed Games

Children learn differently than adults. I built a completely separate, highly sandboxed environment tailored for young minds, stripped of complex UI and focused entirely on engagement and sensory feedback.

### The 25 Kids Games
I built 25 distinct learning modules specifically for kids, including:
- **Digital Ink Handwriting**: Children trace letters and numbers directly on the screen. I use Google ML Kit's Digital Ink Recognition to process and grade their handwriting locally on the device in real-time.
- **Phonics & Sounds**: Connecting letters to their physical sounds using high-fidelity audio cues.
- **Math & Counting**: Interactive drag-and-drop logic for foundational counting.
- **Colors, Shapes, & Weather**: Visual, vibrant sorting games using custom mesh gradients and Lottie animations.
- **Animal Habitats**: Dragging animals to their correct biomes while learning their names.

### Interactive Buddies & The Buddy Rooms
Learning alone is boring. I built a dynamic companion system:
- **Main Buddies (Owly & Panda)**: Fully animated, interactive mascots that guide the user. Using `flutter_tts`, they actually speak to the kids, cheering them on when they win and offering gentle encouragement when they make a mistake.
- **Kids Rooms & The Boutique**: Kids earn "Stars" through learning, which they can spend in the Buddy Boutique to buy hats, glasses, and outfits. They can then equip these items on their buddies and decorate their virtual "Rooms".
- **Holographic Sticker Album**: A tactile sticker album where kids collect rare rewards. It uses the device's gyroscope sensors to create a shiny, holographic visual effect when the phone tilts.

---

## 🧠 The 100% Offline Pedagogical Engine

One of the biggest architectural decisions I made was ensuring Vowl runs **completely offline without live API costs.** 

Instead of hitting live AI APIs during gameplay (which causes loading screens and costs money), I used AI to *pre-generate* the massive 20,000+ level curriculum. This is all securely stored in highly optimized local JSON files.

- **Zero Loading Screens**: The entire curriculum loads instantly from device memory.
- **Advanced Context-Aware Hints**: If a user gets a Prefix/Suffix question wrong, the app doesn't just say "Wrong." The pre-generated pedagogical hint engine analyzes their exact mistake (e.g., using "un-" instead of "re-") and provides a localized micro-lesson.

---

## 🛠️ The Architecture & Tech Stack

To support 125+ game mechanics, interactive buddies, and an offline engine, I had to build a rock-solid foundation.

### Frontend Architecture
- **State Management (`flutter_bloc`)**: The UI is strictly separated from the business logic. With hundreds of games, BLoC ensures the app remains highly predictable and easy to debug.
- **Dependency Injection (`get_it`)**: Manages the massive web of services (TTS, Speech recognition, local JSON repositories).
- **Functional Error Handling (`dartz`)**: I use `Either<Failure, Success>` across the entire data layer to prevent silent crashes.
- **Routing (`go_router`)**: Deep-linking and complex nested flows are handled safely.

### Voice & Machine Learning (Google ML Kit)
- **On-Device Handwriting (Digital Ink)**: Evaluates kids tracing letters instantly, 100% offline.
- **Real-Time Translation & Language ID**: Instant support for users in their native language without network latency.
- **Smart Reply & Text Recognition**: Advanced context-aware text processing within the reading modules.
- **Text-to-Speech (`flutter_tts`)**: Used extensively for dictation exercises and making the Buddies come alive.

---

## 🛡️ Backend, Security & The Game Economy

A massive game needs a secure economy. Vowl runs on a dual-currency system (Coins and Keys), backed entirely by Firebase.

### Firebase Infrastructure
- **Firestore (Atomic Transactions)**: The database is optimized with atomic batches and array unions. This ensures that user progress, level unlocks, and virtual currency updates happen safely.
- **Cloud Functions**: Sensitive operations (like verifying Razorpay purchases or modifying Coin balances) happen securely on the backend.
- **Remote Config**: I can tweak game difficulty, adjust economy payouts, and toggle new feature flags instantly without pushing a new update to the App Store.

### Security & Anti-Cheat
- **Root & Jailbreak Detection (`safe_device`)**: The app actively detects compromised devices to prevent piracy of premium content.
- **Firebase App Check**: Cryptographically ensures that only the compiled, official Vowl binary can communicate with our Firestore database.
- **Global Debounce Protection**: Every single one of the hundreds of interactive buttons is wrapped in debounce logic to prevent rapid-fire API spamming.

### Monetization
- **Premium Subscriptions (Razorpay)**: Fully integrated payment flows for users who want to upgrade to the premium tier.
- **Rewarded Ad Loops**: Free users aren't locked out. By watching Google Mobile Ads, they can earn "Keys" to unlock premium features and Elite Mastery levels with their time instead of their money.

---

## 🚀 Running the Project Locally

### Prerequisites
- Flutter SDK (`^3.10.7`)
- Node.js (Only required if you want to run the massive suite of backend data-generation scripts in the `scripts/` folder)

### Installation

1.  **Clone the Repository**: 
    ```bash
    git clone https://github.com/ansar7787/vowl-app.git
    cd vowl-app
    ```
2.  **Install Flutter Dependencies**: 
    ```bash
    flutter pub get
    ```
3.  **Environment Setup**: 
    Create `.env` from `.env.template` and securely inject your Firebase and Razorpay keys. (No expensive live AI API keys required!)
4.  **Compile & Run**: 
    ```bash
    flutter run
    ```

---
*Architected and built entirely solo with passion by Ansar.*
