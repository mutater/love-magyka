require "script/node/node"
require "script/globals"
require "script/tools"

Equipment = Node{
	identity = "Equipment",
    list = {},
	linkedInventory = nil,
	
    has = function(self, item)
		if item == nil then return false end
		
		return self.list[item.slot] == item
    end,
    
    add = function(self, item)
        if item == nil or not item.equipment or self:has(item) then return end
        
		if list[item.slot] ~= "" then self.remove(item.slot) end
		
		item.list[item.slot] = item
		
		if self.linkedInventory then self.linkedInventory.remove(item) end
    end,
    
    remove = function(self, item)
        if item == nil then return end
        
        local slot = ""
        
        if type(item) == "string" then slot = item
        else slot = item.slot end
        
        list[slot] = ""
		
		if self.linkedInventory then self.linkedInventory.add(item) end
    end,
    
    update = function(self)
        for k, v in pairs(self.list) do
            if v ~= "" then v:update() end
        end
    end,
	
	init = function(self)
		for _, slot in ipairs(Globals.slots) do
			if self.list[slot] == nil then self.list[slot] = "" end 
		end
	end,
}