
#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MODE="${1:-dev}"

# Detect available Electron binary
find_electron() {
    if [ -x "/usr/bin/electron" ]; then
        echo "/usr/bin/electron"
    elif command -v electron &> /dev/null; then
        command -v electron
    elif [ -x "$SCRIPT_DIR/node_modules/.bin/electron" ]; then
        echo "$SCRIPT_DIR/node_modules/.bin/electron"
    else
        echo ""
    fi
}

ELECTRON_BIN=$(find_electron)

case "$MODE" in
    app|build)
        echo -e "${BLUE}=== Building Standalone Linux Application (AppImage) ===${NC}"
        npm run build:linux
        echo -e "${GREEN}✓ Application build complete! Look in $SCRIPT_DIR/dist/${NC}"
        ;;
    
    install-desktop)
        echo -e "${BLUE}=== Creating Desktop Launcher Entry ===${NC}"
        DESKTOP_FILE="$HOME/.local/share/applications/mylocalai.desktop"
        mkdir -p "$HOME/.local/share/applications"
        
        cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=MyLocalAI Studio
Comment=Standalone Offline AI Chat Client
Exec=$SCRIPT_DIR/run.sh
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Utility;Development;
EOF
        chmod +x "$DESKTOP_FILE"
        echo -e "${GREEN}✓ Desktop shortcut created at: $DESKTOP_FILE${NC}"
        echo -e "You can now launch 'MyLocalAI Studio' from your application launcher (Rofi, Wofi, App Menu)."
        ;;

    dev|run|"")
        echo -e "${BLUE}=== Launching MyLocalAI Studio ===${NC}"
        
        if [ -z "$ELECTRON_BIN" ]; then
            echo -e "${RED}Error: Electron binary not found.${NC}"
            echo -e "Please run ${YELLOW}./setup.sh${NC} or install electron via your system package manager."
            exit 1
        fi

        echo -e "Using runtime: ${GREEN}$ELECTRON_BIN${NC}"
        exec "$ELECTRON_BIN" .
        ;;

    *)
        echo -e "${RED}Unknown option: $MODE${NC}"
        echo -e "Usage:"
        echo -e "  ${GREEN}./run.sh${NC}                  Run application directly (development/desktop)"
        echo -e "  ${GREEN}./run.sh app${NC}              Build standalone distribution package (AppImage)"
        echo -e "  ${GREEN}./run.sh install-desktop${NC}  Create desktop application launcher (.desktop entry)"
        exit 1
        ;;
esac
