<!-- markdownlint-disable MD033 MD041 MD051 -->
<div align="center">
  <img src="assets/images/vowly_mascot.png" alt="Vowl Logo" width="150"/>
  <h1>Vowl (formerly VoxAI Quest)</h1>
  <p><b>A highly scalable, production-grade language learning application at enterprise scale.</b></p>

  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/firebase-ffca28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
  [![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
  [![BLoC](https://img.shields.io/badge/BLoC-State_Management-blue?style=for-the-badge)](https://bloclibrary.dev/)
  ![Scale](https://img.shields.io/badge/Scale-100k%2B_LOC-success?style=for-the-badge)
  ![Scale](https://img.shields.io/badge/Games-100%2B-blueviolet?style=for-the-badge)
</div>

---

## 📖 Executive Summary

**Vowl** is a colossal, production-ready language learning and gamification platform built entirely on Flutter and Firebase. Spanning over **1,000+ files and 100,000+ lines of code**, this project represents an enterprise-grade mobile application architecture.

It features a massive, dynamic curriculum comprising over **100 interactive game types**, a **200-level curriculum per game**, and an astounding **60,000+ unique learning challenges**. Engineered for scale, Vowl boasts a robust, 0-static-error architecture, strict backend zero-trust security, server-side receipt validation, and a visually stunning 60fps glassmorphic UI.

---

## 📑 Table of Contents

- [Executive Summary](#-executive-summary)
- [Screenshots & UI Showcase](#-screenshots--ui-showcase)
- [Comprehensive Feature Breakdown](#-comprehensive-feature-breakdown)
- [Core Architecture & Engineering](#-core-architecture--engineering)
- [Security & Backend Infrastructure](#-security--backend-infrastructure)
- [Codebase Structure](#-codebase-structure)
- [Getting Started](#-getting-started)
- [Legal & Compliance](#-legal--compliance)

---

## 📸 Screenshots & UI Showcase

> **Note:** (Developer) Insert actual screenshots here before publishing to your portfolio.

<div align="center">
  <!-- INSERT SCREENSHOT HERE: Home Dashboard -->
  <img src="https://via.placeholder.com/250x500.png?text=Home+Dashboard" alt="Home Dashboard" width="200"/>
  &nbsp;&nbsp;
  <!-- INSERT SCREENSHOT HERE: Game Screen (e.g., Grammar or Vocab) -->
  <img src="https://via.placeholder.com/250x500.png?text=Interactive+Game" alt="Interactive Game" width="200"/>
  &nbsp;&nbsp;
  <!-- INSERT SCREENSHOT HERE: Kids Zone / Parental Gate -->
  <img src="https://via.placeholder.com/250x500.png?text=Kids+Zone" alt="Kids Zone" width="200"/>
  &nbsp;&nbsp;
  <!-- INSERT SCREENSHOT HERE: Profile & Streaks -->
  <img src="https://via.placeholder.com/250x500.png?text=Profile+%26+Streaks" alt="Profile" width="200"/>
</div>

---

## 🚀 Comprehensive Feature Breakdown

Because of the massive scale of this application, features are broken down into core domain modules:

### 🎮 The Game & Curriculum Engine

- **100+ Game Modes:** Unique UI and logic for vocabulary, grammar, pronunciation, typing, matching, and listening comprehension.
- **60,000+ Challenges:** A dynamically loaded curriculum supporting up to 200 levels per game mode.
- **Real-time Lifecycle Management:** Games automatically pause and resume based on the device's foreground/background state via a custom `AppLifecycleHandler`.
- **Haptic & Audio Feedback:** Context-aware haptics and sound effects for correct/incorrect answers, managed centrally.

### 🗣️ Audio & Speech Processing

- **On-Device Speech Recognition:** Real-time voice parsing for pronunciation and speaking exercises.
- **Text-to-Speech (TTS):** Native TTS integration for listening comprehension games.

### 🏆 Progression & Gamification

- **XP & Leveling System:** Granular tracking of user experience points, automatically recalculating user levels.
- **Daily Streaks:** Complex timezone-aware streak tracking to drive user retention.
- **Achievements & Badges:** Unlockable digital assets based on user milestones.

### 🛡️ Kids Zone & Parental Controls

- **Dedicated Kids UI:** A simplified, distraction-free interface for younger learners.
- **COPPA-Compliant Parental Gate:** Complex, randomized math equations protect settings, external links, and IAP, ensuring kids cannot make unauthorized purchases.

### 💳 Monetization & Economy

- **Dual Monetization Strategy:** AdMob integrations (Banners/Interstitials) paired with Premium Subscriptions.
- **In-App Purchases (IAP):** Native Google Play Billing integration supporting recurring subscriptions and one-time coin packs.
- **Razorpay Integration:** Alternative payment gateway tailored for the Indian market.

---

## 🏗️ Core Architecture & Engineering

Managing 100k+ LOC requires rigorous architectural patterns to prevent tech debt and spaghetti code. Vowl utilizes industry-standard paradigms:

### 1. Advanced Mixin-Based Screen Architecture

To support 60+ unique game screens without duplicating core logic, Vowl uses a deeply generic `GameScreenMixin<T>` architecture.

- **DRY Principle:** Handles timer ticks, score tracking, lifecycle pausing, and haptics in one central place.
- **Feature Mixins:** Screens compose functionality via `with GameScreenMixin<Widget>, GrammarFeatureMixin`.

### 2. Strict State Management (BLoC)

- **100% BLoC Pattern:** UI components are completely stateless regarding business logic. All events (e.g., `SubmitAnswerEvent`, `PauseGameEvent`) flow through BLoCs, emitting immutable States.
- **0-Error Codebase:** Rigorous adherence to Dart static analysis ensures 0 errors and 0 warnings across the entire 1,000+ file project.

### 3. Dependency Injection (DI)

- **`get_it` Service Locator:** All repositories, network clients, and local storage managers are injected, making the codebase highly testable and decoupled.

### 4. High-Performance UI Rendering

- **Custom `MeshGradientBackground`:** Instead of relying on heavy image assets or expensive layout calculations, Vowl uses low-level `CustomPainter` to draw animated mesh gradients. By batching `canvas.drawPoints` and stripping dynamic memory allocations, the app achieves a locked **60fps** during complex animations.
- **Release-Mode Optimization:** Over 100+ `debugPrint` statements are strictly guarded by `if (kDebugMode)` to prevent string interpolation memory overhead in production builds.

---

## 🔒 Security & Backend Infrastructure

Vowl's backend relies on a **Zero-Trust Security Model** hosted on Firebase.

### 1. Server-Side IAP Validation (Node.js)

- **Anti-Piracy:** Client-side purchase spoofing is physically impossible. When a user buys Premium, the token is sent to a custom Node.js Firebase Cloud Function (`validateIAPReceipt`).
- **Google Play Server Auth:** The Cloud Function securely authenticates with Google's servers to verify the receipt before granting Premium status in Firestore.

### 2. Firestore & Storage Security Rules

- **Resource Locking:** Users can strictly only read and write their own documents (`request.auth.uid == resource.id`).
- **Anti-Cheat Validation:** Rules validate data payloads (e.g., ensuring `XP` increments are within reasonable mathematical bounds) to prevent client-side memory injection cheating.
- **Rate Limiting:** Global read/write limits applied at the security rule level.

---

## 📂 Codebase Structure

The project follows a highly modular, feature-first structure:

```text
lib/
 ├── core/
 │    ├── presentation/      # Shared Mixins, Base Widgets (e.g., GameScreenMixin)
 │    ├── theme/             # Global AppTheme, AppDimensions, Colors
 │    └── utils/             # Helpers, Lifecycle handlers
 ├── features/
 │    ├── auth/              # OAuth, Email Login, Legal Consents
 │    ├── home/              # Dashboards, Category Shelves
 │    ├── games/             # The 100+ Game Modes (Vocab, Grammar, Math)
 │    ├── kids_zone/         # Parental Gate, Kids UI
 │    ├── profile/           # Streaks, Leaderboards, Settings
 │    └── monetization/      # IAP Repositories, Paywalls
 ├── config/                 # Environment Variables, Keys
 └── main.dart               # App Entrypoint & DI Setup
extensions/                  # Infrastructure-as-Code for Firebase Extensions
 └── delete-user-data.env    # Safe, non-secret configuration (Firebase Best Practice)
functions/
 ├── index.js                # Node.js Server-Side Purchase Validation
 └── package.json            # Node Dependencies (googleapis, firebase-admin)
```

> **Note on Infrastructure-as-Code:** The `extensions/` directory is safely committed to source control following Firebase's modern "Extensions-as-Code" architecture. It contains structural configuration parameters (like Firestore deletion paths) and no sensitive secrets, ensuring infrastructure reproducibility across environments.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (`stable` channel)
- Firebase CLI installed and authenticated
- Google Play Console Developer Account (for IAP testing)

### Installation

1. **Clone the repo:**

   ```bash
   git clone https://github.com/ansar7787/vowl-app.git
   cd vowl-app
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Setup Firebase:**
   Ensure you have `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in their respective directories.

4. **Deploy Cloud Functions (Optional but required for IAP):**

   ```bash
   cd functions
   npm install
   firebase deploy --only functions:validateIAPReceipt
   ```

5. **Run the app:**

   ```bash
   flutter run
   ```

---

## 📄 Legal & Compliance

This application includes fully compliant, production-ready legal documentation hosted externally via GitHub Pages to allow web-based access for App Store compliance:

- [Privacy Policy](https://ansar7787.github.io/vowl-legal/privacy.html)
- [Terms of Service](https://ansar7787.github.io/vowl-legal/terms.html)
- [Refund Policy](https://ansar7787.github.io/vowl-legal/refund.html)

---

<p align="center">Designed, Engineered & Developed by <b>Ansar</b></p>
