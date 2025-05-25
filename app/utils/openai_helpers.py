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
            import asyncio
            
            # Make a single non-streaming API call
            response = await client.chat.completions.create(
                model="gpt-4o-mini",
                messages=messages,
                tools=tools,
                tool_choice="auto",
                stream=False
            )
            
            # Log request + token usage for streaming calls
            print(f"\n[REQUEST → {tool_name}] (STREAMING)\n" +
                  f"{json.dumps(messages, indent=2)}\n" +
                  f"[TOKENS USED] total={response.usage.total_tokens if response.usage else 'N/A'}\n")
            
            # Track tokens for the complete response
            if response.usage:
                add_tokens(response.usage.total_tokens)
            
            # Extract the tool call
            tc = next((tc for tc in response.choices[0].message.tool_calls
                      if tc.function.name == tool_name), None)
            if not tc:
                yield "data: [ERROR]\n\n"
                return
            
            # Parse the JSON arguments
            try:
                args = json.loads(tc.function.arguments)
                description = args.get("description")
                if description is None:
                    yield "data: [ERROR] No description found in response\n\n"
                    return
            except json.JSONDecodeError:
                yield "data: [ERROR] Invalid JSON in tool call arguments\n\n"
                return
            
            # Handle streaming based on description type
            if isinstance(description, str):
                # For single-string output (e.g., summary)
                words = description.split()
                for word in words:
                    yield f"data: {json.dumps(word)}\n\n"
                    await asyncio.sleep(0.02)
            elif isinstance(description, list):
                # For array output (e.g., education)
                for item in description:
                    # Stream each bullet point as a whole (or split into words if desired)
                    yield f"data: {json.dumps(item)}\n\n"
                    await asyncio.sleep(0.02)
            else:
                yield "data: [ERROR] Unsupported description format\n\n"
                return
            
            # Signal completion
            yield "data: [DONE]\n\n"

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
            
            # Log request + token usage for non-streaming calls
            print(f"\n[REQUEST → {tool_name}] (NON-STREAMING)\n" +
                  f"{json.dumps(messages, indent=2)}\n" +
                  f"[TOKENS USED] total={response.usage.total_tokens if response.usage else 'N/A'}\n")
            
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