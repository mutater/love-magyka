require "script/color"
require "script/globals"
require "script/image"
require "script/tools"

draw = {
    width = 10,
    height = 20,
    screenWidth = 128,
    screenHeight = 36,
    xOffset = 0,
    yOffset = 0,
    subLeft = 38,
    autoSpace = true,
    overrideIcon = false,
    fontPrefix = "",
    
    
    -- Main Functions
    
    space = function(self, y)
        local y = y or 1
        self.yOffset = self.yOffset + y * self.height
    end,
    
    shift = function(self, x)
        local x = x or 1
        self.xOffset = self.xOffset + x * self.width
    end,
    
    reset = function(self, x, y)
        local x = x or 1
        local y = y or 1
        
        self.xOffset = x * self.width
        self.yOffset = y * self.height
        self:setColor(color.white)
    end,
    
    setColor = function(self, c)
        local c = c or "white"
        if type(c) == "string" then
            if color[c] then c = color[c]
            else c = color.white end
        end
        love.graphics.setColor(c)
    end,
    
    setLine = function(self, s)
        love.graphics.setLineWidth(s)
    end,
    
    setFont = function(self, size, scale)
        scale = scale or 1
        if size == "small" then
            self.fontPrefix = "small"
        else
            self.fontPrefix = ""
        end
        
        self.font = love.graphics.newImageFont("image/%sfont/imagefont.png" % {self.fontPrefix},
            " abcdefghijklmnopqrstuvwxyz" ..
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
            "123456789.,!?-+/():;%&`'*#=[]\"|_")
        love.graphics.setFont(self.font)
        
        self.width = self.font:getWidth(" ")
        self.height = self.font:getHeight()
        
        self.screenWidth = math.ceil(love.graphics.getWidth() / self.width / scale)
        self.screenHeight = math.ceil(love.graphics.getHeight() / self.height / scale)
    end,
    
    
    -- Drawing Functions
    
    rectangle = function(self, mode, x, y, w, h, rx, ry)
        local x = (x or 0) * self.width
        local y = (y or 0) * self.height
        local w = (w or 1) * self.width
        local h = (h or 1) * self.height
        love.graphics.rectangle(mode, self.xOffset + x, self.yOffset + y, w, h, rx, ry)
        if self.autoSpace then self:space(h) end
    end,
    
    text = function(self, text, x, y)
        local x = x or 0
        local y = y or 0
        
        local parse, length = parseText(text)
        
        local i = 0
        for k, v in ipairs(parse[1]) do
            love.graphics.setColor(parse[2][k])
            love.graphics.print(v, self.xOffset + (x + i) * self.width, self.yOffset + y * self.height)
            i = i + string.len(v)
        end
        
        local r, g, b, a
        if not self.overrideIcon then
            r, g, b, a = love.graphics.getColor()
            love.graphics.setColor(1, 1, 1)
        end
        
        for k, v in pairs(parse[3]) do
            self:image(v, x + (k - 1), y)
        end
        
        if not self.overrideIcon then
            love.graphics.setColor(r, g, b, a)
        end
        
        if self.autoSpace then self:space() end
    end,
    
    hint = function(self, text)
        self:text("{gray5}"..text)
    end,
    
    image = function(self, i, ...)
        local arg = {...}
        local i = i or "default"
        local x = self.xOffset
        local y = self.yOffset
        local s = 1
        
        if #arg == 1 then
            x = arg[1] * self.width + self.xOffset
        elseif #arg == 2 then
            x = arg[1] * self.width + self.xOffset
            y = arg[2] * self.height + self.yOffset
        elseif #arg == 3 then
            x = arg[1] * self.width + self.xOffset
            y = arg[2] * self.height + self.yOffset
            s = arg[3]
        end
        
        i = image["%sfont/%s" % {self.fontPrefix, i}]
        
        if i then love.graphics.draw(i, x, y, 0, s) end
    end,
    
    icon = function(self, i)
        self.autoSpace = false
        self:text("<%s>" % i)
        self.autoSpace = true
    end,
    
    -- Compound Functions
    
    
    bar = function(self, current, maximum, fillColor, emptyColor, width, label, form, x, y)
        local label = label or ""
        local x = x or 0
        local y = y or 0
        
        self:setColor(emptyColor)
        if current > 0 then self:setColor(fillColor) end
        
        local fillLength = math.ceil((current / maximum) * width)

        self:image("icon/bar_left", x, y)
        for i = 1, width - 1 do
            if i > fillLength then self:setColor(emptyColor) end
            self:image("icon/bar_middle", x + i, y)
        end
        self:image("icon/bar_right", x + width - 1, y)
        
        local labelText = ""
        if form == "%" or form == "percent" then
            labelText = label..tostring(math.ceil(current / maximum * 100)).."%"
        elseif form == "#" or form == "number" then
            labelText = label.."%d/%d" % {current, maximum}
        else
            labelText = ""
        end
        
        self:setColor("white")
        self:text(labelText, width + 1 + x, y)
    end,
    
    healthmana = function(self, entity, mode, w)
        local mode = mode or "#"
        local w = w or 40
        local classText = ""
        if entity.class then classText = " "..entity.class.info.name end
        
        local nameText = "{gray7}%s [%s%s]" % {entity:display(), entity.level:display(), classText}
        local nameTextLen = strLen(nameText)
        self:text(nameText)
        
        local passives = entity.passiveHolder.list
        if #passives > 0 then
            draw:space(-1)
            draw:shift()
            for i = 1, #passives do
                self:image("icon/"..passives[i].type, nameTextLen + (i - 1) * 2)
            end
            draw:shift(-1)
            draw:space()
        end
        
        self:icon("hp")
        self:bar(entity.health.current, entity.health.max, "hp", "gray4", w, "{gray7}HP: ", mode, 2)
        self:icon("mp")
        self:bar(entity.mana.current, entity.mana.max, "mp", "gray4", w, "{gray7}MP: ", mode, 2)
    end,
    
    mainStats = function(self, entity, w)
        w = w or 40
        
        self:healthmana(entity, "#", w)
        self:icon("xp")
        self:bar(entity.level.exp, entity.level.maxExp, "xp", "gray4", w, "{gray7}XP: ", "#", 2)
        self:icon("gp")
        self:text("{gray7}Gold: %d" % {entity.gold}, 2)
    end,
    
    stat = function(self, name, stat)
        if stat == nil then return end
        
        local fixedName = title(name)
        
        if stat.opp == "+" then
            local verb = stat.value > 0 and "+" or "-"
            self:text(": %s%s <%s> %s" % {verb, stat.value, name, fixedName})
        elseif stat.opp == "*" then
            local verb = stat.value > 0 and "Increases" or "Decreases"
            self:text(": %s <%s> %s by %s%%" % {verb, name, fixedName, stat.value})
        elseif stat.opp == "=" then
            self:text(": Sets <%s> %s to %s" % {name, fixedName, stat.value})
        end
    end,
    
    item = function(self, item, quantity)
        self:text(item:display(quantity))
        self:space()
        for k, v in ipairs(item:get("description")) do self:text(v) end
        
        local effect = item:get("effect")
        if effect then
            for k, v in ipairs(effect) do self:effect(v) end
        end
        
        local stats = item:get("stats")
        if stats then
            self:space()
            for k, v in pairs(stats) do self:stat(k, v) end
        end
        
        if item:get("value") then
            self:space()
            self:setColor("white")
            self:text("<gp> %d" % {item:get("value")})
        end
    end,
    
    effect = function(self, effect)
        local text = ""
        
        local hpCost = effect:get("hpCost")
        local mpCost = effect:get("mpCost")
        
        if hpCost or mpCost then self:space() end
        
        if hpCost and mpCost then self:text("Costs <hp>{hp} %s{white} and <mp>{mp} %s" % {hpCost, mpCost})
        elseif hpCost then self:text("Costs <hp>{hp} %s" % hpCost)
        elseif mpCost then self:text("Costs <mp>{mp} %s" % mpCost) end
        self:setColor("white")
        
        local hp = effect:get("hp")
        local mp = effect:get("mp")
        
        if hp or mp then self:space() end
        
        if hp and hp[1] + hp[2] ~= 0 then
            if hp[2] > 0 then text = "Heals" else text = "Damages" end
            self:text("%s <hp> {hp}%d - %d" % {text, math.abs(hp[1]), math.abs(hp[2])})
        end
        
        if mp and mp[1] + mp[2] ~= 0 then
            if mp[2] > 0 then text = "Heals" else text = "Damages" end
            self:text("%s <mp> {mp}%d - %d" % {text, math.abs(mp[1]), math.abs(mp[2])})
        end
        self:setColor("white")
    end,
    
}