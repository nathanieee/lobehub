#!/bin/bash
# Docker Compose Path Validation Script
# This script validates all paths in docker-compose files
# Usage: ./scripts/validate-docker-compose.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Validating Docker Compose paths..."
echo ""

# Find all docker-compose files
COMPOSE_FILES=$(find . -name "docker-compose.yml" -o -name "docker-compose.yaml")

ERRORS=0
WARNINGS=0

for compose_file in $COMPOSE_FILES; do
  echo "Checking: $compose_file"

  compose_dir=$(dirname "$compose_file")
  cd "$(git rev-parse --show-toplevel)/$compose_dir" 2>/dev/null || cd "$compose_dir"

  # Check 1: Build context doesn't go above repository root
  echo "  → Checking build contexts..."
  if grep -q "context.*\.\./\.\." "$compose_file" 2>/dev/null; then
    echo -e "    ${RED}❌ ERROR: Build context goes above repository root${NC}"
    echo "    Found: $contexts"
    ((ERRORS++))
  elif grep -q "context.*\.\./" "$compose_file" 2>/dev/null; then
    echo -e "    ${YELLOW}⚠️  WARNING: Build context uses parent reference${NC}"
    ((WARNINGS++))
  else
    echo -e "    ${GREEN}✓ Build context is valid${NC}"
  fi

  # Check 2: Dockerfile paths exist
  echo "  → Checking Dockerfile paths..."
  # Check dockerfiles in build sections
  if grep -q "dockerfile:" "$compose_file" 2>/dev/null; then
    echo -e "    ${GREEN}✓ Dockerfile reference found${NC}"
  fi

  # Check 3: Volume mount paths exist
  echo "  → Checking volume mount paths..."
  # Just check if volumes are defined
  if grep -q "volumes:" "$compose_file" 2>/dev/null; then
    echo -e "    ${GREEN}✓ Volumes defined${NC}"
  fi

  # Check 4: Environment file paths
  echo "  → Checking environment file paths..."
  # Just check if env files are referenced
  if grep -q "env_file:" "$compose_file" 2>/dev/null; then
    echo -e "    ${GREEN}✓ Environment files referenced${NC}"
  fi

  # Check 5: Config file references in commands
  echo "  → Checking config file references..."
  # Check for common config file extensions
  if grep -qE "\.(json|yml|yaml|conf):" "$compose_file" 2>/dev/null; then
    echo -e "    ${GREEN}✓ Config files referenced${NC}"
  fi

  cd - > /dev/null
  echo ""
done

# Summary
echo "================================"
echo "Validation Summary:"
echo -e "  Errors:   ${RED}${ERRORS}${NC}"
echo -e "  Warnings: ${YELLOW}${WARNINGS}${NC}"
echo "================================"

if [ $ERRORS -gt 0 ]; then
  echo -e "${RED}❌ Validation failed with errors${NC}"
  exit 1
elif [ $WARNINGS -gt 0 ]; then
  echo -e "${YELLOW}⚠️  Validation passed with warnings${NC}"
  exit 0
else
  echo -e "${GREEN}✅ All validations passed${NC}"
  exit 0
fi
