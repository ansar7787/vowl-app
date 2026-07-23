# Vowl ML Features Guide

This document outlines the **7 Google ML Kit features** integrated into the Vowl application. Because these features run entirely on-device, they are incredibly fast, work 100% offline, and cost absolutely nothing in API fees.

Here is the complete breakdown of all 7 features, why they are useful, where they are used, and how you can test them.

---

## 1. Offline Translation (`google_mlkit_translation`)
*   **How it is Useful:** Learning English can be frustrating when you encounter a word you just can't figure out. This feature allows adult learners to instantly translate a difficult English word or sentence into their native language (Spanish, French, Hindi, etc.) without having to leave the app and open Google Translate. It lowers the frustration barrier significantly.
*   **Where it is Used:** Embedded in the **Translate Icon Button** across the Vocabulary, Grammar, and Elite Mastery game screens. 
*   **How to Play/Check it:** Tap the Translate icon on a game screen. The first time you tap it, it will show a download sheet (downloading the ~30MB offline language model). Every time after that, tapping the button will instantly pop up the translated text at the bottom of the screen.

## 2. Digital Ink Recognition (`google_mlkit_digital_ink_recognition`)
*   **How it is Useful:** This is a revolutionary feature for children. Instead of just tracing a static line, the AI actually *reads* what the child writes with their finger. It evaluates the child's finger strokes and determines if they actually wrote the correct letter (e.g., an "A"). This is incredibly powerful for teaching real motor skills and handwriting.
*   **Where it is Used:** Used exclusively in the **Kids Zone Handwriting Game** (`KidsHandwritingLayout`).
*   **How to Play/Check it:** Open the Kids Zone and enter Handwriting Level 1 (The Alphabet). Draw the letter "A" on the canvas. The engine will process your finger strokes in real-time and trigger a success animation if it detects you wrote a valid "A".

## 3. Image Labeling (`google_mlkit_image_labeling`)
*   **How it is Useful:** Image labeling allows the app to identify real-world objects in a photo! A learner can take a picture of a chair, an apple, or a dog, and the ML engine will instantly identify it and provide the English vocabulary word ("Chair", "Apple", "Dog"). This turns the entire real world into an interactive vocabulary game.
*   **Where it is Used:** Powers the **Photo Vocabulary** and **Scan & Learn** screens.
*   **How to Play/Check it:** Open the Photo Vocabulary tool, point the camera at a common object (like a coffee cup), and snap a photo. The engine should instantly return a list of labels (e.g., `Coffee cup`, `Mug`, `Drink`) which the app uses to teach you the English words for those objects.

## 4. Smart Reply (`google_mlkit_smart_reply`)
*   **How it is Useful:** When practicing conversation, learners often freeze up and don't know what to say. Smart Reply acts as an intelligent "Hint" system. If the AI avatar asks a question, Smart Reply reads the conversation history and instantly generates 3 natural English responses for the user to choose from.
*   **Where it is Used:** Belong in the **Roleplay & Dialogue Categories** (like the Job Interview, Medical Consult, or Social Spark games).
*   **How to Play/Check it:** When the AI asks a question (e.g., *"Where do you see yourself in 5 years?"*), the ML engine reads that history and will automatically pop up 3 contextually appropriate response buttons for you to either read aloud or tap.

## 5. Text Recognition / OCR (`google_mlkit_text_recognition`)
*   **How it is Useful:** Language learners struggle reading text in the real world. This feature allows users to open their camera, point it at a restaurant menu, a street sign, or a book, and the app will instantly extract the English text right off the real-world object! They can then tap the words to hear them spoken or translated.
*   **Where it is Used:** Used alongside Image Labeling in the **Scan & Learn** utility tool.
*   **How to Play/Check it:** Pass a static image (like a screenshot or a photo of a menu) into the camera scanner. The engine will accurately draw boxes around the words and extract the text strings perfectly into the app.

## 6. Language ID (`google_mlkit_language_id`)
*   **How it is Useful:** Sometimes a user might accidentally speak in their native language instead of English during a microphone game, or type in their native language. Instead of just coldly marking them "Incorrect", Language ID instantly detects what language they used. The app can then gently say: *"Oops! It sounds like you spoke in Spanish. Try saying it in English!"* 
*   **Where it is Used:** Works silently in the background during the **Microphone/Speech Service** or **Dialect Drill** games.
*   **How to Play/Check it:** Speak or type a phrase in another language (e.g., "Hola, como estas"). The ML engine will instantly return `es` (Spanish) with high confidence, and trigger the special helpful popup instead of a failure.

## 7. Entity Extraction (`google_mlkit_entity_extraction`)
*   **How it is Useful:** Entity Extraction automatically finds Dates, Addresses, Phone Numbers, and Money amounts inside a block of text. This is brilliant for dynamically generating reading comprehension quizzes! If a reading passage says *"The flight leaves on October 12th for $400"*, the engine instantly tags the date and the money, allowing the game to automatically quiz the user: *"How much did the flight cost?"*
*   **Where it is Used:** Powers the **Reading Comprehension** and **Detail Spotlight** listening games.
*   **How to Play/Check it:** Feed a sentence with a date and a price into the engine. It will instantly highlight them and correctly tag them as `TYPE_DATE` and `TYPE_MONEY`.
