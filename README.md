# MyLocalAI Studio

A standalone, offline desktop AI chat client built with **Electron**, **Node.js**, and **`node-llama-cpp`**. It executes GGUF language models directly in-process with hardware acceleration (NVIDIA CUDA / Vulkan) without requiring background server binaries, Ollama daemons, or Python.

---

## Features

- **In-Process Inference**: Runs entirely in Node.js via `node-llama-cpp` bindings.
- **Hardware Acceleration**: Automatic GPU offloading (NVIDIA CUDA & Vulkan) with custom layer offload options.
- **Frameless Modern UI**: Dark-themed, borderless window with an ASCII logo and custom window controls.
- **Full Markdown Support**: Live streaming Markdown rendering with code blocks, headings, blockquotes, lists, and tables.
- **File Attachment Support**: Attach code and text files (`.txt`, `.py`, `.js`, `.json`, `.md`, `.cpp`, etc.) directly into your conversation context with dedicated attachment cards.
- **Zero Cloud Dependencies**: 100% offline and private.

---

## Project Structure

```
my-local-ai/
├── package.json        # Dependencies & electron-builder packaging config
├── main.js             # Electron main process & in-process LLM lifecycle
├── preload.js          # Secure contextBridge API
├── index.html          # Chat interface, Markdown parser, & attachment widgets
├── setup.sh            # Automated environment setup script
├── run.sh              # Application runner and packager script
└── models/             # Directory where .gguf models are placed
```

---

## Quick Start

### 1. Run Setup
Run the setup script to install dependencies and prepare the directory:
```bash
./setup.sh
```

### 2. Add Models
Place any `.gguf` model (e.g. `gemma-4-E2B-it-uncensored-Q4_K_M.gguf`, `Llama-3.2-3B-Instruct.gguf`) into the `models/` directory:
```bash
cp /path/to/your-model.gguf ./models/
```

### 3. Launch the Application
Run the client with `run.sh`:
```bash
./run.sh
```

---

## Using `run.sh`

The `run.sh` helper supports multiple execution modes:

### 1. Launch Directly (Development / Daily Use)
```bash
./run.sh
```
Automatically detects your system or local Electron binary and launches the application.

### 2. Install as a Desktop Application Launcher
```bash
./run.sh install-desktop
```
Registers a `.desktop` shortcut in `~/.local/share/applications/` so you can launch **MyLocalAI Studio** directly from your system app menu, Wofi, or Rofi.

### 3. Build a Standalone Application Package (AppImage)
```bash
./run.sh app
```
Bundles the application and your models into a standalone Linux AppImage in the `dist/` folder using `electron-builder`.

---

## Chat & Controls

| Feature | Description |
|---|---|
| **Model Dropdown** | Automatically detects all `.gguf` files inside the `models/` folder. |
| **Load Button** | Initializes the model on your GPU and prepares the context session. |
| **Attach File (`+ Attach File`)** | Attaches files to your prompt with a dedicated status card and remove button. |
| **Config Button** | Adjust temperature, GPU layer offloading, and context size. |
| **Clear Button** | Clears the chat screen without discarding model weights from memory. |

---

## Hardware Acceleration (CUDA / GPU)

The application automatically offloads layers to your GPU when available:
- **NVIDIA GPUs**: Utilizes CUDA bindings for high-speed inference.
- **Vulkan**: Supported across multi-vendor GPUs (AMD / Intel).
- Layer offload mode defaults to **Auto Fit**, allocating maximum layers to VRAM according to the active context size.
