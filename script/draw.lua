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
    
    text = function(self, text, ...) -- Draw cell-snapped text
        local arg = {...}
        local x = 4
        local c = "white"
        
        if #arg == 1 then
            if type(arg[1]) == "number" then x = arg[1]
            elseif type(arg[1]) == "string" then c = arg[1]
            elseif type(arg[1]) == "table" then c = arg[1] end
        elseif #arg == 2 then
            x = arg[1]
            if type(arg[2]) == "number" then self.row = arg[2]
            elseif type(arg[2]) == "string" then c = arg[2]
            elseif type(arg[2]) == "table" then c = arg[2] end
        elseif #arg == 3 then
            x = arg[1]
            y = arg[2]
            c = arg[3]
        end
        
        local oText = text
        local parsedText = {}
        local parsedTextLength = 0
        local parsedColors = {}
        local parsedIcons = {}
         
        if text[1] ~= "{" then
            local colorName = ""
            if type(c) == "string" then colorName = c
            else colorName = "custom" end
            text = "{%s}%s" % {colorName, text}
        end
        
        while count(text, "{") > 0 do
            local i = text:find("{", 1, true)
            local j = text:find("}", 1, true)
            
            local colorName = text:sub(i + 1, j - 1)
            if colorName == "custom" then table.insert(parsedColors, c)
            elseif color[colorName] then table.insert(parsedColors, color[colorName])
            else table.insert(parsedColors, color[c]) end
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
            parsedColors = {c}
        end
        
        local i = 0
        for k, v in ipairs(parsedText) do
            love.graphics.setColor(parsedColors[k])
            love.graphics.print(v, (x + i - 1)*self.width, (self.row - 1)*self.height)
            i = i + string.len(v)
        end
        
        for k, v in pairs(parsedIcons) do self:icon(v, k + x - 1) end
        
        self.row = self.row + 1
    end,
    
    icon = function(self, i, ...) -- Draw a cell-sized icon
        local arg = {...}
        local x = 4
        local c = color.white
        local s = 1
        
        if #arg == 1 then
            if type(arg[1]) == "number" then x = arg[1]
            elseif type(arg[1]) == "table" then c = arg[1] end
        elseif #arg == 2 then
            x = arg[1]
            if type(arg[2]) == "number" then self.row = arg[2]
            elseif type(arg[2]) == "table" then c = arg[2] end
        elseif #arg == 3 then
            x = arg[1]
            self.row = arg[2]
            if type(arg[3]) == "number" then s = arg[3]
            elseif type(arg[3]) == "table" then c = arg[3] end
        elseif #arg == 4 then
            x = arg[1]
            y = arg[2]
            c = arg[3]
            s = arg[4]
        end
        
        if type(i) == "string" and image[i] then i = image[i]
        elseif type(i) == "string" then i = image["icon/default"] end
        
        love.graphics.setColor(c)
        love.graphics.draw(i, (x - 1)*self.width, (self.row - 1)*self.height, 0, s)
    end,
    
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
    
    newline = function(self) -- Go to next row
        self.row = self.row + 1
    end,
    
    top = function(self) -- Reset rows
        self.row = 3
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