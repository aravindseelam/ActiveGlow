"""
chat_handler.py
───────────────
Orchestrates the Gemini LLM conversation for Skye.

Flow per request:
  1. Load chat history from memory_manager.
  2. Build the Gemini GenerativeModel with system_instruction (injected knowledge base).
  3. Start a ChatSession with the existing history.
  4. Send the new user message.
  5. Persist the updated history back to memory.
  6. Return the model reply.
"""

import logging
import os
from datetime import datetime, timezone

import google.generativeai as genai

from app.config import settings
from app import memory_manager

logger = logging.getLogger(__name__)


class ChatHandler:
    """Singleton-style handler; initialised once at app startup."""

    def __init__(self):
        if not settings.GEMINI_API_KEY:
            raise EnvironmentError(
                "GEMINI_API_KEY is missing. "
                "Set it in your .env file or environment variables."
            )

        genai.configure(api_key=settings.GEMINI_API_KEY)

        self.knowledge_base: str = self._load_knowledge_base()
        self.system_prompt: str  = self._build_system_prompt()

        # Build the model with system_instruction — this is the correct
        # Gemini SDK way to inject a persistent system prompt.
        self.model = genai.GenerativeModel(
            model_name=settings.GEMINI_MODEL,
            system_instruction=self.system_prompt,
            generation_config={
                "temperature":      0.4,   # Low = factual & consistent
                "top_p":            0.85,
                "top_k":            40,
                "max_output_tokens": 1024,
            },
            safety_settings=[
                {"category": "HARM_CATEGORY_HARASSMENT",        "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
                {"category": "HARM_CATEGORY_HATE_SPEECH",       "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
                {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
                {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
            ],
        )

        logger.info(
            f"✅  ChatHandler ready | model={settings.GEMINI_MODEL} | "
            f"KB size={len(self.knowledge_base)} chars"
        )

    # ─── Core public method ───────────────────────────────────────────────────

    async def process_message(self, session_id: str, user_message: str) -> dict:
        """
        Send user_message to Gemini with full session history and return the reply.
        """
        # 1. Load existing history from memory
        history = await memory_manager.get_history(session_id)

        # 2. Start a chat session with that history
        #    (Gemini SDK re-loads history into the context each call — it is stateless
        #    server-side, so we must pass history on every request.)
        chat_session = self.model.start_chat(history=history)

        # 3. Send the new message  (async-safe via run_in_executor)
        import asyncio
        loop     = asyncio.get_event_loop()
        response = await loop.run_in_executor(
            None, chat_session.send_message, user_message
        )

        reply = response.text.strip()

        # 4. Persist the updated turn
        message_count = await memory_manager.append_turn(
            session_id, user_message, reply
        )

        return {
            "session_id":    session_id,
            "reply":         reply,
            "message_count": message_count,
            "timestamp":     datetime.now(timezone.utc).isoformat(),
        }

    # ─── Helpers ──────────────────────────────────────────────────────────────

    def _load_knowledge_base(self) -> str:
        kb_path = settings.KNOWLEDGE_BASE_PATH
        if not os.path.exists(kb_path):
            raise FileNotFoundError(
                f"knowledge_base.txt not found at '{kb_path}'. "
                "Ensure the file exists in the backend root directory."
            )
        with open(kb_path, "r", encoding="utf-8") as f:
            content = f.read()
        logger.info(f"📚  Knowledge base loaded from '{kb_path}' ({len(content)} chars).")
        return content

    def _build_system_prompt(self) -> str:
        """
        Construct the complete system prompt by injecting the knowledge base.
        This is the instruction that shapes Skye's every response.
        """
        return f"""
You are Skye, an AI-powered skincare assistant working exclusively for ActiveGlow Skincare.

YOUR PERSONALITY:
- Professional, warm, and encouraging — like a knowledgeable sports dermatologist.
- Scientifically grounded: cite ingredient names and mechanisms when helpful.
- Concise and action-oriented: busy athletes don't want walls of text.
- Never use excessive hype, slang, or emojis. Be helpful, not performative.

YOUR KNOWLEDGE (use ONLY this to answer product and policy questions):
══════════════════════════════════════════════════════════
{self.knowledge_base}
══════════════════════════════════════════════════════════

HARD RULES — follow these exactly, always:

1. DOMAIN RESTRICTION
   You only assist with ActiveGlow Skincare products, routines, and general skincare
   education directly relevant to an active lifestyle. If a user asks about ANY topic
   outside skincare (coding, math, politics, history, food, finance, etc.), you MUST
   respond with EXACTLY this phrase (word for word):
   "I'm sorry, but I am only trained to help with ActiveGlow skincare routines and products. Let's get back to your skin goals!"

2. MEDICAL BOUNDARY
   If a user mentions a severe or diagnosed skin condition (cystic acne, eczema,
   psoriasis, open wounds, bleeding, severe rashes, suspected infections), you MUST
   respond with EXACTLY:
   "I can recommend general products for skin health, but for medical skin conditions, please consult a certified dermatologist."

3. PRICE INTEGRITY
   Quote only the prices in the knowledge base. Do not offer any discounts, codes, or
   custom pricing beyond what is listed in the Bundles & Subscription section.

4. NO HALLUCINATION
   If a user asks about a product, ingredient, or policy not in the knowledge base,
   state that ActiveGlow does not currently offer it, and direct them to
   support@activeglow.com for further help.

5. FORMATTING
   When recommending products or routines, always use bullet points for clarity.
   When quoting prices, always include the $ symbol and USD denomination.
   Keep replies under 300 words unless the user explicitly asks for more detail.

Begin every first interaction with a brief, warm introduction as Skye.
""".strip()
