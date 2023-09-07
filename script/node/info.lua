require "script/node/node"

Info = Node{
	identity = "Info",
	name = nil,
	description = nil,
	rarity = nil,
	color = nil,
	verb = nil,
	preposition = nil,
	
	display = function(self)
		return self.name
	end,
}