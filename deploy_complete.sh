#!/bin/bash

# Complete Lambda Deployment Script (Idempotent & Smart)
# This script does everything: rebuilds image, creates function, sets env vars, creates URL, and tests
# Safe to run multiple times - won't duplicate resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
REGION="ap-south-1"
FUNCTION_NAME="ai-resume-completion-service"
REPOSITORY_NAME="my-fastapi-app"
IMAGE_TAG="latest"
ENV_FILE=".env"
TIMEOUT=30
MEMORY=512
ROLE_NAME="lambda-execution-role-${FUNCTION_NAME}"

echo -e "${PURPLE}🚀 Complete Lambda Deployment Starting (Idempotent Mode)...${NC}"
echo -e "${BLUE}Function: $FUNCTION_NAME${NC}"
echo -e "${BLUE}Region: $REGION${NC}"
echo -e "${BLUE}Repository: $REPOSITORY_NAME${NC}"
echo ""

# Step 1: Check if .env file exists
echo -e "${YELLOW}📋 Step 1: Checking environment file...${NC}"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ .env file found${NC}"
echo ""

# Step 2: Get AWS Account ID
echo -e "${YELLOW}🆔 Step 2: Getting AWS Account ID...${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ Account ID: $ACCOUNT_ID${NC}"
echo ""

# Step 3: Build and Push Fresh Image (Lambda-Compatible)
echo -e "${YELLOW}🐳 Step 3: Building Lambda-compatible Docker image...${NC}"

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    echo -e "${BLUE}Apple Silicon detected - building for x86-64 (Lambda requirement)${NC}"
    PLATFORM_FLAG="--platform linux/amd64"
else
    echo -e "${BLUE}Building for native x86-64${NC}"
    PLATFORM_FLAG=""
fi

# Build the image with Lambda-compatible settings
# Key fix: --provenance=false --sbom=false for Lambda compatibility
echo -e "${BLUE}Building Docker image with Lambda-compatible manifest (Docker v2)...${NC}"
echo -e "${YELLOW}🔧 Using --provenance=false --sbom=false for Lambda compatibility${NC}"

# Enable BuildKit for better compatibility
export DOCKER_BUILDKIT=1
export BUILDX_NO_DEFAULT_ATTESTATIONS=1

docker build $PLATFORM_FLAG \
    --provenance=false \
    --sbom=false \
    -t $REPOSITORY_NAME:$IMAGE_TAG .

# Create ECR repository if it doesn't exist
echo -e "${BLUE}Ensuring ECR repository exists...${NC}"
aws ecr create-repository \
    --repository-name $REPOSITORY_NAME \
    --region $REGION \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256 \
    2>/dev/null || echo "Repository already exists"

# Login to ECR
echo -e "${BLUE}Authenticating with ECR...${NC}"
aws ecr get-login-password --region $REGION | \
    docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Tag and push the image
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG"
echo -e "${BLUE}Tagging and pushing Lambda-compatible image to ECR...${NC}"
docker tag $REPOSITORY_NAME:$IMAGE_TAG $ECR_URI
docker push $ECR_URI

echo -e "${GREEN}✅ Lambda-compatible image built and pushed successfully${NC}"
echo -e "${BLUE}ECR URI: $ECR_URI${NC}"
echo -e "${GREEN}📋 Image manifest: Docker v2 (Lambda compatible)${NC}"
echo ""

# Step 4: Create IAM role for Lambda if it doesn't exist
echo -e "${YELLOW}🔐 Step 4: Setting up IAM execution role...${NC}"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

# Check if role exists
if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    echo -e "${BLUE}Creating IAM role: $ROLE_NAME${NC}"
    
    # Trust policy for Lambda
    TRUST_POLICY='{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }'
    
    # Create the role
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document "$TRUST_POLICY" \
        --description "Execution role for $FUNCTION_NAME Lambda function" >/dev/null
    
    # Attach basic Lambda execution policy
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    
    echo -e "${GREEN}✅ IAM role created: $ROLE_NAME${NC}"
    
    # Wait for role to propagate
    echo -e "${BLUE}Waiting for role to propagate...${NC}"
    sleep 10
else
    echo -e "${GREEN}✅ IAM role already exists: $ROLE_NAME${NC}"
fi
echo ""

# Step 5: Handle existing Lambda function
echo -e "${YELLOW}🔄 Step 5: Managing Lambda function...${NC}"

# First, wait for any existing updates to complete
echo -e "${BLUE}Checking for in-progress updates...${NC}"
MAX_UPDATE_WAIT=120
UPDATE_WAIT_COUNT=0

while [ $UPDATE_WAIT_COUNT -lt $MAX_UPDATE_WAIT ]; do
    LAST_UPDATE_STATUS=$(aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" --query 'Configuration.LastUpdateStatus' --output text 2>/dev/null || echo "NotFound")
    
    if [ "$LAST_UPDATE_STATUS" = "NotFound" ]; then
        echo -e "${BLUE}Function doesn't exist - will create new one${NC}"
        break
    elif [ "$LAST_UPDATE_STATUS" = "InProgress" ]; then
        echo -e "${YELLOW}Update in progress - waiting... (${UPDATE_WAIT_COUNT}s/${MAX_UPDATE_WAIT}s)${NC}"
        sleep 5
        UPDATE_WAIT_COUNT=$((UPDATE_WAIT_COUNT + 5))
    else
        echo -e "${GREEN}✅ Function is ready for updates (Status: $LAST_UPDATE_STATUS)${NC}"
        break
    fi
done

if [ $UPDATE_WAIT_COUNT -ge $MAX_UPDATE_WAIT ]; then
    echo -e "${RED}❌ Function update is taking too long. Please wait and try again later.${NC}"
    exit 1
fi

if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo -e "${BLUE}Function exists - updating with new Lambda-compatible image...${NC}"
    
    # Update the function code with new image
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --image-uri "$ECR_URI" \
        --region "$REGION" >/dev/null
    
    echo -e "${BLUE}Waiting for code update to complete...${NC}"
    
    # Wait for the code update to complete before updating configuration
    CODE_UPDATE_WAIT=0
    MAX_CODE_WAIT=60
    
    while [ $CODE_UPDATE_WAIT -lt $MAX_CODE_WAIT ]; do
        UPDATE_STATUS=$(aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" --query 'Configuration.LastUpdateStatus' --output text)
        
        if [ "$UPDATE_STATUS" = "Successful" ]; then
            echo -e "${GREEN}✅ Code update completed successfully${NC}"
            break
        elif [ "$UPDATE_STATUS" = "Failed" ]; then
            echo -e "${RED}❌ Code update failed${NC}"
            exit 1
        else
            echo -e "${YELLOW}Code update in progress... (${CODE_UPDATE_WAIT}s/${MAX_CODE_WAIT}s)${NC}"
            sleep 3
            CODE_UPDATE_WAIT=$((CODE_UPDATE_WAIT + 3))
        fi
    done
    
    if [ $CODE_UPDATE_WAIT -ge $MAX_CODE_WAIT ]; then
        echo -e "${RED}❌ Code update is taking too long. Continuing without configuration update.${NC}"
    else
        # Now update configuration
        echo -e "${BLUE}Updating function configuration...${NC}"
        aws lambda update-function-configuration \
            --function-name "$FUNCTION_NAME" \
            --timeout "$TIMEOUT" \
            --memory-size "$MEMORY" \
            --region "$REGION" >/dev/null
    fi
    
    echo -e "${GREEN}✅ Function updated with Lambda-compatible image${NC}"
else
    echo -e "${BLUE}Creating new Lambda function with Lambda-compatible image...${NC}"
    
    # Create new function
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --role "$ROLE_ARN" \
        --code ImageUri="$ECR_URI" \
        --package-type Image \
        --timeout "$TIMEOUT" \
        --memory-size "$MEMORY" \
        --region "$REGION" \
        --output table \
        --query '{FunctionName:FunctionName,State:State,Runtime:PackageType,Architecture:Architectures[0]}'
    
    echo -e "${GREEN}✅ Lambda function created successfully${NC}"
fi
echo ""

# Step 6: Wait for function to be ready
echo -e "${YELLOW}⏳ Step 6: Waiting for function to be ready...${NC}"
MAX_WAIT=60
WAIT_COUNT=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    STATE=$(aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" --query 'Configuration.State' --output text)
    LAST_UPDATE_STATUS=$(aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" --query 'Configuration.LastUpdateStatus' --output text)
    
    if [ "$STATE" = "Active" ] && [ "$LAST_UPDATE_STATUS" = "Successful" ]; then
        echo -e "${GREEN}✅ Function is active and ready${NC}"
        break
    else
        echo -e "${BLUE}Current state: $STATE ($LAST_UPDATE_STATUS) - waiting...${NC}"
        sleep 2
        WAIT_COUNT=$((WAIT_COUNT + 2))
    fi
done

if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
    echo -e "${RED}Function is taking too long to be ready. Check AWS console.${NC}"
    exit 1
fi
echo ""

# Step 7: Set environment variables
echo -e "${YELLOW}🔧 Step 7: Setting environment variables...${NC}"

# Read .env file and build JSON
ENV_VARS=""
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Extract key=value pairs
    if [[ "$line" =~ ^[[:space:]]*([^=]+)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        
        # Clean up key and value
        key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^["'\'']*//;s/["'\'']*$//')
        
        # Escape for JSON
        value=$(echo "$value" | sed 's/"/\\"/g')
        
        # Build JSON
        if [ -z "$ENV_VARS" ]; then
            ENV_VARS="\"$key\":\"$value\""
        else
            ENV_VARS="$ENV_VARS,\"$key\":\"$value\""
        fi
        
        echo -e "${BLUE}  ✓ $key${NC}"
    fi
done < "$ENV_FILE"

# Update function with environment variables
ENV_CONFIG="{\"Variables\":{$ENV_VARS}}"
aws lambda update-function-configuration \
    --function-name "$FUNCTION_NAME" \
    --region "$REGION" \
    --environment "$ENV_CONFIG" >/dev/null

echo -e "${GREEN}✅ Environment variables set successfully${NC}"
echo ""

# Step 8: Create or update Function URL
echo -e "${YELLOW}🌐 Step 8: Setting up Function URL...${NC}"

# Check if Function URL already exists
EXISTING_URL=$(aws lambda get-function-url-config \
    --function-name "$FUNCTION_NAME" \
    --region "$REGION" \
    --query 'FunctionUrl' \
    --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_URL" ] && [ "$EXISTING_URL" != "None" ]; then
    echo -e "${GREEN}✅ Function URL already exists: ${BLUE}$EXISTING_URL${NC}"
    FUNCTION_URL=$EXISTING_URL
else
    echo -e "${BLUE}Creating Function URL with Lambda-compatible CORS...${NC}"
    
    # Try creating with CORS first
    FUNCTION_URL=$(aws lambda create-function-url-config \
        --function-name "$FUNCTION_NAME" \
        --region "$REGION" \
        --auth-type NONE \
        --cors '{
            "AllowCredentials": true,
            "AllowHeaders": ["*"],
            "AllowMethods": ["GET", "POST", "PUT"],
            "AllowOrigins": ["*"],
            "ExposeHeaders": ["*"],
            "MaxAge": 86400
        }' \
        --query 'FunctionUrl' \
        --output text 2>/dev/null)
    
    # If CORS creation failed, try without CORS
    if [ -z "$FUNCTION_URL" ] || [ "$FUNCTION_URL" = "None" ]; then
        echo -e "${YELLOW}⚠️  CORS creation failed, creating without CORS configuration...${NC}"
        FUNCTION_URL=$(aws lambda create-function-url-config \
            --function-name "$FUNCTION_NAME" \
            --region "$REGION" \
            --auth-type NONE \
            --query 'FunctionUrl' \
            --output text 2>/dev/null)
    fi
    
    if [ -n "$FUNCTION_URL" ] && [ "$FUNCTION_URL" != "None" ]; then
        echo -e "${GREEN}✅ Function URL created: ${BLUE}$FUNCTION_URL${NC}"
    else
        echo -e "${RED}❌ Failed to create Function URL. You can create it manually in the AWS console.${NC}"
        FUNCTION_URL="[CREATE_MANUALLY_IN_CONSOLE]"
    fi
fi
echo ""

# Step 9: Test the endpoint
echo -e "${YELLOW}🧪 Step 9: Testing the endpoint...${NC}"

# Wait a moment for URL to be ready
sleep 5

MAX_RETRIES=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo -e "${BLUE}Testing attempt $((RETRY_COUNT + 1))/${MAX_RETRIES}...${NC}"
    
    if curl -s --max-time 15 "$FUNCTION_URL" >/dev/null 2>&1; then
        RESPONSE=$(curl -s "$FUNCTION_URL" | head -c 200)
        echo -e "${GREEN}✅ Endpoint is responding!${NC}"
        echo -e "${BLUE}Response preview: $RESPONSE${NC}"
        break
    else
        echo -e "${YELLOW}⏳ Endpoint not ready yet, waiting...${NC}"
        sleep 5
        RETRY_COUNT=$((RETRY_COUNT + 1))
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${YELLOW}⚠️  Endpoint might still be initializing. You can test it manually.${NC}"
fi

echo ""

# Step 10: Show final information
echo -e "${PURPLE}🎉 DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉${NC}"
echo ""
echo -e "${GREEN}📋 DEPLOYMENT SUMMARY:${NC}"
echo -e "${BLUE}  • Function Name: $FUNCTION_NAME${NC}"
echo -e "${BLUE}  • Region: $REGION${NC}"
echo -e "${BLUE}  • Architecture: x86_64${NC}"
echo -e "${BLUE}  • Image Format: Docker v2 (Lambda compatible)${NC}"
echo -e "${BLUE}  • Timeout: ${TIMEOUT}s${NC}"
echo -e "${BLUE}  • Memory: ${MEMORY}MB${NC}"
echo -e "${BLUE}  • IAM Role: $ROLE_NAME${NC}"
echo -e "${BLUE}  • ECR Image: $ECR_URI${NC}"
echo ""
echo -e "${GREEN}🌐 YOUR API ENDPOINT:${NC}"
echo -e "${YELLOW}$FUNCTION_URL${NC}"
echo ""
echo -e "${GREEN}🧪 TEST COMMANDS:${NC}"
echo -e "${BLUE}# Health check:${NC}"
echo -e "curl '$FUNCTION_URL'"
echo ""
echo -e "${BLUE}# Available API endpoints (require authentication):${NC}"
echo -e "curl -X POST '$FUNCTION_URL/api/generate-summary' \\"
echo -e "  -H 'Content-Type: application/json' \\"
echo -e "  -H 'Cookie: auth_token=YOUR_JWT_TOKEN' \\"
echo -e "  -d '{\"jobDescription\":\"Backend developer\",\"targetPosition\":\"Senior Engineer\",\"targetCompany\":\"TechCorp\"}'"
echo ""
echo -e "${BLUE}# Other endpoints:${NC}"
echo -e "# POST /api/generate-education"
echo -e "# POST /api/generate-experience"
echo -e "# POST /api/generate-project"
echo -e "# POST /api/generate-certification"
echo -e "# POST /api/generate-publication"
echo ""
echo -e "${GREEN}🔗 AWS Console Links:${NC}"
echo -e "${BLUE}Lambda Function: https://ap-south-1.console.aws.amazon.com/lambda/home?region=ap-south-1#/functions/$FUNCTION_NAME${NC}"
echo -e "${BLUE}CloudWatch Logs: https://ap-south-1.console.aws.amazon.com/cloudwatch/home?region=ap-south-1#logsV2:log-groups/log-group/\$252Faws\$252Flambda\$252F$FUNCTION_NAME${NC}"
echo -e "${BLUE}IAM Role: https://console.aws.amazon.com/iam/home#/roles/$ROLE_NAME${NC}"
echo -e "${BLUE}ECR Repository: https://ap-south-1.console.aws.amazon.com/ecr/repositories/private/$ACCOUNT_ID/$REPOSITORY_NAME${NC}"
echo ""
echo -e "${GREEN}💡 This script is safe to run multiple times!${NC}"
echo -e "${GREEN}✅ Your FastAPI Resume Completion service is now live on AWS Lambda!${NC}" 