from pydantic import BaseModel
from typing import List, Optional

class SummaryInput(BaseModel):
    jobDescription: str
    targetPosition: str
    targetCompany: str
    fullName: Optional[str] = None
    rawSummary: Optional[str] = None
    rawDescription: Optional[List[str]] = None

class EducationInput(BaseModel):
    institution: str
    degree: str
    fieldOfStudy: str
    location: Optional[str] = None
    startDate: Optional[str] = None
    endDate: Optional[str] = None
    current: Optional[bool] = None
    gpa: Optional[str] = None
    jobDescription: str
    rawDescription: Optional[List[str]] = None
    achievements: Optional[List[str]] = None

class ExperienceInput(BaseModel):
    company: str
    position: str
    location: Optional[str] = None
    startDate: Optional[str] = None
    endDate: Optional[str] = None
    current: Optional[bool] = None
    technologies: Optional[List[str]] = None
    jobDescription: str
    rawDescription: Optional[List[str]] = None
    achievements: Optional[List[str]] = None

class ProjectInput(BaseModel):
    projectName: str
    role: Optional[str] = None
    organization: Optional[str] = None
    url : Optional[str] = None
    startDate: Optional[str] = None
    endDate: Optional[str] = None
    ongoing: Optional[bool] = None
    # achievements (impact metrics, e.g. “reduced load times by 30%”)
    achievements: Optional[List[str]] = None
    jobDescription: str
    rawDescription: Optional[List[str]] = None
    technologies: Optional[List[str]] = None

class CertificationInput(BaseModel):
    issuer: Optional[str] = None
    issueDate: Optional[str] = None
    expirationDate: Optional[str] = None
    credentialUrl: Optional[str] = None
    certificationName: str
    jobDescription: str
    rawDescription: Optional[str] = None



class PublicationInput(BaseModel):
    title: str
    publisher: str
    publicationDate: Optional[str] = None
    authors: Optional[List[str]] = None
    url: Optional[str] = None
    jobDescription: str
    rawDescription: Optional[str] = None