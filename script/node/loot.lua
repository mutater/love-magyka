require "script/node/node"
require "script/tools"

Loot = Node{
    identity = "Loot",
    xp = nil,
    gp = nil,
    items = {},
	arts = {},
    mode = "normal",
    
    activate = function(self)
        local i = {}
		
        for k, v in ipairs(self.items) do
            if rand(1, 100) <= v[3] then
                table.insert(i, {newItem(v[1]), rand(v[2])})
            end
        end
        
        return i
    end,
}