require "script/node/item"
require "script/node/node"

Loot = Node{
    xp = nil,
    gp = nil,
    items = {},
    mode = "normal",
    
    drop = function(self)
        local i = {}
        for k, v in ipairs(self.items) do
            if rand(1, 100) <= v[3] then
                local quantity = 0
                if type(v[2]) == "table" then quantity = rand(v[2])
                else quantity = v[2] end
                
                table.insert(i, {newItem(v[1]), quantity})
            end
        end
        
        return i
    end,
}