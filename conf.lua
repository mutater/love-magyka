function love.conf(t)
    t.version = "11.4"
    t.console = true
    
    t.window.title = "Magyka"
    t.window.width = 1280
    t.window.minwidth = 1152
    t.window.height = 720
    t.window.minheight = 648
    t.window.resizable = true
    t.window.vsync = 0
    
    t.modules.joystick = false
end