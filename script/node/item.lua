require "script/node/node"
require "script/tools"

--[[

Tags:
    infinite: doesn't get consumed on use
    self: overrides usage.targetSelf
    other: overrides usage.targetOther

]]

Item = Node{
	nodes = {
		"Info",
		"StatEffect",
		"Effects",
		"Passives",
		"Usage",
	},
    value = 1,
    stackable = true,
    weapon = false,
    consumable = false,
    equipment = false,
    slot = "",
    weight = 0,
    
	init = function(self)
		if self.slot then self.equipment = true end
		if self.equipment then self.stackable = false end
		
		self.type = "misc"
		if self.equipment then self.type = "equipment"
		elseif self.weapon then self.type = "weapon"
		elseif self.consumable then self.type = "consumable" end
		
		if self.consumable or self.weapon then
			self.usage.verb = "uses"
			self.usage.preposition = "on"
		elseif self.equipment and self.slot == "weapon" then
			self.usage.verb = "attacks"
		end
		
		if self.weapon then
			self.usage.targetSelf = false
			self.usage.targetOther = true
		elseif self.consumable then
			self.usage.targetOther = false
			self.usage.targetSelf = true
		end
	end,
	
    display = function(self, quantity)
        quantity = quantity or 0
        
        if quantity > 0 then quantity = " x"..tostring(quantity)
        else quantity = "" end
        
        return "{%s}%s{white}%s" % {self.info.rarity, self.info.name, quantity}
    end,
    
    info = function(self)
        local infoString = ""
        local buff = false
        local debuff = false
        local dev = startsWith(self.name, "[dev]")
        local hp = false
        local mp = false
        local weapon = self.weapon
        local equipment = self.equipment
        
        if self.effect and self.consumable then
            for k, v in ipairs(self.effect) do
                if self.targetSelf and v.hp and v.hp[2] > 0 then hp = true end
                if self.targetSelf and v.mp and v.mp[2] > 0 then mp = true end
                
                if type(v.passive) == "table" then
                    for _, passive in ipairs(v.passive) do
                        if passive.buff then buff = true end
                        if passive.buff == false then debuff = true end
                    end
                end
            end
        end
        
        if dev then infoString = infoString.."<dev>" end
        if hp then infoString = infoString.."<hp>" end
        if mp then infoString = infoString.."<mp>" end
        if buff then infoString = infoString.."<buff>" end
        if debuff then infoString = infoString.."<debuff>" end
        if weapon then infoString = infoString.."<weapon>" end
        if equipment then infoString = infoString.."<armor>" end
        
        return infoString
    end,
    
    displayNoColor = function(self, quantity)
        quantity = quantity or 0
        
        if quantity > 0 then quantity = " x"..tostring(quantity)
        else quantity = "" end
        
        return "%s%s" % {self.info.name, quantity}
    end,
    
    activate = function(self, source, target)
        return self.effects:activate(self, source, target)
    end,
    
    update = function(self)
    
    end,
}
