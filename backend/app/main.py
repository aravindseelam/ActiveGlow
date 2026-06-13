"""
main.py
───────
FastAPI application entry point for the ActiveGlow Skye chatbot backend.

Endpoints:
  GET    /                 → Root welcome message (Fixes Render 404)
  POST   /chat             → Send a message, receive a reply
  DELETE /session/{id}     → Clear a session's history
  GET    /health           → Health check (used by deployment platforms)
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.models import (
    ChatRequest,
    ChatResponse,
    SessionClearResponse,
    HealthResponse,
)
from app.chat_handler import ChatHandler
from app import memory_manager

# ─── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger(__name__)

# ─── App lifecycle ─────────────────────────────────────────────────────────────
chat_handler: ChatHandler | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialise heavy resources once at startup."""
    global chat_handler
    logger.info("🚀  ActiveGlow API starting…")
    chat_handler = ChatHandler()
    logger.info("✅  Skye is ready to assist customers.")
    yield
    logger.info("🛑  ActiveGlow API shutting down.")


# ─── FastAPI App ───────────────────────────────────────────────────────────────
app = FastAPI(
    title=settings.APP_TITLE,
    version=settings.APP_VERSION,
    description=(
        "Production backend for Skye — ActiveGlow Skincare's AI assistant. "
        "Powered by Google Gemini and built with FastAPI."
    ),
    lifespan=lifespan,
    # Explicitly defining documentation routes to prevent proxy fetch errors
    openapi_url="/openapi.json",
    docs_url="/docs"
)

# ─── CORS ─────────────────────────────────────────────────────────────────────
# Fixed CORS block to allow Vercel and secure credentials
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://active-glow.vercel.app",  # Your exact live Vercel domain
        "http://localhost:8000",           # Local testing
    ],
    allow_origin_regex=r"https://.*",      # Allows any secure HTTPS frontend (like Vercel preview links)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Global error handler ─────────────────────────────────────────────────────
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "An internal server error occurred. Please try again."},
    )


# ─── Routes ───────────────────────────────────────────────────────────────────

@app.get("/", summary="Root Welcome Message")
async def root():
    """
    Root endpoint to prevent 404 errors when visiting the base URL.
    Directs users and recruiters to the interactive documentation.
    """
    return {
        "message": "ActiveGlow Skincare API is Live!", 
        "status": "Healthy",
        "documentation": "/docs"
    }


@app.post("/chat", response_model=ChatResponse, summary="Send a message to Skye")
async def chat(request: ChatRequest):
    """
    Main chat endpoint.

    - Accepts a `session_id` (UUID) and a `message` string.
    - Returns Skye's reply and the current message count for the session.
    - Conversation history is automatically persisted (MongoDB or in-memory).
    """
    if not chat_handler:
        raise HTTPException(status_code=503, detail="Chat service is not ready yet.")

    result = await chat_handler.process_message(
        session_id=request.session_id,
        user_message=request.message.strip(),
    )
    return ChatResponse(**result)


@app.delete(
    "/session/{session_id}",
    response_model=SessionClearResponse,
    summary="Clear a chat session",
)
async def clear_session(session_id: str):
    """
    Wipe all conversation history for a given session_id.
    The Flutter client calls this when the user taps 'New Conversation'.
    """
    await memory_manager.clear_history(session_id)
    logger.info(f"🗑️  Session cleared: {session_id}")
    return SessionClearResponse(
        message="Session history cleared successfully.",
        session_id=session_id,
    )


@app.get("/health", response_model=HealthResponse, summary="Health check")
async def health_check():
    """
    Lightweight endpoint used by Railway, Render, or Docker health checks.
    Returns the memory backend in use (MongoDB or In-Memory).
    """
    return HealthResponse(
        status="ok",
        version=settings.APP_VERSION,
        memory_backend=memory_manager.memory_backend_name(),
    )


# ─── Dev entry point ──────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
