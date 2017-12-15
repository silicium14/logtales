let { app, BrowserWindow } = require('electron')

let mainWindow = null
let devMode = process.env.NODE_ENV === 'development'

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})

app.on('ready', () => {
  mainWindow = new BrowserWindow({
    show: false,
    width: 1024,
    height: 720,
    webPreferences: {
        nodeIntegration: false
    }
  })

  mainWindow.loadURL(`file://${__dirname}/front/app.html`)

  mainWindow.webContents.on('did-finish-load', () => {
    mainWindow.show()
    mainWindow.focus()
  })

  mainWindow.on('closed', () => {
    mainWindow = null
  })

  // if (devMode) mainWindow.openDevTools()
})
