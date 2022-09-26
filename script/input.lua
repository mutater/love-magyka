require "script/color"
require "script/tools"

input = {
    mouse = {
        pressed = false,
        released = true,
        x = 0,
        y = 0,
    },
    
    keyboard = {
        pressed = false,
        released = true,
    },
    
    
    -- Input Functions
    
    mousepressed = function(self, x, y, button)
        self.mouse.pressed = true
        self.mouse.released = false
        if not self.mouse[button].pressed then self.mouse[button].justPressed = true end
        self.mouse[button].pressed = true
        self.mouse[button].released = false
    end,
    
    mousereleased = function(self, x, y, button)
        self.mouse.pressed = false
        self.mouse.released = true
        if not self.mouse[button].released then self.mouse[button].justReleased = true end
        self.mouse[button].pressed = false
        self.mouse[button].released = true
    end,
    
    mousemoved = function(self, x, y)
        self.mouse.x = x
        self.mouse.y = y
    end,
    
    keypressed = function(self, key)
        if self.keyboard[key] then
            self.keyboard.pressed = true
            self.keyboard.released = false
            if not self.keyboard[key].pressed then self.keyboard[key].justPressed = true end
            self.keyboard[key].pressed = true
            self.keyboard[key].released = false
        end
    end,
    
    keyreleased = function(self, key)
        if self.keyboard[key] then
            self.keyboard.pressed = false
            self.keyboard.released = true
            if not self.keyboard[key].released then self.keyboard[key].justReleased = true end
            self.keyboard[key].pressed = false
            self.keyboard[key].released = true
        end
    end,
    
    update = function(self)
        for k, v in ipairs(self.mouse) do
            v.justPressed = false
            v.justReleased = false
        end
        
        for k, v in pairs(self.keyboard) do
            if type(v) == "table" then
                v.justPressed = false
                v.justReleased = false
            end
        end
    end,
    
    
    -- GUI Functions
    
    button = function(self, x, y, w, h)
        if pointInRect(self.mouse.x, self.mouse.y, x, y, w, h) then
            if self.mouse[1].justReleased then return "released"
            elseif self.mouse[1].pressed then return "pressed"
            else return "hovered" end
        end
        
        return "inactive"
        
        -- draw:setColor(c)
        -- draw.autoSpace = false
        -- draw:rectangle("fill", x, y, w, h, 2, 2)
        
        -- draw:setColor(color.black)
        -- draw.autoSpace = true
        -- draw:rectangle("line", x, y, w, h)
        
        -- draw:setColor(color.white)
    end,
    
    textButton = function(self, text, x, y, inactiveColor, hoveredColor, pressedColor)
        local font = love.graphics.getFont()
        local x = x or 0
        local y = y or 0
        local w = font:getWidth(text)
        local h = font:getHeight()
        local inactiveColor = inactiveColor or color.white
        local hoveredColor = hoveredColor or color.rare
        local pressedColor = pressedColor or color.gray48
        local c = inactiveColor
        
        local state = self:button(x - 2 + draw.xOffset, y - 2 + draw.yOffset, w + 2, h + 2)
        
        if state == "hovered" then c = hoveredColor
        elseif state == "pressed" then c = pressedColor
        elseif state == "released" then c = pressedColor end
        
        draw:setColor(c)
        draw:text(text, x, y)
        
        return state
    end,
    
    
    -- GUI Compound Functions
    
    options = function(self, options, x, y)
        local option = ""
        local length = #options
        local x = x + draw.xOffset
        
        draw.autoSpace = false
        draw:setColor("gray28")
        draw:rectangle("fill", x, 0, 3 * 10, (length * 2 - 1) * 20)
        draw.autoSpace = true
        
        for k, v in ipairs(options) do
            local optionCharacter = v:sub(1, 1):lower()
            if self:textButton("[%s] %s" % {v:sub(1, 1), v}, x, 0) == "released" then
                option = optionCharacter
            end
            if self.keyboard[optionCharacter].justPressed then
                option = optionCharacter
            end
            
            draw:setColor("white")
            if k < length then draw:text("|", x + 10, 0) end
        end
        
        return option
    end,
}

local states = {
    pressed = false,
    released = true,
    justPressed = false,
    justReleased = false,
}

for i = 1, 3 do
    input.mouse[i] = deepcopy(states)
end

local keys = "abcdefghijklmnopqrstuvwxyz1234567890"
for c in keys:gmatch(".") do
    input.keyboard[c] = deepcopy(states)
end

local extraKeys = {"up", "left", "down", "right", "escape", "return"}
for k, v in ipairs(extraKeys) do
    input.keyboard[v] = deepcopy(states)
end