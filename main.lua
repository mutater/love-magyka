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

-- TODO

--[[
 
 * Mouse input.
 * Transfer all info to the database.
 * Curing and blessing from the church.
 * Quests.
 * Enchanting.
 * Options.
 * Dynamically scaling screen.
 * Elemental attacks and resistances.
 * Ability to choose an item from the inventory to use in:
   - Item and Art application.
   - Selection for what equipment to use in recipes.
 * Procedurally generated loot.
 * Enchanting at the arcanist.
 * Finish the editor for items, enemies, etc.
 * Fix diagonal collision cases.
 * Figure out how to have columns in the screen.pages function.
 * Random events on map screen.
 * Map painter.
   - Palettes
   - Pencil, Fill, Line
   - Undo and Redo
   - Exporting
   - Map modes
   - Entity placement
   - Entity customization

]]


-- Global Variables

world = newWorld{}
player = world:get("player")

keyLShift = false
keyRShift = false
keyShift = false

backspace = false


-- Local Variables

local console = false
local command = ""

local keyTimer = 0
local keyTimerDefault = 0.1

local frameTimer = 0
local frameTimerDefault = 0.03

saving = false
local saveTimer = 0
local saveTimerDefault = 30


-- Initialization

function love.load()
    
    -- Setup
    
    font = love.graphics.newImageFont("image/imagefont.png",
        " abcdefghijklmnopqrstuvwxyz" ..
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
        "123456789.,!?-+/():;%&`'*#=[]\"|_")
    love.graphics.setFont(font)
    love.graphics.setBackgroundColor(color.gray18)
    love.filesystem.setIdentity("magyka/saves")
    math.randomseed(os.time())
    
    
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
    end
    if key == "lshift" then keyLShift = true end
    if key == "rshift" then keyRShift = true end
    if key == "f11" then
        local fullscreen, _ = love.window.getFullscreen()
        love.window.setFullscreen(not fullscreen)
        screen.width = love.graphics.getWidth()
        screen.height = love.graphics.getHeight()
    end
    
    
    -- Send key to game loop
    
    if not console then input:keypressed(key) end
    
    
    -- Console Input
    
    if console then
        if ("abcdefghijklmnopqrstuvwxyz1234567890,"):find(key) then
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
        
        
        elseif key == "return" then
            devCommand(command)
            command = ""
            console = false
            love.keyboard.setKeyRepeat(false)
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
    input:mousemoved(x, y)
end


-- Update

function love.resize(w, h)
    screen.width = w
    screen.height = h
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
    -- Game Loop
    
    screen:update(0)
    input:update()
    
    
    -- Console Drawing
    
    if console then
        draw:rect("gray18", 1, 1, screen.width, 20)
        draw:rect("gray48", 1, 21, screen.width, 1)
        draw:text(command, 2, 21)
        draw:text("_", 2 + #command, 21)
    end
end