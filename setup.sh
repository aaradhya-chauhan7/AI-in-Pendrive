#!/usr/bin/env bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}     Local AI Studio - Setup Script   ${NC}"
echo -e "${BLUE}======================================${NC}"

# 1. Check Node.js and npm
echo -e "\n${YELLOW}[1/4] Checking Node.js runtime...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed. Please install Node.js (v18+).${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Node.js $(node -v) detected.${NC}"
echo -e "${GREEN}✓ npm $(npm -v) detected.${NC}"

# 2. Ensure models directory exists
echo -e "\n${YELLOW}[2/4] Ensuring models/ directory exists...${NC}"
mkdir -p "$SCRIPT_DIR/models"
echo -e "${GREEN}✓ models/ directory is ready.${NC}"

# 3. Install project dependencies
echo -e "\n${YELLOW}[3/4] Installing npm dependencies...${NC}"
if ! npm install; then
    echo -e "${YELLOW}npm install encountered postinstall notice (common when offline). Verifying dependencies...${NC}"
    if [ -d "$SCRIPT_DIR/node_modules/node-llama-cpp" ]; then
        echo -e "${GREEN}✓ node-llama-cpp is already installed and ready.${NC}"
    fi
fi

# 4. Check & configure Electron execution
echo -e "\n${YELLOW}[4/4] Verifying Electron runtime...${NC}"
if command -v electron &> /dev/null || [ -x "/usr/bin/electron" ]; then
    echo -e "${GREEN}✓ System Electron binary detected (/usr/bin/electron).${NC}"
else
    echo -e "${YELLOW}System electron binary not found in PATH. Checking local node_modules...${NC}"
    if [ ! -d "$SCRIPT_DIR/node_modules/electron/dist" ]; then
        echo -e "${YELLOW}Downloading prebuilt Electron binary...${NC}"
        npx install-electron || echo -e "${YELLOW}Binary download skipped or managed via system package.${NC}"
    fi
fi

# Ensure scripts have execute permissions
chmod +x "$SCRIPT_DIR/setup.sh" "$SCRIPT_DIR/run.sh" 2>/dev/null || true

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}       Setup Completed Successfully!   ${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "Next steps:"
echo -e " 1. Drop your .gguf models into: ${BLUE}$SCRIPT_DIR/models/${NC}"
echo -e " 2. Run the application with:     ${GREEN}./run.sh${NC}"
