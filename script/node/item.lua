require "script/node/node"
require "script/tools"

Item = Node{
    name = "item",
    description = {"description"},
    rarity = "common",
    value = 1,
    stackable = true,
    equipment = false,
    stats = nil,
    slot = "",
    weight = 0,
    consumable = false,
    effect = nil,
    target = "entity",
    targetSelf = true,
    targetOther = true,
    
    display = function(self, quantity)
        quantity = quantity or 0
        
        if quantity > 0 then quantity = " x"..tostring(quantity)
        else quantity = "" end
        
        return "{%s}%s{white}%s" % {self.rarity, self.name, quantity}
    end,
    
    update = function(self)
    
    end,
}