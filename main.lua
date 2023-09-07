require "library/sqlite3"
db = assert(sqlite3.open("data/data.db"))

require "script/color"
require "script/dev"
require "script/draw"
require "script/input"
require "script/generator"
require "script/globals"
require "script/screen"
require "script/tools"

require "library/TSerial"


-- Global Variables

world = newWorld{}
player = world:get("player")

keyLShift = false
keyRShift = false
keyShift = false

backspace = false

saving = false


-- Local Variables

local console = false
local command = ""

local keyTimer = 0
local keyTimerDefault = 0.1

local frameTimer = 0
local frameTimerDefault = 0.03

local saveTimer = 0
local saveTimerDefault = 30

local commandResults = {}
local commandIndex = 1
local lastCommand

local scale = 1


-- Initialization

function love.load()
    
    -- Setup
    
    love.graphics.setBackgroundColor(color.gray1)
    love.filesystem.setIdentity("magyka/saves")
    math.randomseed(os.time())
    draw:setFont("small")
    
    -- Extra
    
end


-- Input Functions

function love.keyreleased(key)
    if key == "lshift" then keyLShift = false end
    if key == "rshift" then keyRShift = false end
    
    input:keyreleased(key)
end

function love.keypressed(key)
    
    -- Global Keys
    
    if key == "`" then
        console = not console
        love.keyboard.setKeyRepeat(console)
        commandIndex = 1
    end
    if key == "lshift" then keyLShift = true end
    if key == "rshift" then keyRShift = true end
    if key == "f11" then
        local fullscreen, _ = love.window.getFullscreen()
        love.window.setFullscreen(not fullscreen)
        love.resize(love.graphics.getWidth(), love.graphics.getHeight())
    end
    
	if key == "f1" then player.stats:print() end
	
    -- Send key to game loop
    
    if not console then input:keypressed(key) end
    
    
    -- Console Input
    
    if console then
        if inString("abcdefghijklmnopqrstuvwxyz1234567890,[]-=+", key) then
            if keyShift then command = command..key:upper()
            else command = command..key end
        
        
        elseif key == "space" then
            command = command.." "
        
        
        elseif key == "backspace" then 
            if #command > 1 then command = command:sub(1, #command - 1)
            elseif #command == 1 then command = "" end
        
        
        elseif key == "escape" then
            command = ""
            console = false
        
        
        elseif key == "down" and commandIndex < #commandResults then
            commandIndex = commandIndex + 1
        
        
        elseif key == "up" and commandIndex > 1 then
            commandIndex = commandIndex - 1
        
        
        elseif key == "left" then
            command = lastCommand
        
        
        elseif key == "return" then
            result = devCommand(command)
            lastCommand = command
            command = ""
            commandIndex = 1
            
            if result == "clear" then
                commandResults = {}
            elseif result then
                for k, v in ipairs(result) do
                    table.insert(commandResults, 1, v)
                end
            end
        end
    end
end

function love.mousepressed(x, y, button, istouch)
    input:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button, istouch)
    input:mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy, istouch)
    input:mousemoved(x / scale, y / scale)
end

function love.wheelmoved(x, y)
    input:wheelmoved(x, y)
end


-- Update

function love.resize(w, h)
    screen.width = w
    screen.height = h
    
    if w < 1920 and h < 1080 then
        if w < 1366 or h < 768 then draw:setFont("small")
        else draw:setFont("") end
        
        scale = 1
    else
        if w < 2560 or h < 1440 then draw:setFont("small", 2)
        else draw:setFont("", 2) end
        
        scale = 2
    end
end

function love.update(dt)
    
    -- Shift
    
    keyShift = keyLShift or keyRShift
    
    
    -- Saving
    
    if saving then
        saveTimer = saveTimer + dt
        if saveTimer >= saveTimerDefault then
            saveTimer = saveTimer - saveTimerDefault
            
            love.filesystem.write(player:get("name"), TSerial.pack(world:export(), false, true))
        end
    end
    
    -- Performance Enhancement
    
    love.timer.sleep(1/30 - dt)
    
    collectgarbage("collect")
end


-- Quit

function love.quit()
    if saving then
        if screen.current ~= "quit" then screen:down("quit") end
        return true
    end
    return false
end


-- Draw and Game Loop

function love.draw()
    love.graphics.scale(scale)
    
    -- Game Loop
    
    screen:update(0)
    input:update()
    
    
    -- Console Drawing
    
    if console then
        draw:reset(0, 0)
        draw.autoSpace = false
        draw:setColor("black")
        draw:rectangle("fill", 0, draw.screenHeight, draw.screenWidth, -20)
        draw:setColor("gray4")
        draw:rectangle("fill", 0, draw.screenHeight - 20, draw.screenWidth)
        draw:setColor("white")
        draw:text(command, 1, draw.screenHeight - 20)
        draw:text("_", 1 + #command, draw.screenHeight - 20)
        draw.autoSpace = true
        
        draw:reset(1, draw.screenHeight - 18)
        for i = commandIndex, #commandResults do
            draw:text(rjust(tostring(i), 2).." | "..commandResults[i])
        end
    end
end