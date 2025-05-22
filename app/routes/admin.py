from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel
from app.utils.token_tracker import get_total_tokens
from app.utils.limiter import limiter
import os
from dotenv import load_dotenv

# Ensure environment variables are loaded from the root directory
load_dotenv(dotenv_path=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), '.env'))

admin_router = APIRouter()

ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "admin123")  # Default fallback

class AdminInput(BaseModel):
    password: str

@admin_router.post("/token-usage")
@limiter.limit("5/minute")
async def token_usage(request: Request, input: AdminInput):
    if input.password != ADMIN_PASSWORD:
        raise HTTPException(status_code=401, detail="Unauthorized")
    return {"totalTokens": get_total_tokens(), "note": "Only non-streaming calls are tracked"}