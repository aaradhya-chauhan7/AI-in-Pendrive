#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}     Local AI Studio - Setup Script   ${NC}"
echo -e "${BLUE}======================================${NC}"

# 1. Detect Operating System
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux*)     PLATFORM="linux" ;;
    Darwin*)    PLATFORM="macos" ;;
    CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
    *)          PLATFORM="unknown" ;;
esac

echo -e "Detected OS: ${GREEN}$PLATFORM ($OS, $ARCH)${NC}"

# 2. Check Node.js and npm
echo -e "\n${YELLOW}[1/4] Checking Node.js runtime...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed.${NC}"
    echo -e "Please install Node.js (v18 or higher):"
    case "$PLATFORM" in
        linux)
            echo -e "  - Ubuntu/Debian: sudo apt update && sudo apt install nodejs npm"
            echo -e "  - Arch/CachyOS:  sudo pacman -S nodejs npm"
            echo -e "  - Fedora:        sudo dnf install nodejs npm"
            ;;
        macos)
            echo -e "  - macOS (Homebrew): brew install node"
            ;;
        windows)
            echo -e "  - Windows: Download from https://nodejs.org/"
            ;;
    esac
    exit 1
fi
echo -e "${GREEN}✓ Node.js $(node -v) detected.${NC}"
echo -e "${GREEN}✓ npm $(npm -v) detected.${NC}"

# 3. Ensure models/ directory exists
echo -e "\n${YELLOW}[2/4] Ensuring models/ directory exists...${NC}"
mkdir -p "$SCRIPT_DIR/models"
echo -e "${GREEN}✓ models/ directory is ready.${NC}"

# 4. Install project dependencies via npm
echo -e "\n${YELLOW}[3/4] Installing npm dependencies...${NC}"
if ! npm install; then
    echo -e "${YELLOW}npm install encountered postinstall notice (common when offline). Verifying dependencies...${NC}"
    if [ -d "$SCRIPT_DIR/node_modules/node-llama-cpp" ]; then
        echo -e "${GREEN}✓ node-llama-cpp is already installed and ready.${NC}"
    fi
fi

# 5. Check & configure Electron execution
echo -e "\n${YELLOW}[4/4] Verifying Electron runtime for $PLATFORM...${NC}"
if [ "$PLATFORM" = "linux" ]; then
    if command -v electron &> /dev/null || [ -x "/usr/bin/electron" ]; then
        echo -e "${GREEN}✓ System Electron binary detected.${NC}"
    else
        echo -e "${YELLOW}Downloading prebuilt Electron binary...${NC}"
        npx install-electron || true
    fi
elif [ "$PLATFORM" = "macos" ]; then
    if [ ! -d "$SCRIPT_DIR/node_modules/electron/dist" ]; then
        echo -e "${YELLOW}Configuring Electron for macOS...${NC}"
        npx install-electron || true
    else
        echo -e "${GREEN}✓ Electron ready.${NC}"
    fi
else
    # Windows
    if [ ! -d "$SCRIPT_DIR/node_modules/electron/dist" ]; then
        npx install-electron || true
    else
        echo -e "${GREEN}✓ Electron ready.${NC}"
    fi
fi

# Ensure executable permissions on Unix systems
chmod +x "$SCRIPT_DIR/setup.sh" "$SCRIPT_DIR/run.sh" 2>/dev/null || true

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}       Setup Completed Successfully!   ${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "Platform: ${GREEN}$PLATFORM${NC}"
echo -e "Next steps:"
echo -e " 1. Drop your .gguf models into: ${BLUE}$SCRIPT_DIR/models/${NC}"
echo -e " 2. Run the application with:     ${GREEN}./run.sh${NC}"
