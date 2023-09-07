require "script/node/node"
require "script/tools"

Loots = Node{
    identity = "Loots",
    list = {},
    
    activate = function(self)
        local i = {}
		
        for k, v in ipairs(self.list) do
            appendTable(i, v:activate())
        end
        
        return i
    end,
}