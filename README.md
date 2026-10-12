# MyLocalAI Studio

A standalone, offline desktop AI chat client built with **Electron**, **Node.js**, and **`node-llama-cpp`**. It runs GGUF language models directly in-process with hardware acceleration (NVIDIA CUDA / Vulkan) without requiring background daemon servers or Python.

---

## Cross-Platform Behavior

### 1. Will `setup.sh` identify the OS and install all dependencies?
**Yes.**
- **Automatic OS Detection:** Identifies whether you are running **Linux**, **macOS**, or **Windows** (Git Bash/WSL/MSYS).
- **Dependency Installation:** Runs `npm install` to create `node_modules/` and install `node-llama-cpp` and Electron.
- **Guidance & Runtime Configuration:** If Node.js is missing, it provides the exact package manager commands for your specific distro (Ubuntu/Debian, Arch/CachyOS, Fedora, macOS Homebrew, or Windows).

### 2. Will `run.sh` install a desktop launcher on all kinds of OS?
**Yes.** When running `./run.sh install-desktop`:
- **On Linux:** Automatically creates a `.desktop` shortcut in `~/.local/share/applications/mylocalai.desktop` (accessible via Wofi, Rofi, GNOME, KDE, or Hyprland app menus).
- **On macOS:** Creates a native `.app` bundle in `~/Applications/MyLocalAI Studio.app` (accessible via Spotlight and Launchpad).
- **On Windows:** Generates a desktop `.lnk` shortcut on your Windows Desktop.

---

## Project Structure

```
my-local-ai/
├── package.json        # Dependencies & electron-builder packaging config
├── main.js             # Electron main process & in-process LLM lifecycle
├── preload.js          # Secure contextBridge API
├── index.html          # Chat UI, streaming Markdown parser & attachment cards
├── setup.sh            # Cross-platform automated setup script
├── run.sh              # Cross-platform runner and desktop installer script
└── models/             # Directory where .gguf models are placed
```

---

## Quick Start

### Step 1: Run Setup
Run the setup script:
```bash
./setup.sh
```

### Step 2: Add GGUF Models
Place any `.gguf` model (e.g. `gemma-4-E2B-it-uncensored-Q4_K_M.gguf`, `Llama-3.2-3B-Instruct.gguf`) into the `models/` directory:
```bash
cp /path/to/your-model.gguf ./models/
```

### Step 3: Run the Application
Start the app:
```bash
./run.sh
```

---

## `run.sh` Execution Modes

| Command | Action | Platform Behavior |
|---|---|---|
| `./run.sh` | **Direct Launch** | Detects local/system Electron and launches the desktop app. |
| `./run.sh install-desktop` | **Install Launcher** | • **Linux**: Installs to `~/.local/share/applications/`<br>• **macOS**: Installs to `~/Applications/`<br>• **Windows**: Installs `.lnk` on Desktop |
| `./run.sh uninstall-desktop` | **Remove Launcher** | Removes the desktop launcher / shortcut on any OS. |
| `./run.sh clean` | **Uninstall & Reset** | Removes desktop launcher, `dist/` builds, and `node_modules/` (safely keeps your models). |
| `./run.sh app` | **Package App** | Builds a standalone distributable:<br>• **Linux**: `.AppImage`<br>• **macOS**: `.dmg`<br>• **Windows**: `.exe` (NSIS) |

---

## Uninstallation

To remove the application or reset dependencies:

1. **Remove Desktop Launcher Only:**
   ```bash
   ./run.sh uninstall-desktop
   ```
   Removes the `.desktop` file (Linux), `.app` bundle (macOS), or `.lnk` shortcut (Windows).

2. **Clean Reset (Remove dependencies, builds & launcher):**
   ```bash
   ./run.sh clean
   ```
   Deletes `node_modules/`, `dist/`, and the desktop launcher while **keeping your downloaded `.gguf` files intact** in `models/`.

3. **Complete Removal:**
   Simply delete the project folder:
   ```bash
   ./run.sh uninstall-desktop
   cd .. && rm -rf Assis-in-pendrive
   ```

---

## Features

- **Hardware Acceleration**: Automatic CUDA (NVIDIA) and Vulkan GPU layer offloading.
- **Markdown Support**: Renders headers, lists, blockquotes, code blocks, and tables in real time as tokens stream.
- **File Upload Support**: Attach text and code files (`.txt`, `.py`, `.js`, `.json`, `.md`, `.cpp`, etc.) directly into your conversation context with dedicated attachment cards and remove buttons.
- **Frameless UI**: Minimal, borderless window with an ASCII logo and custom window controls.
- **100% Offline & Private**: Zero external background binaries, cloud connections, or background services.
