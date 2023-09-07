require "script/globals"
require "script/node/node"
require "script/tools"

Stats = Node{
	identity = "Stats",
	current = {},
	base = {},
    linkedEquipment = nil,
    linkedPassiveHolder = nil,
    linkedArts = nil,
    
	init = function(self)
		local defaultStats = {
			maxHealth = 7,
			maxMana = 10,
			hit = 95,
			dodge = 4,
			crit = 4,
			critDamage = 100,
			carry = 12,
		}
		
		if isNotEmpty(self.base) then
			for k, v in pairs(defaultStats) do
				if not self.base[k] then self.base[k] = v end
			end
		else
			self.base = defaultStats
		end
		
		for k, v in ipairs(Globals.stats) do
			if not self.base[v] then
				self.base[v] = 0
			end
		end
		
		for k, v in ipairs(Globals.extraStats) do
			if not self.base[v] then
				self.base[v] = 0
			end
		end
		
		self.current = deepcopy(self.base)
	end,
	
	update = function(self, ...)
		local args = {...}
		local buffer = {}
		local changes = {}
		
		self.current = deepcopy(self.base)
		
		for k, v in pairs(self.current) do
			changes[k] = {["+"] = 0, ["*"] = 100, ["="] = false}
		end
		
		-- Get stats from args
		
		for _, c in ipairs({linkedEquipment, linkedPassiveHolder, linkedArts}) do
			for k, v in ipairs(c.list) do
				if type(v) == "table" and v.stats ~= nil then
					for _, stat in pairs(v:get("stats")) do table.insert(buffer, stat) end
				end
			end
		end
		
		-- Format buffer into changes
        
        for k, v in pairs(buffer) do
			changes[v.stat][v.opp] = changes[v.stat][v.opp] + v.value
			
            if v.opp == "=" and changes[v.stat]["="] then
				changes[v.stat]["="] = math.min(changes[v.stat]["="], v.value)
            end
        end
        
        
        -- Apply stat changes to self stats
        
        for k, v in pairs(changes) do
            local stat = deepcopy(self.base[k])
			
            stat = stat + v["+"] + math.ceil(self.base[k] * ((v["*"] - 100) / 100))
            if v["="] then stat = v["="] end
			
            self.current[k] = stat
        end
	end,
	
	print = function(self)
		print("STAT                BASE                CURRENT")
		for k, v in pairs(self.base) do
			print("  %s%s%s" % {ljust(k, 20), ljust(tostring(v), 20), self.current[k]})
		end
	end,
}