require "script/color"
require "script/tools"

input = {
    mouse = {
        pressed = false,
        released = true,
		justPressed = false,
		justReleased = false,
		moved = false,
        x = 0,
        y = 0,
		deltaX = 0,
		deltaY = 0,
    },
    
	mouseWheel = {
        x = 0,
        y = 0,
    },
	
    keyboard = {
        pressed = false,
        released = true,
    },
    
    lastKey = "",
	
	
    -- Input Functions
    
    mousepressed = function(self, x, y, button)
        self.mouse.pressed = true
        self.mouse.released = false
        self.mouse[button].justPressed = true
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
		self.mouse.detaX = self.mouse.x - x
		self.mouse.detaY = self.mouse.y - y
		
		self.mouse.moved = true
		
        self.mouse.x = x
        self.mouse.y = y
    end,
    
	wheelmoved = function(self, x, y)
        self.mouseWheel.x = x
        self.mouseWheel.y = y
    end,
	
    keypressed = function(self, key)
        local key = key
        if key == "return" then key = "enter" end
        
		self.lastKey = key
        
		if self.keyboard[key] then
            self.keyboard.pressed = true
            self.keyboard.released = false
            self.keyboard[key].justPressed = true
            self.keyboard[key].pressed = true
            self.keyboard[key].released = false
        end
    end,
    
    keyreleased = function(self, key)
        local key = key
        if key == "return" then key = "enter" end
        
		if lastKey == key then lastKey = "" end
		
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
		
        self.lastKey = ""
        
		self.mouse.detaX = 0
		self.mouse.detaY = 0
		
		self.mouse.moved = false
		
		self.mouseWheel.x = 0
        self.mouseWheel.y = 0
    end,
	
	getButton = function(self, x, y, w, h)
		if pointInRect(self.mouse.x, self.mouse.y, x, y, w, h) then
            if self.mouse[1].justReleased then return "released"
            elseif self.mouse[1].pressed then return "pressed"
            else return "hovered" end
        end
        
        return "inactive"
    end,
	
	getTextButton = function(self, text, x, y)
		local font = love.graphics.getFont()
		local x = x or 0
		local y = y or 0
		local w = font:getWidth(cleanText(text))
        local h = font:getHeight()
		
		return self:getButton(x + draw.xOffset - 2, y + draw.yOffset - 2, w + 4, h + 4)
	end,
	
	
    -- GUI Functions
    
    
    textButton = function(self, text, x, y, inactiveColor, hoveredColor, pressedColor)
        local x = x or 0
        local y = y or 0
        local inactiveColor = inactiveColor or color.white
        local hoveredColor = hoveredColor or color.hovered
        local pressedColor = pressedColor or color.gray4
        local c = inactiveColor
        
        local state = self:getTextButton(text, x, y)
        
        if state == "hovered" then c = hoveredColor
        elseif state == "pressed" then c = pressedColor
        elseif state == "released" then c = pressedColor end
        
        draw:setColor(c)
        draw:text(text, x, y)
        
        return state
    end,
    
    
    -- Compound Functions
    
    options = function(self, options, receiveInput, returnType)
        local option = nil
        local length = #options
        local receiveInput = ifNil(receiveInput, true)
        local returnType = returnType or "char"
        
        draw.autoSpace = false
        draw:setColor("gray2")
        local rectangleLength = length * 2 - 1
        draw:rectangle("fill", 0, 0, 3, rectangleLength)
		draw:setColor("black")
		draw:rectangle("line", 0, 0, 3, rectangleLength)
        draw.autoSpace = true
        
        if receiveInput then
            for k, v in ipairs(options) do
                if self.keyboard["escape"].justPressed or self.mouse[2].justReleased then
                    option = "escape"
                end
                
                local optionCharacter = ""
                optionCharacter = v:sub(1, 1):lower()
                if self:textButton("[%s] %s" % {v:sub(1, 1), v}) == "released" or self.keyboard[optionCharacter].justPressed then
                    if returnType == "char" then option = optionCharacter
                    elseif returnType == "index" then option = k end
                end
                
                draw:setColor("white")
                if k < length then draw:text("|", 1) end
            end
        else
            draw:setColor("gray4")
            for k, v in ipairs(options) do
                draw:text("[%s] %s" % {v:sub(1, 1), v})
                if k < length then draw:text("|", 1) end
            end
            draw:setColor("gray4")
        end
        
        return option
    end,
    
    optionsIndex = function(self, options, receiveInput)
        local receiveInput = ifNil(receiveInput, true)
        return self:options(options, receiveInput, "index")
    end,
	
	optionsList = function(self, options, index, spacing)
		love.keyboard.setKeyRepeat(true)
        local option = ""
		local index = index or 0
		local spacing = spacing or 0
		
		if #options > 0 then
			for i = 1, #options do
				local state = self:getTextButton(options[i])
				
				if i == index then draw:text(" - "..options[i])
				else draw:text(options[i]) end
				draw:space(spacing)
				
				if state == "released" then
                    option = tostring(i)
                    love.keyboard.setKeyRepeat(false)
                end
				if state == "hovered" and self.mouse.moved then index = i end
			end
		end
		
		local escape = (self.keyboard.escape.justPressed or self.mouse[2].justPressed)
		local up = self.keyboard.up.justPressed
		local down = self.keyboard.down.justPressed
		local enter = self.keyboard.enter.justPressed
		
		if escape then
            option = "escape"
            love.keyboard.setKeyRepeat(false)
		elseif up then index = index - 1
		elseif down then index = index + 1
		elseif enter then
            love.keyboard.setKeyRepeat(false)
            if index < 1 then index = 1
            elseif index > #options then index = #options end
            option = tostring(index)
        end
		
		index = index - self.mouseWheel.y
		
		if self.mouseWheel.y ~= 0 or up or down then
			if index < 1 then index = #options end
			if index > #options then index = 1 end
		end
		
		return option, index
	end,
	
	optionsNoGUI = function(self, options, ...)
		local arg = {...}
		local options = options or ""
		local numbered = false
		local optionsWords = {}
		
		if #arg == 1 then
			if type(arg[1]) == "boolean" then numbered = arg[1]
			else optionsWords = arg[1] end
		else
			if type(arg[1]) == "boolean" then
				numbered = arg[1]
				optionsWords = arg[2]
			else
				optionsWords = arg[1]
				numbered = arg[2]
			end
		end
		
		options = toTable(options)
		appendTable(options, optionsWords)
		
		if self.keyboard["escape"].justPressed or self.mouse[2].justReleased then return "escape"
		elseif numbered then
			for i = 0, 9 do
				if self.keyboard[tostring(i)].justPressed then return tostring(i) end
			end
		else
			for k, v in ipairs(options) do
				if self.keyboard[v].justPressed then return v end
			end
		end
		
		return ""
	end,
	
	escape = function(self)
		if self.keyboard["escape"].justPressed or self.mouse[2].justReleased then return "escape" end
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

local extraKeys = {"up", "left", "down", "right", "escape", "enter", "f1"}
for k, v in ipairs(extraKeys) do
    input.keyboard[v] = deepcopy(states)
end