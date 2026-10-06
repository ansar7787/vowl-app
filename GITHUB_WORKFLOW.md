# Vowl Git Workflow & Safety Guide

**DO NOT DELETE THIS FILE.** This explains the split Git architecture designed to protect the Google Play Developer account from being banned via GitHub association.

## The Architecture

The repository has been split into two isolated branches to protect the real AdMob IDs and Google Play package name from Google's automated web-scraping bots.

### 1. `master` Branch (PRIVATE / PRODUCTION)

- **Status:** Backed up to the PRIVATE repository (`vowl-official/vowl-app-private`).
- **Contents:** Contains the real package name (`com.vowl.app`), the real AdMob IDs, and the real Keystore.
- **Rule:** **NEVER** push this branch to a public GitHub repository.

### 2. `portfolio` Branch (PUBLIC / HR)

- **Status:** Pushed to PUBLIC repository (`ansar7787/vowl-app`) on GitHub.
- **Contents:** Contains a fake package name (`com.vowl.portfolio`) and Google test AdMob IDs.
- **Rule:** This branch is purely for HR, recruiters, and portfolio display.

---

## 🛠️ Your Day-to-Day Cheat Sheet (Step-by-Step)

When you wake up and want to code a new feature, just follow these 3 steps:

### Step 1: Check your branch
Before you write any code, make sure you are on the private production branch.
```bash
git checkout master
```

### Step 2: Write your code & test
Code your new feature, run it on your phone, and make sure it works!

### Step 3: Save and Backup (Private)
When your feature is finished, save it to your Private GitHub repository so you don't lose it:
```bash
git add .
git commit -m "feat: added a new cool feature"
git push private master
```

### (Optional) Step 4: Show it to HR
If the feature is amazing and you want recruiters to see it on your public GitHub, **do not merge it yourself.** 
Just open an AI chat and say: 
> *"Read GITHUB_WORKFLOW.md and safely copy my new feature over to the portfolio branch."*

The AI will handle the complicated merging to ensure your private AdMob IDs don't accidentally leak to the public!
