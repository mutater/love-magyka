require "script/color"
require "script/globals"
require "script/image"
require "script/tools"

draw = {
    width = 10,
    height = 20,
    row = 3,
    subLeft = 38,
    
    
    -- Base
    
    
    
    
    rect = function(self, c, x, y, w, h) -- Draw a cell-sized rectangle
        if type(c) == "string" then c = color[c] end
        
        local w = w or 1
        local h = h or 1
        
        love.graphics.setColor(c)
        love.graphics.rectangle("fill", (x-1)*self.width, (y-1)*self.height, w*self.width, h*self.height)
    end,
    
    image = function(self, i, x, y) -- Draw a cell-snapped image
        local i = i or "screen/default"
        if not image[i] then i = "screen/default" end
        self:icon(i, x, y, 8)
    end,
    
    
    
    -- Compound
    
    item = function(self, item, quantity) -- Draw stats for an item
        self:text(item:display(quantity))
        self:newline()
        for k, v in ipairs(item:get("description")) do self:text(v) end
        
        local effect = item:get("effect")
        if effect then
            for k, v in ipairs(effect) do
                self:effect(v)
            end
        end
        
        if item:get("value") then
            self:newline()
            self:text("<gp> %d" % {item:get("value")})
        end
    end,
    
    effect = function(self, effect) -- Draw stats for an effect
        local text = ""
        
        local hpCost = effect:get("hpCost")
        local mpCost = effect:get("mpCost")
        
        if hpCost or mpCost then self:newline() end
        
        if hpCost and mpCost then self:text("Costs <hp>{hp} %s{white} and <mp>{mp} %s" % {hpCost, mpCost})
        elseif hpCost then self:text("Costs <hp>{hp} %s" % hpCost)
        elseif mpCost then self:text("Costs <mp>{mp} %s" % mpCost) end
        
        local hp = effect:get("hp")
        local mp = effect:get("mp")
        
        if hp or mp then self:newline() end
        
        if hp and hp[1] + hp[2] ~= 0 then
            if hp[2] > 0 then text = "Heals" else text = "Damages" end
            self:text("%s <hp> {hp}%d - %d" % {text, math.abs(hp[1]), math.abs(hp[2])})
        end
        
        if mp and mp[1] + mp[2] ~= 0 then
            if mp[2] > 0 then text = "Heals" else text = "Damages" end
            self:text("%s <mp> {mp}%d - %d" % {text, math.abs(mp[1]), math.abs(mp[2])})
        end
    end,
    
    imageSide = function(self, i, default, c) -- Draw an image on the side of the screen
        c = c or color.white
        if not image[i] then i = default end
        
        self:top()
        self:image(i, self.subLeft, 2, color.white)
    end,
    
    initScreen = function(self, subWidth, i) -- Draw a border and image
        self:top()
        self:border(subWidth)
        self:image(i, self.subLeft, 2)
        self:top()
    end,
    
    hpmp = function(self, entity, w) -- Draw name and hp and mp bars
        local x = 4
        local y = self.row
        w = w or 40
        
        self:text("{gray78}%s [Lvl 1 %s]" % {entity:get("name"), entity:get("class").name}, x)
        self:icon("icon/hp", x, self.row)
        self:bar(entity:get("hp"), entity:get("stats").maxHp, color.hp, color.gray48, w, "{gray78}HP: ", "#", x + 2)
        self:icon("icon/mp", x, self.row)
        self:bar(entity:get("mp"), entity:get("stats").maxMp, color.mp, color.gray48, w, "{gray78}MP: ", "#", x + 2)
    end,
    
    hpmpAlt = function(self, entity, x, y) -- Draw name and hp and mp bars at a location
        self:text(entity:get("name"), x, y)
        self:icon("icon/hp", x, self.row)
        self:bar(entity:get("hp"), entity:get("stats").maxHp, color.hp, color.gray48, 20, "HP: ", "%", x + 2)
        self:icon("icon/mp", x, self.row)
        self:bar(entity:get("mp"), entity:get("stats").maxMp, color.mp, color.gray48, 20, "MP: ", "%", x + 2)
    end,
    
    mainStats = function(self, entity, w) -- Draw name and hp, mp, xp, and gp stats
        local x = 4
        local w = w or 40
        
        self:hpmp(entity, w)
        self:icon("icon/xp", x, self.row)
        self:bar(entity:get("xp"), entity:get("maxXp"), color.xp, color.gray48, w, "{gray78}XP: ", "#", x + 2)
        self:icon("icon/gp", x, self.row)
        self:text("{gray78}Gold: %d" % {entity:get("gp")}, x + 2)
    end,
    
    options = function(self, options, x, y) -- Draw options with the first letter in square brackets
        local x = x or 5
        if y then self.row = y end
        
        local length = #options
        self:rect(color.gray28, x, self.row, 3, length * 2 - 1)
        
        for k, v in pairs(options) do
            self:text("[%s] %s" % {v:sub(1, 1), v}, x)
            if k < length then self:text("|", x + 1, self.row) end
        end
    end,
    
    optionsNumbered = function(self, options, x, y) -- Draw options by number in parentheses
        local x = x or 5
        if y then self.row = y end
        
        local length = #options
        self:rect(color.gray28, x, self.row, 3, length * 2 - 1)
        
        for k, v in pairs(options) do
            self:text("(%d) %s" % {k, v}, x)
            if k < length then self:text("|", x + 1, self.row) end
        end
    end,
    
    bar = function(self, current, maximum, fillColor, emptyColor, width, label, form, x, y) -- Draw a bar
        local x = x or 4
        if y then self.row = y end
        local label = label or ""
        
        if current == 0 or current == maximum then
            if current == 0 then c = emptyColor else c = fillColor end
            
            self:icon("icon/bar_left", x, c)
            for i = 1, width - 1 do self:icon("icon/bar_middle", x + i, c) end
            self:icon("icon/bar_right", x + width - 1, c)
        else
            local fillLength = math.ceil((current / maximum) * width)
            if fillLength > width then fillLength = width end
            if fillLength < 1 then fillLength = 1 end
            
            self:icon("icon/bar_left", x, fillColor)
            for i = 1, fillLength do self:icon("icon/bar_middle", x + i, fillColor) end
            for i = fillLength, width - 1 do self:icon("icon/bar_middle", x + i, emptyColor) end
            self:icon("icon/bar_right", x + width - 1, emptyColor)
        end
        
        local labelText = ""
        if form == "%" or form == "percent" then
            labelText = label..tostring(math.ceil(current / maximum * 100)).."%"
        elseif form == "#" or form == "number" then
            labelText = label.."%d/%d" % {current, maximum}
        else
            labelText = ""
        end
        
        self:text(labelText, x + width + 1)
    end,
    
    hint = function(self, text) -- Draw text in the hint color
        self:text("{gray58}"..text)
    end,
    
    border = function(self, subWidth) -- Draw a border around the screen
        local subWidth = subWidth or 1
        local c = color.gray28
        
        self:rect(c, 1, 1, screen.width, 1)
        self:rect(c, 1, screen.height, screen.width, 1)
        self:rect(c, 1, 1, 2, screen.height)
        self:rect(c, screen.width - 1, 1, 2, screen.height)
        
        self:rect(c, screen.width - subWidth - 1, 1, 2, screen.height)
        self.subLeft = screen.width - subWidth + 1
    end,
    
    header = function(self, str) -- Draw a header (QoL)
        self:text(" -= %s {white}=-" % str)
    end,
}

draw = {
    width = 10,
    height = 20,
    xOffset = 0,
    yOffset = 0,
    subLeft = 38,
    autoSpace = true,
    
    
    -- Main Functions
    
    space = function(self, y)
        self.yOffset = self.yOffset + y
    end,
    
    reset = function(self, x, y)
        local x = x or 10
        local y = y or 20
        
        self.xOffset = x
        self.yOffset = y
        self:setColor(color.white)
    end,
    
    setColor = function(self, c)
        local c = c
        if type(c) == "string" then
            if color[c] then c = color[c]
            else c = color.white end
        end
        love.graphics.setColor(c)
    end,
    
    setLine = function(self, s)
        love.graphics.setLineWidth(s)
    end,
    
    
    -- Drawing Functions
    
    rectangle = function(self, mode, x, y, w, h, rx, ry)
        local x = x or 0
        local y = y or 0
        love.graphics.rectangle(mode, self.xOffset + x, self.yOffset + y, w, h, rx, ry)
        if self.autoSpace then self:space(h) end
    end,
    
    text = function(self, text, x, y)
        local x = x or 0
        local y = y or 0
        local font = love.graphics.getFont()
        local text = text
        local oText = text
        local r, g, b, a = love.graphics.getColor()
        local c = {r, g, b}
        local parsedText = {}
        local parsedTextLength = 0
        local parsedColors = {}
        local parsedIcons = {}
         
        if text[1] ~= "{" then text = "{ }"..text end
        
        while count(text, "{") > 0 do
            local i = text:find("{", 1, true)
            local j = text:find("}", 1, true)
            
            local colorName = text:sub(i + 1, j - 1)
            if color[colorName] then table.insert(parsedColors, color[colorName])
            else table.insert(parsedColors, c) end
            text = text:sub(j + 1)
            
            if count(text, "{") > 0 then bufferText = text:sub(1, text:find("{", 1, true) - 1)
            else bufferText = text end
            
            while count(bufferText, "<") > 0 do  -- Parse icons
                local k = bufferText:find("<", 1, true)
                local l = bufferText:find(">", 1, true)
                
                parsedIcons[k + parsedTextLength] = "icon/"..bufferText:sub(k + 1, l - 1)
                bufferText = bufferText:gsub(bufferText:sub(k, l), " ")
            end
            
            parsedTextLength = parsedTextLength + #bufferText
            table.insert(parsedText, bufferText)
            text = text:sub(#bufferText)
        end
        
        if #parsedText ~= #parsedColors then
            parsedText = {oText}
            text = oText
            parsedColors = {color.white}
        end
        
        local i = 0
        for k, v in ipairs(parsedText) do
            love.graphics.setColor(parsedColors[k])
            love.graphics.print(v, self.xOffset + x + i * 10, y + self.yOffset)
            i = i + string.len(v)
        end
        
        for k, v in pairs(parsedIcons) do
            self:image(v, x + (k - 1) * 10, y)
        end
        
        if self.autoSpace then self:space(font:getHeight()) end
    end,
    
    image = function(self, i, ...)
        local arg = {...}
        local i = i
        local x = self.xOffset
        local y = self.yOffset
        local s = 1
        
        if #arg == 1 then
            x = arg[1] + self.xOffset
        elseif #arg == 2 then
            x = arg[1] + self.xOffset
            y = arg[2] + self.yOffset
        elseif #arg == 3 then
            x = arg[1] + self.xOffset
            y = arg[2] + self.yOffset
            s = arg[3]
        end
        
        if type(i) == "string" and image[i] then i = image[i]
        elseif type(i) == "string" then i = image["image/default"] end
        
        love.graphics.draw(i, x, y, 0, s)
    end,
    
    -- Compound Functions
    
    
    bar = function(self, current, maximum, fillColor, emptyColor, width, label, form, x, y)
        local x = x or 0
        local y = y or 0
        local label = label or ""
        
        self:setColor(emptyColor)
        if current > 0 then self:setColor(fillColor) end
        
        local fillLength = math.ceil((current / maximum) * width)

        self:image("icon/bar_left", x, y)
        for i = 1, width - 1 do
            if i > fillLength then self:setColor(emptyColor) end
            self:image("icon/bar_middle", x + i * 10, y)
        end
        self:image("icon/bar_right", x + (width - 1) * 10, y)
        
        local labelText = ""
        if form == "%" or form == "percent" then
            labelText = label..tostring(math.ceil(current / maximum * 100)).."%"
        elseif form == "#" or form == "number" then
            labelText = label.."%d/%d" % {current, maximum}
        else
            labelText = ""
        end
        
        self:setColor("white")
        self:text(labelText, x + (width + 1) * 10, y)
    end,
    
    hpmp = function(self, entity, w)
        w = w or 40
        
        self:text("{gray78}%s [Lvl 1 %s]" % {entity:get("name"), entity:get("class").name})
        self:image("icon/hp")
        self:bar(entity:get("hp"), entity:get("stats").maxHp, "hp", "gray48", w, "{gray78}HP: ", "#", 20)
        self:image("icon/mp")
        self:bar(entity:get("mp"), entity:get("stats").maxMp, "mp", "gray48", w, "{gray78}MP: ", "#", 20)
    end,
    
    mainStats = function(self, entity, w)
        w = w or 40
        
        self:hpmp(entity, w)
        self:image("icon/xp")
        self:bar(entity:get("xp"), entity:get("maxXp"), "xp", "gray48", w, "{gray78}XP: ", "#", 20)
        self:image("icon/gp")
        self:text("{gray78}Gold: %d" % {entity:get("gp")}, 20)
    end,
}