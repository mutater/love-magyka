require "script/node/node"
require "script/tools"

Passives = Node{
	identity = "Passives",
	list = {},
    
    activate = function(self, parent, source, target)
        local text = {}
        
        if #self.list > 0 then
            for k, v in ipairs(self.list) do
                appendTable(text, v:activate(parent, source, target))
            end
        end
        
        return text
    end,
}