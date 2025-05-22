from app.schemas.validation import (
    SummaryInput,
    EducationInput,
    ExperienceInput,
    ProjectInput,
    CertificationInput,
    PublicationInput,
)
from typing import List, Dict, Tuple

def create_system_message(section_type: str) -> Dict[str, str]:
    content = (
        "You are an ATS-optimized resume expert. "
        + ("Craft a professional summary." if section_type == "summary" else f"Generate a detailed, keyword-rich description for a {section_type} entry.")
    )
    return {"role": "system", "content": content}

def create_tool(tool_name: str, is_array_output: bool) -> Dict:
    return {
        "type": "function",
        "function": {
            "name": tool_name,
            "description": f"Generates {tool_name.replace('generate_', '').replace('_description', '')}",
            "parameters": {
                "type": "object",
                "properties": {
                    "description": (
                        {"type": "array", "items": {"type": "string"}} if is_array_output else {"type": "string"}
                    )
                },
                "required": ["description"],
            },
        },
    }

def generate_summary(input: SummaryInput) -> Tuple[List[Dict], List[Dict], str, str]:
    parts = [
        f"job: {input.jobDescription}",
        f"position: {input.targetPosition}",
        f"company: {input.targetCompany}"
    ]
    if input.fullName:
        parts.append(f"candidate name: {input.fullName}")
    if input.rawSummary:
        parts.append(f"summary hints: {input.rawSummary}")
    if input.rawDescription:
        parts.append(f"additional notes: {'; '.join(input.rawDescription)}")
    user_content = (
        "Generate a concise, ATS-friendly summary using "
        + ", ".join(parts)
        + "."
    )
    messages = [create_system_message("summary"), {"role": "user", "content": user_content}]
    tools = [create_tool("generate_summary", False)]
    return messages, tools, "generate_summary", "summary"

def generate_education(input: EducationInput) -> Tuple[List[Dict], List[Dict], str, str]:
    parts = [
        f"institution: {input.institution}",
        f"degree: {input.degree}"
    ]
    if input.fieldOfStudy:
        parts.append(f"field of study: {input.fieldOfStudy}")
    if input.location:
        parts.append(f"location: {input.location}")
    if input.startDate or input.endDate:
        parts.append(
            f"tenure: {input.startDate or 'N/A'} to {input.endDate or 'Present'}"
        )
    if input.current:
        parts.append("currently enrolled")
    if input.gpa:
        parts.append(f"GPA: {input.gpa}")
    if input.rawDescription:
        parts.append(f"notes: {'; '.join(input.rawDescription)}")
    if input.achievements:
        parts.append(f"achievements: {'; '.join(input.achievements)}")
    parts.append(f"for target job: {input.jobDescription}")
    user_content = (
        "Generate ATS-optimized education bullets including "
        + ", ".join(parts)
        + "."
    )
    messages = [create_system_message("education"), {"role":"user","content":user_content}]
    tools = [create_tool("generate_education_description", True)]
    return messages, tools, "generate_education_description", "education"

def generate_experience(input: ExperienceInput) -> Tuple[List[Dict], List[Dict], str, str]:
    parts = [
        f"company: {input.company}",
        f"position: {input.position}"
    ]
    if input.location:
        parts.append(f"location: {input.location}")
    if input.startDate or input.endDate:
        parts.append(
            f"tenure: {input.startDate or 'N/A'} to {input.endDate or 'Present'}"
        )
    if input.current:
        parts.append("currently in role")
    if input.technologies:
        parts.append(f"technologies: {', '.join(input.technologies)}")
    if input.achievements:
        parts.append(f"achievements: {'; '.join(input.achievements)}")
    if input.rawDescription:
        parts.append(f"notes: {'; '.join(input.rawDescription)}")
    parts.append(f"for target job: {input.jobDescription}")
    user_content = (
        "Generate ATS-friendly experience description with "
        + ", ".join(parts)
        + "."
    )
    messages = [create_system_message("experience"), {"role":"user","content":user_content}]
    tools = [create_tool("generate_experience_description", True)]
    return messages, tools, "generate_experience_description", "experience"

def generate_project(input: ProjectInput) -> Tuple[List[Dict], List[Dict], str, str]:
    parts = [f"project: {input.projectName}"]
    if input.role:
        parts.append(f"role: {input.role}")
    if input.organization:
        parts.append(f"organization: {input.organization}")
    if input.url:
        parts.append(f"url: {input.url}")
    if input.startDate or input.endDate:
        parts.append(
            f"duration: {input.startDate or 'N/A'} to {input.endDate or 'Present'}"
        )
    if input.ongoing:
        parts.append("ongoing project")
    if input.technologies:
        parts.append(f"technologies: {', '.join(input.technologies)}")
    if input.achievements:
        parts.append(f"achievements: {'; '.join(input.achievements)}")
    if input.rawDescription:
        parts.append(f"notes: {'; '.join(input.rawDescription)}")
    parts.append(f"for target job: {input.jobDescription}")
    user_content = (
        "Generate ATS-optimized project bullets using "
        + ", ".join(parts)
        + "."
    )
    messages = [create_system_message("project"), {"role":"user","content":user_content}]
    tools = [create_tool("generate_project_description", True)]
    return messages, tools, "generate_project_description", "project"

def generate_certification(input: CertificationInput) -> Tuple[List[Dict], List[Dict], str, str]:
    parts = [f"certification: {input.certificationName}"]
    if input.issuer:
        parts.append(f"issued by: {input.issuer}")
    if input.issueDate:
        parts.append(f"issue date: {input.issueDate}")
    if input.expirationDate:
        parts.append(f"expires: {input.expirationDate}")
    if input.credentialUrl:
        parts.append(f"url: {input.credentialUrl}")
    if input.rawDescription:
        parts.append(f"notes: {input.rawDescription}")
    parts.append(f"for target job: {input.jobDescription}")
    user_content = (
        "Generate a concise, ATS-friendly certification description with "
        + ", ".join(parts)
        + "."
    )
    messages = [create_system_message("certification"), {"role":"user","content":user_content}]
    tools = [create_tool("generate_certification_description", False)]
    return messages, tools, "generate_certification_description", "certification"

def generate_publication(input: PublicationInput) -> Tuple[List[Dict], List[Dict], str, str]:
    parts = [f"title: {input.title}", f"publisher: {input.publisher}"]
    if input.publicationDate:
        parts.append(f"date: {input.publicationDate}")
    if input.authors:
        parts.append(f"authors: {', '.join(input.authors)}")
    if input.url:
        parts.append(f"url: {input.url}")
    if input.rawDescription:
        parts.append(f"notes: {input.rawDescription}")
    parts.append(f"for target job: {input.jobDescription}")
    user_content = (
        "Generate ATS-optimized publication bullets using "
        + ", ".join(parts)
        + "."
    )
    messages = [create_system_message("publication"), {"role":"user","content":user_content}]
    tools = [create_tool("generate_publication_description", True)]
    return messages, tools, "generate_publication_description", "publication"
