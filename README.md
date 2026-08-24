# 🦉 Vowl: An AI-Powered English Learning Adventure

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![AI Powered](https://img.shields.io/badge/AI-Powered-green?style=for-the-badge)
![CI/CD](https://github.com/ansar7787/vowl-app/actions/workflows/flutter_ci.yml/badge.svg)

Vowl is a massive, full-stack language learning application built from the ground up with Flutter and Firebase. I wanted to build something that goes beyond simple multiple-choice quizzes, so I integrated Google Gemini and on-device machine learning to create a platform that actually listens, speaks, and adapts to the user.

Whether you're an adult practicing for a job interview in the AI Roleplay arena, or a kid learning to write the alphabet using on-device handwriting recognition, Vowl handles it all within a single, highly structured codebase.

---

## 📸 A Look Inside

*(Note: Add your long, detailed screenshots of the app here so people can see the beautiful UI you built!)*

<div align="center">
  <img src="https://via.placeholder.com/250x700.png?text=Home+Screen" width="250" />
  <img src="https://via.placeholder.com/250x700.png?text=Game+UI" width="250" />
  <img src="https://via.placeholder.com/250x700.png?text=Kids+Zone" width="250" />
</div>

---

## 🛠️ How It's Built (The Tech Stack)

I didn't want this to just be a prototype. I built Vowl to handle real users, which meant focusing heavily on clean architecture, predictable state management, and backend security.

### Frontend Architecture
- **State Management**: I use `flutter_bloc` exclusively. The UI is strictly separated from the business logic, making the app highly predictable and easy to debug.
- **Dependency Injection**: `get_it` handles my services so the app remains testable and modular.
- **Functional Error Handling**: I use `dartz` to implement `Either<Failure, Success>` across the data layer. This prevents silent crashes and forces the UI to handle errors gracefully.
- **Routing**: Deep-linking and complex nested flows are handled entirely by `go_router`.

### Backend & Infrastructure (Firebase)
- **Firestore**: The database is optimized with atomic transactions and array unions. This ensures that user progress and virtual currency updates happen safely, even if the user has a spotty internet connection.
- **Cloud Functions**: Sensitive operations (like verifying purchases or modifying coin balances) happen securely on the backend.
- **Remote Config**: I can tweak game difficulty, adjust economy payouts, and toggle new feature flags instantly without pushing a new update to the App Store.
- **Security & Anti-Cheat**: I use Firebase App Check and `safe_device` (root/jailbreak detection) to prevent malicious actors from spoofing API calls or hacking the in-game economy.

---

## 🧠 Bringing It to Life with AI & Machine Learning

This is where Vowl really shines. I relied heavily on Google's ML Kit and Generative AI to build features that feel magical:

- **AI Roleplay (Gemini)**: Instead of scripted conversations, users talk to an AI that adapts to their skill level. They can practice real-world scenarios, like negotiating a salary or ordering coffee, dynamically.
- **Handwriting Recognition**: In the Kids Zone, children trace letters directly on the screen. I use Google ML Kit's Digital Ink Recognition to process and grade their handwriting locally on the device.
- **Speech Evaluation**: I use `speech_to_text` to capture the user's pronunciation, allowing the app to provide real-time feedback on their speaking clarity.
- **Interactive Voices**: Using `flutter_tts`, the app actually speaks to users—from dictation exercises in the adult curriculum to our fully animated kids' mascots, Owly and Panda.
- **Context-Aware Hints**: Instead of a generic "wrong answer" popup, the app uses AI to generate specific hints based on what the user got wrong.

---

## 🎮 The Learning Experience

The app is split into two massive, distinct ecosystems to cater to different age groups.

### For Adults (Advanced Learning)
- **Grammar Architect**: Users physically drag and drop sentence fragments to build complex clauses.
- **Topic Nexus & Flashcards**: Context-aware vocabulary training that spans over 50 real-world topics.
- **Elite Mastery**: A grueling, 10,000-level challenge that tests everything the user has learned in a fast-paced gauntlet.

### For Kids (The Kids Zone Sandbox)
- **22 Unique Games**: Covering foundational skills like phonics, math, weather, and shapes.
- **The Buddy Boutique**: Kids earn "Stars" through learning, which they can spend in the boutique to buy hats, glasses, and outfits for their virtual mascots.
- **Holographic Stickers**: A tactile sticker album where kids collect rewards. It uses the device's sensors to create a shiny, holographic visual effect when the phone tilts.

---

## 💰 The Game Economy & Monetization

To keep the app sustainable, I built a dual-currency system (Coins and Keys) powered by real integrations:
- **Premium Subscriptions (Razorpay)**: Fully integrated payment flows for users who want to upgrade to the premium tier.
- **Rewarded Ad Loops**: Free users aren't locked out. By watching Google Mobile Ads, they can earn "Keys" to unlock premium features and Elite Mastery levels with their time instead of their money.

---

## 🚀 Running the Project Locally

### Prerequisites
- Flutter SDK (`^3.10.7`)
- Node.js (Only required if you want to run the backend data-generation scripts in the `scripts/` folder)

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
    Create `.env` from `.env.template` and add your Firebase, Razorpay, and Gemini API keys.
4.  **Run the App**: 
    ```bash
    flutter run
    ```

---
*Built with passion by the Vowl Team.*
