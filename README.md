# Growtrics Full-Stack Assessment Repository

This repo contains the solution to the Growtrics take-home assignment: a **Flutter** application backed by a **Flask + Firebase** service that solves mathematics homework problems using LLMs.

```
.
├── src/
│   ├── score-ai-backend/                    # Flask code
│   └── score-ai-app/                        # Flutter project
│
├── behavioural_questions.md        # Answers to behavioural questions
├── README.md                       # You are here
```

> Detailed technical roadmaps are documented in:
>
> • `score-ai-backend/README.md`
> • `score-ai-app/README.md`

## Quick Start

### Prerequisites
- Python 3.12
- Flutter 3.22 (stable)
- Firebase CLI (`npm i -g firebase-tools`)
- Docker (for local services)

### Backend (local dev)
```bash
cd score-ai-backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export FLASK_ENV=development
flask --app app run -p 5000
```

### Mobile App
```bash
cd score-ai-app
flutter pub get
flutter run
```

## Demo
FE: https://score-ai-65bd7.web.app/
BE: https://api-hprsya2ljq-uc.a.run.app
Mobile (Demo): 
## Features

### User Authentication
- **Get Profile**: Retrieve the current user's profile information.

### Homework Analysis
- **Upload & Solve**: Upload a file (e.g., an image of a math problem) to be solved by the AI.
- **Get Job List**: Retrieve a list of all analysis jobs submitted by the user.
- **Get Job Solution**: Fetch the detailed solution for a specific job.
- **Delete Jobs**: Delete a specific job or all jobs for a user.

### AI-Powered Chat
- **Explain Solution**: Ask the AI for a detailed explanation of a specific question from a solved job. The chat is streamed to provide a real-time experience. 