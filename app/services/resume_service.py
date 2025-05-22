from app.schemas.validation import SummaryInput, EducationInput, ExperienceInput, ProjectInput, CertificationInput, PublicationInput
from typing import List, Dict, Tuple

def create_system_message(section_type: str) -> Dict[str, str]:
    content = f"You are a resume expert generating {'a professional summary' if section_type == 'summary' else f'a description for a {section_type} entry'}."
    return {"role": "system", "content": content}

def create_tool(tool_name: str, is_array_output: bool) -> Dict:
    return {
        "type": "function",
        "function": {
            "name": tool_name,
            "description": f"Generate {tool_name.replace('generate_', '').replace('_description', '')}",
            "parameters": {
                "type": "object",
                "properties": {
                    "description": {"type": "array", "items": {"type": "string"}} if is_array_output else {"type": "string"}
                },
                "required": ["description"]
            }
        }
    }

def generate_summary(input: SummaryInput) -> Tuple[List[Dict], List[Dict], str, str]:
    messages = [
        create_system_message("summary"),
        {
            "role": "user",
            "content": f"Generate a professional summary for the job: {input.jobDescription}, position: {input.targetPosition}, company: {input.targetCompany}. User hints: {input.rawSummary or 'none'}."
        }
    ]
    tools = [create_tool("generate_summary", False)]
    tool_name = "generate_summary"
    section = "summary"
    return messages, tools, tool_name, section

def generate_education(input: EducationInput) -> Tuple[List[Dict], List[Dict], str, str]:
    messages = [
        create_system_message("education"),
        {
            "role": "user",
            "content": f"Generate a description for the education entry: institution: {input.institution}, degree: {input.degree}, field of study: {input.fieldOfStudy}{', location: ' + input.location if input.location else ''}{', start date: ' + input.startDate if input.startDate else ''}{', end date: ' + input.endDate if input.endDate else ''}{', currently enrolled' if input.current else ''}{', GPA: ' + input.gpa if input.gpa else ''}, for the target job: {input.jobDescription}. User hints: {', '.join(input.rawDescription) if input.rawDescription else 'none'}. Achievements: {', '.join(input.achievements) if input.achievements else 'none'}."
        }
    ]
    tools = [create_tool("generate_education_description", True)]
    tool_name = "generate_education_description"
    section = "education"
    return messages, tools, tool_name, section

def generate_experience(input: ExperienceInput) -> Tuple[List[Dict], List[Dict], str, str]:
    messages = [
        create_system_message("experience"),
        {
            "role": "user",
            "content": f"Generate a description for the experience entry: company: {input.company}, position: {input.position}{', location: ' + input.location if input.location else ''}{', start date: ' + input.startDate if input.startDate else ''}{', end date: ' + input.endDate if input.endDate else ''}{', current job' if input.current else ''}, for the target job: {input.jobDescription}. User hints: {', '.join(input.rawDescription) if input.rawDescription else 'none'}. Achievements: {', '.join(input.achievements) if input.achievements else 'none'}."
        }
    ]
    tools = [create_tool("generate_experience_description", True)]
    tool_name = "generate_experience_description"
    section = "experience"
    return messages, tools, tool_name, section

def generate_project(input: ProjectInput) -> Tuple[List[Dict], List[Dict], str, str]:
    messages = [
        create_system_message("project"),
        {
            "role": "user",
            "content": f"Generate a description for the project entry: project name: {input.projectName}{', start date: ' + input.startDate if input.startDate else ''}{', end date: ' + input.endDate if input.endDate else ''}{', ongoing' if input.ongoing else ''}, for the target job: {input.jobDescription}. User hints: {', '.join(input.rawDescription) if input.rawDescription else 'none'}. Technologies: {', '.join(input.technologies) if input.technologies else 'none'}."
        }
    ]
    tools = [create_tool("generate_project_description", True)]
    tool_name = "generate_project_description"
    section = "project"
    return messages, tools, tool_name, section

def generate_certification(input: CertificationInput) -> Tuple[List[Dict], List[Dict], str, str]:
    messages = [
        create_system_message("certification"),
        {
            "role": "user",
            "content": f"Generate a description for the certification entry: certification name: {input.certificationName}, issuing organization: {input.issuingOrganization}{', date earned: ' + input.dateEarned if input.dateEarned else ''}, for the target job: {input.jobDescription}. User hints: {input.rawDescription or 'none'}."
        }
    ]
    tools = [create_tool("generate_certification_description", False)]
    tool_name = "generate_certification_description"
    section = "certification"
    return messages, tools, tool_name, section

def generate_publication(input: PublicationInput) -> Tuple[List[Dict], List[Dict], str, str]:
    messages = [
        create_system_message("publication"),
        {
            "role": "user",
            "content": f"Generate a description for the publication entry: title: {input.title}, publisher: {input.publisher}{', publication date: ' + input.publicationDate if input.publicationDate else ''}, for the target job: {input.jobDescription}. User hints: {input.rawDescription or 'none'}."
        }
    ]
    tools = [create_tool("generate_publication_description", False)]
    tool_name = "generate_publication_description"
    section = "publication"
    return messages, tools, tool_name, section