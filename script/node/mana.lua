require "script/node/node"

Mana = Node{
	identity = "Mana",
	current = 1,
	max = 1,
    linkedStats = nil,
	
	set = function(self, value)
		self.current = math.min(value, self.max)
		self.current = math.max(self.current, 0)
	end,
	
	setFull = function(self)
		self.current = self.max
	end,
	
	setMax = function(self, value)
		self.max = value
		self.current = math.min(self.current, self.max)
	end,
	
	add = function(self, value)
		self:set(self.current + value)
	end,
    
    update = function(self)
        if self.linkedStats then self:setMax(self.linkedStats.current.maxMana) end
    end,
}