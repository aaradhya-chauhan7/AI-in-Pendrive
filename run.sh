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

# Detect OS platform
OS="$(uname -s)"
case "$OS" in
    Linux*)     PLATFORM="linux" ;;
    Darwin*)    PLATFORM="macos" ;;
    CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
    *)          PLATFORM="unknown" ;;
esac

# Find available Electron binary based on platform
find_electron() {
    if [ "$PLATFORM" = "linux" ] && [ -x "/usr/bin/electron" ]; then
        echo "/usr/bin/electron"
    elif command -v electron &> /dev/null; then
        command -v electron
    elif [ -x "$SCRIPT_DIR/node_modules/.bin/electron" ]; then
        echo "$SCRIPT_DIR/node_modules/.bin/electron"
    elif [ "$PLATFORM" = "windows" ] && [ -f "$SCRIPT_DIR/node_modules/.bin/electron.cmd" ]; then
        echo "$SCRIPT_DIR/node_modules/.bin/electron.cmd"
    else
        echo "npx electron"
    fi
}

ELECTRON_BIN=$(find_electron)

case "$MODE" in
    app|build)
        echo -e "${BLUE}=== Building Standalone Application Package for $PLATFORM ===${NC}"
        case "$PLATFORM" in
            linux)
                npm run build:linux
                echo -e "${GREEN}✓ Linux AppImage package generated in: $SCRIPT_DIR/dist/${NC}"
                ;;
            macos)
                npm run build:mac
                echo -e "${GREEN}✓ macOS DMG package generated in: $SCRIPT_DIR/dist/${NC}"
                ;;
            windows)
                npm run build:win
                echo -e "${GREEN}✓ Windows NSIS Installer generated in: $SCRIPT_DIR/dist/${NC}"
                ;;
            *)
                npm run build
                ;;
        esac
        ;;
    
    install-desktop)
        echo -e "${BLUE}=== Creating Desktop Launcher for $PLATFORM ===${NC}"
        case "$PLATFORM" in
            linux)
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
                echo -e "${GREEN}✓ Linux .desktop shortcut created at: $DESKTOP_FILE${NC}"
                echo -e "You can now launch 'MyLocalAI Studio' from your application menu (Rofi, Wofi, GNOME, KDE)."
                ;;

            macos)
                APP_DIR="$HOME/Applications/MyLocalAI Studio.app"
                mkdir -p "$APP_DIR/Contents/MacOS"
                cat > "$APP_DIR/Contents/MacOS/launcher" << EOF
#!/bin/bash
cd "$SCRIPT_DIR" && ./run.sh
EOF
                chmod +x "$APP_DIR/Contents/MacOS/launcher"
                echo -e "${GREEN}✓ macOS Application launcher created at: $APP_DIR${NC}"
                echo -e "You can now open 'MyLocalAI Studio' from Spotlight or your Applications folder."
                ;;

            windows)
                VBS_SCRIPT="$SCRIPT_DIR/create_shortcut.vbs"
                DESKTOP_PATH="$USERPROFILE/Desktop"
                cat > "$VBS_SCRIPT" << EOF
Set oWS = WScript.CreateObject("WScript.Shell")
sLinkFile = "$DESKTOP_PATH\MyLocalAI Studio.lnk"
Set oLink = oWS.CreateShortcut(sLinkFile)
oLink.TargetPath = "$SCRIPT_DIR\run.bat"
oLink.WorkingDirectory = "$SCRIPT_DIR"
oLink.Description = "MyLocalAI Studio"
oLink.Save
EOF
                cscript //nologo "$VBS_SCRIPT" 2>/dev/null && rm -f "$VBS_SCRIPT" || true
                echo -e "${GREEN}✓ Windows Desktop Shortcut created on your Desktop.${NC}"
                ;;

            *)
                echo -e "${YELLOW}Desktop launcher creation not supported on $PLATFORM.${NC}"
                ;;
        esac
        ;;

    uninstall-desktop|remove-desktop)
        echo -e "${BLUE}=== Removing Desktop Launcher for $PLATFORM ===${NC}"
        case "$PLATFORM" in
            linux)
                DESKTOP_FILE="$HOME/.local/share/applications/mylocalai.desktop"
                if [ -f "$DESKTOP_FILE" ]; then
                    rm -f "$DESKTOP_FILE"
                    echo -e "${GREEN}✓ Removed Linux desktop shortcut: $DESKTOP_FILE${NC}"
                else
                    echo -e "${YELLOW}No desktop shortcut found at $DESKTOP_FILE${NC}"
                fi
                ;;

            macos)
                APP_DIR="$HOME/Applications/MyLocalAI Studio.app"
                if [ -d "$APP_DIR" ]; then
                    rm -rf "$APP_DIR"
                    echo -e "${GREEN}✓ Removed macOS app bundle: $APP_DIR${NC}"
                else
                    echo -e "${YELLOW}No app bundle found at $APP_DIR${NC}"
                fi
                ;;

            windows)
                DESKTOP_PATH="$USERPROFILE/Desktop/MyLocalAI Studio.lnk"
                if [ -f "$DESKTOP_PATH" ]; then
                    rm -f "$DESKTOP_PATH"
                    echo -e "${GREEN}✓ Removed Windows desktop shortcut.${NC}"
                else
                    echo -e "${YELLOW}No desktop shortcut found.${NC}"
                fi
                ;;
        esac
        ;;

    clean|uninstall-all)
        echo -e "${YELLOW}=== Uninstalling & Cleaning MyLocalAI Studio ===${NC}"
        # 1. Remove desktop launcher
        "$SCRIPT_DIR/run.sh" uninstall-desktop

        # 2. Remove build artifacts
        if [ -d "$SCRIPT_DIR/dist" ]; then
            rm -rf "$SCRIPT_DIR/dist"
            echo -e "${GREEN}✓ Removed dist/ build artifacts.${NC}"
        fi

        # 3. Remove node_modules
        if [ -d "$SCRIPT_DIR/node_modules" ]; then
            echo -e "${YELLOW}Removing node_modules/...${NC}"
            rm -rf "$SCRIPT_DIR/node_modules"
            echo -e "${GREEN}✓ Removed node_modules/.${NC}"
        fi

        echo -e "${GREEN}✓ Clean uninstallation complete.${NC}"
        echo -e "Note: Your .gguf files in ${BLUE}models/${NC} were kept intact."
        ;;

    dev|run|"")
        echo -e "${BLUE}=== Launching MyLocalAI Studio ($PLATFORM) ===${NC}"
        echo -e "Using runtime: ${GREEN}$ELECTRON_BIN${NC}"
        exec $ELECTRON_BIN .
        ;;

    *)
        echo -e "${RED}Unknown option: $MODE${NC}"
        echo -e "Usage:"
        echo -e "  ${GREEN}./run.sh${NC}                    Run application directly"
        echo -e "  ${GREEN}./run.sh app${NC}                Build standalone distribution package ($PLATFORM)"
        echo -e "  ${GREEN}./run.sh install-desktop${NC}    Create native desktop launcher ($PLATFORM)"
        echo -e "  ${GREEN}./run.sh uninstall-desktop${NC}  Remove native desktop launcher ($PLATFORM)"
        echo -e "  ${GREEN}./run.sh clean${NC}              Remove launcher, dist/ & node_modules/ (keeps models)"
        exit 1
        ;;
esac
