#!/bin/zsh
# Test script for all API endpoints on Lambda deployment

BASE_URL="https://jochtjg54mxoi3a3x6aepfw32m0xyguz.lambda-url.ap-south-1.on.aws/api"
AUTH_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJhZjllNWM0ZC0zOTVkLTRmNTUtODBjMy0zM2MzY2IzZTYzNzgiLCJmaXJzdF9uYW1lIjoiUm9oaXQiLCJsYXN0X25hbWUiOiJTaW5naCBSYXdhdCIsInVzZXJuYW1lIjoicm9oaXRfc2luZ2hyYXdhdCIsInByb2ZpbGVfcGljIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jS1M1XzJ5STItU1hpWlUxZ3pCUTExbldHMnVTbmlDVzRhajNKX1IyaUtfTzgxaERvSE49czk2LWMiLCJwcmltYXJ5X3VzZXJfdHlwZSI6Ik1FTlRFRSIsImVtYWlsVmVyaWZpZWQiOm51bGwsImlhdCI6MTc0Nzc0NjU4OH0.w0UMXLNpa2F9gPOk2_AIqIjrvsYCR8hX3cNHyGljYhQ"

echo "🚀 Testing Lambda Deployment: AI Resume Completion Service"
echo "Base URL: $BASE_URL"
echo "Authentication: Using provided JWT token"
echo "================================================\n"

run_test() {
  local endpoint=$1
  local data=$2
  local stream=$3
  local description=$4
  
  echo "\n🧪 Testing $description"
  echo "POST ${BASE_URL}${endpoint}?stream=${stream}"
  echo "Data: $data"
  echo "---"
  
  if [ "$stream" = "true" ]; then
    curl -X POST "${BASE_URL}${endpoint}?stream=${stream}" \
      -H "Content-Type: application/json" \
      -H "Cookie: auth_token=${AUTH_TOKEN}" \
      -d "${data}" --no-buffer -w "\n" -s
  else
    curl -X POST "${BASE_URL}${endpoint}?stream=${stream}" \
      -H "Content-Type: application/json" \
      -H "Cookie: auth_token=${AUTH_TOKEN}" \
      -d "${data}" -w "\n" -s | jq .
  fi
  
  echo "\n✅ Test completed\n"
}

# Test 1: Summary generation
echo "=== 1. SUMMARY GENERATION ==="
run_test "/generate-summary" '{"jobDescription":"Backend developer with FastAPI","targetPosition":"Senior Backend Engineer","targetCompany":"TechCorp"}' false "Summary Generation (non-streaming)"
run_test "/generate-summary" '{"jobDescription":"Backend developer with FastAPI","targetPosition":"Senior Backend Engineer","targetCompany":"TechCorp"}' true "Summary Generation (streaming)"

# Test 2: Education generation
echo "=== 2. EDUCATION GENERATION ==="
run_test "/generate-education" '{"institution":"MIT","degree":"BS","fieldOfStudy":"Computer Science","jobDescription":"Software Engineering role"}' false "Education Generation (non-streaming)"
run_test "/generate-education" '{"institution":"MIT","degree":"BS","fieldOfStudy":"Computer Science","jobDescription":"Software Engineering role"}' true "Education Generation (streaming)"

# Test 3: Experience generation
echo "=== 3. EXPERIENCE GENERATION ==="
run_test "/generate-experience" '{"company":"Amazon","position":"Software Developer","jobDescription":"Lead Developer position"}' false "Experience Generation (non-streaming)"
run_test "/generate-experience" '{"company":"Amazon","position":"Software Developer","jobDescription":"Lead Developer position"}' true "Experience Generation (streaming)"

# Test 4: Project generation
echo "=== 4. PROJECT GENERATION ==="
run_test "/generate-project" '{"projectName":"E-commerce Platform","jobDescription":"Full Stack Developer role"}' false "Project Generation (non-streaming)"
run_test "/generate-project" '{"projectName":"E-commerce Platform","jobDescription":"Full Stack Developer role"}' true "Project Generation (streaming)"

# Test 5: Certification generation
echo "=== 5. CERTIFICATION GENERATION ==="
run_test "/generate-certification" '{"certificationName":"Microsoft Azure Administrator","jobDescription":"Cloud Administrator role"}' false "Certification Generation (non-streaming)"
run_test "/generate-certification" '{"certificationName":"Microsoft Azure Administrator","jobDescription":"Cloud Administrator role"}' true "Certification Generation (streaming)"

# Test 6: Publication generation
echo "=== 6. PUBLICATION GENERATION ==="
run_test "/generate-publication" '{"title":"Machine Learning Approaches","publisher":"ACM Conference","jobDescription":"Data Scientist role"}' false "Publication Generation (non-streaming)"
run_test "/generate-publication" '{"title":"Machine Learning Approaches","publisher":"ACM Conference","jobDescription":"Data Scientist role"}' true "Publication Generation (streaming)"

echo "\n🎉 All Lambda API tests completed!"
echo "If all tests passed, your resume completion service is fully deployed and working on AWS Lambda!" 