-- Love2D Configuration File

function love.conf(t)
    t.window.width = 800
    t.window.height = 600
    t.window.title = "Love Expanded"
    t.window.vsync = true
    t.window.resizable = true
end

function love.expandedConf(t)
    t.updateSync = true
    t.maxUpdatesInRow = 2
    t.updateSyncFPS = 75
end