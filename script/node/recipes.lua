require "script/node/node"


Recipes = Node{
	identifier = "Recipes",
	list = {},
	
	add = function(self, arg)
        if type(arg) == "string" then arg = newItem(arg) end
        
        if arg.identifier == "Recipe" then
            for k, v in ipairs(self.list) do
                if v.info.name == arg.info.name and v.id == arg.id then
                    return
                end
            end
            
            self.list.append(arg)
        elseif arg.identifier == "Item" then
            for k, v in ipairs(recipes[item.info.name]) do
                self:add(v)
            end
        end
    end,
}