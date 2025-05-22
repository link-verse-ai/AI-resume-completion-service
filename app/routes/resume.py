from fastapi import APIRouter, Depends, Query, Request
from app.schemas.validation import (
    SummaryInput,
    EducationInput,
    ExperienceInput,
    ProjectInput,
    CertificationInput,
    PublicationInput,
)
from app.services.resume_service import (
    generate_summary,
    generate_education,
    generate_experience,
    generate_project,
    generate_certification,
    generate_publication,
)
from app.utils.openai_helpers import handle_openai_completion
from app.dependencies.auth import get_current_user
from app.utils.limiter import limiter

resume_router = APIRouter()

@resume_router.post("/generate-summary")
@limiter.limit("5/minute")
async def generate_summary_route(
    request: Request,
    input: SummaryInput,
    stream: bool = Query(False),
    current_user: dict = Depends(get_current_user),
):
    messages, tools, tool_name, _ = generate_summary(input)
    return await handle_openai_completion(messages, tools, stream, tool_name)


@resume_router.post("/generate-education")
@limiter.limit("5/minute")
async def generate_education_route(
    request: Request,
    input: EducationInput,
    stream: bool = Query(False),
    current_user: dict = Depends(get_current_user),
):
    messages, tools, tool_name, _ = generate_education(input)
    return await handle_openai_completion(messages, tools, stream, tool_name)


@resume_router.post("/generate-experience")
@limiter.limit("5/minute")
async def generate_experience_route(
    request: Request,
    input: ExperienceInput,
    stream: bool = Query(False),
    current_user: dict = Depends(get_current_user),
):
    messages, tools, tool_name, _ = generate_experience(input)
    return await handle_openai_completion(messages, tools, stream, tool_name)


@resume_router.post("/generate-project")
@limiter.limit("5/minute")
async def generate_project_route(
    request: Request,
    input: ProjectInput,
    stream: bool = Query(False),
    current_user: dict = Depends(get_current_user),
):
    messages, tools, tool_name, _ = generate_project(input)
    return await handle_openai_completion(messages, tools, stream, tool_name)


@resume_router.post("/generate-certification")
@limiter.limit("5/minute")
async def generate_certification_route(
    request: Request,
    input: CertificationInput,
    stream: bool = Query(False),
    current_user: dict = Depends(get_current_user),
):
    messages, tools, tool_name, _ = generate_certification(input)
    return await handle_openai_completion(messages, tools, stream, tool_name)


@resume_router.post("/generate-publication")
@limiter.limit("5/minute")
async def generate_publication_route(
    request: Request,
    input: PublicationInput,
    stream: bool = Query(False),
    current_user: dict = Depends(get_current_user),
):
    messages, tools, tool_name, _ = generate_publication(input)
    return await handle_openai_completion(messages, tools, stream, tool_name)
