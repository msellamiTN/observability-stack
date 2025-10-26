#!/bin/bash

# Setup Grafana Alerting with Environment Variables
# This script substitutes environment variables in the contactpoints.yaml file

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Setting up Grafana Alerting Configuration...${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found!${NC}"
    echo -e "${YELLOW}Please create .env file from .env.alerting.example${NC}"
    exit 1
fi

# Load environment variables
source .env

# Check if SLACK_WEBHOOK_URL is set
if [ -z "$SLACK_WEBHOOK_URL" ] || [ "$SLACK_WEBHOOK_URL" = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" ]; then
    echo -e "${RED}❌ SLACK_WEBHOOK_URL is not configured in .env file${NC}"
    echo -e "${YELLOW}Please set your Slack webhook URL in .env${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Environment variables loaded${NC}"
echo -e "${BLUE}📝 Slack Webhook: ${SLACK_WEBHOOK_URL:0:40}...${NC}"

# Create temporary contactpoints file with substituted values
TEMPLATE_FILE="grafana/provisioning/alerting/contactpoints.yaml"
TEMP_FILE="grafana/provisioning/alerting/contactpoints.yaml.tmp"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}❌ Template file not found: $TEMPLATE_FILE${NC}"
    exit 1
fi

# Substitute environment variables
envsubst < "$TEMPLATE_FILE" > "$TEMP_FILE"

# Validate the generated file
if grep -q "\${SLACK_WEBHOOK_URL}" "$TEMP_FILE"; then
    echo -e "${RED}❌ Environment variable substitution failed${NC}"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo -e "${GREEN}✅ Configuration file generated successfully${NC}"
echo -e "${BLUE}📄 Generated: $TEMP_FILE${NC}"

# Optional: Move the temp file to replace the original (for runtime)
# mv "$TEMP_FILE" "$TEMPLATE_FILE"

echo -e "${GREEN}✅ Alerting setup complete!${NC}"
echo -e "${YELLOW}Note: The template file still contains \${SLACK_WEBHOOK_URL} placeholder${NC}"
echo -e "${YELLOW}The actual webhook URL is stored securely in .env file${NC}"
