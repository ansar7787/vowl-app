# Ultimate Deep Curriculum Content & Manual Audit Report

This is a deep, rigorous programmatic audit of all **2,440 JSON batch files** containing **73,200 curriculum questions** across the SpeakPay / Fluentify application.

## 1. Metrics & Quality Gate Check

| Quality Check | Result Status | Errors Found |
| :--- | :--- | :--- |
| **JSON Integrity Check** | 🟢 PASS (100% Malformed-Free) | 0 |
| **Whitespace & Schema Validation** | 🟢 PASS (0 Whitespace Gaps) | 0 |
| **Generator Placeholders Check** | 🟢 PASS (0 Temp Strings) | 0 |
| **Index Bounds & Range Integrity** | 🟢 PASS (0 Index Exceptions) | 0 |
| **Options/Choice Uniqueness** | 🟢 PASS (0 Duplicate Options) | 0 |
| **Brackets & Markdown Sanity** | 🟢 PASS (0 Unclosed Brackets) | 0 |
| **Link & Match Pair Validation** | 🟢 PASS (0 Malformed Pairs) | 0 |
| **Character & Encoding Corruption** | 🟢 PASS (0 Corrupted Chars) | 0 |
| **Semantic Question Uniqueness** | 🟡 WARNING | 18017 |

---

## 2. Details of Issues Found

### Semantic Duplicate Questions (18017)

- **Text**: "next door"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L104_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "ten cards"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L104_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "good boy"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L102_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L105_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "media event"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L102_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L106_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "law and order"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L106_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "don't you"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L106_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "white paper"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L107_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "last night"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L104_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L107_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "next door"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L107_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "ten cards"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L108_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "good boy"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L102_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L108_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "media event"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L102_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L109_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "law and order"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L109_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "don't you"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L110_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "white paper"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L110_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "last night"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L104_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L110_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
- **Text**: "next door"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L111_Q1` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "ten cards"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L111_Q2` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "good boy"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L102_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L112_Q1` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "media event"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L102_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L112_Q3` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "law and order"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L113_Q1` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "don't you"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L113_Q2` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "white paper"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L113_Q3` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "last night"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L104_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L114_Q1` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "next door"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L114_Q2` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "ten cards"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L114_Q3` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "good boy"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L102_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L115_Q2` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "media event"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L102_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L116_Q1` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "law and order"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L116_Q2` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "don't you"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L116_Q3` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "white paper"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L117_Q1` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "last night"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L104_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L117_Q2` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "next door"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L117_Q3` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "ten cards"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L118_Q1` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "good boy"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L102_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L118_Q3` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "media event"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L102_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L119_Q2` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "law and order"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L119_Q3` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "don't you"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L120_Q1` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "white paper"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L120_Q2` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "last night"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L104_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L120_Q3` in [connectedSpeech_111_120.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_111_120.json)
- **Text**: "next door"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L11_Q1` in [connectedSpeech_11_20.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_11_20.json)
- **Text**: "ten cards"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L11_Q2` in [connectedSpeech_11_20.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_11_20.json)
- **Text**: "good boy"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L102_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L12_Q1` in [connectedSpeech_11_20.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_11_20.json)
- **Text**: "media event"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L102_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L12_Q3` in [connectedSpeech_11_20.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_11_20.json)
- **Text**: "law and order"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L13_Q1` in [connectedSpeech_11_20.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_11_20.json)
- **Text**: "don't you"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L13_Q2` in [connectedSpeech_11_20.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_11_20.json)
- **Text**: "white paper"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L103_Q3` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L13_Q3` in [connectedSpeech_11_20.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_11_20.json)
- **Text**: "last night"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L104_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L14_Q1` in [connectedSpeech_11_20.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_11_20.json)
- **Text**: "next door"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q1` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L14_Q2` in [connectedSpeech_11_20.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_11_20.json)
- **Text**: "ten cards"
  - *Occurrence 1*: ID `ACC_CONNECTEDSPEECH_L101_Q2` in [connectedSpeech_101_110.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_101_110.json)
  - *Occurrence 2*: ID `ACC_CONNECTEDSPEECH_L14_Q3` in [connectedSpeech_11_20.json](file:///C:\Users\asus\Documents\App Projects\vowl\assets\curriculum\accent\connectedSpeech_11_20.json)

*(Showing first 50 semantic duplicates out of 18017)*
