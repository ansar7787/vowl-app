# 🦉 Vowl: AI-Powered English Mastery Adventure

![Vowl Banner](https://img.shields.io/badge/Vowl-Enterprise--Grade-blueviolet?style=for-the-badge&logo=appveyor)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![AI](https://img.shields.io/badge/AI-Powered-green?style=for-the-badge)
![CI/CD](https://github.com/ansar7787/vowl-app/actions/workflows/flutter_ci.yml/badge.svg)

**Vowl** is a premium educational platform designed to transform English language learning into an immersive adventure. Built with Flutter, powered by Google Gemini AI and Google ML Kit, Vowl offers a massive curriculum designed for both adults and children.

---

## 📸 Application Previews

*(Note to maintainer: Add 3-4 high-quality screenshots or a GIF of the app running here. Long scrolling screenshots of your UI are highly recommended!)*

<div align="center">
  <img src="https://via.placeholder.com/250x500.png?text=Home+Screen" width="200" />
  <img src="https://via.placeholder.com/250x500.png?text=Game+UI" width="200" />
  <img src="https://via.placeholder.com/250x500.png?text=Kids+Zone" width="200" />
</div>

---

## 💎 The Vowl Feature Matrix

Vowl is not just an app; it is a full-scale enterprise platform. Here is a deep dive into the features powering the application:

### 🧠 Advanced Artificial Intelligence & Machine Learning
- **Google Gemini AI Integration**: Dynamic generation of roleplays, stories, and context-aware feedback.
- **On-Device ML Kit**: 
  - **Digital Ink Recognition**: Hand-writing recognition for the Kids Zone.
  - **Real-time Translation & Language ID**: Instant support for users in their native language.
  - **Smart Reply & Text Recognition**: Advanced context-aware text processing.
- **Speech & Audio Processing**: 
  - Real-time **Speech-to-Text** for pronunciation grading.
  - Natural **Text-to-Speech (TTS)** for listening exercises and interactive mascots.

### 🏛️ Enterprise-Grade Architecture
- **State Management**: Highly scalable, strictly decoupled architecture using `flutter_bloc`, `get_it`, and `dartz` (Functional Programming).
- **Navigation**: Deep-link ready routing powered by `go_router`.
- **CI/CD Pipeline**: Fully automated GitHub Actions workflow (`flutter analyze`, `flutter test`) ensuring zero broken builds in `master`.
- **Responsive UI**: Pixel-perfect scaling across all devices using `flutter_screenutil`.

### 🛡️ Security & Production Hardening
- **Root & Jailbreak Detection**: Utilizes `safe_device` to prevent execution on compromised devices, protecting the in-app economy.
- **Firebase App Check**: Hardened backend security ensuring only the official Vowl app can access Firestore.
- **Robust Firestore Security Rules**: Strict read/write validation at the database level.
- **Debounce Protection**: Global debouncing on all critical UI interactions to prevent double-spending or rapid-fire crashes.

### 🎛️ Backend & Monetization Engine
- **Firebase Ecosystem Ecosystem**:
  - **Firestore & Cloud Functions**: Atomic transactions and scalable cloud logic.
  - **Remote Config**: Real-time balance tuning, AB testing, and feature flags without app updates.
  - **Crashlytics & Analytics**: Deep telemetry for 99.9% crash-free sessions.
  - **Cloud Messaging**: Push notifications for daily streaks and challenges.
- **Monetization**:
  - Integrated **Razorpay** for seamless premium subscription processing.
  - **Google Mobile Ads** integration for rewarded learning loops.

### ✨ "Diamond Standard" User Experience
- **Sensory Feedback**: High-fidelity `haptic_feedback` and immersive `audioplayers` soundscapes.
- **Fluid Animations**: Complex micro-interactions built with `flutter_animate`, `lottie`, and `confetti`.
- **Custom UI**: Glassmorphism, mesh gradients, and highly polished custom widgets.

---

## 🎭 Massive Pedagogical Curriculum

Vowl contains a meticulously structured local JSON curriculum of **20,000+ levels**, covering:
- **Grammar Architect**: Interactive tree-based learning for complex structures.
- **Speaking Studio**: AI speech recognition for pronunciation and fluency.
- **Roleplay Arena**: Dynamic AI scenarios for real-world conversation practice.
- **Vocabulary & Flashcards**: High-speed recall training with context-aware hints.
- **Elite Mastery**: The ultimate challenge for advanced adult learners.

---

## 🧒 The Kids Zone

A vibrant, tailored environment for young minds featuring 22 unique game types (Colors, Phonics, Handwriting, Math, and more!):
- **🦉 Smart Mascots**: Interactive buddies (Owly, Panda) that guide the learning journey.
- **🎒 Buddy Boutique**: Full accessory system for equipping earned gear.
- **🎨 Sticker Album**: 80+ unique holographic stickers to collect.

---

## 🏗️ Getting Started

### Prerequisites
- Flutter SDK (`^3.10.7`)
- Node.js (Only required for running backend data-generation scripts)

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
3.  **Install Script Dependencies**:
    *Note: The `package.json` in the root directory is strictly used for data-generation and utility scripts located in the `scripts/` folder, NOT for the core Flutter application.*
    ```bash
    npm install
    ```
4.  **Environment Setup**: 
    Create `.env` from `.env.template` and add your Firebase/Gemini keys.
5.  **Run the App**: 
    ```bash
    flutter run --release
    ```

---
**Developed with ❤️ by the Vowl Team.**
