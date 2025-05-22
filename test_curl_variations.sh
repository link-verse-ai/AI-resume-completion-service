#!/bin/zsh
# Test script for all generation endpoints with streaming and non-streaming, valid, partial, and invalid data

BASE_URL="http://localhost:8001/api"
AUTH_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJhZjllNWM0ZC0zOTVkLTRmNTUtODBjMy0zM2MzY2IzZTYzNzgiLCJmaXJzdF9uYW1lIjoiUm9oaXQiLCJsYXN0X25hbWUiOiJTaW5naCBSYXdhdCIsInVzZXJuYW1lIjoicm9oaXRfc2luZ2hyYXdhdCIsInByb2ZpbGVfcGljIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jS1M1XzJ5STItU1hpWlUxZ3pCUTExbldHMnVTbmlDVzRhajNKX1IyaUtfTzgxaERvSE49czk2LWMiLCJwcmltYXJ5X3VzZXJfdHlwZSI6Ik1FTlRFRSIsImVtYWlsVmVyaWZpZWQiOm51bGwsImlhdCI6MTc0Nzc0NjU4OH0.w0UMXLNpa2F9gPOk2_AIqIjrvsYCR8hX3cNHyGljYhQ"

run_curl() {
  local endpoint=$1
  local data=$2
  local stream=$3
  local label=$4
  echo "\n===== $label ====="
  echo "POST $endpoint?stream=$stream"
  echo "Request body: $data"
  curl -s -X POST "$BASE_URL$endpoint?stream=$stream" \
    -H "Content-Type: application/json" \
    -H "Cookie: auth_token=$AUTH_TOKEN" \
    -d "$data"
  echo "\n-----------------------------"
}

# 1. generate-summary
run_curl "/generate-summary" '{"jobDescription":"Python dev","targetPosition":"Backend","targetCompany":"Acme","fullName":"Alice","rawSummary":"Fast learner","rawDescription":["Knows Django","REST APIs"]}' false "Summary: All fields, non-streaming"
run_curl "/generate-summary" '{"jobDescription":"Python dev","targetPosition":"Backend","targetCompany":"Acme"}' true "Summary: Only required, streaming"
run_curl "/generate-summary" '{}' false "Summary: No data, non-streaming (should fail)"
run_curl "/generate-summary" '{"jobDescription":123,"targetPosition":[],"targetCompany":null}' false "Summary: Wrong types, non-streaming (should fail)"

# 2. generate-education
run_curl "/generate-education" '{"institution":"MIT","degree":"BS","fieldOfStudy":"CS","location":"Cambridge","startDate":"2015","endDate":"2019","current":false,"gpa":"4.0","jobDescription":"Backend dev","rawDescription":["AI courses"],"achievements":["Summa Cum Laude"]}' false "Education: All fields, non-streaming"
run_curl "/generate-education" '{"institution":"MIT","degree":"BS","fieldOfStudy":"CS","jobDescription":"Backend dev"}' true "Education: Only required, streaming"
run_curl "/generate-education" '{}' false "Education: No data, non-streaming (should fail)"
run_curl "/generate-education" '{"institution":123,"degree":false,"fieldOfStudy":[],"jobDescription":null}' false "Education: Wrong types, non-streaming (should fail)"

# 3. generate-experience
run_curl "/generate-experience" '{"company":"Globex","position":"Engineer","location":"NYC","startDate":"2020","endDate":"2022","current":true,"technologies":["Python","Docker"],"jobDescription":"DevOps","rawDescription":["Built CI/CD"],"achievements":["Reduced downtime"]}' false "Experience: All fields, non-streaming"
run_curl "/generate-experience" '{"company":"Globex","position":"Engineer","jobDescription":"DevOps"}' true "Experience: Only required, streaming"
run_curl "/generate-experience" '{}' false "Experience: No data, non-streaming (should fail)"
run_curl "/generate-experience" '{"company":[],"position":null,"jobDescription":123}' false "Experience: Wrong types, non-streaming (should fail)"

# 4. generate-project
run_curl "/generate-project" '{"projectName":"ResumeBot","role":"Lead","organization":"OpenAI","url":"https://github.com","startDate":"2023","endDate":"2024","ongoing":false,"achievements":["Launched MVP"],"jobDescription":"AI dev","rawDescription":["Built with FastAPI"],"technologies":["Python","React"]}' false "Project: All fields, non-streaming"
run_curl "/generate-project" '{"projectName":"ResumeBot","jobDescription":"AI dev"}' true "Project: Only required, streaming"
run_curl "/generate-project" '{}' false "Project: No data, non-streaming (should fail)"
run_curl "/generate-project" '{"projectName":false,"jobDescription":[]}' false "Project: Wrong types, non-streaming (should fail)"

# 5. generate-certification
run_curl "/generate-certification" '{"certificationName":"AWS Cert","issuer":"Amazon","issueDate":"2022","expirationDate":"2025","credentialUrl":"https://aws.amazon.com","jobDescription":"Cloud dev","rawDescription":"Passed exam"}' false "Certification: All fields, non-streaming"
run_curl "/generate-certification" '{"certificationName":"AWS Cert","jobDescription":"Cloud dev"}' true "Certification: Only required, streaming"
run_curl "/generate-certification" '{}' false "Certification: No data, non-streaming (should fail)"
run_curl "/generate-certification" '{"certificationName":[],"jobDescription":123}' false "Certification: Wrong types, non-streaming (should fail)"

# 6. generate-publication
run_curl "/generate-publication" '{"title":"AI Paper","publisher":"Science","publicationDate":"2024","authors":["Alice","Bob"],"url":"https://arxiv.org","jobDescription":"Researcher","rawDescription":"Published in top journal"}' false "Publication: All fields, non-streaming"
run_curl "/generate-publication" '{"title":"AI Paper","publisher":"Science","jobDescription":"Researcher"}' true "Publication: Only required, streaming"
run_curl "/generate-publication" '{}' false "Publication: No data, non-streaming (should fail)"
run_curl "/generate-publication" '{"title":false,"publisher":[],"jobDescription":123}' false "Publication: Wrong types, non-streaming (should fail)"

echo "\nAll tests completed!"
