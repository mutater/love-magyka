require "script/node/node"

Level = Node{
	identity = "Level",
	current = 1,
	exp = 0,
	maxExp = 100,
	totalExp = 0,
	linkedHealth = nil,
	linkedMana = nil,
	linkedStats = nil,
	
	setExp = function(self, value)
		self:removeTotalExp(value - self.exp)
		self.exp = value
		while self.exp > self.maxExp do self:levelUp() end
	end,
	
	addExp = function(self, value)
		self:setExp(self.exp + value)
	end,
	
	removeTotalExp = function(self, value)
		self.totalExp = self.totalExp - value
	end,
	
	levelUp = function(self, value)
		if self.current < 999 then
            local current
            if self.level <= 49 then levelMod = 1.05
            elseif self.current <= 99 then levelMod = 1.02
            elseif self.current <= 199 then levelMod = 1.003
            elseif self.current <= 299 then levelMod = 1.001
            elseif self.current <= 399 then levelMod = 1.0004
            elseif self.current <= 499 then levelMod = 1.0001
            else levelMod = 1.00001 end
            
            self.maxExp = math.ceil(self.maxExp * levelMod * 1.008)
            self.current = self.current + 1
			
			if (self.linkedHealth or self.linkedMana) and self.linkedStats then
				if self.linkedHealth then
					local base = self.linkedStats.base
					local mod = base.vitality / (1000 + self.current)
					base.maxHp = math.ceil(base.maxHp * (levelMod + mod))
					self.linkedHealth:set(base.maxHp)
				end
				
				if self.linkedMana then
					local base = self.linkedStats.base
					local mod = base.intelligence / (1000 + self.current)
					base.maxMp = math.ceil(base.maxMp * (levelMod + mod))
					self.linkedMana:set(base.maxMp)
				end
				
				self:update()
			end
        else
            self.exp = self.maxExp
        end
	end,
	
	display = function(self)
		return "Lvl %d" % self.current
	end,
}