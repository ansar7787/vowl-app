# Vowl Git Workflow & Safety Guide

**DO NOT DELETE THIS FILE.** This explains the split Git architecture designed to protect the Google Play Developer account from being banned via GitHub association.

## The Architecture

The repository has been split into two isolated branches to protect the real AdMob IDs and Google Play package name from Google's automated web-scraping bots.

### 1. master Branch (PRIVATE / PRODUCTION)

- **Status:** Local only. We intentionally deleted the remote master branch from the public internet.
- **Contents:** Contains the real package name (com.vowl.app), the real AdMob IDs, and the real Keystore.
- **Rule:** **NEVER** push this branch to a public GitHub repository.

### 2. portfolio Branch (PUBLIC / HR)

- **Status:** Pushed to nsar7787/vowl-app on GitHub.
- **Contents:** Contains a fake package name (com.vowl.portfolio) and Google test AdMob IDs.
- **Rule:** This branch is purely for HR, recruiters, and portfolio display.

## How to Work on Code (For the AI)

If the user asks you to build a new feature or push code, **always check which branch you are on** (git branch).

- Always write new features on the master branch.
- If the user explicitly wants to update their public portfolio for HR, switch to the portfolio branch, ensure no real AdMob IDs or com.vowl.app package names leak into it, and git push origin portfolio.
