import os
import json
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from dotenv import load_dotenv
from mangum import Mangum
from app.utils.limiter import limiter
from app.routes.resume import resume_router

# Load environment variables from the root directory
load_dotenv(dotenv_path=os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env'))

app = FastAPI()

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for Lambda URL access
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Rate limiter configuration
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Include routers
app.include_router(resume_router, prefix="/api")

# Add a simple root endpoint for testing
@app.get("/")
async def root():
    return {"message": "Resume Completion API is running on Lambda!", "status": "healthy", "version": "1.1.0"}

# Lambda handler with better error handling
def lambda_handler(event, context):
    """
    AWS Lambda entry point with debugging
    """
    print(f"Event received: {json.dumps(event, default=str)}")
    print(f"Context: {context}")
    
    # Initialize Mangum adapter
    adapter = Mangum(app, lifespan="off")
    
    try:
        return adapter(event, context)
    except Exception as e:
        print(f"Error in Lambda handler: {str(e)}")
        print(f"Event type: {type(event)}")
        print(f"Event keys: {list(event.keys()) if isinstance(event, dict) else 'Not a dict'}")
        raise

# Keep the old handler for compatibility
handler = lambda_handler