#!/usr/bin/env bash
# Exam Converter - Markdown to Canvas QTI
# Uses examark for conversion
# OPTIONAL: Only needed if using exam workflow (Increment 3)

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

EXAM_FILE="$1"

if [[ -z "$EXAM_FILE" ]]; then
  echo -e "${RED}Usage: exam-to-qti.sh <exam-file.md>${NC}"
  exit 1
fi

if [[ ! -f "$EXAM_FILE" ]]; then
  echo -e "${RED}❌ Exam file not found: $EXAM_FILE${NC}"
  exit 1
fi

# Check examark installed
if ! command -v examark &>/dev/null; then
  echo -e "${RED}❌ examark not installed${NC}"
  echo -e "${YELLOW}Install: npm install -g examark${NC}"
  exit 1
fi

echo -e "${BLUE}📝 Converting exam to Canvas format...${NC}"
examark "$EXAM_FILE" -o "${EXAM_FILE%.md}.qti.zip"

if [[ $? -eq 0 ]]; then
  echo ""
  echo -e "${GREEN}✅ Canvas file ready: ${EXAM_FILE%.md}.qti.zip${NC}"
  echo -e "${BLUE}📤 Upload to Canvas manually${NC}"
  echo ""
  echo -e "${YELLOW}💡 Tip: Open Canvas in browser and upload the .qti.zip file${NC}"
else
  echo -e "${RED}❌ Conversion failed${NC}"
  exit 1
fi
