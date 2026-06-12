# 🌿 ActiveGlow Skincare — Skye AI Chatbot

> **Full-stack AI chatbot** | FastAPI · Google Gemini · MongoDB · Flutter

A production-ready, cross-platform AI chat assistant for ActiveGlow Skincare, powered by Google Gemini and built with FastAPI (backend) and Flutter (frontend). Skye answers customer questions about skincare products, routines, and policies — and politely refuses anything outside her domain.

---

## 📁 Project Structure

```
activeglow_project/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py           ← FastAPI app + routes
│   │   ├── chat_handler.py   ← Gemini integration + system prompt builder
│   │   ├── memory_manager.py ← MongoDB / in-memory conversation history
│   │   ├── models.py         ← Pydantic request/response models
│   │   └── config.py         ← Environment variable config
│   ├── knowledge_base.txt    ← Industrial-level brand knowledge base
│   ├── requirements.txt
│   ├── .env.example
│   ├── Dockerfile
│   └── docker-compose.yml
│
└── flutter/
    ├── lib/
    │   ├── main.dart
    │   ├── config/constants.dart    ← Theme, colors, API URL
    │   ├── models/message_model.dart
    │   ├── services/chat_api_service.dart  ← HTTP calls to backend
    │   ├── screens/chat_screen.dart        ← Main chat UI + logic
    │   └── widgets/
    │       ├── message_bubble.dart         ← User & bot bubbles
    │       ├── chat_input_field.dart       ← Input + send button
    │       └── typing_indicator.dart       ← Animated dots
    └── pubspec.yaml
```

---

## 🛠️ Tech Stack

| Layer        | Technology                          |
|--------------|-------------------------------------|
| LLM          | Google Gemini 1.5 Flash             |
| Backend      | Python 3.11 + FastAPI + Uvicorn     |
| Memory       | MongoDB (Motor async) + in-memory fallback |
| Frontend     | Flutter 3.x (iOS, Android, Web)     |
| Deployment   | Railway.app / Render (backend) + Firebase Hosting (web) |

---

## ⚡ Local Setup — Backend

### Prerequisites
- Python 3.11+
- A Google Gemini API key → https://aistudio.google.com/app/apikey
- MongoDB (optional — app works without it via in-memory fallback)

### Steps

```bash
# 1. Navigate to the backend folder
cd activeglow_project/backend

# 2. Create a virtual environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Create your .env file from the template
cp .env.example .env

# 5. Open .env and set your GEMINI_API_KEY:
#    GEMINI_API_KEY=your_actual_key_here

# 6. Start the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API is now running at **http://localhost:8000**

Visit **http://localhost:8000/docs** for the interactive Swagger UI.

### Testing the API (curl)
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-123",
    "message": "What cleanser do you recommend for oily skin?"
  }'
```

### Running with Docker (includes MongoDB)
```bash
cd activeglow_project/backend

# Copy and fill in your .env
cp .env.example .env
# Edit .env: set GEMINI_API_KEY=...

# Build and launch both API + MongoDB
docker-compose up --build
```

---

## 📱 Local Setup — Flutter

### Prerequisites
- Flutter SDK 3.x → https://docs.flutter.dev/get-started/install
- Android Studio or Xcode (for mobile builds)
- Chrome (for web builds)

### Steps

```bash
# 1. Navigate to the Flutter folder
cd activeglow_project/flutter

# 2. Install dependencies
flutter pub get

# 3. Set your backend URL
# Open lib/config/constants.dart
# Change apiBaseUrl to match your environment:
#
#   Android Emulator (reaches host machine): http://10.0.2.2:8000
#   iOS Simulator / Web:                     http://localhost:8000
#   Physical device (same WiFi):             http://192.168.x.x:8000
#   Deployed backend:                        https://your-app.railway.app

# 4. Run the app
flutter run                     # Prompts you to choose a device
flutter run -d chrome           # Force web
flutter run -d android          # Force Android emulator
flutter run -d ios              # Force iOS simulator (Mac only)
```

---

## 🌐 Deployment Guide

### Option A: Railway.app (Recommended — Free Tier Available)

**Backend deployment:**

1. Create a free account at https://railway.app
2. Click **New Project → Deploy from GitHub Repo**
3. Connect your GitHub repository
4. Set the root directory to `backend/`
5. Add environment variables in the Railway dashboard:
   ```
   GEMINI_API_KEY=your_key_here
   MONGO_URI=mongodb+srv://...   (from MongoDB Atlas below)
   GEMINI_MODEL=gemini-1.5-flash
   MAX_HISTORY_TURNS=20
   CORS_ORIGINS=*
   ```
6. Railway auto-detects the Dockerfile and deploys.
7. Copy the generated URL (e.g., `https://activeglow-api.up.railway.app`)

**MongoDB Atlas (free cloud database):**

1. Create a free cluster at https://cloud.mongodb.com
2. Create a database user with read/write permissions
3. Whitelist IP `0.0.0.0/0` (allow all) for Railway
4. Get your connection string:
   `mongodb+srv://<user>:<password>@cluster0.xxxxx.mongodb.net/`
5. Set this as `MONGO_URI` in Railway environment variables

---

### Option B: Render.com (Alternative Free Tier)

1. Create account at https://render.com
2. New → Web Service → Connect your repo
3. Set root directory: `backend`
4. Build Command: `pip install -r requirements.txt`
5. Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
6. Add environment variables in Render dashboard (same as Railway above)

---

### Option C: Self-hosted with Docker

```bash
# On your server (Ubuntu/Debian)
git clone <your-repo>
cd activeglow_project/backend
cp .env.example .env
# Edit .env with your production values

docker-compose up -d --build

# Check it's running
curl http://your-server-ip:8000/health
```

---

### Flutter Web Deployment (Firebase Hosting)

```bash
# Install Firebase CLI
npm install -g firebase-tools
firebase login

# In your flutter folder
cd activeglow_project/flutter

# 1. Update apiBaseUrl in lib/config/constants.dart to your deployed backend URL

# 2. Build the web release
flutter build web --release

# 3. Initialize Firebase (first time only)
firebase init hosting
# Public directory: build/web
# Single page app: Yes
# Overwrite index.html: No

# 4. Deploy
firebase deploy --only hosting
```

Your chatbot is now live at `https://your-project.web.app` 🎉

---

### Flutter Android APK Build

```bash
cd activeglow_project/flutter

# Update apiBaseUrl to your deployed backend URL first!
# lib/config/constants.dart → static const String apiBaseUrl = 'https://your-app.railway.app';

# Build release APK
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧠 How Conversation Memory Works

Each request to `/chat` includes a `session_id` (UUID generated by the Flutter client).

```
Flutter Client                    FastAPI Backend               MongoDB
     │                                  │                          │
     │  POST /chat {session_id, msg}    │                          │
     │─────────────────────────────────>│                          │
     │                                  │  get_history(session_id) │
     │                                  │─────────────────────────>│
     │                                  │  [history array]         │
     │                                  │<─────────────────────────│
     │                                  │                          │
     │                                  │  Gemini.start_chat(history)
     │                                  │  .send_message(user_msg) │
     │                                  │  ← reply                 │
     │                                  │                          │
     │                                  │  save_history(updated)   │
     │                                  │─────────────────────────>│
     │  { reply, message_count }        │                          │
     │<─────────────────────────────────│                          │
```

**Key design decision:** Gemini is stateless — it has no memory between API calls. We solve this by passing the full conversation history with every request. The backend fetches history, builds a `ChatSession` with it, sends the new message, then saves the updated history back.

**Rolling window:** History is capped at `MAX_HISTORY_TURNS` (default 20) turn pairs to prevent the context window from growing indefinitely.

---

## 🔧 Customization

### Change the brand / bot
Edit `knowledge_base.txt` — that's the single source of truth for everything Skye knows. No code changes needed.

### Change the LLM
In `.env`, change `GEMINI_MODEL` to any available Gemini model:
- `gemini-1.5-flash` (fast, cheap — default)
- `gemini-1.5-pro` (smarter, more expensive)

### Change brand colors
Edit `flutter/lib/config/constants.dart` — update the `brandGreen`, `brandGreenDark`, etc. color values.

### Adjust bot personality / rules
Edit the `_build_system_prompt()` method in `backend/app/chat_handler.py`.

---

## 🔑 API Reference

| Method   | Endpoint              | Description                     |
|----------|-----------------------|---------------------------------|
| `POST`   | `/chat`               | Send a message, get a reply     |
| `DELETE` | `/session/{session_id}` | Clear a session's history     |
| `GET`    | `/health`             | Health check + memory backend   |
| `GET`    | `/docs`               | Swagger UI (dev only)           |

**POST /chat request body:**
```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "message": "What's your best product for post-workout skin?"
}
```

**Response:**
```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "reply": "For post-workout skin, I recommend...",
  "message_count": 4,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

---

## 📝 Environment Variables Reference

| Variable              | Required | Default                  | Description                        |
|-----------------------|----------|--------------------------|------------------------------------|
| `GEMINI_API_KEY`      | ✅ Yes   | —                        | Your Google Gemini API key         |
| `GEMINI_MODEL`        | No       | `gemini-1.5-flash`       | Gemini model to use                |
| `MONGO_URI`           | No       | `mongodb://localhost:27017` | MongoDB connection string       |
| `MONGO_DB_NAME`       | No       | `activeglow_db`          | MongoDB database name              |
| `MONGO_COLLECTION`    | No       | `chat_sessions`          | MongoDB collection name            |
| `MAX_HISTORY_TURNS`   | No       | `20`                     | Rolling history window (turn pairs)|
| `CORS_ORIGINS`        | No       | `*`                      | Comma-separated allowed origins    |
| `KNOWLEDGE_BASE_PATH` | No       | `knowledge_base.txt`     | Path to knowledge base file        |

---

## 🛡️ Security Notes for Production

- Set `CORS_ORIGINS` to your specific domain instead of `*`
- Store `GEMINI_API_KEY` in a secrets manager, not in code
- Enable MongoDB Atlas IP allowlist (don't use `0.0.0.0/0` in production)
- Add rate limiting (e.g., `slowapi` library) to prevent API abuse
- Consider adding an authentication layer if the bot handles user accounts

---

Built with ❤️ for ActiveGlow Skincare.
