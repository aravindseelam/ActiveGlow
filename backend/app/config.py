import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    # ── Gemini ──────────────────────────────────────────────────────────────────
    GEMINI_API_KEY: str       = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL: str         = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")

    # ── MongoDB ──────────────────────────────────────────────────────────────────
    MONGO_URI: str            = os.getenv("MONGO_URI", "mongodb://localhost:27017")
    MONGO_DB_NAME: str        = os.getenv("MONGO_DB_NAME", "activeglow_db")
    MONGO_COLLECTION: str     = os.getenv("MONGO_COLLECTION", "chat_sessions")

    # ── Memory settings ──────────────────────────────────────────────────────────
    # Maximum number of message pairs (user+model) to keep in rolling history.
    # Prevents the context window from growing unbounded over long sessions.
    MAX_HISTORY_TURNS: int    = int(os.getenv("MAX_HISTORY_TURNS", "20"))

    # ── CORS ─────────────────────────────────────────────────────────────────────
    CORS_ORIGINS: list        = os.getenv("CORS_ORIGINS", "*").split(",")

    # ── App ──────────────────────────────────────────────────────────────────────
    APP_TITLE: str            = "ActiveGlow Skincare Chatbot API"
    APP_VERSION: str          = "2.0.0"
    KNOWLEDGE_BASE_PATH: str  = os.getenv("KNOWLEDGE_BASE_PATH", "knowledge_base.txt")

settings = Settings()
