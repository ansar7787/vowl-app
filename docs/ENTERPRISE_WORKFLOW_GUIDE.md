# Enterprise Git Workflow & CI/CD Guide

This guide is designed to help you transition from a "solo developer" mindset to an "enterprise team engineer" mindset. If an interviewer asks you how you work with Git or how your team ensures code quality, you will use the concepts in this document.

---

## Part 1: The Enterprise Git Workflow (Branches & PRs)

**Why Companies Do This:** 
In a real company, 5 to 50 developers might be working on the exact same app. If everyone pushed directly to `master`, the code would break constantly. Instead, companies use **Branches** and **Pull Requests (PRs)** to ensure code is reviewed and tested *before* it goes live.

### Step-by-Step Workflow:

1. **Get the latest code:**
   Always start by making sure your local `master` is up to date.
   ```bash
   git checkout master
   git pull origin master
   ```

2. **Create a Feature Branch:**
   Never code on `master`. Create a branch specifically for the feature or bug you are working on.
   ```bash
   git checkout -b feature/flashcard-ui-fix
   ```
   *(Note: Use `feature/` for new things, and `fix/` or `bugfix/` for fixing things).*

3. **Write Code and Commit:**
   Make your changes in your IDE, then commit them to your branch.
   ```bash
   git add .
   git commit -m "feat: updated flashcard ui layout"
   ```

4. **Push the Branch to GitHub:**
   Push your specific branch to the remote repository.
   ```bash
   git push origin feature/flashcard-ui-fix
   ```

5. **Create a Pull Request (PR):**
   Go to GitHub.com. You will see a green button that says "Compare & pull request". Click it. This tells your team: *"Hey, I finished this feature. Please review my code before we merge it into master."*

6. **Merge and Delete:**
   Once the team (or just you, if solo) approves the PR, you click "Merge". Then you delete the branch and start over at Step 1 for the next feature.

---

## Part 2: CI/CD (Continuous Integration / Continuous Deployment)

**What is it?**
CI/CD is an automated robot that checks your code. Every time you push code or make a Pull Request, the CI/CD pipeline runs. 

**Is it free?**
Yes! **GitHub Actions** is completely free for public repositories. For private repositories, GitHub gives you 2,000 free minutes per month, which is more than enough for a solo developer or small team.

**How we set it up in VOWL:**
We created a file at `.github/workflows/flutter_ci.yml`. 
Every time a commit is pushed, GitHub Actions automatically starts a virtual Ubuntu server, installs Flutter, and runs:
1. `flutter analyze` (To check for messy code or bad habits)
2. `flutter test` (To run all your automated tests)

If either of these fail, the robot puts a big **RED X** on your Pull Request, preventing you from merging broken code into `master`.

---

## Part 3: How to Answer Interview Questions

**Question:** *"Are you comfortable working on a team using version control?"*
**Your Answer:** *"Absolutely. Even when developing Vowl independently, I adhered to strict enterprise workflows. I never push directly to master. I use feature branches, write semantic commit messages, and open Pull Requests. I also built a CI/CD pipeline using GitHub Actions that automatically runs `flutter analyze` and `flutter test` on every PR to ensure code quality before merging."*

**Question:** *"Have you ever used CI/CD pipelines?"*
**Your Answer:** *"Yes, I integrated GitHub Actions into the Vowl repository. It serves as our Continuous Integration layer. On every push and pull request, the pipeline automatically checks out the code, sets up the Flutter environment, and runs static analysis and widget tests. It guarantees that our `master` branch is always stable and production-ready."*
