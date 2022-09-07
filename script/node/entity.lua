require "script/globals"
require "script/node/effect"
require "script/node/node"
require "script/node/recipe"
require "script/tools"

Entity = Node{
    hp = 0,
    mp = 0,
    xp = 0,
    maxXp = 10,
    gp = 0,
    
    name = "name",
    level = 1,
    
    attackEffect = nil,
    attackText = "attacks",
    
    stats = {},
    baseStats = {},
    
    equipment = {},
    inventory = {},
    recipes = {},
    arts = {},
    passives = {},
    
    levelUp = function(self)
        self.stats.maxHp = math.ceil(self.stats.maxHp * (1.09 - self.level / 2000))
        self.stats.maxMp = math.ceil(self.stats.maxMp * (1.09 - self.level / 2000))
        self:set("maxXp", math.ceil(self.maxXp * (1.11 - self.level / 2000)))
        self:add("level", 1)
    end,
    
    display = function(self)
        return self:get("name")
    end,
    
    
    -- INVENTORY / EQUIPMENT
    
    
    numOfItem = function(self, item)
        local quantity = 0
        local name = ""
        
        if type(item) == "string" then name = item
        else name = item:get("name") end
        
        for k, v in ipairs(self.inventory) do
            if v[1]:get("stackable") and v[1]:get("name") == name then
                quantity = v[2]
                break
            elseif not v[1]:get("stackable") and type(item) == "string" then
                quantity = quantity + 1
            elseif not v[1]:get("stackable") and type(item) == "table" then
                quantity = 1
                break
            end
        end
        
        return quantity
    end,
    
    addItem = function(self, item, quantity)
        if item then
            local quantity = quantity or 1
            item = deepcopy(item)
            item:update()
            
            -- Add item
            if self:numOfItem(item) > 0 and item:get("stackable") then
                for k, v in ipairs(self.inventory) do
                    if v[1] == item then
                        v[2] = v[2] + quantity
                        break
                    end
                end
            elseif item:get("stackable") then
                table.insert(self.inventory, {item, quantity})
            else
                for i = 1, quantity do table.insert(self.inventory, {deepcopy(item), 1}) end
            end
            
            -- Add recipes
            if recipes[item.name] then
                for k, v in ipairs(recipes[item.name]) do
                    local recipeFound = false
                    for _, recipe in ipairs(self.recipes) do
                        if recipe:get("name") == v then
                            recipeFound = true
                            break
                        end
                    end
                    
                    if not recipeFound then table.insert(self.recipes, newRecipe(v)) end
                end
            end
        end
    end,
    
    removeItem = function(self, item, quantity)
        local quantity = quantity or 1
        
        local name = item
        if type(item) == "table" then name = item:get("name") end
        
        if quantity > self:numOfItem(item) then quantity = self:numOfItem(item) end
        
        if self:numOfItem(item) > 0 then
            if type(item) == "string" or item:get("stackable") then
                for k, v in ipairs(self.inventory) do
                    if v[1]:get("name") == name then
                        if quantity == v[2] then table.remove(self.inventory, k)
                        else v[2] = v[2] - quantity end
                        break
                    end
                end
            else
                for k, v in ipairs(self.inventory) do
                    if v[1] == item then
                        table.remove(self.inventory, k)
                        break
                    end
                end
            end
        end
    end,
    
    equip = function(self, item)
        local slot = item:get("slot")
        if slot then
            item:update()
            
            self:unequip(slot)
            self.equipment[slot] = item
            self:removeItem(item)
            
            self:update()
        end
    end,
    
    unequip = function(self, a)
        if type(a) == "string" then slot = a
        elseif type(a) == "table" then slot = a:get("slot") end
        
        if self:isEquipped(slot) then
            self.equipment[slot]:update()
            self:addItem(self.equipment[slot])
            self.equipment[slot] = ""
        end
        
        self:update()
    end,
    
    isEquipped = function(self, slot)
        return self.equipment[slot] and self.equipment[slot] ~= ""
    end,
    
    
    -- BATTLING / STATS
    
    
    update = function(self)
        local stats = {}
        local statChanges = {}
        for k, v in pairs(self:get("stats")) do statChanges[k] = {["+"] = 0, ["*"] = 100, ["="] = false} end
        
        for k, v in pairs(self:get("equipment")) do
            if v ~= "" and v:get("stats") then
                for _, stat in pairs(v:get("stats")) do table.insert(stats, stat) end
            end
        end
        
        for k, v in pairs(self:get("passives")) do
            if v:get("stats") then
                for _, stat in pairs(v:get("stats")) do table.insert(stats, stat) end
            end
        end
        
        for k, v in pairs(stats) do
            if v.opp == "=" then
                if statChanges[v.stat]["="] and v.value < statChanges[v.stat]["="] then
                    statChanges[v.stat]["="] = v.value end
            elseif v.opp == "*" then
                statChanges[v.stat]["*"] = statChanges[v.stat]["*"] + v.value
            else
                statChanges[v.stat]["+"] = statChanges[v.stat]["+"] + v.value
            end
        end
        
        for k, v in pairs(statChanges) do
            local baseStat = self:get("baseStats")[k]
            local stat = baseStat
            stat = stat + v["+"]
            stat = stat + math.ceil(baseStat * ((v["*"] - 100) / 100))
            if v["="] then stat = v["="] end
            
            self:get("stats")[k] = stat
        end
        
        if self:get("hp") > self:get("stats").maxHp then self:set("hp", self:get("stats").maxHp) end
        if self:get("mp") > self:get("stats").maxMp then self:set("mp", self:get("stats").maxMp) end
    end,
    
    updatePassives = function(self)
        self:update()
        local text = {}
        
        if #self:get("passives") > 0 then
            for i = #self:get("passives"), 1, -1 do
                local passive = self:get("passives")[i]
                if passive:get("passiveType") ~= "stats" then appendTable(text, passive:use(passive, self, self)) end
                
                passive:add("turns", -1)
                if passive:get("turns") <= 0 then
                    table.remove(self:get("passives"), i)
                end
            end
        end
        
        return text
    end,
    
    applyPassive = function(self, passive)
        local turns = passive:get("turns")
        if type(turns) == "table" then turns = rand(turns) end
        
        local passiveFound = false
        for k, v in ipairs(self:get("passives")) do
            if v:get("name") == passive:get("name") then
                passiveFound = true
                v:set("turns", math.max(v:get("turns"), passive:get("turns")))
                break
            end
        end
        
        if not passiveFound then table.insert(self:get("passives"), passive) end
        self:update()
    end,
    
    attack = function(self, target)
        local weapon = self.equipment["weapon"]
        local text = {}
        local parent = self
        
        if self:isEquipped("weapon") then
            parent = weapon
            effect = self:get("equipment").weapon:get("effect")
        else
            parent = nil
            effect = newEffect(self:get("attackEffect"))
            effect:set("verb", self:get("attackText"))
            effect = {effect}
        end
        
        for k, e in ipairs(effect) do
            if e.hp then
                e.hp[1] = e.hp[1] - self:get("stats").strength
                e.hp[2] = e.hp[2] - self:get("stats").strength
            end
            
            if e.crit == nil then e.crit = e.critBonus + self:get("stats").crit end
            
            appendTable(text, e:use(parent, self, target))
        end
        
        return text
    end,
    
    setClass = function(self, class)
        self.baseStats.maxHp = class.hp
        self.baseStats.maxMp = class.mp
        
        self:update()
        
        self.hp = class.hp
        self.mp = class.mp
        self.class = class
        
        for k, v in pairs(class.stats) do
            self.baseStats[k] = v
        end
        
        self:update()
    end,
    
    
    -- CLASS FUNCTION OVERRIDES
    
    
    get = function(self, key)
        if key == "title" then
            local class = ""
            if self:get("class") then class = " "..self:get("class") end
            return "%s [Lvl %d%s]" % {self:get("name"), self:get("level"), class}
        else
            return self[key]
        end
    end,
    
    set = function(self, key, value)
        if key == "hp" then
            self.hp = value
            
            if self.hp < 0 then self.hp = 0 end
            if self.hp > self.stats.maxHp then self.hp = self.stats.maxHp end
        elseif key == "mp" then
            self.mp = value
            
            if self.mp < 0 then self.mp = 0 end
            if self.mp > self.stats.maxMp then self.mp = self.stats.maxMp end
        elseif key == "xp" then
            self.xp = value
            
            while self.xp >= self.maxXp do
                self.xp = self.xp - self.maxXp
                self:levelUp()
            end
        else
            self[key] = value
        end 
    end,
}