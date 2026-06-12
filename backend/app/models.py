from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class ChatRequest(BaseModel):
    """Incoming message from the Flutter client."""
    session_id: str = Field(..., description="Unique session UUID generated on the client side")
    message: str    = Field(..., min_length=1, max_length=2000, description="User's chat message")

    class Config:
        json_schema_extra = {
            "example": {
                "session_id": "550e8400-e29b-41d4-a716-446655440000",
                "message": "What cleanser do you recommend for oily skin after the gym?"
            }
        }


class ChatResponse(BaseModel):
    """Response sent back to the Flutter client."""
    session_id: str
    reply: str
    message_count: int
    timestamp: str

    class Config:
        json_schema_extra = {
            "example": {
                "session_id": "550e8400-e29b-41d4-a716-446655440000",
                "reply": "For oily skin post-workout, I recommend The Reset Cleanser ($18)...",
                "message_count": 4,
                "timestamp": "2024-01-15T10:30:00Z"
            }
        }


class SessionClearResponse(BaseModel):
    """Confirmation after clearing a chat session."""
    message: str
    session_id: str


class HealthResponse(BaseModel):
    """Health check response."""
    status: str
    version: str
    memory_backend: str
