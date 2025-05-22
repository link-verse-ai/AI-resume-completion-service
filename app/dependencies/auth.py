from fastapi import Request, HTTPException, Depends
from jose import jwt
import os
from dotenv import load_dotenv

# Ensure environment variables are loaded from the root directory
load_dotenv(dotenv_path=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), '.env'))

SECRET_KEY = os.getenv("JWT_SECRET", "secret")

async def get_current_user(request: Request):
    token = request.cookies.get("auth_token")
    if not token:
        raise HTTPException(status_code=401, detail="Unauthorized: Missing token")
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        user_id = payload.get("userId")
        if not user_id:
            raise HTTPException(status_code=401, detail="Unauthorized: Invalid token - Missing userId")
        request.state.user = payload
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Unauthorized: Token expired")
    except jwt.JWTError:
        raise HTTPException(status_code=401, detail="Unauthorized: Invalid token")