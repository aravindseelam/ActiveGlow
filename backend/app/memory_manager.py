"""
memory_manager.py
─────────────────
Manages conversation history for Skye.

Strategy (priority order):
  1. MongoDB via Motor (async) — persistent across restarts, ideal for production.
  2. In-memory dict        — zero-config fallback for local dev with no MongoDB.

The manager stores Gemini-compatible history:
  [ {"role": "user", "parts": ["..."]}, {"role": "model", "parts": ["..."]} ]
"""

import logging
from datetime import datetime
from app.config import settings

logger = logging.getLogger(__name__)


# ─── Try to connect to MongoDB ────────────────────────────────────────────────
_mongo_available = False
_db_client       = None
_collection      = None

try:
    from motor.motor_asyncio import AsyncIOMotorClient
    _db_client   = AsyncIOMotorClient(settings.MONGO_URI, serverSelectionTimeoutMS=3000)
    _db          = _db_client[settings.MONGO_DB_NAME]
    _collection  = _db[settings.MONGO_COLLECTION]
    _mongo_available = True
    logger.info("✅  MongoDB connected — using persistent memory.")
except Exception as exc:
    logger.warning(f"⚠️  MongoDB unavailable ({exc}). Falling back to in-memory storage.")

# In-memory fallback: { session_id: [gemini_history_list] }
_in_memory_store: dict[str, list] = {}


# ─── Public helpers ───────────────────────────────────────────────────────────

async def get_history(session_id: str) -> list[dict]:
    """Return the full Gemini-compatible chat history for a session."""
    if _mongo_available:
        doc = await _collection.find_one({"session_id": session_id})
        if doc:
            return doc.get("history", [])
        return []
    else:
        return list(_in_memory_store.get(session_id, []))


async def save_history(session_id: str, history: list[dict]) -> None:
    """Persist the full history for a session (upsert)."""
    # Apply rolling window to prevent unbounded growth
    trimmed = _trim_history(history)

    if _mongo_available:
        await _collection.update_one(
            {"session_id": session_id},
            {
                "$set": {
                    "history":    trimmed,
                    "updated_at": datetime.utcnow().isoformat(),
                },
                "$setOnInsert": {
                    "created_at": datetime.utcnow().isoformat(),
                }
            },
            upsert=True,
        )
    else:
        _in_memory_store[session_id] = trimmed


async def append_turn(session_id: str, user_text: str, model_text: str) -> int:
    """
    Append one user+model turn to the session history.
    Returns the new total message count.
    """
    history = await get_history(session_id)
    history.append({"role": "user",  "parts": [user_text]})
    history.append({"role": "model", "parts": [model_text]})
    await save_history(session_id, history)
    return len(history)


async def clear_history(session_id: str) -> None:
    """Delete all conversation history for a session."""
    if _mongo_available:
        await _collection.delete_one({"session_id": session_id})
    else:
        _in_memory_store.pop(session_id, None)


def memory_backend_name() -> str:
    return "MongoDB" if _mongo_available else "In-Memory"


# ─── Private ──────────────────────────────────────────────────────────────────

def _trim_history(history: list[dict]) -> list[dict]:
    """
    Keep only the last MAX_HISTORY_TURNS * 2 messages (each turn = 2 items).
    Always preserves pairs so Gemini never receives a dangling user or model message.
    """
    max_items = settings.MAX_HISTORY_TURNS * 2
    if len(history) > max_items:
        # Trim from front, keep even count so pairs stay intact
        history = history[-max_items:]
        if history and history[0]["role"] != "user":
            history = history[1:]  # Ensure we start with a user turn
    return history
