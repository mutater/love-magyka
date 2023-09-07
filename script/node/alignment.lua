require "script/node/node"
require "script/tools"

Alignment = Node{
	identity = "Alignment",
	elementX = 0,
    elementY = 0,
	bc = 0,
    linkedEquipment = nil,
    linkedPassiveHolder = nil,
	
	update = function(self)
		if linkedEquipment or linkedPassiveHolder then
			local eX = 0
			local eY = 0
			local bc = 0
			
			for _, c in ipairs({linkedEquipment, linkedPassiveHolder}) do
				for k, v in ipairs(c.list) do
					if type(v) == "table" and v.alignment ~= nil then
						local e = alignment:getElement()
						eX = eX + e.x
						eY = eY + e.y
						bc = bc + alignment:getBc()
					end
				end
			end
			
			self.elementX = eX
			self.elementY = eY
			self.bc = bc
		end
	end,
	
	getElement = function(self)
		local magnitude = (self.elementX ^ 2 + self.elementY ^ 2) ^ 0.5
		return {x=self.elementX/magnitude, y=self.elementY/magnitude}
	end,

    getBc = function(self)
		return clamp(self.bc, -1, 1)
	end,
}