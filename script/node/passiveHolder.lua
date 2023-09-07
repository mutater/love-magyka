require "script/node/node"
require "script/tools"

PassiveHolder = Node{
	identity = "PassiveHolder",
	list = {},
    linkedEntity = nil,
	
	has = function(self, passive)
        local name = passive
        if type(passive) == "table" then name = passive.info.name end
        
        for k, v in ipairs(self.list) do
            if v.info.name == name then return true end
        end
        
        return false
    end,
    
    add = function(self, passive)
        if passive == nil then return end
        
        passive.turns = rand(passive.turns)
        
        for k, v in ipairs(self.list) do
            if v.info.name == passive.info.name then
                v.turns = passive.turns
                break
            end
            
            if v.type ~= nil and v.type == passive.type then
                self.list[k] = passive
                break
            end
        end
    end,
    
    remove = function(self, passive)
        if passive == nil then return end
        
        local name = passive
        if type(passive) == "table" then name = passive.info.name end
        
        for i = #self.list, 1, -1 do
            if self.list[i].info.name == name then
                table.remove(self.list, i)
            end
        end
    end,
    
    activate = function(self)
        self.linkedEntity:update()
        local text = {}
        
        if #self.list > 0 then
            for i = #self.list, 1, -1 do
                local passive = self.list[i]
                local line = passive.effect:activate(passive, self.linkedEntity, self.linkedEntity)
                
                if not isInTable({"stats", "load"}, passive.category) then appendTable(text, line) end
                
                passive.turns = passive.turns + 1
                if passive.turns <= 0 then
                    table.remove(self.list, i)
                end
            end
        end
        
        return text
    end,
}