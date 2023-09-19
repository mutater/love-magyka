require "script/globals"
require "script/node/effect"
require "script/node/node"
require "script/node/recipe"
require "script/tools"

Entity = Node{
    identity = "Entity",
	nodes = {
		"Info",
		"Health",
		"Mana",
		"Stats",
		"Alignment",
		"Level",
		"Inventory",
		"Equipment",
		"PassiveHolder",
		"Recipes",
		"Loots",
		"Effects",
		"Passives",
	},
	gold = 0,
    
    init = function(self)
		self.health.linkedStats = self.stats
		self.mana.linkedStats = self.stats
		
		self.stats.linkedEquipment = self.equipment
		self.stats.linkedPassiveHolder = self.passiveHolder
		
		self.alignment.linkedEquipment = self.equipment
		self.alignment.linkedPassiveHolder = self.passiveHolder
		
		self.level.linkedHealth = self.health
		self.level.linkedMana = self.mana
		self.level.linkedStats = self.stats
		
		self.equipment.linkedInventory = self.inventory
		
		self.passiveHolder.linkedEntity = self
    end,
    
    update = function(self)
		self.equipment:update()
		self.alignment:update()
		self.stats:update()
		self.health:update()
		self.mana:update()
		
        -- local weight = 0
        -- for k, v in pairs(self.equipment) do
            -- if v ~= "" and v.stats then
                -- if v.weight then weight = weight + v.weight end
            -- end
        -- end
        
        -- local carry = self.stats.current.carry
        -- printClass(self.stats)
		
        -- local loadDepraved = 3
        -- local loadLight = math.ceil(carry / 2) + 2
        -- local loadMedium = carry + 2
        -- local loadHeavy = carry * 2 + 2
        
        -- if weight <= loadDepraved then self:applyPassive(newPassive("Unburdened"))
        -- elseif weight <= loadLight then self:applyPassive(newPassive("Light Load"))
        -- elseif weight <= loadMedium then self:removePassive("load")
        -- elseif weight <= loadHeavy then self:applyPassive(newPassive("Heavy Load"))
        -- else self:applyPassive(newPassive("Overencumbered")) end
    end,
    
    display = function(self)
        local text = self.info.name
        if self.targetID and self.targetID ~= "" then text = "%s (%s)" % {text, self.targetID} end
        return text
    end,
	
    attack = function(self, target)
        local weapon = self.equipment["weapon"]
        local text = {}
        local parent = self
        
        if self:isEquipped("weapon") then
            parent = weapon
            effect = self:get("equipment").weapon:get("effect")
        else
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
        self.stats.base = deepcopy(class.stats.base)
		self.stats:init()
        self:init()
		
		self.stats:update()
		self.health:update()
		self.mana:update()
		
        self.health:setFull()
		self.mana:setFull()
        self.info.class = class
		
		self:update()
    end,
}
