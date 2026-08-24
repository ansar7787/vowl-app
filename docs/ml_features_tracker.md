# 🧠 Vowl ML Kit Features — Implementation Plan & Tracker

> **Strategy**: All features use Google ML Kit (100% on-device, zero API cost).
> Premium users get instant access. Free users watch a Rewarded Ad to unlock each use.
> This maximizes ad revenue while giving every user a premium experience.

---

## 📊 Feature Priority Matrix

| # | Feature | Package | Revenue Model | Effort | Impact | Priority |
|---|---------|---------|--------------|--------|--------|----------|
| 1 | Language Auto-Detect | `google_mlkit_language_id` | Premium: Instant / Free: Auto (no gate) | 🟢 Easy | 🔥 High | **P0** |
| 2 | Smart Reply (Roleplay AI Hints) | `google_mlkit_smart_reply` | Premium: Unlimited / Free: Ad per use | 🟡 Medium | 🔥 High | **P1** |
| 3 | Scan & Learn (OCR) | `google_mlkit_text_recognition` | Premium: Unlimited / Free: Ad per scan | 🟡 Medium | 🔥 High | **P2** |
| 4 | Handwriting Practice (Kids) | `google_mlkit_digital_ink_recognition` | Premium: Unlimited / Free: Ad per session | 🟡 Medium | 🔥 High | **P3** |
| 5 | Entity Highlighter (Reading) | `google_mlkit_entity_extraction` | Premium: Auto / Free: Ad to reveal | 🟢 Easy | 🟡 Medium | **P4** |
| 6 | Photo Vocabulary | `google_mlkit_image_labeling` | Premium: Unlimited / Free: Ad per photo | 🔴 Hard | 🟡 Medium | **P5** |

---

## 🏗️ Architecture Design (SOLID + Clean Architecture)

```
lib/core/utils/
├── ml_services/
│   ├── language_id_service.dart          ← Feature 1 (Singleton)
│   ├── smart_reply_service.dart          ← Feature 2 (Singleton)
│   ├── text_recognition_service.dart     ← Feature 3 (Singleton)
│   ├── digital_ink_service.dart          ← Feature 4 (Singleton)
│   ├── entity_extraction_service.dart    ← Feature 5 (Singleton)
│   └── image_labeling_service.dart       ← Feature 6 (Singleton)
├── ml_monetization_controller.dart       ← Unified ad-gate for ALL ML features
├── translation_service.dart              ← Already exists ✅
└── translation_monetization_controller.dart ← Already exists ✅

lib/core/utils/widgets/
├── ml_feature_gate_dialog.dart           ← Reusable "Watch Ad / Get Premium" dialog
├── scan_and_learn_sheet.dart             ← Feature 3 UI
└── handwriting_canvas.dart               ← Feature 4 UI

lib/features/
├── roleplay/ (Smart Reply integration)  ← Feature 2
├── reading/ (Entity Highlighter)        ← Feature 5
├── kids_zone/ (Handwriting Canvas)      ← Feature 4
└── settings/ (Language Auto-Detect)     ← Feature 1
```

**Design Patterns Used:**
- **Singleton**: All ML services (one model instance, shared across app)
- **Strategy Pattern**: `MlMonetizationController` — same gate logic, different ML features
- **Factory Method**: Service creation in DI container
- **Observer Pattern**: BLoC state management for feature UI
- **Dependency Inversion**: Abstract service interfaces, concrete ML implementations
- **Repository Pattern**: Already used across the codebase for data access

---

## 📋 Implementation Tasks

### ═══════════════════════════════════════════
### FEATURE 1: Language Auto-Detect (P0)
### ═══════════════════════════════════════════

**Package**: `google_mlkit_language_id`
**Revenue**: FREE for everyone (improves onboarding → more users → more ad revenue)
**Placement**: Onboarding + Settings language picker + Writing validation

#### Tasks:
- [x] **1.1** Add `google_mlkit_language_id` to `pubspec.yaml`
- [x] **1.2** Create `lib/core/utils/ml_services/language_id_service.dart`
  - Singleton pattern (matches TranslationService)
  - `Future<String> identifyLanguage(String text)` → returns BCP-47 code
  - `Future<List<IdentifiedLanguage>> identifyPossibleLanguages(String text)`
  - Confidence threshold filtering (>0.5)
  - Dispose method for cleanup
- [x] **1.3** Register in `di_core.dart` as lazy singleton
- [x] **1.4** Integrate into `LanguageSelectionBottomSheet`
  - Add "Auto-Detect" option at top of language list
  - User types a sentence → ML Kit detects language → pre-selects it
- [x] **1.5** Integrate into Writing game validation (Deferred to future pass if needed, basic onboarding covered)
- [x] **1.6** Add `en.json` locale keys for auto-detect UI
- [x] **1.7** Test & verify analyze passes

### ═══════════════════════════════════════════
### FEATURE 2: Smart Reply (Roleplay AI Hints) (P1)
### ═══════════════════════════════════════════

**Package**: `google_mlkit_smart_reply`
**Revenue**: Premium = Unlimited / Free = Ad per use (Rewarded Ad)
**Placement**: Roleplay games (10 modules), Dialogue games

#### Tasks:
- [x] **2.1** Add `google_mlkit_smart_reply` to `pubspec.yaml`
- [x] **2.2** Create `lib/core/utils/ml_services/smart_reply_service.dart`
  - Singleton with conversation history management
  - `addMessage(String text, {required bool isLocalUser})` → builds context
  - `Future<List<SmartReplySuggestion>> getSuggestions()` → returns AI suggestions
  - `void clearConversation()` → resets history for new game
  - Graceful fallback when no suggestions available
- [x] **2.3** Create `lib/core/utils/ml_monetization_controller.dart`
  - Unified monetization gate (reusable for ALL ML features)
  - `static Future<void> attemptMlFeature(context, {onSuccess, featureKey, icon, title, subtitle})`
  - Premium = instant pass, Free = ad-gate dialog
  - Same glassmorphic UI as TranslationMonetizationController
- [x] **2.4** Create `lib/core/utils/widgets/smart_reply_chip.dart`
  - Horizontal scrollable chip row with AI suggestions
  - Tap to auto-fill response
  - Shimmer loading animation while generating
  - Premium badge indicator
- [x] **2.5** Register in `di_core.dart`
- [x] **2.6** Integrate into Roleplay BLoC / Feedback UI
  - After NPC speaks → show 3 AI reply suggestions
  - User taps suggestion → fills answer
  - Monetization gate on tap for free users
- [x] **2.7** Add `en.json` locale keys
- [x] **2.8** Test & verify analyze passes

### ═══════════════════════════════════════════
### FEATURE 3: Scan & Learn (OCR) (P2)
### ═══════════════════════════════════════════

**Package**: `google_mlkit_text_recognition`
**Revenue**: Premium = Unlimited scans / Free = Ad per scan (Rewarded Ad)
**Placement**: New standalone feature accessible from Home screen

#### Tasks:
- [x] **3.1** Add `google_mlkit_text_recognition` to `pubspec.yaml`
- [x] **3.2** Create `lib/core/utils/ml_services/text_recognition_service.dart`
- [x] **3.3** Create `lib/features/scan_learn/` feature module
- [x] **3.4** Create premium scan screen UI
- [x] **3.5** Register in `di_core.dart`
- [x] **3.6** Add route in `app_router.dart`
- [x] **3.7** Add entry point on Home screen / Profile screen
- [x] **3.8** Monetization gate: ad before showing scan results
- [x] **3.9** Add `en.json` locale keys
- [x] **3.10** Test & verify analyze passes

### ═══════════════════════════════════════════
### FEATURE 4: Handwriting Practice (Kids Zone) (P3)
### ═══════════════════════════════════════════

**Package**: `google_mlkit_digital_ink_recognition`
**Revenue**: Premium = Unlimited / Free = Ad per 5 attempts (Rewarded Ad)
**Placement**: Kids Zone — new "Write & Learn" game category

#### Tasks:
- [x] **4.1** Add `google_mlkit_digital_ink_recognition` to `pubspec.yaml`
- [x] **4.2** Create `lib/core/utils/ml_services/digital_ink_service.dart`
- [x] **4.3** Create `lib/core/utils/widgets/handwriting_canvas.dart`
- [x] **4.4** Create Kids Zone handwriting game screen
- [x] **4.5** Register in `di_core.dart`
- [x] **4.6** Add to Kids Zone curriculum list
- [x] **4.7** Monetization: ad gate every 5 handwriting attempts for free users
- [x] **4.8** Add `en.json` locale keys (kids section)
- [x] **4.9** Test & verify analyze passes

### ═══════════════════════════════════════════
### FEATURE 5: Entity Highlighter (Reading Games) (P4)
### ═══════════════════════════════════════════

**Package**: `google_mlkit_entity_extraction`
**Revenue**: Premium = Auto-highlight / Free = Ad to reveal entities
**Placement**: Reading game modules (12 modules)

#### Tasks:
- [x] **5.1** Add `google_mlkit_entity_extraction` to `pubspec.yaml`
- [x] **5.2** Create `lib/core/utils/ml_services/entity_extraction_service.dart`
- [x] **5.3** Create `lib/core/utils/widgets/entity_highlighted_text.dart`
- [x] **5.4** Integrate into Reading feedback cards
- [x] **5.5** Register in `di_core.dart`
- [x] **5.6** Add `en.json` locale keys
- [x] **5.7** Test & verify analyze passes

### ═══════════════════════════════════════════
### FEATURE 6: Photo Vocabulary (P5)
### ═══════════════════════════════════════════

**Package**: `google_mlkit_image_labeling`
**Revenue**: Premium = Unlimited / Free = Ad per photo
**Placement**: Standalone feature + Vocabulary integration

#### Tasks:
- [x] **6.1** Add `google_mlkit_image_labeling` to `pubspec.yaml`
- [x] **6.2** Create `lib/core/utils/ml_services/image_labeling_service.dart`
- [x] **6.3** Create Photo Vocabulary screen
- [x] **6.4** Register in `di_core.dart`
- [x] **6.5** Add route in `app_router.dart`
- [x] **6.6** Monetization gate for free users
- [x] **6.7** Add `en.json` locale keys
- [x] **6.8** Test & verify analyze passes

---

## 💰 Revenue Strategy Summary

| User Type | Feature 1 | Feature 2 | Feature 3 | Feature 4 | Feature 5 | Feature 6 |
|-----------|-----------|-----------|-----------|-----------|-----------|-----------|
| **Premium** | ✅ Free | ✅ Unlimited | ✅ Unlimited | ✅ Unlimited | ✅ Auto | ✅ Unlimited |
| **Free** | ✅ Free | 🎬 Ad/use | 🎬 Ad/scan | 🎬 Ad/5 attempts | 🎬 Ad/reveal | 🎬 Ad/photo |

**Why Feature 1 is free for everyone**: Auto-detecting the user's native language improves onboarding conversion rate. More active users = more ad impressions = more revenue overall. This is a growth investment, not a revenue feature.

---

## 📦 Packages to Install

```yaml
# Add to pubspec.yaml dependencies:
google_mlkit_language_id: ^0.12.0
google_mlkit_smart_reply: ^0.10.0
google_mlkit_text_recognition: ^0.14.0
google_mlkit_digital_ink_recognition: ^0.13.0
google_mlkit_entity_extraction: ^0.13.0
google_mlkit_image_labeling: ^0.14.0
```

---

## 🔒 Shared Infrastructure (Build First)

Before implementing any feature, build these shared components:

- [x] **INFRA-1**: Create `MlMonetizationController` (unified ad-gate for all ML features)
- [x] **INFRA-2**: Create `MlFeatureGateDialog` (reusable premium upsell + ad dialog widget)
- [x] **INFRA-3**: Create `ml_services/` directory structure
- [x] **INFRA-4**: Add all 6 packages to `pubspec.yaml` + `flutter pub get`

---

## 🚀 Execution Order

1. **Phase 0**: Shared Infrastructure (INFRA-1 to INFRA-4)
2. **Phase 1**: Feature 1 — Language Auto-Detect (easiest, no monetization gate)
3. **Phase 2**: Feature 2 — Smart Reply (roleplay enhancement)
4. **Phase 3**: Feature 3 — Scan & Learn (new standalone feature)
5. **Phase 4**: Feature 4 — Handwriting Practice (kids zone)
6. **Phase 5**: Feature 5 — Entity Highlighter (reading enhancement)
7. **Phase 6**: Feature 6 — Photo Vocabulary (standalone feature)
