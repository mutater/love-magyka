require "script/node/node"
require "script/tools"

Inventory = Node{
	identity = "Inventory",
    list = {},
	linkedRecipes = nil,
	
    has = function(self, item)
        return self:count(item) > 0
    end,
    
    count = function(self, item)
        local quantity = 0
        local name = ""
        
        if type(item) == "string" then name = item
        else name = item.info.name end
        
        local notStackable = type(item) == "table" and not item.stackable
        
        for k, v in ipairs(self.list) do
            if notStackable and item == v[1] then
                return 1
            elseif name == v[1].info.name then
                if v[1].stackable then return v[2]
                else quantity = quantity + 1 end
            end
        end
        
        return quantity
    end,
    
    add = function(self, item, quantity)
        if item == nil then return end
        
		if self.linkedRecipes then self.linkedRecipes:add(item) end
		
        local quantity = quantity or 0
        if item.stackable and self:has(item) then
            for k, v in ipairs(self.list) do
                if v[1].info.name == item.info.name then
                    v[2] = v[2] + quantity
                    break
                end
            end
        elseif item.stackable then
            table.insert(self.list, {item, quantity})
        else
            for i = 1, quantity do table.insert(self.list, {deepcopy(item), 1}) end
        end
    end,
    
    remove = function(self, item, quantity)
        if item == nil then return end
        
        local quantity = quantity or 1
        local name = ""
        
        if type(item) == "string" then name = item
        else name = item.info.name end
        
        local notStackable = type(item) == "table" and not item.stackable and quantity == 1
        
        for i = #self.list, 1, -1 do
            local v = self.list[i]
            if notStackable and item == v[1] then
                table.remove(self.list, i)
                break
            elseif name == v[1].info.name and v[1].stackable then
                v[2] = v[2] - quantity
                if v[2] <= 0 then table.remove(self.list, i) end
                break
            elseif name == v[1].info.name then
                table.remove(self.list, i)
                quantity = quantity - 1
            end
        end
    end,
    
    update = function(self)
		-- maybe check for nil items here?
		
        for k, v in ipairs(self.list) do
            v[1]:update()
        end
    end,
}