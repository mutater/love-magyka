require "script/globals"
require "script/node/node"
require "script/tools"

StatEffect = Node{
	identity = "StatEFfect",
	current = {},
    
	init = function(self)
		for k, v in pairs(self.base) do
			if type(v) ~= "table" then self.base[k] = {stat = k, value = v, opp = "+"} end
		end
	end,
	
	update = function(self)
	
	end,
}