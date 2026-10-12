const { app, BrowserWindow, ipcMain, shell, dialog } = require('electron');
const path = require('path');
const fs = require('fs');

let mainWindow = null;
let llamaInstance = null;
let currentModel = null;
let currentContext = null;
let currentChatSession = null;
let currentModelName = null;

// Determine models directory
function getModelsDirectory() {
  const localModelsPath = path.join(__dirname, 'models');
  if (fs.existsSync(localModelsPath)) {
    return localModelsPath;
  }

  const modelsPath = app.isPackaged
    ? path.join(process.resourcesPath, 'models')
    : localModelsPath;

  if (!fs.existsSync(modelsPath)) {
    try {
      fs.mkdirSync(modelsPath, { recursive: true });
    } catch (err) {
      console.warn('Could not create directory at', modelsPath, err.message);
    }
  }
  return modelsPath;
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1100,
    height: 780,
    minWidth: 780,
    minHeight: 560,
    frame: false,
    titleBarStyle: 'hidden',
    backgroundColor: '#0a0d14',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });

  mainWindow.loadFile('index.html');
}

// Window control IPC handlers
ipcMain.handle('window-minimize', () => {
  if (mainWindow) mainWindow.minimize();
});

ipcMain.handle('window-maximize', () => {
  if (mainWindow) {
    if (mainWindow.isMaximized()) {
      mainWindow.unmaximize();
    } else {
      mainWindow.maximize();
    }
  }
});

ipcMain.handle('window-close', () => {
  if (mainWindow) mainWindow.close();
});

// Memory cleanup helper for node-llama-cpp entities
async function cleanupActiveModel() {
  if (currentChatSession) {
    currentChatSession = null;
  }
  if (currentContext) {
    try {
      await currentContext.dispose();
    } catch (err) {
      console.warn('Context disposal warning:', err.message);
    }
    currentContext = null;
  }
  if (currentModel) {
    try {
      await currentModel.dispose();
    } catch (err) {
      console.warn('Model disposal warning:', err.message);
    }
    currentModel = null;
  }
  currentModelName = null;
}

// 1. Scan models/ directory for .gguf files
ipcMain.handle('get-local-models', async () => {
  try {
    const modelsDir = getModelsDirectory();
    const entries = await fs.promises.readdir(modelsDir, { withFileTypes: true });
    const ggufFiles = [];

    for (const entry of entries) {
      if (entry.isFile() && entry.name.toLowerCase().endsWith('.gguf')) {
        const fullPath = path.join(modelsDir, entry.name);
        let size = 0;
        try {
          const stat = await fs.promises.stat(fullPath);
          size = stat.size;
        } catch {
          // ignore stat error
        }
        ggufFiles.push({
          name: entry.name,
          sizeBytes: size,
          sizeFormatted: (size / (1024 * 1024 * 1024)).toFixed(2) + ' GB'
        });
      }
    }

    return { success: true, models: ggufFiles, directory: modelsDir };
  } catch (error) {
    console.error('Error scanning models directory:', error);
    return { success: false, error: error.message, models: [] };
  }
});

// 2. Open models directory in OS file manager
ipcMain.handle('open-models-folder', async () => {
  try {
    const modelsDir = getModelsDirectory();
    await shell.openPath(modelsDir);
    return { success: true, directory: modelsDir };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

// 3. File upload / reader
ipcMain.handle('select-and-read-file', async () => {
  try {
    const { canceled, filePaths } = await dialog.showOpenDialog(mainWindow, {
      title: 'Select File to Upload',
      properties: ['openFile'],
      filters: [
        { name: 'All Files', extensions: ['*'] },
        { name: 'Text & Code', extensions: ['txt', 'md', 'json', 'js', 'ts', 'py', 'c', 'cpp', 'html', 'css', 'yaml', 'yml', 'sh', 'csv'] }
      ]
    });

    if (canceled || filePaths.length === 0) {
      return { success: false, canceled: true };
    }

    const filePath = filePaths[0];
    const fileName = path.basename(filePath);
    const stats = await fs.promises.stat(filePath);

    // Limit text reading to ~1.5 MB to avoid freezing or crashing context
    const maxSizeBytes = 1.5 * 1024 * 1024;
    let content = '';
    let isTruncated = false;

    if (stats.size > maxSizeBytes) {
      const buffer = Buffer.alloc(maxSizeBytes);
      const fd = await fs.promises.open(filePath, 'r');
      await fd.read(buffer, 0, maxSizeBytes, 0);
      await fd.close();
      content = buffer.toString('utf8');
      isTruncated = true;
    } else {
      content = await fs.promises.readFile(filePath, 'utf8');
    }

    return {
      success: true,
      fileName,
      filePath,
      fileSize: (stats.size / 1024).toFixed(1) + ' KB',
      content,
      isTruncated
    };
  } catch (error) {
    console.error('File read error:', error);
    return { success: false, error: error.message };
  }
});

// 4. Initialize and load selected GGUF model with GPU acceleration
ipcMain.handle('load-model', async (event, { filename, options = {} }) => {
  if (!filename) {
    return { success: false, error: 'No model filename specified' };
  }

  const modelsDir = getModelsDirectory();
  const modelPath = path.join(modelsDir, filename);

  if (!fs.existsSync(modelPath)) {
    return { success: false, error: `Model file not found: ${modelPath}` };
  }

  try {
    const { getLlama, LlamaChatSession } = await import('node-llama-cpp');
    await cleanupActiveModel();

    const startTime = Date.now();
    const requestedGpuType = options.gpuType || 'auto';

    if (!llamaInstance || (requestedGpuType !== 'auto' && llamaInstance.gpu !== requestedGpuType)) {
      try {
        if (requestedGpuType === 'auto') {
          try {
            llamaInstance = await getLlama({ gpu: 'cuda' });
          } catch {
            llamaInstance = await getLlama({ gpu: 'auto' });
          }
        } else if (requestedGpuType === 'cpu') {
          llamaInstance = await getLlama({ gpu: false });
        } else {
          llamaInstance = await getLlama({ gpu: requestedGpuType });
        }
      } catch (err) {
        llamaInstance = await getLlama();
      }
    }

    const gpuLayers = options.gpuLayers !== undefined ? options.gpuLayers : 'auto';
    const contextSize = options.contextSize ? Number(options.contextSize) : 4096;
    const systemPrompt = options.systemPrompt || '';

    let modelGpuLayersParam = undefined;
    if (gpuLayers === 'auto' || gpuLayers === 'max') {
      modelGpuLayersParam = { fitContext: { contextSize } };
    } else if (gpuLayers !== undefined && gpuLayers !== 'auto') {
      modelGpuLayersParam = Number(gpuLayers);
    }

    currentModel = await llamaInstance.loadModel({
      modelPath,
      gpuLayers: modelGpuLayersParam
    });

    const activeOffloadedLayers = currentModel.gpuLayers || 0;

    currentContext = await currentModel.createContext({
      contextSize
    });

    currentChatSession = new LlamaChatSession({
      contextSequence: currentContext.getSequence(),
      systemPrompt: systemPrompt.trim() ? systemPrompt.trim() : undefined
    });

    currentModelName = filename;
    const duration = ((Date.now() - startTime) / 1000).toFixed(2);

    return {
      success: true,
      message: `Model loaded in ${duration}s.`,
      modelName: filename,
      gpu: llamaInstance.gpu || 'cpu',
      gpuLayers: activeOffloadedLayers
    };
  } catch (error) {
    console.error('Error loading model:', error);
    await cleanupActiveModel();
    return {
      success: false,
      error: error.message || 'Failed to load model.'
    };
  }
});

// 5. Prompt active model with streaming
ipcMain.handle('send-prompt', async (event, { promptText, options = {} }) => {
  if (!currentChatSession) {
    return {
      success: false,
      error: 'No model loaded.'
    };
  }

  if (!promptText || !promptText.trim()) {
    return { success: false, error: 'Prompt cannot be empty.' };
  }

  const startTime = Date.now();
  let firstTokenTime = null;
  let tokenCount = 0;

  try {
    const promptConfig = {
      temperature: options.temperature !== undefined ? Number(options.temperature) : 0.7,
      topP: options.topP !== undefined ? Number(options.topP) : 0.9,
      maxTokens: options.maxTokens ? Number(options.maxTokens) : undefined,
      onTextChunk(chunk) {
        if (!firstTokenTime) {
          firstTokenTime = Date.now();
        }
        tokenCount++;
        if (!event.sender.isDestroyed()) {
          event.sender.send('chat-token', chunk);
        }
      }
    };

    const response = await currentChatSession.prompt(promptText, promptConfig);

    const totalTimeMs = Date.now() - startTime;
    const ttftMs = firstTokenTime ? (firstTokenTime - startTime) : totalTimeMs;
    const generationTimeSec = (totalTimeMs - (ttftMs || 0)) / 1000;
    const tps = generationTimeSec > 0 ? (tokenCount / generationTimeSec).toFixed(1) : (tokenCount / (totalTimeMs / 1000)).toFixed(1);

    return {
      success: true,
      response,
      stats: {
        tokenCount,
        totalTimeMs,
        ttftMs,
        tokensPerSec: tps
      }
    };
  } catch (error) {
    console.error('Inference error:', error);
    return { success: false, error: error.message || 'Inference error occurred.' };
  }
});

// 6. Unload model
ipcMain.handle('unload-model', async () => {
  await cleanupActiveModel();
  return { success: true };
});

// 7. Reset chat conversation memory
ipcMain.handle('reset-chat', async () => {
  if (currentContext && currentModel) {
    const { LlamaChatSession } = await import('node-llama-cpp');
    currentChatSession = new LlamaChatSession({
      contextSequence: currentContext.getSequence()
    });
    return { success: true, message: 'Session reset.' };
  }
  return { success: false, error: 'No active session.' };
});

app.whenReady().then(() => {
  getModelsDirectory();
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', async () => {
  await cleanupActiveModel();
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
