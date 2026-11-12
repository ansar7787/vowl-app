# Vowl ML Features Architecture Guide: The Lean Single-ML Engine

This document outlines the **Single-ML Engine Architecture** integrated into the Vowl application.

Following our comprehensive architectural review, Vowl operates on **`google_mlkit_translation`** as its sole ML Kit dependency, eliminating over 25MB to 32MB of binary overhead, 2.18MB of uncompressed asset curriculum JSONs, and 50MB to 80MB of runtime memory usage.

---

## 1. Active ML Engine: Offline Multi-Language Translation (`google_mlkit_translation`)

* **Purpose & Impact:** Allows language learners to instantly translate vocabulary words and sentences into their native language (Spanish, French, German, Hindi, Arabic, Tamil, etc.) with 100% offline capability and $0.00 cloud API costs.
* **Where it is Used:** Embedded in the **Offline Translator Suite** and accessible via the **Translate Icon Button** across Vocabulary, Grammar, and Elite Mastery game screens.
* **Capabilities:** Supports 50+ language pairs on-device. When first initialized, it downloads the compact offline language model and stores it securely on the device.

---

## 2. Purged & Retired Legacy Features (Architectural Changelog)

| Feature / Package | Reason for Retirement | Replaced By |
| :--- | :--- | :--- |
| **`google_mlkit_digital_ink_recognition`** & Handwriting | Heavy binary footprint, stroke evaluation friction, local fork dependency override debt | Natural UI interactive writing games & handwriting tracing with native canvas |
| **`google_mlkit_text_recognition`** & Scan & Learn | Heavy OCR binary bloat, unreliable indoor camera capture | High-density curated Reading & Skimming lessons with audio playback |
| **`google_mlkit_image_labeling`** & Photo Vocabulary | Vision classification ambiguity, camera dependency | Curated visual vocabulary & daily word accelerators (`DailyWordsService`) |
| **`google_mlkit_smart_reply`** | 100% redundant with authored dialogue curriculum synonyms | Structured quest accepted synonyms (`quest.acceptedSynonyms`) |
| **`google_mlkit_language_id`** | Only used for basic Latin/English verification in writing games | Ultra-fast native Unicode script regex validation (`GibberishDetectorService`) |
| **`google_mlkit_entity_extraction`** | 100% ghost code; registered in DI but never called by any screen | Completely purged with 0 impact |
| **Review Mistakes (`errorJournal`)** | Unnecessary Firestore write overhead on wrong answers; duplicated standard game retry loop | Native game session retry loops and in-memory error reviews |

---

## 3. Performance & Footprint Metrics

* **Google ML Kit Packages:** 1 (Retained `google_mlkit_translation: ^0.14.0`)
* **Local Package Debt:** 0 (`packages/google_mlkit_digital_ink_recognition` deleted)
* **Asset Curriculum Reduction:** ~2.18 MB JSON deleted
* **Estimated APK / IPA Reduction:** ~25 MB to 32 MB smaller
* **Device RAM Overhead:** Reduced by ~50 MB to 80 MB
* **Firestore Database Write Cost:** 100% error journal write costs eliminated
