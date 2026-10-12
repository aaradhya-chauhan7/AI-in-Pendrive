const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  // Window controls (for frameless titlebarless window)
  minimizeWindow: () => ipcRenderer.invoke('window-minimize'),
  maximizeWindow: () => ipcRenderer.invoke('window-maximize'),
  closeWindow: () => ipcRenderer.invoke('window-close'),

  // Retrieve list of .gguf files in models/
  getLocalModels: () => ipcRenderer.invoke('get-local-models'),

  // Open the models folder in OS file manager
  openModelsFolder: () => ipcRenderer.invoke('open-models-folder'),

  // File upload reader dialog
  selectAndReadFile: () => ipcRenderer.invoke('select-and-read-file'),

  // Load a designated .gguf model with options
  loadModel: (filename, options = {}) => ipcRenderer.invoke('load-model', { filename, options }),

  // Unload the current model from memory
  unloadModel: () => ipcRenderer.invoke('unload-model'),

  // Reset conversation memory
  resetChat: () => ipcRenderer.invoke('reset-chat'),

  // Send prompt to active session
  sendPrompt: (promptText, options = {}) => ipcRenderer.invoke('send-prompt', { promptText, options }),

  // Subscribe to real-time streaming tokens
  onChatToken: (callback) => {
    const handler = (_event, token) => callback(token);
    ipcRenderer.on('chat-token', handler);
    return () => ipcRenderer.removeListener('chat-token', handler);
  }
});
