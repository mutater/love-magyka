require "script/node/node"
require "script/tools"

Passive = Node{
	identity = "Passive",
	nodes = {
		"Info",
		"StatEffect",
		"Effects",
		"Alignment",
	},
    turns = nil,
    addChance = 100,
    removeChance = 100,
    activateChance = 100,
    buff = true,
    category = nil,
	
	display = function(self)
		return self.info.name
	end,
    
    activate = function(self, parent)
        if rand(1, 100) <= self.activateChance then
            return self.effects:activate(self, parent)
        end
        
        return {""}
    end,
}