require "script/node/node"

Arts = Node{
    identity = "Arts",
	list = {},
	
	has = function(self, art)
		local name = art
		if type(art) == "table" then name = art.info.name end
		
		for k, v in ipairs(self.list) do
			if v.info.name == name then return true end
		end
		
		return false
	end,
	
	add = function(self, art)
		if not self:has(art) then
			table.insert(art)
		end
	end,
	
	remove = function(self, art)
		local name = art
		if type(art) == "table" then name = art.info.name end
		
		for k, v in ipairs(self.list) do
			if v.info.name == name then
				table.remove(self.list, k)
				break
			end
		end
	end,
	
	update = function(self)
		for k, v in ipairs(self.list) do
			v:update()
		end
	end,
}