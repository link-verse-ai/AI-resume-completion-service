from typing import Dict, List
from openai import AsyncOpenAI
from fastapi.responses import StreamingResponse
import json
from app.utils.token_tracker import add_tokens
from fastapi import HTTPException
import os
from dotenv import load_dotenv
import sys

# Ensure environment variables are loaded from the root directory
load_dotenv(dotenv_path=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), '.env'))

# Get API key from environment
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    print("ERROR: OPENAI_API_KEY environment variable not found. Please check your .env file.")
    sys.exit(1)

client = AsyncOpenAI(api_key=api_key)

async def handle_openai_completion(messages: List[Dict], tools: List[Dict], stream: bool, tool_name: str):
    if stream:
        async def stream_response():
            stream = await client.chat.completions.create(
                model="gpt-4o-mini",
                messages=messages,
                tools=tools,
                tool_choice="auto",
                stream=True
            )
            async for chunk in stream:
                yield f"data: {json.dumps(chunk.choices[0].delta if chunk.choices else {})}\n\n"
        return StreamingResponse(stream_response(), media_type="text/event-stream")
    else:
        try:
            response = await client.chat.completions.create(
                model="gpt-4o-mini",
                messages=messages,
                tools=tools,
                tool_choice="auto",
                stream=False
            )
            if response.usage:
                add_tokens(response.usage.total_tokens)
            if response.choices and response.choices[0].message.tool_calls:
                tool_call = next((tc for tc in response.choices[0].message.tool_calls if tc.function.name == tool_name), None)
                if tool_call:
                    args = json.loads(tool_call.function.arguments)
                    return args
                else:
                    raise HTTPException(status_code=500, detail="Unexpected tool call from AI")
            else:
                raise HTTPException(status_code=500, detail="Unexpected response from AI")
        except Exception as e:
            raise HTTPException(status_code=502, detail=f"AI service error: {str(e)}")